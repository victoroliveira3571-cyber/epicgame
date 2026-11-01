extends Node

## v3.7: print do mapa-múndi em pergaminho (Vicerus) em dois momentos da história.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.start_new_game("Teo", "Rui", "Miriam", "m")
	GameState.choose_class("mago")
	Story.st()["step"] = "a_jardim"
	Story.set_flag("bussola")
	Game.go_to_city("academia")
	await dev.wait(3.0)
	HUD.open_window("mundo")
	await dev.wait(0.8)
	await dev.shot(OUT + "v37_mapa_academia.png")
	HUD.close_window()
	Story.dev_start()
	Game.go_to_town("start")
	await dev.wait(2.5)
	HUD.open_window("mundo")
	await dev.wait(0.8)
	await dev.shot(OUT + "v37_mapa_fim.png")
