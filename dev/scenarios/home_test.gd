extends Node

## Casa com todos os móveis: testa arrumar (pegar/soltar) e se a posição é lembrada ao reentrar.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

func run(dev: Node) -> void:
	GameState.debug_reset()
	GameState.choose_class("escudeiro")
	GameState.gold = 5000
	for f in Data.FURNITURE_ORDER:
		GameState.buy_furniture(f)
	Game.enter_interior("casa")
	await dev.wait(1.5)
	var home: Interior = get_tree().current_scene
	var pl: Player = get_tree().get_first_node_in_group("player")
	pl.camera.zoom = Vector2(2.2, 2.2)
	pl.camera.reset_smoothing()
	await dev.wait(0.4)
	await dev.shot(OUT + "home_1_default.png")
	# entra no modo arrumar, pega a cama e solta em outro lugar
	home._set_edit_mode(true)
	var cama: Node2D = home.furniture_nodes["cama"]
	var from := cama.position
	home._pick_at(cama.position + Vector2(0, -10))
	print("[home] pegou: ", home.picked_id)
	Input.warp_mouse(Vector2(900, 500))
	await dev.wait(0.2)
	home.picked_id = "cama"
	cama.position = Vector2(300, 170)
	GameState.set_furniture_pos("cama", cama.position)
	home.picked_id = ""
	await dev.shot(OUT + "home_2_edit.png")
	home._set_edit_mode(false)
	print("[home] cama de ", from, " para ", cama.position, " layout=", GameState.furniture_layout.get("cama"))
	# sai e entra de novo: a posição fica
	home._leave()
	await dev.wait(1.5)
	Game.enter_interior("casa")
	await dev.wait(1.5)
	var home2: Interior = get_tree().current_scene
	print("[home] reentrou: cama em ", home2.furniture_nodes["cama"].position)
	# descansar
	GameState.hp = 1
	for s in get_tree().get_nodes_in_group("interactable"):
		if s.has_meta("fid") and s.get_meta("fid") == "cama":
			s.interact(null)
	print("[home] vida apos descansar: ", GameState.hp, "/", GameState.get_max_hp())
