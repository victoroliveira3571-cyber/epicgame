class_name Interior
extends Node2D

## Interiores da cidade: sua casa (móveis que você arruma), o restaurante, a guilda e as
## casas dos moradores. Cada interior é uma sala montada por código com pisos, paredes e
## móveis do Ninja Adventure; o jogador entra e sai pela porta de baixo.

const T := 16
const WALL_H := 2          # linhas de parede no topo
const DOOR_W := 2          # largura do vão da porta (tiles)

# Moradores das casas de cenário (índice = ordem de HOUSE_DEFS na cidade)
const HOUSES := [
	{"title": "Casa da Dona Marta", "npc": "OldWoman", "floor": "floor_wood", "wall": "wall_cream",
		"lines": ["Entre, querido! Aceita um chá?", "Eu costurava para os aventureiros.", "Foco e chá quente: receita de vovó."]},
	{"title": "Estalagem do Viajante", "npc": "Villager4", "floor": "floor_wood_dark", "wall": "wall_red",
		"lines": ["Os quartos estão cheios hoje!", "Quem sobe a masmorra dorme melhor.", "Já ouvi histórias do chefe do andar 5."]},
	{"title": "Casa do Mestre Lin", "npc": "Monk", "floor": "floor_stone", "wall": "wall_stone",
		"lines": ["Respire fundo. Um pomodoro por vez.", "A mente calma corta mais fundo.", "Hoje meditei por 25 minutos."]},
	{"title": "Salão do Clã", "npc": "Samurai", "floor": "floor_wood_dark", "wall": "wall_red",
		"lines": ["Aqui treinamos de madrugada.", "Honra vem da disciplina.", "Mostre o que você aprendeu."]},
]

var id: String = "casa"
var cols: int = 28
var rows: int = 16
var floor_tex: String = "floor_wood"
var wall_tex: String = "wall_cream"
var world: Node2D
var player: Player
var deco: Node2D
var colliders: StaticBody2D
var furniture_nodes: Dictionary = {}
var edit_mode: bool = false
var picked_id: String = ""
var picked_from: Vector2 = Vector2.ZERO
var _ending: bool = false


## Textura de um móvel/objeto: primeiro assets/custom/props (arte própria), depois assets/ninja/props.
static func prop_tex(name: String) -> Texture2D:
	var custom := "res://assets/custom/props/%s.png" % name
	if ResourceLoader.exists(custom):
		return load(custom)
	return Pix.tex("props/%s.png" % name)


static func house_title(index: int) -> String:
	return HOUSES[index]["title"]


class Spot extends Interactable:
	var text: String = ""
	var cb: Callable

	func _init(label_text: String = "", callback: Callable = Callable(), radius: float = 20.0) -> void:
		text = label_text
		cb = callback
		interact_range = radius

	func get_prompt() -> String:
		return "[E] " + text

	func interact(_player: Node) -> void:
		if cb.is_valid():
			cb.call()


# ================================================================== Montagem
func _ready() -> void:
	add_to_group("interior")
	id = Game.interior_id if Game.interior_id != "" else "casa"
	_configure()
	var img := _compose_room()
	var ground := Sprite2D.new()
	ground.texture = ImageTexture.create_from_image(img)
	ground.centered = false
	ground.z_index = -100
	add_child(ground)
	deco = Node2D.new()
	deco.z_index = -95
	add_child(deco)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	colliders = StaticBody2D.new()
	colliders.collision_layer = 1
	colliders.collision_mask = 0
	add_child(colliders)
	_build_walls()
	_build_exit()
	if id == "casa":
		_build_home()
	elif id == "restaurante":
		_build_restaurant()
	elif id == "guilda":
		_build_guild()
	else:
		_build_resident_house()
	_spawn_player()
	var mod := CanvasModulate.new()
	mod.color = Color(1.0, 0.94, 0.86)
	add_child(mod)
	Audio.play_music("home")
	HUD.on_scene_ready("interior")


