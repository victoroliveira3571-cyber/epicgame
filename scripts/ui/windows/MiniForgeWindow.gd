extends MiniGameWindow

## Forja (mini-jogo v2, arte: Blacksmith assets, Anvil 2, Sword and hammer character). Três etapas por peça:
##  1) Aquecer: segure ESPAÇO no fole e mantenha o calor da barra na faixa laranja;
##  2) Martelar: 8 golpes no ponto certo (a faixa encolhe quando o metal esfria);
##  3) Resfriar: mergulhe a peça na água quando o cursor passar pela faixa azul.
## Treina reação, ritmo e controle fino. Nota final = 30% calor + 55% martelo + 15% banho.

const HEAT_TIME := 8.0
const STRIKES := 8
const BAND_LO := 0.60
const BAND_HI := 0.80
const BAR_W := 300.0
const K := 3.0

var _cv: MgArt.Canvas
var _stage_id: String = "heat"          # heat | hammer | quench | wait
var _heat: float = 0.15
var _heat_t: float = 0.0
var _heat_acc: float = 0.0
var _s1: float = 0.0
var _temp: float = 1.0
var _strike: int = 0
var _scores: Array = []
var _cursor: float = 0.0
var _dir: float = 1.0
var _zone_c: float = 0.5
var _zone_w: float = 70.0
var _s2: float = 0.0
var _s3: float = 0.0
var _msg: String = ""
var _msg_t: float = 0.0
var _swing_t: float = 0.0
var _spark_t: float = 0.0
var _dip_t: float = 0.0
var _wait_t: float = 0.0
var _wait_next: String = ""
var _pumping: bool = false


func _init() -> void:
	super()
	win_title = "Forja: forjar uma peça"
	game_id = "forja"
	skill = "reação, ritmo e controle fino"
	how_to = "Forje uma peça em três etapas. 1) Segure ESPAÇO para soprar o fole e mantenha o calor na faixa laranja. " \
		+ "2) Aperte ESPAÇO quando o cursor cruzar a faixa dourada: 8 golpes, e o metal esfria. " \
		+ "3) Aperte ESPAÇO de novo para mergulhar a peça quando o cursor passar pela faixa azul."


func _start_game() -> void:
	_stage_id = "heat"
	_heat = 0.15
	_heat_t = 0.0
	_heat_acc = 0.0
	_scores = []
	_strike = 0
	_msg = ""
	_cv = MgArt.Canvas.new()
	_cv.size = Vector2(520, 250)
	_cv.painter = Callable(self, "_paint")
	_cv.clicked.connect(func(_id: String) -> void: _press())
	_cv.hit_area(Rect2(Vector2.ZERO, _cv.size), "all")
	_stage.add_child(_cv)


func _unhandled_key_input(ev: InputEvent) -> void:
	if phase == "play" and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		_press()


func _press() -> void:
	match _stage_id:
		"hammer":
			_hit_hammer()
		"quench":
			_hit_quench()


func _tick(delta: float) -> void:
	_swing_t = maxf(0.0, _swing_t - delta)
	_spark_t = maxf(0.0, _spark_t - delta)
	_msg_t = maxf(0.0, _msg_t - delta)
	_dip_t = maxf(0.0, _dip_t - delta)
	match _stage_id:
		"heat":
			_pumping = Input.is_key_pressed(KEY_SPACE) or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _cv.get_global_rect().has_point(get_global_mouse_position()))
			_heat += ((0.52 if _pumping else -0.2) + randf_range(-0.04, 0.04)) * delta
			_heat = clampf(_heat, 0.0, 1.0)
			_heat_t += delta
			_heat_acc += clampf(1.0 - absf(_heat - (BAND_LO + BAND_HI) / 2.0) / 0.35, 0.0, 1.0) * delta
			if _heat_t >= HEAT_TIME:
				_s1 = _heat_acc / HEAT_TIME
				_temp = 0.55 + 0.45 * _s1
				_go("hammer", 0.6)
		"hammer":
			_cursor += _dir * lerpf(0.85, 1.8, float(_strike) / float(STRIKES - 1)) * delta
			if _cursor >= 1.0 or _cursor <= 0.0:
				_cursor = clampf(_cursor, 0.0, 1.0)
				_dir = -_dir
			_temp = maxf(0.2, _temp - 0.03 * delta)
		"quench":
			_cursor += _dir * 1.7 * delta
			if _cursor >= 1.0 or _cursor <= 0.0:
				_cursor = clampf(_cursor, 0.0, 1.0)
				_dir = -_dir
		"wait":
			_wait_t -= delta
			if _wait_t <= 0.0:
				_begin_stage(_wait_next)
	if _cv != null:
		_cv.queue_redraw()


func _go(next: String, pause: float) -> void:
	_stage_id = "wait"
	_wait_next = next
	_wait_t = pause


func _begin_stage(id: String) -> void:
	_stage_id = id
	if id == "hammer":
		_strike = 0
		_scores = []
		_new_strike()
	elif id == "quench":
		_zone_c = randf_range(0.25, 0.75)
		_zone_w = 56.0
		_cursor = 0.0
		_dir = 1.0


