extends Node
## ゲーム進行データの保持とセーブ／ロード（autoload: GameState）。

const SAVE_VERSION := 1
const MAX_RECIPES := 50
const MAX_MENU := 3
const MAX_TOPPINGS := 4
const HISTORY_DAYS := 30

var save_path := "user://save.json"

var day := 1
var money := 0
var location_id := ""
var open_slots: Array = []
var recipes: Array = []       # [{id, name, noodle, soup, tare, oil, toppings, plating, locked}]
var menu: Array = []          # [{recipe_id, price}]
var sides := {}               # side_id -> {enabled, price}
var reputation := {}          # customer_id -> 0〜100
var interior_level := 0
var ad_days_left := 0
var cooking_skill := 0.0
var total_served := {}        # customer_id -> 累計提供数
var history: Array = []       # [{day, profit, served}]
var last_result := {}
var game_over := false
var next_recipe_seq := 1

# 画面遷移時の引数（保存しない）
var nav_args := {}


func _init() -> void:
	MasterData.ensure_loaded()
	reset()


func reset() -> void:
	day = 1
	money = Balance.START_MONEY
	location_id = ""
	open_slots = Balance.DEFAULT_OPEN_SLOTS.duplicate()
	recipes = [{
		"id": "r0",
		"name": "先代の醤油ラーメン",
		"noodle": "noodle-curly-medium",
		"soup": "soup-shoyu-clear",
		"tare": "tare-rich-soy",
		"oil": "oil-chicken",
		"toppings": ["topping-chashu", "topping-menma", "topping-green-onion"],
		"plating": "plating-white-classic",
		"locked": true,
	}]
	menu = [{"recipe_id": "r0", "price": 750}]
	sides = {}
	for side in MasterData.sides:
		sides[side["id"]] = {"enabled": false, "price": side["price"]}
	reputation = {}
	total_served = {}
	for cust in MasterData.customers:
		reputation[cust["id"]] = Balance.REP_INITIAL
		total_served[cust["id"]] = 0
	interior_level = 0
	ad_days_left = 0
	cooking_skill = Balance.START_SKILL
	history = []
	last_result = {}
	game_over = false
	next_recipe_seq = 1
	nav_args = {}


# --- 参照 ---

func weekday() -> int:
	return (day - 1) % 7


func location() -> Dictionary:
	return MasterData.location(location_id)


func fixed_cost() -> int:
	return Economy.fixed_cost(location(), open_slots)


func find_recipe(id: String):
	for recipe in recipes:
		if recipe["id"] == id:
			return recipe
	return null


func menu_entry(recipe_id: String):
	for entry in menu:
		if entry["recipe_id"] == recipe_id:
			return entry
	return null


## 営業を始められない理由。問題なければ空文字。
func business_problem() -> String:
	if location_id == "":
		return "店舗が決まっていません。"
	if menu.is_empty():
		return "メニューにラーメンがありません。「メニュー・価格」で提供するレシピを選んでください。"
	if not open_slots.has(true):
		return "営業時間が設定されていません。"
	return ""


# --- 操作 ---

func contract_location(id: String) -> void:
	var loc := MasterData.location(id)
	money -= int(loc["deposit"])
	location_id = id
	# 評判は立地ごとのものなので、移転したら振り出しに戻る
	for cid in reputation:
		reputation[cid] = Balance.REP_INITIAL
	save_game()


## 新規なら追加、既存なら上書き。保存したレシピの id を返す。
func upsert_recipe(recipe: Dictionary) -> String:
	recipe["locked"] = bool(recipe.get("locked", false))
	if str(recipe.get("id", "")) == "":
		recipe["id"] = "r%d" % next_recipe_seq
		next_recipe_seq += 1
		recipes.append(recipe)
	else:
		for i in recipes.size():
			if recipes[i]["id"] == recipe["id"]:
				recipes[i] = recipe
	save_game()
	return recipe["id"]


func delete_recipe(id: String) -> void:
	recipes = recipes.filter(func(r): return r["id"] != id)
	menu = menu.filter(func(e): return e["recipe_id"] != id)
	save_game()


func set_on_menu(recipe_id: String, enabled: bool, price: int = 800) -> bool:
	var entry = menu_entry(recipe_id)
	if enabled:
		if entry != null:
			return true
		if menu.size() >= MAX_MENU:
			return false
		menu.append({"recipe_id": recipe_id, "price": price})
	elif entry != null:
		menu.erase(entry)
	return true


func upgrade_interior() -> bool:
	if interior_level >= Balance.INTERIOR_COSTS.size():
		return false
	var cost := Balance.INTERIOR_COSTS[interior_level]
	if money < cost:
		return false
	money -= cost
	interior_level += 1
	save_game()
	return true


