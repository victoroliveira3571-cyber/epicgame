extends Node

## v3.7: entrada de reino (muralha, portão com torres, fosso e ponte, guardas) e castelo do rei em Pedralta;
## entrada da masmorra arrumada em Focus Town. Atravessa o portão andando e tira prints em _shots/v37_rei_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0
var dev: Node


func check(cond: bool, what: String) -> void:
	if cond:
		print("[rei] ok    ", what)
	else:
		fails += 1
		printerr("[rei] FALHA ", what)


func _walk(action: String, secs: float) -> void:
	Input.action_press(action)
	await dev.wait(secs)
	Input.action_release(action)
	await dev.wait(0.15)


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	Game.go_to_city("pedralta")
	await dev.wait(4.0)
	var c := get_tree().current_scene
	check(c.get("city_id") == "pedralta", "Pedralta carregou")
	var pl: Node2D = c.player
	await dev.shot(OUT + "v37_rei_portao_dentro.png")
	# sai pelo portão e pela ponte (andando)
	pl.global_position = Vector2(28 * 16, 38 * 16)
	await dev.wait(0.2)
	Input.action_press("move_down")
	var crossed := false
	for i in 40:
		await dev.wait(0.1)
		if pl.global_position.y > 43 * 16:
			crossed = true
			Input.action_release("move_down")
			break
	Input.action_release("move_down")
	check(crossed, "atravessou o portão e chegou à ponte (y=%d)" % int(pl.global_position.y))
	await dev.shot(OUT + "v37_rei_ponte.png")
	# muralha bloqueia fora do portão
	pl.global_position = Vector2(12 * 16, 38 * 16)
	await dev.wait(0.2)
	await _walk("move_down", 1.2)
	check(pl.global_position.y < 40 * 16, "muralha bloqueia (y=%d)" % int(pl.global_position.y))
	# castelo
	pl.global_position = Vector2(28 * 16 + 8, 16 * 16)
	await dev.wait(1.0)
	check(c.buildings.has("castelo"), "castelo do rei")
	await dev.shot(OUT + "v37_rei_castelo.png")
	# horta
	pl.global_position = Vector2(14 * 16, 38 * 16)
	await dev.wait(0.8)
	await dev.shot(OUT + "v37_rei_horta.png")
	# entrada da masmorra em Focus Town
	Game.go_to_town("start")
	await dev.wait(3.0)
	var t := get_tree().current_scene
	var p2: Node2D = get_tree().get_first_node_in_group("player")
	p2.global_position = Vector2(t.SPINE_X * 16 + 8, (t.GATE_Y - 3) * 16)
	await dev.wait(1.0)
	await dev.shot(OUT + "v37_rei_masmorra.png")
	print("[rei] falhas: ", fails)