func _configure() -> void:
	if id == "casa":
		cols = 28
		rows = 16
		floor_tex = "floor_wood"
		wall_tex = "wall_cream"
	elif id == "restaurante":
		cols = 30
		rows = 17
		floor_tex = "floor_wood_dark"
		wall_tex = "wall_red"
	elif id == "guilda":
		cols = 32
		rows = 18
		floor_tex = "floor_stone"
		wall_tex = "wall_stone"
	else:
		var h: Dictionary = HOUSES[_house_index()]
		cols = 28
		rows = 16
		floor_tex = h["floor"]
		wall_tex = h["wall"]


func _house_index() -> int:
	return clampi(int(id.get_slice("_", 2)), 0, HOUSES.size() - 1) if id.begins_with("casa_npc_") else 0


func _compose_room() -> Image:
	var w := cols * T
	var h := rows * T
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color("131b1b"))
	var floor_img := TileComposer.src_img("res://assets/interior/%s.png" % floor_tex)
	var wall_img := TileComposer.src_img("res://assets/interior/%s.png" % wall_tex)
	for y in range(WALL_H, rows - 1):
		for x in range(1, cols - 1):
			img.blit_rect(floor_img, Rect2i((x % 4) * T, (y % 4) * T, T, T), Vector2i(x * T, y * T))
	for x in range(cols):
		img.blit_rect(wall_img, Rect2i(0, 0, T, T * WALL_H), Vector2i(x * T, 0))
	# paredes laterais e de baixo: moldura escura com friso claro na borda interna
	var edge := Color("4a3a32")
	var lip := Color("9a7a62")
	for y in range(WALL_H, rows):
		img.fill_rect(Rect2i(0, y * T, T, T), edge)
		img.fill_rect(Rect2i(T - 2, y * T, 2, T), lip)
		img.fill_rect(Rect2i(w - T, y * T, T, T), edge)
		img.fill_rect(Rect2i(w - T, y * T, 2, T), lip)
	var door_x0 := (cols / 2 - DOOR_W / 2) * T
	for x in range(cols):
		var px := x * T
		if px >= door_x0 and px < door_x0 + DOOR_W * T:
			continue
		img.fill_rect(Rect2i(px, (rows - 1) * T, T, T), edge)
		img.fill_rect(Rect2i(px, (rows - 1) * T, T, 2), lip)
	# sombra sob a parede de cima e ao lado das paredes
	for i in 6:
		var a := 0.32 - float(i) * 0.05
		for x in range(1, cols - 1):
			for k in T:
				var px := Vector2i(x * T + k, WALL_H * T + i)
				img.set_pixelv(px, img.get_pixelv(px).darkened(a))
	# tapete de entrada na porta
	img.fill_rect(Rect2i(door_x0 + 2, (rows - 1) * T - 5, DOOR_W * T - 4, 5), Color("7a3a34"))
	img.fill_rect(Rect2i(door_x0 + 2, (rows - 1) * T - 5, DOOR_W * T - 4, 1), Color("b25a4a"))
	return img


func room_px() -> Vector2:
	return Vector2(cols * T, rows * T)


func floor_rect() -> Rect2:
	return Rect2(T, WALL_H * T, (cols - 2) * T, (rows - 1 - WALL_H) * T)


func _build_walls() -> void:
	var w := cols * T
	var h := rows * T
	var door_x0 := (cols / 2 - DOOR_W / 2) * T
	_block(Rect2(-8, -8, w + 16, WALL_H * T + 8 + 4))                     # parede de cima (até a linha do piso)
	_block(Rect2(-8, 0, T + 8, h))
	_block(Rect2(w - T, 0, T + 8, h))
	_block(Rect2(-8, h - T + 2, door_x0 + 8, T + 8))
	_block(Rect2(door_x0 + DOOR_W * T, h - T + 2, w - door_x0 - DOOR_W * T + 8, T + 8))
	_block(Rect2(door_x0, h + 4, DOOR_W * T, 12))                            # fecha o vão: a saída é pela porta


func _block(r: Rect2) -> void:
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	c.shape = s
	c.position = r.position + r.size / 2.0
	colliders.add_child(c)


func _build_exit() -> void:
	var door_x := (cols / 2) * T
	var spot := Spot.new("Sair", func() -> void: _leave(), 22.0)
	spot.position = Vector2(door_x, rows * T - 14)
	world.add_child(spot)


