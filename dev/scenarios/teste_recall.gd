extends Node

## Diagnóstico do recall: mede XP, ouro, créditos, minutos de história e o relógio da pausa
## enquanto o jogador escreve o recall em tamanhos diferentes. Saída só no console.


func _snap() -> Dictionary:
	return {"xp": GameState.xp, "gold": GameState.gold, "credits": GameState.study_credits,
		"story_min": Story.focus_minutes(), "pomo_log": GameState.pomo_log.size(),
		"pomo_left": snappedf(HUD.pomo_left, 0.1), "state": HUD.pomo_state}


func _delta(a: Dictionary, b: Dictionary) -> Dictionary:
	var d := {}
	for k in a:
		if a[k] is float:
			d[k] = snappedf(float(b[k]) - float(a[k]), 0.1)
		elif a[k] is int:
			d[k] = int(b[k]) - int(a[k])
		else:
			d[k] = str(a[k]) + " -> " + str(b[k])
	return d


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	HUD.pomodoro_start(25, 5)
	HUD.pomo_left = HUD.pomo_total - 150.0
	var s0 := _snap()
	HUD.pomodoro_finish()
	await dev.wait(2.0)
	var s1 := _snap()
	print("[recall] FOCO FINALIZADO (2,5 min): ", _delta(s0, s1), " janela=", HUD.window_id)
	var w = HUD.window
	if w == null or HUD.window_id != "recall":
		print("[recall] janela de recall NÃO abriu")
		return
	var ed = w.get("_edit")
	var texts := [
		["0 letras", ""],
		["130 letras", "a".repeat(130)],
		["600 letras", "b".repeat(600)],
	]
	var prev := _snap()
	for t in texts:
		ed.text = t[1]
		ed.text_changed.emit()
		await dev.wait(1.0)
		var now := _snap()
		print("[recall] digitou ", t[0], ": ", _delta(prev, now))
		prev = now
	HUD.recall_submit(String(texts[2][1]))
	await dev.wait(1.0)
	var fin := _snap()
	print("[recall] ENVIOU recall: ", _delta(prev, fin), " janela=", HUD.window_id)
	print("[recall] pausa restante após o recall: ", snappedf(HUD.pomo_left, 0.1), " estado=", HUD.pomo_state)