func buy_ad() -> bool:
	if money < Balance.AD_COST:
		return false
	money -= Balance.AD_COST
	ad_days_left = Balance.AD_DAYS
	save_game()
	return true


func buy_training() -> bool:
	if money < Balance.TRAINING_COST or cooking_skill >= 1.0:
		return false
	money -= Balance.TRAINING_COST
	cooking_skill = minf(1.0, cooking_skill + Balance.TRAINING_GAIN)
	save_game()
	return true


## 1日営業して結果を反映し、翌日に進める。
func run_day(skill_bonus: float = 0.0, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var result := DaySimulator.simulate(self, rng, skill_bonus)

	money += int(result["profit"])
	for cid in result["categories"]:
		var stat: Dictionary = result["categories"][cid]
		reputation[cid] = stat["rep_after"]
		total_served[cid] = int(total_served.get(cid, 0)) + int(stat["served"])
	ad_days_left = maxi(0, ad_days_left - 1)
	cooking_skill = minf(1.0, cooking_skill + Balance.SKILL_GROWTH_PER_DAY)
	history.append({"day": day, "profit": result["profit"], "served": result["served"]})
	if history.size() > HISTORY_DAYS:
		history = history.slice(history.size() - HISTORY_DAYS)
	last_result = result
	day += 1
	game_over = money < Balance.BANKRUPT_LINE
	save_game()
	return result


# --- セーブ／ロード ---

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)


func save_game() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("セーブに失敗: %s" % save_path)
		return false
	file.store_string(JSON.stringify(to_dict(), "  "))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data == null or not (data is Dictionary):
		push_error("セーブデータが壊れています: %s" % save_path)
		return false
	from_dict(data)
	return true


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"day": day,
		"money": money,
		"location_id": location_id,
		"open_slots": open_slots,
		"recipes": recipes,
		"menu": menu,
		"sides": sides,
		"reputation": reputation,
		"interior_level": interior_level,
		"ad_days_left": ad_days_left,
		"cooking_skill": cooking_skill,
		"total_served": total_served,
		"history": history,
		"last_result": last_result,
		"game_over": game_over,
		"next_recipe_seq": next_recipe_seq,
	}


## JSON は数値がすべて float で返ってくるので、整数は明示的に戻す。
func from_dict(data: Dictionary) -> void:
	reset()
	day = int(data.get("day", 1))
	money = int(data.get("money", Balance.START_MONEY))
	location_id = str(data.get("location_id", ""))
	var slots: Array = data.get("open_slots", [])
	if slots.size() == Balance.SLOT_LABELS.size():
		open_slots = []
		for v in slots:
			open_slots.append(bool(v))

	recipes = []
	for raw in data.get("recipes", []):
		var toppings: Array = []
		for t in raw.get("toppings", []):
			toppings.append(str(t))
		recipes.append({
			"id": str(raw["id"]),
			"name": str(raw["name"]),
			"noodle": str(raw.get("noodle", "")),
			"soup": str(raw.get("soup", "")),
			"tare": str(raw.get("tare", "")),
			"oil": str(raw.get("oil", "")),
			"toppings": toppings,
			"plating": str(raw.get("plating", "")),
			"locked": bool(raw.get("locked", false)),
		})
	menu = []
	for raw in data.get("menu", []):
		if find_recipe(str(raw["recipe_id"])) != null:
			menu.append({"recipe_id": str(raw["recipe_id"]), "price": int(raw["price"])})
	var saved_sides: Dictionary = data.get("sides", {})
	for id in sides:
		if saved_sides.has(id):
			sides[id] = {
				"enabled": bool(saved_sides[id]["enabled"]),
				"price": int(saved_sides[id]["price"]),
			}
	var saved_rep: Dictionary = data.get("reputation", {})
	var saved_served: Dictionary = data.get("total_served", {})
	for cid in reputation:
		reputation[cid] = float(saved_rep.get(cid, Balance.REP_INITIAL))
		total_served[cid] = int(saved_served.get(cid, 0))
	interior_level = int(data.get("interior_level", 0))
	ad_days_left = int(data.get("ad_days_left", 0))
	cooking_skill = float(data.get("cooking_skill", Balance.START_SKILL))
	history = []
	for raw in data.get("history", []):
		history.append({"day": int(raw["day"]), "profit": int(raw["profit"]), "served": int(raw["served"])})
	last_result = data.get("last_result", {})
	game_over = bool(data.get("game_over", false))
	next_recipe_seq = int(data.get("next_recipe_seq", 1))
