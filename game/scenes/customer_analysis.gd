extends Screen
## E1 顧客分析シーン ＋ E2 評判・流入分析。カテゴリ別の評判と前日の評価傾向。


func build() -> void:
	set_header("顧客分析", "dashboard")
	var loc: Dictionary = GameState.location()
	var last: Dictionary = GameState.last_result.get("categories", {})
	lbl(content, "評判は50が基準。高いほど来客が増え、支払ってもらえる上限も上がります。",
		UiTheme.FONT_SMALL, UiTheme.MUTED)

	# この立地にいる客層を先に並べる
	var ordered: Array = MasterData.customers.duplicate()
	ordered.sort_custom(func(a, b): return _daily_base(loc, a) > _daily_base(loc, b))

	for cust in ordered:
		var cid: String = cust["id"]
		var rep: float = GameState.reputation[cid]
		var base := _daily_base(loc, cust)
		var box := card(content)
		var head := row(box)
		lbl(head, cust["name"], UiTheme.FONT_LARGE, UiTheme.GOLD if base > 0.0 else UiTheme.MUTED)
		var traffic := lbl(head, _traffic_text(base), UiTheme.FONT_SMALL, UiTheme.MUTED)
		traffic.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl(box, cust["desc"], UiTheme.FONT_SMALL, UiTheme.MUTED)
		if base <= 0.0:
			continue

		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = rep
		bar.show_percentage = false
		bar.custom_minimum_size.y = 18
		box.add_child(bar)
		pair(box, "評判", "%d" % roundi(rep), UiTheme.GOOD if rep >= 50.0 else UiTheme.BAD)
		pair(box, "支払い上限の目安", yen(roundi(Economy.payment_limit(cust, rep))))
		pair(box, "来店時間帯", _rhythm_text(cust))
		pair(box, "営業時間のカバー率", "%d%%" % roundi(Economy.coverage(cust, GameState.open_slots) * 100))
		var stat = last.get(cid)
		if stat != null and int(stat["served"]) > 0:
			pair(box, "前日", "%d人・%s" % [int(stat["served"]), Economy.satisfaction_label(stat["avg_score"])])
		pair(box, "累計", "%d人" % int(GameState.total_served[cid]))


## 評判・天候などの補正を除いた、1日あたりの基礎来客数。
func _daily_base(loc: Dictionary, cust: Dictionary) -> float:
	var pool = loc["customers"].get(cust["id"])
	return 0.0 if pool == null else pool["potential"] * pool["base_rate"]


func _traffic_text(base: float) -> String:
	if base <= 0.0:
		return "この立地にはいない"
	if base >= 20.0:
		return "人通り：多い"
	if base >= 8.0:
		return "人通り：ふつう"
	return "人通り：少ない"


func _rhythm_text(cust: Dictionary) -> String:
	var parts: Array[String] = []
	for i in Balance.SLOT_LABELS.size():
		parts.append("%s%s" % [Balance.SLOT_LABELS[i], Economy.rhythm_symbol(cust["rhythm"][i])])
	return " ".join(parts)
