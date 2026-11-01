class_name HousingEditor
extends Node2D

## Modo Decorar da sua casa (tecla V). Mostra uma grade de 8 px sobre o piso e a caixa de móveis
## guardados numa barra embaixo. Arraste um móvel da caixa para a casa (ou clique nele e clique de
## novo no piso), clique num móvel posto para pegá-lo, R gira, G guarda de volta na caixa, botão
## direito/Esc cancela. Verde = cabe; vermelho = em cima de outro móvel, de uma peça fixa ou de você.
## Posição (x, y) e giro de cada móvel ficam no save (GameState.furniture_layout).

const GRID := 8.0
const WALL_FOOT := 8.0          # quanto da base do móvel de parede entra no piso (o resto sobe pela parede)
## Onde cada móvel aparece na primeira vez (saves antigos e móveis sem posição guardada).
const DEFAULTS := {
	"cama": Vector2(40, 104), "estante": Vector2(104, 64), "lareira": Vector2(192, 60), "trofeu": Vector2(254, 64),
	"relogio": Vector2(300, 54), "planta": Vector2(360, 110), "tapete": Vector2(192, 168), "mesa": Vector2(300, 168),
}

var room: Interior
var nodes: Dictionary = {}          # id do móvel -> nó na casa
var blockers: Array = []            # Rect2 das peças fixas (escrivaninha, espelho, baú...)
var active: bool = false
var held: String = ""               # móvel na mão
var held_rot: int = 0
var _held_new: bool = false         # veio da caixa (cancelar = volta para a caixa)
var _from_pos: Vector2 = Vector2.ZERO
var _from_rot: int = 0
var _drag_from_bar: bool = false
var _valid: bool = false
var _ui: CanvasLayer
var _bar: Control
var _list: HBoxContainer
var _cam: Camera2D = null           # v3.7: câmera do modo Decorar (mostra a casa inteira acima da caixa)

const BAR_H := 62.0                 # altura da caixa de móveis (em unidades da interface, 640x360)


func setup(r: Interior, fixed: Array) -> void:
	room = r
	blockers = fixed
	z_index = 1   # acima dos tapetes, abaixo dos móveis em pé


func _ready() -> void:
	for fid in Data.FURNITURE_ORDER:
		if GameState.is_furniture_placed(fid):
			var stored: Variant = GameState.furniture_pos(fid)
			var pos: Vector2 = stored if stored != null else DEFAULTS.get(fid, Vector2(224, 140))
			var rot := GameState.furniture_rot(fid)
			var node := _spawn(fid, _snap(fid, pos, rot), rot)
			if stored == null:
				GameState.set_furniture_pos(fid, node.position, rot)


# ================================================================== Móveis
func _info(fid: String) -> Dictionary:
	return Data.FURNITURE.get(fid, {})


func _flat(fid: String) -> bool:
	return bool(_info(fid).get("flat", false))


func _wall(fid: String) -> bool:
	return bool(_info(fid).get("wall", false))


func _tex(fid: String) -> Texture2D:
	return Interior.prop_tex(str(_info(fid).get("icon", "")))


func _size(fid: String) -> Vector2:
	var t := _tex(fid)
	return t.get_size() if t != null else Vector2(16, 16)


func _spawn(fid: String, pos: Vector2, rot: int) -> Node2D:
	var flat := _flat(fid)
	var node := room.prop(str(_info(fid)["icon"]), pos, not flat, flat)
	node.set_meta("fid", fid)
	_apply_rot(node, fid, rot)
	match fid:
		"cama":
			var bed := Interior.Spot.new("Descansar", func() -> void:
				GameState.full_heal()
				Audio.wake_up()
				HUD.show_toast("Você descansou. Vida cheia!", UI.C_GOOD), 22.0)
			bed.position = Vector2(0, 8)
			node.add_child(bed)
		"lareira":
			Fx.make_light(node, Vector2(0, -8), Color(1.0, 0.55, 0.25), 0.8, 0.9)
		"relogio":
			Audio.emitter(node, Vector2.ZERO, "amb_relogio", -16.0, true, 0.0, 160.0)
	if bool(_info(fid).get("light", false)):
		Fx.make_light(node, Vector2(0, -14), Color(1.0, 0.8, 0.5), 0.7, 0.8)
	nodes[fid] = node
	return node


## Tapetes giram de 90 em 90 graus; móveis em pé viram para o outro lado (espelhados).
func _apply_rot(node: Node2D, fid: String, rot: int) -> void:
	var s := node.get_child(0) as Sprite2D
	if s == null:
		return
	if _flat(fid):
		var sz := _size(fid)
		s.centered = true
		s.offset = Vector2.ZERO
		s.position = Vector2(0, -sz.y / 2.0)
		s.rotation = float(rot % 4) * PI / 2.0
	else:
		s.flip_h = rot % 2 == 1