func _leave() -> void:
	if _ending:
		return
	_ending = true
	Audio.sfx("ui_close", -4.0)
	Game.leave_interior()


func _spawn_player() -> void:
	var pos := Vector2((cols / 2) * T, (rows - 2) * T + 4)
	player = Player.spawn(world, pos)
	player.set_camera_limits(Rect2(0, 0, cols * T, rows * T))
	player.camera.reset_smoothing()


func _process(_delta: float) -> void:
	if _ending or player == null:
		return
	# andar para o vão da porta também sai
	if player.global_position.y > rows * T - 4 and absf(player.global_position.x - float(cols / 2 * T)) < T:
		_leave()
	if edit_mode and picked_id != "" and furniture_nodes.has(picked_id):
		furniture_nodes[picked_id].position = _snap(get_global_mouse_position())


# ================================================================== Peças
func prop(name: String, foot: Vector2, solid: bool = true, flat: bool = false, parent: Node = null) -> Node2D:
	var tex := prop_tex(name)
	var holder := Node2D.new()
	holder.position = foot.round()
	(parent if parent != null else (deco if flat else world)).add_child(holder)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var sz := tex.get_size() if tex != null else Vector2(16, 16)
	s.offset = Vector2(-sz.x / 2.0, -sz.y)
	holder.add_child(s)
	if solid and not flat:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var c := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(maxf(sz.x - 2.0, 4.0), minf(maxf(sz.y * 0.35, 5.0), 10.0))
		c.shape = r
		c.position = Vector2(0, -r.size.y / 2.0)
		body.add_child(c)
		holder.add_child(body)
	return holder


func tile_foot(tx: float, ty: float) -> Vector2:
	return Vector2(tx * T + T / 2.0, (ty + 1.0) * T)


func spot(text: String, pos: Vector2, cb: Callable, radius: float = 20.0) -> Spot:
	var s := Spot.new(text, cb, radius)
	s.position = pos
	world.add_child(s)
	return s


func npc(sheet: String, pos: Vector2, lines: Array, mode: String = "static", radius: float = 60.0) -> NPC:
	var n := NPC.create(world, sheet, pos, mode)
	n.lines = lines
	if mode == "wander":
		n.wander_radius = radius
		n.move_speed = 14.0
		var pts: Array = []
		for i in 6:
			pts.append(pos + Vector2(randf_range(-radius, radius), randf_range(-radius * 0.5, radius * 0.5)))
		n.wander_points = pts
	return n


func light(pos: Vector2, color: Color, size: float, energy: float) -> void:
	Fx.make_light(world, pos, color, size, energy)


# ================================================================== Casa do jogador
const FURNITURE_DEFAULTS := {
	"cama": Vector2(44, 108), "estante": Vector2(120, 64), "lareira": Vector2(196, 60), "trofeu": Vector2(276, 64),
	"relogio": Vector2(340, 52), "planta": Vector2(404, 112), "tapete": Vector2(226, 186), "mesa": Vector2(332, 176),
}


func _build_home() -> void:
	# decoração fixa da parede e o catálogo de móveis
	prop("i_painting", Vector2(70, 26), false, true)
	prop("i_painting", Vector2(236, 26), false, true)
	prop("i_painting", Vector2(392, 26), false, true)
	prop("i_desk_paper", Vector2(412, 64))
	spot("Catálogo de móveis", Vector2(412, 76), func() -> void: HUD.open_window("casa"), 24.0)
	prop("i_chest", Vector2(32, 232))
	_place_furniture()
	light(Vector2(224, 130), Color(1.0, 0.85, 0.6), 1.8, 0.3)
	HUD.set_hint("V  Organizar móveis")


