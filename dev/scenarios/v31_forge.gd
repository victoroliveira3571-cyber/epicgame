extends Node

## v3.1: joga a forja v2 por script e tira prints de cada etapa.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var fails := 0


func check(c: bool, what: String) -> void:
	print("[forja] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	HUD.open_window("mg_forja")
	await dev.wait(0.3)
	var w: MiniGameWindow = HUD.window
	w._begin()
	await dev.wait(0.5)
	# etapa 1: mantém o calor na faixa
	var t := 0.0
	while w._stage_id == "heat" and t < 12.0:
		w._pumping = true
		w._heat = 0.7
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > 3.0 and t < 3.1:
			await dev.shot(OUT + "v31_forja_calor.png")
	check(w._s1 > 0.8, "calor bem controlado rende nota alta (%.2f)" % w._s1)
	await dev.wait(0.9)
	check(w._stage_id == "hammer", "foi para a etapa do martelo")
	for i in 8:
		w._cursor = w._zone_c
		w._swing_t = 0.0
		if i == 3:
			await dev.shot(OUT + "v31_forja_martelo.png")
		w._hit_hammer()
		await dev.wait(0.05)
	check(w._s2 > 0.9, "martelo perfeito (%.2f)" % w._s2)
	await dev.wait(1.0)
	check(w._stage_id == "quench", "foi para o resfriamento")
	w._cursor = w._zone_c
	await dev.shot(OUT + "v31_forja_banho.png")
	w._hit_quench()
	await dev.wait(1.5)
	check(w.phase == "result", "terminou com resultado")
	print("[forja] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
