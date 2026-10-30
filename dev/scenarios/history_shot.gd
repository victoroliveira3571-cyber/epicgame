extends Node

## Cria um histórico de exemplo e fotografa a janela nas 4 abas.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

func run(dev: Node) -> void:
	GameState.debug_reset()
	GameState.choose_class("arqueiro")
	var now := int(Time.get_unix_time_from_system())
	var r := RandomNumberGenerator.new()
	r.seed = 7
	for i in 420:
		var day_off := r.randi_range(0, 420)
		if r.randf() < 0.25:
			continue
		var u := now - day_off * 86400
		GameState.pomo_log.append({"d": Time.get_date_string_from_unix_time(u), "t": u, "m": [15, 25, 25, 45][r.randi() % 4], "s": "cafeteria"})
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	for tab in 4:
		HUD.open_window("historico")
		await dev.wait(0.3)
		HUD.window.tab = tab
		HUD.window.rebuild()
		await dev.wait(0.4)
		await dev.shot(OUT + "hist_%d.png" % tab)
		HUD.close_window()
	# o save do dia fica gravado e recarrega com o histórico
	GameState.save_now()
	var n := GameState.pomo_log.size()
	GameState.pomo_log.clear()
	GameState.load_game()
	print("[hist] registros salvos=", n, " recarregados=", GameState.pomo_log.size())
