extends Node

## v3.7: floresta recomposta pelas referências do Victor (platô com penhascos, escadaria, cascata, ponte no alto,
## Rochedo da Borda com baú diário, nenúfares, canteiros e borda de mata fechada). Sobe as escadas andando de
## verdade (ação move_up), confere que a face do penhasco bloqueia e tira prints em _shots/v37_flo_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0
var dev: Node


func check(cond: bool, what: String) -> void:
	if cond:
		print("[flo] ok    ", what)
	else:
		fails += 1
		printerr("[flo] FALHA ", what)


func _walk(action: String, secs: float) -> void:
	Input.action_press(action)
	await dev.wait(secs)
	Input.action_release(action)
	await dev.wait(0.15)


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("arqueiro")
	Story.st()["rank"] = 2
	GameState.level = 12
	Game.go_to_forest("town")
	await dev.wait(3.0)
	var f := get_tree().current_scene
	check(f.is_in_group("forest"), "floresta carregou")
	var pl: Node2D = get_tree().get_first_node_in_group("player")
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()
	await dev.wait(0.3)
	var T := 16
	# ---- cascata
	pl.global_position = Vector2((f.FALLS_X + 1) * T + 8, (f.PLATEAU_EDGE + 8) * T)
	await dev.wait(1.2)
	await dev.shot(OUT + "v37_flo_cascata.png")
	# ---- face do penhasco bloqueia (anda para cima longe da escada)
	var x_face := 36
	pl.global_position = Vector2(x_face * T + 8, (f.plateau_edge(x_face) + 4) * T + 8)
	await dev.wait(0.3)
	var y0 := pl.global_position.y
	await _walk("move_up", 1.4)
	check(pl.global_position.y > (f.plateau_edge(x_face) + 2) * T, "face do penhasco bloqueia (y %d -> %d)" % [int(y0), int(pl.global_position.y)])
	# ---- escadaria: sobe andando
	pl.global_position = Vector2((f.STAIRS_X + 2) * T, (f.PLATEAU_EDGE + 4) * T + 8)
	await dev.wait(0.3)
	await dev.shot(OUT + "v37_flo_escada.png")
	await _walk("move_up", 1.6)
	check(pl.global_position.y < f.PLATEAU_EDGE * T, "subiu a escadaria (y=%d)" % int(pl.global_position.y))
	# ---- ponte do alto e mirante
	pl.global_position = Vector2((f.RIVER_X - 3) * T, 10 * T)
	await dev.wait(0.3)
	await _walk("move_right", 1.8)
	check(pl.global_position.x > (f.RIVER_X + 3) * T, "atravessou a ponte do platô (x=%d)" % int(pl.global_position.x))
	await dev.shot(OUT + "v37_flo_mirante.png")
	var chest: Node = null
	for c in f.world.get_children():
		if c is DungeonObjects.Chest and c.get("key") == "bau_mirante":
			chest = c
	check(chest != null, "baú do mirante")
	if chest != null:
		var gold0 := GameState.gold
		chest.interact(pl)
		await dev.wait(0.6)
		check(chest.opened and str(Story.flag("bau_mirante", "")) == Time.get_date_string_from_system(), "baú abre e guarda o dia")
	# ---- ponte principal
	pl.global_position = Vector2((f.RIVER_X - 3) * T, f.PATH_Y * T + 8)
	await dev.wait(0.3)
	await _walk("move_right", 1.6)
	check(pl.global_position.x > (f.RIVER_X + 3) * T, "atravessou a ponte principal (x=%d)" % int(pl.global_position.x))
	await dev.shot(OUT + "v37_flo_ponte.png")
	# ---- Rochedo da Borda
	pl.global_position = Vector2((f.MESA_STAIRS_X + 2) * T, (f.MESA.end.y + 3) * T)
	await dev.wait(0.3)
	await _walk("move_up", 1.4)
	check(pl.global_position.y < (f.MESA.end.y - 1) * T, "subiu o Rochedo (y=%d)" % int(pl.global_position.y))
	await dev.shot(OUT + "v37_flo_rochedo.png")
	# ---- pântano (nenúfares e barco) e borda
	pl.global_position = Vector2(37 * T, 60 * T)
	await dev.wait(0.6)
	await dev.shot(OUT + "v37_flo_pantano.png")
	# ---- reentrar: baú continua aberto no mesmo dia
	Game.go_to_forest("town")
	await dev.wait(3.0)
	var f2 := get_tree().current_scene
	var reopened := false
	for c in f2.world.get_children():
		if c is DungeonObjects.Chest and c.get("key") == "bau_mirante" and not c.opened:
			reopened = true
	check(not reopened, "baú do mirante não reabre no mesmo dia")
	print("[flo] falhas: ", fails)
