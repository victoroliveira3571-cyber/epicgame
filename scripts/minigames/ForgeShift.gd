class_name ForgeShift
extends WorkShift

## v3.7: turno na forja (top-down). Ritmo, tempo de reação e paciência.
## Caixote de barras -> FORNALHA (tirar com o calor na faixa laranja) -> BIGORNA (martelar no ritmo: ESPAÇO ou E
## quando a nota chega ao círculo; o metal esfria se demorar) -> TINA (temperar com o vapor na faixa) -> Brás.
## A peça sai com a média das três etapas. Arte: fornalha e bigorna animadas do Pixel Crawler, barris e caixotes
## do Ninja Adventure, barras do Ninja Adventure.

## Pedidos: nome, notas na bigorna (intervalos em batidas), pontos base, barra usada
const ORDERS := [
	{"name": "Ferradura", "beats": [1, 1, 1, 1, 2], "pts": 16.0, "bar": "items/resource/BarIron"},
	{"name": "Adaga", "beats": [1, 0.5, 0.5, 1, 1, 2], "pts": 20.0, "bar": "items/resource/BarIron"},
	{"name": "Espada", "beats": [1, 1, 0.5, 0.5, 1, 1, 0.5, 0.5, 2], "pts": 28.0, "bar": "items/resource/BarSilver"},
	{"name": "Elmo", "beats": [1, 0.5, 0.5, 0.5, 0.5, 1, 1, 1, 2], "pts": 30.0, "bar": "items/resource/BarSilver"},
	{"name": "Machado", "beats": [2, 1, 1, 0.5, 0.5, 1, 2], "pts": 24.0, "bar": "items/resource/BarGold"},
]
const HEAT_TIME := 6.0          # segundos até o calor máximo na fornalha
const HEAT_ZONE := Vector2(0.62, 0.86)
const COOL_TIME := 14.0         # a barra quente esfria nesse tempo fora do fogo
const BEAT := 0.55              # segundos por batida
const TARGET := 130.0

var _order: Dictionary = {}
var _furnace: Dictionary = {"state": "", "t": 0.0}    # "", heating, burnt
var _bar: Dictionary = {}        # barra em mãos/na bigorna: {heat_q, warm (0..1), hammer_q, quench_q, stage}
var _done: int = 0
var _perfect: int = 0
var _ruined: int = 0
var _furn_st: Station
var _anvil_st: Station
var _tub_st: Station
var _smith: NPC
var _board_lbl: Label
var _rhythm: Rhythm = null
var _quench: Dictionary = {}     # {t} enquanto o vapor oscila


func _init() -> void:
	duration = 150.0


func _bar_tex() -> Texture2D:
	return Pix.tex(str(_order.get("bar", "items/resource/BarIron")) + ".png")


