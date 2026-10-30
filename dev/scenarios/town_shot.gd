extends Node

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

func run(dev: Node) -> void:
	GameState.debug_reset()
	GameState.choose_class("cavaleiro")
	GameState.level = 5
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	var town := get_tree().current_scene
	var player: Player = get_tree().get_first_node_in_group("player")
	await dev.shot(OUT + "town_1.png")
	player.global_position = Vector2(520, 380)
	player.camera.reset_smoothing()
	await dev.wait(0.6)
	await dev.shot(OUT + "town_2_plaza.png")
	player.global_position = Vector2(520, 300)
	player.camera.reset_smoothing()
	await dev.wait(0.6)
	await dev.shot(OUT + "town_3_guild.png")
	player.global_position = Vector2(300, 400)
	player.camera.reset_smoothing()
	await dev.wait(0.6)
	await dev.shot(OUT + "town_4_west.png")
