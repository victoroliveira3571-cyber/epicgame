class_name Interior
extends Node2D

## Interiores da cidade: sua casa (móveis que você arruma), a pousada, a guilda, a biblioteca,
## a ferraria, a loja de armas, a arena e as casas dos moradores. Cada sala é montada por código
## com pisos, paredes e móveis (Ninja Adventure + props próprios p_*); o tamanho segue a função
## do lugar (oficina de costura pequena, salões grandes). O dono de cada estabelecimento se
## apresenta na primeira visita (ShopTalk). O jogador entra e sai pela porta de baixo.

const T := 16
const WALL_H := 2          # linhas de parede no topo
const DOOR_W := 2          # largura do vão da porta (tiles)

# Moradores das casas de cenário (índice = ordem de HOUSE_DEFS na cidade)
const HOUSES := [
	{"title": "Ateliê da Costureira", "npc": "costureira", "floor": "floor_wood", "wall": "wall_cream", "size": Vector2i(14, 10),
		"lines": ["Entre! Cuidado com os alfinetes.", "Capa nova? Volte quando juntar fichas de estilo.", "A Dona Marta manda lembranças."]},
	{"title": "Estalagem do Viajante", "npc": "estalajadeiro", "floor": "floor_wood_dark", "wall": "wall_red", "size": Vector2i(24, 14),
		"lines": ["Os quartos estão cheios hoje!", "Quem sobe a masmorra dorme melhor.", "Já ouvi histórias do chefe do andar 5."]},
	{"title": "Casa do Mestre Lin", "npc": "Master", "floor": "floor_stone", "wall": "wall_stone", "size": Vector2i(16, 10),
		"lines": ["Respire fundo. Um pomodoro por vez.", "A mente calma corta mais fundo.", "Hoje meditei por 25 minutos."]},
	{"title": "Salão do Clã", "npc": "mestre_cla", "floor": "floor_wood_dark", "wall": "wall_red", "size": Vector2i(26, 14),
		"lines": ["Aqui treinamos de madrugada.", "Honra vem da disciplina.", "Mostre o que você aprendeu na Arena."]},
]

## Tamanho de cada sala (tiles) e pisos.
const ROOMS := {
	"casa": [24, 14, "floor_wood", "wall_cream"], "restaurante": [28, 16, "floor_wood_dark", "wall_red"],
	"guilda": [32, 18, "floor_stone", "wall_stone"], "biblioteca": [26, 15, "floor_wood_dark", "wall_cream"],
	"casa_familia": [20, 12, "floor_wood", "wall_cream"], "casa_pai": [16, 10, "floor_wood_dark", "wall_stone"],
	"forja": [18, 11, "floor_stone", "wall_stone"], "loja": [16, 10, "floor_wood", "wall_red"],
	"arena": [30, 18, "floor_sand", "wall_stone"], "delegacia": [22, 13, "floor_stone", "wall_stone"],
	"laboratorio": [24, 14, "floor_stone", "wall_cream"],
}

var id: String = "casa"
var cols: int = 28
var rows: int = 16
var floor_tex: String = "floor_wood"
var wall_tex: String = "wall_cream"
var world: Node2D
var player: Player
var deco: Node2D
var colliders: StaticBody2D
var housing: HousingEditor = null    # sua casa: modo Decorar (V)
var _blockers: Array = []            # peças fixas da casa (o editor não deixa pôr móvel em cima)
var _ending: bool = false
var owner_id: String = ""          # dono do lugar (apresentação na primeira visita, ShopTalk)
var owner_npc: NPC = null


## Textura de um móvel/objeto: primeiro assets/custom/props (arte própria), depois assets/ninja/props.
static func prop_tex(name: String) -> Texture2D:
	if BuildingFactory.is_factory_name(name):
		return BuildingFactory.texture(name)
	var custom := "res://assets/custom/props/%s.png" % name
	if ResourceLoader.exists(custom):
		return load(custom)
	return Pix.tex("props/%s.png" % name)


static func house_title(index: int) -> String:
	return HOUSES[index]["title"]


## v2.7: marca no chão da zona de estudo (anel que pulsa e fica mais forte quando o herói está perto).
class StudyMarker extends Node2D:
	var radius: float = 22.0

	func _init() -> void:
		z_index = -1

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		var near := pl != null and pl.global_position.distance_to(global_position) <= radius + 6.0
		var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
		var a := (0.55 if near else 0.28) + 0.2 * beat
		var col := Color(1.0, 0.82, 0.35, a)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_arc(Vector2.ZERO, radius - 2.0 - 2.0 * beat, 0.0, TAU, 28, col, 1.5)
		draw_circle(Vector2.ZERO, radius - 6.0, Color(1.0, 0.82, 0.35, 0.08 + (0.1 if near else 0.0)))


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
	elif id == "biblioteca":
		_build_library()
	elif id == "casa_familia":
		_build_family_home()
	elif id == "casa_pai":
		_build_father_house()
	elif id == "forja":
		_build_forge()
	elif id == "loja":
		_build_weapon_shop()
	elif id == "arena":
		_build_arena()
	elif id == "delegacia":
		_build_jail()
	elif id == "laboratorio":
		_build_lab()
	else:
		_build_resident_house()
	_spawn_player()
	var mod := CanvasModulate.new()
	mod.color = Color(0.72, 0.7, 0.76) if id == "casa_pai" else Color(1.0, 0.94, 0.86)
	add_child(mod)
	Audio.play_music("musica_laboratorio" if id == "laboratorio" else ("interior_taverna" if id in ["restaurante", "casa_npc_1"] else ("home" if id == "casa_familia" else "interior_manor")))
	Audio.set_place_loop("biblioteca_escrita" if id == "biblioteca" else ("ferraria_ambiente" if id == "forja" else ("lareira_casa" if id.begins_with("casa") else "")))
	HUD.on_scene_ready("interior")
	if id == "casa_familia" and Story.step() == "c1_casa":
		await get_tree().create_timer(0.8).timeout
		Story.talk("mae")
	elif owner_id != "" and not Story.flag("intro_" + owner_id) and not Story.is_busy():
		# primeira visita: o dono nota o jogador, acena e se apresenta
		await get_tree().create_timer(0.7).timeout
		if is_instance_valid(owner_npc):
			owner_npc.show_emote(22)
			owner_npc.face(player.global_position)
			if owner_npc.actor != null:
				owner_npc.actor.hop(3.0)
		await get_tree().create_timer(0.5).timeout
		ShopTalk.talk(owner_id)


func _configure() -> void:
	if ROOMS.has(id):
		var r: Array = ROOMS[id]
		cols = r[0]
		rows = r[1]
		floor_tex = r[2]
		wall_tex = r[3]
	else:
		var h: Dictionary = HOUSES[_house_index()]
		cols = h["size"].x
		rows = h["size"].y
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
	if id == "delegacia" and Law.is_jailed():
		player.global_position.y -= 18.0
		return
	if id == "casa_familia" and Story.step() == "c1_casa":
		HUD.set_prompt("")
		HUD.show_toast("Fale com %s antes de partir." % Story.fmt("{mae}"), UI.C_ORANGE_L)
		player.global_position.y -= 18.0
		return
	_ending = true
	Audio.sfx("ui_close", -4.0)
	# prólogo: da casa da família a trilha leva direto a Focus Town
	if id == "casa_familia" and not Story.flag("saiu_casa"):
		Story.set_flag("saiu_casa")
		await Story.say("c1_saida")
		Game.go_to_town("start")
		return
	Game.leave_interior()


