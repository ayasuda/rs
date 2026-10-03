extends Screen
## D4 営業結果シーン。売上・評判・来客数などを表示する。
## 結果は JSON から読み直した場合 float になっているので、整数は int() で受ける。


func build() -> void:
	var r: Dictionary = GameState.last_result
	if r.is_empty():
		set_header("営業結果", "dashboard")
		lbl(content, "まだ営業していません。")
		return
	set_header("%d日目（%s）の結果" % [int(r["day"]), Balance.WEEKDAY_LABELS[int(r["weekday"])]])

	var profit := int(r["profit"])
	var summary := card(content)
	var profit_label := lbl(summary, signed_yen(profit), 56, money_color(profit))
	profit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pair(summary, "天気", str(r["weather"]))
	pair(summary, "売上", yen(int(r["revenue"])))
	if int(r["revenue_side"]) > 0:
		pair(summary, "　うちサイドメニュー", yen(int(r["revenue_side"])))
	pair(summary, "原価", yen(-int(r["variable_cost"])))
	pair(summary, "固定費", yen(-int(r["fixed_cost"])))
	pair(summary, "所持金", yen(GameState.money), money_color(GameState.money))

	var visitors := card(content)
	lbl(visitors, "来客", 0, UiTheme.GOLD)
	pair(visitors, "提供した杯数", "%d杯" % int(r["served"]))
	for slot in r["slots"]:
		pair(visitors, "　" + str(slot["label"]), "%d人" % int(slot["visitors"]))
	if int(r["lost_full"]) > 0:
		pair(visitors, "満席で入れなかった", "%d人" % int(r["lost_full"]), UiTheme.BAD)
	if int(r["lost_price"]) > 0:
		pair(visitors, "値段を見て帰った", "%d人" % int(r["lost_price"]), UiTheme.BAD)
	for item in r["sold"]:
		pair(visitors, str(item["name"]), "%d杯" % int(item["sold"]))
	for label in r["sides_sold"]:
		pair(visitors, str(label), "%d品" % int(r["sides_sold"][label]))
	if float(r["skill_bonus"]) > 0.0:
		pair(visitors, "湯切りの成果", "調理技術 +%d" % roundi(float(r["skill_bonus"]) * 100), UiTheme.GOOD)

	var by_category := card(content)
	lbl(by_category, "客層ごとの反応", 0, UiTheme.GOLD)
	var any_served := false
	for cust in MasterData.customers:
		var stat = r["categories"].get(cust["id"])
		if stat == null or int(stat["served"]) == 0:
			continue
		any_served = true
		var delta: float = float(stat["rep_after"]) - float(stat["rep_before"])
		pair(by_category, "%s（%d人）%s" % [cust["name"], int(stat["served"]),
			Economy.satisfaction_label(stat["avg_score"])],
			"評判 %d（%s%.1f）" % [roundi(stat["rep_after"]), "+" if delta >= 0.0 else "", delta],
			UiTheme.GOOD if delta >= 0.0 else UiTheme.BAD)
	if not any_served:
		lbl(by_category, "誰にも提供できなかった。", UiTheme.FONT_SMALL, UiTheme.MUTED)

	if not r["comments"].is_empty():
		var voices := card(content)
		lbl(voices, "お客さんの声", 0, UiTheme.GOLD)
		for c in r["comments"]:
			lbl(voices, "%s（%s）「%s」" % [c["customer"], c["label"], c["text"]], UiTheme.FONT_SMALL)

	if GameState.game_over:
		var over := card(content)
		lbl(over, "資金が尽きた……", UiTheme.FONT_LARGE, UiTheme.BAD)
		lbl(over, "借金が膨らみ、店を畳むことになった。%d日間の営業だった。" % (GameState.day - 1))
		btn(footer, "タイトルへ", _on_game_over, true)
	else:
		btn(footer, "次の日へ", goto.bind("dashboard"), true)


func _on_game_over() -> void:
	GameState.delete_save()
	GameState.reset()
	goto("title")
