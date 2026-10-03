class_name Economy
extends RefCounted
## 来客・価格・評判まわりの計算式（spec/location.md, spec/menu.md, spec/customer.md）。


## 評判補正 R[c] = (評判スコア[c] - 50) ÷ 100
static func reputation_bonus(reputation: float) -> float:
	return (reputation - 50.0) / 100.0


## 支払い上限[c] = 基本予算[c] × (1 + 評判補正[c])
static func payment_limit(customer: Dictionary, reputation: float) -> float:
	return customer["budget"] * (1.0 + reputation_bonus(reputation))


## 上限以内なら必ず買う。超えると購入確率が大きく下がる。
static func purchase_probability(price: float, limit: float, sensitivity: float) -> float:
	if price <= limit or limit <= 0.0:
		return 1.0 if limit > 0.0 else 0.0
	return clampf(1.0 - (price / limit - 1.0) * Balance.OVERPRICE_DROP * sensitivity, 0.0, 1.0)


## 価格が満足度に与える影響。上限に対して割安なら加点、割高なら減点。
static func price_adjust(price: float, limit: float, sensitivity: float) -> float:
	if limit <= 0.0:
		return -Balance.PRICE_SCORE_MAX
	var raw := (1.0 - price / limit) * Balance.PRICE_SCORE_SCALE * sensitivity
	return clampf(raw, -Balance.PRICE_SCORE_MAX, Balance.PRICE_SCORE_MAX)


## 固定費 = 基本家賃 × 営業帯合計係数（1日あたり）
static func fixed_cost(location: Dictionary, open_slots: Array) -> int:
	if location.is_empty():
		return 0
	var coef := 0.0
	for i in Balance.SLOT_COST_COEF.size():
		if open_slots[i]:
			coef += Balance.SLOT_COST_COEF[i]
	return roundi(location["rent"] * coef)


static func slot_capacity(location: Dictionary) -> int:
	return int(location["seats"]) * Balance.TURNS_PER_SLOT


## 時間帯カバレッジ[c]：生活リズムと営業時間の重なり率（0.0〜1.0）
static func coverage(customer: Dictionary, open_slots: Array) -> float:
	var total := 0.0
	var covered := 0.0
	var rhythm: Array = customer["rhythm"]
	for i in rhythm.size():
		total += rhythm[i]
		if open_slots[i]:
			covered += rhythm[i]
	return 0.0 if total <= 0.0 else covered / total


## その日の平均満足度と提供数から、評判スコアの変化量を出す。
static func reputation_delta(avg_score: float, served: int) -> float:
	if served <= 0:
		return 0.0
	var step := clampf(
		(avg_score - Balance.REP_NEUTRAL_SCORE) * Balance.REP_GAIN,
		-Balance.REP_MAX_STEP, Balance.REP_MAX_STEP)
	return step * minf(1.0, served / Balance.REP_FULL_SAMPLE)


static func satisfaction_label(score: float) -> String:
	if score >= 85.0:
		return "大満足"
	if score >= 75.0:
		return "満足"
	if score >= 65.0:
		return "ふつう"
	if score >= 50.0:
		return "やや不満"
	return "不満"


static func rhythm_symbol(value: float) -> String:
	if value >= 0.9:
		return "◎"
	if value >= 0.5:
		return "○"
	if value > 0.0:
		return "△"
	return "×"
