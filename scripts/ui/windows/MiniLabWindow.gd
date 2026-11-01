extends MiniGameWindow

## Laboratório do Dr. Faísca (mini-jogo v2, arte: Potion Pack, Pixel Potions e caldeirão CC0): alquimia.
## O doutor pede uma poção com CALOR, ACIDEZ e ENERGIA exatos. Cada ingrediente soma esses três números;
## misture até os medidores baterem com a receita. Nas duas primeiras poções os efeitos estão à vista; nas
## outras ficam ocultos, e você deduz pelo que os medidores mostram e pelo que aprendeu antes.
## Treina raciocínio e memória de trabalho.

const ROUNDS := [2, 2, 3, 3, 4]       # ingredientes usados para montar cada pedido
const ROUND_TIME := 50.0
const MAX_ADD := 5
const AXES := ["Calor", "Acidez", "Energia"]
const HERBS := [
	{"name": "Fogo", "color": "red", "fx": [3, 1, 0], "rgb": Color("e0463a")},
	{"name": "Gelo", "color": "blue", "fx": [-3, 0, 1], "rgb": Color("4a8ee0")},
	{"name": "Seiva", "color": "green", "fx": [0, -2, 1], "rgb": Color("62d168")},
	{"name": "Éter", "color": "purple", "fx": [1, 1, 3], "rgb": Color("b06ae8")},
	{"name": "Luz", "color": "yellow", "fx": [1, -1, 2], "rgb": Color("f0d24a")},
	{"name": "Brisa", "color": "cyan", "fx": [-1, 2, -1], "rgb": Color("4ad8d8")},
]

var _cv: MgArt.Canvas
var _round: int = 0
var _target: Array = [0, 0, 0]
var _mix: Array = []
var _time: float = ROUND_TIME
var _total: float = 0.0
var _msg: String = ""
var _msg_t: float = 0.0
var _msg_col: Color = UI.C_TEXT
var _pause_t: float = 0.0
var _revealed: bool = true


func _init() -> void:
	super()
	win_title = "Laboratório: alquimia"
	game_id = "laboratorio"
	skill = "raciocínio e memória de trabalho"
	how_to = "O Dr. Faísca pede uma poção com Calor, Acidez e Energia exatos (números dourados). Cada ingrediente soma " \
		+ "valores a esses três medidores. Clique nos frascos para pôr no caldeirão e misture quando os medidores baterem. " \
		+ "Nas duas primeiras poções os efeitos aparecem; nas outras ficam ocultos: deduza pelos medidores e lembre do que aprendeu."


func _start_game() -> void:
	_round = 0
	_total = 0.0
	_cv = MgArt.Canvas.new()
	_cv.size = Vector2(520, 272)
	_cv.painter = Callable(self, "_paint")
	_cv.clicked.connect(_on_click)
	_stage.add_child(_cv)
	_new_round()


func _new_round() -> void:
	var n: int = ROUNDS[_round]
	_mix = []
	var sum := [0, 0, 0]
	for i in n:
		var h: Dictionary = HERBS[randi() % HERBS.size()]
		for a in 3:
			sum[a] += int(h["fx"][a])
	_target = sum
	_revealed = _round < 2
	_time = ROUND_TIME
	_msg = ""
	_pause_t = 0.0


func _current() -> Array:
	var sum := [0, 0, 0]
	for i in _mix:
		for a in 3:
			sum[a] += int(HERBS[i]["fx"][a])
	return sum


func _on_click(id: String) -> void:
	if phase != "play" or _pause_t > 0.0:
		return
	if id.begins_with("h"):
		if _mix.size() >= MAX_ADD:
			_say("O caldeirão está cheio.", UI.C_BAD)
			Audio.sfx("ui_error")
			return
		_mix.append(int(id.substr(1)))
		Audio.sfx2("gota", -8.0, 0.1)
	elif id == "undo":
		if not _mix.is_empty():
			_mix.pop_back()
			Audio.sfx("ui_click", -8.0)
	elif id == "brew":
		_submit()


