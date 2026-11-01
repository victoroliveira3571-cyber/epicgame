extends Node

## v3.7: mapa-múndi, emboscada na estrada, Vila da Neve e Oásis (provisórios) e as duas side quests
## (Bruxo do Submundo na floresta, Pé Grande na caverna). Prints em _shots/v37_mundo_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0
var dev: Node
var _auto := true


func check(cond: bool, what: String) -> void:
	if cond:
		print("[mundo] ok    ", what)
	else:
		fails += 1
		printerr("[mundo] FALHA ", what)


func run(d: Node) -> void:
	dev = d
	_autoplay()
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("paladino")
	GameState.level = 20
	Game.go_to_town("start")
	await dev.wait(2.5)
	# ---- mapa-múndi
	HUD.open_window("mundo")
	await dev.wait(0.6)
	check(HUD.window_id == "mundo", "mapa-múndi abre")
	await dev.shot(OUT + "v37_mundo_mapa.png")
	HUD.close_window()
	# ---- emboscada na estrada a caminho do Oásis
	Game.travel_road("oasis")
	await dev.wait(3.0)
	var road := get_tree().current_scene
	check(road.get("city_id") == "estrada", "estrada da emboscada")
	var foes := get_tree().get_nodes_in_group("enemy").size()
	check(foes >= 5, "monstros no caminho (%d)" % foes)
	await dev.shot(OUT + "v37_mundo_estrada.png")
	var pl: Node2D = get_tree().get_first_node_in_group("player")
	pl.global_position = Vector2((road.W - 1) * 16, 11 * 16)
	await dev.wait(3.0)
	check(get_tree().current_scene.get("city_id") == "oasis", "seguiu a pé até o Oásis")
	await dev.shot(OUT + "v37_mundo_oasis.png")
	# ---- side quest do Bruxo
	Story.st()["rank"] = 1
	check(SideQuests.available(), "Rank E libera as missões especiais")
	SideQuests.d()["bruxo"] = 1
	Game.go_to_forest("town")
	await dev.wait(3.0)
	var monsters := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_meta("sq_bruxo"):
			monsters += 1
			e.take_hit(999999.0, Vector2.ZERO, false)
			await dev.wait(0.2)
	check(monsters == 3, "três monstros do bruxo na Mata")
	await dev.wait(2.0)
	check(SideQuests.stage("bruxo") == 2, "rastro leva às Ruínas")
	Game.go_to_forest("town")
	await dev.wait(3.0)
	var boss: Node = null
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_meta("sq_bruxo_boss"):
			boss = e
	check(boss != null, "Bruxo do Submundo nas Ruínas")
	if boss != null:
		var p2: Node2D = get_tree().get_first_node_in_group("player")
		p2.global_position = boss.global_position + Vector2(0, 50)
		await dev.wait(1.5)
		await dev.shot(OUT + "v37_mundo_bruxo.png")
		boss.take_hit(999999.0, Vector2.ZERO, false)
	await dev.wait(5.0)
	check(SideQuests.stage("bruxo") == 3, "bruxo derrotado")
	check(GameState.count_item("manto_cacador") == 1 and str(GameState.lab_data().get("book_spell", "")) == "trevas", "manto e Magia Sombria")
	# ---- side quest do Pé Grande
	SideQuests.d()["pe_grande"] = 1
	Game.go_to_city("vila_neve")
	await dev.wait(3.0)
	await dev.shot(OUT + "v37_mundo_vila_neve.png")
	await Story.talk("anciao")
	check(SideQuests.stage("pe_grande") == 2, "ancião manda à caverna")
	SideQuests.enter_cave()
	await dev.wait(4.0)
	check(get_tree().current_scene.is_in_group("dungeon") and Game.is_duel(), "duelo na caverna")
	await dev.shot(OUT + "v37_mundo_pe_grande.png")
	var dg := get_tree().current_scene
	if dg.get("boss") != null:
		dg.boss.take_hit(1.0, Vector2.ZERO, false)   # o primeiro golpe acorda o chefe
		await dev.wait(2.5)
		dg.boss.take_hit(999999.0, Vector2.ZERO, false)
	await dev.wait(8.0)
	check(SideQuests.stage("pe_grande") == 3, "Pé Grande derrotado")
	check(get_tree().current_scene.get("city_id") == "vila_neve", "voltou à Vila da Neve")
	check(GameState.count_item("pele_pe_grande") == 1, "Pele do Pé Grande")
	# vestir a armadura única e ver o visual
	GameState.equip_item("pele_pe_grande")
	var p3 := get_tree().get_first_node_in_group("player") as Player
	p3.refresh_sheet()
	await dev.wait(1.5)
	await dev.shot(OUT + "v37_mundo_pele.png")
	_auto = false
	print("[mundo] falhas: ", fails)


func _autoplay() -> void:
	while true:
		await get_tree().create_timer(0.12, true, false, true).timeout
		if not _auto:
			continue
		var box: DialogueBox = HUD._dialog
		if box == null or not is_instance_valid(box):
			continue
		if box.choosing:
			var kids := box._choices.get_children()
			if not kids.is_empty():
				kids[0].emit_signal("pressed")
			continue
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		var ev2 := InputEventKey.new()
		ev2.keycode = KEY_E
		ev2.pressed = false
		Input.parse_input_event(ev2)
