class_name Screen
extends Control
## 各シーン共通の画面枠（ヘッダー／スクロールする本文／フッター）。
## UI はコードで組み立てる。各シーンは build() をオーバーライドする。

var content: VBoxContainer
var footer: VBoxContainer
var _header: HBoxContainer


func _ready() -> void:
	MasterData.ensure_loaded()
	theme = UiTheme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	_header = HBoxContainer.new()
	root.add_child(_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	footer = VBoxContainer.new()
	root.add_child(footer)

	build()


## 画面の中身を組み立てる。各シーンで実装する。
func build() -> void:
	pass


## 状態が変わったときに画面を作り直す。
func rebuild() -> void:
	for box in [_header, content, footer]:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
	build()


func goto(scene: String, args: Dictionary = {}) -> void:
	GameState.nav_args = args
	get_tree().change_scene_to_file.call_deferred("res://scenes/%s.tscn" % scene)


# --- 部品 ---

func set_header(title: String, back_scene: String = "") -> void:
	if back_scene != "":
		var back := btn(_header, "＜ 戻る", func(): goto(back_scene))
		back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var label := lbl(_header, title, UiTheme.FONT_TITLE, UiTheme.GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if back_scene != "" else HORIZONTAL_ALIGNMENT_LEFT
	_header.visible = title != "" or back_scene != ""


func lbl(parent: Node, text: String, font_size: int = 0, color = null) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)
	if color != null:
		label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func heading(parent: Node, text: String) -> Label:
	return lbl(parent, text, UiTheme.FONT_LARGE, UiTheme.GOLD)


func btn(parent: Node, text: String, on_pressed: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 76
	if primary:
		button.theme_type_variation = "PrimaryButton"
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button


## ON/OFF を切り替えるボタン。ON のときアクセント色になる。
func toggle(parent: Node, text: String, pressed: bool, on_toggled: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_pressed = pressed
	button.custom_minimum_size.y = 68
	button.toggled.connect(on_toggled)
	parent.add_child(button)
	return button


## 枠つきのまとまり。返り値の VBox に中身を足していく。
func card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	return box


func row(parent: Node) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(box)
	return box


## 「項目名 ……… 値」の1行。
func pair(parent: Node, key: String, value: String, value_color = null) -> void:
	var box := row(parent)
	# 項目名は折り返さず、残りの幅を値に使う
	var k := lbl(box, key, 0, UiTheme.MUTED)
	k.autowrap_mode = TextServer.AUTOWRAP_OFF
	k.size_flags_horizontal = Control.SIZE_FILL
	var v := lbl(box, value, 0, value_color)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func spacer(parent: Node, height: float) -> void:
	var s := Control.new()
	s.custom_minimum_size.y = height
	parent.add_child(s)


## [−] ¥800 [＋] の金額入力。
func price_stepper(parent: Node, value: int, step: int, lo: int, hi: int, on_change: Callable) -> void:
	var box := row(parent)
	var state := {"value": value}
	var minus := btn(box, "−%d" % step, func(): pass)
	var label := lbl(box, yen(value), UiTheme.FONT_LARGE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := btn(box, "＋%d" % step, func(): pass)
	var apply := func(delta: int) -> void:
		state["value"] = clampi(state["value"] + delta, lo, hi)
		label.text = yen(state["value"])
		on_change.call(state["value"])
	minus.pressed.connect(apply.bind(-step))
	plus.pressed.connect(apply.bind(step))
	minus.custom_minimum_size.x = 130
	plus.custom_minimum_size.x = 130


func confirm(text: String, on_ok: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "確認"
	dialog.ok_button_text = "はい"
	dialog.cancel_button_text = "いいえ"
	_show_dialog(dialog, text)
	dialog.confirmed.connect(on_ok)


func notify(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "お知らせ"
	dialog.ok_button_text = "OK"
	_show_dialog(dialog, text)


func _show_dialog(dialog: AcceptDialog, text: String) -> void:
	dialog.dialog_text = text
	dialog.dialog_autowrap = true
	dialog.borderless = true
	dialog.theme = theme
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 0))
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free())


static func yen(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if amount < 0 else "") + "¥" + digits + out


static func signed_yen(amount: int) -> String:
	return ("+" if amount >= 0 else "") + yen(amount)


static func money_color(amount: int) -> Color:
	return UiTheme.GOOD if amount >= 0 else UiTheme.BAD
