extends Node

## v3.7: ofícios novos jogados por script: turno na cozinha (pega, cozinha e serve), turno na forja (fornalha,
## ritmo na bigorna com teclas simuladas, têmpera e entrega), Fórmula Secreta (laboratório) e Ateliê (costura).
## Confere pontos, patentes de ofício e a volta ao lugar de origem. Prints em _shots/v37_of_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0
var dev: Node


func check(cond: bool, what: String) -> void:
	if cond:
		print("[of] ok    ", what)
	else:
		fails += 1
		printerr("[of] FALHA ", what)


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	Game.go_to_town("start")
	await dev.wait(2.0)
	await _kitchen()
	await _forge()
	await _lab()
	await _sew()
	print("[of] falhas: ", fails)


func _start_shift(id: String) -> WorkShift:
	WorkShift.begin(id)
	await dev.wait(2.0)
	check(HUD.window_id == "mg_turno", "%s: janela de introdução" % id)
	await dev.shot(OUT + "v37_of_%s_intro.png" % id)
	ShiftWindow.choice = "start"
	HUD.close_window()
	await dev.wait(3.4)
	var s: WorkShift = null
	for c in get_tree().current_scene.get_children():
		if c is WorkShift:
			s = c
	check(s != null and s.running, "%s: turno rodando" % id)
	return s


func _end_shift(s: WorkShift, id: String) -> void:
	s.time_left = 0.01
	await dev.wait(0.5)
	check(HUD.window_id == "mg_turno", "%s: resultado" % id)
	await dev.shot(OUT + "v37_of_%s_fim.png" % id)
	ShiftWindow.choice = "exit"
	HUD.close_window()
	await dev.wait(2.0)
	check(get_tree().current_scene.is_in_group("town") or get_tree().current_scene.is_in_group("interior"), "%s: voltou" % id)


# ------------------------------------------------------------------ cozinha
func _kitchen() -> void:
	var s: KitchenShift = await _start_shift("cozinha")
	if s == null:
		return
	# cliente que pede coxa
	s._cust[0] = {}
	s._spawn_customer(0)
	s._cust[0]["order"] = "coxa"
	(s._cust[0]["st"] as WorkShift.Station).item_tex = KitchenShift.tex_of("coxa")
	s._take_crate("coxa_crua")
	check(s.carry == "coxa_crua", "pegou coxa crua")
	s._use_stove(s._stoves[0])
	check(s._stoves[0]["state"] == "cooking", "coxa no fogão")
	var pl: Node2D = get_tree().get_first_node_in_group("player")
	pl.global_position = Vector2(232, 100)
	await dev.wait(2.0)
	await dev.shot(OUT + "v37_of_cozinha_jogo.png")
	await dev.wait(3.6)
	check(s._stoves[0]["state"] == "ready", "coxa pronta (brilha)")
	s._use_stove(s._stoves[0])
	check(s.carry == "coxa", "tirou a coxa assada")
	s._serve(s._cust[0])
	check(s._served == 1 and s.points > 0.0, "serviu o cliente (+%d)" % int(s.points))
	# bife na tábua, hambúrguer na mesa
	s._take_crate("bife_cru")
	s._use_board()
	for i in 4:
		s._use_board()
	check(s.carry == "bife_prep", "bife batido na tábua")
	s.set_carry("bife", KitchenShift.tex_of("bife"))
	s._use_plate()
	s._take_crate("pao")
	s._use_plate()
	s._use_plate()
	check(s.carry == "hamburguer", "hambúrguer montado")
	await _end_shift(s, "cozinha")
	check(GameState.profession_xp("cozinha") > 0, "experiência de cozinheiro")