func _say(t: String, col: Color) -> void:
	_msg = t
	_msg_col = col
	_msg_t = 1.4


func _submit() -> void:
	if _mix.is_empty():
		_say("Ponha ao menos um ingrediente.", UI.C_BAD)
		return
	var cur := _current()
	var dist := 0
	for a in 3:
		dist += absi(int(cur[a]) - int(_target[a]))
	var n: int = ROUNDS[_round]
	var acc := clampf(1.0 - float(dist) / (2.0 * float(n) + 2.0), 0.0, 1.0)
	_total += acc
	if dist == 0:
		_say("POÇÃO PERFEITA!", UI.C_GOLD)
		Audio.sfx2("ding", -4.0)
	elif acc >= 0.6:
		_say("Quase! (erro %d)" % dist, UI.C_GOOD)
		Audio.sfx2("ding", -10.0)
	else:
		_say("A poção desandou. (erro %d)" % dist, UI.C_BAD)
		Audio.sfx("ui_error")
	_revealed = true
	_pause_t = 1.6


func _tick(delta: float) -> void:
	_msg_t = maxf(0.0, _msg_t - delta)
	if _pause_t > 0.0:
		_pause_t -= delta
		if _pause_t <= 0.0:
			_round += 1
			if _round >= ROUNDS.size():
				_finish(_total / float(ROUNDS.size()))
				return
			_new_round()
	else:
		_time -= delta
		if _time <= 0.0:
			_say("O tempo acabou!", UI.C_BAD)
			_submit_timeout()
	if _cv != null:
		_cv.queue_redraw()


func _submit_timeout() -> void:
	if _mix.is_empty():
		_pause_t = 1.2
		_revealed = true
		return
	_submit()


# ---------------------------------------------------------------- desenho
func _mix_color() -> Color:
	if _mix.is_empty():
		return Color(0.25, 0.3, 0.35)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for i in _mix:
		var col: Color = HERBS[i]["rgb"]
		r += col.r
		g += col.g
		b += col.b
	var n := float(_mix.size())
	return Color(r / n, g / n, b / n)


