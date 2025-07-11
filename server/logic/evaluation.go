package logic

import (
  "math"
  "math/rand"
  "time"
  "fmt"
  "sort"
)

type Evaluation map[MetricKey]uint16
type Preference map[MetricKey]uint16
type Weight map[MetricKey]float64

// 顧客満足度スコアを算出する関数
// CalculateMatchingScore は、ラーメンの評価ベクトル（Evaluation）と、
// 顧客の嗜好ベクトル（Preference）、および各評価軸の重み（Weight）をもとに、
// 顧客の満足度スコア（0〜100）を算出します。
//
// 評価値は各評価軸について以下のように計算され：
//     score_i = weight_i × (65535 - |recipe_i - preference_i|)
// 各軸のスコアを合計し、正規化して 0〜100 にスケーリングします。
//
// - Evaluation: 実際のラーメンが持つ評価（各軸の uint16 値）
// - Preference: 顧客の理想的な評価（各軸の uint16 値）
// - Weight: 各軸に対する顧客の重視度（float64）
//
// 戻り値:
//   - 満足度スコア（float64, 0〜100）
func CalculateMatchingScore(e Evaluation, h Preference, w Weight) float64 {
  var sum float64
  for _, key := range MetricKeys {
    ri := float64(e[key])
    hi := float64(h[key])
    wi := w[key]
    score := wi * (65535 - math.Abs(ri-hi))
    sum += score
  }
  return sum / 655350.0 * 100 // 正規化：65535 × 10
}


type Component struct {
  Type string `json:"type"` // e.g. "noodle", "soup", ...
  ID   string `json:"id"`   // e.g. "thick-noodle-001"
}

type Recipe struct {
  ID         string      `json:"id"`
  Name       string      `json:"name"`
  Components []Component `json:"components"`
}

// EvaluateRecipe は、レシピに含まれる各Componentの寄与値を合算して
// 評価ベクトル（10軸）を返します。
func EvaluateRecipe(recipe Recipe) Evaluation {
  result := make(Evaluation)
  for _, key := range MetricKeys {
    result[key] = 0
  }

  for _, c := range recipe.Components {
    spec, ok := ComponentMaster[c.ID]
    if !ok {
      continue // 未知のIDは無視（ログ出すならここ）
    }
    for k, v := range spec.Contribution {
      if result[k]+v < result[k] { // uint16 overflow対策（理論上不要）
        result[k] = 65535
      } else {
        result[k] += v
      }
    }
  }

  // 明示的に最大値クリップ（念のため）
  for k, v := range result {
    if v > 65535 {
      result[k] = 65535
    } else {
      result[k] = v
    }
  }

  return result
}



// ApplyCookingSkill は調理スキルに応じて評価値にノイズを加える。
// skill は 0.0（未熟）〜1.0（完璧）で、skill が低いほどブレ幅が大きくなる。
func ApplyCookingSkill(base Evaluation, skill float64) Evaluation {
  rand.Seed(time.Now().UnixNano())

  result := make(Evaluation)
  for k, v := range base {
    // ノイズ幅：±10% × (1 - skill)
    noiseRatio := rand.NormFloat64() * (1.0 - skill) * 0.1
    adjusted := float64(v) * (1.0 + noiseRatio)

    // 最小0, 最大65535でクリップしてuint16に変換
    if adjusted < 0 {
      adjusted = 0
    }
    if adjusted > 65535 {
      adjusted = 65535
    }
    result[k] = uint16(math.Round(adjusted))
  }
  return result
}

// コメントテンプレート（シンプル版）
var commentTemplates = map[MetricKey][2]string{
  Umami:      {"旨味が物足りない", "旨味がしっかりしていた"},
  Aroma:      {"香りが控えめだった", "香りが立っていた"},
  Salt:       {"味が薄めだった", "ちょうどいい塩加減だった"},
  Fat:        {"もう少しこってりでも良かった", "脂がちょうどよかった"},
  Sweet:      {"甘味が感じられなかった", "甘味がほのかに良かった"},
  Spicy:      {"刺激が足りない", "刺激的でクセになる味"},
  Creative:   {"個性が弱かった", "独創的で印象に残った"},
  Appearance: {"見た目が少し地味だった", "盛り付けが美しかった"},
  Volume:     {"量が少し物足りない", "ボリューム満点だった"},
  Harmony:    {"味のバランスが微妙だった", "全体の調和が取れていた"},
}

// GenerateEvaluationComment は評価と嗜好の差分から印象コメントを返します
func GenerateEvaluationComment(e Evaluation, h Preference, w Weight) string {
  type delta struct {
    key   MetricKey
    score float64 // 重み×差分
    diff  int      // 差分の向き
  }

  var deltas []delta

  for _, key := range MetricKeys {
    d := int(e[key]) - int(h[key])
    score := float64(abs(d)) * w[key]
    deltas = append(deltas, delta{
      key:   key,
      score: score,
      diff:  d,
    })
  }

  // 重み付き差分が大きい順に並べる
  sort.Slice(deltas, func(i, j int) bool {
    return deltas[i].score > deltas[j].score
  })

  // 上位1〜3軸からコメント生成（最大2軸出す）
  comments := []string{}
  for i := 0; i < len(deltas) && len(comments) < 2; i++ {
    d := deltas[i]
    templates, ok := commentTemplates[d.key]
    if !ok {
      continue
    }
    if d.diff < -1000 {
      comments = append(comments, templates[0])
    } else if d.diff > 1000 {
      comments = append(comments, templates[1])
    }
  }

  if len(comments) == 0 {
    return "特に印象には残らなかったようだ。"
  }
  return fmt.Sprintf("お客さんの感想：%s。", joinComments(comments))
}

func joinComments(comments []string) string {
  if len(comments) == 1 {
    return comments[0]
  }
  return fmt.Sprintf("%s、%s", comments[0], comments[1])
}

func abs(x int) int {
  if x < 0 {
    return -x
  }
  return x
}
