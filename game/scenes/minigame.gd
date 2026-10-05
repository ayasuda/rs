extends Screen
## D3 接客ミニゲームシーン（湯切りチャレンジ）。
## 仕様は未確定なので、タイミングを合わせるだけの簡易版。精度がその日の調理技術に上乗せされる。

const ROUNDS := 5
const BASE_SPEED := 0.9   # 1秒あたりに進む量（バーの幅 = 1.0）
const SPEED_STEP := 0.2
const ZONE_HALF := 0.09

var _bar: TimingBar
var _status: Label
var _log: VBoxContainer
var _action: Button
var _round := 0
var _time := 0.0
var _scores: Array[float] = []


func build() -> void:
	set_header("湯切りチャレンジ", "dashboard")
	lbl(content, "カーソルが緑のゾーンに重なった瞬間に湯切り！\n精度が高いほど、今日の一杯の仕上がりが良くなります。",
		UiTheme.FONT_SMALL, UiTheme.MUTED)
	_status = lbl(content, "", UiTheme.FONT_LARGE, UiTheme.GOLD)
	_bar = TimingBar.new()
	_bar.custom_minimum_size.y = 140
	content.add_child(_bar)
	_log = card(content)
	lbl(_log, "判定", 0, UiTheme.GOLD)
	_action = btn(footer, "湯切り！", _on_action, true)
	_action.custom_minimum_size.y = 160
	_next_round()


func _process(delta: float) -> void:
	if _bar == null or _round > ROUNDS:
		return
	_time += delta * (BASE_SPEED + SPEED_STEP * (_round - 1))
	_bar.cursor = pingpong(_time, 1.0)
	_bar.queue_redraw()


func _next_round() -> void:
	_round += 1
	if _round > ROUNDS:
		_finish()
		return
	_time = 0.0
	_bar.zone_center = randf_range(0.3, 0.85)
	_bar.zone_half = ZONE_HALF
	_status.text = "%d杯目 / %d杯" % [_round, ROUNDS]


func _on_action() -> void:
	if _round > ROUNDS:
		GameState.run_day(_bonus())
		goto("day_result")
		return
	var accuracy := accuracy_for(absf(_bar.cursor - _bar.zone_center), _bar.zone_half)
	_scores.append(accuracy)
	lbl(_log, "%d杯目：%s" % [_round, _judge(accuracy)], 0, UiTheme.GOOD if accuracy >= 0.6 else UiTheme.BAD)
	_next_round()


func _finish() -> void:
	_bar.visible = false
	_status.text = "今日の調理技術 +%d" % roundi(_bonus() * 100)
	_action.text = "営業結果を見る"


func _bonus() -> float:
	if _scores.is_empty():
		return 0.0
	var total := 0.0
	for s in _scores:
		total += s
	return total / _scores.size() * Balance.MINIGAME_MAX_BONUS


## ゾーン中心からの距離を 0.0〜1.0 の精度にする。ゾーンの端でおよそ 0.67。
static func accuracy_for(distance: float, zone_half: float) -> float:
	return clampf(1.0 - distance / (zone_half * 3.0), 0.0, 1.0)


func _judge(accuracy: float) -> String:
	if accuracy >= 0.9:
		return "完璧！"
	if accuracy >= 0.66:
		return "いい湯切り"
	if accuracy >= 0.3:
		return "惜しい"
	return "ミス……"


class TimingBar extends Control:
	var cursor := 0.0
	var zone_center := 0.5
	var zone_half := 0.09

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, h * 0.3, w, h * 0.4), UiTheme.PANEL)
		draw_rect(Rect2((zone_center - zone_half) * w, h * 0.3, zone_half * 2.0 * w, h * 0.4), UiTheme.GOOD)
		draw_rect(Rect2(cursor * w - 5, 0, 10, h), UiTheme.GOLD)