func _new_strike() -> void:
	_zone_w = lerpf(80.0, 34.0, float(_strike) / float(STRIKES - 1)) * (0.6 + 0.4 * _temp)
	_zone_c = randf_range(0.2, 0.8)
	_cursor = 0.0 if randf() < 0.5 else 1.0
	_dir = 1.0 if _cursor == 0.0 else -1.0


func _accuracy() -> float:
	var dist := absf(_cursor - _zone_c) * BAR_W
	return clampf(1.0 - maxf(0.0, dist - 4.0) / (_zone_w / 2.0 + 12.0), 0.0, 1.0)


func _hit_hammer() -> void:
	if _swing_t > 0.05:
		return
	var acc := _accuracy()
	_scores.append(acc)
	_swing_t = 0.3
	_spark_t = 0.4
	_msg = "PERFEITO!" if acc >= 0.92 else ("Bom!" if acc >= 0.6 else ("Fraco..." if acc > 0.0 else "Errou!"))
	_msg_t = 0.7
	Audio.sfx2("bigorna1" if acc >= 0.5 else "bigorna2", -6.0 if acc >= 0.5 else -12.0, 0.05)
	_temp = maxf(0.2, _temp - 0.05)
	_strike += 1
	if _strike >= STRIKES:
		var total := 0.0
		for a in _scores:
			total += float(a)
		_s2 = total / float(STRIKES)
		_go("quench", 0.8)
		return
	_new_strike()


func _hit_quench() -> void:
	_s3 = _accuracy()
	_dip_t = 0.8
	_msg = "No ponto!" if _s3 >= 0.8 else ("Quase..." if _s3 > 0.3 else "Rachou!")
	_msg_t = 1.0
	Audio.sfx2("servir_agua", -4.0)
	_stage_id = "done"
	var final_score := 0.3 * _s1 + 0.55 * _s2 + 0.15 * _s3
	await get_tree().create_timer(1.0).timeout
	if phase == "play":
		_finish(final_score)


