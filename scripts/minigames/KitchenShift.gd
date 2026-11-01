class_name KitchenShift
extends WorkShift

## v3.7: turno na cozinha da taverna (estilo Overcooked, top-down). Atenção dividida e prioridades.
## Caixotes (pão, coxa, bife, peixe) -> TÁBUA (E várias vezes: bife e peixe) -> FOGÃO (cozinha sozinho; pronto
## brilha; esquecido, queima) -> MESA DE MONTAGEM (hambúrguer = bife + pão) -> BALCÃO, na frente do cliente.
## Arte: fogões acesos do Pixel Crawler (pc_cooker3), móveis do Ninja Adventure, comida do 64 Food Icons.

const FOOD := "food64.png"
## item -> [nome, coluna, linha] no food64
const ITEMS := {
	"pao": ["Pão", 0, 6], "coxa_crua": ["Coxa crua", 0, 2], "coxa": ["Coxa assada", 0, 3],
	"bife_cru": ["Bife cru", 2, 2], "bife_prep": ["Bife batido", 1, 2], "bife": ["Bife", 2, 3],
	"peixe_cru": ["Peixe cru", 3, 2], "peixe_prep": ["Peixe limpo", 5, 2], "peixe": ["Peixe assado", 3, 3],
	"hamburguer": ["Hambúrguer", 3, 6], "queimado": ["Queimado", 1, 3],
}
## Preparo na tábua: item cru -> [golpes, resultado]
const CHOP := {"bife_cru": [4, "bife_prep"], "peixe_cru": [3, "peixe_prep"]}
## Fogão: o que entra -> [segundos, resultado]
const COOK := {"coxa_crua": [5.0, "coxa"], "bife_prep": [5.5, "bife"], "peixe_prep": [6.5, "peixe"]}
const BURN_AFTER := 7.0
## Pedidos: prato -> pontos base
const ORDERS := {"coxa": 10.0, "peixe": 16.0, "bife": 15.0, "hamburguer": 24.0}
const CRATES := [["pao", 32], ["coxa_crua", 64], ["bife_cru", 96], ["peixe_cru", 128]]
const STOVES_X := [232, 272, 312]
const SLOTS_X := [216, 264, 312]
const FACES := ["Villager", "Woman", "Villager2", "OldMan", "Villager3", "Villager4", "Boy", "OldWoman"]
const TARGET := 170.0

var _board: Dictionary = {}     # {item, hits}
var _stoves: Array = []         # {item, t, need, state ("", cooking, ready, burnt), st: Station}
var _plate: Array = []          # itens na mesa de montagem
var _cust: Array = []           # {npc, order, pat, max, st}
var _spawn_in: float = 2.0
var _served: int = 0
var _lost: int = 0
var _burnt: int = 0
var _wrong: int = 0
var _board_st: Station
var _plate_st: Station


func _init() -> void:
	duration = 120.0


static func tex_of(item: String) -> Texture2D:
	var d: Array = ITEMS.get(item, ITEMS["queimado"])
	return MgArt.cell(FOOD, int(d[1]), int(d[2]))


static func name_of(item: String) -> String:
	return str(ITEMS.get(item, ["?"])[0])


