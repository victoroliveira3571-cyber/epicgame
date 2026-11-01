extends Node

## v3.1: joga o laboratório v2 por script.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
var fails := 0


func check(c: bool, what: String) -> void:
	print("[lab] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	HUD.open_window("mg_lab")
	await dev.wait(0.3)
	var w: MiniGameWindow = HUD.window
	w._begin()
	await dev.wait(0.3)
	for r in 5:
		check(w._round == r, "poção %d" % (r + 1))
		# resolve por força bruta: acha uma combinação de até 4 frascos que bate o alvo
		var sol := _solve(w)
		check(not sol.is_empty(), "existe solução")
		for i in sol:
			w._on_click("h%d" % i)
		if r == 0:
			await dev.shot(OUT + "v31_lab2.png")
		if r == 3:
			await dev.shot(OUT + "v31_lab2_oculto.png")
		w._on_click("brew")
		await dev.wait(0.1)
		w._pause_t = 0.05
		await dev.wait(0.3)
	check(w.phase == "result", "terminou")
	check(w._total >= 4.99, "todas perfeitas (%.2f)" % w._total)
	print("[lab] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)


func _solve(w: Node) -> Array:
	var n: int = w.ROUNDS[w._round]
	var tgt: Array = w._target
	var h: Array = w.HERBS
	var stack: Array = [[]]
	while not stack.is_empty():
		var cur: Array = stack.pop_back()
		var s := [0, 0, 0]
		for i in cur:
			for a in 3:
				s[a] += int(h[i]["fx"][a])
		if cur.size() == n and s == tgt:
			return cur
		if cur.size() < n:
			for i in h.size():
				var nxt := cur.duplicate()
				nxt.append(i)
				stack.append(nxt)
	return []