func _spawn_player() -> void:
	var pos := Vector2((cols / 2) * T, (rows - 2) * T + 4)
	if id == "delegacia" and Law.is_jailed():
		pos = Vector2(52, 138)   # dentro da cela
	player = Player.spawn(world, pos)
	player.set_camera_limits(Rect2(0, 0, cols * T, rows * T))
	player.camera.reset_smoothing()


func _process(_delta: float) -> void:
	if _ending or player == null:
		return
	if id == "delegacia":
		_jail_tick()
	# andar para o vão da porta também sai
	if player.global_position.y > rows * T - 4 and absf(player.global_position.x - float(cols / 2 * T)) < T:
		_leave()


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
		if id == "casa" and housing == null:
			_blockers.append(Rect2(foot.round() + Vector2(-sz.x / 2.0 + 1.0, -clampf(roundf(sz.y * 0.35), 6.0, 12.0)),
				Vector2(sz.x - 2.0, clampf(roundf(sz.y * 0.35), 6.0, 12.0))))
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


## Mesa onde dá para estudar: abre o Pomodoro preso ao cenário deste lugar.
func study_spot(scene: String, pos: Vector2) -> Spot:
	var marker := StudyMarker.new()
	marker.position = pos
	world.add_child(marker)
	return spot("Estudar aqui (Pomodoro)", pos, func() -> void:
		if Game.transitioning or HUD.is_dialogue_open():
			return
		await Cutscene.play("sit", {"line": _study_line(), "setting": _study_setting()})
		HUD.open_pomodoro_at(scene), 22.0)


func _study_setting() -> String:
	match id:
		"biblioteca":
			return "library"
		"restaurante", "casa_npc_1":
			return "inn"
		"delegacia":
			return "jail"
		_:
			return "home"


func _study_line() -> String:
	var lines := ["Respire fundo. Um bloco de cada vez.", "Celular longe. Livro aberto.", "Começar é a parte mais difícil. Você já começou.", "Só os próximos 25 minutos importam."]
	return lines[randi() % lines.size()]


## Objeto preso na parede de cima (quadros, janelas, prateleiras): fica atrás de todo mundo.
func wall(name: String, x: float, y: float = 30.0) -> Node2D:
	return prop(name, Vector2(x, y), false, true)


## Morador sentado (taverna, biblioteca): `dir` = para onde olha.
func sitter(look: String, pos: Vector2, dir: String, lines: Array) -> NPC:
	var n := NPC.new()
	n.sheet = look
	n.mode = "sit"
	n.sit_dir = dir
	n.position = pos
	n.lines = lines
	world.add_child(n)
	return n


## Dono do lugar: NPC com "Falar com" (ShopTalk) e apresentação na primeira visita.
func shop_owner(look: String, talk_id: String, title: String, pos: Vector2, lines: Array, mode: String = "static") -> NPC:
	var n := npc(look, pos, lines, mode, 30.0)
	n.add_to_group("speaker_" + talk_id)
	n.set_meta("has_talker", true)
	n.use_look(Looks.SPEAKER_LOOK.get(talk_id, look))
	var p := Spot.new("Falar com " + title, func() -> void: ShopTalk.talk(talk_id), 22.0)
	n.add_child(p)
	owner_id = talk_id
	owner_npc = n
	return n


## Mesa com banquinhos, louça e, às vezes, vela.
func table_set(t: Vector2, round_table: bool = false, deco: String = "i_bowl2", candle: bool = false) -> void:
	prop("p_mesa_redonda" if round_table else "i_table", t, true)
	prop("i_stool", t + Vector2(-16, 6))
	prop("i_stool", t + Vector2(16, 6))
	if deco != "":
		prop(deco, t + Vector2(-3, -7 if round_table else -6), false)
	if candle:
		prop("p_vela", t + Vector2(5, -8), false)
		light(t + Vector2(5, -14), Color(1.0, 0.75, 0.45), 0.5, 0.45)


# ================================================================== Biblioteca
func _build_library() -> void:
	var w := cols * T
	var cx := w / 2.0
	for x in [36.0, 72.0, 108.0, w - 108.0, w - 72.0, w - 36.0]:
		prop("i_bookcase", Vector2(x, 62), false)
	wall("i_painting", cx, 26)
	wall("p_janela", cx - 46, 28)
	wall("p_janela", cx + 46, 28)
	prop("furn_relogio", Vector2(w - 20, 66), false)
	Audio.emitter(world, Vector2(w - 20, 56), "amb_relogio", -14.0, true, 0.0, 180.0)
	# balcão da bibliotecária
	for dx in [-24.0, 24.0]:
		prop("i_counter", Vector2(cx + dx, 100))
	_block(Rect2(cx - 50, 44, 100, 36))
	shop_owner("bibliotecaria", "bibliotecaria", "Dona Celeste", Vector2(cx, 82),
		["Bem-vindo à biblioteca.", "As mesas de estudo estão livres.", "Um pomodoro por vez, sem pressa."])
	prop("i_desk_paper", Vector2(cx + 30, 92), false)
	prop("p_livros", Vector2(cx - 34, 92), false)
	prop("p_vela", Vector2(cx - 18, 91), false)
	# estantes no meio da sala
	for x in [48.0, w - 48.0]:
		prop("i_bookshelf_s", Vector2(x, 140))
		prop("i_bookshelf_s", Vector2(x, 186))
	prop("p_livros", Vector2(70, 196), false)
	# mesas de estudo (com vela) e quem estuda nelas
	var tables := [Vector2(cx - 62, 160), Vector2(cx + 62, 160), Vector2(cx - 62, 206), Vector2(cx + 62, 206)]
	for t in tables:
		table_set(t, false, "p_livros", true)
		study_spot("livraria", t + Vector2(0, 14))
	prop("p_tapete_azul", Vector2(cx, 200), false, true)
	sitter("aventureira_maga", tables[1] + Vector2(16, 6), "left", ["Shhh! Estou revisando.", "Ler também é treinar."])
	sitter("Villager", tables[2] + Vector2(-16, 6), "right", ["Mais uma página...", "Esse livro tem dragões!"])
	# canto de leitura
	prop("i_armchair", Vector2(w - 44, 220))
	prop("p_planta_pequena", Vector2(w - 22, 222), false)
	prop("furn_planta", Vector2(24, 222))
	npc("Child", Vector2(cx, 226), ["Shhh! Estou lendo.", "Achei um livro sobre a masmorra!"], "wander", 40.0)
	light(Vector2(cx, 80), Color(1.0, 0.86, 0.6), 2.4, 0.3)


