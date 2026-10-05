extends Screen
## A1 タイトルシーン


func build() -> void:
	set_header("")
	spacer(content, 220)
	var title := lbl(content, "ラーメン屋\nシミュレーター", 72, UiTheme.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub := lbl(content, "理想の一杯で、行列のできる店へ", 0, UiTheme.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var has_save: bool = GameState.has_save()
	if has_save:
		btn(footer, "つづきから", _on_continue, true)
	btn(footer, "はじめから", _on_new_game, not has_save)
	spacer(footer, 40)


func _on_continue() -> void:
	if not GameState.load_game():
		notify("セーブデータを読み込めませんでした。")
		return
	if GameState.location_id == "":
		goto("location_select")
	elif GameState.game_over:
		goto("day_result")
	else:
		goto("dashboard")


func _on_new_game() -> void:
	if GameState.has_save():
		confirm("セーブデータを消して、最初から始めますか？", _start_new_game)
	else:
		_start_new_game()


func _start_new_game() -> void:
	GameState.delete_save()
	GameState.reset()
	goto("location_select")
