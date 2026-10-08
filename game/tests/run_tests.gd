extends SceneTree
## ロジックのテスト。
##   godot --headless --path game -s tests/run_tests.gd

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var _failures := 0
var _checks := 0


func _initialize() -> void:
	MasterData.ensure_loaded()
	for test in [
		"test_master_data", "test_matching_score", "test_satisfaction_matches_spec_example",
		"test_evaluate_recipe_matches_spec", "test_evaluate_ignores_unknown_and_clips",
		"test_quality_penalty", "test_cooking_noise_shrinks_with_skill", "test_comment",
		"test_recipe_cost",
		"test_economy", "test_simulation", "test_closed_slots_bring_nobody",
		"test_overpriced_menu_loses_customers", "test_run_day_and_save_roundtrip",
	]:
		var before := _failures
		call(test)
		print("%s %s" % ["ok  " if _failures == before else "FAIL", test])
	print("\n%d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, message: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("  ✗ " + message)


func spec_recipe() -> Dictionary:
	# spec/recipe.md の「黒香味油の濃厚鶏白湯」
	return {
		"id": "spec", "name": "黒香味油の濃厚鶏白湯",
		"noodle": "noodle-thick-high-water", "soup": "soup-tori-paitan",
		"tare": "tare-rich-soy", "oil": "oil-black-garlic",
		"toppings": ["topping-chashu", "topping-egg", "topping-green-onion"],
		"plating": "plating-black-radial",
	}


func new_state():
	var gs = GameStateScript.new()
	gs.save_path = "user://test_save.json"
	gs.location_id = "gakusei"
	return gs


func seeded(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_master_data() -> void:
	check(MasterData.customers.size() == 10, "顧客カテゴリは10種")
	check(MasterData.locations.size() >= 3, "立地が読み込まれている")
	for type in MasterData.COMPONENT_TYPES:
		check(MasterData.component_ids_by_type[type].size() >= 4, "%s が4種以上ある" % type)
	for loc in MasterData.locations:
		for cid in loc["customers"]:
			check(MasterData.customers_by_id.has(cid), "%s の客層 %s が存在する" % [loc["id"], cid])
	var gs = new_state()
	for id in Evaluation.recipe_component_ids(gs.recipes[0]):
		check(MasterData.components.has(id), "初期レシピの素材 %s が存在する" % id)
	gs.free()


## 特徴 8 軸 + 出来 2 軸のベクトルを作る。
func vec(features: Array, creative: int = 0, harmony: int = 0) -> PackedInt32Array:
	var v := PackedInt32Array(features)
	v.append(creative)
	v.append(harmony)
	return v


## 特徴 8 軸の重み。出来 2 軸の分は 0 で埋める（満足度の式では使わない）。
func weights(features: Array) -> PackedFloat64Array:
	var w := PackedFloat64Array(features)
	w.append(0.0)
	w.append(0.0)
	return w


func test_matching_score() -> void:
	var pref := vec([32000, 20000, 24000, 33000, 9000, 6000, 17000, 29000])
	var weight := weights([1.0, 0.8, 1.2, 1.0, 0.5, 0.5, 0.6, 1.0])
	check(is_equal_approx(Evaluation.matching_score(vec([32000, 20000, 24000, 33000, 9000, 6000, 17000, 29000], 255, 255), pref, weight), 1000.0),
		"特徴が完全一致で出来が最高なら 1000")
	check(is_equal_approx(Evaluation.matching_score(vec([32000, 20000, 24000, 33000, 9000, 6000, 17000, 29000]), pref, weight), 800.0),
		"特徴が完全一致で出来が 0 なら 800")
	var near := Evaluation.matching_score(vec([30000, 20000, 25000, 32000, 10000, 5000, 18000, 28000]), pref, weight)
	check(near > 750.0 and near < 800.0, "近い嗜好なら特徴分はほぼ満点: %f" % near)
	var far := Evaluation.matching_score(vec([0, 60000, 0, 0, 60000, 60000, 0, 0]), pref, weight)
	check(far < 10.0, "かけ離れていれば特徴分はほぼ 0: %f" % far)
	var base := vec([32000, 20000, 24000, 33000, 9000, 6000, 17000, 29000], 100, 100)
	var more := vec([32000, 20000, 24000, 33000, 9000, 6000, 17000, 29000], 200, 100)
	check(Evaluation.matching_score(more, pref, weight) > Evaluation.matching_score(base, pref, weight),
		"出来は高いほど良い")
	var heavy := PackedFloat64Array(weight)
	for i in Metric.FEATURE_COUNT:
		heavy[i] *= 3.0
	var off := vec([30000, 20000, 25000, 32000, 10000, 5000, 18000, 28000])
	check(is_equal_approx(Evaluation.matching_score(off, pref, heavy), Evaluation.matching_score(off, pref, weight)),
		"重みは相対配分：全体を大きくしても採点は辛くならない")
	check(is_equal_approx(Evaluation.closeness(Balance.SATISFACTION_SIGMA), exp(-0.5)), "1σ ずれで exp(-1/2)")


## spec/recipe.md「顧客満足度の算出」の例：大学生、σ=6000、創作性 90・調和性 94 で 829 点。
func test_satisfaction_matches_spec_example() -> void:
	var e := vec([35000, 17000, 17000, 32000, 8000, 3500, 12500, 12000], 90, 94)
	var h := vec([36000, 17000, 17000, 33000, 8000, 6000, 12000, 16000])
	var w := weights([1.0, 0.7, 0.6, 1.2, 0.4, 0.8, 0.4, 1.2])
	var score := Evaluation.matching_score(e, h, w)
	check(absf(score - 829.4) < 0.5, "仕様書の算出例は 829 点: %f" % score)


func test_evaluate_recipe_matches_spec() -> void:
	# 特徴 8 軸は仕様書の表の合計どおり。出来 2 軸は暫定の算出（素材の値の合算を 255 に縮める）
	var eval := Evaluation.evaluate_recipe(spec_recipe())
	var want := vec([35000, 17000, 17000, 32000, 8000, 3500, 12500, 12000], 57, 172)
	for i in Metric.COUNT:
		check(eval[i] == want[i], "%s: got %d, want %d" % [Metric.LABELS[i], eval[i], want[i]])


func test_evaluate_ignores_unknown_and_clips() -> void:
	var eval := Evaluation.evaluate_components(["no-such-id", "noodle-thin-straight"])
	check(eval[Metric.Key.UMAMI] == 4000, "未知のIDは無視される")
	var many := []
	for n in 10:
		many.append("soup-tonkotsu")
	var clipped := Evaluation.evaluate_components(many)
	check(clipped[Metric.Key.UMAMI] == Metric.MAX_VALUE, "特徴は 65535 でクリップ")
	check(clipped[Metric.Key.HARMONY] == Metric.QUALITY_MAX, "出来は 255 でクリップ")


func test_quality_penalty() -> void:
	var base := Evaluation.evaluate_recipe(spec_recipe())
	check(Evaluation.apply_quality_penalty(base, 1.0) == base, "skill=1.0 ならレシピどおり（良くはならない）")
	var low := Evaluation.apply_quality_penalty(base, 0.0)
	for i in Metric.FEATURE_COUNT:
		check(low[i] == base[i], "特徴 %s は減点されない" % Metric.LABELS[i])
	for i in Metric.QUALITY_KEYS:
		var want := roundi(base[i] * (1.0 - Balance.SKILL_QUALITY_PENALTY))
		check(low[i] == want, "出来 %s は減点される: got %d, want %d" % [Metric.LABELS[i], low[i], want])
	var mid := Evaluation.apply_quality_penalty(base, 0.5)
	check(mid[Metric.Key.HARMONY] > low[Metric.Key.HARMONY] and mid[Metric.Key.HARMONY] < base[Metric.Key.HARMONY],
		"技術が中くらいなら減点も中くらい")


func test_cooking_noise_shrinks_with_skill() -> void:
	var base := vec([30000, 30000, 30000, 30000, 30000, 30000, 30000, 30000], 200, 200)
	var rng := seeded(1)
	var low := 0.0
	var high := 0.0
	for n in 20:
		var a := Evaluation.apply_cooking_noise(base, 0.6, rng)
		var b := Evaluation.apply_cooking_noise(base, 0.98, rng)
		for i in Metric.FEATURE_COUNT:
			low += absf(a[i] - base[i])
			high += absf(b[i] - base[i])
		for i in Metric.QUALITY_KEYS:
			check(a[i] == base[i], "出来 2 軸はブレない")
	check(high < low, "高スキルの方がブレが小さい: low=%.0f high=%.0f" % [low, high])
	var perfect := Evaluation.apply_cooking_noise(base, 1.0, rng)
	check(perfect == base, "skill=1.0 ならブレない")


func test_comment() -> void:
	var pref := vec([30000, 30000, 30000, 30000, 30000, 30000, 30000, 30000])
	var weight := weights([0.5, 0.5, 0.5, 1.2, 0.5, 0.5, 1.0, 0.5])
	var eval := vec([30000, 30000, 30000, 50000, 30000, 30000, 45000, 30000], 128, 128)
	var comment := Evaluation.generate_comment(eval, pref, weight)
	check(comment.contains("脂") and comment.contains("見た目"), "ズレの大きい軸が感想に出る: " + comment)
	check(comment.begins_with("脂"), "重み付きの不満度が大きい順: " + comment)
	var praise := Evaluation.generate_comment(vec([30000, 30000, 30000, 30000, 30000, 30000, 30000, 30000], 128, 128), pref, weight)
	check(praise.contains("脂がちょうどよかった"), "合っていれば重視する軸を褒める: " + praise)
	var clumsy := Evaluation.generate_comment(vec([30000, 30000, 30000, 50000, 30000, 30000, 30000, 30000], 128, 20), pref, weight)
	check(clumsy == "脂っこすぎた、味のバランスが微妙だった", "出来が低ければ不満に出る: " + clumsy)
	# 特徴はどれも不満にも褒め言葉にもならない程度のずれ（4000）にしておく
	var fine := Evaluation.generate_comment(vec([34000, 34000, 34000, 34000, 34000, 34000, 34000, 34000], 230, 128), pref, weight)
	check(fine == "独創的で印象に残った", "出来が高ければ褒める（特徴の褒め言葉が足りないとき）: " + fine)


func test_recipe_cost() -> void:
	check(Evaluation.recipe_cost(spec_recipe()) == 60 + 110 + 20 + 25 + 90 + 40 + 15 + 15, "原価は素材の合計")


func test_economy() -> void:
	var cust: Dictionary = MasterData.customers_by_id["university"]
	check(is_equal_approx(Economy.payment_limit(cust, 50.0), 850.0), "評判50なら基本予算のまま")
	check(is_equal_approx(Economy.payment_limit(cust, 75.0), 850.0 * 1.25), "評判+25で上限 ×1.25")
	check(Economy.purchase_probability(800, 850, 1.0) == 1.0, "上限以内は必ず買う")
	check(Economy.purchase_probability(1100, 850, 1.0) == 0.0, "大きく超えると買わない")
	check(Economy.price_adjust(600, 850, 1.0) > 0.0 and Economy.price_adjust(950, 850, 1.0) < 0.0, "割安は加点・割高は減点")
	var loc := MasterData.location("gakusei")
	check(Economy.fixed_cost(loc, [false, true, true, true, false]) == roundi(4000 * 3.9), "固定費 = 家賃 × 係数合計")
	var office: Dictionary = MasterData.customers_by_id["office"]
	check(Economy.coverage(office, [false, false, false, false, true]) == 0.0, "会社員は深夜のみ営業だと来ない")
	check(is_equal_approx(Economy.coverage(office, [true, true, true, true, true]), 1.0), "全時間帯ならカバレッジ 1.0")
	check(Economy.reputation_delta(900.0, 20) > 0.0 and Economy.reputation_delta(400.0, 20) < 0.0, "満足度（1000 点満点）で評判が上下")
	check(Economy.reputation_delta(900.0, 0) == 0.0, "誰も食べていなければ評判は動かない")


func test_simulation() -> void:
	var gs = new_state()
	var a: Dictionary = DaySimulator.simulate(gs, seeded(42))
	var b: Dictionary = DaySimulator.simulate(gs, seeded(42))
	check(JSON.stringify(a) == JSON.stringify(b), "同じ seed なら同じ結果")
	check(a["served"] > 0, "初期状態でも客が来る: %d" % a["served"])
	check(a["profit"] == a["revenue"] - a["variable_cost"] - a["fixed_cost"], "利益 = 売上 - 原価 - 固定費")
	check(a["revenue"] == a["served"] * 750, "サイドなしなら売上 = 提供数 × 価格")
	var capacity := Economy.slot_capacity(gs.location())
	var from_slots := 0
	for slot in a["slots"]:
		check(slot["visitors"] <= capacity, "時間帯ごとの来客は席数×回転数まで")
		from_slots += slot["visitors"]
	check(from_slots == a["visitors"], "時間帯別の合計 = 来客数")
	check(a["visitors"] == a["served"] + a["lost_price"], "来客 = 提供 + 価格で帰った人")
	for cid in a["categories"]:
		var stat: Dictionary = a["categories"][cid]
		check(stat["rep_after"] >= 0.0 and stat["rep_after"] <= 100.0, "評判は 0〜100")
		if not gs.location()["customers"].has(cid):
			check(stat["visitors"] == 0, "立地にいない客層は来ない: " + cid)
	check(JSON.stringify(a) != "", "結果は JSON 化できる")

	# 評判が上がれば来客が増える
	var base_total := 0
	var high_total := 0
	for n in 20:
		base_total += DaySimulator.simulate(gs, seeded(n))["visitors"]
	for cid in gs.reputation:
		gs.reputation[cid] = 100.0
	for n in 20:
		high_total += DaySimulator.simulate(gs, seeded(n))["visitors"]
	check(high_total > base_total * 1.2, "評判100で来客増: %d → %d" % [base_total, high_total])

	# サイドメニューを出せば売上に乗る
	gs.sides["gyoza"]["enabled"] = true
	var with_side: Dictionary = DaySimulator.simulate(gs, seeded(42))
	check(with_side["revenue_side"] > 0, "サイドが売れる")
	gs.free()


func test_closed_slots_bring_nobody() -> void:
	var gs = new_state()
	gs.open_slots = [false, false, false, false, false]
	var result: Dictionary = DaySimulator.simulate(gs, seeded(7))
	check(result["visitors"] == 0 and result["fixed_cost"] == 0, "閉店中は来客も固定費もゼロ")
	check(gs.business_problem() != "", "営業時間なしは開店できない")
	gs.free()


func test_overpriced_menu_loses_customers() -> void:
	var gs = new_state()
	gs.menu[0]["price"] = 3000
	var result: Dictionary = DaySimulator.simulate(gs, seeded(3))
	check(result["served"] == 0 and result["lost_price"] > 0, "高すぎると誰も注文しない")
	gs.free()


func test_run_day_and_save_roundtrip() -> void:
	var gs = new_state()
	gs.money = 123456
	var id: String = gs.upsert_recipe(spec_recipe().merged({"id": ""}, true))
	check(id == "r1" and gs.recipes.size() == 2, "レシピ追加で id が振られる")
	check(gs.set_on_menu(id, true, 900), "メニューに追加できる")
	gs.buy_ad()
	var result: Dictionary = gs.run_day(0.1, seeded(5))
	check(gs.day == 2, "翌日に進む")
	check(gs.money == 123456 - Balance.AD_COST + result["profit"], "利益が所持金に反映される")
	check(gs.ad_days_left == Balance.AD_DAYS - 1, "宣伝の残り日数が減る")

	var loaded = GameStateScript.new()
	loaded.save_path = gs.save_path
	check(loaded.load_game(), "ロードできる")
	check(loaded.day == gs.day and loaded.money == gs.money, "日付と所持金が戻る")
	check(typeof(loaded.money) == TYPE_INT and typeof(loaded.menu[1]["price"]) == TYPE_INT, "整数は整数で戻る")
	# last_result は表示用で、JSON を通すと整数が float になる。それ以外は完全一致するはず
	var saved: Dictionary = gs.to_dict()
	var restored: Dictionary = loaded.to_dict()
	check(int(restored["last_result"]["profit"]) == result["profit"], "前日の結果が戻る")
	saved.erase("last_result")
	restored.erase("last_result")
	check(JSON.stringify(restored) == JSON.stringify(saved), "セーブ → ロードで内容が一致")
	var again: Dictionary = DaySimulator.simulate(loaded, seeded(9))
	check(again["served"] > 0, "ロード後も営業できる")

	loaded.delete_recipe(id)
	check(loaded.menu.size() == 1 and loaded.find_recipe(id) == null, "削除したレシピはメニューからも消える")
	loaded.delete_save()
	check(not loaded.has_save(), "セーブ削除")
	gs.free()
	loaded.free()