func _place_furniture() -> void:
	for fid in Data.FURNITURE_ORDER:
		if not GameState.owns_furniture(fid):
			continue
		var f: Dictionary = Data.FURNITURE[fid]
		var stored: Variant = GameState.furniture_pos(fid)
		var pos: Vector2 = stored if stored != null else FURNITURE_DEFAULTS.get(fid, Vector2(224, 140))
		var flat: bool = fid == "tapete"
		var node := prop(f["icon"], _clamp_to_floor(pos, fid), not flat, flat)
		node.set_meta("fid", fid)
		furniture_nodes[fid] = node
		if fid == "cama":
			var bed_spot := spot("Descansar", node.position + Vector2(0, 8), func() -> void:
				GameState.full_heal()
				Audio.sfx("sleep", -4.0)
				HUD.show_toast("Você descansou. Vida cheia!", UI.C_GOOD), 22.0)
			bed_spot.set_meta("fid", fid)
		if fid == "lareira":
			light(node.position + Vector2(0, -8), Color(1.0, 0.55, 0.25), 0.8, 0.9)


func _snap(p: Vector2) -> Vector2:
	return Vector2(roundf(p.x / 4.0) * 4.0, roundf(p.y / 4.0) * 4.0)


func _clamp_to_floor(p: Vector2, fid: String) -> Vector2:
	var tex := prop_tex(Data.FURNITURE[fid]["icon"])
	var sz := tex.get_size() if tex != null else Vector2(16, 16)
	var fr := floor_rect()
	var min_y := fr.position.y + sz.y * (0.6 if fid != "tapete" else 1.0)
	return Vector2(clampf(p.x, fr.position.x + sz.x / 2.0, fr.end.x - sz.x / 2.0), clampf(p.y, min_y, fr.end.y))


func _unhandled_input(ev: InputEvent) -> void:
	if id != "casa" or _ending:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_V and not HUD.is_window_open():
			get_viewport().set_input_as_handled()
			_set_edit_mode(not edit_mode)
		elif ev.keycode == KEY_ESCAPE and edit_mode:
			get_viewport().set_input_as_handled()
			if picked_id != "":
				furniture_nodes[picked_id].position = picked_from
				picked_id = ""
			else:
				_set_edit_mode(false)
	elif edit_mode and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var mp := get_global_mouse_position()
		if picked_id == "":
			_pick_at(mp)
		else:
			_drop()
	elif edit_mode and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT and picked_id != "":
		furniture_nodes[picked_id].position = picked_from
		picked_id = ""
		Audio.sfx("ui_back", -4.0)


func _set_edit_mode(on: bool) -> void:
	if on and furniture_nodes.is_empty():
		HUD.show_toast("Compre móveis no catálogo para poder arrumar a casa.", UI.C_DIM)
		return
	edit_mode = on
	picked_id = ""
	Game.input_locked = on
	Audio.sfx("ui_open" if on else "ui_close", -4.0)
	if on:
		HUD.set_hint("MODO ARRUMAR: clique num móvel para pegar e clique de novo para soltar  |  botão direito/Esc cancela  |  V termina")
		HUD.set_prompt("")
		for fid in furniture_nodes:
			_outline(furniture_nodes[fid], true)
	else:
		HUD.set_hint("V  Organizar móveis")
		for fid in furniture_nodes:
			_outline(furniture_nodes[fid], false)


func _outline(node: Node2D, on: bool) -> void:
	for c in node.get_children():
		if c is Sprite2D:
			(c as Sprite2D).modulate = Color(1.25, 1.25, 1.1) if on else Color.WHITE


func _pick_at(mp: Vector2) -> void:
	var best := ""
	var best_y := -INF
	for fid in furniture_nodes:
		var node: Node2D = furniture_nodes[fid]
		var s := node.get_child(0) as Sprite2D
		var rect := Rect2(node.position + s.offset, s.texture.get_size()).grow(3.0)
		if rect.has_point(mp) and node.position.y > best_y:
			best = fid
			best_y = node.position.y
	if best == "":
		return
	picked_id = best
	picked_from = furniture_nodes[best].position
	Audio.sfx("ui_move", -2.0)
	var node2: Node2D = furniture_nodes[best]
	var tw := create_tween()
	tw.tween_property(node2, "scale", Vector2(1.08, 1.08), 0.08)
	tw.tween_property(node2, "scale", Vector2.ONE, 0.08)


