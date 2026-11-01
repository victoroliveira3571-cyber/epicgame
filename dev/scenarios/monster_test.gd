extends Node

## v3.4: monstros e chefes novos (Dungeon Tileset II): monta todos, confere animações e tira um print da fila.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0


func check(c: bool, what: String) -> void:
	if not c:
		print("[monstros] FALHA ", what)
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	var town := get_tree().current_scene
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	var world: Node = town.world
	var ids: Array = []
	for id in Data.MONSTERS:
		if Data.MONSTERS[id].get("kind", "") == "dt2":
			ids.append(id)
	check(ids.size() >= 18, "monstros novos cadastrados (%d)" % ids.size())
	var i := 0
	var enemies: Array = []
	for id in ids:
		var e := Enemy.spawn(world, id, pl.global_position + Vector2(-150 + (i % 10) * 34, -60 + (i / 10) * 40), 12, false)
		enemies.append(e)
		i += 1
	await dev.wait(0.6)
	for e in enemies:
		var sf: SpriteFrames = (e as Enemy).sprite.sprite_frames
		check(sf.has_animation("walk_down") and sf.get_frame_count("walk_down") >= 2, "%s tem animação" % e.def_id)
		check(sf.has_animation("walk_left") and sf.get_frame_count("walk_left") >= 2, "%s tem animação para a esquerda" % e.def_id)
		check((e as Enemy).max_hp > 10.0, "%s tem vida" % e.def_id)
	await dev.shot(OUT + "monstros_novos.png")
	for e in enemies:
		(e as Node).queue_free()
	var bi := 0
	var bosses: Array = []
	for bid in ["ogro_ancestral", "zumbi_colossal", "demonio_abissal", "orc_senhor"]:
		var b := Boss.spawn_boss(world, bid, pl.global_position + Vector2(-150 + bi * 100, -40), 15)
		bosses.append(b)
		bi += 1
	await dev.wait(0.6)
	for b in bosses:
		var sf: SpriteFrames = (b as Boss).sprite.sprite_frames
		check(sf.get_frame_count("idle") >= 2 and sf.get_frame_count("walk") >= 2, "%s tem animações" % b.boss_id)
		check(b.max_hp > 1000.0, "%s tem vida" % b.boss_id)
	await dev.shot(OUT + "chefes_novos.png")
	var seen := {}
	for f in range(5, 60, 5):
		seen[Data.boss_for_floor(f)] = true
	check(seen.size() >= 10, "10 chefes diferentes até o andar 50 (%d)" % seen.size())
	for f in range(1, 36):
		var biome := Data.biome_for_floor(f)
		for id in biome["enemies"]:
			check(Data.MONSTERS.has(id), "monstro %s existe" % id)
	print("[monstros] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
