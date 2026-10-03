extends Screen
## B1 レシピノートシーン（一覧）＋ B2 レシピ詳細。spec/scenes/recipe_note.md

var _selected := ""


func build() -> void:
	if _selected == "":
		_selected = str(GameState.nav_args.get("selected", ""))
		GameState.nav_args = {}
	var recipe = GameState.find_recipe(_selected)
	if recipe == null:
		_selected = ""
		_build_list()
	else:
		_build_detail(recipe)


func _build_list() -> void:
	set_header("レシピノート", "dashboard")
	lbl(content, "もくじ（%d / %d）" % [GameState.recipes.size(), GameState.MAX_RECIPES],
		UiTheme.FONT_SMALL, UiTheme.MUTED)
	for recipe in GameState.recipes:
		var on_menu: bool = GameState.menu_entry(recipe["id"]) != null
		var text := "%s%s\n原価 %s" % [
			recipe["name"], "　［提供中］" if on_menu else "", yen(Evaluation.recipe_cost(recipe))]
		var button := btn(content, text, _select.bind(recipe["id"]))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var add := btn(content, "＋ 新しいレシピを考える", goto.bind("recipe_edit"), true)
	add.disabled = GameState.recipes.size() >= GameState.MAX_RECIPES


func _build_detail(recipe: Dictionary) -> void:
	set_header("レシピ詳細")
	var eval := Evaluation.evaluate_recipe(recipe)

	var box := card(content)
	heading(box, recipe["name"])
	lbl(box, Evaluation.headline(eval), 0, UiTheme.MUTED)
	pair(box, "原価", yen(Evaluation.recipe_cost(recipe)))
	var entry = GameState.menu_entry(recipe["id"])
	pair(box, "販売", "提供中 %s" % yen(entry["price"]) if entry != null else "メニュー外")

	var parts := card(content)
	lbl(parts, "構成", 0, UiTheme.GOLD)
	for key in ["noodle", "soup", "tare", "oil"]:
		pair(parts, MasterData.COMPONENT_TYPE_LABELS[key], MasterData.component_label(recipe[key]))
	var toppings: Array[String] = []
	for id in recipe["toppings"]:
		toppings.append(MasterData.component_label(id))
	pair(parts, "具材", "なし" if toppings.is_empty() else "\n".join(toppings))
	pair(parts, "盛り付け", MasterData.component_label(recipe["plating"]))

	var taste := card(content)
	lbl(taste, "味の印象", 0, UiTheme.GOLD)
	var grid := GridContainer.new()
	grid.columns = 2
	taste.add_child(grid)
	for line in Evaluation.describe(eval):
		lbl(grid, line, UiTheme.FONT_SMALL)

	if recipe.get("locked", false):
		lbl(content, "先代から受け継いだレシピ。書き換えたり捨てたりはできない。",
			UiTheme.FONT_SMALL, UiTheme.MUTED)
	else:
		btn(footer, "編集する", goto.bind("recipe_edit", {"recipe_id": recipe["id"]}), true)
		btn(footer, "削除する", _on_delete.bind(recipe))
	btn(footer, "もくじに戻る", _select.bind(""))


func _select(id: String) -> void:
	_selected = id
	rebuild()


func _on_delete(recipe: Dictionary) -> void:
	confirm("「%s」を削除しますか？" % recipe["name"], func():
		GameState.delete_recipe(recipe["id"])
		_select(""))