# ------------------------------------------------------------------ forja
func _forge() -> void:
	var s: ForgeShift = await _start_shift("forja")
	if s == null:
		return
	s._bar = {"stage": "fria", "heat_q": 0.0, "warm": 0.0, "hammer_q": 0.0, "quench_q": 0.0}
	s.set_carry("fria", s._bar_tex())
	s._use_furnace()
	check(s._furnace["state"] == "heating", "barra na fornalha")
	s._furnace["t"] = ForgeShift.HEAT_TIME * 0.74
	await dev.wait(0.1)
	s._use_furnace()
	check(s.carry == "quente" and float(s._bar["heat_q"]) >= 0.99, "tirou no ponto")
	var pl: Node2D = get_tree().get_first_node_in_group("player")
	pl.global_position = Vector2(176, 150)
	s._start_hammer()
	await dev.wait(0.2)
	check(s._rhythm != null, "trilha de ritmo aberta")
	var shot := false
	while s._rhythm != null:
		var r = s._rhythm
		for i in r._notes.size():
			if r._graded[i] == "" and absf(r._t - float(r._notes[i])) < 0.03:
				var ev := InputEventKey.new()
				ev.keycode = KEY_SPACE
				ev.pressed = true
				Input.parse_input_event(ev)
				var ev2 := InputEventKey.new()
				ev2.keycode = KEY_SPACE
				ev2.pressed = false
				Input.parse_input_event(ev2)
				if i == 2 and not shot:
					shot = true
					await get_tree().process_frame
					await dev.shot(OUT + "v37_of_forja_ritmo.png")
		await get_tree().process_frame
	check(s.carry == "batida" and float(s._bar["hammer_q"]) >= 0.8, "martelada no ritmo (%d%%)" % int(float(s._bar.get("hammer_q", 0.0)) * 100.0))
	s._use_tub()
	for i in 200:
		var v := s._tub_st.progress
		if v >= 0.5 and v <= 0.57:
			break
		await get_tree().process_frame
	s._use_tub()
	check(s.carry == "pronta" and float(s._bar["quench_q"]) >= 0.99, "têmpera na faixa")
	s._deliver()
	check(s._done == 1 and s.points > 12.0, "peça entregue (+%d)" % int(s.points))
	await _end_shift(s, "forja")


# ------------------------------------------------------------------ laboratório
func _lab() -> void:
	HUD.open_window("mg_lab")
	await dev.wait(0.5)
	var w = HUD.window
	await dev.shot(OUT + "v37_of_lab_intro.png")
	w._begin()
	await dev.wait(0.3)
	# um teste errado, depois a resposta
	for rnd in 3:
		var r: Dictionary = w.ROUNDS[w._round]
		var wrong: Array = []
		for k in int(r["slots"]):
			wrong.append((int(w._secret[k]) + 1) % int(r["pool"]))
		if not bool(r["repeat"]):
			wrong = []
			for k in int(r["pool"]):
				if wrong.size() < int(r["slots"]):
					wrong.append(k)
		w._guess = wrong
		w._mix()
		if rnd == 1:
			await dev.wait(0.2)
			await dev.shot(OUT + "v37_of_lab_jogo.png")
		if w._pause_t <= 0.0:
			w._guess = w._secret.duplicate()
			w._mix()
		check(float(w._scores[-1]) > 0.5, "rodada %d resolvida (%.2f)" % [rnd + 1, float(w._scores[-1])])
		w._pause_t = 0.01
		await dev.wait(0.2)
	await dev.wait(0.3)
	check(w.phase == "result", "laboratório: resultado")
	await dev.shot(OUT + "v37_of_lab_fim.png")
	HUD.close_window()
	check(GameState.profession_xp("lab") > 0, "experiência de alquimista")


# ------------------------------------------------------------------ costura
func _sew() -> void:
	HUD.open_window("mg_costura")
	await dev.wait(0.5)
	var w = HUD.window
	w._begin()
	await dev.wait(1.5)
	await dev.shot(OUT + "v37_of_costura_mostra.png")
	for rnd in 3:
		w._t = 0.0
		await dev.wait(0.2)
		check(w._phase == "build", "cliente %d: montar no manequim" % (rnd + 1))
		w._have = w._want.duplicate()
		w._refresh_mannequin()
		if rnd == 0:
			await dev.wait(1.0)
			await dev.shot(OUT + "v37_of_costura_manequim.png")
		w._start_sew()
		while w._phase == "sew":
			for i in w._marks.size():
				if w._hits[i] < 0.0 and absf(w._needle - float(w._marks[i])) < 0.012:
					w._stitch()
			await get_tree().process_frame
		check(float(w._scores[-1]) > 0.8, "cliente %d satisfeito (%.2f)" % [rnd + 1, float(w._scores[-1])])
		await dev.wait(2.9)
	await dev.wait(0.5)
	check(w.phase == "result", "costura: resultado")
	await dev.shot(OUT + "v37_of_costura_fim.png")
	HUD.close_window()