# ================================================================== Sala
func _build_room() -> void:
	var w := room.cols * Interior.T
	# parede: prateleira, panelas e barris (Ninja Adventure)
	room.prop("i_shelf_big", Vector2(176, 44), false)
	room.prop("i_pot", Vector2(206, 46), false)
	room.prop("i_barrel2", Vector2(w - 18, 76))
	# caixotes de ingredientes
	for c in CRATES:
		room.prop("i_crate", Vector2(int(c[1]), 66))
		var st := _station(Vector2(int(c[1]), 66), 18.0)
		st.item_tex = tex_of(str(c[0]))
		var item: String = c[0]
		st.label_fn = func() -> String: return ("Pegar " + name_of(item)) if carry == "" else ""
		st.use_fn = func() -> void: _take_crate(item)
	# tábua de corte (mesa)
	room.prop("i_table", Vector2(176, 72))
	_board_st = _station(Vector2(176, 72), 20.0)
	_board_st.bar_col = Color(0.6, 0.9, 1.0)
	_board_st.label_fn = func() -> String: return _board_label()
	_board_st.use_fn = func() -> void: _use_board()
	# três fogões acesos (Pixel Crawler)
	for i in STOVES_X.size():
		var x: float = STOVES_X[i]
		var anim := _anim_sprite("pc_cooker3.png", 4, 48, 32, 7.0, Vector2(x, 70))
		anim.stop()
		var st2 := _station(Vector2(x, 70), 20.0)
		st2.icon_y = -30.0
		var slot := {"item": "", "t": 0.0, "need": 0.0, "state": "", "st": st2, "anim": anim}
		_stoves.append(slot)
		st2.label_fn = func() -> String: return _stove_label(slot)
		st2.use_fn = func() -> void: _use_stove(slot)
	# mesa de montagem e barril de descarte
	room.prop("i_table", Vector2(120, 124))
	_plate_st = _station(Vector2(120, 124), 20.0)
	_plate_st.label_fn = func() -> String: return _plate_label()
	_plate_st.use_fn = func() -> void: _use_plate()
	room.prop("i_barrel", Vector2(28, 128))
	var trash := _station(Vector2(28, 128), 18.0)
	trash.label_fn = func() -> String: return ("Jogar fora: " + name_of(carry)) if carry != "" else ""
	trash.use_fn = func() -> void:
		if carry != "":
			_say("Jogou fora: %s" % name_of(carry), UI.C_DIM, 1.0)
			set_carry("")
	# balcão dos pedidos (os clientes ficam do outro lado)
	for x in SLOTS_X:
		room.prop("i_counter", Vector2(x, 156))
	room.colliders.add_child(_rect_shape(Rect2(190, 146, 150, 12)))
	for i in SLOTS_X.size():
		_cust.append({})
	room.light(Vector2(272, 60), Color(1.0, 0.6, 0.3), 1.2, 0.6)
	room.light(Vector2(176, 120), Color(1.0, 0.85, 0.6), 2.2, 0.3)


func _station(pos: Vector2, radius: float) -> Station:
	var st := Station.new(radius)
	st.position = pos + Vector2(0, 6)
	room.world.add_child(st)
	return st


func _anim_sprite(sheet: String, n: int, fw: int, fh: int, fps: float, foot: Vector2) -> AnimatedSprite2D:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("loop")
	sf.set_animation_speed("loop", fps)
	for i in n:
		sf.add_frame("loop", MgArt.sheet(sheet, i, n, fw, fh))
	var holder := Node2D.new()
	holder.position = foot
	room.world.add_child(holder)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.offset = Vector2(0, -fh / 2.0)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(spr)
	spr.play("loop")
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.add_child(_rect_shape(Rect2(-fw / 2.0 + 4, -10, fw - 8, 10)))
	holder.add_child(body)
	return spr


func _rect_shape(r: Rect2) -> CollisionShape2D:
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	c.shape = s
	c.position = r.position + r.size / 2.0
	return c


# ================================================================== Estações
func _take_crate(item: String) -> void:
	if carry != "":
		_say("Mãos ocupadas: largue %s primeiro." % name_of(carry), UI.C_BAD, 1.2)
		return
	set_carry(item, tex_of(item))


func _board_label() -> String:
	if not _board.is_empty():
		if carry == "":
			var need: int = CHOP[_board["item"]][0]
			return "Cortar (%d/%d)" % [int(_board["hits"]), need]
		return ""
	if CHOP.has(carry):
		return "Pôr %s na tábua" % name_of(carry)
	return ""


func _use_board() -> void:
	if _board.is_empty():
		if CHOP.has(carry):
			_board = {"item": carry, "hits": 0}
			_board_st.item_tex = tex_of(carry)
			_board_st.progress = 0.0
			set_carry("")
		elif carry != "":
			_say("%s não precisa ir para a tábua." % name_of(carry), UI.C_DIM, 1.0)
		return
	if carry != "":
		return
	var need: int = CHOP[_board["item"]][0]
	_board["hits"] = int(_board["hits"]) + 1
	_board_st.progress = float(_board["hits"]) / float(need)
	Audio.sfx("hit", -10.0, 0.15)
	if room.player != null and room.player.sprite != null:
		room.player.sprite.play("slash_up", true)
	Fx.burst(room.world, _board_st.global_position + Vector2(0, -20), Color(1, 1, 1), 3, 20.0, 0.2)
	if int(_board["hits"]) >= need:
		var out: String = CHOP[_board["item"]][1]
		_board = {}
		_board_st.item_tex = null
		_board_st.progress = -1.0
		set_carry(out, tex_of(out))
		_say("%s pronto para o fogo!" % name_of(out), UI.C_GOOD, 1.0)


