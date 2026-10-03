extends SceneTree
## 全シーンを順に開いてスクリーンショットを撮る（見た目の確認用。ウィンドウが開く）。
##   godot --path game -s tests/screenshots.gd
## 出力先: game/tests/screenshots/

const SCENES := [
	"title", "location_select", "dashboard", "recipe_note", "recipe_edit",
	"menu_settings", "hours_settings", "shop", "customer_analysis", "minigame", "day_result",
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.save_path = "user://screenshot_save.json"
	gs.reset()
	var out := ProjectSettings.globalize_path("res://tests/screenshots")
	DirAccess.make_dir_recursive_absolute(out)

	await _shot("title", out)
	await _shot("location_select", out)
	gs.contract_location("gakusei")
	gs.sides["gyoza"]["enabled"] = true
	gs.run_day(0.1)
	for scene in SCENES.slice(2):
		await _shot(scene, out)
	gs.nav_args = {"selected": "r0"}
	await _shot("recipe_note", out, "recipe_detail")

	current_scene.confirm("「先代の醤油ラーメン」を削除しますか？", func(): pass)
	await _capture(out, "dialog")

	gs.delete_save()
	quit()


func _shot(scene: String, out: String, file_name: String = "") -> void:
	change_scene_to_file("res://scenes/%s.tscn" % scene)
	await _capture(out, file_name if file_name != "" else scene)


func _capture(out: String, file_name: String) -> void:
	for n in 6:
		await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [out, file_name])
	print("saved ", file_name)