# ================================================================== Casa do jogador
func _build_home() -> void:
	var w := cols * T
	# decoração fixa da parede e o catálogo de móveis
	wall("p_janela", 70, 28)
	wall("i_painting", 150, 26)
	wall("p_janela", 330, 28)
	wall("p_prateleira_potes", 236, 30)
	prop("i_desk_paper", Vector2(w - 40, 64))
	prop("p_vela", Vector2(w - 48, 54), false)
	spot("Catálogo de móveis", Vector2(w - 40, 76), func() -> void: HUD.open_window("casa"), 24.0)
	prop("p_espelho", Vector2(w - 70, 64))
	spot("Espelho (aparência)", Vector2(w - 70, 76), func() -> void: HUD.open_window("aparencia"), 20.0)
	prop("i_chest", Vector2(28, 206))
	spot("Baú da casa", Vector2(28, 218), func() -> void: HUD.open_window("bau"), 20.0)
	prop("p_caixotes", Vector2(30, 186))
	prop("p_vaso_flores", Vector2(w - 22, 208), false)
	# escrivaninha de estudo: abre o Pomodoro com o cenário da casa
	prop("i_desk_paper", Vector2(140, 206))
	prop("p_livros", Vector2(128, 197), false)
	prop("p_vela", Vector2(152, 196), false)
	prop("i_stool", Vector2(140, 220))
	study_spot("casa", Vector2(140, 218))
	# móveis: posição, giro e caixa de guardados ficam com o editor (HousingEditor)
	housing = HousingEditor.new()
	housing.setup(self, _blockers)
	deco.add_child(housing)
	light(Vector2(192, 120), Color(1.0, 0.85, 0.6), 1.8, 0.3)
	light(Vector2(152, 190), Color(1.0, 0.75, 0.45), 0.6, 0.4)
	HUD.set_hint("V  Decorar a casa")


