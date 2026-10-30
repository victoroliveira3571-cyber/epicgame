extends Node

## Confere as faixas .mp3 novas e o relógio do Pomodoro (via estado real do HUD).
func run(dev: Node) -> void:
	for n in ["town", "town_night", "title"]:
		Audio._current_music = ""
		Audio.play_music(n)
		await dev.wait(0.3)
		print("[audio] ", n, " tocando=", Audio._active_music.playing, " faixa=", Audio._active_music.stream.resource_path.get_file())
	HUD.pomodoro_toggle()
	await dev.wait(0.4)
	print("[audio] foco ativo -> relogio=", Audio._clock.playing)
	HUD.pomodoro_toggle()
	await dev.wait(0.3)
	print("[audio] pausado -> relogio=", Audio._clock.playing)
	HUD.pomodoro_toggle()
	await dev.wait(0.3)
	HUD.pomodoro_cancel()
	await dev.wait(0.3)
	print("[audio] cancelado -> relogio=", Audio._clock.playing)
