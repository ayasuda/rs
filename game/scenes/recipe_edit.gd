extends Screen
## B3 ラーメンレシピ作成シーン。構成要素を組み合わせて試作・保存する。

var _draft := {}
var _name_edit: LineEdit
var _preview: VBoxContainer


func build() -> void:
	var editing_id := str(GameState.nav_args.get("recipe_id", ""))
	GameState.nav_args = {}
	var source = GameState.find_recipe(editing_id)
	if source != null:
		_draft = source.duplicate(true)
	else:
		_draft = {"id": "", "name": "", "toppings": [], "locked": false}
		for type in ["noodle", "soup", "tare", "oil", "plating"]:
			_draft[type] = MasterData.component_ids_by_type[type][0]

	set_header("レシピ作成", "recipe_note")
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "ラーメンの名前"
	_name_edit.text = _draft["name"]
	_name_edit.max_length = 20
	_name_edit.custom_minimum_size.y = 72
	content.add_child(_name_edit)

	for type in ["noodle", "soup", "tare", "oil"]:
		_build_single_choice(type)
	_build_toppings()
	_build_single_choice("plating")

	_preview = card(footer)
	_refresh_preview()
	btn(footer, "この内容で保存する", _on_save, true)


func _component_text(id: String) -> String:
	var spec: Dictionary = MasterData.components[id]
	var hint := Evaluation.component_hint(id)
	return "%s\n%s%s" % [spec["label"], yen(spec["cost"]), "" if hint == "" else "・" + hint]


func _build_single_choice(type: String) -> void:
	var box := card(content)
	lbl(box, MasterData.COMPONENT_TYPE_LABELS[type], 0, UiTheme.GOLD)
	var flow := HFlowContainer.new()
	box.add_child(flow)
	var group := ButtonGroup.new()
	for id in MasterData.component_ids_by_type[type]:
		var button := toggle(flow, _component_text(id), _draft[type] == id, func(on: bool):
			if on:
				_draft[type] = id
				_refresh_preview())
		button.button_group = group
		button.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)


func _build_toppings() -> void:
	var box := card(content)
	lbl(box, "具材（%d種まで）" % GameState.MAX_TOPPINGS, 0, UiTheme.GOLD)
	var flow := HFlowContainer.new()
	box.add_child(flow)
	for id in MasterData.component_ids_by_type["topping"]:
		var button := toggle(flow, _component_text(id), _draft["toppings"].has(id), func(_on: bool): pass)
		button.add_theme_font_size_override("font_size", UiTheme.FONT_SMALL)
		button.toggled.connect(_on_topping_toggled.bind(id, button))


func _on_topping_toggled(on: bool, id: String, button: Button) -> void:
	var toppings: Array = _draft["toppings"]
	if not on:
		toppings.erase(id)
	elif toppings.size() >= GameState.MAX_TOPPINGS:
		button.set_pressed_no_signal(false)
		notify("具材は%d種までです。" % GameState.MAX_TOPPINGS)
		return
	else:
		toppings.append(id)
	_refresh_preview()


func _refresh_preview() -> void:
	for child in _preview.get_children():
		_preview.remove_child(child)
		child.queue_free()
	var eval := Evaluation.evaluate_recipe(_draft)
	pair(_preview, "原価", yen(Evaluation.recipe_cost(_draft)))
	lbl(_preview, Evaluation.headline(eval), UiTheme.FONT_SMALL, UiTheme.MUTED)
	var grid := GridContainer.new()
	grid.columns = 2
	_preview.add_child(grid)
	for line in Evaluation.describe(eval):
		lbl(grid, line, UiTheme.FONT_SMALL)


func _on_save() -> void:
	var recipe_name := _name_edit.text.strip_edges()
	if recipe_name == "":
		notify("ラーメンの名前を入れてください。")
		return
	_draft["name"] = recipe_name
	var id: String = GameState.upsert_recipe(_draft)
	goto("recipe_note", {"selected": id})
