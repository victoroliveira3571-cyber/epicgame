extends Node

## Entra em cada interior e tira prints. Uso: --scenario=interior_shot -- --ids=casa,restaurante,guilda,casa_npc_0
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

func run(dev: Node) -> void:
	var ids: PackedStringArray = ["casa", "restaurante", "guilda", "casa_npc_0"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ids="):
			ids = arg.substr(6).split(",")
	GameState.debug_reset()
	GameState.choose_class("mago")
	GameState.gold = 5000
	for f in Data.FURNITURE_ORDER:
		GameState.buy_furniture(f)
	GameState.level = 3
	GameState.mark_dirty()
	for id in ids:
		Game.enter_interior(id)
		await dev.wait(1.4)
		var pl: Player = get_tree().get_first_node_in_group("player")
		pl.camera.zoom = Vector2(2.0, 2.0)
		pl.global_position = Vector2(pl.global_position.x, pl.global_position.y - 70)
		pl.camera.reset_smoothing()
		await dev.wait(0.5)
		await dev.shot(OUT + "int_%s.png" % id)
	print("[int] cena=", get_tree().current_scene.name)
