extends Node

## v2.9: divisórias colocadas na casa e colisão.

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var fails := 0


func check(c: bool, what: String) -> void:
	print("[v29] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.furniture = ["divisoria_madeira", "divisoria_pedra"]
	GameState.furniture_stored = []
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	Game.enter_interior("casa")
	await dev.wait(1.5)
	var home := get_tree().current_scene as Interior
	var ed := home.housing
	ed.set_active(true)
	ed._take_from_box("divisoria_madeira")
	var pos: Vector2 = ed._snap("divisoria_madeira", Vector2(160, 130), 0)
	ed.nodes["divisoria_madeira"].position = pos
	ed._valid = ed.is_free("divisoria_madeira", pos, 0)
	check(ed._valid, "divisória cabe no piso")
	ed._drop()
	ed._take_from_box("divisoria_pedra")
	var pos2: Vector2 = ed._snap("divisoria_pedra", Vector2(210, 130), 0)
	ed.nodes["divisoria_pedra"].position = pos2
	ed._valid = ed.is_free("divisoria_pedra", pos2, 0)
	ed._drop()
	check(GameState.is_furniture_placed("divisoria_madeira"), "divisória de madeira colocada")
	var node: Node2D = ed.nodes.get("divisoria_madeira", null)
	check(node != null, "nó da divisória existe")
	ed.set_active(false)
	await dev.wait(0.5)
	var has_body := false
	for c in node.get_children():
		if c is StaticBody2D:
			has_body = true
	check(has_body, "divisória tem colisão")
	await dev.shot(OUT + "v29_divisorias.png")
	print("[v29] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
