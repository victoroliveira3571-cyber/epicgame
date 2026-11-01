extends Node

## v2.2: ringue cercado, torcida por prestígio e quadro de resultado. Prints em _shots/arena_*.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func _skip() -> void:
	for i in 60:
		if not HUD.is_dialogue_open():
			return
		var ev := InputEventKey.new()
		ev.keycode = KEY_E
		ev.pressed = true
		Input.parse_input_event(ev)
		await get_tree().create_timer(0.1).timeout


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	for pr in [0, 300, 900]:
		Arena.data()["prestige"] = pr
		Game.enter_interior("arena")
		await dev.wait(2.0)
		await _skip()
		var n := get_tree().get_nodes_in_group("arena_crowd").size()
		print("[arena] prestígio %d: torcida %d" % [pr, n])
		await dev.shot(OUT + "arena_prest_%d.png" % pr)
		if pr == 300:
			var room := get_tree().get_first_node_in_group("interior")
			room.start_duel(Arena.opponents()[0])
			await dev.wait(3.4)
			await dev.shot(OUT + "arena_luta.png")
			room._duel.take_hit(99999.0, Vector2.ZERO, false)
			await dev.wait(5.0)
			await dev.shot(OUT + "arena_resultado.png")
			print("[arena] janela: ", HUD.window_id)
			HUD.close_window()
