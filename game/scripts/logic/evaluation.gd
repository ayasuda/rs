class_name Evaluation
extends RefCounted
## レシピの評価ベクトル算出と顧客マッチング（spec/recipe.md）。

# 軸ごとの感想：[足りない, 多すぎる, ちょうどいい]
const COMMENT_TEMPLATES: Array[Array] = [
	["旨味が物足りない", "旨味が強すぎてくどい", "旨味がしっかりしていた"],
	["香りが控えめだった", "香りが強すぎた", "香りが立っていた"],
	["味が薄めだった", "しょっぱかった", "ちょうどいい塩加減だった"],
	["もう少しこってりでも良かった", "脂っこすぎた", "脂がちょうどよかった"],
	["甘味が感じられなかった", "甘さが気になった", "甘味がほのかに良かった"],
	["刺激が足りない", "辛すぎた", "刺激的でクセになる味"],
	["個性が弱かった", "奇抜すぎてついていけない", "独創的で印象に残った"],
	["見た目が少し地味だった", "見た目が派手すぎて落ち着かない", "盛り付けが美しかった"],
	["量が少し物足りない", "量が多すぎて食べきれない", "ボリュームがちょうどよかった"],
	["味のバランスが微妙だった", "まとまりすぎて印象が薄い", "全体の調和が取れていた"],
]
const COMMENT_COMPLAINT_DIFF := 5000  # これ以上ズレた軸は不満として出る
const COMMENT_PRAISE_DIFF := 3000     # これ未満なら褒められる
const COMMENT_PRAISE_SCORE := 80.0

const LEVEL_THRESHOLDS: Array[int] = [4000, 12000, 22000, 32000]
const LEVEL_WORDS: Array[String] = ["ほぼなし", "控えめ", "ほどほど", "しっかり", "強烈"]


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


## 各構成要素の寄与値を合算して評価ベクトル（10軸）を返す。未知のIDは無視。
static func evaluate_components(ids: Array) -> PackedInt32Array:
	var result := Metric.zeros()
	for id in ids:
		var spec = MasterData.components.get(id)
		if spec == null:
			continue
		var contribution: PackedInt32Array = spec["contribution"]
		for i in Metric.COUNT:
			result[i] = mini(result[i] + contribution[i], Metric.MAX_VALUE)
	return result


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


## 調理技術によるブースト。skill=1.0 で全軸 +3%、調和性はさらに +5%。
static func apply_skill_boost(base: PackedInt32Array, skill: float) -> PackedInt32Array:
	var result := Metric.zeros()
	for i in Metric.COUNT:
		var factor := 1.0 + Balance.SKILL_BOOST * skill
		if i == Metric.Key.HARMONY:
			factor += Balance.SKILL_HARMONY_BOOST * skill
		result[i] = clampi(roundi(base[i] * factor), 0, Metric.MAX_VALUE)
	return result


## 一杯ごとの仕上がりのブレ。skill が低いほどブレ幅が大きい。
static func apply_cooking_noise(base: PackedInt32Array, skill: float, rng: RandomNumberGenerator) -> PackedInt32Array:
	var result := Metric.zeros()
	for i in Metric.COUNT:
		var noise := rng.randfn(0.0, 1.0) * (1.0 - skill) * Balance.SKILL_NOISE
		result[i] = clampi(roundi(base[i] * (1.0 + noise)), 0, Metric.MAX_VALUE)
	return result


## 顧客満足度スコア（0〜100）。
##   S = Σ w_i × (D - |r_i - h_i|) を Σ w_i × D で正規化する。
static func matching_score(e: PackedInt32Array, h: PackedInt32Array, w: PackedFloat64Array) -> float:
	var sum := 0.0
	var weight_sum := 0.0
	for i in Metric.COUNT:
		sum += w[i] * (Balance.SCORE_RANGE - absf(e[i] - h[i]))
		weight_sum += w[i]
	if weight_sum <= 0.0:
		return 0.0
	return clampf(sum / (weight_sum * Balance.SCORE_RANGE) * 100.0, 0.0, 100.0)


## 評価と嗜好の差分から感想を作る。重み付き差分が大きい軸ほど先に出る。
static func generate_comment(e: PackedInt32Array, h: PackedInt32Array, w: PackedFloat64Array) -> String:
	var deltas: Array[Dictionary] = []
	for i in Metric.COUNT:
		var diff := e[i] - h[i]
		deltas.append({"key": i, "diff": diff, "weight": w[i], "score": absf(diff) * w[i]})

	var complaints: Array[String] = []
	deltas.sort_custom(func(a, b): return a["score"] > b["score"])
	for d in deltas:
		if complaints.size() >= 2:
			break
		if d["diff"] <= -COMMENT_COMPLAINT_DIFF:
			complaints.append(COMMENT_TEMPLATES[d["key"]][0])
		elif d["diff"] >= COMMENT_COMPLAINT_DIFF:
			complaints.append(COMMENT_TEMPLATES[d["key"]][1])

	var praises: Array[String] = []
	deltas.sort_custom(func(a, b): return a["weight"] > b["weight"])
	for d in deltas:
		if praises.size() >= 2:
			break
		if absi(d["diff"]) < COMMENT_PRAISE_DIFF:
			praises.append(COMMENT_TEMPLATES[d["key"]][2])

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
		lines.append("%s：%s" % [Metric.LABELS[i], level_word(e[i])])
	return lines


static func level_word(value: int) -> String:
	for i in LEVEL_THRESHOLDS.size():
		if value < LEVEL_THRESHOLDS[i]:
			return LEVEL_WORDS[i]
	return LEVEL_WORDS[LEVEL_WORDS.size() - 1]


## 一番目立つ2軸を使った一言紹介。
static func headline(e: PackedInt32Array) -> String:
	var order: Array[int] = []
	for i in Metric.COUNT:
		if i != Metric.Key.HARMONY:
			order.append(i)
	order.sort_custom(func(a, b): return e[a] > e[b])
	if e[order[0]] == 0:
		return "まだ何も入っていない"
	return "「%s」と「%s」が際立つ一杯" % [Metric.LABELS[order[0]], Metric.LABELS[order[1]]]


## 素材の特徴（寄与の大きい2軸）。レシピ作成時のヒントに使う。
static func component_hint(id: String) -> String:
	var spec = MasterData.components.get(id)
	if spec == null:
		return ""
	var contribution: PackedInt32Array = spec["contribution"]
	var order: Array[int] = []
	for i in Metric.COUNT:
		if contribution[i] > 0:
			order.append(i)
	order.sort_custom(func(a, b): return contribution[a] > contribution[b])
	var names: Array[String] = []
	for i in order.slice(0, 2):
		names.append(Metric.LABELS[i])
	return "・".join(names)
