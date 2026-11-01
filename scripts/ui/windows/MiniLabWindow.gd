extends MiniGameWindow

## v3.7: Laboratório do Dr. Faísca: "Fórmula Secreta" (ofício de Alquimista, caminho do Exército na história v4).
## Raciocínio lógico e memória de trabalho (dedução, como o Mastermind). O doutor guarda uma receita secreta de
## ingredientes numa ordem. Você testa misturas no caldeirão; cada teste solta bolhas: DOURADA = ingrediente certo
## no lugar certo, PRATEADA = ingrediente certo no lugar errado. Descubra a receita com o menor número de testes.
## Três rodadas: 3 frascos de 4 cores; 4 de 6; 4 de 6 com repetição. Arte: frascos do Potion Pack e a mesa de
## alquimia animada do Pixel Crawler.

const ROUNDS := [
	{"slots": 3, "pool": 4, "repeat": false, "tries": 7},
	{"slots": 4, "pool": 6, "repeat": false, "tries": 8},
	{"slots": 4, "pool": 6, "repeat": true, "tries": 9},
]
const HERBS := [
	{"name": "Fogo", "color": "red", "rgb": Color("e0463a")},
	{"name": "Gelo", "color": "blue", "rgb": Color("4a8ee0")},
	{"name": "Seiva", "color": "green", "rgb": Color("62d168")},
	{"name": "Éter", "color": "purple", "rgb": Color("b06ae8")},
	{"name": "Luz", "color": "yellow", "rgb": Color("f0d24a")},
	{"name": "Brisa", "color": "cyan", "rgb": Color("4ad8d8")},
]
const TOTAL_TIME := 210.0
const LINES_OK := ["Eureca! Exatamente a minha fórmula!", "Brilhante! A Pipeta vai anotar isso.", "Correto! O Tonico desmaiou de emoção."]
const LINES_HINT := ["Hm, bolhas douradas: alguém está no lugar certo.", "Prateadas... o ingrediente existe, mas não aí.",
	"Nenhuma bolha? Então esses frascos nem entram na receita!", "Lembre do que cada teste já mostrou."]

var _cv: MgArt.Canvas
var _round: int = 0
var _secret: Array = []
var _guess: Array = []
var _history: Array = []        # [{g: Array, gold: int, silver: int}]
var _time: float = TOTAL_TIME
var _scores: Array = []
var _line: String = ""
var _pause_t: float = 0.0
var _anim_t: float = 0.0
var _bubble: Color = Color(0.5, 0.8, 0.6)


func _init() -> void:
	super()
	win_title = "Laboratório do Dr. Faísca: Fórmula Secreta"
	game_id = "lab"
	skill = "raciocínio lógico e memória de trabalho"
	how_to = "O Dr. Faísca esconde uma receita: alguns frascos numa ordem certa. Clique nos frascos para montar um teste e " \
		+ "em MISTURAR. Bolha DOURADA = frasco certo no lugar certo; PRATEADA = frasco certo no lugar errado. Use o que " \
		+ "cada teste revelou para deduzir a receita com poucos testes. Três rodadas, a última pode repetir frascos."
	win_size = Vector2(560, 320)


func _start_game() -> void:
	_round = 0
	_scores = []
	_time = TOTAL_TIME
	_cv = MgArt.Canvas.new()
	_cv.size = Vector2(540, 282)
	_cv.painter = Callable(self, "_paint")
	_cv.clicked.connect(_on_click)
	_stage.add_child(_cv)
	_new_round()


func _new_round() -> void:
	var r: Dictionary = ROUNDS[_round]
	_secret = []
	var pool := range(int(r["pool"]))
	pool.shuffle()
	for i in int(r["slots"]):
		_secret.append(randi() % int(r["pool"]) if bool(r["repeat"]) else pool[i])
	_guess = []
	_history = []
	_line = "Rodada %d: %d frascos, %s. Comece testando!" % [_round + 1, int(r["slots"]), "pode repetir cor" if bool(r["repeat"]) else "sem repetir cor"]
	_bubble = Color(0.5, 0.8, 0.6)


func _tick(delta: float) -> void:
	_anim_t += delta
	if _pause_t > 0.0:
		_pause_t -= delta
		if _pause_t <= 0.0:
			_round += 1
			if _round >= ROUNDS.size():
				_end_game()
				return
			_new_round()
	else:
		_time -= delta
		if _time <= 0.0:
			_round_done(false)
			_end_game()
			return
	_cv.queue_redraw()


