extends Node

## Mesas de estudo: biblioteca, casa e taverna abrem o Pomodoro com o cenário do lugar (fixo).
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	var ok := true
	GameState.debug_reset()
	GameState.choose_class("arqueiro")
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	for pair in [["biblioteca", "livraria"], ["casa", "casa"], ["restaurante", "taverna"]]:
		Game.enter_interior(pair[0])
		await dev.wait(1.6)
		await dev.shot(OUT + "place_%s.png" % pair[0])
		var spots := get_tree().get_nodes_in_group("interactable")
		var found: Node = null
		for s in get_tree().current_scene.find_children("*", "Interactable", true, false):
			if s.get("text") == "Estudar aqui (Pomodoro)":
				found = s
		ok = ok and found != null
		if found != null:
			found.interact(null)
			await dev.wait(0.6)
			ok = ok and HUD.window_id == "pomodoro" and str(GameState.pomo_cfg["scene"]) == pair[1] and HUD.pomo_place == pair[1]
			await dev.shot(OUT + "place_%s_pomo.png" % pair[0])
			HUD.pomodoro_start(25, 5)
			await dev.wait(1.2)
			await dev.shot(OUT + "place_%s_run.png" % pair[0])
			HUD.pomodoro_toggle()
			await dev.wait(0.2)
			ok = ok and Audio._active_music.stream_paused
			HUD.pomodoro_toggle()
			await dev.wait(0.2)
			ok = ok and not Audio._active_music.stream_paused
			HUD.pomodoro_cancel()
			HUD.close_window()
		print("[places] ", pair[0], " mesa=", found != null, " ok=", ok)
		Game.go_to_town("door:" + pair[0])
		await dev.wait(1.6)
	print("[places] ", "TUDO OK" if ok else "FALHOU")