## Área que o móvel ocupa no chão (a base, para os de pé; o tapete inteiro, para os do chão).
func footprint(fid: String, pos: Vector2, rot: int) -> Rect2:
	var sz := _size(fid)
	if _flat(fid):
		var s2 := sz if rot % 2 == 0 else Vector2(sz.y, sz.x)
		return Rect2(pos + Vector2(-s2.x / 2.0, -sz.y / 2.0 - s2.y / 2.0), s2)
	var depth := clampf(roundf(sz.y * 0.35), 6.0, 12.0)
	return Rect2(pos + Vector2(-sz.x / 2.0 + 1.0, -depth), Vector2(sz.x - 2.0, depth))


## Encaixa na grade e prende dentro do piso.
func _snap(fid: String, want: Vector2, rot: int) -> Vector2:
	var fp := footprint(fid, Vector2.ZERO, rot)
	var fr := room.floor_rect()
	var left := snappedf(want.x + fp.position.x, GRID)
	left = clampf(left, fr.position.x, fr.end.x - fp.size.x)
	var y := snappedf(want.y, GRID)
	if _wall(fid):
		# móvel de parede: encosta na parede de cima, só escolhe a posição ao longo dela
		return Vector2(left - fp.position.x, fr.position.y + WALL_FOOT).round()
	var sz := _size(fid)
	var min_y := fr.position.y + (sz.y * 0.6 if not _flat(fid) else -fp.position.y)
	y = clampf(y, ceilf(min_y / GRID) * GRID, fr.end.y - (fp.end.y if _flat(fid) else 0.0))
	return Vector2(left - fp.position.x, y).round()


func is_free(fid: String, pos: Vector2, rot: int) -> bool:
	var fp := footprint(fid, pos, rot)
	var flat := _flat(fid)
	for other in nodes:
		if other == fid or _flat(other) != flat:
			continue
		var n: Node2D = nodes[other]
		if fp.intersects(footprint(other, n.position, GameState.furniture_rot(other)).grow(-0.5)):
			return false
	if not flat:
		for r in blockers:
			if fp.intersects((r as Rect2).grow(-0.5)):
				return false
		if room.player != null and fp.grow(5.0).has_point(room.player.global_position):
			return false
	# a passagem da porta fica livre
	var door := Rect2((room.cols / 2 - 1) * Interior.T, (room.rows - 2) * Interior.T, 2 * Interior.T, 2 * Interior.T)
	return not fp.intersects(door)


# ================================================================== Modo Decorar
func toggle() -> void:
	set_active(not active)


func set_active(on: bool) -> void:
	if on and GameState.furniture.is_empty():
		HUD.show_toast("Compre móveis no catálogo (escrivaninha da casa) para poder decorar.", UI.C_DIM)
		return
	if not on and held != "":
		_cancel()
	active = on
	Game.input_locked = on
	Audio.sfx("ui_open" if on else "ui_close", -4.0)
	HUD.set_bottom_hidden(on)
	HUD.set_top_hidden(on)
	if on:
		HUD.set_prompt("")
		_build_ui()
		_frame_room(true)
	else:
		HUD.set_hint("V  Decorar a casa")
		if _ui != null:
			_ui.queue_free()
			_ui = null
		_frame_room(false)
	for fid in nodes:
		_outline(nodes[fid], on)
	queue_redraw()


## v3.7: a caixa de móveis cobria a parte de baixo da casa (a câmera do herói fica em 3x e segue o herói).
## No modo Decorar entra uma câmera própria que afasta a vista e centraliza a casa inteira no espaço acima da caixa.
func _frame_room(on: bool) -> void:
	if not on:
		if _cam != null:
			_cam.queue_free()
			_cam = null
		if room.player != null and is_instance_valid(room.player) and room.player.camera != null:
			room.player.camera.make_current()
			room.player.camera.reset_smoothing()
		return
	var vp := get_viewport().get_visible_rect().size
	var px := room.room_px()
	var ui_k := vp.y / UI.SIZE.y                       # quantos px de tela vale 1 unidade da interface
	var free_h := vp.y - (BAR_H + 12.0) * ui_k          # altura livre acima da caixa
	var zoom := minf((vp.x - 24.0) / px.x, (free_h - 16.0) / px.y)
	zoom = clampf(zoom, 1.0, Player.CAMERA_ZOOM)
	_cam = Camera2D.new()
	_cam.zoom = Vector2(zoom, zoom)
	# o centro da casa vai para o meio da área livre (acima da caixa), não para o meio da tela
	_cam.position = px / 2.0 + Vector2(0, (vp.y / 2.0 - free_h / 2.0) / zoom)
	room.add_child(_cam)
	_cam.make_current()


