class_name Balance
extends RefCounted
## ゲームバランスの定数。仕様書に数値が無いものは暫定値。

# --- 経営 ---
const START_MONEY := 500000
const BANKRUPT_LINE := -100000  # これを下回ると倒産

# --- 時間帯（spec/customer.md） ---
const SLOT_LABELS: Array[String] = ["朝", "昼", "夕方", "夜", "深夜"]
# 営業帯ごとの固定費係数。夕方は仕様に無いので昼と同じにしている。
const SLOT_COST_COEF: Array[float] = [1.0, 1.2, 1.2, 1.5, 2.0]
const DEFAULT_OPEN_SLOTS: Array[bool] = [false, true, true, true, false]
const TURNS_PER_SLOT := 5  # 1営業帯あたりの回転数（キャパ = 席数 × 回転数）

const WEEKDAY_LABELS: Array[String] = ["月", "火", "水", "木", "金", "土", "日"]
const WEEKEND_BONUS := 0.1  # 曜日補正 D

# --- 天候補正 W（spec/location.md） ---
const WEATHERS: Array[Dictionary] = [
	{"id": "sunny", "label": "晴れ", "w": 0.0, "prob": 0.55},
	{"id": "cloudy", "label": "くもり", "w": -0.05, "prob": 0.25},
	{"id": "rain", "label": "雨", "w": -0.3, "prob": 0.17},
	{"id": "snow", "label": "雪", "w": -0.5, "prob": 0.03},
]

# --- 宣伝 M・内装 A ---
const AD_BONUS := 0.2
const AD_COST := 8000
const AD_DAYS := 3
const INTERIOR_BONUS_PER_LEVEL := 0.07
const INTERIOR_COSTS: Array[int] = [80000, 200000, 400000]  # レベル1〜3への改装費
const INTERIOR_LABELS: Array[String] = ["居抜きのまま", "清潔感のある内装", "こだわりの内装", "評判の名店風"]

# --- 調理技術（spec/recipe.md） ---
const START_SKILL := 0.5
const SKILL_BOOST := 0.03          # skill=1.0 のとき全軸 +3%
const SKILL_HARMONY_BOOST := 0.05  # skill=1.0 のとき調和性にさらに +5%
const SKILL_NOISE := 0.10          # 仕上がりのブレ：±10% × (1 - skill)
const SKILL_GROWTH_PER_DAY := 0.005
const TRAINING_COST := 30000
const TRAINING_GAIN := 0.05
const MINIGAME_MAX_BONUS := 0.15   # ミニゲームの精度でその日の技術に上乗せ

# --- 満足度 ---
# S = Σ w_i × (D - |r_i - h_i|) を 0〜100 に正規化するときの D。
# 仕様の 65535 だと差がほとんど出ないので、バランス用に狭めている。
const SCORE_RANGE := 18000.0
const PRICE_SCORE_SCALE := 15.0  # 支払い上限に対する割安・割高の影響
const PRICE_SCORE_MAX := 8.0
const OVERPRICE_DROP := 4.0      # 上限を 25% 超えると誰も買わない

# --- 評判（基準 50、0〜100） ---
const REP_INITIAL := 50.0
const REP_NEUTRAL_SCORE := 70.0  # 平均満足度がこれより上なら評判が上がる
const REP_GAIN := 0.12
const REP_MAX_STEP := 3.0
const REP_FULL_SAMPLE := 8.0     # この人数に届かない日は変化を割り引く

# --- 満腹度（spec/menu.md） ---
const FULLNESS_DIVISOR := 28000.0  # ボリューム感 → 満腹占有率

const RESULT_COMMENTS := 6
