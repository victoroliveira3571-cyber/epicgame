extends Node

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	Story.st()["step"] = "c2_pietro"
	Law.data()["jail_left"] = 0
	Game.go_to_town("start")
	await dev.wait(2.0)
	Story.st()["step"] = "c1_marta"
	HUD.open_window("mapa")
	await dev.wait(0.6)
	await dev.shot(OUT + "map_town.png")
	HUD.close_window()
	Story.st()["step"] = "c2_pietro"
	Game.go_to_forest("town")
	await dev.wait(2.5)
	HUD.open_window("mapa")
	await dev.wait(0.6)
	await dev.shot(OUT + "map_forest.png")
	print("[map] ok ", Story.objective_world_pos(get_tree().get_first_node_in_group("town")))
