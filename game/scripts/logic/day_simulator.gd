class_name DaySimulator
extends RefCounted
## 1日分の営業シミュレーション。来店 → 注文 → 調理 → 評価 → 集計。
## gs（GameState）は読むだけで、結果は JSON に保存できる Dictionary で返す。


static func simulate(gs, rng: RandomNumberGenerator, skill_bonus: float = 0.0) -> Dictionary:
	MasterData.ensure_loaded()
	var loc: Dictionary = MasterData.location(gs.location_id)
	var weather := _roll_weather(rng)
	var weekday: int = (gs.day - 1) % 7
	var weekend := weekday >= 5
	var skill := clampf(gs.cooking_skill + skill_bonus, 0.0, 1.0)

	# 実効流入率のうち全カテゴリ共通の補正：(1 + W) × (1 + M) × (1 + D) × (1 + A)
	var common: float = (1.0 + weather["w"]) \
		* (1.0 + (Balance.AD_BONUS if gs.ad_days_left > 0 else 0.0)) \
		* (1.0 + (Balance.WEEKEND_BONUS if weekend else 0.0)) \
		* (1.0 + Balance.INTERIOR_BONUS_PER_LEVEL * gs.interior_level)

	var items := _menu_items(gs, skill)
	var side_items := _side_items(gs)

	# カテゴリごとに、どのラーメンを選ぶか・買える確率を先に決めておく
	var plans := {}
	var categories := {}
	for cust in MasterData.customers:
		var cid: String = cust["id"]
		var rep: float = gs.reputation.get(cid, Balance.REP_INITIAL)
		var limit := Economy.payment_limit(cust, rep)
		var best := -1
		var best_value := -INF
		for i in items.size():
			var value: float = Evaluation.matching_score(items[i]["eval"], cust["pref"], cust["weight"]) \
				+ Economy.price_adjust(items[i]["price"], limit, cust["price_sensitivity"])
			if value > best_value:
				best_value = value
				best = i
		plans[cid] = {"item": best, "limit": limit, "rep": rep}
		categories[cid] = {
			"name": cust["name"], "visitors": 0, "served": 0, "lost_price": 0,
			"score_sum": 0.0, "avg_score": 0.0, "rep_before": rep, "rep_after": rep,
		}

	var revenue_ramen := 0
	var revenue_side := 0
	var variable_cost := 0
	var lost_full := 0
	var served_total := 0
	var sides_sold := {}
	var slots: Array[Dictionary] = []
	var samples: Array[Dictionary] = []  # コメント用に何人か抜き出す

	for s in Balance.SLOT_LABELS.size():
		if not gs.open_slots[s]:
			continue
		# 来客数[c] = 潜在顧客数[c] × 実効流入率[c]（この時間帯の分）
		var arrivals: Array[String] = []
		for cust in MasterData.customers:
			var cid: String = cust["id"]
			var pool = loc["customers"].get(cid)
			if pool == null:
				continue
			var rhythm: Array = cust["rhythm"]
			var rhythm_total := 0.0
			for v in rhythm:
				rhythm_total += v
			if rhythm_total <= 0.0 or rhythm[s] <= 0.0:
				continue
			var day_mult: float = cust["weekend_mult"] if weekend else cust["weekday_mult"]
			var demand: float = pool["potential"] * pool["base_rate"] \
				* (1.0 + Economy.reputation_bonus(plans[cid]["rep"])) \
				* common * day_mult * (rhythm[s] / rhythm_total)
			for n in _stochastic_round(demand, rng):
				arrivals.append(cid)

		# 席数を超えた分は入れずに帰る
		_shuffle(arrivals, rng)
		var capacity := Economy.slot_capacity(loc)
		if arrivals.size() > capacity:
			lost_full += arrivals.size() - capacity
			arrivals.resize(capacity)

		for cid in arrivals:
			var cust: Dictionary = MasterData.customers_by_id[cid]
			var plan: Dictionary = plans[cid]
			var stat: Dictionary = categories[cid]
			stat["visitors"] += 1
			if plan["item"] < 0:
				stat["lost_price"] += 1
				continue
			var item: Dictionary = items[plan["item"]]
			var limit: float = plan["limit"]
			var sensitivity: float = cust["price_sensitivity"]
			if rng.randf() > Economy.purchase_probability(item["price"], limit, sensitivity):
				stat["lost_price"] += 1
				continue

			var cooked := Evaluation.apply_cooking_noise(item["eval"], skill, rng)
			var price_adj := Economy.price_adjust(item["price"], limit, sensitivity)
			var score := clampf(
				Evaluation.matching_score(cooked, cust["pref"], cust["weight"]) + price_adj, 0.0, 100.0)
			stat["served"] += 1
			stat["score_sum"] += score
			served_total += 1
			item["sold"] += 1
			revenue_ramen += item["price"]
			variable_cost += item["cost"]

			# 満腹消費量 = ラーメンのボリューム感 + サイドメニューのボリューム感 ≤ 満腹度
			var room: float = cust["fullness"] - cooked[Metric.Key.VOLUME] / Balance.FULLNESS_DIVISOR
			var side := _pick_side(side_items, room, item["price"], limit, cust, rng)
			if not side.is_empty():
				revenue_side += side["price"]
				variable_cost += side["cost"]
				sides_sold[side["label"]] = sides_sold.get(side["label"], 0) + 1

			_reservoir_add(samples, {
				"cid": cid, "cooked": cooked, "score": score,
				"price_adj": price_adj, "recipe": item["name"],
			}, served_total, rng)

		slots.append({"slot": s, "label": Balance.SLOT_LABELS[s], "visitors": arrivals.size()})

	# 評価 → 評判：カテゴリ別の平均満足度で評判スコアが動く
	var visitors_total := 0
	var lost_price_total := 0
	for cid in categories:
		var stat: Dictionary = categories[cid]
		visitors_total += stat["visitors"]
		lost_price_total += stat["lost_price"]
		if stat["served"] > 0:
			stat["avg_score"] = stat["score_sum"] / stat["served"]
			stat["rep_after"] = clampf(
				stat["rep_before"] + Economy.reputation_delta(stat["avg_score"], stat["served"]),
				0.0, 100.0)

	var comments: Array[Dictionary] = []
	for sample in samples:
		var cust: Dictionary = MasterData.customers_by_id[sample["cid"]]
		var text := Evaluation.generate_comment(sample["cooked"], cust["pref"], cust["weight"])
		if sample["price_adj"] <= -3.0:
			text += "、値段は高く感じた"
		elif sample["price_adj"] >= 3.0:
			text += "、この値段ならお得"
		comments.append({
			"customer": cust["name"], "recipe": sample["recipe"],
			"label": Economy.satisfaction_label(sample["score"]), "text": text,
		})

	var sold := []
	for item in items:
		sold.append({"name": item["name"], "price": item["price"], "sold": item["sold"]})

	var fixed_cost := Economy.fixed_cost(loc, gs.open_slots)
	var revenue := revenue_ramen + revenue_side
	return {
		"day": gs.day,
		"weekday": weekday,
		"weather": weather["label"],
		"skill": skill,
		"skill_bonus": skill_bonus,
		"slots": slots,
		"categories": categories,
		"visitors": visitors_total,
		"served": served_total,
		"lost_full": lost_full,
		"lost_price": lost_price_total,
		"revenue": revenue,
		"revenue_ramen": revenue_ramen,
		"revenue_side": revenue_side,
		"variable_cost": variable_cost,
		"fixed_cost": fixed_cost,
		"profit": revenue - variable_cost - fixed_cost,
		"sold": sold,
		"sides_sold": sides_sold,
		"comments": comments,
	}