# ================================================================== Sala
func _build_room() -> void:
	var w := room.cols * Interior.T
	# fornalha animada (Pixel Crawler)
	_anim("pc_furnace_iron3.png", 2, 48, 64, 4, 5.0, Vector2(60, 82))
	room.light(Vector2(60, 60), Color(1.0, 0.5, 0.2), 1.4, 1.0)
	_furn_st = _station(Vector2(60, 82), 24.0)
	_furn_st.icon_y = -40.0
	_furn_st.zone = HEAT_ZONE
	_furn_st.bar_col = Color(1.0, 0.45, 0.15)
	_furn_st.label_fn = func() -> String: return _furnace_label()
	_furn_st.use_fn = func() -> void: _use_furnace()
	# caixote de barras
	room.prop("i_crate", Vector2(118, 72))
	var crate := _station(Vector2(118, 72), 18.0)
	crate.item_tex = Pix.tex("items/resource/BarIron.png")
	crate.label_fn = func() -> String: return "Pegar uma barra" if _bar.is_empty() and _furnace["state"] == "" else ""
	crate.use_fn = func() -> void:
		if _bar.is_empty():
			_bar = {"stage": "fria", "heat_q": 0.0, "warm": 0.0, "hammer_q": 0.0, "quench_q": 0.0}
			set_carry("fria", _bar_tex())
	# bigorna (Pixel Crawler)
	var anv := Sprite2D.new()
	anv.texture = MgArt.tex("anvil32.png")
	anv.position = Vector2(176, 132)
	anv.offset = Vector2(0, -12)
	anv.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.world.add_child(anv)
	room.colliders.add_child(_rect_shape(Rect2(164, 122, 24, 10)))
	_anvil_st = _station(Vector2(176, 128), 24.0)
	_anvil_st.icon_y = -30.0
	_anvil_st.label_fn = func() -> String: return "Martelar a peça" if carry == "quente" else ""
	_anvil_st.use_fn = func() -> void: _start_hammer()
	# tina de água para temperar
	room.prop("i_wash", Vector2(260, 128))
	_tub_st = _station(Vector2(260, 128), 22.0)
	_tub_st.zone = Vector2(0.45, 0.62)
	_tub_st.bar_col = Color(0.6, 0.85, 1.0)
	_tub_st.label_fn = func() -> String: return _tub_label()
	_tub_st.use_fn = func() -> void: _use_tub()
	# Brás e o quadro de pedidos
	_smith = NPC.create(room.world, "Villager", Vector2(w - 50, 92), "cutscene", "ferreiro")
	_smith.play_anim("idle_left")
	var deliver := _station(Vector2(w - 50, 92), 24.0)
	deliver.label_fn = func() -> String: return ("Entregar: %s" % _order.get("name", "")) if carry == "pronta" else ""
	deliver.use_fn = func() -> void: _deliver()
	room.prop("i_board", Vector2(w - 90, 50), false)
	_board_lbl = Label.new()
	_board_lbl.add_theme_font_override("font", Pix.font(1))
	_board_lbl.add_theme_font_size_override("font_size", 12)
	_board_lbl.add_theme_color_override("font_color", Color("ffe8b0"))
	_board_lbl.add_theme_color_override("font_outline_color", Color("2a1810"))
	_board_lbl.add_theme_constant_override("outline_size", 3)
	_board_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_lbl.size = Vector2(160, 14)
	_board_lbl.scale = Vector2(0.75, 0.75)
	_board_lbl.position = Vector2(w - 150, 14)
	_board_lbl.z_index = 60
	room.world.add_child(_board_lbl)
	room.prop("i_barrel", Vector2(24, 150))
	room.prop("i_barrel2", Vector2(w - 24, 170))
	room.light(Vector2(176, 110), Color(1.0, 0.75, 0.5), 2.0, 0.3)


func _station(pos: Vector2, radius: float) -> Station:
	var st := Station.new(radius)
	st.position = pos
	room.world.add_child(st)
	return st


