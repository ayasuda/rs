extends Screen
## G4 営業時間設定シーン。営業帯と固定費、時間帯別の客層。spec/customer.md


func build() -> void:
	set_header("営業時間", "dashboard")
	var loc: Dictionary = GameState.location()
	lbl(content, "開ける時間帯が増えるほど固定費がかさみます。誰に向けて店を開けるかを決めましょう。",
		UiTheme.FONT_SMALL, UiTheme.MUTED)

	var slots := card(content)
	for i in Balance.SLOT_LABELS.size():
		var text := "%s（固定費係数 +%.1f）" % [Balance.SLOT_LABELS[i], Balance.SLOT_COST_COEF[i]]
		toggle(slots, text, GameState.open_slots[i], func(on: bool):
			GameState.open_slots[i] = on
			GameState.save_game()
			rebuild())
	pair(slots, "家賃（係数1.0あたり）", yen(loc["rent"]))
	pair(slots, "固定費（1日）", yen(GameState.fixed_cost()), UiTheme.GOLD)

	heading(content, "この立地の客層と来店時間帯")
	var table := card(content)
	var grid := GridContainer.new()
	grid.columns = Balance.SLOT_LABELS.size() + 2
	table.add_child(grid)
	lbl(grid, "", UiTheme.FONT_SMALL)
	for label in Balance.SLOT_LABELS:
		_cell(grid, label, UiTheme.MUTED)
	_cell(grid, "カバー", UiTheme.MUTED)
	for cust in MasterData.customers:
		if not loc["customers"].has(cust["id"]):
			continue
		lbl(grid, cust["name"], UiTheme.FONT_SMALL)
		for i in Balance.SLOT_LABELS.size():
			_cell(grid, Economy.rhythm_symbol(cust["rhythm"][i]),
				UiTheme.TEXT if GameState.open_slots[i] else Color(UiTheme.MUTED, 0.45))
		var coverage := Economy.coverage(cust, GameState.open_slots)
		_cell(grid, "%d%%" % roundi(coverage * 100), UiTheme.GOOD if coverage >= 0.6 else UiTheme.BAD)


func _cell(grid: GridContainer, text: String, color: Color) -> void:
	var label := lbl(grid, text, UiTheme.FONT_SMALL, color)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.x = 64
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
