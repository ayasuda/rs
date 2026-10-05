extends Screen
## G5 メニュー・価格設定シーン。spec/menu.md

const PRICE_STEP := 50
const PRICE_MIN := 300
const PRICE_MAX := 3000


func build() -> void:
	set_header("メニュー・価格", "dashboard")
	lbl(content, "ラーメンは%d品まで提供できます。お客さんは自分の好みと予算に合う一杯を選びます。" % GameState.MAX_MENU,
		UiTheme.FONT_SMALL, UiTheme.MUTED)

	heading(content, "ラーメン")
	for recipe in GameState.recipes:
		var box := card(content)
		var cost := Evaluation.recipe_cost(recipe)
		var entry = GameState.menu_entry(recipe["id"])
		lbl(box, recipe["name"], UiTheme.FONT_LARGE)
		var margin_label := lbl(box, "", UiTheme.FONT_SMALL, UiTheme.MUTED)
		toggle(box, "提供中" if entry != null else "提供する", entry != null, _on_ramen_toggled.bind(recipe["id"]))
		if entry != null:
			margin_label.text = _margin_text(cost, entry["price"])
			price_stepper(box, entry["price"], PRICE_STEP, PRICE_MIN, PRICE_MAX, func(value: int):
				entry["price"] = value
				margin_label.text = _margin_text(cost, value)
				GameState.save_game())
		else:
			margin_label.text = "原価 %s" % yen(cost)

	heading(content, "サイドメニュー")
	lbl(content, "ボリュームのあるラーメンほど、お腹に余裕がなくなってサイドは売れにくくなります。",
		UiTheme.FONT_SMALL, UiTheme.MUTED)
	for side in MasterData.sides:
		var box := card(content)
		var setting: Dictionary = GameState.sides[side["id"]]
		lbl(box, side["label"], UiTheme.FONT_LARGE)
		var margin_label := lbl(box, "", UiTheme.FONT_SMALL, UiTheme.MUTED)
		toggle(box, "提供中" if setting["enabled"] else "提供する", setting["enabled"], func(on: bool):
			setting["enabled"] = on
			GameState.save_game()
			rebuild())
		if setting["enabled"]:
			margin_label.text = _margin_text(side["cost"], setting["price"])
			price_stepper(box, setting["price"], PRICE_STEP, 50, 1500, func(value: int):
				setting["price"] = value
				margin_label.text = _margin_text(side["cost"], value)
				GameState.save_game())
		else:
			margin_label.text = "原価 %s" % yen(side["cost"])


func _margin_text(cost: int, price: int) -> String:
	return "原価 %s　／　一品あたりの粗利 %s" % [yen(cost), signed_yen(price - cost)]


func _on_ramen_toggled(on: bool, recipe_id: String) -> void:
	if not GameState.set_on_menu(recipe_id, on):
		notify("ラーメンは%d品までです。" % GameState.MAX_MENU)
	GameState.save_game()
	rebuild()
