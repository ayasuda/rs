class_name Evaluation
extends RefCounted
## レシピの評価ベクトル算出・調理・顧客満足度（spec/recipe.md）。

# 特徴 8 軸の感想：[足りない, 多すぎる, ちょうどいい]
const COMMENT_TEMPLATES: Array[Array] = [
	["旨味が物足りない", "旨味が強すぎてくどい", "旨味がしっかりしていた"],
	["香りが控えめだった", "香りが強すぎた", "香りが立っていた"],
	["味が薄めだった", "しょっぱかった", "ちょうどいい塩加減だった"],
	["もう少しこってりでも良かった", "脂っこすぎた", "脂がちょうどよかった"],
	["甘味が感じられなかった", "甘さが気になった", "甘味がほのかに良かった"],
	["刺激が足りない", "辛すぎた", "刺激的でクセになる味"],
	["見た目が少し地味だった", "見た目が派手すぎて落ち着かない", "盛り付けが美しかった"],
	["量が少し物足りない", "量が多すぎて食べきれない", "ボリュームがちょうどよかった"],
]
# 出来 2 軸の感想：[低い, 高い]。Metric.QUALITY_KEYS の順
const QUALITY_COMMENTS: Array[Array] = [
	["個性が弱かった", "独創的で印象に残った"],
	["味のバランスが微妙だった", "全体の調和が取れていた"],
]
# 特徴の近さ s_i（0〜1）で感想を出し分ける。σ=6000 のとき 0.7 ≒ 5000 ずれ、0.88 ≒ 3000 ずれ
const COMMENT_COMPLAINT_CLOSENESS := 0.7  # これ未満の軸は不満として出る
const COMMENT_PRAISE_CLOSENESS := 0.88    # これ以上なら褒められる
const COMMENT_QUALITY_LOW := 64           # 出来がこれ未満なら不満
const COMMENT_QUALITY_HIGH := 192         # 出来がこれ以上なら褒める
const COMMENT_PRAISE_SCORE := 800.0

const LEVEL_THRESHOLDS: Array[int] = [4000, 12000, 22000, 32000]
const LEVEL_WORDS: Array[String] = ["ほぼなし", "控えめ", "ほどほど", "しっかり", "強烈"]
const QUALITY_LEVEL_THRESHOLDS: Array[int] = [51, 102, 153, 204]
const QUALITY_LEVEL_WORDS: Array[String] = ["いまひとつ", "やや弱い", "ほどほど", "良い", "見事"]


