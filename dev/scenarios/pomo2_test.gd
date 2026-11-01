extends Node

## Pomodoro novo: janela (configuração, foco, painel Sons), troca livro/caneca, finalizar antes
## da hora (conta o tempo), playlist/ambiente, Guarda-roupa e Créditos. Prints em _shots/.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")

var ok := true


func check(cond: bool, what: String) -> void:
	print("[pomo2] ", "ok    " if cond else "FALHOU ", what)
	ok = ok and cond


func run(dev: Node) -> void:
	var scenes: PackedStringArray = ["estudo", "cafeteria", "natureza", "livraria"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenes="):
			scenes = arg.substr(9).split(",")
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	GameState.pomo_cfg["scene"] = "cafeteria"
	HUD.open_window("pomodoro")
	await dev.wait(0.6)
	await dev.shot(OUT + "p2_settings.png")
	# foco
	HUD.pomodoro_start(25, 5)
	await dev.wait(0.5)
	await dev.wait(2.0)
	check(Audio.pomo_genre_playing() == "" and not Audio._active_music.playing, "Pomodoro sem música (v2.4)")
	check(Audio._amb_players.is_empty(), "Pomodoro sem ambiente (v2.4)")
	for sid in scenes:
		GameState.pomo_cfg["scene"] = sid
		Audio.pomo_update()
		HUD.close_window()
		HUD.open_window("pomodoro")
		await dev.wait(1.2)
		await dev.shot(OUT + "p2_%s.png" % sid)
		var sc: StudyScene = HUD.window._scene
		# meio da troca: livro indo para a mesa, depois a mão buscando a caneca
		for k in [0.5, 1.15, 1.9]:
			sc.held = "book"
			sc._start("swap")
			sc.anim_t = k
			sc.state = "paused"
			await dev.wait(0.15)
			await dev.shot(OUT + "p2_%s_swap_%d.png" % [sid, int(k * 100)])
		sc.held = "mug"
		sc._start("sip")
		sc.anim_t = 0.75
		await dev.wait(0.15)
		await dev.shot(OUT + "p2_%s_sip.png" % sid)
		sc.state = "focus"
		sc.reset_hold()
	# finalizar antes da hora: 7 min e 5 s estudados contam 7 min
	var credits0 := GameState.study_credits
	var logs0 := GameState.pomo_log.size()
	HUD.pomo_left = HUD.pomo_total - (7 * 60 + 5)
	check(HUD.pomo_studied_minutes() == 7, "minutos estudados = 7")
	HUD.pomodoro_finish()
	check(HUD.pomo_state == "break", "depois de finalizar começa a pausa")
	check(GameState.study_credits - credits0 == 7, "créditos +7")
	check(GameState.pomo_log.size() == logs0 + 1 and int(GameState.pomo_log[-1]["m"]) == 7 and GameState.pomo_log[-1].has("e"), "histórico com 7 min (finalizado antes)")
	HUD.pomodoro_finish()
	check(HUD.pomo_state == "idle", "finalizar na pausa encerra a pausa")
	await dev.wait(0.2)
	check(HUD.window_id == "recall", "fim do foco abre o recall obrigatório")
	HUD.recall_submit("x".repeat(Data.RECALL_MIN_CHARS))
	await dev.wait(1.8)
	check(Audio.pomo_genre_playing() == "" and Audio._amb_players.is_empty(), "sem foco: playlist e ambiente param")
	# menos de 1 minuto não conta
	HUD.pomodoro_start(25, 5)
	HUD.pomo_left = HUD.pomo_total - 30
	HUD.pomodoro_finish()
	check(HUD.pomo_state == "idle" and GameState.pomo_log.size() == logs0 + 1, "menos de 1 min não registra")
	# guarda-roupa e créditos
	GameState.study_credits = 400
	HUD.close_window()
	HUD.open_window("guarda_roupa")
	await dev.wait(0.5)
	await dev.shot(OUT + "p2_wardrobe.png")
	var w = HUD.window
	w.cat_id = "chapeu"
	w.selected = Lpc.items_in("chapeu")[0]
	w.rebuild()
	await dev.wait(0.4)
	await dev.shot(OUT + "p2_wardrobe_chapeu.png")
	var hat: String = Lpc.items_in("chapeu")[0]
	var bought := GameState.buy_look(hat)
	GameState.toggle_look(hat)
	check(bought and GameState.look["equip"].get("cabeca", "") == hat, "comprar e vestir chapéu")
	GameState.save_now()
	GameState.look = {}
	GameState.load_game()
	check(Lpc.resolve(GameState.look)["equip"].get("cabeca", "") == hat, "visual volta ao carregar o save")
	w.cat_id = "camisa"
	w.selected = "camiseta"
	w.rebuild()
	await dev.wait(0.4)
	await dev.shot(OUT + "p2_wardrobe_cor.png")
	HUD.close_window()
	HUD.open_window("creditos")
	await dev.wait(0.4)
	await dev.shot(OUT + "p2_creditos.png")
	HUD.close_window()
	print("[pomo2] ", "TUDO OK" if ok else "HOUVE FALHAS")
