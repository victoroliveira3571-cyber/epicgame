extends MiniGameWindow

## v3.7: Ateliê da Rosa: ofício de Costureiro (história v4, caminho da Guilda). Memória e precisão.
## Três clientes por turno. Cada um mostra a roupa que quer (personagem LPC vestido) por alguns segundos;
## depois a roupa some e você monta no manequim: modelo e cor da parte de cima e da parte de baixo (e, no último
## cliente, a cor da capa). Por fim, costura: a agulha corre pela costura e você aperta ESPAÇO (ou clica) em cada
## ponto marcado. Nota = memória (60%) + costura (40%). Arte: roupas e corpos do LPC (pack), nada desenhado à mão.

const TOPS := ["camiseta", "camisa_social", "blusa_ombro", "moletom", "cardigan", "polo"]
const BOTTOMS := ["calca", "calca_larga", "saia", "bermuda", "bombacha", "calca_listrada"]
const COLORS := ["red", "blue", "green", "yellow", "purple", "white", "black", "orange"]
const CAPES := ["red", "blue", "green", "purple", "black", "white"]
const SHOW_TIME := [6.0, 5.0, 4.5]
const SHORT := {"camiseta": "Camiseta", "camisa_social": "Camisa", "blusa_ombro": "Blusa", "moletom": "Moletom", "cardigan": "Cardigã",
	"polo": "Polo", "calca": "Calça", "calca_larga": "Comprida", "saia": "Saia", "bermuda": "Bermuda", "bombacha": "Bombacha",
	"calca_listrada": "Listrada"}
const STITCHES := [6, 8, 10]

var _round: int = 0
var _phase: String = ""          # show | build | sew | judge
var _t: float = 0.0
var _want: Dictionary = {}
var _have: Dictionary = {}
var _scores: Array = []
var _client: AppearanceEditor.Preview
var _mannequin: AppearanceEditor.Preview
var _ui_box: Control
var _info: Label
var _timer_lbl: Label
var _needle: float = 0.0
var _marks: Array = []
var _hits: Array = []
var _sew_t: float = 0.0
var _sew_canvas: Control


func _init() -> void:
	super()
	win_title = "Ateliê da Rosa: costura"
	game_id = "costura"
	skill = "memória de trabalho e precisão"
	how_to = "Três clientes. Cada um mostra a roupa que quer por poucos segundos: memorize o modelo e a cor da parte " \
		+ "de cima e de baixo (o último também quer uma capa). Depois monte no manequim e costure: aperte ESPAÇO " \
		+ "(ou clique) quando a agulha passar em cada ponto marcado. Nota = memória + costura."
	win_size = Vector2(560, 320)


func _start_game() -> void:
	_round = 0
	_scores = []
	_next_client()


func _next_client() -> void:
	for c in _stage.get_children():
		c.queue_free()
	_want = {"top": TOPS[randi() % TOPS.size()], "top_c": COLORS[randi() % COLORS.size()],
		"bottom": BOTTOMS[randi() % BOTTOMS.size()], "bottom_c": COLORS[randi() % COLORS.size()]}
	if _round == 2:
		_want["cape"] = CAPES[randi() % CAPES.size()]
	_have = {"top": TOPS[0], "top_c": "white", "bottom": BOTTOMS[0], "bottom_c": "white", "cape": "" if _round < 2 else "white"}
	_phase = "show"
	_t = SHOW_TIME[_round]
	var head := UI.label("Cliente %d de 3" % (_round + 1), UI.C_ORANGE_L)
	head.position = Vector2(8, 2)
	_stage.add_child(head)
	_timer_lbl = UI.label("", UI.C_GOLD)
	_timer_lbl.position = Vector2(420, 2)
	_stage.add_child(_timer_lbl)
	_info = UI.label("Memorize a roupa!", UI.C_TEXT, 2)
	_info.position = Vector2(8, 18)
	_stage.add_child(_info)
	_client = AppearanceEditor.Preview.new()
	_client.custom_minimum_size = Vector2(120, 150)
	_client.size = Vector2(120, 150)
	_client.position = Vector2(40, 60)
	_client.px = 2.0
	_client.set_look(_look_of(_want, false))
	_stage.add_child(_client)
	var note := UI.wrap_label(_describe(_want), UI.C_DIM, 300)
	note.position = Vector2(200, 80)
	note.name = "Nota"
	_stage.add_child(note)


func _look_of(d: Dictionary, female_body: bool) -> Dictionary:
	var lk := LpcW.default_look("female" if female_body or d.get("bottom", "") == "saia" else "male")
	var eq: Dictionary = lk["equip"]
	eq["torso"] = str(d["top"])
	eq["pernas"] = str(d["bottom"])
	lk["equip"] = eq
	var cols: Dictionary = lk.get("colors", {})
	cols[str(d["top"])] = str(d["top_c"])
	cols[str(d["bottom"])] = str(d["bottom_c"])
	lk["colors"] = cols
	if str(d.get("cape", "")) != "":
		lk["extras"] = [["npc_cape_solid", str(d["cape"])]]
	return lk