func _anim(sheet: String, cols: int, fw: int, fh: int, n: int, fps: float, foot: Vector2) -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("loop")
	sf.set_animation_speed("loop", fps)
	for i in n:
		sf.add_frame("loop", MgArt.sheet(sheet, i, cols, fw, fh))
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.position = foot
	spr.offset = Vector2(0, -fh / 2.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room.world.add_child(spr)
	spr.play("loop")
	room.colliders.add_child(_rect_shape(Rect2(foot.x - fw / 2.0 + 6, foot.y - 14, fw - 12, 14)))


func _rect_shape(r: Rect2) -> CollisionShape2D:
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	c.shape = s
	c.position = r.position + r.size / 2.0
	return c


# ================================================================== Pedidos
func _on_start() -> void:
	_next_order()


func _next_order() -> void:
	var pool := [0, 1, 2]
	if _done >= 2:
		pool.append_array([3, 4])
	_order = ORDERS[pool[randi() % pool.size()]]
	_board_lbl.text = "Pedido: %s" % _order["name"]
	_say("Novo pedido: %s" % _order["name"], UI.C_ORANGE_L, 1.4)


# ================================================================== Fornalha
func _furnace_label() -> String:
	match str(_furnace["state"]):
		"":
			return "Aquecer a barra" if carry in ["fria", "quente"] else ""
		"heating":
			return "Tirar do fogo" if carry == "" else ""
		"burnt":
			return "Tirar a barra derretida" if carry == "" else ""
	return ""


func _use_furnace() -> void:
	match str(_furnace["state"]):
		"":
			if carry in ["fria", "quente"]:
				_furnace = {"state": "heating", "t": float(_bar.get("warm", 0.0)) * HEAT_TIME * 0.7}
				_furn_st.item_tex = _bar_tex()
				_furn_st.progress = 0.0
				set_carry("")
				Audio.sfx2("whoosh", -8.0, 0.1)
		"heating":
			if carry == "":
				var h := float(_furnace["t"]) / HEAT_TIME
				var q := 1.0 if h >= HEAT_ZONE.x and h <= HEAT_ZONE.y else clampf(1.0 - absf(h - (HEAT_ZONE.x + HEAT_ZONE.y) / 2.0) * 3.0, 0.1, 0.8)
				_bar["heat_q"] = maxf(float(_bar.get("heat_q", 0.0)), q) if _bar.get("stage", "") == "quente" else q
				_bar["warm"] = 1.0
				_bar["stage"] = "quente"
				_furnace = {"state": "", "t": 0.0}
				_furn_st.item_tex = null
				_furn_st.progress = -1.0
				set_carry("quente", _bar_tex())
				_say("No ponto!" if q >= 1.0 else ("Frio demais..." if h < HEAT_ZONE.x else "Quente demais..."), UI.C_GOOD if q >= 1.0 else UI.C_GOLD, 1.0)
		"burnt":
			if carry == "":
				_furnace = {"state": "", "t": 0.0}
				_furn_st.item_tex = null
				_furn_st.smoking = false
				_furn_st.progress = -1.0
				_bar = {}
				_ruined += 1
				break_combo()


# ================================================================== Bigorna (ritmo)
func _start_hammer() -> void:
	if carry != "quente" or _rhythm != null:
		return
	set_carry("")
	_anvil_st.item_tex = _bar_tex()
	Game.input_locked = true
	HUD.set_bottom_hidden(true)
	_rhythm = Rhythm.new()
	_rhythm.beats = _order["beats"]
	_rhythm.beat_s = BEAT
	_rhythm.warm_start = float(_bar.get("warm", 1.0))
	_rhythm.on_hit = func(grade: String) -> void: _on_hammer(grade)
	_ui.add_child(_rhythm)
	await _rhythm.done
	_bar["hammer_q"] = _rhythm.result()
	_bar["warm"] = _rhythm.warm_end
	_rhythm.queue_free()
	_rhythm = null
	HUD.set_bottom_hidden(false)
	Game.input_locked = false
	_anvil_st.item_tex = null
	if float(_bar["warm"]) <= 0.05:
		_bar["stage"] = "fria"
		set_carry("fria", _bar_tex())
		_say("O metal esfriou no meio! Volte à fornalha.", UI.C_BAD, 1.4)
		return
	_bar["stage"] = "batida"
	set_carry("batida", _bar_tex())
	_say("Peça moldada (%d%%). Agora tempere na tina." % int(float(_bar["hammer_q"]) * 100.0), UI.C_GOOD, 1.4)


func _on_hammer(grade: String) -> void:
	var p := room.player
	if p != null and p.sprite != null:
		p.sprite.play("slash_right", true)
	if grade != "miss":
		Audio.sfx2("bigorna1" if randf() < 0.5 else "bigorna2", -6.0, 0.06)
		Fx.burst(room.world, _anvil_st.global_position + Vector2(0, -28), Color(1.0, 0.75, 0.3), 8 if grade == "perfect" else 4, 40.0, 0.3)
		Fx.shake_camera(p.camera, 1.2 if grade == "perfect" else 0.6, 0.08)
	else:
		Audio.sfx("hit", -14.0, 0.2)


# ================================================================== Tina
func _tub_label() -> String:
	if not _quench.is_empty():
		return "Tirar da água!"
	return "Temperar na água" if carry == "batida" else ""


func _use_tub() -> void:
	if _quench.is_empty():
		if carry != "batida":
			return
		set_carry("")
		_tub_st.item_tex = _bar_tex()
		_quench = {"t": 0.0}
		Audio.sfx2("servir_agua", -6.0, 0.05)
		return
	var v := _tub_st.progress
	var q := 1.0 if v >= _tub_st.zone.x and v <= _tub_st.zone.y else clampf(1.0 - absf(v - (_tub_st.zone.x + _tub_st.zone.y) / 2.0) * 2.5, 0.1, 0.8)
	_bar["quench_q"] = q
	_bar["stage"] = "pronta"
	_quench = {}
	_tub_st.item_tex = null
	_tub_st.progress = -1.0
	_tub_st.smoking = false
	set_carry("pronta", _bar_tex())
	_say("Têmpera perfeita!" if q >= 1.0 else "Têmpera razoável.", UI.C_GOOD if q >= 1.0 else UI.C_GOLD, 1.0)


# ================================================================== Entrega
func _deliver() -> void:
	if carry != "pronta":
		return
	var q := (float(_bar["heat_q"]) + float(_bar["hammer_q"]) * 2.0 + float(_bar["quench_q"])) / 4.0
	var got := add_points(float(_order["pts"]) * (0.4 + 0.8 * q))
	_done += 1
	if q >= 0.95:
		_perfect += 1
	set_carry("")
	_bar = {}
	_smith.show_emote(22 if q >= 0.7 else 8)
	Audio.novo("ferraria_criar", -6.0)
	_say("+%d  %s (%d%%)" % [int(got), "Obra-prima!" if q >= 0.95 else ("Boa peça." if q >= 0.7 else "Serve..."), int(q * 100.0)], UI.C_GOLD, 1.4)
	_next_order()


# ================================================================== Tempo
func _tick(delta: float) -> void:
	if str(_furnace["state"]) == "heating":
		_furnace["t"] = float(_furnace["t"]) + delta
		var h := float(_furnace["t"]) / HEAT_TIME
		_furn_st.progress = h
		_furn_st.ready_glow = h >= HEAT_ZONE.x and h <= HEAT_ZONE.y
		if h >= 1.25:
			_furnace["state"] = "burnt"
			_furn_st.smoking = true
			_furn_st.ready_glow = false
			_furn_st.progress = -1.0
			_say("A barra derreteu! Tire e pegue outra.", UI.C_BAD, 1.4)
	if carry in ["quente", "batida"] and _rhythm == null:
		_bar["warm"] = maxf(0.0, float(_bar.get("warm", 1.0)) - delta / COOL_TIME)
		_carry_spr.modulate = Color(1.0, 0.5 + 0.5 * (1.0 - float(_bar["warm"])), 0.5 + 0.5 * (1.0 - float(_bar["warm"])))
		if carry == "quente" and float(_bar["warm"]) <= 0.0:
			_bar["stage"] = "fria"
			set_carry("fria", _bar_tex())
			_say("A barra esfriou. Volte à fornalha.", UI.C_DIM, 1.2)
	else:
		_carry_spr.modulate = Color.WHITE
	if not _quench.is_empty():
		_quench["t"] = float(_quench["t"]) + delta
		_tub_st.progress = 0.5 + 0.5 * sin(float(_quench["t"]) * 2.6 - PI / 2.0)
		_tub_st.smoking = true


func _status() -> String:
	return "peças %d" % _done


func _score() -> float:
	return points / TARGET


func _summary() -> Array:
	return ["Peças entregues: %d (obras-primas: %d)" % [_done, _perfect], "Barras perdidas no fogo: %d" % _ruined,
		"Pontos: %d (meta %d)" % [int(points), int(TARGET)]]


# ================================================================== Trilha de ritmo
## Notas descem por uma trilha até o círculo; ESPAÇO ou E no tempo certo. O metal esfria durante a martelada.
class Rhythm extends Control:
	signal done
	var beats: Array = []
	var beat_s: float = 0.55
	var warm_start: float = 1.0
	var warm_end: float = 1.0
	var on_hit: Callable
	var _notes: Array = []       # tempo de cada nota (s)
	var _graded: Array = []      # "" | perfect | good | miss
	var _t: float = -1.2
	var _scores: Array = []
	var _flash: String = ""
	var _flash_t: float = 0.0
	const SPEED := 120.0         # px por segundo (em unidades da interface)
	const HIT_X := 150.0
	const PERFECT := 0.08
	const GOOD := 0.17

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = UI.SIZE
		var acc := 0.0
		for b in beats:
			_notes.append(acc)
			_graded.append("")
			acc += float(b) * beat_s
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(delta: float) -> void:
		_t += delta
		warm_end = clampf(warm_start - maxf(_t, 0.0) / 9.0, 0.0, 1.0)
		for i in _notes.size():
			if _graded[i] == "" and _t - float(_notes[i]) > GOOD:
				_graded[i] = "miss"
				_scores.append(0.0)
				_show("Errou", on_hit, "miss")
		if _flash_t > 0.0:
			_flash_t -= delta
		queue_redraw()
		if _graded.count("") == 0 and _t > float(_notes[-1]) + 0.4:
			done.emit()

	func _unhandled_input(ev: InputEvent) -> void:
		if not (ev is InputEventKey) or not ev.pressed or ev.echo:
			return
		if ev.keycode != KEY_SPACE and not ev.is_action("interact"):
			return
		get_viewport().set_input_as_handled()
		var best := -1
		var best_d := INF
		for i in _notes.size():
			if _graded[i] != "":
				continue
			var dt := absf(_t - float(_notes[i]))
			if dt < best_d:
				best_d = dt
				best = i
		if best < 0 or best_d > GOOD * 1.6:
			return
		var g := "perfect" if best_d <= PERFECT else ("good" if best_d <= GOOD else "miss")
		_graded[best] = g
		var warm_k := 0.6 + 0.4 * warm_end
		_scores.append((1.0 if g == "perfect" else (0.6 if g == "good" else 0.0)) * warm_k)
		_show({"perfect": "Perfeito!", "good": "Bom", "miss": "Errou"}[g], on_hit, g)

	func _show(txt: String, cb: Callable, g: String) -> void:
		_flash = txt
		_flash_t = 0.5
		if cb.is_valid():
			cb.call(g)

	func result() -> float:
		if _scores.is_empty():
			return 0.0
		var s := 0.0
		for v in _scores:
			s += float(v)
		return s / float(_notes.size())

	func _draw() -> void:
		var y := 300.0
		var lane := Rect2(60, y - 14, 520, 28)
		draw_rect(lane, Color(0.08, 0.06, 0.05, 0.85))
		draw_rect(lane, UI.C_ORANGE, false, 1.0)
		# metal esfriando: barra de calor
		var hb := Rect2(60, y - 26, 520, 6)
		draw_rect(hb, Color(0.1, 0.1, 0.12, 0.9))
		draw_rect(Rect2(hb.position, Vector2(hb.size.x * warm_end, hb.size.y)), Color(1.0, 0.45 + 0.4 * (1.0 - warm_end), 0.2 + 0.6 * (1.0 - warm_end)))
		var f := Pix.font(1)
		draw_string(f, Vector2(62, y - 30), "Calor do metal", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_DIM)
		draw_circle(Vector2(HIT_X, y), 12.0, Color(1, 0.85, 0.4, 0.25))
		draw_arc(Vector2(HIT_X, y), 12.0, 0.0, TAU, 24, UI.C_GOLD, 2.0)
		for i in _notes.size():
			if _graded[i] != "":
				continue
			var x := HIT_X + (float(_notes[i]) - _t) * SPEED
			if x < 40.0 or x > 600.0:
				continue
			draw_circle(Vector2(x, y), 8.0, Color(1.0, 0.6, 0.25))
			draw_circle(Vector2(x, y), 4.0, Color(1.0, 0.95, 0.7))
		draw_string(f, Vector2(380, y + 30), "ESPAÇO ou E no círculo", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_TEXT)
		if _flash_t > 0.0:
			draw_string_outline(f, Vector2(HIT_X - 20, y - 40), _flash, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 4, Color(0.1, 0.06, 0.04))
			draw_string(f, Vector2(HIT_X - 20, y - 40), _flash, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UI.C_GOLD)
