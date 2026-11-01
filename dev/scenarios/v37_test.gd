extends Node

## v3.7 (Lote 3.7, seção A): bússola presa no canto inferior direito, seta que segue a missão das ervas e some
## ao chegar, cerca da Mata antes da ponte (Rank F barra, Rank E passa), modo Decorar com a casa inteira acima
## da caixa, dificuldade e som cortado em trechos. Prints em _shots/v37_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0
var dev: Node


func check(cond: bool, what: String) -> void:
	if cond:
		print("[v37] ok    ", what)
	else:
		fails += 1
		printerr("[v37] FALHA ", what)


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	Story.start_new_game("Teo", "Rui", "Miriam", "m")
	GameState.choose_class("arqueiro")
	# ---- 1) bússola: ao terminar a despedida a mãe dá a bússola; ela voa para o canto inferior direito
	var comp: ObjectiveCompass = HUD._compass
	check(not comp.has_compass(), "sem bússola antes da mãe")
	Story.set_flag("bussola")
	Story.set_step("c1_marta")
	check(comp.has_compass(), "bússola depois da despedida")
	Game.go_to_town("start")
	await dev.wait(2.5)
	var dock := comp.dock_point()
	check(dock.x > UI.SIZE.x * 0.6 and dock.y > UI.SIZE.y * 0.6, "bússola presa no canto inferior direito (%s)" % dock)
	comp.play_gain()
	await dev.wait(1.2)
	await dev.shot(OUT + "v37_bussola_abrindo.png")
	await dev.wait(2.6)
	await dev.shot(OUT + "v37_bussola_canto.png")
	# ---- 2) seta da missão das ervas: erva mais próxima, depois o Pietro, depois some
	Story.set_step("c1_portao")
	Story.st()["credits"] = 5
	Game.go_to_forest("town")
	await dev.wait(2.5)
	var f := get_tree().current_scene
	check(Story.step() == "c1_ervas", "entrar na floresta abre a missão das ervas")
	var pos: Variant = Story.objective_world_pos(f)
	var herbs := get_tree().get_nodes_in_group("forest_herb")
	check(pos is Vector2 and herbs.size() > 0, "seta aponta para uma erva")
	var pl: Player = get_tree().get_first_node_in_group("player")
	var nearest := INF
	for h in herbs:
		nearest = minf(nearest, (h as Node2D).global_position.distance_to(pl.global_position))
	check(pos is Vector2 and absf((pos as Vector2).distance_to(pl.global_position) - nearest) < 0.5, "é a erva mais próxima")
	Story.st()["herbs"] = 5
	pos = Story.objective_world_pos(f)
	var pietro: Node2D = f.get("_pietro_c1")
	check(pietro != null and pos is Vector2 and (pos as Vector2).distance_to(pietro.global_position) < 1.0, "com 5 ervas a seta vai para o Pietro")
	Story.give_pet("corvin")
	Story._check_c1_ervas()
	check(Story.step() == "c1_marca", "com Corvin e 5 ervas o passo muda para a árvore marcada")
	pos = Story.objective_world_pos(f)
	check(pos is Vector2, "seta da árvore marcada")
	await dev.wait(0.3)
	await dev.shot(OUT + "v37_seta_arvore.png")
	# ---- 3) cerca da Mata (Rank F): o herói anda para oeste pela trilha e para antes da ponte
	var fence_x: float = (f.RIVER_X + 4) * f.T + 8
	pl.global_position = Vector2((f.RIVER_X + 9) * f.T, f.PATH_Y * f.T + 10)
	pl.camera.reset_smoothing()
	await dev.wait(0.3)
	Input.action_press("move_left")
	await dev.wait(2.5)
	Input.action_release("move_left")
	check(pl.global_position.x > fence_x, "Rank F: parou na cerca (x=%d, cerca=%d)" % [pl.global_position.x, fence_x])
	check(pl.global_position.x < fence_x + 40.0, "Rank F: chegou até a cerca")
	await dev.shot(OUT + "v37_cerca_mata.png")
	# Rank E: sem cerca, passa a ponte
	Story.st()["rank"] = 1
	Game.go_to_forest("town")
	await dev.wait(2.5)
	f = get_tree().current_scene
	pl = get_tree().get_first_node_in_group("player")
	check(f.get("_barrier") == null, "Rank E: sem cerca")
	pl.global_position = Vector2((f.RIVER_X + 9) * f.T, f.PATH_Y * f.T + 10)
	await dev.wait(0.3)
	Input.action_press("move_left")
	await dev.wait(3.0)
	Input.action_release("move_left")
	check(pl.global_position.x < (f.RIVER_X - 2) * f.T, "Rank E: atravessou a ponte (x=%d)" % pl.global_position.x)
	# ---- 4) modo Decorar: câmera própria com a casa inteira acima da caixa
	GameState.gold = 5000
	for fid in Data.FURNITURE_ORDER:
		GameState.buy_furniture(fid)
	Game.enter_interior("casa")
	await dev.wait(2.0)
	var home: Interior = get_tree().current_scene
	home.housing.set_active(true)
	await dev.wait(0.5)
	var cam := get_viewport().get_camera_2d()
	check(cam != null and cam != home.player.camera, "Decorar usa câmera própria")
	if cam != null:
		var vp := get_viewport().get_visible_rect().size
		var xf := get_viewport().get_canvas_transform()
		var top_left: Vector2 = xf * Vector2.ZERO
		var bottom_right: Vector2 = xf * home.room_px()
		var bar_top := vp.y * (UI.SIZE.y - HousingEditor.BAR_H - 4.0) / UI.SIZE.y
		check(top_left.x >= -1.0 and bottom_right.x <= vp.x + 1.0, "casa inteira na largura")
		check(top_left.y >= -1.0 and bottom_right.y <= bar_top + 1.0, "casa inteira acima da caixa (fundo %d, caixa %d)" % [bottom_right.y, bar_top])
	await dev.shot(OUT + "v37_decorar.png")
	home.housing.set_active(false)
	await dev.wait(0.3)
	check(get_viewport().get_camera_2d() == home.player.camera, "ao sair do Decorar volta a câmera do herói")
	# ---- 5) sons cortados em trechos
	check(Audio.NOVO_PARTS.has("passos_heroi") and Audio.NOVO_PARTS.has("pomodoro_inicio"), "passos e início do Pomodoro em trechos")
	print("[v37] falhas: ", fails)
