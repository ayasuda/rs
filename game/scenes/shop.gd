extends Screen
## 設備・宣伝シーン。G3 内装編集と E3 店員育成の簡易版に、宣伝と移転をまとめている。


func build() -> void:
	set_header("設備・宣伝", "dashboard")
	lbl(content, "所持金 %s" % yen(GameState.money), UiTheme.FONT_LARGE)

	var interior := card(content)
	heading(interior, "内装・外観")
	var level: int = GameState.interior_level
	pair(interior, "現在", Balance.INTERIOR_LABELS[level])
	pair(interior, "来客への効果", "+%d%%" % roundi(Balance.INTERIOR_BONUS_PER_LEVEL * level * 100))
	if level < Balance.INTERIOR_COSTS.size():
		var cost := Balance.INTERIOR_COSTS[level]
		var button := btn(interior, "「%s」に改装する（%s）" % [Balance.INTERIOR_LABELS[level + 1], yen(cost)],
			_buy.bind(GameState.upgrade_interior), true)
		button.disabled = GameState.money < cost
	else:
		lbl(interior, "これ以上は改装できません。", UiTheme.FONT_SMALL, UiTheme.MUTED)

	var ad := card(content)
	heading(ad, "宣伝")
	lbl(ad, "チラシを配ると%d日間、来客が +%d%% になります。" % [
		Balance.AD_DAYS, roundi(Balance.AD_BONUS * 100)], UiTheme.FONT_SMALL, UiTheme.MUTED)
	if GameState.ad_days_left > 0:
		pair(ad, "効果の残り", "あと%d日" % GameState.ad_days_left, UiTheme.GOOD)
	var ad_button := btn(ad, "チラシを配る（%s）" % yen(Balance.AD_COST), _buy.bind(GameState.buy_ad), true)
	ad_button.disabled = GameState.money < Balance.AD_COST

	var training := card(content)
	heading(training, "調理技術")
	lbl(training, "技術が高いほど味が底上げされ、一杯ごとのブレも減ります。営業を重ねても少しずつ伸びます。",
		UiTheme.FONT_SMALL, UiTheme.MUTED)
	pair(training, "現在", "%d / 100" % roundi(GameState.cooking_skill * 100))
	var training_button := btn(training, "研修を受ける（%s）" % yen(Balance.TRAINING_COST),
		_buy.bind(GameState.buy_training), true)
	training_button.disabled = GameState.money < Balance.TRAINING_COST or GameState.cooking_skill >= 1.0

	var move := card(content)
	heading(move, "移転")
	pair(move, "現在の店舗", GameState.location()["name"])
	btn(move, "物件を探す", goto.bind("location_select"))


func _buy(action: Callable) -> void:
	action.call()
	rebuild()
