extends Node

## v2.2 lote 4: cela no Pomodoro, arena sem arquibancada, magia inicial, nome x visual na rua, Rei LPC.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var ok := true


func check(c: bool, what: String) -> void:
	print("[v22b] ", "ok    " if c else "FALHOU ", what)
	ok = ok and c


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.level = 1
	GameState.choose_class("cavaleiro")
	check(GameState.slot_skill("skill2") != "", "classe nasce com a magia R (%s)" % GameState.slot_skill("skill2"))
	# gente de rua: nome bate com o visual
	var errs := 0
	for sheet in ["Villager", "Villager2", "Villager3", "Woman", "OldMan", "Villager5"]:
		var n := NPC.create(self, sheet, Vector2(10, 10), "static")
		var idx := Street.persona_index(Street.key_of(n), Street.is_female(n), Street.is_child(n))
		if (idx % 2 == 1) != Street.is_female(n):
			errs += 1
		print("[v22b] ", sheet, " fem=", Street.is_female(n), " -> ", Street.PERSONAS[idx][0])
		n.queue_free()
	check(errs == 0, "persona com o gênero do visual")
	# cela
	Law.data()["jail_left"] = 30
	Law.data()["jail_total"] = 30
	Game.go_to_jail(30, "assault")
	await dev.wait(3.0)
	for i in 30:
		if not HUD.is_dialogue_open():
			break
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await dev.wait(0.12)
	HUD.open_pomodoro_at("cela")
	HUD.pomodoro_start(25, 5)
	await dev.wait(1.5)
	await dev.shot(OUT + "v22b_cela_pomodoro.png")
	HUD.pomodoro_cancel()
	HUD.close_window()
	Law.data()["jail_left"] = 0
	# arena
	Arena.data()["prestige"] = 400
	Game.enter_interior("arena")
	await dev.wait(2.5)
	for i in 40:
		if not HUD.is_dialogue_open():
			break
		var ev2 := InputEventKey.new()
		ev2.keycode = KEY_E
		ev2.pressed = true
		Input.parse_input_event(ev2)
		await dev.wait(0.12)
	var pl := get_tree().get_first_node_in_group("player") as Player
	pl.camera.zoom = Vector2(1.6, 1.6)
	pl.global_position = Vector2(240, 160)
	pl.camera.reset_smoothing()
	await dev.wait(0.8)
	await dev.shot(OUT + "v22b_arena.png")
	# Rei Demônio no palco
	var st := Stage.new()
	HUD.root.add_child(st)
	st.open_stage("throne")
	await dev.wait(0.8)
	st.focus("rei", Looks.speaker_visual("rei"))
	await dev.wait(1.4)
	await dev.shot(OUT + "v22b_rei.png")
	st.queue_free()
	print("[v22b] ", "TUDO OK" if ok else "COM FALHAS")
