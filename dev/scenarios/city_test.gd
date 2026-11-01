extends Node

## v3.2: as três cidades: carrega cada uma, confere prédios/NPCs/mapa, joga o fragmento e a saída.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var fails := 0


func check(c: bool, what: String) -> void:
	print("[cidade] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.level = 30
	Story.st()["credits"] = 20
	Story.st()["focus_min"] = 60 * 20
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	check(Story.chapter() >= 6, "Parte 1 concluída")
	# estação na cidade
	var station := false
	for n in get_tree().get_nodes_in_group("speaker_cocheiro"):
		station = true
	check(station, "Tobias está na estação de carruagens")
	# portões das cidades
	for id in CityData.ORDER:
		Game.go_to_city(id)
		await dev.wait(2.0)
		var sc := get_tree().current_scene
		check(sc.is_in_group("city"), "%s carregou" % id)
		check(sc.buildings.size() >= 5, "%s tem prédios (%d)" % [id, sc.buildings.size()])
		check(sc.map_landmarks().size() >= 6, "%s tem pontos no mapa" % id)
		check(sc.player != null, "%s tem jogador" % id)
		await dev.shot(OUT + "city_%s.png" % id)
		# fragmento
		var npc_id: String = {"porto": "capitao", "pedralta": "granito", "academia": "reitora"}[id]
		check(get_tree().get_nodes_in_group("speaker_" + npc_id).size() == 1, "%s tem o NPC do fragmento" % id)
		var before := CityStory.fragments()
		Story.st()["focus_min"] = 0
		Story.set_flag("fraginit_" + id, true)
		var t0 := Story.credits()
		CityStory.talk(npc_id)
		await dev.wait(0.6)
		Input.parse_input_event(_key(KEY_E))
		# fecha o diálogo "ainda não"
		for i in 30:
			if not HUD.is_dialogue_open():
				break
			Input.parse_input_event(_key(KEY_E))
			await get_tree().create_timer(0.1).timeout
		check(CityStory.fragments() == before, "%s: sem horas não dá fragmento" % id)
		Story.st()["focus_min"] = 60 * 20
		CityStory._reward(id)
		check(CityStory.fragments() == before + 1 and Story.credits() == t0 + 1, "%s: fragmento dá crédito" % id)
	check(CityStory.fragments() == 3, "três fragmentos")
	# Profundezas: sem fragmentos o andar 11 não abre
	for id in CityData.ORDER:
		Story.set_flag("frag_" + id, false)
	GameState.best_floor = 30
	check(not Story.floor_unlocked(11), "andar 11 pede 1 fragmento")
	Story.set_flag("frag_porto", true)
	check(Story.floor_unlocked(11) and not Story.floor_unlocked(16), "1 fragmento abre até o 15")
	Story.set_flag("frag_pedralta", true)
	Story.set_flag("frag_academia", true)
	check(Story.floor_unlocked(21), "3 fragmentos abrem tudo")
	# volta para Focus Town pela estrada
	Game.go_to_city("porto")
	await dev.wait(4.0)
	var city := get_tree().current_scene
	city.player.global_position = Vector2(8, city.player.global_position.y)
	print("[cidade] jogador em ", city.player.global_position, " exit ", city.city["exit"], " leaving ", city._leaving, " transitioning ", Game.transitioning)
	await dev.wait(4.0)
	print("[cidade] cena agora: ", get_tree().current_scene.name, " ", Game.town_spawn)
	check(get_tree().current_scene.is_in_group("town") and not get_tree().current_scene.is_in_group("city"), "a estrada leva de volta a Focus Town")
	print("[cidade] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)


func _key(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.pressed = true
	return ev
