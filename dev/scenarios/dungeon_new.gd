extends Node

## v3.4: entra em andares com os biomas novos, lista os monstros e tira um print perto de um inimigo.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	GameState.level = 40
	GameState.energy = 9
	Story.st()["credits"] = 99
	for id in CityData.ORDER:
		Story.set_flag("frag_" + id, true)
	GameState.best_floor = 60
	GameState.mark_dirty()
	GameState.full_heal()
	var fl := 22
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--floor="):
			fl = int(arg.substr(8))
	Game.enter_dungeon(fl)
	await dev.wait(3.0)
	var d := get_tree().get_first_node_in_group("dungeon")
	if d == null:
		print("[dungeon] não abriu o andar ", fl)
		return
	var names := {}
	for e in get_tree().get_nodes_in_group("enemy"):
		names[(e as Enemy).display_name] = int(names.get((e as Enemy).display_name, 0)) + 1
	print("[dungeon] andar ", fl, " bioma ", Data.biome_for_floor(fl)["name"], " chefe=", d.boss != null, " monstros: ", names)
	var target: Node2D = d.boss if d.boss != null else get_tree().get_first_node_in_group("enemy")
	d.player.global_position = target.global_position + Vector2(-60, 0)
	d.player.camera.reset_smoothing()
	await dev.wait(1.5)
	await dev.shot(OUT + "dd_novo_%d.png" % fl)
