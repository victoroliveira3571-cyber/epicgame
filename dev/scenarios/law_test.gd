extends Node

## v2.2 lote 3: moradores feridos, guarda, cela, pena em minutos de foco, regeneração e conversa de rua.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var ok := true


func check(c: bool, what: String) -> void:
	print("[law] ", "ok    " if c else "FALHOU ", what)
	ok = ok and c


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	var pl := get_tree().get_first_node_in_group("player") as Player
	# conversa de rua: acha um morador sem história
	var folk: NPC = null
	for n in get_tree().get_nodes_in_group("npc_hit"):
		if n is NPC and not (n as NPC).has_meta("has_talker") and (n as NPC).mode == "wander":
			folk = n
			break
	check(folk != null, "há morador comum na rua")
	pl.global_position = folk.global_position + Vector2(10, 0)
	Street.talk(folk)
	await dev.wait(0.8)
	await dev.shot(OUT + "law_rua.png")
	check(HUD.is_dialogue_open(), "[E] no morador abre a história dele")
	for i in 80:
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await get_tree().create_timer(0.12).timeout
		if not HUD.is_dialogue_open():
			break
	await dev.wait(0.5)
	print("[law] diálogo aberto? ", HUD.is_dialogue_open(), " talking ", folk.talking, " targetable ", folk.is_targetable())
	# agressão
	folk.take_hit(5.0, Vector2.ZERO, false)
	check(folk.hp < folk.max_hp, "morador ferido")
	await dev.wait(2.0)
	check(Law._cop != null and is_instance_valid(Law._cop), "guarda chamado")
	await dev.shot(OUT + "law_guarda.png")
	pl.global_position = Law._cop.global_position + Vector2(8, 0)
	await dev.wait(4.0)
	check(Law.is_jailed() and Law.jail_left() == 90, "preso com cadeia de 90 min (%d)" % Law.jail_left())
	check(get_tree().current_scene is Interior and (get_tree().current_scene as Interior).id == "delegacia", "na delegacia")
	await dev.wait(1.0)
	await dev.shot(OUT + "law_cela.png")
	# a pena é paga com minutos de foco
	Story.add_focus_minutes(20)
	check(Law.jail_left() == 70, "20 min de foco abatem a pena (faltam %d)" % Law.jail_left())
	var cred := Story.credits()
	Story.add_focus_minutes(100)
	check(not Law.is_jailed(), "pena cumprida")
	check(Story.credits() == cred + 1, "100 min: 70 pagam a pena e os 30 que sobram viram 1 crédito")
	await dev.wait(1.5)
	# segunda prisão custa mais
	check(Law.next_fine() == 90, "próxima cadeia continua 90 (%d)" % Law.next_fine())
	Law.data()["murders"] = 0
	print("[law] ", "TUDO OK" if ok else "COM FALHAS")