static func recipe_component_ids(recipe: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for key in ["noodle", "soup", "tare", "oil"]:
		var id := str(recipe.get(key, ""))
		if id != "":
			ids.append(id)
	for topping in recipe.get("toppings", []):
		ids.append(str(topping))
	var plating := str(recipe.get("plating", ""))
	if plating != "":
		ids.append(plating)
	return ids


## 各構成要素の寄与値を合算して評価ベクトルを返す。未知のIDは無視。
## 特徴 8 軸は合算して 65535 でクリップ。出来 2 軸は算出方法が仕様で tbd; のため、
## 暫定で素材ごとの値を合算し、Balance.QUALITY_RAW_FULL で 255 になるよう縮める。
static func evaluate_components(ids: Array) -> PackedInt32Array:
	var raw := Metric.zeros()
	for id in ids:
		var spec = MasterData.components.get(id)
		if spec == null:
			continue
		var contribution: PackedInt32Array = spec["contribution"]
		for i in Metric.COUNT:
			raw[i] = mini(raw[i] + contribution[i], Metric.MAX_VALUE)
	for i in Metric.QUALITY_KEYS:
		raw[i] = clampi(roundi(raw[i] * Metric.QUALITY_MAX / Balance.QUALITY_RAW_FULL), 0, Metric.QUALITY_MAX)
	return raw


static func evaluate_recipe(recipe: Dictionary) -> PackedInt32Array:
	return evaluate_components(recipe_component_ids(recipe))


## レシピ内容から自動算出される一杯あたりの原価（spec/menu.md）。
static func recipe_cost(recipe: Dictionary) -> int:
	var total := 0
	for id in recipe_component_ids(recipe):
		var spec = MasterData.components.get(id)
		if spec != null:
			total += int(spec["cost"])
	return total


## 調理による出来 2 軸の減点。skill=1.0 なら減点なし（レシピが天井）。
static func apply_quality_penalty(base: PackedInt32Array, skill: float) -> PackedInt32Array:
	var result := base.duplicate()
	var factor := 1.0 - Balance.SKILL_QUALITY_PENALTY * (1.0 - clampf(skill, 0.0, 1.0))
	for i in Metric.QUALITY_KEYS:
		result[i] = clampi(roundi(base[i] * factor), 0, Metric.QUALITY_MAX)
	return result


## 一杯ごとの特徴 8 軸のブレ。skill が低いほどブレ幅が大きい。出来 2 軸は動かさない。
static func apply_cooking_noise(base: PackedInt32Array, skill: float, rng: RandomNumberGenerator) -> PackedInt32Array:
	var result := base.duplicate()
	for i in Metric.FEATURE_COUNT:
		var noise := rng.randfn(0.0, 1.0) * (1.0 - skill) * Balance.SKILL_NOISE
		result[i] = clampi(roundi(base[i] * (1.0 + noise)), 0, Metric.MAX_VALUE)
	return result


## 特徴 1 軸の近さ s_i = exp(-(d/σ)² / 2)。d = 一杯の値 - 理想値。
static func closeness(diff: float) -> float:
	var z := diff / Balance.SATISFACTION_SIGMA
	return exp(-0.5 * z * z)


## 顧客満足度（0〜1000）。spec/recipe.md ステップ5。
##   S = 800 × Σ(w_i × s_i) / Σ w_i + 創作性/255 × 100 + 調和性/255 × 100
static func matching_score(e: PackedInt32Array, h: PackedInt32Array, w: PackedFloat64Array) -> float:
	var sum := 0.0
	var weight_sum := 0.0
	for i in Metric.FEATURE_COUNT:
		sum += w[i] * closeness(e[i] - h[i])
		weight_sum += w[i]
	var near := 0.0 if weight_sum <= 0.0 else sum / weight_sum
	var score := Balance.FEATURE_POINTS * near
	for i in Metric.QUALITY_KEYS:
		score += Balance.QUALITY_POINTS * e[i] / float(Metric.QUALITY_MAX)
	return clampf(score, 0.0, Balance.SCORE_MAX)


## 評価と嗜好の差分から感想を作る。
## 不満は特徴 8 軸の重み付きの不満度 w_i × (1 - s_i) が大きい順、次に出来 2 軸の低いもの。
## 褒め言葉は重視する特徴の軸から、次に出来 2 軸の高いもの。
static func generate_comment(e: PackedInt32Array, h: PackedInt32Array, w: PackedFloat64Array) -> String:
	var deltas: Array[Dictionary] = []
	for i in Metric.FEATURE_COUNT:
		var diff := e[i] - h[i]
		var s := closeness(diff)
		deltas.append({"key": i, "diff": diff, "closeness": s, "weight": w[i], "score": (1.0 - s) * w[i]})

	var complaints: Array[String] = []
	deltas.sort_custom(func(a, b): return a["score"] > b["score"])
	for d in deltas:
		if complaints.size() >= 2:
			break
		if d["closeness"] < COMMENT_COMPLAINT_CLOSENESS:
			complaints.append(COMMENT_TEMPLATES[d["key"]][0 if d["diff"] < 0 else 1])
	for q in Metric.QUALITY_KEYS.size():
		if complaints.size() < 2 and e[Metric.QUALITY_KEYS[q]] < COMMENT_QUALITY_LOW:
			complaints.append(QUALITY_COMMENTS[q][0])

	var praises: Array[String] = []
	deltas.sort_custom(func(a, b): return a["weight"] > b["weight"])
	for d in deltas:
		if praises.size() >= 2:
			break
		if d["closeness"] >= COMMENT_PRAISE_CLOSENESS:
			praises.append(COMMENT_TEMPLATES[d["key"]][2])
	for q in Metric.QUALITY_KEYS.size():
		if praises.size() < 2 and e[Metric.QUALITY_KEYS[q]] >= COMMENT_QUALITY_HIGH:
			praises.append(QUALITY_COMMENTS[q][1])

	var parts: Array[String] = []
	if matching_score(e, h, w) >= COMMENT_PRAISE_SCORE:
		parts = praises if not praises.is_empty() else complaints
	elif not complaints.is_empty():
		parts = complaints
	else:
		parts = praises.slice(0, 1)

	if parts.is_empty():
		return "特に印象には残らなかった"
	return "、".join(parts)


## 評価値はプレイヤーに数値で見せない。軸ごとの強さを言葉にして返す。
static func describe(e: PackedInt32Array) -> Array[String]:
	var lines: Array[String] = []
	for i in Metric.COUNT:
		var word := level_word(e[i]) if Metric.is_feature(i) else quality_level_word(e[i])
		lines.append("%s：%s" % [Metric.LABELS[i], word])
	return lines


static func level_word(value: int) -> String:
	return _word(value, LEVEL_THRESHOLDS, LEVEL_WORDS)


static func quality_level_word(value: int) -> String:
	return _word(value, QUALITY_LEVEL_THRESHOLDS, QUALITY_LEVEL_WORDS)


static func _word(value: int, thresholds: Array[int], words: Array[String]) -> String:
	for i in thresholds.size():
		if value < thresholds[i]:
			return words[i]
	return words[words.size() - 1]


## 一番目立つ特徴 2 軸を使った一言紹介。
static func headline(e: PackedInt32Array) -> String:
	var order: Array[int] = []
	for i in Metric.FEATURE_COUNT:
		order.append(i)
	order.sort_custom(func(a, b): return e[a] > e[b])
	if e[order[0]] == 0:
		return "まだ何も入っていない"
	return "「%s」と「%s」が際立つ一杯" % [Metric.LABELS[order[0]], Metric.LABELS[order[1]]]


## 素材の特徴（寄与の大きい特徴 2 軸）。レシピ作成時のヒントに使う。
static func component_hint(id: String) -> String:
	var spec = MasterData.components.get(id)
	if spec == null:
		return ""
	var contribution: PackedInt32Array = spec["contribution"]
	var order: Array[int] = []
	for i in Metric.FEATURE_COUNT:
		if contribution[i] > 0:
			order.append(i)
	order.sort_custom(func(a, b): return contribution[a] > contribution[b])
	var names: Array[String] = []
	for i in order.slice(0, 2):
		names.append(Metric.LABELS[i])
	return "・".join(names)
