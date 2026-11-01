extends Node

## v2.6: zona segura (golpes ignoram moradores na cidade) e mira automática corpo a corpo.

var fails := 0


func check(c: bool, what: String) -> void:
	print("[v26] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	var pl := get_tree().get_first_node_in_group("player") as Player
	var folk: NPC = null
	for t in 6:
		for n in get_tree().get_nodes_in_group("npc_hit"):
			if n is NPC and (n as NPC).mode == "wander" and not (n as NPC).has_meta("has_talker"):
				folk = n
				break
		if folk != null:
			break
		await dev.wait(1.0)
	check(folk != null, "há morador na rua")
	if folk == null:
		print("[v26] npc_hit: ", get_tree().get_nodes_in_group("npc_hit").size())
		return
	folk.set_physics_process(false)
	folk.set_process(false)
	pl.global_position = folk.global_position + Vector2(-14, 0)
	pl.facing = Vector2.RIGHT
	GameState.safe_zone = true
	var hp0 := folk.hp
	pl._melee("sword", false)
	await dev.wait(0.4)
	check(folk.hp == hp0, "zona segura ligada: morador não é ferido")
	GameState.set_safe_zone(false)
	pl._melee("sword", false)
	await dev.wait(0.4)
	check(folk.hp < hp0, "zona segura desligada: morador é ferido")
	GameState.set_safe_zone(true)
	# v2.7: baú
	GameState.add_item("pocao_vida", 5, true)
	var q0 := GameState.count_item("pocao_vida")
	check(GameState.stash_put("pocao_vida", 3) and GameState.count_item("pocao_vida") == q0 - 3, "baú guarda 3")
	check(int(GameState.stash.get("pocao_vida", 0)) == 3, "baú tem 3")
	check(GameState.stash_take("pocao_vida", 2) and GameState.count_item("pocao_vida") == q0 - 1, "baú devolve 2")
	check(not GameState.stash_take("item_inexistente", 1), "não tira o que não há")
	HUD.open_window("bau")
	await dev.wait(0.4)
	check(HUD.window_id == "bau", "janela do baú abre")
	HUD.close_window()
	print("[v26] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
