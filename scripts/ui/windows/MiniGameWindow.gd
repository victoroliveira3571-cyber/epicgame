class_name MiniGameWindow
extends UIWindow

## v3.1: base dos mini-jogos (forja, cozinha, laboratório). Cada um treina uma habilidade mental e paga
## XP e um pouco de ouro pelo desempenho (GameState.minigame_reward). Fluxo: tela inicial -> jogo -> resultado.
## Subclasses definem `game_id`, `skill`, `how_to`, e implementam `_start_game()` e `_tick(delta)`.

var game_id: String = ""
var skill: String = ""
var how_to: String = ""
var phase: String = "intro"          # intro | play | result
var _stage: Control                   # área do jogo (recriada a cada partida)


func _init() -> void:
	win_size = Vector2(540, 310)


func build() -> void:
	phase = "intro" if phase != "play" else phase
	_show_intro()


func _clear() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	_stage = null


func _show_intro() -> void:
	_clear()
	phase = "intro"
	var v := UI.vbox(6)
	add_to_body(v, Vector2(20, 14))
	v.add_child(UI.label("Habilidade treinada: " + skill, UI.C_ORANGE_L))
	v.add_child(UI.wrap_label(how_to, UI.C_TEXT, 470))
	var played := 0
	if str(GameState.minigame_plays.get("date", "")) == GameState.call("_today"):
		played = int(GameState.minigame_plays.get(game_id, 0))
	var note := "Partidas hoje: %d.  Recompensa cheia nas primeiras %d." % [played, GameState.MINIGAME_FULL]
	if Data.PROFESSIONS.has(game_id):
		v.add_child(UI.label(ShiftWindow._prof_line(game_id), UI.C_GOLD))
	v.add_child(UI.label(note, UI.C_DIM))
	var go := UI.button("Começar", func() -> void: _begin(), 100)
	add_to_body(go, Vector2(20, 210))
	var back := UI.button("Voltar", func() -> void: _back(), 70)
	add_to_body(back, Vector2(130, 210))


func _back() -> void:
	HUD.close_window()


func _begin() -> void:
	_clear()
	phase = "play"
	_stage = Control.new()
	_stage.size = body.size
	body.add_child(_stage)
	_start_game()


## Fim da partida: `score` de 0 a 1. Mostra o resultado e paga a recompensa.
func _finish(score: float) -> void:
	if phase == "result":
		return
	phase = "result"
	var r := GameState.minigame_reward(game_id, score)
	var pg: Dictionary = GameState.add_profession_xp(game_id, score) if Data.PROFESSIONS.has(game_id) else {}
	_clear()
	var v := UI.vbox(6)
	add_to_body(v, Vector2(20, 14))
	v.add_child(UI.label(_grade(score), UI.C_GOLD, 2))
	v.add_child(UI.label("Desempenho: %d%%" % int(round(score * 100.0)), UI.C_TEXT))
	v.add_child(UI.label("+%d XP   +%d ouro%s" % [int(r["xp"]), int(r["gold"]), ("   +%d de ofício" % int(pg["gain"])) if not pg.is_empty() else ""], UI.C_GOOD))
	if not pg.is_empty():
		v.add_child(UI.label(("Nova patente: " if int(pg["after"]) > int(pg["before"]) else "") + ShiftWindow._prof_line(game_id), UI.C_GOLD))
	if bool(r["reduced"]):
		v.add_child(UI.wrap_label("Você já jogou bastante hoje: a recompensa caiu para 25%. Amanhã volta ao normal.", UI.C_DIM, 470))
	Audio.jingle("success" if score >= 0.5 else "defeat", -4.0)
	add_to_body(UI.button("Jogar de novo", func() -> void: _begin(), 100), Vector2(20, 210))
	add_to_body(UI.button("Sair", func() -> void: _back(), 70), Vector2(130, 210))


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


func refresh() -> void:
	pass   # o estado do jogo muda durante a partida (ouro, XP); não reconstruir


func _process(delta: float) -> void:
	if phase == "play":
		_tick(delta)


func _start_game() -> void:
	pass


func _tick(_delta: float) -> void:
	pass
