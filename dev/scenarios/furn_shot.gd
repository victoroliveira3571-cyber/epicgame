extends Node

## Põe os móveis LPC novos (e os trocados) na casa para ver o visual.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")

func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("escudeiro")
	HUD.close_window()
	GameState.gold = 5000
	for f in Data.FURNITURE_ORDER:
		GameState.buy_furniture(f)
	for f in ["cama", "mesa", "tapete", "estante", "relogio"]:
		GameState.store_furniture(f)
	Game.enter_interior("casa")
	await dev.wait(1.5)
	var home: Interior = get_tree().current_scene
	var ed := home.housing
	var spots := {
		"armario": Vector2(60, 70), "louceiro": Vector2(100, 70), "comoda": Vector2(140, 70), "lareira_tijolos": Vector2(250, 70),
		"sofa": Vector2(60, 140), "sofa_veludo": Vector2(120, 140), "sofa_imperial": Vector2(190, 140), "poltrona": Vector2(250, 140),
		"banco_estofado": Vector2(60, 180), "cadeira": Vector2(110, 180), "pufe": Vector2(140, 180), "abajur": Vector2(170, 180),
		"barris": Vector2(220, 190), "mesa_toalha": Vector2(290, 150), "mesa_redonda": Vector2(330, 190), "mesa_centro": Vector2(380, 150),
	}
	ed.set_active(true)
	await dev.wait(0.3)
	for f in spots:
		ed._take_from_box(f)
		ed._drag_from_bar = false
		var sp: Vector2 = ed._snap(f, spots[f], 0)
		ed.nodes[f].position = sp
		ed._valid = true
		ed._drop()
	var pl: Player = get_tree().get_first_node_in_group("player")
	pl.camera.zoom = Vector2(2.2, 2.2)
	pl.camera.reset_smoothing()
	await dev.wait(0.6)
	print("colocados: ", ed.nodes.keys())
	await dev.shot(OUT + "furn_casa.png")
