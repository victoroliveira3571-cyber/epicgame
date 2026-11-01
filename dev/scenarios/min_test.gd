extends Node

var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	await dev.shot(OUT + "min_0.png")
	HUD._set_pomo_min(true)
	GameState.pomo_cfg["obj_min"] = true
	HUD._refresh_objective()
	await dev.wait(0.3)
	await dev.shot(OUT + "min_1.png")
	HUD._set_pomo_min(false)
	GameState.pomo_cfg["obj_min"] = false
	HUD._refresh_objective()
	print("[min] ok")
