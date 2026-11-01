extends Node

## v3.7: história v4 de ponta a ponta, com os diálogos avançados sozinhos (E) e as escolhas pela fila `picks`:
## criação com classe -> prólogo (pulado com Esc) -> despedida -> carruagem -> Academia (matrícula, aula, três
## missões do jardim com colegas) -> Formatura (sequência de 2 h) -> Exército (alistamento, patrulha, promoção,
## cruzada) e, num segundo save, a Guilda (c1_marta e registro sem janela de classe). Prints em _shots/v4_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0
var dev: Node
var picks: Array = []     # índices das próximas escolhas (o resto escolhe a primeira opção)
var _auto := true


func check(cond: bool, what: String) -> void:
	if cond:
		print("[v4] ok    ", what)
	else:
		fails += 1
		printerr("[v4] FALHA ", what)


func run(d: Node) -> void:
	dev = d
	_autoplay()
	GameState.debug_reset()
	# ---------------------------------------------------------------- criação: nomes, aparência e classe
	HUD.open_window("criacao")
	await dev.wait(0.6)
	var cw: Node = HUD.window
	cw._hero.text = "Teo"
	cw._father.text = "Rui"
	cw._mother.text = "Miriam"
	cw._start()
	await dev.wait(0.5)
	await dev.shot(OUT + "v4_01_classes.png")
	cw._begin("mago")
	await dev.wait(2.5)
	check(Story.step() == "p_prologo", "jogo novo começa no prólogo")
	check(GameState.player_class == "mago", "classe escolhida na criação")
	check(Story.chapter() == 0, "capítulo 0 (prólogo/Academia)")
	# ---------------------------------------------------------------- prólogo (deixa a primeira cena rodar, depois Esc)
	await dev.wait(5.0)
	await dev.shot(OUT + "v4_02_berco.png")
	var pro: Node = _find_prologue()
	check(pro != null, "prólogo rodando na casa da família")
	await dev.wait(14.0)
	await dev.shot(OUT + "v4_03_montagem.png")
	if pro != null and is_instance_valid(pro):
		pro._skip = true
	for i in 240:
		if Story.step() == "a_viagem" and not HUD.is_dialogue_open():
			break
		await dev.wait(0.25)
	await dev.wait(1.0)
	await dev.shot(OUT + "v4_03b_casa.png")
	check(Story.flag("bussola", false), "despedida da mãe deu a bússola")
	check(Story.step() == "a_viagem", "depois da despedida: viagem para a Academia (passo %s)" % Story.step())
	# ---------------------------------------------------------------- carruagem (bolsa) até a Academia
	Game.go_to_town("start")
	await dev.wait(2.5)
	var dest: Array = CityStory._destinations()
	check(dest.size() == 1 and dest[0][0] == "academia" and int(dest[0][2]) == 0, "carruagem: só a Academia, de graça")
	await Story.talk("cocheiro")
	await dev.wait(3.0)
	check(get_tree().current_scene.has_method("is_academy") and get_tree().current_scene.is_academy(), "chegou à Academia")
	await dev.shot(OUT + "v4_04_academia.png")
	await Story.talk("reitora")
	check(Story.step() == "a_aula", "matrícula feita")
	await Story.talk("lin_a")
	check(Story.step() == "a_jardim", "aula do Mestre Lin abre o jardim")
	# ---------------------------------------------------------------- missões do jardim
	await Story.talk("lin_a")
	check(not bool(AcademyStory.d()["on"]), "sem horas: a missão não abre")
	for m in 3:
		Story.add_focus_minutes(40)
		await Story.talk("lin_a")
		check(bool(AcademyStory.d()["on"]), "missão %d aberta com horas de foco" % (m + 1))
		await dev.wait(0.8)
		var allies := get_tree().get_nodes_in_group("ally").size()
		check(allies >= 2, "colegas lutando junto na missão %d (%d)" % [m + 1, allies])
		if m == 0:
			var pl: Node2D = get_tree().get_first_node_in_group("player")
			pl.global_position = get_tree().current_scene._tile_pos(40, 51)
			await dev.wait(2.0)
			await dev.shot(OUT + "v4_05_jardim.png")
		for e in get_tree().get_nodes_in_group("enemy"):
			if e.has_meta("jardim"):
				e.take_hit(99999.0, Vector2.ZERO, false)
		await dev.wait(0.6)
		check(bool(AcademyStory.d()["done"]), "missão %d cumprida" % (m + 1))
		await Story.talk("lin_a")
	check(Story.step() == "a_formatura", "três missões: Formatura")
	# ---------------------------------------------------------------- Formatura: sequência de foco
	await Story.talk("reitora")
	check(Story.step() == "a_formatura", "sem a sequência, ainda não forma")
	Story.on_focus_session(25, false)
	Story.on_focus_session(25, true)   # finalizar antes da hora zera
	check(int(AcademyStory.d()["streak"]) == 0, "finalizar antes da hora zera a sequência")
	for k in 5:
		AcademyStory.d()["end"] = int(Time.get_unix_time_from_system()) - 25 * 60 - 120
		Story.on_focus_session(25, false)
	check(int(AcademyStory.d()["best"]) >= 120, "cinco focos de 25 min seguidos = %d min" % int(AcademyStory.d()["best"]))
	picks = [1]   # Exército
	await Story.talk("reitora")
	check(Story.path() == "exercito" and Story.step() == "b_alistar", "escolheu o Exército")
	check(Story.rank_name() == "Recruta", "patente no cartão: %s" % Story.rank_name())
	# ---------------------------------------------------------------- Exército: Pedralta
	Game.go_to_town("start")
	await dev.wait(2.5)
	dest = CityStory._destinations()
	check(not dest.is_empty() and dest[0][0] == "pedralta" and int(dest[0][2]) == 0, "recruta vai de graça a Pedralta")
	Game.go_to_city("pedralta")
	await dev.wait(3.0)
	await dev.shot(OUT + "v4_06_pedralta.png")
	await Story.talk("brigida")
	check(Story.step() == "b_missao", "alistamento")
	await Story.talk("brigida")
	check(bool(ArmyStory.d()["on"]), "patrulha da Borda aceita")
	check(Story.has_trail_pass(), "insígnia vale como passe da floresta")
	ArmyStory.d()["kills"] = 7
	Game.go_to_forest("town")
	await dev.wait(2.5)
	var f := get_tree().current_scene
	for e in get_tree().get_nodes_in_group("enemy"):
		var p: Vector2 = e.global_position
		if f.zone_at(int(p.x / 16), int(p.y / 16)) == "borda":
			e.take_hit(99999.0, Vector2.ZERO, false)
			break
	await dev.wait(0.5)
	check(bool(ArmyStory.d()["done"]), "patrulha cumprida (8/8)")
	Game.go_to_city("pedralta")
	await dev.wait(2.5)
	await Story.talk("brigida")
	check(ArmyStory.patente() == 1 and Story.rank_name() == "Soldado", "promovido a Soldado")
	# side quests: quadro especial ainda fechado para Soldado
	check(not SideQuests.available(), "missões especiais pedem patente de Cabo")
	ArmyStory.d()["patente"] = 2
	check(SideQuests.available(), "Cabo libera as missões especiais")
	# ---------------------------------------------------------------- segundo save: Guilda
	GameState.debug_reset()
	Story.start_new_game("Ana", "Rui", "Lia", "f")
	GameState.choose_class("arqueiro")
	Story.st()["step"] = "a_escolha"
	picks = [0]
	await AcademyStory.choose_path()
	check(Story.path() == "aventureiro" and Story.step() == "c1_marta" and Story.chapter() == 1, "Guilda: começa o capítulo 1 na Dona Marta")
	Story.set_step("c1_guilda")
	await Story.talk("helena")
	check(Story.step() == "c1_portao" and not HUD.is_window_open(), "registro sem janela de classe")
	check(Story.has_trail_pass(), "cartão da Guilda")
	check(Story.rank_name() == "Rank F", "Rank F no cartão")
	_auto = false
	print("[v4] falhas: ", fails)


func _find_prologue() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	for c in scene.get_children():
		if c is Prologue:
			return c
	return null


## Avança diálogos sozinho: E para seguir; nas escolhas, usa a fila `picks` (ou a primeira opção).
func _autoplay() -> void:
	while true:
		await get_tree().create_timer(0.12, true, false, true).timeout
		if not _auto:
			continue
		var box: DialogueBox = HUD._dialog
		if box == null or not is_instance_valid(box):
			continue
		if box.choosing:
			var i: int = picks.pop_front() if not picks.is_empty() else 0
			var kids := box._choices.get_children()
			if i < kids.size():
				kids[i].emit_signal("pressed")
			continue
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		var ev2 := InputEventKey.new()
		ev2.keycode = KEY_E
		ev2.pressed = false
		Input.parse_input_event(ev2)