func _stove_label(s: Dictionary) -> String:
	match str(s["state"]):
		"":
			return ("Cozinhar " + name_of(carry)) if COOK.has(carry) else ""
		"cooking":
			return ""
		"ready":
			return ("Tirar " + name_of(s["item"])) if carry == "" else ""
		"burnt":
			return "Raspar o queimado" if carry == "" else ""
	return ""


func _use_stove(s: Dictionary) -> void:
	var st: Station = s["st"]
	match str(s["state"]):
		"":
			if COOK.has(carry):
				s["item"] = COOK[carry][1]
				s["need"] = float(COOK[carry][0])
				s["t"] = 0.0
				s["state"] = "cooking"
				st.item_tex = tex_of(carry)
				st.progress = 0.0
				(s["anim"] as AnimatedSprite2D).play("loop")
				Audio.sfx2("gota", -10.0, 0.1)
				set_carry("")
			elif carry != "":
				_say("Isso não vai no fogo assim.", UI.C_DIM, 1.0)
		"ready":
			if carry == "":
				set_carry(str(s["item"]), tex_of(str(s["item"])))
				_clear_stove(s)
		"burnt":
			if carry == "":
				_clear_stove(s)
				_say("Queimou! Comece de novo.", UI.C_BAD, 1.0)


func _clear_stove(s: Dictionary) -> void:
	var st: Station = s["st"]
	s["state"] = ""
	s["item"] = ""
	st.item_tex = null
	st.progress = -1.0
	st.ready_glow = false
	st.smoking = false
	(s["anim"] as AnimatedSprite2D).stop()


func _plate_label() -> String:
	if _plate.size() == 2:
		return "Pegar o hambúrguer" if carry == "" else ""
	if carry in ["pao", "bife"] and not _plate.has(carry):
		return "Montar: pôr %s" % name_of(carry)
	if _plate.size() == 1 and carry == "":
		return "Pegar %s de volta" % name_of(_plate[0])
	return ""


func _use_plate() -> void:
	if _plate.size() == 2 and carry == "":
		_plate.clear()
		_plate_st.item_tex = null
		set_carry("hamburguer", tex_of("hamburguer"))
		_say("Hambúrguer montado!", UI.C_GOOD, 1.0)
		return
	if carry in ["pao", "bife"] and not _plate.has(carry):
		_plate.append(carry)
		set_carry("")
		if _plate.size() == 2:
			_plate_st.item_tex = tex_of("hamburguer")
			_plate_st.ready_glow = true
		else:
			_plate_st.item_tex = tex_of(_plate[0])
			_plate_st.ready_glow = false
		return
	if _plate.size() == 1 and carry == "":
		set_carry(_plate[0], tex_of(_plate[0]))
		_plate.clear()
		_plate_st.item_tex = null


# ================================================================== Clientes
func _on_start() -> void:
	_spawn_in = 1.0


