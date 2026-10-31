extends Node

## Diálogo real (DialogueBox) por cima do palco: loja, chefe e rua (a rua não abre palco).
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func _skip() -> void:
	for i in 60:
		if not HUD.is_dialogue_open():
			return
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await get_tree().create_timer(0.1).timeout


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	Law.data()["jail_left"] = 0
	Game.enter_interior("forja")
	await dev.wait(2.0)
	await dev.wait(1.5)
	await dev.shot(OUT + "sd_forja_intro.png")
	await dev.wait(3.0)
	await dev.shot(OUT + "sd_forja_intro2.png")
	await _skip()
	Game.go_to_town("start")
	await dev.wait(2.5)
	Story.say([["narr", "O trono está vazio. Uma voz ecoa no salão."], ["rei", "Você chegou longe, aventureiro."], ["heroi", "Devolva as páginas!"], ["rei@anger", "Páginas? Elas são minhas agora."]])
	await dev.wait(3.5)
	await dev.shot(OUT + "sd_rei_1.png")
	for i in 3:
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await dev.wait(0.9)
	await dev.wait(2.0)
	await dev.shot(OUT + "sd_rei_2.png")
	await _skip()
	print("[sd] ok")