# ---------------------------------------------------------------- desenho
func _paint(c: MgArt.Canvas) -> void:
	var t_ms := Time.get_ticks_msec()
	# parede e chão da oficina
	c.draw_rect(Rect2(0, 0, 520, 250), Color("2a2118"))
	c.draw_rect(Rect2(0, 0, 520, 20), Color("3a2c1e"))
	c.draw_rect(Rect2(0, 214, 520, 36), Color("3d2f22"))
	c.draw_rect(Rect2(0, 214, 520, 2), Color("1a120c"))
	# forno (Pixel Crawler: animado)
	var glow := 0.5 + 0.5 * sin(t_ms * 0.008)
	MgArt.blit(c, MgArt.sheet("pc_furnace_stone3.png", int(t_ms / 220) % 4, 2, 48, 64), Vector2(24, 84), 2.0)
	var fire := _heat if _stage_id in ["heat", "wait"] and _s1 == 0.0 else 0.0
	if fire > 0.05:
		c.draw_rect(Rect2(58, 160, 28, 38), Color(1.0, 0.35 + 0.4 * fire, 0.05, 0.18 + 0.5 * fire))
		c.draw_circle(Vector2(72, 180), 26.0 + 6.0 * glow * fire, Color(1.0, 0.5, 0.15, 0.06 + 0.16 * fire))
	# medidor de calor
	if _stage_id == "heat" or _stage_id == "wait":
		var gx := 150.0
		c.draw_rect(Rect2(gx, 60, 18, 150), Color("1d1a18"))
		c.draw_rect(Rect2(gx, 60 + 150 * (1.0 - BAND_HI), 18, 150 * (BAND_HI - BAND_LO)), Color(0.95, 0.55, 0.15, 0.55))
		var hh := 150.0 * _heat
		var hc := Color(0.9, 0.3, 0.1) if _heat < BAND_LO else (Color(1.0, 0.8, 0.3) if _heat <= BAND_HI else Color(1.0, 1.0, 0.9))
		c.draw_rect(Rect2(gx + 2, 60 + 150 - hh, 14, hh), hc)
		c.draw_rect(Rect2(gx, 60, 18, 150), UI.C_LINE, false, 1.0)
		c.text("Calor", Vector2(gx - 6, 54), UI.C_DIM, 12)
		if _stage_id == "heat":
			var left := maxf(0.0, HEAT_TIME - _heat_t)
			c.text("%d s" % int(ceil(left)), Vector2(gx + 24, 80), UI.C_TEXT, 12)
			# fole: encolhe quando bombeia
			var squeeze := 8.0 if _pumping else 0.0
			var top := 150.0 + squeeze
			c.draw_colored_polygon(PackedVector2Array([Vector2(196, top), Vector2(224, top), Vector2(230, 184), Vector2(190, 184)]), Color("8a5a2a"))
			c.draw_polyline(PackedVector2Array([Vector2(196, top), Vector2(224, top), Vector2(230, 184), Vector2(190, 184), Vector2(196, top)]), UI.C_LINE, 1.0)
			c.draw_line(Vector2(200, top + 6.0), Vector2(220, top + 6.0), Color("6a4220"), 2.0)
			c.draw_line(Vector2(198, top + 14.0), Vector2(222, top + 14.0), Color("6a4220"), 2.0)
			c.text("Fole", Vector2(198, 146), UI.C_DIM, 12)
	# bigorna animada (o ferreiro bate) e a peça em brasa
	var swing_f := 0
	if _swing_t > 0.0:
		swing_f = clampi(int((1.0 - _swing_t / 0.3) * 14.0), 0, 14)
	MgArt.blit(c, MgArt.sheet("pc_anvil1.png", swing_f, 8, 64, 80), Vector2(312, 52), 2.0)
	var hot := _heat if _stage_id in ["heat", "wait"] and _s1 == 0.0 else _temp
	var ingot_pos := Vector2(206, 56)
	MgArt.blit(c, MgArt.cell("forge_demo.png", 10, 8), ingot_pos, K)
	if _stage_id != "done" and _stage_id != "quench":
		MgArt.blit(c, MgArt.cell("forge_demo.png", 8, 8), ingot_pos, K, Color(1, 1, 1, clampf(hot * 1.2 - 0.1, 0.0, 1.0)))
	c.text("Peça", Vector2(ingot_pos.x + 6.0, ingot_pos.y + 62.0), UI.C_DIM, 12, false)
	if _spark_t > 0.0:
		for i in 9:
			var a: float = float(i) / 9.0 * TAU + _spark_t * 5.0
			var r: float = (0.4 - _spark_t) * 90.0
			c.draw_circle(Vector2(358, 110) + Vector2(cos(a), sin(a)) * r, 2.0, Color(1.0, 0.85, 0.3, _spark_t * 2.5))
	# balde de água
	MgArt.blit(c, MgArt.cell("forge_demo.png", 4, 8), Vector2(452, 164), K)
	if _dip_t > 0.0:
		for i in 6:
			c.draw_circle(Vector2(474 + sin(t_ms * 0.01 + i) * 8.0, 150 - float(i) * 10.0 * (1.0 - _dip_t)), 3.0, Color(0.8, 0.9, 1.0, _dip_t))
	# barra de tempo (martelar e resfriar)
	if _stage_id == "hammer" or _stage_id == "quench":
		var bx := 110.0
		var by := 16.0
		c.draw_rect(Rect2(bx, by, BAR_W, 20), Color("1d1a18"))
		var zc := bx + _zone_c * BAR_W
		var zcol := Color(0.9, 0.7, 0.2, 0.85) if _stage_id == "hammer" else Color(0.4, 0.7, 1.0, 0.85)
		c.draw_rect(Rect2(zc - _zone_w / 2.0, by, _zone_w, 20), zcol)
		c.draw_rect(Rect2(zc - 4.0, by, 8.0, 20), Color(1.0, 1.0, 0.9, 0.95))
		c.draw_rect(Rect2(bx, by, BAR_W, 20), UI.C_LINE, false, 1.0)
		var cx := bx + _cursor * BAR_W
		c.draw_rect(Rect2(cx - 1.0, by - 4.0, 3.0, 28.0), UI.C_TEXT)
		c.draw_colored_polygon(PackedVector2Array([Vector2(cx, by + 24.0), Vector2(cx - 6.0, by + 34.0), Vector2(cx + 6.0, by + 34.0)]), UI.C_TEXT)
	# textos
	var title := ""
	var hint := ""
	match _stage_id:
		"heat":
			title = "1/3  Aquecer"
			hint = "Segure ESPAÇO: sopre o fole e mantenha o calor na faixa laranja."
		"hammer":
			title = "2/3  Martelar  (golpe %d de %d)" % [mini(_strike + 1, STRIKES), STRIKES]
			hint = "ESPAÇO quando o cursor cruzar a faixa dourada. O metal esfria: a faixa encolhe."
		"quench":
			title = "3/3  Resfriar"
			hint = "ESPAÇO para mergulhar quando o cursor cruzar a faixa azul."
		"wait":
			title = "Prepare-se..."
		"done":
			title = "Peça pronta!"
	c.text(title, Vector2(10, 14), UI.C_ORANGE_L, 12)
	c.text(hint, Vector2(10, 238), UI.C_DIM, 12)
	if _stage_id == "hammer" and _scores.size() > 0:
		var sum := 0.0
		for a in _scores:
			sum += float(a)
		c.text("Média: %d%%" % int(round(sum / float(_scores.size()) * 100.0)), Vector2(420, 14), UI.C_GOLD, 12)
	if _msg_t > 0.0:
		var col := UI.C_GOLD if _msg in ["PERFEITO!", "No ponto!"] else (UI.C_GOOD if _msg == "Bom!" else UI.C_BAD)
		c.text(_msg, Vector2(318, 84), col, 24)
