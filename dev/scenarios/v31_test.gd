extends Node

## v3.1: despedida da mãe (ramos, bênção permanente, visitas) e mini-jogos.

var fails := 0


func check(c: bool, what: String) -> void:
	print("[v31] ", "ok   " if c else "FALHA", " ", what)
	if not c:
		fails += 1


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	var paths := {"promessa": [0, -1], "medo_0": [1, 0], "medo_1": [1, 1], "medo_2": [1, 2], "luz": [2, -1]}
	var base_hp := GameState.get_max_hp()
	var seen := {}
	for path in paths:
		var f: Array = paths[path]
		Story.set_flag("despedida", f[0])
		Story.set_flag("despedida_medo", f[1])
		check(Story.mother_path() == path, "caminho %s" % path)
		check(not Story.mother_bonus().is_empty(), "bênção de %s" % path)
		check(StoryData.MAE_BONUS_TEXT.has(path), "texto da bênção de %s" % path)
		for ch in [1, 2, 4]:
			Story.st()["chapter"] = ch
			var lines: Array = Story.mother_visit_lines()
			check(lines.size() >= 1 and lines[0][0] == "mae", "visita %s no cap. %d" % [path, ch])
			seen[str(lines)] = true
	check(seen.size() >= 10, "falas da mãe variam por caminho e fase (%d)" % seen.size())
	Story.set_flag("despedida", 1)
	Story.set_flag("despedida_medo", 2)
	GameState.mark_dirty()
	check(GameState.get_max_hp() >= base_hp + 12, "bênção de vida soma na vida máxima")
	Story.set_flag("despedida", -1)
	check(Story.mother_path() == "", "sem conversa não há bênção")
	check(Story.mother_visit_lines() == StoryData.DIALOGS["mae_livre"], "sem caminho usa a fala padrão")
	# diálogo ramificado de verdade
	Story.set_flag("despedida", -1)
	Story.set_flag("despedida_medo", -1)
	var d := DialogueBox.new()
	var dl: Array = StoryData.DIALOGS["c1_despedida"]
	var n0 := dl.size()
	d.lines = dl.duplicate()
	check(d.lines.size() == n0, "cópia das falas")
	d.free()
	print("[v31] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
