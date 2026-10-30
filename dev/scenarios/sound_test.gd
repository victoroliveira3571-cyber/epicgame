extends Node

## Liga/desliga da música e do relógio (janela do Pomodoro) e se o save guarda as escolhas.

func run(dev: Node) -> void:
	var ok := true
	GameState.set_music_on(false)
	ok = ok and Audio._music_db() <= -80.0
	GameState.set_music_on(true)
	ok = ok and Audio._music_db() > -80.0
	GameState.set_clock_on(false)
	Audio.set_clock(true)
	ok = ok and (Audio._clock == null or not Audio._clock.playing)
	GameState.set_clock_on(true)
	Audio.set_clock(true)
	ok = ok and Audio._clock != null and Audio._clock.playing
	Audio.set_clock(false)
	GameState.set_music_on(false)
	GameState.set_clock_on(false)
	GameState.save_now()
	GameState.music_on = true
	GameState.clock_on = true
	GameState.load_game()
	ok = ok and not GameState.music_on and not GameState.clock_on
	GameState.set_music_on(true)
	GameState.set_clock_on(true)
	GameState.save_now()
	print("[sound] ", "OK" if ok else "FALHOU")
	await dev.wait(0.1)