func _end_game() -> void:
	while _scores.size() < ROUNDS.size():
		_scores.append(0.0)
	var total := 0.0
	for s in _scores:
		total += float(s)
	_finish(total / float(ROUNDS.size()))


func _on_click(id: String) -> void:
	if _pause_t > 0.0:
		return
	var r: Dictionary = ROUNDS[_round]
	if id.begins_with("herb_"):
		var h := int(id.substr(5))
		if _guess.size() >= int(r["slots"]):
			return
		if not bool(r["repeat"]) and _guess.has(h):
			_line = "Nesta rodada cada frasco aparece uma vez só."
			Audio.sfx("ui_error", -8.0)
			return
		_guess.append(h)
		Audio.sfx2("gota", -8.0, 0.15)
	elif id == "undo" and not _guess.is_empty():
		_guess.pop_back()
		Audio.ui_click()
	elif id == "mix" and _guess.size() == int(r["slots"]):
		_mix()


func _mix() -> void:
	var r: Dictionary = ROUNDS[_round]
	var gold := 0
	var silver := 0
	var left_s: Array = []
	var left_g: Array = []
	for i in _secret.size():
		if _guess[i] == _secret[i]:
			gold += 1
		else:
			left_s.append(_secret[i])
			left_g.append(_guess[i])
	for g in left_g:
		var k := left_s.find(g)
		if k >= 0:
			silver += 1
			left_s.remove_at(k)
	_history.append({"g": _guess.duplicate(), "gold": gold, "silver": silver})
	var c := Color(0, 0, 0)
	for g in _guess:
		c += HERBS[g]["rgb"]
	_bubble = c / float(_guess.size())
	_guess = []
	Audio.sfx2("servir_agua", -8.0, 0.05)
	if gold == _secret.size():
		_line = LINES_OK[randi() % LINES_OK.size()]
		Audio.jingle("success", -6.0)
		_round_done(true)
		return
	if _history.size() >= int(r["tries"]):
		_line = "Acabaram os testes desta rodada. A receita era outra..."
		Audio.sfx("ui_error", -6.0)
		_round_done(false)
		return
	_line = LINES_HINT[0] if gold > 0 else (LINES_HINT[1] if silver > 0 else LINES_HINT[2])
	if randf() < 0.25:
		_line = LINES_HINT[3]


func _round_done(solved: bool) -> void:
	var r: Dictionary = ROUNDS[_round]
	var tries := _history.size()
	var sc := 0.0
	if solved:
		sc = 0.45 + 0.55 * (1.0 - float(tries - 1) / float(int(r["tries"]) - 1))
	elif not _history.is_empty():
		var best := 0
		for h in _history:
			best = maxi(best, int(h["gold"]))
		sc = 0.3 * float(best) / float(_secret.size())
	_scores.append(clampf(sc, 0.0, 1.0))
	_pause_t = 2.4


