extends MiniGameWindow

## Cozinha da pousa (mini-jogo v2, ícones: 64 Food Icons 16x16 e caldeirão CC0). Atenção dividida:
## cada pedido passa por TÁBUA (cortar: vários cliques) -> PANELA (cozinhar, tempos diferentes) -> BALCÃO
## (pratos prontos) -> CLIENTE. Prato esquecido com o balcão cheio queima; cliente impaciente vai embora.
## Treina fazer várias coisas ao mesmo tempo e priorizar.

const DURATION := 75.0
const POTS := 3
const SLOTS := 4
const COUNTER := 4
const PATIENCE := 30.0
const BURN_AFTER := 8.0
const DISHES := {
	"pao": {"name": "Pão", "cell": Vector2i(6, 7), "chop": 0, "cook": 4.0},
	"batata": {"name": "Batata", "cell": Vector2i(7, 7), "chop": 2, "cook": 4.0},
	"burger": {"name": "Burger", "cell": Vector2i(3, 6), "chop": 3, "cook": 5.0},
	"bolo": {"name": "Bolo", "cell": Vector2i(3, 4), "chop": 3, "cook": 6.0},
	"peixe": {"name": "Peixe", "cell": Vector2i(3, 2), "chop": 2, "cook": 7.0},
	"pizza": {"name": "Pizza", "cell": Vector2i(6, 6), "chop": 4, "cook": 8.0},
	"sushi": {"name": "Sushi", "cell": Vector2i(3, 7), "chop": 5, "cook": 0.0},
}
const MENU := ["pao", "batata", "burger", "bolo", "peixe", "pizza", "sushi"]
const FACES := ["Villager", "Woman", "Boy", "Villager3", "Child"]

var _cv: MgArt.Canvas
var _time_left: float = DURATION
var _spawn_in: float = 1.0
var _cust: Array = []        # {face, dish, pat} ou null
var _pots: Array = []        # {dish, t, state} ou null
var _board: Dictionary = {}  # {dish, left, waiting} ou vazio
var _counter: Array = []     # ids de pratos ou ""
var _sel: int = -1           # prato selecionado no balcão
var _points: float = 0.0
var _seen: int = 0
var _served: int = 0
var _lost: int = 0
var _burnt: int = 0
var _wrong: int = 0
var _msg: String = ""
var _msg_t: float = 0.0
var _msg_col: Color = UI.C_TEXT


func _init() -> void:
	super()
	win_title = "Cozinha da pousa"
	game_id = "cozinha"
	skill = "atenção dividida e prioridades"
	how_to = "Clientes pedem pratos (ícone no balão) e perdem a paciência. Escolha um prato no cardápio de baixo: " \
		+ "ele vai para a TÁBUA (clique nela para cortar) e depois para uma PANELA livre. Pronto, vai para o BALCÃO: " \
		+ "clique no prato e depois no cliente certo. Balcão cheio faz o prato queimar na panela! São 75 segundos."


func _start_game() -> void:
	_time_left = DURATION
	_spawn_in = 0.8
	_cust = []
	_pots = []
	_counter = []
	for i in SLOTS:
		_cust.append(null)
	for i in POTS:
		_pots.append(null)
	for i in COUNTER:
		_counter.append("")
	_board = {}
	_sel = -1
	_points = 0.0
	_seen = 0
	_served = 0
	_lost = 0
	_burnt = 0
	_wrong = 0
	_msg = ""
	_cv = MgArt.Canvas.new()
	_cv.size = Vector2(520, 272)
	_cv.painter = Callable(self, "_paint")
	_cv.clicked.connect(_on_click)
	_stage.add_child(_cv)


func _say(text: String, col: Color) -> void:
	_msg = text
	_msg_col = col
	_msg_t = 1.5