# ================================================================== Pousada Pão Quente
func _build_restaurant() -> void:
	var w := cols * T
	var cx := w / 2.0
	wall("p_janela", 40, 28)
	wall("p_janela", w - 40, 28)
	wall("p_panelas", cx - 50, 28)
	wall("p_ervas", cx + 50, 26)
	wall("i_painting", 110, 26)
	wall("i_painting", w - 110, 26)
	# cozinha atrás do balcão
	prop("p_fogao", Vector2(cx - 40, 62), false)
	prop("p_prateleira_potes", Vector2(cx + 36, 52), false, true)
	prop("i_shelf_big", Vector2(cx + 40, 62), false)
	light(Vector2(cx - 40, 52), Color(1.0, 0.6, 0.3), 0.8, 0.7)
	for dx in [-45.0, 0.0, 45.0]:
		prop("i_counter", Vector2(cx + dx, 96))
	_block(Rect2(cx - 70, 40, 140, 34))
	var cook := npc("OldWoman", Vector2(cx - 18, 76), ["Hoje tem pão quentinho!", "Estudou hoje?", "Chá e foco: receita de vó."])
	cook.sprite.z_index = 0
	cook.add_to_group("speaker_marta")
	cook.use_look("marta")
	spot("Falar com Dona Marta", Vector2(cx - 20, 110), func() -> void: Story.talk("marta"), 22.0)
	prop("p_cha", Vector2(cx + 22, 88), false)
	prop("i_mug", Vector2(cx - 50, 88), false)
	prop("p_vaso_flores", Vector2(cx + 46, 88), false)
	spot("Pedir comida", Vector2(cx + 30, 110), func() -> void: HUD.open_window("restaurante"), 22.0)
	Audio.emitter(world, Vector2(cx, 70), "servir_agua", -16.0, false, 26.0, 200.0)
	# barris e sacos nos cantos
	prop("i_barrel", Vector2(22, 92))
	prop("i_barrel2", Vector2(22, 74))
	prop("i_sack", Vector2(40, 92))
	prop("i_barrel", Vector2(w - 22, 92))
	prop("p_caixotes", Vector2(w - 26, 74), false)
	# lareira lateral e bancos
	prop("furn_lareira", Vector2(w - 24, 196))
	light(Vector2(w - 24, 184), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	prop("p_banco", Vector2(26, 230))
	# mesas com fregueses sentados
	var tables := [Vector2(76, 150), Vector2(156, 150), Vector2(w - 156, 150), Vector2(w - 76, 150), Vector2(116, 204), Vector2(w - 136, 204)]
	for i in tables.size():
		table_set(tables[i], i % 2 == 1, ["i_bowl2", "i_bowl1", "i_mug", "i_bowl3"][i % 4], i % 3 == 0)
	study_spot("taverna", tables[4] + Vector2(0, 14))
	sitter("Villager", tables[0] + Vector2(-16, 6), "right", ["Esse macarrão é o melhor da cidade.", "Vim comer antes da masmorra."])
	sitter("OldMan", tables[2] + Vector2(16, 6), "left", ["Já foi à Guilda hoje?", "Uma boa refeição dá força de verdade."])
	sitter("Villager2", tables[3] + Vector2(-16, 6), "right", ["A sopa da Marta cura tudo.", "Hoje é dia de folga!"])
	sitter("aventureiro_cacador", tables[5] + Vector2(16, 6), "left", ["Caçada boa hoje.", "Lobos na Borda de novo."])
	prop("p_tapete_grande", Vector2(cx, 196), false, true)
	npc("Child", Vector2(cx + 30, 176), ["Quero um sushi!", "Mamãe disse pra eu comer tudo."], "wander", 40.0)
	light(Vector2(cx, 70), Color(1.0, 0.8, 0.55), 2.2, 0.3)
	light(Vector2(90, 150), Color(1.0, 0.8, 0.55), 1.2, 0.25)
	light(Vector2(w - 90, 150), Color(1.0, 0.8, 0.55), 1.2, 0.25)


# ================================================================== Guilda
func _build_guild() -> void:
	var w := cols * T
	var cx := w / 2.0
	prop("i_bookcase", Vector2(52, 62), false)
	prop("i_bookshelf_s", Vector2(90, 62), false)
	prop("i_bookcase", Vector2(w - 52, 62), false)
	prop("i_bookshelf_s", Vector2(w - 90, 62), false)
	wall("quadro_missoes", cx - 110, 52)
	wall("quadro_missoes", cx + 110, 52)
	wall("i_painting", cx, 26)
	wall("p_estandarte", cx - 60, 34)
	wall("p_estandarte_azul", cx + 60, 34)
	wall("p_escudos_parede", 140, 28)
	wall("p_tocha_parede", 20, 30)
	wall("p_tocha_parede", w - 20, 30)
	light(Vector2(20, 18), Color(1.0, 0.6, 0.3), 0.6, 0.8)
	light(Vector2(w - 20, 18), Color(1.0, 0.6, 0.3), 0.6, 0.8)
	# balcão de recepção
	for dx in [-45.0, 0.0, 45.0]:
		prop("i_counter", Vector2(cx + dx, 104))
	_block(Rect2(cx - 70, 44, 140, 38))
	var helena := npc("Princess", Vector2(cx, 84), ["Bem-vindo à Guilda!", "As missões do dia estão no quadro.", "Quem foca, conquista."])
	helena.add_to_group("speaker_helena")
	helena.use_look("helena")
	prop("i_desk_paper", Vector2(cx - 50, 96), false)
	prop("p_cofre", Vector2(cx + 50, 78))
	prop("p_vaso_flores", Vector2(cx + 20, 96), false)
	spot("Falar com Helena", Vector2(cx, 118), func() -> void: Story.talk("helena"), 22.0)
	spot("Missões da Guilda", Vector2(cx + 46, 118), func() -> void: HUD.open_window("guilda"), 18.0)
	_guild_story_npcs(cx, w)
	spot("Quadro de missões", Vector2(cx - 110, 70), func() -> void: HUD.open_window("guilda"), 24.0)
	spot("Quadro de missões", Vector2(cx + 110, 70), func() -> void: HUD.open_window("guilda"), 24.0)
	# escada para a masmorra
	prop("stairs_down_0", Vector2(w - 64, 196), false, true)
	spot("Portão da masmorra", Vector2(w - 64, 200), func() -> void: HUD.open_window("dungeon"), 26.0)
	prop("h_estatua_pequena", Vector2(w - 100, 200), true)
	prop("p_lancas", Vector2(w - 30, 200))
	prop("p_caixotes", Vector2(28, 250))
	prop("p_barril_espadas", Vector2(52, 252))
	# mesas dos aventureiros
	var tables := [Vector2(110, 170), Vector2(190, 214), Vector2(w - 220, 170), Vector2(110, 236)]
	for t in tables:
		table_set(t, false, "i_mug", false)
	prop("p_banco", Vector2(cx, 250))
	prop("p_tapete_grande", Vector2(cx, 200), false, true)
	sitter("aventureiro_samurai", tables[0] + Vector2(-16, 6), "right", ["Cheguei no andar 8 ontem.", "O chefe do pântano é duro."])
	sitter("aventureira_maga", tables[2] + Vector2(16, 6), "left", ["Santuários dão bênçãos de verdade.", "Mago sem foco explode o próprio chapéu."])
	npc("Hunter", Vector2(w - 190, 214), ["Arqueiros mantêm a distância.", "Baús no fundo das salas, sempre."], "wander", 50.0)
	npc("FighterRed", Vector2(cx + 70, 150), ["Vou treinar na Arena.", "Elites soltam equipamento melhor!"], "wander", 50.0)
	light(Vector2(cx, 80), Color(1.0, 0.82, 0.55), 2.4, 0.3)
	light(Vector2(130, 150), Color(1.0, 0.8, 0.55), 1.4, 0.25)
	light(Vector2(w - 130, 150), Color(1.0, 0.8, 0.55), 1.4, 0.25)


## Personagens da história que aparecem na Guilda conforme o capítulo.
func _guild_story_npcs(cx: float, w: float) -> void:
	var s := Story.step()
	var ch := Story.chapter()
	if s == "c2_exame":
		StoryProp.talker(npc("NinjaBlue2", Vector2(cx + 40, 140), ["Hoje eu passo no exame.", "Vento não espera ninguém."]), "ivo", "Ivo")
	elif ch >= 2:
		StoryProp.talker(npc("NinjaBlue2", Vector2(cx + 60, 160), ["Já fez seu foco de hoje?", "Revanche quando quiser."], "wander", 40.0), "ivo", "Ivo")
	if ch >= 3:
		StoryProp.talker(npc("Master", Vector2(w - 100, 170), ["A Névoa espera lá embaixo.", "Respire antes de descer."]), "lin", "Mestre Lin")
	if s == "c1_volta" or s == "c4_pietro":
		StoryProp.talker(npc("Hunter", Vector2(cx - 60, 150), ["Boa caçada hoje?", "A floresta muda todo dia."]), "pietro", "Pietro")


# ================================================================== Casa da família (floresta)
func _build_family_home() -> void:
	var w := cols * T
	wall("p_janela", 50, 28)
	wall("p_janela", w - 50, 28)
	wall("p_ervas", 110, 26)
	wall("i_painting", 210, 26)
	prop("furn_lareira", Vector2(w / 2.0, 58), true)
	light(Vector2(w / 2.0, 50), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	prop("furn_cama", Vector2(30, 100))
	prop("p_cama_simples", Vector2(66, 96))
	prop("i_dresser", Vector2(w - 34, 62), false)
	prop("p_espelho", Vector2(w - 62, 62))
	spot("Espelho (aparência)", Vector2(w - 62, 74), func() -> void: HUD.open_window("aparencia"), 18.0)
	prop("p_fogao", Vector2(w / 2.0 + 56, 62), false)
	wall("p_panelas", w / 2.0 + 56, 30)
	prop("p_mesa_redonda", Vector2(w / 2.0 + 56, 140))
	prop("i_stool", Vector2(w / 2.0 + 38, 146))
	prop("i_stool", Vector2(w / 2.0 + 74, 146))
	prop("i_bowl3", Vector2(w / 2.0 + 52, 133), false)
	prop("p_vaso_flores", Vector2(w / 2.0 + 62, 132), false)
	prop("furn_tapete", Vector2(w / 2.0 - 40, 150), false, true)
	# canto de costura da mãe
	prop("p_roca", Vector2(96, 128))
	prop("p_novelos", Vector2(120, 132), false)
	prop("furn_planta", Vector2(w - 24, 120))
	prop("i_basket", Vector2(w - 28, 164))
	prop("p_caixotes", Vector2(26, 166))
	var mom := npc("Woman", Vector2(118, 112), ["Coma alguma coisa antes de sair.", "Seu pai adorava esta lareira."])
	StoryProp.talker(mom, "mae", Story.fmt("{mae}"))
	spot("Descansar", Vector2(30, 112), func() -> void:
		GameState.full_heal()
		Audio.sfx("sleep", -4.0)
		HUD.show_toast("Você descansou em casa. Vida cheia!", UI.C_GOOD), 20.0)
	Audio.emitter(world, Vector2(w / 2.0, 50), "amb_relogio", -20.0, true, 0.0, 120.0)
	light(Vector2(w / 2.0, 120), Color(1.0, 0.82, 0.55), 2.0, 0.3)


# ================================================================== Casa abandonada do pai
func _build_father_house() -> void:
	var w := cols * T
	prop("i_bookcase", Vector2(40, 62), false)
	prop("i_shelf_s", Vector2(w - 40, 62), false)
	wall("p_janela", w / 2.0, 28)
	wall("p_ervas", 90, 26)
	prop("i_desk_paper", Vector2(w / 2.0, 96))
	prop("p_vela", Vector2(w / 2.0 - 10, 86), false)
	prop("p_livros", Vector2(w / 2.0 + 12, 87), false)
	prop("i_stool", Vector2(w / 2.0, 110))
	prop("i_crate", Vector2(24, 130))
	prop("p_caixotes", Vector2(30, 112), false)
	prop("i_sack", Vector2(w - 24, 128))
	prop("p_cama_simples", Vector2(w - 30, 106)).modulate = Color(0.8, 0.76, 0.72)
	var chest_prop := prop("i_chest", Vector2(w / 2.0 + 50, 132))
	spot("Abrir o baú do pai", Vector2(w / 2.0 + 50, 142), func() -> void:
		Audio.sfx2("chaves", -6.0)
		await Story.say("casa_pai")
		if not Story.flag("diario_pai"):
			Story.set_flag("diario_pai")
			GameState.add_gold(30)
			GameState.add_xp(30, false)
			HUD.show_toast("Página do diário guardada. +30 ouro  +30 XP", UI.C_GOLD), 22.0)
	chest_prop.modulate = Color(0.85, 0.8, 0.75)
	Audio.emitter(world, Vector2(40, 140), "amb_goteira", -10.0, true, 0.0, 200.0)
	light(Vector2(w / 2.0, 90), Color(0.9, 0.85, 0.7), 1.2, 0.35)


# ================================================================== Ferraria
func _build_forge() -> void:
	var w := cols * T
	var cx := w / 2.0
	prop("p_fornalha", Vector2(70, 66), false)
	light(Vector2(70, 52), Color(1.0, 0.5, 0.2), 1.3, 1.1)
	prop("p_fole", Vector2(98, 62), false)
	prop("p_carvao", Vector2(40, 72), false)
	wall("p_ferramentas", cx + 20, 30)
	wall("p_escudos_parede", w - 60, 28)
	prop("p_rack_espadas", Vector2(w - 40, 64), false)
	prop("p_lingotes", Vector2(cx + 40, 66), false)
	# bigorna no meio, ferreiro martelando
	prop("p_bigorna", Vector2(cx - 8, 110))
	prop("p_tina_agua", Vector2(cx + 26, 112))
	prop("p_rebolo", Vector2(w - 42, 118))
	prop("i_barrel", Vector2(24, 128))
	prop("p_barril_espadas", Vector2(24, 150))
	prop("p_caixotes", Vector2(w - 28, 160))
	var smith := shop_owner("ferreiro", "ferreiro", "Brás", Vector2(cx - 30, 104),
		["Traga barras e ouro.", "Aprimoro qualquer arma.", "Ferro quente, trabalho bom."])
	smith.set_meta("hammer", true)
	_hammer_loop(smith)
	# balcão de serviço perto da porta
	prop("i_counter", Vector2(cx - 50, 150))
	spot("Aprimorar equipamento", Vector2(cx - 50, 162), func() -> void: HUD.open_window("forja"), 22.0)
	Audio.emitter(world, Vector2(70, 56), "bigorna1", -18.0, false, 9.0, 220.0)
	light(Vector2(cx, 100), Color(1.0, 0.75, 0.5), 1.8, 0.3)


## O ferreiro bate na bigorna de tempos em tempos (gesto + som + faíscas).
func _hammer_loop(smith: NPC) -> void:
	var t := Timer.new()
	t.wait_time = 2.6
	t.autostart = true
	smith.add_child(t)
	t.timeout.connect(func() -> void:
		if smith.talking or smith.actor == null:
			return
		smith.play_anim("idle_right")
		smith.actor.gesture()
		Audio.sfx2("bigorna1" if randf() < 0.5 else "bigorna2", -14.0, 0.08)
		Fx.burst(world, smith.global_position + Vector2(22, -10), Color(1.0, 0.7, 0.3), 6, 26.0, 0.3)
		t.wait_time = randf_range(2.0, 4.0))


# ================================================================== Loja de armas
func _build_weapon_shop() -> void:
	var w := cols * T
	var cx := w / 2.0
	wall("p_escudos_parede", 48, 28)
	wall("p_arcos_parede", w - 48, 28)
	wall("p_tocha_parede", cx, 30)
	light(Vector2(cx, 20), Color(1.0, 0.6, 0.3), 0.6, 0.8)
	prop("p_rack_espadas", Vector2(cx - 50, 64), false)
	prop("p_rack_espadas", Vector2(cx + 50, 64), false)
	prop("p_armadura", Vector2(24, 82))
	prop("p_armadura", Vector2(w - 24, 82))
	prop("p_lancas", Vector2(24, 126))
	prop("p_barril_espadas", Vector2(w - 24, 128))
	prop("p_cofre", Vector2(cx + 34, 76))
	# vitrine com o armeiro atrás
	prop("p_vitrine", Vector2(cx, 102))
	_block(Rect2(cx - 24, 50, 48, 46))
	shop_owner("armeiro", "armeiro", "Otávio", Vector2(cx, 84), ["Espadas novas chegaram!", "Equipamento bom salva vidas.", "Só vendo o que presta."])
	spot("Comprar equipamento", Vector2(cx, 116), func() -> void: HUD.open_window("loja"), 22.0)
	prop("p_tapete_grande", Vector2(cx, 130), false, true)
	prop("p_planta_pequena", Vector2(w - 40, 150), false)
	light(Vector2(cx, 100), Color(1.0, 0.82, 0.55), 1.6, 0.3)


# ================================================================== Laboratório
## Laboratório do Dr. Faísca: bancadas com frascos, caldeirão borbulhando, bobina que solta faíscas,
## quadro de fórmulas. Dr. Faísca (dono, bancada de poções), Pipeta e Tonico (ajudantes cômicos).
func _build_lab() -> void:
	var w := cols * T
	var cx := w / 2.0
	wall("p_lab_quadro", cx, 30)
	wall("p_janela", 60, 28)
	wall("p_janela", w - 60, 28)
	prop("p_lab_potes", Vector2(36, 72), false)
	prop("p_lab_potes", Vector2(w - 36, 72), false)
	prop("p_lab_bancada", Vector2(cx - 70, 104))
	prop("p_lab_bancada", Vector2(cx + 70, 104))
	prop("p_lab_caldeirao", Vector2(cx, 150))
	light(Vector2(cx, 140), Color(0.4, 1.0, 0.5), 1.6, 0.9)
	Audio.emitter(world, Vector2(cx, 150), "gota", -16.0, false, 4.0, 200.0)
	var coil := prop("p_lab_bobina", Vector2(w - 40, 170))
	light(Vector2(w - 40, 130), Color(0.6, 0.8, 1.0), 1.2, 0.8)
	_spark_loop(coil)
	prop("p_caixotes", Vector2(30, 180))
	prop("i_barrel", Vector2(30, 206))
	var doc := shop_owner("cientista", "cientista", "Dr. Faísca", Vector2(cx - 40, 132),
		["Eureka! Ou quase.", "Traga ingredientes!", "Não toque no frasco rosa."], "static")
	doc.set_meta("hammer", true)
	spot("Bancada de preparos (laboratório)", Vector2(cx - 70, 118), func() -> void: HUD.open_window("laboratorio"), 24.0)
	var pip := npc("pipeta", Vector2(cx + 70, 122), ["Anotando tudo, doutor!", "Isso era para borbulhar?", "Óculos de proteção salvam vidas."], "static")
	pip.use_look("pipeta")
	pip.set_meta("has_talker", true)
	pip.add_to_group("speaker_pipeta")
	pip.add_child(Spot.new("Falar com Pipeta", func() -> void: ShopTalk.talk("pipeta"), 22.0))
	var ton := npc("tonico", Vector2(80, 160), ["Eu só carrego as coisas.", "Gosma não sai da roupa.", "O doutor me deixa provar tudo primeiro."], "wander", 40.0)
	ton.use_look("tonico")
	ton.set_meta("has_talker", true)
	ton.add_to_group("speaker_tonico")
	ton.add_child(Spot.new("Falar com Tonico", func() -> void: ShopTalk.talk("tonico"), 22.0))
	light(Vector2(cx, 100), Color(0.85, 1.0, 0.9), 2.2, 0.35)


## A bobina solta faíscas de tempos em tempos.
func _spark_loop(coil: Node2D) -> void:
	while is_instance_valid(coil) and is_inside_tree():
		await get_tree().create_timer(randf_range(1.5, 3.5)).timeout
		if not is_instance_valid(coil):
			return
		Fx.burst(world, coil.global_position + Vector2(0, -40), Color(0.7, 0.9, 1.0), 6, 40.0, 0.3)
		Audio.sfx("magic2", -18.0)


# ================================================================== Delegacia
var _jail_gate: Node2D = null
var _jail_was_free: bool = false
var _jail_guard: NPC = null


## Cela à esquerda (grade que some quando a pena acaba), mesa do guarda no meio, bancos de espera.
func _build_jail() -> void:
	var w := cols * T
	for x in [40.0, 100.0]:
		wall("p_janela", x - 6, 28)
	wall("p_estandarte", w / 2.0 + 20, 34)
	wall("p_estandarte_azul", w - 40, 34)
	# a cela: fundo, lateral e grade na frente do corredor
	_block(Rect2(104, 70, 6, 150))
	_jail_gate = Node2D.new()
	world.add_child(_jail_gate)
	for y in [100.0, 128.0, 156.0]:
		var bars := prop("p_portao_arena", Vector2(107, y), false, false, _jail_gate)
		bars.scale = Vector2(0.6, 0.8)
	var gate_body := StaticBody2D.new()
	gate_body.collision_layer = 1
	gate_body.collision_mask = 0
	var gc := CollisionShape2D.new()
	var gr := RectangleShape2D.new()
	gr.size = Vector2(8, 96)
	gc.shape = gr
	gc.position = Vector2(107, 128)
	gate_body.add_child(gc)
	_jail_gate.add_child(gate_body)
	prop("p_banco", Vector2(30, 180))             # cama de pedra da cela
	prop("i_barrel", Vector2(80, 100))
	study_spot("cela", Vector2(60, 148)).text = "Estudar na cela (cumprir a pena)"
	# mesa do guarda
	prop("i_desk_paper", Vector2(w / 2.0 + 30, 96))
	prop("i_counter", Vector2(w / 2.0 + 6, 104))
	prop("i_counter", Vector2(w / 2.0 + 54, 104))
	_block(Rect2(w / 2.0 - 20, 80, 100, 30))
	_jail_guard = npc("guarda", Vector2(w / 2.0 + 30, 86), ["Cumpra a pena e não volte aqui.", "Aqui, quem estuda sai mais rápido."], "static")
	_jail_guard.use_look("guarda")
	_jail_guard.add_to_group("speaker_guarda")
	var talk := Spot.new("Falar com o guarda", func() -> void: _jail_talk(), 24.0)
	_jail_guard.add_child(talk)
	prop("p_banco", Vector2(w - 60, 190))
	prop("i_stool", Vector2(w - 90, 210))
	light(Vector2(60, 140), Color(1.0, 0.85, 0.6), 1.4, 0.3)
	_jail_was_free = not Law.is_jailed()
	_jail_apply()
	if Law.is_jailed():
		var d := Law.data()
		await get_tree().create_timer(1.0).timeout
		Story.say([["guarda@anger", "Alto lá! Agressão a morador é crime em Focus Town."],
			["guarda", "A multa é de %d minutos de foco. Estude aqui na cela (mesa da cela) para pagar." % int(d.get("jail_total", 0))],
			["tip:guarda", "Aqui dentro cada minuto de foco abate a pena antes de virar crédito. Cumprida a pena, a grade abre."]])


func _jail_tick() -> void:
	var free := not Law.is_jailed()
	if free != _jail_was_free:
		_jail_was_free = free
		_jail_apply()
		if free:
			Audio.sfx2("porta_metal", -6.0, 0.0)
			Story.say([["guarda", "Pena cumprida. Está livre. Comporte-se, cidadão."]])


func _jail_apply() -> void:
	if _jail_gate == null:
		return
	_jail_gate.visible = Law.is_jailed()
	for c in _jail_gate.get_children():
		if c is StaticBody2D:
			(c as StaticBody2D).collision_layer = 1 if Law.is_jailed() else 0


func _jail_talk() -> void:
	if Story.is_busy() or HUD.is_dialogue_open():
		return
	if Law.is_jailed():
		await Story.say([["guarda", "Faltam %d min de foco para quitar a pena. Use a mesa da cela." % Law.jail_left()]])
	else:
		var d := Law.data()
		await Story.say([["guarda", "Você tem %d prisão(ões) no histórico. A próxima agressão custa %d min. Ande na linha." % [int(d.get("arrests", 0)), Law.next_fine()]]])


# ================================================================== Arena
func _build_arena() -> void:
	var w := cols * T
	var cx := w / 2.0
	wall("p_estandarte", 30, 34)
	wall("p_estandarte_azul", w - 30, 34)
	for x in [120.0, w - 120.0]:
		wall("p_tocha_parede", x, 30)
		light(Vector2(x, 20), Color(1.0, 0.6, 0.3), 0.8, 0.8)
	prop("p_portao_arena", Vector2(22, 170), true)
	prop("p_portao_arena", Vector2(w - 22, 170), true)
	# torcida em pé em volta do ringue (sem arquibancada): cresce com o prestígio (Bronze ~6, Lenda lotada)
	var crowd := ["Villager", "Villager2", "OldMan", "Villager5", "Child", "aventureiro_cacador", "Woman", "aventureira_maga"]
	var total := clampi(6 + Arena.prestige() / 22, 6, 40)
	var ring_c := Vector2(cx, 160)
	var placed_n := 0
	var ring_i := 0
	while placed_n < total and ring_i < 3:
		var rx := 168.0 + float(ring_i) * 20.0
		var ry := 88.0 + float(ring_i) * 16.0
		var cap := 20 + ring_i * 6
		var want := mini(total - placed_n, cap)
		for k in want:
			var ang := TAU * (float(k) + 0.5 * float(ring_i)) / float(want)
			# sem gente na frente da entrada (embaixo): deixa a passagem até a mestra da arena
			if sin(ang) > 0.55 and absf(cos(ang)) < 0.55:
				continue
			var pos := ring_c + Vector2(cos(ang) * rx, sin(ang) * ry)
			pos.x = clampf(pos.x, 40.0, w - 40.0)
			pos.y = clampf(pos.y, 56.0, rows * T - 40.0)
			var cn := npc(crowd[(placed_n + k * 3) % crowd.size()], pos, ["Vai! Vai!", "Que golpe!", "Rola, rola!", "Esse é dos bons!", "Mais um round!"], "static")
			cn.face(ring_c)
			cn.add_to_group("arena_crowd")
			placed_n += 1
		ring_i += 1
	# a mestra da arena perto da entrada
	shop_owner("bruna", "arena", "Bruna", Vector2(cx - 60, rows * T - 52),
		["Pronto para um duelo?", "Prestígio se conquista luta a luta.", "Rolar na hora certa vale ouro."])
	spot("Inscrever-se num duelo", Vector2(cx - 30, rows * T - 44), func() -> void: HUD.open_window("arena"), 20.0)
	prop("p_placa_arena", Vector2(cx - 30, rows * T - 56), false)
	prop("p_boneco_treino", Vector2(w - 60, rows * T - 46))
	# ringue delimitado: poço de areia, cerca de madeira com estacas e colisão (ninguém sai da luta)
	var c := Vector2(cx, 160)
	var pit := Polygon2D.new()
	var pts := PackedVector2Array()
	for k in 48:
		var a := TAU * k / 48.0
		pts.append(c + Vector2(cos(a) * 146.0, sin(a) * 66.0))
	pit.polygon = pts
	pit.color = Color(0.62, 0.48, 0.3, 0.55)
	deco.add_child(pit)
	var inner := Line2D.new()
	inner.width = 1.0
	inner.default_color = Color(0.45, 0.3, 0.18, 0.6)
	for k in 49:
		var a2 := TAU * k / 48.0
		inner.add_point(c + Vector2(cos(a2) * 138.0, sin(a2) * 60.0))
	deco.add_child(inner)
	var fence := Line2D.new()
	fence.width = 2.0
	fence.default_color = Color(0.4, 0.26, 0.14)
	var seg_n := 32
	var ring_pts: Array = []
	for k in seg_n + 1:
		var a3 := TAU * k / float(seg_n)
		var p := c + Vector2(cos(a3) * 152.0, sin(a3) * 72.0)
		ring_pts.append(p)
		fence.add_point(p)
	deco.add_child(fence)
	for k in seg_n:
		var seg := CollisionShape2D.new()
		var ss := SegmentShape2D.new()
		ss.a = ring_pts[k]
		ss.b = ring_pts[k + 1]
		seg.shape = ss
		colliders.add_child(seg)
		if k % 2 == 0:
			var post := ColorRect.new()
			post.color = Color(0.55, 0.37, 0.2)
			post.size = Vector2(3, 7)
			post.position = (ring_pts[k] as Vector2) - Vector2(1.5, 6)
			post.z_index = 1
			world.add_child(post)
	arena_center = c
	light(Vector2(cx, 160), Color(1.0, 0.9, 0.7), 3.0, 0.3)


var arena_center: Vector2 = Vector2.ZERO
var _duel: ArenaFighter = null
var _duel_opp: Dictionary = {}
var _duel_over: bool = true


## Duelo da Arena: posiciona os dois no ringue, contagem, luta até alguém cair.
func start_duel(opp: Dictionary) -> void:
	if not _duel_over:
		return
	_duel_over = false
	_duel_opp = opp
	GameState.full_heal()
	GameState.no_death = true
	if not GameState.knocked_out.is_connected(_on_duel_lost):
		GameState.knocked_out.connect(_on_duel_lost)
	player.global_position = arena_center + Vector2(-90, 0)
	player.facing = Vector2.RIGHT
	player.camera.reset_smoothing()
	_duel = ArenaFighter.spawn(world, opp, arena_center + Vector2(90, 0))
	_duel.defeated.connect(_on_duel_won)
	Game.input_locked = true
	Audio.sfx2("porta_metal", -6.0, 0.0)
	Audio.play_music("boss", 0.6)
	HUD.show_boss(str(opp["name"]), 1.0)
	_crowd_cheer(18)
	for n in ["3", "2", "1"]:
		HUD.floor_banner(n, "Duelo contra " + str(opp["name"]))
		Audio.sfx("ui_tab", -4.0)
		await get_tree().create_timer(0.75).timeout
		if not is_inside_tree():
			return
	HUD.floor_banner("LUTEM!", Arena.rank_name() + "  -  " + str(Arena.DIFFS[int(opp["diff"])][0]))
	Audio.sfx2("impacto", -6.0)
	Audio.set_place_loop("arena_batalha", -12.0)
	Game.input_locked = false
	_duel.begin()
	while not _duel_over and is_inside_tree():
		await get_tree().create_timer(2.4).timeout
		if not _duel_over and is_inside_tree():
			_crowd_cheer(18, 6)


func _crowd_cheer(emote: int, how_many: int = 10) -> void:
	var nodes := get_tree().get_nodes_in_group("arena_crowd")
	nodes.shuffle()
	for n in nodes.slice(0, how_many):
		(n as NPC).show_emote(emote if randf() < 0.7 else 27)


func _on_duel_won() -> void:
	if _duel_over:
		return
	_duel_over = true
	_end_duel(true)


func _on_duel_lost() -> void:
	if _duel_over:
		return
	_duel_over = true
	_end_duel(false)


func _end_duel(won: bool) -> void:
	Audio.set_place_loop("")
	GameState.no_death = false
	Game.input_locked = true
	HUD.hide_boss()
	var res := Arena.record(_duel_opp, won)
	if won:
		Audio.jingle("boss_clear")
		Audio.sfx2("moedas", -4.0)
		_crowd_cheer(27)
		player.sprite.play("emote_down", true)
		HUD.floor_banner("VITÓRIA!", "+%d ouro  +%d XP  +%d prestígio" % [res["gold"], res["xp"], res["prestige"]])
	else:
		Audio.sfx2("trombone", -4.0)
		if is_instance_valid(_duel):
			_duel.celebrate()
		_crowd_cheer(16)
		player.sprite.hold_last = true
		player.sprite.play("hurt_down", true)
		HUD.floor_banner("DERROTA", "%d prestígio. Treine e volte!" % res["prestige"])
	if res["rank_up"]:
		await get_tree().create_timer(1.6).timeout
		Audio.sfx("powerup")
		HUD.floor_banner("NOVO RANK: " + Arena.rank_name(), "A Arena inteira aplaude você")
		_crowd_cheer(27)
	await get_tree().create_timer(2.0).timeout
	if not is_inside_tree():
		return
	player.sprite.hold_last = false
	player.sprite.play("idle_down", true)
	GameState.full_heal()
	if is_instance_valid(_duel):
		var tw := _duel.create_tween()
		tw.tween_property(_duel, "modulate:a", 0.0, 0.5)
		tw.tween_callback(_duel.queue_free)
	player.global_position = arena_center + Vector2(20, 98)   # fora da cerca, perto da Bruna
	player.camera.reset_smoothing()
	Game.input_locked = false
	Audio.play_music("interior_manor", 1.0)
	Arena.last_result = res
	HUD.open_window("arena_resultado")


# ================================================================== Casa de morador
func _build_resident_house() -> void:
	var idx := _house_index()
	var h: Dictionary = HOUSES[idx]
	var w := cols * T
	match idx:
		0:
			_build_tailor(h, w)
		1:
			_build_inn(h, w)
		2:
			_build_lin(h, w)
		_:
			_build_dojo(h, w)
	var title := UI.label(h["title"], Color("fff1c9"))
	title.size = Vector2(300, 14)
	title.position = Vector2(w / 2.0 - 150, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 50
	add_child(title)


func _build_tailor(h: Dictionary, w: float) -> void:
	# ateliê pequeno e cheio: manequins, roca, tecidos e a mesa de costura
	wall("p_janela", 40, 28)
	prop("p_tecidos", Vector2(w / 2.0, 62), false)
	prop("p_manequim", Vector2(w - 30, 70))
	prop("p_manequim", Vector2(w - 52, 74))
	prop("p_espelho", Vector2(26, 66))
	prop("p_mesa_costura", Vector2(w / 2.0 - 10, 104))
	prop("i_stool", Vector2(w / 2.0 - 10, 118))
	prop("p_roca", Vector2(30, 110))
	prop("p_novelos", Vector2(w - 30, 112), false)
	prop("i_rack", Vector2(w / 2.0 + 30, 132), false)
	prop("p_vaso_flores", Vector2(w / 2.0 + 6, 96), false)
	shop_owner("costureira", "costureira", "Rosa", Vector2(w / 2.0 + 20, 92), h["lines"])
	spot("Guarda-roupa da Rosa", Vector2(w - 40, 86), func() -> void: HUD.open_window("guarda_roupa"), 18.0)
	light(Vector2(w / 2.0, 90), Color(1.0, 0.8, 0.55), 1.4, 0.3)


func _build_inn(h: Dictionary, w: float) -> void:
	wall("p_janela", 60, 28)
	wall("p_janela", w - 60, 28)
	wall("i_painting", w / 2.0 - 90, 26)
	prop("furn_lareira", Vector2(w / 2.0, 58), true)
	light(Vector2(w / 2.0, 50), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	# quartos: camas separadas por estantes
	for x in [26.0, 62.0, w - 62.0, w - 26.0]:
		prop("p_cama_simples", Vector2(x, 104))
	prop("i_shelf_s", Vector2(44, 128), false)
	prop("i_shelf_s", Vector2(w - 44, 128), false)
	# recepção
	prop("i_counter", Vector2(w / 2.0 - 20, 128))
	prop("i_counter", Vector2(w / 2.0 + 25, 128))
	prop("p_vela", Vector2(w / 2.0 - 10, 120), false)
	shop_owner("estalajadeiro", "estalajadeiro", "Bento", Vector2(w / 2.0, 108), h["lines"])
	table_set(Vector2(w / 2.0 - 60, 176), true, "i_mug", true)
	table_set(Vector2(w / 2.0 + 60, 176), false, "i_bowl1", false)
	sitter("aventureiro_samurai", Vector2(w / 2.0 + 76, 182), "left", ["Amanhã sigo para a Mata.", "Ouvi luzes no Pântano."])
	prop("p_banco", Vector2(w / 2.0, 206))
	prop("i_barrel", Vector2(24, 200))
	prop("i_barrel2", Vector2(w - 24, 200))
	light(Vector2(w / 2.0, 150), Color(1.0, 0.8, 0.55), 2.0, 0.28)


func _build_lin(h: Dictionary, w: float) -> void:
	prop("i_bookshelf_s", Vector2(36, 62), false)
	prop("i_bookshelf_s", Vector2(w - 36, 62), false)
	wall("p_janela", w / 2.0 - 52, 28)
	prop("h_estatua_pequena", Vector2(w / 2.0, 66), true)
	prop("p_tapete_azul", Vector2(w / 2.0, 128), false, true)
	for p in [Vector2(-34, 96), Vector2(34, 96), Vector2(-34, 136), Vector2(34, 136)]:
		prop("p_vela", Vector2(w / 2.0, 0) + p, false)
		light(Vector2(w / 2.0, -6) + p, Color(1.0, 0.75, 0.45), 0.45, 0.5)
	prop("p_cha", Vector2(w / 2.0 + 50, 120), false)
	prop("p_livros", Vector2(30, 120), false)
	prop("p_planta_pequena", Vector2(w - 22, 136), false)
	# Lin só está em casa quando a história não o colocou na floresta ou na Guilda
	var away := Story.chapter() >= 3 or Story.step() in ["c2_lin", "c2_carta", "c2_ruinas", "c2_sentinela"]
	if away:
		prop("i_desk_paper", Vector2(w / 2.0 + 30, 120), false)
		spot("Ler o bilhete na mesa", Vector2(w / 2.0 + 30, 132), func() -> void:
			var where := "na Guilda" if Story.chapter() >= 3 else "perto da ponte da Mata Profunda"
			await Story.say([["narr", "Um bilhete com letra caprichada: \"Saí. Estou %s. Respire antes de me procurar. - Lin\"" % where]]), 20.0)
	else:
		var lin := npc(h["npc"], Vector2(w / 2.0, 112), h["lines"], "static")
		StoryProp.talker(lin, "lin", "Mestre Lin")
	Audio.emitter(world, Vector2(w / 2.0, 60), "amb_relogio", -20.0, true, 0.0, 120.0)


func _build_dojo(h: Dictionary, w: float) -> void:
	wall("p_estandarte", 40, 34)
	wall("p_estandarte_azul", w - 40, 34)
	wall("p_escudos_parede", w / 2.0 + 90, 28)
	prop("p_lancas", Vector2(80, 64), false)
	prop("p_rack_espadas", Vector2(w - 90, 64), false)
	prop("p_tatame", Vector2(w / 2.0 - 40, 150), false, true)
	prop("p_tatame", Vector2(w / 2.0 + 40, 150), false, true)
	for x in [60.0, w - 60.0, w / 2.0]:
		prop("p_boneco_treino", Vector2(x, 112))
	shop_owner("mestre_cla", "mestre_cla", "Mestre Daichi", Vector2(w / 2.0, 86), h["lines"])
	var pupil := npc("aventureira_lutadora", Vector2(70, 140), ["Mais um golpe!", "Hah!"], "static")
	var t := Timer.new()
	t.wait_time = 1.8
	t.autostart = true
	pupil.add_child(t)
	t.timeout.connect(func() -> void:
		if pupil.actor != null and not pupil.talking:
			pupil.play_anim("idle_up")
			pupil.actor.gesture()
			Audio.sfx("swing1", -22.0, 0.1))
	prop("p_banco", Vector2(w / 2.0, 200))
	prop("i_barrel", Vector2(24, 196))
	light(Vector2(w / 2.0, 120), Color(1.0, 0.8, 0.55), 2.2, 0.28)
