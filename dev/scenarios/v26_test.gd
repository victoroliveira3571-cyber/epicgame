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
	# v2.8: 8 tiers
	check(Data.TIER_NAMES.size() == 8 and Data.TIER_UNLOCK_LEVEL.size() == 8, "8 tiers de material")
	check(Data.TIER_UNLOCK_LEVEL[7] == 100, "Supremo no nível 100")
	check(Data.RARITY_NAMES.size() >= 8 and Data.RARITY_COLORS.size() >= 8, "raridades para 8 tiers")
	var all_ok := true
	for slot in Data.EQUIP_SLOTS:
		var per := 0
		for it in Data.ITEMS.values():
			if it["kind"] == "equip" and it["slot"] == slot and int(it["tier"]) == 7:
				per += 1
				all_ok = all_ok and float(it.get("atk", 0)) + float(it.get("def", 0)) + float(it.get("crit", 0)) > 0.0
		all_ok = all_ok and per >= 1
	check(all_ok, "todo espaço tem item Supremo com atributos")
	check(Data.max_tier_for_level(99) == 6 and Data.max_tier_for_level(100) == 7, "Supremo libera no nível 100")
	check(Data.ITEMS["armadura_suprema"]["def"] > Data.ITEMS["couraca_draconica"]["def"], "Supremo supera Obsidiana")
	check(Loot._roll_tier(30) <= 7, "drop sorteia até o tier 7")
	# v2.8: personas únicas e persistentes
	var seen := {}
	var dup := false
	for k in 10:
		var idx := Street.persona_index("teste_m_%d" % k, false)
		dup = dup or seen.has(idx)
		seen[idx] = true
	check(not dup, "10 moradores sem persona repetida")
	check(Street.persona_index("teste_m_3", false) == Street.persona_index("teste_m_3", false), "persona estável por morador")
	check(str(Street.PERSONAS[12][0]) == "Kilian" and str(Street.PERSONAS[13][0]) == "Dame Cora", "nomes anglo-medievais")
	# v2.8: minério na floresta
	Game.go_to_forest("town")
	await dev.wait(2.0)
	var veins := 0
	for n in get_tree().get_nodes_in_group("player")[0].get_parent().get_children():
		if n is StoryProp and str((n as StoryProp).text).begins_with("Minerar"):
			veins += 1
			if veins == 1:
				var b0 := GameState.count_item("barra_cobre") + GameState.count_item("barra_ferro") + GameState.count_item("barra_prata") + GameState.count_item("barra_ouro") + GameState.count_item("barra_mithril")
				(n as StoryProp).interact(null)
				var b1 := GameState.count_item("barra_cobre") + GameState.count_item("barra_ferro") + GameState.count_item("barra_prata") + GameState.count_item("barra_ouro") + GameState.count_item("barra_mithril")
				check(b1 > b0 and not (n as StoryProp).enabled, "minerar dá barra e esgota o veio")
	check(veins >= 8, "veios de minério na floresta (%d)" % veins)
	print("[v26] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