# ================================================================== Desenho
func _paint(c: MgArt.Canvas) -> void:
	var r: Dictionary = ROUNDS[mini(_round, ROUNDS.size() - 1)]
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color("1d1a2a"))
	c.text("Rodada %d de 3" % (mini(_round, 2) + 1), Vector2(8, 14), UI.C_ORANGE_L)
	c.text("Testes: %d / %d" % [_history.size(), int(r["tries"])], Vector2(150, 14), UI.C_TEXT)
	c.text("%d s" % int(maxf(_time, 0.0)), Vector2(490, 14), UI.C_GOLD if _time > 30.0 else UI.C_BAD)
	# mesa de alquimia animada e as bolhas da última mistura
	var af := int(_anim_t * 8.0) % 20 + 6 if _history.size() > 0 else int(_anim_t * 4.0) % 6
	MgArt.blit(c, MgArt.sheet("pc_alchemy1.png", af, 6, 32, 64), Vector2(30, 40), 2.0)
	for i in 6:
		var k := fmod(_anim_t * 0.7 + i * 0.17, 1.0)
		c.draw_circle(Vector2(62 + sin(_anim_t * 3.0 + i) * 10.0, 80 - k * 46.0), 2.0 + k * 3.0, Color(_bubble, 0.7 * (1.0 - k)))
	c.draw_rect(Rect2(8, 180, 132, 70), Color(0.12, 0.1, 0.16, 0.95))
	c.draw_rect(Rect2(8, 180, 132, 70), UI.C_LINE, false, 1.0)
	c.text("Dr. Faísca:", Vector2(14, 194), UI.C_ORANGE_L)
	_wrap_text(c, _line, Vector2(14, 208), 124)
	# histórico dos testes
	var x0 := 160.0
	for i in _history.size():
		var h: Dictionary = _history[i]
		var y := 26.0 + i * 24.0
		c.draw_rect(Rect2(x0 - 4, y - 2, 236, 22), Color(0.14, 0.12, 0.2, 0.8))
		for j in (h["g"] as Array).size():
			_flask(c, int(h["g"][j]), Vector2(x0 + j * 26, y), 1.15)
		var px := x0 + 120.0
		for k in int(h["gold"]):
			c.draw_circle(Vector2(px + k * 12, y + 9), 4.5, Color("ffd24a"))
			c.draw_arc(Vector2(px + k * 12, y + 9), 4.5, 0, TAU, 12, Color("7a5a10"), 1.0)
		for k in int(h["silver"]):
			var sx := px + (int(h["gold"]) + k) * 12
			c.draw_circle(Vector2(sx, y + 9), 4.5, Color("d8dde8"))
			c.draw_arc(Vector2(sx, y + 9), 4.5, 0, TAU, 12, Color("5a6070"), 1.0)
	# teste atual
	var ty := 236.0
	c.text("Seu teste:", Vector2(x0 - 4, ty - 6), UI.C_DIM)
	for j in int(r["slots"]):
		var rect := Rect2(x0 + j * 30, ty, 24, 24)
		c.draw_rect(rect, Color(0.1, 0.08, 0.14))
		c.draw_rect(rect, UI.C_ORANGE if j == _guess.size() else UI.C_LINE, false, 1.0)
		if j < _guess.size():
			_flask(c, int(_guess[j]), rect.position + Vector2(2, 2), 1.25)
	# frascos para escolher
	for i in int(r["pool"]):
		var bx := 410.0 + float(i % 2) * 62.0
		var by := 30.0 + float(i / 2) * 52.0
		var rr := Rect2(bx, by, 56, 46)
		c.draw_rect(rr, Color(0.16, 0.13, 0.22) if c.hover != "herb_%d" % i else Color(0.26, 0.2, 0.34))
		c.draw_rect(rr, UI.C_LINE, false, 1.0)
		_flask(c, i, Vector2(bx + 16, by + 4), 1.5)
		c.text(str(HERBS[i]["name"]), Vector2(bx + 4, by + 42), HERBS[i]["rgb"], 12)
		c.hit_area(rr, "herb_%d" % i)
	var bu := Rect2(410, 196, 118, 22)
	c.draw_rect(bu, Color(0.25, 0.2, 0.18) if c.hover != "undo" else Color(0.35, 0.28, 0.24))
	c.draw_rect(bu, UI.C_LINE, false, 1.0)
	c.text("Desfazer", Vector2(440, 211), UI.C_TEXT)
	c.hit_area(bu, "undo")
	var bm := Rect2(410, 224, 118, 30)
	var ready := _guess.size() == int(r["slots"])
	c.draw_rect(bm, (UI.C_ORANGE if ready else Color(0.3, 0.25, 0.2)) if c.hover != "mix" else UI.C_ORANGE_L)
	c.text("MISTURAR", Vector2(436, 244), UI.C_TEXT if ready else UI.C_DIM, 12)
	c.hit_area(bm, "mix")
	if _pause_t > 0.0:
		c.draw_rect(Rect2(160, 236, 230, 26), Color(0, 0, 0, 0.75))
		c.text("Receita:", Vector2(164, 253), UI.C_GOLD)
		for j in _secret.size():
			_flask(c, int(_secret[j]), Vector2(224 + j * 26, 238), 1.1)


func _flask(c: CanvasItem, i: int, pos: Vector2, k: float) -> void:
	MgArt.blit(c, MgArt.cell("potions_%s.png" % HERBS[i]["color"], 0, 4), pos, k)


func _wrap_text(c: MgArt.Canvas, s: String, pos: Vector2, width: float) -> void:
	var words := s.split(" ")
	var line := ""
	var y := pos.y
	var f := Pix.font(1)
	for w in words:
		var test := (line + " " + w).strip_edges()
		if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x > width and line != "":
			c.text(line, Vector2(pos.x, y), UI.C_TEXT, 12, false)
			y += 12.0
			line = w
		else:
			line = test
	if line != "":
		c.text(line, Vector2(pos.x, y), UI.C_TEXT, 12, false)
