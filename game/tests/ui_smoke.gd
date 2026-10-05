extends SceneTree
## 画面を実際に操作して一通り遊べることを確かめる（ボタンを文言で探して押す）。
##   godot --headless --path game -s tests/ui_smoke.gd

var _gs: Node
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_gs = root.get_node("GameState")
	_gs.save_path = "user://ui_smoke_save.json"
	_gs.delete_save()
	_gs.reset()

	# タイトル → 店舗選択 → 契約
	await _open("title")
	await _press("はじめから")
	_expect_scene("location_select")
	await _press("ここに決める")
	await _confirm()
	_expect_scene("dashboard")
	check(_gs.location_id == "gakusei", "最初の物件を契約できる")
	check(_gs.money == Balance.START_MONEY - 100000, "契約金が引かれる")

	# レシピを作って保存
	await _press("レシピノート")
	await _press("新しいレシピ")
	_expect_scene("recipe_edit")
	_find(LineEdit).text = "こってり学生ラーメン"
	for label in ["濃厚とんこつ", "極太ワシワシ", "背脂", "炙りチャーシュー", "もやし山盛り", "刻みニンニク", "味玉", "すり鉢"]:
		await _toggle(label, true)
	await _toggle("海苔", true)  # 5種目は弾かれる
	await _dismiss()
	await _press("この内容で保存する")
	_expect_scene("recipe_note")
	var recipe = _gs.find_recipe("r1")
	check(recipe != null and recipe["soup"] == "soup-tonkotsu", "作ったレシピが保存される")
	check(recipe != null and recipe["toppings"].size() == 4, "具材は4種まで")
	check(_button("編集する") != null, "保存後は詳細が開く")

	# 編集して名前を変える
	await _press("編集する")
	check(_find(LineEdit).text == "こってり学生ラーメン", "編集画面に元の内容が入る")
	_find(LineEdit).text = "学生街の二郎系"
	await _press("この内容で保存する")
	check(_gs.find_recipe("r1")["name"] == "学生街の二郎系" and _gs.recipes.size() == 2, "上書き保存される")
	await _press("もくじに戻る")
	await _press("戻る")

	# メニューに載せて値段を上げ、サイドも出す
	await _press("メニュー・価格")
	_buttons("提供する")[0].button_pressed = true
	await _frames()
	check(_gs.menu.size() == 2, "2品目をメニューに載せられる")
	_buttons("＋50")[1].pressed.emit()
	check(_gs.menu[1]["price"] == 850, "価格を変えられる")
	_buttons("提供する")[1].button_pressed = true
	await _frames()
	check(_gs.sides["gyoza"]["enabled"], "サイドメニューを出せる")
	await _press("戻る")

	# 営業時間・設備
	await _press("営業時間")
	await _toggle("深夜", true)
	check(_gs.open_slots[4] and _gs.fixed_cost() == roundi(4000 * 5.9), "深夜営業で固定費が増える")
	await _toggle("深夜", false)
	await _press("戻る")
	await _press("設備・宣伝")
	var before: int = _gs.money
	await _press("チラシを配る")
	check(_gs.ad_days_left == Balance.AD_DAYS and _gs.money == before - Balance.AD_COST, "チラシを買える")
	await _press("戻る")
	await _press("顧客分析")
	await _press("戻る")

	# おまかせで営業
	await _press("店員におまかせ")
	_expect_scene("day_result")
	check(_gs.day == 2 and _gs.last_result["served"] > 0, "1日営業して翌日に進む")
	await _press("次の日へ")

	# ミニゲームで営業
	await _press("厨房に立つ")
	_expect_scene("minigame")
	for n in 5:
		await _press("湯切り")
	await _press("営業結果を見る")
	_expect_scene("day_result")
	check(_gs.day == 3, "ミニゲーム経由でも営業できる")
	await _press("次の日へ")

	# レシピ削除でメニューからも外れる
	await _press("レシピノート")
	await _press("学生街の二郎系")
	await _press("削除する")
	await _confirm()
	check(_gs.find_recipe("r1") == null and _gs.menu.size() == 1, "レシピを削除できる")

	# タイトルに戻って続きから
	var day: int = _gs.day
	var money: int = _gs.money
	_gs.reset()
	await _open("title")
	await _press("つづきから")
	_expect_scene("dashboard")
	check(_gs.day == day and _gs.money == money, "続きから再開できる")

	# 倒産
	_gs.money = Balance.BANKRUPT_LINE - 100000
	await _press("店員におまかせ")
	check(_gs.game_over, "資金が尽きると倒産する")
	await _press("タイトルへ")
	_expect_scene("title")
	check(not _gs.has_save(), "倒産するとセーブが消える")

	_gs.delete_save()
	print("\nui smoke: %d failures" % _failures)
	quit(1 if _failures > 0 else 0)


func check(cond: bool, message: String) -> void:
	print("%s %s" % ["ok  " if cond else "FAIL", message])
	if not cond:
		_failures += 1


func _frames(count: int = 4) -> void:
	for n in count:
		await process_frame


func _open(scene: String) -> void:
	change_scene_to_file("res://scenes/%s.tscn" % scene)
	await _frames()


func _expect_scene(scene: String) -> void:
	var path := current_scene.scene_file_path
	check(path.ends_with("/%s.tscn" % scene), "画面は %s（実際: %s）" % [scene, path.get_file()])


## 画面上のボタンを文言の部分一致で探す（ダイアログ内のボタンは除く）。
func _buttons(text: String, node: Node = null) -> Array:
	if node == null:
		node = current_scene
	var found := []
	if node is Button and node.text.contains(text):
		found.append(node)
	for child in node.get_children():
		if not (child is Window):
			found.append_array(_buttons(text, child))
	return found


func _button(text: String) -> Button:
	var found := _buttons(text)
	return null if found.is_empty() else found[0]


func _press(text: String) -> void:
	var button := _button(text)
	if button == null or button.disabled:
		check(false, "ボタン「%s」が押せる" % text)
		return
	button.pressed.emit()
	await _frames()


func _toggle(text: String, on: bool) -> void:
	var button := _button(text)
	if button == null:
		check(false, "トグル「%s」がある" % text)
		return
	button.button_pressed = on
	await _frames()


func _find(type: Variant, node: Node = null) -> Node:
	if node == null:
		node = current_scene
	if is_instance_of(node, type):
		return node
	for child in node.get_children():
		var hit := _find(type, child)
		if hit != null:
			return hit
	return null


func _confirm() -> void:
	var dialog: ConfirmationDialog = _find(ConfirmationDialog)
	if dialog == null:
		check(false, "確認ダイアログが出る")
		return
	dialog.confirmed.emit()
	dialog.hide()
	await _frames()


func _dismiss() -> void:
	var dialog: AcceptDialog = _find(AcceptDialog)
	check(dialog != null, "お知らせダイアログが出る")
	if dialog != null:
		dialog.hide()
	await _frames()
