extends Node

## Janela do Pomodoro: configuração e as 4 cenas rodando. Uso: -- --class=mago --scenes=estudo,cafeteria
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

func run(dev: Node) -> void:
	var cls := "cavaleiro"
	var scenes: PackedStringArray = ["estudo", "cafeteria", "natureza", "livraria"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--class="):
			cls = arg.substr(8)
		if arg.begins_with("--scenes="):
			scenes = arg.substr(9).split(",")
	GameState.debug_reset()
	GameState.choose_class(cls)
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	GameState.pomo_cfg["scene"] = scenes[0]
	HUD.open_window("pomodoro")
	await dev.wait(0.8)
	await dev.shot(OUT + "pomo_settings.png")
	HUD.pomodoro_start(25, 5)
	for sid in scenes:
		GameState.pomo_cfg["scene"] = sid
		HUD.close_window()
		HUD.open_window("pomodoro")
		await dev.wait(2.2)
		await dev.shot(OUT + "pomo_%s_%s.png" % [cls, sid])
	HUD.pomodoro_cancel()
	await dev.wait(0.3)
