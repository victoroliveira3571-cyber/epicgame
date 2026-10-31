extends Node

## Joga a história inteira (prólogo ao Rei Demônio) com atalhos: pula as falas, responde as
## perguntas dos chefes e teleporta o jogador. Confere os passos e tira prints em _shots/story_*.png.
## Rodar: tools/run_godot.sh 600 --resolution 1280x720 -- --scenario=story_test --save=dev_save.json

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var dev: Node
var fails: int = 0


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	await dev.wait(0.5)
	# ---------------------------------------------------------------- criação
	HUD.open_window("criacao")
	await dev.wait(0.6)
	await dev.shot(OUT + "story_01_criacao.png")
	HUD.close_window()
	Story.start_new_game("Ana", "Rui", "Lia", "f")
	HUD.close_window()
	Game.enter_interior("casa_familia")
	await dev.wait(2.2)
	await dev.shot(OUT + "story_02_despedida.png")
	await skip()
	check("c1_marta")
	await _leave_interior()
	await dev.wait(1.5)
	await skip()
	await dev.wait(1.2)
	check_scene("Town")
	await dev.shot(OUT + "story_03_cidade.png")
	# ---------------------------------------------------------------- pousada e Guilda
	await talk("marta")
	check("c1_guilda")
	Story.talk("helena")
	await dev.wait(0.4)
	await skip()
	await dev.wait(0.4)
	await dev.shot(OUT + "story_04_classe.png")
	print("[story] janela: ", HUD.window_id)
	GameState.choose_class("cavaleiro")
	HUD.close_window()
	Story.on_class_chosen()
	await dev.wait(0.3)
	await skip()
	check("c1_portao")
	print("[story] arma: ", GameState.equipped.get("weapon"), " rank: ", Story.rank_name())
	# ---------------------------------------------------------------- Osvaldo sem crédito
	await talk("osvaldo")
	check_scene("Town")
	GameState.complete_focus_session(240, 120, 60)
	print("[story] créditos: ", Story.credits(), " horas: ", Story.focus_hours())
	if Story.credits() != 1:
		fail("crédito depois de 60 min")
	Story.talk("osvaldo")
	await dev.wait(0.3)
	await skip()
	await dev.wait(2.0)
	check_scene("Forest")
	print("[story] créditos depois do pedágio: ", Story.credits(), " passe: ", Story.has_pass("floresta"))
	await dev.shot(OUT + "story_05_floresta_borda.png")
	# ---------------------------------------------------------------- capítulo 1 na floresta
	var forest := get_tree().current_scene
	if Story.step() != "c1_ervas":
		Story.st()["step"] = "c1_ervas"
	for i in 5:
		Story.on_herb()
	forest.player.global_position = forest._pietro_c1.global_position + Vector2(60, 0)
	await dev.wait(1.2)
	await skip()
	await dev.wait(0.6)
	var wolf := _enemy_named("Lobo Faminto")
	if wolf == null:
		fail("lobo do Pietro não apareceu")
	else:
		wolf.take_hit(9999.0, Vector2.ZERO, false)
	await dev.wait(1.5)
	await skip()
	check("c1_marca")
	print("[story] pets: ", Story.pets())
	await dev.wait(0.6)
	await dev.shot(OUT + "story_06_corvin.png")
	var mark := _prop("Examinar a árvore marcada")
	forest.player.global_position = mark.global_position + Vector2(0, 14)
	await dev.wait(0.3)
	mark.interact(forest.player)
	await dev.wait(0.3)
	await skip()
	await dev.wait(0.5)
	var boss := _boss()
	if boss == null:
		fail("Espírito do Caçador não apareceu")
	else:
		forest.player.global_position = boss.global_position + Vector2(0, 40)
		await dev.wait(1.0)
		await dev.shot(OUT + "story_07_espirito.png")
		await kill_boss(boss)
	check("c1_volta")
	# ---------------------------------------------------------------- capítulo 2
	Game.enter_interior("guilda")
	await dev.wait(1.5)
	await talk("helena")
	check("c2_exame")
	await dev.shot(OUT + "story_08_guilda.png")
	await talk("helena")
	check("c2_pena")
	Game.go_to_forest("town")
	await dev.wait(2.0)
	forest = get_tree().current_scene
	var pena := _prop("Pegar a Pena Dourada")
	pena.interact(forest.player)
	await dev.wait(0.3)
	await skip()
	check("c2_entrega")
	Game.enter_interior("guilda")
	await dev.wait(1.5)
	await talk("helena")
	check("c2_pietro")
	if Story.rank() != 1:
		fail("rank E")
	Game.go_to_forest("town")
	await dev.wait(2.0)
	forest = get_tree().current_scene
	forest.player.global_position = forest._tile_pos(64, 36)
	await dev.wait(0.8)
	await dev.shot(OUT + "story_09_clareira.png")
	await talk("pietro")
	check("c2_brisa")
	Game.go_to_forest("town")
	await dev.wait(2.0)
	forest = get_tree().current_scene
	var den := _prop("Aproximar-se da toca")
	forest.player.global_position = den.global_position + Vector2(0, 10)
	await dev.wait(0.6)
	await dev.shot(OUT + "story_10_toca.png")
	den.interact(forest.player)
	await dev.wait(0.3)
	await skip(0)
	check("c2_lin")
	print("[story] pets: ", Story.pets(), " ativo: ", Story.active_pet())
	await talk("lin")
	check("c2_carta")
	Story.on_notebook_written()
	check("c2_ruinas")
	Game.go_to_forest("town")
	await dev.wait(2.0)
	forest = get_tree().current_scene
	forest.player.global_position = forest._tile_pos(30, 30)
	await dev.wait(0.8)
	await dev.shot(OUT + "story_11_mata.png")
	forest.player.global_position = forest._tile_pos(30, 58)
	await dev.wait(0.8)
	await dev.shot(OUT + "story_12_pantano.png")
	forest.player.global_position = forest._tile_pos(15, 36)
	await dev.wait(1.2)
	await skip()
	check("c2_sentinela")
	boss = _boss()
	GameState.complete_focus_session(240, 120, 60)   # 2 h
	forest.player.global_position = boss.global_position + Vector2(0, 60)
	await dev.wait(1.2)
	await skip()
	await dev.wait(0.8)
	await dev.shot(OUT + "story_13_sentinela_pergunta.png")
	await answer_quizzes()
	await kill_boss(boss)
	check("c2_marta")
	print("[story] pets: ", Story.pets())
	Game.enter_interior("restaurante")
	await dev.wait(1.5)
	await talk("marta")
	check("c3_lin")
	# ---------------------------------------------------------------- capítulo 3
	Game.enter_interior("guilda")
	await dev.wait(1.5)
	await talk("lin")
	check("c3_paginas")
	GameState.complete_focus_session(240, 120, 120)   # 4 h, créditos para os andares
	print("[story] créditos: ", Story.credits(), " horas: ", Story.focus_hours())
	HUD.open_window("dungeon")
	await dev.wait(0.5)
	await dev.shot(OUT + "story_14_portao.png")
	HUD.close_window()
	Game.enter_dungeon(1)
	await dev.wait(2.5)
	check_scene("Dungeon")
	var dun := get_tree().current_scene
	var pages := 0
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is StoryProp and (n as StoryProp).text.begins_with("Pegar a página"):
			(n as StoryProp).interact(dun.player)
			pages += 1
	print("[story] páginas: ", pages, " -> ", Story.st().get("pages"))
	var ivo := _prop("Alguém está preso")
	if ivo != null:
		dun.player.global_position = ivo.global_position + Vector2(0, 14)
		await dev.wait(0.5)
		await dev.shot(OUT + "story_15_ivo_preso.png")
		ivo.interact(dun.player)
		await dev.wait(0.3)
		await skip(0)
	Game.finish_run(false)
	await dev.wait(2.0)
	HUD.close_window()
	Game.enter_interior("guilda")
	await dev.wait(1.5)
	await talk("lin")
	await dev.wait(0.3)
	await skip()
	check("c3_exame")
	Game.enter_dungeon(2)
	await dev.wait(2.5)
	dun = get_tree().current_scene
	boss = dun.boss
	dun.player.global_position = boss.global_position + Vector2(0, 70)
	await dev.wait(1.2)
	await skip()
	await dev.wait(0.6)
	await dev.shot(OUT + "story_16_bibliotecario.png")
	await answer_quizzes()
	await kill_boss(boss)
	check("c3_volta")
	Game.finish_run(false)
	await dev.wait(2.0)
	HUD.close_window()
	# ---------------------------------------------------------------- capítulo 4
	Game.enter_interior("guilda")
	await dev.wait(1.5)
	await talk("helena")
	check("c4_torneio")
	Story.talk("helena")
	await dev.wait(0.3)
	await skip()
	await dev.wait(2.5)
	dun = get_tree().current_scene
	boss = dun.boss
	dun.player.global_position = boss.global_position + Vector2(0, 50)
	await dev.wait(1.0)
	await dev.shot(OUT + "story_17_duelo.png")
	await kill_boss(boss)
	await dev.wait(2.5)
	check("c4_pietro")
	print("[story] rank: ", Story.rank_name(), " cena: ", get_tree().current_scene.name)
	await talk("pietro")
	check("c4_cavaleiro")
	GameState.complete_focus_session(240, 120, 120)   # 6 h
	Game.enter_dungeon(3)
	await dev.wait(2.5)
	await dev.wait(1.2)
	await skip()
	await dev.shot(OUT + "story_18_espelhos.png")
	Game.finish_run(false)
	await dev.wait(2.0)
	HUD.close_window()
	GameState.complete_focus_session(240, 120, 240)   # créditos para o andar 4
	Game.enter_dungeon(4)
	await dev.wait(2.5)
	dun = get_tree().current_scene
	boss = dun.boss
	dun.player.global_position = boss.global_position + Vector2(0, 70)
	await dev.wait(1.2)
	await skip()
	await answer_quizzes()
	await dev.shot(OUT + "story_19_cavaleiro.png")
	await kill_boss(boss)
	check("c4_volta")
	Game.finish_run(false)
	await dev.wait(2.0)
	HUD.close_window()
	Game.enter_interior("guilda")
	await dev.wait(1.5)
	await talk("lin")
	check("c5_trono")
	# ---------------------------------------------------------------- capítulo 5
	GameState.complete_focus_session(240, 120, 300)   # 8 h + créditos
	Game.enter_dungeon(5)
	await dev.wait(2.5)
	await dev.wait(1.0)
	await skip()
	dun = get_tree().current_scene
	boss = dun.boss
	dun.player.global_position = boss.global_position + Vector2(0, 70)
	await dev.wait(1.2)
	await skip()
	await dev.shot(OUT + "story_20_rei.png")
	await answer_quizzes()
	await kill_boss(boss)
	await dev.shot(OUT + "story_21_final.png")
	check("fim")
	print("[story] capítulo: ", Story.chapter(), " rank: ", Story.rank_name(), " andar 6 liberado: ", Story.floor_unlocked(6))
	print("[story] RESULTADO: %d falhas" % fails)


