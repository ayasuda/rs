extends Screen
## G1/G2 店舗候補一覧・契約シーン。新規開始時と移転時の両方で使う。


func build() -> void:
	var relocating: bool = GameState.location_id != ""
	set_header("移転先を選ぶ" if relocating else "店舗を選ぶ", "shop" if relocating else "title")
	lbl(content, "所持金 %s" % yen(GameState.money), UiTheme.FONT_LARGE)
	if relocating:
		lbl(content, "移転すると、評判は振り出しに戻ります。", UiTheme.FONT_SMALL, UiTheme.BAD)

	for loc in MasterData.locations:
		var box := card(content)
		heading(box, loc["name"])
		lbl(box, loc["desc"], UiTheme.FONT_SMALL, UiTheme.MUTED)
		pair(box, "家賃（係数1.0あたり）", yen(loc["rent"]))
		pair(box, "席数", "%d席" % loc["seats"])
		pair(box, "契約金", yen(loc["deposit"]))
		pair(box, "主な客層", "、".join(_main_customers(loc)))

		var is_current: bool = loc["id"] == GameState.location_id
		var button := btn(box, "現在の店舗" if is_current else "ここに決める",
			_on_choose.bind(loc), true)
		button.disabled = is_current or GameState.money < loc["deposit"]


func _main_customers(loc: Dictionary) -> Array[String]:
	var ids: Array = loc["customers"].keys()
	ids.sort_custom(func(a, b):
		var pa: Dictionary = loc["customers"][a]
		var pb: Dictionary = loc["customers"][b]
		return pa["potential"] * pa["base_rate"] > pb["potential"] * pb["base_rate"])
	var names: Array[String] = []
	for id in ids.slice(0, 3):
		names.append(MasterData.customers_by_id[id]["name"])
	return names


func _on_choose(loc: Dictionary) -> void:
	confirm("「%s」を契約金 %s で契約しますか？" % [loc["name"], yen(loc["deposit"])], func():
		GameState.contract_location(loc["id"])
		goto("dashboard"))
