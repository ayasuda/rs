extends Screen
## A2 メインダッシュボードシーン。店舗状況と各機能へのハブ。


func build() -> void:
	set_header("%d日目（%s）" % [GameState.day, Balance.WEEKDAY_LABELS[GameState.weekday()]])
	var loc: Dictionary = GameState.location()

	var status := card(content)
	heading(status, loc["name"])
	pair(status, "所持金", yen(GameState.money), money_color(GameState.money))
	pair(status, "営業時間", _hours_text())
	pair(status, "固定費（1日）", yen(GameState.fixed_cost()))
	pair(status, "メニュー", _menu_text())
	pair(status, "調理技術", "%d / 100" % roundi(GameState.cooking_skill * 100))
	if GameState.ad_days_left > 0:
		pair(status, "チラシの効果", "あと%d日" % GameState.ad_days_left, UiTheme.GOOD)
	if not GameState.history.is_empty():
		var last: Dictionary = GameState.history[GameState.history.size() - 1]
		pair(status, "前日の利益", signed_yen(int(last["profit"])), money_color(int(last["profit"])))

	var grid := GridContainer.new()
	grid.columns = 2
	content.add_child(grid)
	for entry in [
		["レシピノート", "recipe_note"], ["メニュー・価格", "menu_settings"],
		["営業時間", "hours_settings"], ["設備・宣伝", "shop"],
		["顧客分析", "customer_analysis"], ["前日の結果", "day_result"],
	]:
		var button := btn(grid, entry[0], goto.bind(entry[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 110
		if entry[1] == "day_result":
			button.disabled = GameState.last_result.is_empty()

	btn(footer, "営業開始（厨房に立つ）", _on_open.bind(true), true)
	btn(footer, "営業開始（店員におまかせ）", _on_open.bind(false))
	btn(footer, "タイトルへ", goto.bind("title"))


func _hours_text() -> String:
	var labels: Array[String] = []
	for i in Balance.SLOT_LABELS.size():
		if GameState.open_slots[i]:
			labels.append(Balance.SLOT_LABELS[i])
	return "未設定" if labels.is_empty() else "・".join(labels)


func _menu_text() -> String:
	if GameState.menu.is_empty():
		return "なし"
	var parts: Array[String] = []
	for entry in GameState.menu:
		var recipe = GameState.find_recipe(entry["recipe_id"])
		if recipe != null:
			parts.append("%s %s" % [recipe["name"], yen(entry["price"])])
	return "\n".join(parts)


func _on_open(play_minigame: bool) -> void:
	var problem: String = GameState.business_problem()
	if problem != "":
		notify(problem)
		return
	if play_minigame:
		goto("minigame")
	else:
		GameState.run_day()
		goto("day_result")
