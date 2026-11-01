extends Node

## v3.0: pets animados na janela de personagem e chamado do pet (B).

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	for pid in Data.PET_ORDER:
		Story.give_pet(pid)
	Story.set_pet("corvin")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	var ev := InputEventKey.new()
	ev.keycode = KEY_B
	ev.pressed = true
	Input.parse_input_event(ev)
	await dev.wait(0.9)
	await dev.shot(OUT + "v30_pet_b.png")
	HUD.open_window("personagem")
	await dev.wait(0.5)
	HUD.window.mode = "pets"
	HUD.window.rebuild()
	await dev.wait(0.6)
	await dev.shot(OUT + "v30_pets.png")
