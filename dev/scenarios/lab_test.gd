extends Node

## Laboratório: prédio na cidade, interior, apresentação do Dr. Faísca no palco, bancada, tônico e livro de magia (Z).
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var ok := true


func check(c: bool, what: String) -> void:
	print("[lab] ", "ok    " if c else "FALHOU ", what)
	ok = ok and c


func _skip_until(n: int) -> void:
	for i in n:
		if not HUD.is_dialogue_open():
			return
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await get_tree().create_timer(0.12).timeout


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	Law.data()["jail_left"] = 0
	Game.go_to_town("start")
	await dev.wait(2.0)
	var town := get_tree().current_scene
	check(town.buildings.has("laboratorio"), "prédio do laboratório na cidade")
	var pl := get_tree().get_first_node_in_group("player") as Player
	pl.global_position = (town.buildings["laboratorio"] as Node2D).position + Vector2(0, 30)
	pl.camera.reset_smoothing()
	await dev.wait(0.6)
	await dev.shot(OUT + "lab_predio.png")
	Game.enter_interior("laboratorio")
	await dev.wait(3.5)
	await dev.shot(OUT + "lab_intro_palco.png")
	await _skip_until(80)
	await dev.wait(0.5)
	await dev.shot(OUT + "lab_interior.png")
	# bancada
	for ing in ["erva_azul", "gosma", "asa", "essencia", "osso", "cristal", "pelo"]:
		GameState.add_item(ing, 6, true)
	HUD.open_window("laboratorio")
	await dev.wait(0.5)
	var w = HUD.window
	w.selected = 3
	w.rebuild()
	await dev.wait(0.3)
	await dev.shot(OUT + "lab_bancada.png")
	w._make(3)
	check(GameState.count_item("tonico_memoria") == 1, "tônico preparado")
	w.selected = 5
	w._make(5)
	check(GameState.count_item("livro_chamas") == 1, "livro de chamas preparado (tem 10 h de foco)")
	HUD.close_window()
	GameState.use_item("tonico_memoria")
	var before := GameState.xp
	var r := GameState.complete_focus_session(100, 10, 25)
	check(int(GameState.lab_data()["boost_sessions"]) == 2, "tônico gasto 1 de 3 sessões")
	print("[lab] xp do foco com tônico: ", r.get("xp", 0))
	GameState.use_item("livro_chamas")
	check(GameState.slot_skill("skill_book") == "chamas", "magia do livro na tecla Z")
	print("[lab] ", "TUDO OK" if ok else "COM FALHAS")
