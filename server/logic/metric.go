package logic

//go:generate stringer -type=MetricKey

// MetricKey はラーメンの評価軸を列挙する型です。
type MetricKey int

const (
  Umami MetricKey = iota        // 旨味強度
  Aroma                         // 香りの強さ
  Salt                          // 塩味の強さ
  Fat                           // 脂の量（こってり感）
  Sweet                         // 甘味の存在感
  Spicy                         // 刺激・辛味
  Creative                      // 個性・創作性
  Appearance                    // 見た目の美しさ
  Volume                        // ボリューム感
  Harmony                       // 調和性
)

// MetricKeys はすべての評価軸を列挙したスライスです。
var MetricKeys = []MetricKey{
  Umami, Aroma, Salt, Fat, Sweet, Spicy, Creative, Appearance, Volume, Harmony,
}