# ---------------------------------------------------------------- ações
func _on_click(id: String) -> void:
	if phase != "play":
		return
	if id.begins_with("m"):
		_order(MENU[int(id.substr(1))])
	elif id == "board":
		_chop()
	elif id.begins_with("p"):
		pass   # panelas são automáticas; o clique só mostra o estado
	elif id.begins_with("k"):
		var i := int(id.substr(1))
		if _counter[i] != "":
			_sel = -1 if _sel == i else i
			Audio.sfx("ui_click", -8.0)
	elif id.begins_with("c"):
		_serve(int(id.substr(1)))


func _order(dish: String) -> void:
	if not _board.is_empty():
		_say("A tábua está ocupada.", UI.C_BAD)
		Audio.sfx("ui_error")
		return
	var d: Dictionary = DISHES[dish]
	_board = {"dish": dish, "left": int(d["chop"]), "waiting": false}
	Audio.sfx("ui_click", -6.0)
	if int(d["chop"]) == 0:
		_after_chop()


func _chop() -> void:
	if _board.is_empty() or int(_board["left"]) <= 0:
		return
	_board["left"] = int(_board["left"]) - 1
	Audio.sfx2("gaveta", -12.0, 0.15)
	if int(_board["left"]) <= 0:
		_after_chop()


func _after_chop() -> void:
	var dish := str(_board["dish"])
	var d: Dictionary = DISHES[dish]
	if float(d["cook"]) <= 0.0:
		if _to_counter(dish):
			_board = {}
		else:
			_board["waiting"] = true
		return
	for i in POTS:
		if _pots[i] == null:
			_pots[i] = {"dish": dish, "t": 0.0, "state": "cooking"}
			_board = {}
			return
	_board["waiting"] = true      # sem panela livre: fica na tábua


func _to_counter(dish: String) -> bool:
	for i in COUNTER:
		if _counter[i] == "":
			_counter[i] = dish
			return true
	return false


func _serve(i: int) -> void:
	if _cust[i] == null:
		return
	if _sel < 0 or _counter[_sel] == "":
		_say("Escolha um prato no balcão primeiro.", UI.C_DIM)
		return
	var c: Dictionary = _cust[i]
	if c["dish"] == _counter[_sel]:
		var fast: bool = float(c["pat"]) > PATIENCE * 0.5
		_points += 1.5 if fast else 1.0
		_served += 1
		_say("Servido!%s" % (" Gorjeta!" if fast else ""), UI.C_GOOD)
		Audio.sfx2("moedas", -8.0)
	else:
		_wrong += 1
		_say("Não era esse o pedido!", UI.C_BAD)
		Audio.sfx("ui_error")
	_counter[_sel] = ""
	_sel = -1
	_cust[i] = null


# ---------------------------------------------------------------- tempo
func _tick(delta: float) -> void:
	_time_left -= delta
	_msg_t = maxf(0.0, _msg_t - delta)
	_spawn_in -= delta
	if _spawn_in <= 0.0 and _time_left > 10.0:
		for i in SLOTS:
			if _cust[i] == null:
				_cust[i] = {"face": FACES[randi() % FACES.size()], "dish": MENU[randi() % MENU.size()], "pat": PATIENCE}
				_seen += 1
				break
		_spawn_in = lerpf(5.5, 3.4, 1.0 - _time_left / DURATION) + randf_range(-0.6, 0.6)
	for i in SLOTS:
		if _cust[i] != null:
			_cust[i]["pat"] = float(_cust[i]["pat"]) - delta
			if float(_cust[i]["pat"]) <= 0.0:
				_cust[i] = null
				_lost += 1
				_say("Um cliente foi embora...", UI.C_BAD)
	for i in POTS:
		if _pots[i] == null:
			continue
		var p: Dictionary = _pots[i]
		p["t"] = float(p["t"]) + delta
		if p["state"] == "cooking" and float(p["t"]) >= float(DISHES[p["dish"]]["cook"]):
			p["state"] = "ready"
			p["t"] = 0.0
			Audio.sfx2("ding", -10.0)
		if p["state"] == "ready":
			if _to_counter(str(p["dish"])):
				_pots[i] = null
			elif float(p["t"]) >= BURN_AFTER:
				_pots[i] = null
				_burnt += 1
				_say("Um prato queimou! (balcão cheio)", UI.C_BAD)
	# prato esperando vaga na tábua
	if not _board.is_empty() and bool(_board["waiting"]):
		_after_chop()
	if _time_left <= 0.0:
		_end()
	if _cv != null:
		_cv.queue_redraw()