func _describe(d: Dictionary) -> String:
	var s := "%s %s  +  %s %s" % [_pname(d["top"]), _cname(d["top_c"]), _pname(d["bottom"]), _cname(d["bottom_c"])]
	if str(d.get("cape", "")) != "":
		s += "  +  capa %s" % _cname(d["cape"])
	return s


func _pname(id: String) -> String:
	return str(LpcW.part(id).get("name", id))


func _cname(c: String) -> String:
	return {"red": "vermelha", "blue": "azul", "green": "verde", "yellow": "amarela", "purple": "roxa", "white": "branca",
		"black": "preta", "orange": "laranja"}.get(c, c)


func _tick(delta: float) -> void:
	match _phase:
		"show":
			_t -= delta
			_timer_lbl.text = "%.1f s" % maxf(_t, 0.0)
			if _t <= 0.0:
				_start_build()
		"sew":
			_sew_t += delta
			_needle = _sew_t * (0.11 + 0.025 * _round)
			if _sew_canvas != null:
				_sew_canvas.queue_redraw()
			if _needle >= 1.05:
				_judge()


# ================================================================== Montagem no manequim
func _start_build() -> void:
	_phase = "build"
	_client.visible = false
	var n := _stage.get_node_or_null("Nota")
	if n != null:
		n.queue_free()
	_timer_lbl.text = ""
	_info.text = "Monte a roupa do cliente no manequim:"
	_mannequin = AppearanceEditor.Preview.new()
	_mannequin.custom_minimum_size = Vector2(120, 150)
	_mannequin.size = Vector2(120, 150)
	_mannequin.position = Vector2(20, 60)
	_mannequin.px = 2.0
	_stage.add_child(_mannequin)
	_ui_box = UI.vbox(3)
	_ui_box.position = Vector2(160, 44)
	_stage.add_child(_ui_box)
	_row_parts("Parte de cima", "top", TOPS)
	_row_colors("Cor", "top_c", COLORS)
	_row_parts("Parte de baixo", "bottom", BOTTOMS)
	_row_colors("Cor", "bottom_c", COLORS)
	if _want.has("cape"):
		_row_colors("Capa", "cape", CAPES)
	var go := UI.button("Costurar!", func() -> void: _start_sew(), 90)
	_ui_box.add_child(go)
	_refresh_mannequin()


func _row_parts(title: String, key: String, opts: Array) -> void:
	var h := UI.hbox(2)
	h.add_child(UI.label(title, UI.C_TEXT))
	for id in opts:
		var b := UI.button(str(SHORT.get(id, _pname(id))), func() -> void:
			_have[key] = id
			Audio.ui_click()
			_refresh_mannequin(), 0)
		b.add_theme_font_size_override("font_size", 12)
		b.tooltip_text = _pname(id)
		b.set_meta("pick", [key, id])
		h.add_child(b)
	_ui_box.add_child(h)


func _row_colors(title: String, key: String, opts: Array) -> void:
	var h := UI.hbox(2)
	h.add_child(UI.label(title, UI.C_DIM))
	for c in opts:
		var b := Button.new()
		b.custom_minimum_size = Vector2(18, 14)
		var sb := StyleBoxFlat.new()
		sb.bg_color = LpcW.swatch("cloth", c)
		sb.border_color = UI.C_LINE
		sb.set_border_width_all(1)
		b.add_theme_stylebox_override("normal", sb)
		var sb2 := sb.duplicate() as StyleBoxFlat
		sb2.border_color = UI.C_GOLD
		sb2.set_border_width_all(2)
		b.add_theme_stylebox_override("hover", sb2)
		b.add_theme_stylebox_override("pressed", sb2)
		b.tooltip_text = _cname(c)
		b.pressed.connect(func() -> void:
			_have[key] = c
			Audio.ui_click()
			_refresh_mannequin())
		b.set_meta("pick", [key, c])
		h.add_child(b)
	_ui_box.add_child(h)


func _refresh_mannequin() -> void:
	if _mannequin != null:
		_mannequin.set_look(_look_of(_have, false))
	# destaca o que está escolhido em cada linha
	if _ui_box != null and is_instance_valid(_ui_box):
		for row in _ui_box.get_children():
			for b in row.get_children():
				if b is Button and b.has_meta("pick"):
					var pk: Array = b.get_meta("pick")
					var on := str(_have.get(str(pk[0]), "")) == str(pk[1])
					b.modulate = Color(1.25, 1.15, 0.7) if on else Color(0.8, 0.8, 0.8)


