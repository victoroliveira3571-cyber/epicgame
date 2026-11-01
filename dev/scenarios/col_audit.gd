extends Node

## Mostra as formas de colisão sobre o mapa (cidade e floresta) para achar o que atravessa/trava.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	GameState.mark_dirty()
	get_tree().debug_collisions_hint = false
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	var pl: Player = get_tree().get_first_node_in_group("player")
	pl.camera.zoom = Vector2(1.25, 1.25)
	for q in [[Vector2(260, 220), "nw"], [Vector2(760, 220), "ne"], [Vector2(260, 580), "sw"], [Vector2(760, 580), "se"]]:
		pl.global_position = q[0]
		pl.camera.reset_smoothing()
		await dev.wait(0.5)
		await dev.shot(OUT + "col_town_%s.png" % q[1])
	Game.go_to_forest("town")
	await dev.wait(2.5)
	pl = get_tree().get_first_node_in_group("player")
	pl.camera.zoom = Vector2(1.25, 1.25)
	for q in [[Vector2(1500, 600), "borda"], [Vector2(1000, 570), "clareira"], [Vector2(500, 600), "mata"], [Vector2(400, 900), "pantano"]]:
		pl.global_position = q[0]
		pl.camera.reset_smoothing()
		await dev.wait(0.5)
		await dev.shot(OUT + "col_forest_%s.png" % q[1])
