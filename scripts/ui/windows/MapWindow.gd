extends UIWindow

## Mapa grande (tecla M): cidade, floresta ou andar da masmorra com cada local nomeado, o jogador e o
## objetivo da história destacado em dourado. À direita, a lista dos locais (o do objetivo no topo).

var _canvas: Control
var _scene: Node = null


class Canvas extends Control:
	var scene: Node
	var landmarks: Array = []
	var tex: Texture2D
	var tiles: Vector2
	var k: float = 1.0                  # pixels do mapa por pixel do mundo
	var obj_id: String = ""
	var dungeon: bool = false

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.06, 0.9))
		if scene == null or not is_instance_valid(scene):
			return
		if dungeon:
			_draw_dungeon()
		else:
			_draw_overworld()
		draw_rect(Rect2(Vector2.ZERO, size), UI.C_ORANGE, false, 1.0)

	func _draw_overworld() -> void:
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, 0.95))
		var f := Pix.font(1)
		var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		var placed: Array = []      # retângulos de rótulos já desenhados (desvia para não sobrepor)
		var order: Array = landmarks.duplicate()
		order.sort_custom(func(a: Array, b: Array) -> bool: return str(a[0]) == obj_id)   # objetivo escolhe primeiro
		for l in order:
			var p: Vector2 = (l[2] as Vector2) * k
			var is_obj := str(l[0]) == obj_id
			var col := UI.C_GOLD if is_obj else Color("e9b27a")
			if is_obj:
				draw_circle(p, 7.0 + 3.0 * beat, Color(UI.C_GOLD, 0.25 + 0.3 * beat))
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), col)
			draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), UI.C_LINE, false, 1.0)
			var name := ("> " if is_obj else "") + str(l[1])
			var w := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var tp := p + Vector2(-w / 2.0, -8.0)
			tp.x = clampf(tp.x, 2.0, size.x - w - 2.0)
			for dy in [0.0, 17.0, -13.0, 30.0, -26.0, 43.0]:
				var cand := Rect2(tp.x, clampf(tp.y + dy, 12.0, size.y - 4.0) - 11.0, w, 13.0)
				var clash := false
				for r in placed:
					if (r as Rect2).intersects(cand):
						clash = true
						break
				if not clash or dy == 43.0:
					tp.y = cand.position.y + 11.0
					placed.append(cand)
					break
			draw_string_outline(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0.1, 0.06, 0.04))
			draw_string(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_GOLD if is_obj else Color("fff1c9"))
		var pl: Node2D = scene.get("player")
		if pl != null and is_instance_valid(pl):
			var pp := pl.global_position * k
			var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.008)
			draw_rect(Rect2(pp - Vector2(3, 3), Vector2(6, 6)), Color(1, 1, 1, pulse))
			draw_rect(Rect2(pp - Vector2(3, 3), Vector2(6, 6)), UI.C_LINE, false, 1.0)

	func _draw_dungeon() -> void:
		var s: Vector2i = scene.map_size()
		var c := k
		for y in s.y:
			for x in s.x:
				if scene.explored[y * s.x + x] == 0:
					continue
				if scene.is_floor_cell(x, y):
					draw_rect(Rect2(x * c, y * c, c, c), Color(0.62, 0.56, 0.5, 0.95))
				elif scene.is_floor_cell(x, y + 1) or scene.is_floor_cell(x - 1, y) or scene.is_floor_cell(x + 1, y) or scene.is_floor_cell(x, y - 1):
					draw_rect(Rect2(x * c, y * c, c, c), Color(0.25, 0.22, 0.26, 0.95))
		var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
		var f := Pix.font(1)
		if scene.stairs_down != null:
			var sc: Vector2i = scene.cell_of(scene.stairs_down.global_position)
			if scene.explored[sc.y * s.x + sc.x] == 1:
				draw_circle(Vector2(sc.x + 0.5, sc.y + 0.5) * c, 4.0 + 2.0 * beat, Color(UI.C_GOLD, 0.5))
				draw_string_outline(f, Vector2(sc.x * c + 6, sc.y * c), "Escada para baixo", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0.1, 0.06, 0.04))
				draw_string(f, Vector2(sc.x * c + 6, sc.y * c), "Escada para baixo", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_GOLD)
		if scene.stairs_up != null:
			var uc: Vector2i = scene.cell_of(scene.stairs_up.global_position)
			draw_rect(Rect2(uc.x * c, uc.y * c, c, c), UI.C_GOOD)
		if scene.boss != null and is_instance_valid(scene.boss) and scene.boss.state != Enemy.State.DEAD:
			var bc: Vector2i = scene.cell_of(scene.boss.global_position)
			if scene.explored[bc.y * s.x + bc.x] == 1:
				draw_circle(Vector2(bc.x + 0.5, bc.y + 0.5) * c, 4.0, UI.C_HP)
		var pc: Vector2i = scene.player_cell()
		draw_rect(Rect2(pc.x * c - 1, pc.y * c - 1, c + 2, c + 2), Color(1, 1, 1, 0.6 + 0.4 * beat))


