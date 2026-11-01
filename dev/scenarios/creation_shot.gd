extends Node

## Criação do personagem com o editor de aparência e o espelho. Prints em _shots/creation_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	await dev.wait(0.3)
	HUD.open_window("criacao")
	await dev.wait(0.8)
	await dev.shot(OUT + "creation_1.png")
	var w := HUD.window
	w._editor._randomize()
	w._set_body("female")
	await dev.wait(0.6)
	await dev.shot(OUT + "creation_2.png")
	w._hero.text = "Ana"
	w._father.text = "Rui"
	w._mother.text = "Lia"
	w._start()
	await dev.wait(2.0)
	while HUD.is_dialogue_open():
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await dev.wait(0.15)
		var box: DialogueBox = HUD._dialog
		if box != null and box.choosing:
			box._choices.get_child(0).emit_signal("pressed")
		await dev.wait(0.05)
	HUD.open_window("aparencia")
	await dev.wait(0.8)
	await dev.shot(OUT + "creation_3_espelho.png")