func _end() -> void:
	var score := _points / (1.5 * float(maxi(_seen, 1))) - 0.04 * float(_burnt) - 0.03 * float(_wrong)
	_finish(clampf(score, 0.0, 1.0))


# ---------------------------------------------------------------- desenho
func _food(c: MgArt.Canvas, dish: String, pos: Vector2, k: float, mod: Color = Color.WHITE) -> void:
	var cell: Vector2i = DISHES[dish]["cell"]
	MgArt.blit(c, MgArt.cell("food64.png", cell.x, cell.y), pos, k, mod)


func _paint(c: MgArt.Canvas) -> void:
	var t_ms := Time.get_ticks_msec()
	c.draw_rect(Rect2(0, 0, 520, 272), Color("3a2c1e"))
	for x in range(0, 520, 40):
		c.draw_line(Vector2(x, 0), Vector2(x, 272), Color(0, 0, 0, 0.12), 1.0)
	# clientes
	c.draw_rect(Rect2(0, 0, 520, 78), Color("2a2118"))
	for i in SLOTS:
		var x := 6.0 + float(i) * 128.0
		c.draw_rect(Rect2(x, 4, 122, 70), Color("463626"))
		c.draw_rect(Rect2(x, 4, 122, 70), UI.C_LINE, false, 1.0)
		c.hit_area(Rect2(x, 4, 122, 70), "c%d" % i)
		if _cust[i] == null:
			c.text("(mesa livre)", Vector2(x + 28, 44), UI.C_DIM, 12, false)
			continue
		var cu: Dictionary = _cust[i]
		var r: float = float(cu["pat"]) / PATIENCE
		MgArt.blit(c, MgArt.face(str(cu["face"])), Vector2(x + 6, 10), 1.3, Color(1, 1, 1, 1) if r > 0.25 else Color(1.0, 0.7, 0.7))
		# balão do pedido
		c.draw_rect(Rect2(x + 62, 8, 54, 44), Color("f4ecda"))
		c.draw_rect(Rect2(x + 62, 8, 54, 44), UI.C_LINE, false, 1.0)
		_food(c, str(cu["dish"]), Vector2(x + 69, 12), 2.5)
		var sel_ok: bool = _sel >= 0 and _counter[_sel] == str(cu["dish"])
		if sel_ok:
			c.draw_rect(Rect2(x + 1, 5, 120, 68), Color(0.55, 1.0, 0.55, 0.9), false, 2.0)
		c.bar(Rect2(x + 6, 62, 110, 6), r, UI.C_GOOD if r > 0.5 else (UI.C_ENERGY if r > 0.25 else UI.C_BAD))
	# tábua
	c.draw_rect(Rect2(6, 84, 124, 66), Color("8a5a2a"))
	c.draw_rect(Rect2(6, 84, 124, 66), UI.C_LINE, false, 2.0)
	c.hit_area(Rect2(6, 84, 124, 66), "board")
	c.text("Tábua", Vector2(12, 98), UI.C_TEXT, 12)
	if not _board.is_empty():
		_food(c, str(_board["dish"]), Vector2(46, 100), 2.5)
		var left := int(_board["left"])
		if bool(_board["waiting"]):
			c.text("Sem vaga...", Vector2(30, 146), UI.C_BAD, 12)
		elif left > 0:
			c.text("Clique: corte x%d" % left, Vector2(20, 146), UI.C_GOLD, 12)
	else:
		c.text("(livre)", Vector2(44, 124), Color(1, 1, 1, 0.5), 12, false)
	# panelas
	for i in POTS:
		var x := 140.0 + float(i) * 126.0
		c.draw_rect(Rect2(x, 84, 120, 66), Color("2c2c34"))
		c.draw_rect(Rect2(x, 84, 120, 66), UI.C_LINE, false, 2.0)
		var cooking: bool = _pots[i] != null and _pots[i]["state"] == "cooking"
		MgArt.blit(c, MgArt.sheet("pc_cooker3.png", (int(t_ms / 140) % 4) if cooking else 0, 4, 48, 32), Vector2(x + 12, 90), 2.0)
		if _pots[i] == null:
			continue
		var p: Dictionary = _pots[i]
		_food(c, str(p["dish"]), Vector2(x + 44, 84), 2.0)
		if p["state"] == "cooking":
			var need := float(DISHES[p["dish"]]["cook"])
			c.bar(Rect2(x + 8, 140, 104, 6), float(p["t"]) / need, UI.C_ORANGE)
			for j in 3:
				c.draw_circle(Vector2(x + 42 + j * 18, 100 - fmod(t_ms * 0.03 + j * 9.0, 22.0)), 2.5, Color(1, 1, 1, 0.5))
		else:
			c.bar(Rect2(x + 8, 140, 104, 6), 1.0 - float(p["t"]) / BURN_AFTER, UI.C_BAD)
			c.text("Balcão cheio!", Vector2(x + 18, 134), UI.C_BAD, 12)
	# balcão
	c.draw_rect(Rect2(0, 156, 520, 40), Color("5a4630"))
	c.text("Balcão", Vector2(8, 180), UI.C_TEXT, 12)
	for i in COUNTER:
		var x := 70.0 + float(i) * 108.0
		c.draw_rect(Rect2(x, 160, 100, 32), Color("d8d0c0") if _sel != i else Color("ffe9a8"))
		c.draw_rect(Rect2(x, 160, 100, 32), UI.C_LINE, false, 1.0)
		c.hit_area(Rect2(x, 160, 100, 32), "k%d" % i)
		if _counter[i] != "":
			_food(c, str(_counter[i]), Vector2(x + 34, 162), 1.8)
	# cardápio
	c.draw_rect(Rect2(0, 200, 520, 52), Color("2a2118"))
	for i in MENU.size():
		var x := 6.0 + float(i) * 73.0
		var d: Dictionary = DISHES[MENU[i]]
		var hover: bool = c.hover == "m%d" % i
		c.draw_rect(Rect2(x, 202, 68, 48), Color("5a4630") if not hover else Color("7a6040"))
		c.draw_rect(Rect2(x, 202, 68, 48), UI.C_LINE, false, 1.0)
		c.hit_area(Rect2(x, 202, 68, 48), "m%d" % i)
		_food(c, MENU[i], Vector2(x + 3, 205), 2.0)
		c.text(str(d["name"]), Vector2(x + 4, 246), UI.C_TEXT, 12, false)
		if int(d["chop"]) > 0:
			c.text("C%d" % int(d["chop"]), Vector2(x + 40, 218), UI.C_DIM, 12, false)
		if float(d["cook"]) > 0.0:
			c.text("F%ds" % int(d["cook"]), Vector2(x + 40, 232), UI.C_ORANGE_L, 12, false)
	# status
	c.text("Tempo %d s   Servidos %d   Perdidos %d   Queimados %d   (C = cortes, F = fogo)" % [maxi(0, int(ceil(_time_left))), _served, _lost, _burnt], Vector2(8, 266), UI.C_GOLD, 12)
	if _msg_t > 0.0:
		c.text(_msg, Vector2(150, 190), _msg_col, 12)
