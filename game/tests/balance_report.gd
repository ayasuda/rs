extends SceneTree
## バランス確認用：各立地で初期レシピのまま30日営業した推移を出す。
##   godot --headless --path game -s tests/balance_report.gd

const GameStateScript := preload("res://scripts/autoload/game_state.gd")


func _initialize() -> void:
	MasterData.ensure_loaded()
	for loc in MasterData.locations:
		var gs = GameStateScript.new()
		gs.save_path = "user://balance_report.json"
		gs.contract_location(loc["id"])
		var rng := RandomNumberGenerator.new()
		rng.seed = 1
		var profit := 0
		var served := 0
		var first: Dictionary = {}
		for n in 30:
			var result: Dictionary = gs.run_day(0.0, rng)
			if n == 0:
				first = result
			profit += result["profit"]
			served += result["served"]
		print("\n== %s（固定費 %d/日）" % [loc["name"], gs.fixed_cost()])
		print("  1日目: 来客 %d / 提供 %d / 満席 %d / 利益 %d" % [
			first["visitors"], first["served"], first["lost_full"], first["profit"]])
		print("  30日: 平均提供 %.1f / 平均利益 %d / 所持金 %d" % [served / 30.0, profit / 30, gs.money])
		for cust in MasterData.customers:
			var stat: Dictionary = gs.last_result["categories"][cust["id"]]
			if loc["customers"].has(cust["id"]):
				print("  %-8s 評判 %5.1f  最終日 %2d人 満足度 %5.1f" % [
					cust["name"], gs.reputation[cust["id"]], stat["served"], stat["avg_score"]])
		gs.delete_save()
		gs.free()
	quit()