func _paint(c: MgArt.Canvas) -> void:
	var t_ms := Time.get_ticks_msec()
	c.draw_rect(Rect2(0, 0, 520, 272), Color("231d2c"))
	c.draw_rect(Rect2(0, 232, 520, 40), Color("3a2c3f"))
	for x in range(0, 520, 40):
		c.draw_line(Vector2(x, 0), Vector2(x, 272), Color(1, 1, 1, 0.03), 1.0)
	# cabeçalho
	c.text("Poção %d de %d   (C Calor, A Acidez, E Energia)" % [mini(_round + 1, ROUNDS.size()), ROUNDS.size()], Vector2(10, 16), UI.C_ORANGE_L, 12)
	c.bar(Rect2(360, 6, 110, 8), _time / ROUND_TIME, UI.C_GOOD if _time > 15.0 else UI.C_BAD)
	c.text("%d s" % maxi(0, int(ceil(_time))), Vector2(476, 14), UI.C_DIM, 12, false)
	# mesa de alquimia (Pixel Crawler): parada enquanto você monta; anima ao misturar
	var mc := _mix_color()
	var af := 0
	if _pause_t > 0.0:
		af = 6 + clampi(int((1.0 - _pause_t / 1.6) * 54.0), 0, 54)
	c.draw_circle(Vector2(110, 138), 44.0, Color(mc.r, mc.g, mc.b, 0.12))
	MgArt.blit(c, MgArt.sheet("pc_alchemy1.png", af, 6, 32, 64), Vector2(80, 44), 2.0)
	if not _mix.is_empty():
		c.draw_circle(Vector2(122, 116), 4.0, Color(mc.r, mc.g, mc.b, 0.9))
	# frascos já postos
	for j in _mix.size():
		var h: Dictionary = HERBS[_mix[j]]
		MgArt.blit(c, MgArt.cell("potions_%s.png" % h["color"], j % 6, 4), Vector2(28 + j * 22, 52), 1.3)
	c.text("Caldeirão (%d/%d)" % [_mix.size(), MAX_ADD], Vector2(28, 44), UI.C_DIM, 12, false)
	# medidores
	var cur := _current()
	for a in 3:
		var y := 40.0 + a * 40.0
		var x0 := 262.0
		var w := 240.0
		c.text(AXES[a], Vector2(x0, y), UI.C_TEXT, 12, false)
		var lo := -9.0
		var span := 18.0
		c.draw_rect(Rect2(x0, y + 6, w, 12), Color("1d1a18"))
		var zero := x0 + w * (0.0 - lo) / span
		c.draw_line(Vector2(zero, y + 4), Vector2(zero, y + 20), Color(1, 1, 1, 0.3), 1.0)
		var cv := clampf(float(cur[a]), lo, lo + span)
		var cx := x0 + w * (cv - lo) / span
		var ok: bool = int(cur[a]) == int(_target[a])
		c.draw_rect(Rect2(minf(zero, cx), y + 7, absf(cx - zero), 10), UI.C_GOOD if ok else UI.C_ORANGE)
		var tx := x0 + w * (clampf(float(_target[a]), lo, lo + span) - lo) / span
		c.draw_rect(Rect2(tx - 2, y + 2, 4, 20), UI.C_GOLD)
		c.draw_rect(Rect2(x0, y + 6, w, 12), UI.C_LINE, false, 1.0)
		c.text("%d / %d" % [cur[a], _target[a]], Vector2(x0 + w - 56, y), UI.C_GOLD if ok else UI.C_DIM, 12, false)
	# ingredientes
	for i in HERBS.size():
		var h: Dictionary = HERBS[i]
		var x := 10.0 + float(i) * 84.0
		var hover: bool = c.hover == "h%d" % i
		c.draw_rect(Rect2(x, 176, 78, 78), Color("3a3048") if not hover else Color("554466"))
		c.draw_rect(Rect2(x, 176, 78, 78), UI.C_LINE, false, 1.0)
		c.hit_area(Rect2(x, 176, 78, 78), "h%d" % i)
		MgArt.blit(c, MgArt.cell("potions_%s.png" % h["color"], i % 6, 4), Vector2(x + 15, 180), 3.0)
		c.text(str(h["name"]), Vector2(x + 6, 240), UI.C_TEXT, 12, false)
		var fx_txt := "C? A? E?"
		if _revealed:
			fx_txt = "C%+d A%+d E%+d" % [h["fx"][0], h["fx"][1], h["fx"][2]]
		c.text(fx_txt, Vector2(x + 4, 252), UI.C_DIM, 12, false)
	# botões
	c.draw_rect(Rect2(262, 150, 112, 22), Color("5a4630"))
	c.draw_rect(Rect2(262, 150, 112, 22), UI.C_LINE, false, 1.0)
	c.hit_area(Rect2(262, 150, 112, 22), "undo")
	c.text("Desfazer", Vector2(290, 166), UI.C_TEXT, 12, false)
	c.draw_rect(Rect2(386, 150, 116, 22), UI.C_ORANGE)
	c.draw_rect(Rect2(386, 150, 116, 22), UI.C_LINE, false, 1.0)
	c.hit_area(Rect2(386, 150, 116, 22), "brew")
	c.text("Misturar", Vector2(418, 166), UI.C_TEXT, 12, false)
	c.text("C = Calor, A = Acidez, E = Energia", Vector2(262, 190 - 14), UI.C_DIM, 12, false) if false else null
	if _msg_t > 0.0:
		c.text(_msg, Vector2(60, 270), _msg_col, 12)