static func _menu_items(gs, skill: float) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for entry in gs.menu:
		var recipe = gs.find_recipe(entry["recipe_id"])
		if recipe == null:
			continue
		items.append({
			"name": recipe["name"],
			"price": int(entry["price"]),
			"cost": Evaluation.recipe_cost(recipe),
			"eval": Evaluation.apply_skill_boost(Evaluation.evaluate_recipe(recipe), skill),
			"sold": 0,
		})
	return items


static func _side_items(gs) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for side in MasterData.sides:
		var setting = gs.sides.get(side["id"])
		if setting == null or not setting["enabled"]:
			continue
		items.append({
			"label": side["label"], "cost": side["cost"],
			"volume": side["volume"], "price": int(setting["price"]),
		})
	return items


## 満腹度と予算の残りに収まるサイドを最大1品選ぶ。買わなければ空の辞書。
static func _pick_side(side_items: Array[Dictionary], room: float, ramen_price: int,
		limit: float, cust: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if side_items.is_empty() or rng.randf() > cust["side_affinity"]:
		return {}
	var candidates: Array[Dictionary] = []
	for side in side_items:
		if side["volume"] <= room:
			candidates.append(side)
	if candidates.is_empty():
		return {}
	var side: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var total: float = ramen_price + side["price"]
	if rng.randf() > Economy.purchase_probability(total, limit, cust["price_sensitivity"]):
		return {}
	return side


static func _roll_weather(rng: RandomNumberGenerator) -> Dictionary:
	var roll := rng.randf()
	var acc := 0.0
	for weather in Balance.WEATHERS:
		acc += weather["prob"]
		if roll < acc:
			return weather
	return Balance.WEATHERS[0]


## 端数を確率で切り上げる（期待値が demand と一致する）。
static func _stochastic_round(value: float, rng: RandomNumberGenerator) -> int:
	var base := floori(value)
	return base + (1 if rng.randf() < value - base else 0)


static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


static func _reservoir_add(samples: Array[Dictionary], sample: Dictionary, seen: int,
		rng: RandomNumberGenerator) -> void:
	if samples.size() < Balance.RESULT_COMMENTS:
		samples.append(sample)
		return
	var j := rng.randi_range(0, seen - 1)
	if j < Balance.RESULT_COMMENTS:
		samples[j] = sample
