package logic

import (
  "testing"
  "strings"
)

func TestCalculateMatchingScore(t *testing.T) {
  recipe := Evaluation{
    Umami:      30000,
    Aroma:      20000,
    Salt:       25000,
    Fat:        32000,
    Sweet:      10000,
    Spicy:      5000,
    Creative:   15000,
    Appearance: 18000,
    Volume:     28000,
    Harmony:    22000,
  }

  preference := Preference{
    Umami:      32000,
    Aroma:      20000,
    Salt:       24000,
    Fat:        33000,
    Sweet:      9000,
    Spicy:      6000,
    Creative:   16000,
    Appearance: 17000,
    Volume:     29000,
    Harmony:    21000,
  }

  weight := Weight{
    Umami:      1.0,
    Aroma:      0.8,
    Salt:       1.2,
    Fat:        1.0,
    Sweet:      0.5,
    Spicy:      0.5,
    Creative:   0.7,
    Appearance: 0.6,
    Volume:     1.0,
    Harmony:    0.9,
  }

  score := CalculateMatchingScore(recipe, preference, weight)
  if score < 80.0 || score > 100.0 {
    t.Errorf("unexpected score: got %f, want between 80 and 100", score)
  }
}


// 仮のマスターデータを埋め込んでテストする
func TestEvaluateRecipe(t *testing.T) {
  // テスト用マスターデータを直書き（YAML読み込みを使わない）
  ComponentMaster = map[string]ComponentSpec{
    "noodle-test": {
      ID:    "noodle-test",
      Type:  "noodle",
      Label: "テスト麺",
      Contribution: map[MetricKey]uint16{
        Umami:  2000,
        Fat:    500,
        Volume: 3000,
      },
    },
    "topping-test": {
      ID:    "topping-test",
      Type:  "topping",
      Label: "テスト具材",
      Contribution: map[MetricKey]uint16{
        Umami:      1000,
        Appearance: 1500,
      },
    },
  }

  recipe := Recipe{
    ID:   "test-recipe",
    Name: "テストレシピ",
    Components: []Component{
      {ID: "noodle-test", Type: "noodle"},
      {ID: "topping-test", Type: "topping"},
    },
  }

  eval := EvaluateRecipe(recipe)

  expect := map[MetricKey]uint16{
    Umami:      3000, // 2000 + 1000
    Fat:        500,
    Volume:     3000,
    Appearance: 1500,
  }

  for key, want := range expect {
    got := eval[key]
    if got != want {
      t.Errorf("評価軸 %s: got %d, want %d", key, got, want)
    }
  }

  // 他の軸はゼロであることを確認
  for _, key := range MetricKeys {
    if _, ok := expect[key]; !ok && eval[key] != 0 {
      t.Errorf("評価軸 %s: expected 0, got %d", key, eval[key])
    }
  }
}


// 基本の評価ベクトル（変化を比較しやすいよう、すべて固定値）
var baseEvaluation = Evaluation{
  Umami:      30000,
  Aroma:      30000,
  Salt:       30000,
  Fat:        30000,
  Sweet:      30000,
  Spicy:      30000,
  Creative:   30000,
  Appearance: 30000,
  Volume:     30000,
  Harmony:    30000,
}

func TestApplyCookingSkill_ReducesVariance(t *testing.T) {
  skillLow := 0.6
  skillHigh := 0.98

  // 低スキルと高スキルで5回ずつノイズをかけて平均差を取る
  var lowVariance, highVariance float64

  for i := 0; i < 5; i++ {
    low := ApplyCookingSkill(baseEvaluation, skillLow)
    high := ApplyCookingSkill(baseEvaluation, skillHigh)

    var lv, hv float64
    for _, key := range MetricKeys {
      // 絶対差の合計
      lv += absDiff(baseEvaluation[key], low[key])
      hv += absDiff(baseEvaluation[key], high[key])
    }
    lowVariance += lv
    highVariance += hv
  }

  if highVariance >= lowVariance {
    t.Errorf("高スキルの方がブレが大きい：low=%.2f, high=%.2f", lowVariance, highVariance)
  }
}

func absDiff(a, b uint16) float64 {
  if a > b {
    return float64(a - b)
  }
  return float64(b - a)
}

func TestGenerateEvaluationComment(t *testing.T) {
  // 評価ベクトル（やや脂が多く、見た目が派手）
  eval := Evaluation{
    Umami:      30000,
    Aroma:      30000,
    Salt:       30000,
    Fat:        50000, // 脂が多い
    Sweet:      30000,
    Spicy:      30000,
    Creative:   30000,
    Appearance: 45000, // 見た目よし
    Volume:     30000,
    Harmony:    30000,
  }

  // 顧客の理想（脂と見た目を重視）
  preference := Preference{
    Umami:      30000,
    Aroma:      30000,
    Salt:       30000,
    Fat:        30000,
    Sweet:      30000,
    Spicy:      30000,
    Creative:   30000,
    Appearance: 30000,
    Volume:     30000,
    Harmony:    30000,
  }

  // 重み：脂と見た目に強く関心
  weight := Weight{
    Umami:      0.5,
    Aroma:      0.5,
    Salt:       0.5,
    Fat:        1.2, // 重視
    Sweet:      0.5,
    Spicy:      0.5,
    Creative:   0.5,
    Appearance: 1.0, // 重視
    Volume:     0.5,
    Harmony:    0.5,
  }

  comment := GenerateEvaluationComment(eval, preference, weight)

  if !strings.Contains(comment, "脂") || !(strings.Contains(comment, "見た目") || strings.Contains(comment, "盛り付け")) {
    t.Errorf("期待するコメントが含まれていません: %s", comment)
  }
}


func TestEvaluationPipeline(t *testing.T) {
  // ★ 1. 仮のレシピ
  recipe := Recipe{
    ID:   "test-recipe",
    Name: "とんこつ黒マー油ラーメン",
    Components: []Component{
      {ID: "noodle-thick"},
      {ID: "soup-tonkotsu"},
      {ID: "tare-rich-soy"},
      {ID: "oil-black-garlic"},
      {ID: "topping-chashu"},
      {ID: "topping-egg"},
      {ID: "plating-black-bowl"},
    },
  }

  // ★ 2. 評価値を算出
  rawEval := EvaluateRecipe(recipe)

  // ★ 3. 調理スキルを仮定（例：skill = 0.85）
  skill := 0.85
  cookedEval := ApplyCookingSkill(rawEval, skill)

  // ★ 4. 顧客データを仮定（男子大学生風）
  preference := Preference{
    Fat:    35000,
    Volume: 32000,
    Spicy:  8000,
  }
  weight := Weight{
    Fat:    1.2,
    Volume: 1.0,
    Spicy:  0.8,
  }

  // 全軸にデフォルト値を入れておく
  for _, k := range MetricKeys {
    if _, ok := preference[k]; !ok {
      preference[k] = 30000
    }
    if _, ok := weight[k]; !ok {
      weight[k] = 0.5
    }
  }

  // ★ 5. スコアを計算
  score := CalculateMatchingScore(cookedEval, preference, weight)
  if score < 50.0 || score > 100.0 {
    t.Errorf("満足度スコアが想定外: %f", score)
  }

  // ★ 6. コメントを生成
  comment := GenerateEvaluationComment(cookedEval, preference, weight)
  if !strings.Contains(comment, "脂") && !strings.Contains(comment, "ボリューム") {
    t.Errorf("コメントが薄すぎる: %s", comment)
  }
}

