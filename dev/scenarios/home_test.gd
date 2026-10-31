extends Node

## Casa e modo Decorar: móveis comprados vão para a caixa, saem da caixa para a grade, giram,
## não entram em cima de outro, voltam para a caixa e a posição/giro ficam no save ao reentrar.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("[home] FALHA: ", what)


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("escudeiro")
	GameState.gold = 5000
	for f in Data.FURNITURE_ORDER:
		GameState.buy_furniture(f)
	check(not GameState.is_furniture_placed("cama"), "móvel comprado deveria ir para a caixa")
	# saves antigos: comprado sem estar guardado = posto no lugar padrão
	GameState.furniture_stored.erase("cama")
	GameState.furniture_stored.erase("tapete")
	Game.enter_interior("casa")
	await dev.wait(1.5)
	var home: Interior = get_tree().current_scene
	var ed := home.housing
	var pl: Player = get_tree().get_first_node_in_group("player")
	pl.camera.zoom = Vector2(2.2, 2.2)
	pl.camera.reset_smoothing()
	check(ed.nodes.has("cama") and ed.nodes.has("tapete"), "cama e tapete na casa")
	check(not ed.nodes.has("sofa"), "sofá ainda na caixa")
	await dev.wait(0.4)
	await dev.shot(OUT + "home_1_default.png")
	ed.set_active(true)
	await dev.wait(0.3)
	# tira o sofá da caixa e põe num lugar livre
	ed._take_from_box("sofa")
	ed._drag_from_bar = false
	var free_pos := ed._snap("sofa", Vector2(260, 140), 0)
	ed.nodes["sofa"].position = free_pos
	ed._valid = ed.is_free("sofa", free_pos, 0)
	check(ed._valid, "lugar livre para o sofá")
	ed.held_rot = 1
	ed._apply_rot(ed.nodes["sofa"], "sofa", 1)
	ed._drop()
	check(GameState.is_furniture_placed("sofa"), "sofá posto")
	check(GameState.furniture_rot("sofa") == 1, "giro do sofá salvo")
	check(int(free_pos.x) % 1 == 0 and fmod(free_pos.y, HousingEditor.GRID) == 0.0, "posição na grade")
	# em cima da cama não pode
	var bed: Vector2 = ed.nodes["cama"].position
	ed._take_from_box("comoda")
	ed._drag_from_bar = false
	ed.nodes["comoda"].position = bed
	check(not ed.is_free("comoda", bed, 0), "cômoda em cima da cama deveria ser recusada")
	ed._cancel()
	check(not ed.nodes.has("comoda") and not GameState.is_furniture_placed("comoda"), "cancelar devolve à caixa")
	# tapete gira de 90 graus
	ed._pick("tapete")
	ed._rotate()
	var tp: Vector2 = ed._snap("tapete", ed.nodes["tapete"].position, ed.held_rot)
	ed.nodes["tapete"].position = tp
	ed._valid = ed.is_free("tapete", tp, ed.held_rot)
	print("[home] tapete em ", tp, " giro ", ed.held_rot, " livre ", ed._valid, " pegada ", ed.footprint("tapete", tp, ed.held_rot), " piso ", home.floor_rect())
	ed._drop()
	check(GameState.furniture_rot("tapete") == 1, "tapete girado")
	# segura um móvel para o print
	ed._take_from_box("tatame")
	ed._drag_from_bar = false
	await dev.wait(0.3)
	await dev.shot(OUT + "home_2_edit.png")
	ed._cancel()
	# guarda a cama
	ed.store("cama")
	check(not GameState.is_furniture_placed("cama") and GameState.owns_furniture("cama"), "cama guardada")
	ed.set_active(false)
	# sai e entra de novo: posição e giro ficam
	home._leave()
	await dev.wait(1.5)
	Game.enter_interior("casa")
	await dev.wait(1.5)
	var home2: Interior = get_tree().current_scene
	var ed2 := home2.housing
	print("[home] sofá ", free_pos, " -> ", ed2.nodes["sofa"].position if ed2.nodes.has("sofa") else "nada", " layout ", GameState.furniture_layout.get("sofa"))
	check(ed2.nodes.has("sofa") and ed2.nodes["sofa"].position == free_pos, "sofá no mesmo lugar ao reentrar")
	check(not ed2.nodes.has("cama"), "cama continua guardada")
	var spr := ed2.nodes["sofa"].get_child(0) as Sprite2D
	check(spr.flip_h, "sofá continua virado")
	await dev.wait(0.3)
	await dev.shot(OUT + "home_3_reentrou.png")
	print("[home] falhas: ", fails)
