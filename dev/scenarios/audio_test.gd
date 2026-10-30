extends Node

## Confere que cada som novo (.mp3) carrega, não faz loop (efeitos) e toca.
func run(dev: Node) -> void:
	var sfx := ["talk", "ui_click", "ui_open", "ui_move", "swing_combo", "coin_big", "growl", "cough", "star", "magic_select", "rune_break", "shrine_ring", "sleep"]
	var jingles := ["defeat", "victory_flute", "boss_intro", "pomo_done", "pomo_start"]
	var bad := 0
	for n in sfx:
		var s: AudioStream = Audio._load_stream(Audio._find(Audio.SFX_DIR, n))
		var ok: bool = s != null and not (s as AudioStreamMP3).loop
		print("[audio] sfx ", n, " ", "ok %.1fs" % s.get_length() if ok else "PROBLEMA")
		bad += 0 if ok else 1
	for n in jingles:
		var s2: AudioStream = Audio._load_stream(Audio._find(Audio.JINGLE_DIR, n))
		var ok2: bool = s2 != null and not (s2 as AudioStreamMP3).loop
		print("[audio] jingle ", n, " ", "ok %.1fs" % s2.get_length() if ok2 else "PROBLEMA")
		bad += 0 if ok2 else 1
	Audio.sfx("coin_big")
	Audio.jingle("pomo_start")
	Audio.set_ambience("ambience_nature")
	await dev.wait(0.4)
	print("[audio] ambiente tocando=", Audio._ambience.playing, " loop=", (Audio._ambience.stream as AudioStreamMP3).loop)
	Audio.set_ambience("")
	await dev.wait(0.1)
	print("[audio] ambiente parado=", not Audio._ambience.playing, " problemas=", bad)