func _drop() -> void:
	var node: Node2D = furniture_nodes[picked_id]
	node.position = _clamp_to_floor(_snap(get_global_mouse_position()), picked_id)
	GameState.set_furniture_pos(picked_id, node.position)
	# o ponto de "Descansar" acompanha a cama
	for s in get_tree().get_nodes_in_group("interactable"):
		if s.has_meta("fid") and s.get_meta("fid") == picked_id:
			(s as Node2D).position = node.position + Vector2(0, 8)
	Audio.sfx("ui_ok", -3.0)
	picked_id = ""


# ================================================================== Restaurante
func _build_restaurant() -> void:
	var w := cols * T
	prop("i_shelf_big", Vector2(60, 62), false)
	prop("i_bookcase", Vector2(108, 62), false)
	prop("i_shelf_big", Vector2(w - 60, 62), false)
	prop("i_pot", Vector2(w - 110, 60), false)
	prop("i_barrel", Vector2(24, 100))
	prop("i_barrel2", Vector2(24, 80))
	prop("i_barrel", Vector2(w - 22, 100))
	prop("i_sack", Vector2(w - 22, 120))
	prop("i_laundry", Vector2(180, 40), false, true)
	# balcão com a cozinheira atrás
	var cx := w / 2.0
	for dx in [-45.0, 0.0, 45.0]:
		prop("i_counter", Vector2(cx + dx, 98))
	_block(Rect2(cx - 70, 40, 140, 36))     # cozinha atrás do balcão
	var cook := npc("Woman", Vector2(cx - 20, 78), ["Hoje tem macarrão quentinho!", "Comer bem rende mais foco.", "O que vai ser?"])
	cook.sprite.z_index = 0
	prop("i_bowl1", Vector2(cx + 22, 90), false)
	prop("i_mug", Vector2(cx - 50, 90), false)
	spot("Pedir comida", Vector2(cx, 112), func() -> void: HUD.open_window("restaurante"), 28.0)
	# mesas com banquinhos
	var tables := [Vector2(90, 168), Vector2(180, 168), Vector2(w - 180, 168), Vector2(w - 90, 168), Vector2(135, 226), Vector2(w - 135, 226)]
	for t in tables:
		prop("i_table", t, true)
		prop("i_stool", t + Vector2(-16, 6))
		prop("i_stool", t + Vector2(16, 6))
		prop("i_bowl2", t + Vector2(2, -6), false)
	prop("i_rug_big", Vector2(cx, 214), false, true)
	prop("i_painting", Vector2(w - 190, 28), false, true)
	prop("i_painting", Vector2(190, 28), false, true)
	# fregueses
	npc("Villager", Vector2(130, 196), ["Esse macarrão é o melhor da cidade.", "Vim comer antes da masmorra."], "wander", 60.0)
	npc("OldMan", Vector2(w - 130, 196), ["Já foi à Guilda hoje?", "Uma boa refeição dá força de verdade."], "wander", 60.0)
	npc("Child", Vector2(cx + 60, 150), ["Quero um sushi!", "Mamãe disse pra eu comer tudo."], "wander", 50.0)
	light(Vector2(cx, 70), Color(1.0, 0.8, 0.55), 2.2, 0.3)
	light(Vector2(90, 150), Color(1.0, 0.8, 0.55), 1.2, 0.25)
	light(Vector2(w - 90, 150), Color(1.0, 0.8, 0.55), 1.2, 0.25)


