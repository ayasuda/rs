class_name UiTheme
extends RefCounted
## 全画面共通のテーマ（色・ボタン・パネル）。

const BG := Color("2a1f1a")
const PANEL := Color("3b2c24")
const BUTTON := Color("5a4336")
const BUTTON_HOVER := Color("6b5142")
const ACCENT := Color("c8452c")
const ACCENT_HOVER := Color("dc5a3f")
const ACCENT_DARK := Color("9c3220")
const TEXT := Color("f5ead8")
const MUTED := Color("bfae9a")
const GOOD := Color("8fd18a")
const BAD := Color("ff8a7a")
const GOLD := Color("f2c14e")

const FONT_SIZE := 28
const FONT_SMALL := 22
const FONT_LARGE := 36
const FONT_TITLE := 42

static var _theme: Theme


static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = FONT_SIZE

	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, _flat(BUTTON))
		t.set_stylebox("hover", type, _flat(BUTTON_HOVER))
		t.set_stylebox("pressed", type, _flat(ACCENT))
		t.set_stylebox("hover_pressed", type, _flat(ACCENT_HOVER))
		t.set_stylebox("disabled", type, _flat(Color(BUTTON, 0.4)))
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, TEXT)
		t.set_color("font_pressed_color", type, TEXT)
		t.set_color("font_hover_pressed_color", type, TEXT)
		t.set_color("font_focus_color", type, TEXT)
		t.set_color("font_disabled_color", type, Color(MUTED, 0.6))

	# 主要な操作に使う目立つボタン
	t.set_type_variation("PrimaryButton", "Button")
	t.set_stylebox("normal", "PrimaryButton", _flat(ACCENT))
	t.set_stylebox("hover", "PrimaryButton", _flat(ACCENT_HOVER))
	t.set_stylebox("pressed", "PrimaryButton", _flat(ACCENT_DARK))
	t.set_stylebox("disabled", "PrimaryButton", _flat(Color(ACCENT, 0.35)))

	t.set_stylebox("panel", "PanelContainer", _flat(PANEL, 16, 20))
	t.set_color("font_color", "Label", TEXT)
	t.set_constant("separation", "VBoxContainer", 14)
	t.set_constant("separation", "HBoxContainer", 12)
	t.set_constant("h_separation", "GridContainer", 12)
	t.set_constant("v_separation", "GridContainer", 12)
	t.set_constant("h_separation", "HFlowContainer", 10)
	t.set_constant("v_separation", "HFlowContainer", 10)

	t.set_stylebox("normal", "LineEdit", _flat(Color("1c1411"), 12, 16))
	t.set_stylebox("focus", "LineEdit", _flat(Color("1c1411"), 12, 16, ACCENT))
	t.set_color("font_color", "LineEdit", TEXT)

	t.set_stylebox("panel", "AcceptDialog", _flat(PANEL, 16, 28, GOLD))
	t.set_constant("buttons_separation", "AcceptDialog", 24)

	t.set_stylebox("background", "ProgressBar", _flat(Color("1c1411"), 8, 0))
	t.set_stylebox("fill", "ProgressBar", _flat(GOLD, 8, 0))
	_theme = t
	return t


static func _flat(color: Color, radius: int = 14, margin: int = 18, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.75
	sb.content_margin_bottom = margin * 0.75
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(2)
	return sb
