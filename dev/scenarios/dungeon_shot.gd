extends Node

## Abre andares da masmorra com o HUD ligado, tira prints e testa pontos básicos.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")

func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	GameState.level = 8
	GameState.best_floor = 40          # libera as Profundezas para os prints
	for cid in CityData.ORDER:
		Story.set_flag("frag_" + cid)
	GameState.energy = 5
	GameState.add_item("pocao_vida", 3, true)
	GameState.add_item("pao", 2, true)
	GameState.mark_dirty()
	GameState.full_heal()
	var fl := 5
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--floor="):
			fl = int(arg.substr(8))
	Game.enter_dungeon(fl)
	await dev.wait(2.5)
	var d := get_tree().get_first_node_in_group("dungeon")
	print("[dungeon] andar %d: inimigos=%d boss=%s energia=%d" % [fl, get_tree().get_nodes_in_group("enemy").size(), str(d.boss != null), GameState.energy])
	await dev.shot(OUT + "dd_1_start.png")
	# anda até uma sala com monstros: teleporta perto do primeiro inimigo (ou do chefe)
	var target: Node2D = d.boss if d.boss != null else get_tree().get_first_node_in_group("enemy")
	d.player.global_position = target.global_position + Vector2(-70, 0)
	d.player.camera.reset_smoothing()
	await dev.wait(1.5)
	await dev.shot(OUT + "dd_2_enemy.png")
	d.player.global_position = target.global_position + Vector2(-30, 0)
	await dev.wait(1.0)
	await dev.shot(OUT + "dd_3_close.png")