func _tick(delta: float) -> void:
	for s in _stoves:
		var st: Station = s["st"]
		match str(s["state"]):
			"cooking":
				s["t"] = float(s["t"]) + delta
				st.progress = float(s["t"]) / float(s["need"])
				if float(s["t"]) >= float(s["need"]):
					s["state"] = "ready"
					s["t"] = 0.0
					st.item_tex = tex_of(str(s["item"]))
					st.ready_glow = true
					st.bar_col = Color(1.0, 0.4, 0.2)
					Audio.sfx2("ding", -8.0)
			"ready":
				s["t"] = float(s["t"]) + delta
				st.progress = float(s["t"]) / BURN_AFTER
				if float(s["t"]) >= BURN_AFTER:
					s["state"] = "burnt"
					s["item"] = "queimado"
					st.item_tex = tex_of("queimado")
					st.ready_glow = false
					st.smoking = true
					st.progress = -1.0
					st.bar_col = Color(1.0, 0.8, 0.3)
					_burnt += 1
					break_combo()
					Audio.sfx("die", -10.0, 0.1)
					_say("Algo queimou no fogão!", UI.C_BAD, 1.2)
	# clientes: paciência
	for i in _cust.size():
		var c: Dictionary = _cust[i]
		if c.is_empty():
			continue
		c["pat"] = float(c["pat"]) - delta
		var st3: Station = c["st"]
		st3.progress = float(c["pat"]) / float(c["max"])
		st3.bar_col = UI.C_GOOD if st3.progress > 0.5 else (UI.C_GOLD if st3.progress > 0.25 else UI.C_BAD)
		if float(c["pat"]) <= 0.0:
			_lost += 1
			break_combo()
			_say("Um cliente cansou de esperar e foi embora.", UI.C_BAD, 1.4)
			_remove_customer(i)
	_spawn_in -= delta
	if _spawn_in <= 0.0:
		var free := -1
		for i in _cust.size():
			if _cust[i].is_empty():
				free = i
				break
		if free >= 0:
			_spawn_customer(free)
		var elapsed := duration - time_left
		_spawn_in = lerpf(11.0, 7.0, clampf(elapsed / duration, 0.0, 1.0)) + randf() * 2.0


func _spawn_customer(i: int) -> void:
	var elapsed := duration - time_left
	var pool := ["coxa", "coxa", "peixe", "bife"]
	if elapsed > 25.0:
		pool.append_array(["hamburguer", "peixe", "bife"])
	if elapsed > 60.0:
		pool.append_array(["hamburguer", "hamburguer"])
	var order: String = pool[randi() % pool.size()]
	var x: float = SLOTS_X[i]
	var n := NPC.create(room.world, FACES[randi() % FACES.size()], Vector2(x, 182), "cutscene")
	n.face(Vector2(x, 140))
	n.play_anim("idle_up")
	var st := _station(Vector2(x, 150), 22.0)
	st.icon_y = -34.0
	st.item_tex = tex_of(order)
	var pat := lerpf(55.0, 40.0, clampf(elapsed / duration, 0.0, 1.0)) + (10.0 if order == "hamburguer" else 0.0)
	var c := {"npc": n, "order": order, "pat": pat, "max": pat, "st": st}
	_cust[i] = c
	st.label_fn = func() -> String: return ("Entregar %s" % name_of(carry)) if carry != "" else ("Pedido: %s" % name_of(order))
	st.use_fn = func() -> void: _serve(c)
	n.show_emote(8)


func _serve(c: Dictionary) -> void:
	if carry == "":
		return
	var i := _cust.find(c)
	if i < 0:
		return
	if carry != str(c["order"]):
		_wrong += 1
		break_combo()
		(c["npc"] as NPC).show_emote(17)
		_say("Não foi isso que pediram! (%s)" % name_of(str(c["order"])), UI.C_BAD, 1.2)
		return
	var ratio := float(c["pat"]) / float(c["max"])
	var got := add_points(float(ORDERS[c["order"]]) * (0.6 + 0.6 * ratio))
	_served += 1
	set_carry("")
	Audio.novo("compra", -6.0)
	(c["npc"] as NPC).show_emote(22)
	_say("+%d  %s" % [int(got), "Rápido! Gorjeta!" if ratio > 0.6 else "Servido."], UI.C_GOLD, 1.0)
	_remove_customer(i)


func _remove_customer(i: int) -> void:
	var c: Dictionary = _cust[i]
	if c.is_empty():
		return
	var n: NPC = c["npc"]
	var st: Station = c["st"]
	st.queue_free()
	var tw := n.create_tween()
	n.play_anim("walk_down")
	tw.tween_property(n, "position", n.position + Vector2(0, 30), 0.6)
	tw.tween_callback(n.queue_free)
	_cust[i] = {}


# ================================================================== Resultado
func _status() -> String:
	return "servidos %d" % _served


func _score() -> float:
	return points / TARGET


func _summary() -> Array:
	return ["Clientes servidos: %d" % _served, "Foram embora: %d   Pratos queimados: %d   Pedidos errados: %d" % [_lost, _burnt, _wrong],
		"Pontos: %d (meta %d)" % [int(points), int(TARGET)]]
