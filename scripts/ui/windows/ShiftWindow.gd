class_name ShiftWindow
extends UIWindow

## v3.7: introdução e resultado dos ofícios (turnos de trabalho e mini-jogos de mesa).
## `data`: {mode: intro|result, title, skill, how_to, prof, score, reward, prof_gain, lines}. `choice` diz o que o
## jogador escolheu: start | again | exit.

static var data: Dictionary = {}
static var choice: String = ""


func _init() -> void:
	win_title = "Ofício"
	win_size = Vector2(500, 270)
	close_on_escape = false


func build() -> void:
	close_button.visible = false
	win_title = str(data.get("title", "Ofício"))
	var v := UI.vbox(5)
	add_to_body(v, Vector2(14, 8))
	var prof := str(data.get("prof", ""))
	if str(data.get("mode", "intro")) == "intro":
		v.add_child(UI.label(str(data.get("title", "")), UI.C_ORANGE_L, 2))
		v.add_child(UI.label("Habilidade treinada: " + str(data.get("skill", "")), UI.C_XP))
		v.add_child(UI.wrap_label(str(data.get("how_to", "")), UI.C_TEXT, 460))
		v.add_child(UI.hline())
		v.add_child(UI.label(_prof_line(prof), UI.C_GOLD))
		var played := 0
		if str(GameState.minigame_plays.get("date", "")) == GameState.call("_today"):
			played = int(GameState.minigame_plays.get(prof, 0))
		v.add_child(UI.label("Partidas hoje: %d. Recompensa cheia nas primeiras %d." % [played, GameState.MINIGAME_FULL], UI.C_DIM))
		var row := UI.hbox(8)
		row.add_child(UI.button("Começar o turno", func() -> void: _pick("start"), 130))
		row.add_child(UI.button("Agora não", func() -> void: _pick("exit"), 90))
		add_to_body(row, Vector2(14, 214))
		return
	var score := float(data.get("score", 0.0))
	var r: Dictionary = data.get("reward", {})
	var g: Dictionary = data.get("prof_gain", {})
	v.add_child(UI.label(_grade(score), UI.C_GOLD, 2))
	v.add_child(UI.label("Desempenho: %d%%" % int(round(score * 100.0)), UI.C_TEXT))
	for line in data.get("lines", []):
		v.add_child(UI.label(str(line), UI.C_DIM))
	v.add_child(UI.label("+%d XP   +%d ouro   +%d de ofício" % [int(r.get("xp", 0)), int(r.get("gold", 0)), int(g.get("gain", 0))], UI.C_GOOD))
	if int(g.get("after", 0)) > int(g.get("before", 0)):
		v.add_child(UI.label("Nova patente: %s!" % _prof_title(prof), UI.C_GOLD, 2))
	else:
		v.add_child(UI.label(_prof_line(prof), UI.C_XP))
	if bool(r.get("reduced", false)):
		v.add_child(UI.wrap_label("Você já jogou bastante hoje: a recompensa caiu para 25%. Amanhã volta ao normal.", UI.C_DIM, 460))
	var row2 := UI.hbox(8)
	row2.add_child(UI.button("Jogar de novo", func() -> void: _pick("again"), 110))
	row2.add_child(UI.button("Sair", func() -> void: _pick("exit"), 70))
	add_to_body(row2, Vector2(14, 214))
	Audio.jingle("success" if score >= 0.5 else "defeat", -4.0)


func _pick(c: String) -> void:
	choice = c
	HUD.close_window()


func refresh() -> void:
	pass


static func _prof_title(prof: String) -> String:
	var info: Dictionary = Data.PROFESSIONS.get(prof, {})
	var fem := str(Story.st().get("gender", "m")) == "f"
	return "%s %s" % [GameState.profession_rank_name(prof), str(info.get("fem" if fem else "name", ""))]


static func _prof_line(prof: String) -> String:
	var r := GameState.profession_rank(prof)
	var xp := GameState.profession_xp(prof)
	var nxt := "patente máxima" if r >= Data.PROF_XP.size() - 1 else "%d/%d para %s" % [xp, int(Data.PROF_XP[r + 1]), Data.PROF_RANKS[r + 1]]
	var home := "  (ofício do seu caminho: x2)" if GameState.is_path_profession(prof) else ""
	return "%s  -  %s%s" % [_prof_title(prof), nxt, home]


func _grade(score: float) -> String:
	if score >= 0.95:
		return "Perfeito!"
	if score >= 0.8:
		return "Excelente!"
	if score >= 0.6:
		return "Muito bom"
	if score >= 0.35:
		return "Bom trabalho"
	return "Pode melhorar"