func _outline(node: Node2D, on: bool) -> void:
	var s := node.get_child(0) as Sprite2D
	if s != null:
		s.modulate = Color(1.2, 1.2, 1.08) if on else Color.WHITE


func _take_from_box(fid: String) -> void:
	if held != "":
		_cancel()
	if _wall(fid):
		HUD.show_toast("%s é móvel de parede: ele encosta na parede de cima." % str(_info(fid).get("name", "")), UI.C_DIM)
	held = fid
	held_rot = GameState.furniture_rot(fid)
	_held_new = true
	var node := _spawn(fid, _snap(fid, get_global_mouse_position(), held_rot), held_rot)
	_outline(node, true)
	_drag_from_bar = true
	Audio.sfx("ui_move", -2.0)
	_refresh_box()


func _pick(fid: String) -> void:
	held = fid
	held_rot = GameState.furniture_rot(fid)
	_held_new = false
	_from_pos = (nodes[fid] as Node2D).position
	_from_rot = held_rot
	Audio.sfx("ui_move", -2.0)


func _drop() -> void:
	if held == "":
		return
	var node: Node2D = nodes[held]
	if not _valid:
		Audio.sfx("ui_error", -4.0)
		HUD.show_toast("Não cabe aqui: escolha um lugar verde na grade.", UI.C_BAD)
		return
	GameState.set_furniture_pos(held, node.position, held_rot)
	node.modulate = Color.WHITE
	held = ""
	Audio.novo("movel", -3.0)
	_refresh_box()


func _cancel() -> void:
	if held == "":
		return
	var node: Node2D = nodes[held]
	if _held_new:
		nodes.erase(held)
		node.queue_free()
	else:
		node.position = _from_pos
		node.modulate = Color.WHITE
		_apply_rot(node, held, _from_rot)
	held = ""
	Audio.sfx("ui_back", -4.0)
	_refresh_box()


## Guarda o móvel na caixa (sai da casa; o bônus continua valendo).
func store(fid: String) -> void:
	if not nodes.has(fid):
		return
	(nodes[fid] as Node2D).queue_free()
	nodes.erase(fid)
	GameState.store_furniture(fid)
	if held == fid:
		held = ""
	Audio.sfx("ui_close", -3.0)
	_refresh_box()


func _rotate() -> void:
	var fid := held if held != "" else _hovered()
	if fid == "":
		return
	if _flat(fid):
		held_rot = (held_rot + 1) % 4 if held == fid else (GameState.furniture_rot(fid) + 1) % 4
	else:
		held_rot = 1 - (held_rot % 2) if held == fid else 1 - (GameState.furniture_rot(fid) % 2)
	_apply_rot(nodes[fid], fid, held_rot)
	if held != fid:
		# girar um móvel posto: só vale se ainda couber
		var node: Node2D = nodes[fid]
		if is_free(fid, node.position, held_rot):
			GameState.set_furniture_pos(fid, node.position, held_rot)
		else:
			_apply_rot(node, fid, GameState.furniture_rot(fid))
			HUD.show_toast("Girando assim ele bate em outra coisa.", UI.C_BAD)
	Audio.sfx("ui_move", -6.0)


func _hovered() -> String:
	var mp := get_global_mouse_position()
	var best := ""
	var best_y := -INF
	for fid in nodes:
		var node: Node2D = nodes[fid]
		var s := node.get_child(0) as Sprite2D
		var r: Rect2
		if _flat(fid):
			r = footprint(fid, node.position, GameState.furniture_rot(fid))
		else:
			r = Rect2(node.position + s.offset, s.texture.get_size())
		# tapetes perdem para o que está em pé em cima deles
		var y := node.position.y - (1000.0 if _flat(fid) else 0.0)
		if r.grow(2.0).has_point(mp) and y > best_y:
			best = fid
			best_y = y
	return best


# ================================================================== Entrada
func _input(ev: InputEvent) -> void:
	# arrastar da caixa: soltar o botão em cima do piso já coloca o móvel
	if active and _drag_from_bar and ev is InputEventMouseButton and not ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_drag_from_bar = false
		if held != "" and not _over_bar():
			get_viewport().set_input_as_handled()
			_drop()