# ================================================================== Costura
func _start_sew() -> void:
	_phase = "sew"
	if _ui_box != null:
		_ui_box.queue_free()
	_info.text = "Costure! ESPAÇO (ou clique) em cada ponto."
	_marks = []
	_hits = []
	var n: int = STITCHES[_round]
	for i in n:
		_marks.append(0.08 + 0.84 * float(i) / float(maxi(n - 1, 1)) + randf_range(-0.02, 0.02))
		_hits.append(-1.0)
	_sew_t = -0.6
	_needle = 0.0
	_sew_canvas = SewCanvas.new()
	_sew_canvas.owner_win = self
	_sew_canvas.position = Vector2(160, 110)
	_sew_canvas.size = Vector2(360, 60)
	_stage.add_child(_sew_canvas)


func _unhandled_key_input(ev: InputEvent) -> void:
	if _phase == "sew" and ev is InputEventKey and ev.pressed and not ev.echo and (ev.keycode == KEY_SPACE or ev.is_action("interact")):
		get_viewport().set_input_as_handled()
		_stitch()
		return
	super(ev)


func _unhandled_input(ev: InputEvent) -> void:
	if _phase == "sew" and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_stitch()


func _stitch() -> void:
	var best := -1
	var best_d := INF
	for i in _marks.size():
		if _hits[i] >= 0.0:
			continue
		var d := absf(_needle - float(_marks[i]))
		if d < best_d:
			best_d = d
			best = i
	if best < 0 or best_d > 0.06:
		Audio.sfx("ui_error", -10.0)
		return
	_hits[best] = clampf(1.0 - best_d / 0.06, 0.0, 1.0)
	Audio.sfx2("ui_pack4", -8.0, 0.1)


func _judge() -> void:
	_phase = "judge"
	var mem := 0.0
	var keys := ["top", "top_c", "bottom", "bottom_c"]
	if _want.has("cape"):
		keys.append("cape")
	for k in keys:
		if str(_have.get(k, "")) == str(_want.get(k, "")):
			mem += 1.0
	mem /= float(keys.size())
	var sew := 0.0
	for h in _hits:
		sew += maxf(float(h), 0.0)
	sew /= float(maxi(_hits.size(), 1))
	var sc := mem * 0.6 + sew * 0.4
	_scores.append(sc)
	_info.text = "Memória %d%%  Costura %d%%" % [int(mem * 100.0), int(sew * 100.0)]
	_client.visible = true
	_client.position = Vector2(400, 150)
	_client.size = Vector2(90, 120)
	_client.px = 1.5
	if _sew_canvas != null:
		_sew_canvas.queue_free()
		_sew_canvas = null
	var verdict := UI.label("O cliente: \"%s\"" % ("Perfeito, é exatamente isso!" if sc >= 0.9 else ("Ficou bom!" if sc >= 0.6 else "Hm... não era bem isso.")), UI.C_GOLD if sc >= 0.6 else UI.C_BAD)
	verdict.position = Vector2(160, 70)
	_stage.add_child(verdict)
	var want := UI.wrap_label("Pedido: " + _describe(_want), UI.C_DIM, 230)
	want.position = Vector2(160, 92)
	_stage.add_child(want)
	Audio.jingle("success" if sc >= 0.6 else "defeat", -6.0)
	await get_tree().create_timer(2.6, true, false, true).timeout
	if phase != "play":
		return
	_round += 1
	if _round >= 3:
		var total := 0.0
		for s in _scores:
			total += float(s)
		_finish(total / 3.0)
	else:
		_next_client()


class SewCanvas extends Control:
	var owner_win: Node

	func _draw() -> void:
		var w := owner_win
		var y := 30.0
		draw_rect(Rect2(0, 10, size.x, 40), Color(0.85, 0.78, 0.62, 0.95))
		draw_rect(Rect2(0, 10, size.x, 40), UI.C_LINE, false, 1.0)
		for x in range(0, int(size.x), 8):
			draw_line(Vector2(x, y), Vector2(x + 4, y), Color(0.45, 0.35, 0.25, 0.6), 1.0)
		for i in w._marks.size():
			var mx: float = float(w._marks[i]) * size.x
			var h: float = float(w._hits[i])
			var col := Color(0.8, 0.2, 0.2) if h < 0.0 else (UI.C_GOOD if h >= 0.6 else UI.C_GOLD)
			draw_circle(Vector2(mx, y), 4.0, col)
			if h >= 0.0:
				draw_line(Vector2(mx - 4, y - 4), Vector2(mx + 4, y + 4), Color(0.15, 0.1, 0.1), 2.0)
				draw_line(Vector2(mx - 4, y + 4), Vector2(mx + 4, y - 4), Color(0.15, 0.1, 0.1), 2.0)
		var nx: float = clampf(float(w._needle), 0.0, 1.0) * size.x
		draw_line(Vector2(nx, 4), Vector2(nx, y + 2), Color(0.85, 0.88, 0.95), 2.0)
		draw_circle(Vector2(nx, 6), 2.0, Color(0.85, 0.88, 0.95))
