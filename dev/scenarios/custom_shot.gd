extends Node

## Tela de classe com paisagem + casa com móveis novos + guilda com quadros.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")

func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	await dev.shot(OUT + "custom_classe.png")
	GameState.choose_class("cavaleiro")
	HUD.close_window()
	GameState.gold = 5000
	for f in Data.FURNITURE_ORDER:
		GameState.buy_furniture(f)
	for id in ["casa", "guilda"]:
		Game.enter_interior(id)
		await dev.wait(1.5)
		var pl: Player = get_tree().get_first_node_in_group("player")
		pl.camera.zoom = Vector2(2.1, 2.1)
		pl.global_position = Vector2(pl.global_position.x, pl.global_position.y - 90)
		pl.camera.reset_smoothing()
		await dev.wait(0.5)
		await dev.shot(OUT + "custom_%s.png" % id)