func _unhandled_input(ev: InputEvent) -> void:
	if room._ending or HUD.is_window_open() or HUD.is_dialogue_open():
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.is_action("decorar"):
			get_viewport().set_input_as_handled()
			toggle()
			return
		if not active:
			return
		match ev.keycode:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				if held != "":
					_cancel()
				else:
					set_active(false)
			KEY_R:
				get_viewport().set_input_as_handled()
				_rotate()
			KEY_G, KEY_DELETE, KEY_BACKSPACE:
				get_viewport().set_input_as_handled()
				var fid := held if held != "" else _hovered()
				if fid != "":
					store(fid)
		return
	if not active or not (ev is InputEventMouseButton) or not ev.pressed:
		return
	if ev.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if held == "":
			var fid := _hovered()
			if fid != "":
				_pick(fid)
		else:
			_drop()
	elif ev.button_index == MOUSE_BUTTON_RIGHT and held != "":
		get_viewport().set_input_as_handled()
		_cancel()


func _over_bar() -> bool:
	return _bar != null and _bar.get_global_rect().has_point(_bar.get_global_mouse_position())


func _process(_delta: float) -> void:
	if not active:
		return
	if held != "" and nodes.has(held):
		var node: Node2D = nodes[held]
		node.position = _snap(held, get_global_mouse_position(), held_rot)
		_valid = is_free(held, node.position, held_rot) and not _over_bar()
		node.modulate = Color(1, 1, 1, 0.85)
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var fr := room.floor_rect()
	var x := fr.position.x
	while x <= fr.end.x:
		var major := int(x) % Interior.T == 0
		draw_line(Vector2(x, fr.position.y), Vector2(x, fr.end.y), Color(1, 0.95, 0.8, 0.28 if major else 0.12), 1.0)
		x += GRID
	var y := fr.position.y
	while y <= fr.end.y:
		var major2 := int(y) % Interior.T == 0
		draw_line(Vector2(fr.position.x, y), Vector2(fr.end.x, y), Color(1, 0.95, 0.8, 0.28 if major2 else 0.12), 1.0)
		y += GRID
	for fid in nodes:
		if fid == held:
			continue
		var n: Node2D = nodes[fid]
		draw_rect(footprint(fid, n.position, GameState.furniture_rot(fid)), Color(1, 1, 1, 0.22), false, 1.0)
	var hov := _hovered() if held == "" else ""
	if hov != "":
		var hn: Node2D = nodes[hov]
		draw_rect(footprint(hov, hn.position, GameState.furniture_rot(hov)), Color(1.0, 0.85, 0.4, 0.35))
	if held != "" and nodes.has(held):
		var c := Color(0.35, 1.0, 0.45, 0.4) if _valid else Color(1.0, 0.3, 0.25, 0.45)
		var fp := footprint(held, (nodes[held] as Node2D).position, held_rot)
		draw_rect(fp, c)
		draw_rect(fp, Color(c, 0.9), false, 1.0)


# ================================================================== Caixa de móveis (interface)
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 55
	_ui.scale = Vector2(2, 2)
	add_child(_ui)
	var root := Control.new()
	root.theme = UI.theme()
	root.size = UI.SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)
	_bar = UI.card(Color(0.11, 0.09, 0.08, 0.94), UI.C_ORANGE)
	_bar.position = Vector2(8, UI.SIZE.y - BAR_H - 4.0)
	_bar.custom_minimum_size = Vector2(624, BAR_H)
	_bar.size = _bar.custom_minimum_size
	root.add_child(_bar)
	var v := UI.vbox(2)
	_bar.add_child(v)
	var head := UI.hbox(6)
	v.add_child(head)
	var title := UI.label("Decorar: arraste ou clique num móvel. Esc cancela.", UI.C_ORANGE_L)
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UI.button("Girar (R)", func() -> void: _rotate(), 56))
	head.add_child(UI.button("Guardar (G)", func() -> void:
		var fid := held
		if fid != "":
			store(fid), 64))
	head.add_child(UI.button("Pronto (V)", func() -> void: set_active(false), 56))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(614, 36)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_list = UI.hbox(3)
	sc.add_child(_list)
	_refresh_box()


func _refresh_box() -> void:
	if _list == null or not is_instance_valid(_list):
		return
	for c in _list.get_children():
		c.queue_free()
	var any := false
	for fid in Data.FURNITURE_ORDER:
		if not GameState.owns_furniture(fid) or nodes.has(fid):
			continue
		any = true
		var b := Button.new()
		b.custom_minimum_size = Vector2(72, 32)
		b.icon = _tex(fid)
		b.expand_icon = true
		b.text = str(_info(fid)["name"]).get_slice(" ", 0)
		b.tooltip_text = "%s\n%s\nSegure e arraste para a casa." % [_info(fid)["name"], _info(fid)["desc"]]
		b.add_theme_font_size_override("font_size", 12)
		b.button_down.connect(func() -> void: _take_from_box(fid))
		_list.add_child(b)
	if not any:
		_list.add_child(UI.label("Tudo na casa. Clique num móvel para mudar de lugar ou G para guardar.", UI.C_DIM))