# ================================================================== ajudas
func check(step: String) -> void:
	if Story.step() != step:
		fail("passo esperado %s, atual %s" % [step, Story.step()])
	else:
		print("[story] ok ", step)


func check_scene(n: String) -> void:
	if get_tree().current_scene == null or get_tree().current_scene.name != n:
		fail("cena esperada %s, atual %s" % [n, get_tree().current_scene.name if get_tree().current_scene else "?"])


func fail(msg: String) -> void:
	fails += 1
	printerr("[story] FALHA: ", msg)


func talk(npc: String) -> void:
	Story.talk(npc)
	await dev.wait(0.3)
	await skip()
	await dev.wait(0.2)


## Pula as falas abertas (escolhas: opção `choice`). Espera aparecer diálogo novo por um tempo.
func skip(choice: int = 0) -> void:
	var idle := 0.0
	while idle < 0.6:
		if HUD.is_dialogue_open():
			idle = 0.0
			var box: DialogueBox = HUD._dialog
			if box.choosing:
				var btns := box._choices.get_children()
				if btns.size() > choice:
					(btns[choice] as Button).pressed.emit()
			else:
				box.typing = false
				box._next()
			await get_tree().process_frame
		else:
			idle += 0.05
			await dev.wait(0.05)


func answer_quizzes() -> void:
	var idle := 0.0
	while idle < 1.0:
		var q := _quiz()
		if q != null:
			idle = 0.0
			Recall.record(q.card, "full")
			q.done.emit({"result": "full", "hints": 0})
			await dev.wait(0.3)
			await skip()
		else:
			idle += 0.1
			await dev.wait(0.1)


func kill_boss(boss: Node) -> void:
	var guard := 0
	while is_instance_valid(boss) and boss.state != Enemy.State.DEAD and guard < 40:
		guard += 1
		await skip()
		await answer_quizzes()
		if is_instance_valid(boss) and boss.state != Enemy.State.DEAD:
			boss.take_hit(boss.max_hp * 0.2, Vector2.ZERO, false)
		await dev.wait(0.3)
	await dev.wait(1.6)
	await skip()
	await dev.wait(0.5)
	await skip()


func _quiz() -> QuizPanel:
	for c in HUD.root.get_children():
		if c is QuizPanel:
			return c
	return null


func _enemy_named(n: String) -> Enemy:
	for e in get_tree().get_nodes_in_group("enemy"):
		if (e as Enemy).display_name == n:
			return e
	return null


func _boss() -> Boss:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Boss:
			return e
	return null


func _prop(prefix: String) -> StoryProp:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is StoryProp and (n as StoryProp).text.begins_with(prefix):
			return n
	return null


func _leave_interior() -> void:
	var interior := get_tree().current_scene
	interior._leave()
	await dev.wait(0.4)
