extends Node

## Abre andares da masmorra, tira prints e testa pontos básicos (spawn, escadas, A*).
const OUT := "/private/tmp/claude-501/-Users-victor-Desktop-EPICGAME/fb73ee53-e2fb-41d8-854a-a4ec864f0bcc/scratchpad/"

func run(dev: Node) -> void:
	GameState.debug_reset()
	GameState.choose_class("cavaleiro")
	GameState.level = 8
	GameState.mark_dirty()
	for fl in [1, 6, 5]:
		Game.run = {}
		Game.current_floor = fl
		get_tree().change_scene_to_file(Game.DUNGEON_SCENE)
		await dev.wait(1.5)
		var d := get_tree().get_first_node_in_group("dungeon")
		var enemies := get_tree().get_nodes_in_group("enemy").size()
		print("[dungeon] andar %d: %dx%d, inimigos=%d, boss=%s" % [fl, d.w, d.h, enemies, str(d.boss != null)])
		if d.stairs_down != null:
			var pth: PackedVector2Array = d.path_to(d.player.global_position, d.stairs_down.global_position)
			print("[dungeon] caminho ate escada: %d pontos" % pth.size())
		await dev.shot(OUT + "dungeon_%d_start.png" % fl)
		var sd = d.stairs_down
		if sd != null:
			d.player.global_position = sd.global_position + Vector2(-20, 0)
			d.player.camera.reset_smoothing()
			await dev.wait(0.8)
			await dev.shot(OUT + "dungeon_%d_stairs.png" % fl)
