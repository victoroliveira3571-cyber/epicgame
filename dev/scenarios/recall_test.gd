extends Node

## v2.2: recall ativo no fim do foco (não fecha sem o mínimo de caracteres, fica salvo no histórico)
## e caixa de preocupações dentro do foco. Prints em _shots/.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

var ok := true


func check(cond: bool, what: String) -> void:
	print("[recall] ", "ok    " if cond else "FALHOU ", what)
	ok = ok and cond


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	var before := GameState.pomo_log.size()
	HUD.pomodoro_start(25, 5)
	HUD.open_window("pomodoro")
	await dev.wait(0.6)
	HUD.window._toggle_worry(true)
	await dev.wait(0.3)
	HUD.window._worry_edit.text = "preciso responder o e-mail da secretaria"
	await dev.shot(OUT + "r_worry.png")
	var w_before := (GameState.story.get("worries", []) as Array).size()
	HUD.window._save_worry()
	check((GameState.story.get("worries", []) as Array).size() == w_before + 1, "preocupação guardada sem sair do foco")
	check(HUD.pomo_state == "focus", "foco continua rodando")
	HUD.pomo_left = 1.0
	await dev.wait(2.5)
	check(HUD.window_id == "recall", "recall abre no fim do foco (janela: %s)" % HUD.window_id)
	await dev.shot(OUT + "r_recall_vazio.png")
	HUD.close_window()
	HUD.open_window("inventario")
	check(HUD.window_id == "recall", "não dá para fechar nem trocar de janela")
	var w: Node = HUD.window
	w._edit.text = "curto demais"
	w._update()
	check(w._done.disabled, "botão travado abaixo do mínimo")
	w._submit()
	check(HUD.window_id == "recall", "submit curto é ignorado")
	w._edit.text = "x".repeat(Data.RECALL_MIN_CHARS)
	w._update()
	check(not w._done.disabled, "botão libera no mínimo (%d)" % Data.RECALL_MIN_CHARS)
	await dev.shot(OUT + "r_recall_ok.png")
	w._submit()
	await dev.wait(0.3)
	check(HUD.window_id == "", "recall fecha depois de escrito")
	check(GameState.pomo_log.size() == before + 1 and String(GameState.pomo_log[-1].get("r", "")).length() >= Data.RECALL_MIN_CHARS, "texto salvo no histórico")
	check(HUD.recall_pending().is_empty(), "pendência limpa")
	print("[recall] ", "TUDO OK" if ok else "COM FALHAS")