# ================================================================== Guilda
func _build_guild() -> void:
	var w := cols * T
	var cx := w / 2.0
	prop("i_bookcase", Vector2(70, 62), false)
	prop("i_bookshelf_s", Vector2(112, 62), false)
	prop("i_bookcase", Vector2(w - 70, 62), false)
	prop("i_bookshelf_s", Vector2(w - 112, 62), false)
	# quadro de missões na parede
	prop("quadro_missoes", Vector2(cx - 110, 52), false, true)
	prop("quadro_missoes", Vector2(cx + 110, 52), false, true)
	prop("i_painting", Vector2(cx, 28), false, true)
	# balcão de recepção
	for dx in [-45.0, 0.0, 45.0]:
		prop("i_counter", Vector2(cx + dx, 104))
	_block(Rect2(cx - 70, 44, 140, 38))
	npc("OldMan3", Vector2(cx, 84), ["Bem-vindo, aventureiro!", "As missões do dia estão no quadro.", "Quem foca, conquista."])
	prop("i_desk_paper", Vector2(cx - 50, 96), false)
	spot("Falar com o atendente (missões)", Vector2(cx, 118), func() -> void: HUD.open_window("guilda"), 30.0)
	spot("Quadro de missões", Vector2(cx - 110, 70), func() -> void: HUD.open_window("guilda"), 24.0)
	spot("Quadro de missões", Vector2(cx + 110, 70), func() -> void: HUD.open_window("guilda"), 24.0)
	# escada para a masmorra
	prop("stairs_down_0", Vector2(w - 64, 196), false, true)
	spot("Portão da masmorra", Vector2(w - 64, 200), func() -> void: HUD.open_window("dungeon"), 26.0)
	prop("h_estatua_pequena", Vector2(w - 100, 200), true)
	# mesas dos aventureiros
	for t in [Vector2(120, 170), Vector2(200, 214), Vector2(w - 220, 170)]:
		prop("i_table", t, true)
		prop("i_stool", t + Vector2(-16, 6))
		prop("i_stool", t + Vector2(16, 6))
		prop("i_mug", t + Vector2(-3, -8), false)
	prop("i_rug_big", Vector2(cx, 200), false, true)
	# aventureiros
	npc("Samurai", Vector2(150, 190), ["Cheguei no andar 8 ontem.", "O chefe do pântano é duro."], "wander", 50.0)
	npc("Hunter", Vector2(w - 190, 190), ["Arqueiros mantêm a distância.", "Baús no fundo das salas, sempre."], "wander", 50.0)
	npc("SorcererOrange", Vector2(cx - 40, 160), ["Santuários dão bênçãos de verdade.", "Mago sem foco explode o próprio chapéu."], "wander", 50.0)
	npc("FighterRed", Vector2(cx + 70, 150), ["Vou treinar no andar 3.", "Elites soltam equipamento melhor!"], "wander", 50.0)
	light(Vector2(cx, 80), Color(1.0, 0.82, 0.55), 2.4, 0.3)
	light(Vector2(130, 150), Color(1.0, 0.8, 0.55), 1.4, 0.25)
	light(Vector2(w - 130, 150), Color(1.0, 0.8, 0.55), 1.4, 0.25)


# ================================================================== Casa de morador
func _build_resident_house() -> void:
	var idx := _house_index()
	var h: Dictionary = HOUSES[idx]
	var w := cols * T
	var r := RandomNumberGenerator.new()
	r.seed = 9000 + idx
	prop("i_painting", Vector2(90, 26), false, true)
	prop("i_painting", Vector2(w - 90, 26), false, true)
	prop("furn_estante", Vector2(150, 62), false)
	prop("i_bookcase", Vector2(w - 150, 62), false)
	prop("furn_lareira", Vector2(w / 2.0, 58), true)
	light(Vector2(w / 2.0, 50), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	prop("furn_cama", Vector2(48, 110))
	prop("i_chest", Vector2(48, 150))
	prop("furn_mesa", Vector2(w / 2.0 + 30, 170))
	prop("i_stool", Vector2(w / 2.0 + 10, 182))
	prop("i_stool", Vector2(w / 2.0 + 50, 182))
	prop("i_bowl3", Vector2(w / 2.0 + 30, 165), false)
	prop("furn_tapete", Vector2(w / 2.0 - 70, 200), false, true)
	prop("furn_planta", Vector2(w - 40, 112))
	prop("i_pot", Vector2(w - 40, 215))
	prop("i_barrel", Vector2(30, 232))
	npc(h["npc"], Vector2(w / 2.0 - 30, 150), h["lines"], "wander", 50.0)
	var title := UI.label(h["title"], Color("fff1c9"))
	title.size = Vector2(300, 14)
	title.position = Vector2(w / 2.0 - 150, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 50
	title.scale = Vector2.ONE
	add_child(title)
	light(Vector2(w / 2.0, 120), Color(1.0, 0.8, 0.55), 2.0, 0.28)