func _init() -> void:
	win_title = "Mapa  (M para fechar)"
	win_size = Vector2(620, 346)


func refresh() -> void:
	pass


func build() -> void:
	_scene = get_tree().get_first_node_in_group("town")
	if _scene == null:
		_scene = get_tree().get_first_node_in_group("dungeon")
	if _scene == null:
		HUD.close_window()
		return
	_canvas = Canvas.new()
	_canvas.scene = _scene
	var is_dungeon := _scene.is_in_group("dungeon")
	_canvas.dungeon = is_dungeon
	var avail := Vector2(398, 306)
	if is_dungeon:
		var s: Vector2i = _scene.map_size()
		_canvas.k = floorf(minf(avail.x / float(s.x), avail.y / float(s.y)))
		_canvas.size = Vector2(s.x, s.y) * _canvas.k
	else:
		var world_px := Vector2(_scene.W, _scene.H) * float(_scene.T)
		_canvas.k = minf(avail.x / world_px.x, avail.y / world_px.y)
		_canvas.size = (world_px * _canvas.k).round()
		_canvas.tex = _scene.minimap_tex
		_canvas.landmarks = _scene.map_landmarks()
		_canvas.obj_id = Story.objective_target() if Story.started() else ""
	_canvas.custom_minimum_size = _canvas.size
	add_to_body(_canvas, Vector2(0, 0))
	# lista de locais à direita
	var side := UI.vbox(2)
	add_to_body(side, Vector2(410, 0))
	if Story.started():
		side.add_child(UI.label("Objetivo", UI.C_GOLD))
		side.add_child(UI.wrap_label(Story.objective_text(), UI.C_TEXT, 190))
		side.add_child(UI.hline())
	add_to_body(UI.button("Vicerus (mapa-múndi) >", func() -> void: HUD.open_window("mundo"), 160), Vector2(410, 286))
	side.add_child(UI.label("Locais", UI.C_ORANGE_L))
	if is_dungeon:
		side.add_child(UI.wrap_label("Verde: escada de subida. Dourado: escada para baixo. Vermelho: chefe. Só aparece o que você já explorou.", UI.C_DIM, 190))
	else:
		var list: Array = _canvas.landmarks.duplicate()
		list.sort_custom(func(a: Array, b: Array) -> bool: return str(a[0]) == _canvas.obj_id or (str(b[0]) != _canvas.obj_id and str(a[1]) < str(b[1])))
		for l in list:
			var is_obj: bool = str(l[0]) == _canvas.obj_id
			side.add_child(UI.label(("> " if is_obj else "- ") + str(l[1]), UI.C_GOLD if is_obj else UI.C_DIM))


func _process(_delta: float) -> void:
	if _canvas != null:
		_canvas.queue_redraw()
