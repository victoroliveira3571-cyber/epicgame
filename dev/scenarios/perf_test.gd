extends Node

## Carga: põe N inimigos perto do jogador num andar e mede FPS e tempo de processamento.
## Uso: --scenario=perf_test -- --n=80 --floor=12

func run(dev: Node) -> void:
	var n := 80
	var fl := 12
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--n="):
			n = int(arg.substr(4))
		if arg.begins_with("--floor="):
			fl = int(arg.substr(8))
	GameState.debug_reset()
	GameState.choose_class("mago")
	GameState.level = 60
	GameState.talents["vigor"] = 40
	GameState.energy = 5
	GameState.mark_dirty()
	GameState.full_heal()
	Game.enter_dungeon(fl)
	await dev.wait(2.0)
	var d := get_tree().get_first_node_in_group("dungeon")
	await _measure(dev, "andar normal (%d inimigos)" % get_tree().get_nodes_in_group("enemy").size())
	# junta todos os inimigos perto do jogador e completa até N
	var enemies := get_tree().get_nodes_in_group("enemy")
	var i := 0
	for e in enemies:
		e.global_position = d.player.global_position + Vector2(cos(i * 0.7), sin(i * 0.7)) * (40.0 + float(i % 5) * 14.0)
		i += 1
	var extra := n - enemies.size()
	var pc: Vector2i = Vector2i((d.player.global_position / 16.0).floor())
	for k in maxi(extra, 0):
		var off := Vector2i(int(cos(k * 1.3) * 3.0), int(sin(k * 1.3) * 3.0))
		d._spawn_enemy(pc + off)
	await dev.wait(0.5)
	await _measure(dev, "%d inimigos em volta" % get_tree().get_nodes_in_group("enemy").size())
	await dev.shot("/Users/victor/Desktop/EPICGAME/game/_shots/perf.png")


func _measure(dev: Node, label: String) -> void:
	var frames := 0
	var worst := 0.0
	var sum_proc := 0.0
	var sum_phys := 0.0
	var t0 := Time.get_ticks_msec()
	var last := t0
	while Time.get_ticks_msec() - t0 < 4000:
		await get_tree().process_frame
		var now := Time.get_ticks_msec()
		worst = maxf(worst, float(now - last))
		last = now
		frames += 1
		sum_proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		sum_phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	print("[perf] %s: %.1f fps, pior quadro %.0f ms, process %.2f ms, physics %.2f ms, nós %d" % [
		label, frames / 4.0, worst, sum_proc / frames, sum_phys / frames, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
