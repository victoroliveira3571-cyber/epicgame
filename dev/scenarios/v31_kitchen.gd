extends Node

## v3.1: joga a cozinha v2 por script.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
var fails := 0


func check(c: bool, what: String) -> void:
	print("[cozinha] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	HUD.open_window("mg_cozinha")
	await dev.wait(0.3)
	var w: MiniGameWindow = HUD.window
	w._begin()
	await dev.wait(0.3)
	# três clientes
	for k in 3:
		w._spawn_in = 0.0
		await dev.wait(0.15)
	var wanted := ""
	for c in w._cust:
		if c != null:
			wanted = str(c["dish"])
	check(wanted != "", "há pedidos")
	# cozinha o último pedido: tábua -> panela -> balcão -> cliente
	w._order(wanted)
	while not w._board.is_empty() and int(w._board.get("left", 0)) > 0:
		w._chop()
	await dev.wait(0.2)
	check(w._board.is_empty(), "prato saiu da tábua")
	var pot_used := false
	for p in w._pots:
		if p != null:
			pot_used = true
			p["t"] = 100.0
	await dev.wait(0.3)
	check(pot_used or w._counter.has(wanted), "prato foi cozinhar ou já está no balcão")
	await dev.wait(0.5)
	check(w._counter.has(wanted), "prato chegou ao balcão")
	await dev.shot(OUT + "v31_cozinha2.png")
	w._sel = w._counter.find(wanted)
	for i in 4:
		if w._cust[i] != null and w._cust[i]["dish"] == wanted:
			w._serve(i)
			break
	check(w._served >= 1, "cliente servido")
	w._time_left = 0.05
	await dev.wait(0.4)
	check(w.phase == "result", "partida terminou")
	print("[cozinha] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
