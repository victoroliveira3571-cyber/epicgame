extends Node2D

## v3.7 (pedido do Victor): o campus da Academia de Fontelúcida é um castelo grande. Do lado de fora fica o
## pátio com o jardim das provas; por dentro, este mapa de corredores (no jeito das masmorras, com outro traçado)
## com portas para as salas: Reitoria, Grande Biblioteca, Secretaria, Sala de Aula, Sala do Bibliotecário,
## Refeitório, Alojamento dos Mestres, Meu Quarto, Dormitório, Sala Comum e Laboratório de Alquimia.
## Cada porta leva a um Interior (Interior.gd, ids "acad_*"); ao sair da sala o herói volta para a frente da porta.
## Mesma interface de minimapa e mapa grande que Town/City (grupo "town": W, H, T, minimap_tex, buildings,
## map_landmarks). PROVISÓRIO: chão e paredes do estilo de masmorra (assets/dungeon) até um tileset de castelo.

const W := 50
const H := 36
const T := 16
const STYLE := 1                 # estilo de pedra azul-acinzentada dos tiles de masmorra

## Corredores (retângulos em tiles, inclusivos): x0, y0, x1, y1.
const HALLS := [
	[21, 27, 28, 33],   # saguão de entrada
	[23, 5, 26, 27],    # corredor central (norte-sul)
	[4, 5, 45, 7],      # corredor de cima
	[4, 15, 45, 17],    # corredor do meio
	[4, 25, 45, 27],    # corredor de baixo
	[4, 5, 6, 27],      # ala oeste
	[43, 5, 45, 27],    # ala leste
]
## Portas na parede de cima de cada corredor: id do interior, nome, coluna, linha da parede (a face).
const DOORS := [
	["acad_reitoria", "Reitoria", 24, 4, 2],
	["biblioteca", "Grande Biblioteca", 13, 4, 1],
	["acad_secretaria", "Secretaria", 35, 4, 1],
	["acad_aula", "Sala de Aula", 11, 14, 1],
	["acad_bibliotecario", "Sala do Bibliotecário", 17, 14, 1],
	["acad_refeitorio", "Refeitório", 32, 14, 1],
	["acad_alojamento", "Alojamento dos Mestres", 38, 14, 1],
	["acad_quarto", "Meu Quarto", 10, 24, 1],
	["acad_dormitorio", "Dormitório", 16, 24, 1],
	["acad_comum", "Sala Comum", 33, 24, 1],
	["acad_lab", "Laboratório de Alquimia", 39, 24, 1],
]
## Ids de landmark que a história usa (StoryV4.TARGETS) -> porta.
const STORY_IDS := {"reitoria": "acad_reitoria", "classe": "acad_aula", "sala_aula": "acad_aula", "biblioteca": "biblioteca"}

var rng := RandomNumberGenerator.new()
var world: Node2D
var player: Player
var buildings: Dictionary = {}       # minimapa: um marcador por porta
var minimap_tex: Texture2D
var cells := PackedByteArray()
var door_spawns: Dictionary = {}
var _leaving: bool = false


func _ready() -> void:
	rng.seed = 7341
	add_to_group("town")
	add_to_group("castle")
	_build_cells()
	var room_of := PackedInt32Array()
	room_of.resize(W * H)
	room_of.fill(0)
	var img := TileComposer.compose_dungeon(cells, W, H, STYLE, room_of, rng)
	_paint_carpets(img)
	_paint_doors(img)
	var small := img.duplicate() as Image
	small.resize(W * 2, H * 2, Image.INTERPOLATE_BILINEAR)
	minimap_tex = ImageTexture.create_from_image(small)
	var ground := Sprite2D.new()
	ground.texture = ImageTexture.create_from_image(img)
	ground.centered = false
	ground.z_index = -100
	add_child(ground)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_build_colliders()
	_build_doors()
	_build_decor()
	_build_npcs()
	_spawn_player()
	var mod := CanvasModulate.new()
	mod.color = Color(0.92, 0.88, 0.84)
	add_child(mod)
	Audio.play_music("interior_manor")
	Audio.set_place_loop("")
	HUD.on_scene_ready("town")


func _process(_delta: float) -> void:
	if player == null or _leaving:
		return
	var p := player.global_position
	if p.y > (H - 2) * T + 4 and absf(p.x - 25 * T) < 2.5 * T:
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	Audio.sfx("ui_close", -4.0)
	Game.go_to_city("academia", "door:castelo")


# ================================================================== Mapa
func _idx(x: int, y: int) -> int:
	return y * W + x


func _build_cells() -> void:
	cells.resize(W * H)
	cells.fill(0)
	for r in HALLS:
		for y in range(int(r[1]), int(r[3]) + 1):
			for x in range(int(r[0]), int(r[2]) + 1):
				cells[_idx(x, y)] = 1
	# saída: vão na parede de baixo do saguão
	for x in [24, 25]:
		cells[_idx(x, 34)] = 1


func is_floor(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H and cells[_idx(x, y)] == 1


## Tapete vermelho com friso dourado no meio dos corredores (como num salão de castelo).
func _paint_carpets(img: Image) -> void:
	var red := Color("7a1e22")
	var gold := Color("d8a23a")
	# corredor central (vertical, 2 tiles de largura) até a porta da Reitoria
	var vx0 := 24 * T + 3
	var vx1 := 26 * T - 3
	img.fill_rect(Rect2i(vx0, 5 * T, vx1 - vx0, 30 * T), red)
	img.fill_rect(Rect2i(vx0 + 1, 5 * T, 1, 30 * T), gold)
	img.fill_rect(Rect2i(vx1 - 2, 5 * T, 1, 30 * T), gold)
	# corredores de cima, do meio e de baixo (horizontais, 1 tile)
	for ry in [6, 16, 26]:
		var y0: int = int(ry) * T + 3
		var y1: int = (int(ry) + 1) * T - 3
		img.fill_rect(Rect2i(7 * T, y0, 36 * T, y1 - y0), red)
		img.fill_rect(Rect2i(7 * T, y0 + 1, 36 * T, 1), gold)
		img.fill_rect(Rect2i(7 * T, y1 - 2, 36 * T, 1), gold)


## Portas de madeira desenhadas na face da parede (TilesetElement do Ninja), com moldura escura.
func _paint_doors(img: Image) -> void:
	var el := TileComposer.tileset("TilesetElement")
	for d in DOORS:
		var x0 := int(d[2])
		var fy := int(d[3])
		var n := int(d[4])
		for k in n:
			var dx := (x0 + k) * T
			img.fill_rect(Rect2i(dx, fy * T, T, T), Color("2a1a14"))
			img.blend_rect(el, Rect2i(8 * T, 13 * T, T, T), Vector2i(dx, fy * T))


func _build_colliders() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	for y in H:
		var x := 0
		while x < W:
			if cells[_idx(x, y)] == 0:
				var x0 := x
				while x < W and cells[_idx(x, y)] == 0:
					x += 1
				var c := CollisionShape2D.new()
				var s := RectangleShape2D.new()
				s.size = Vector2((x - x0) * T, T)
				c.shape = s
				c.position = Vector2(x0 * T + (x - x0) * T / 2.0, y * T + T / 2.0)
				body.add_child(c)
			else:
				x += 1
	# fecha o vão da saída por baixo (quem passa dele sai do castelo)
	var c2 := CollisionShape2D.new()
	var s2 := RectangleShape2D.new()
	s2.size = Vector2(2 * T, 8)
	c2.shape = s2
	c2.position = Vector2(25 * T, H * T + 4)
	body.add_child(c2)


# ================================================================== Portas
func _build_doors() -> void:
	for d in DOORS:
		var id := str(d[0])
		var title := str(d[1])
		var cx := (int(d[2]) + int(d[4]) / 2.0) * T
		var fy := int(d[3])
		var foot := Vector2(cx, (fy + 1) * T + 12)
		door_spawns[id] = foot + Vector2(0, 12)
		var sp := Interior.Spot.new("Entrar: " + title, func() -> void:
			Audio.novo("entrar_casa", -4.0, 0.0)
			Game.enter_interior(id, "castle"), 20.0)
		sp.position = foot
		world.add_child(sp)
		var marker := Node2D.new()
		marker.position = Vector2(cx, (fy + 1) * T)
		marker.set("display_name", title)
		add_child(marker)
		buildings[id] = marker
		var l := UI.label(title, Color("ffe7b0"), 0)
		l.add_theme_font_size_override("font_size", 8)
		l.add_theme_color_override("font_outline_color", Color("1a1014"))
		l.add_theme_constant_override("outline_size", 3)
		l.size = Vector2(110, 10)
		l.position = Vector2(cx - 55, fy * T - 12)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.z_index = 60
		add_child(l)
		# tochas dos dois lados de cada porta
		for side in [-1.0, 1.0]:
			_wall_prop("p_tocha_parede", Vector2(cx + side * (12.0 + 8.0 * (int(d[4]) - 1)), (fy + 1) * T - 1))
			Fx.make_light(world, Vector2(cx + side * (12.0 + 8.0 * (int(d[4]) - 1)), fy * T + 2), Color(1.0, 0.6, 0.3), 0.55, 0.75)


func _wall_prop(name: String, foot: Vector2) -> Node2D:
	var tex := Interior.prop_tex(name)
	var holder := Node2D.new()
	holder.position = foot.round()
	holder.z_index = -50
	add_child(holder)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var sz := tex.get_size() if tex != null else Vector2(16, 16)
	s.offset = Vector2(-sz.x / 2.0, -sz.y)
	holder.add_child(s)
	return holder


func _prop(name: String, foot: Vector2, radius: float = 0.0) -> Node2D:
	var tex := Interior.prop_tex(name)
	var holder := Node2D.new()
	holder.position = foot.round()
	world.add_child(holder)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var sz := tex.get_size() if tex != null else Vector2(16, 16)
	s.offset = Vector2(-sz.x / 2.0, -sz.y)
	holder.add_child(s)
	if radius > 0.0:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var c := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius
		c.shape = circle
		c.position = Vector2(0, -radius)
		body.add_child(c)
		holder.add_child(body)
	return holder


# ================================================================== Decoração e gente
func _build_decor() -> void:
	# estandartes e janelas nas paredes dos corredores, longe das portas
	var used: Array = []
	for d in DOORS:
		for k in range(-2, int(d[4]) + 2):
			used.append(Vector2i(int(d[2]) + k, int(d[3])))
	for fy in [4, 14, 24]:
		for x in range(8, 42, 4):
			if Vector2i(x, fy) in used or (x >= 22 and x <= 27):
				continue
			var name := "p_estandarte_azul" if (x / 4) % 2 == 0 else "p_janela"
			_wall_prop(name, Vector2(x * T + 8, (fy + 1) * T - 1))
	# saguão: estátuas do fundador, plantas, bancos e o mural
	_prop("h_estatua_pequena_verde", Vector2(22 * T + 8, 29 * T), 6.0)
	_prop("h_estatua_pequena_verde", Vector2(27 * T + 8, 29 * T), 6.0)
	for pp in [Vector2(21, 33), Vector2(28, 33), Vector2(4, 27), Vector2(45, 27), Vector2(4, 5), Vector2(45, 5)]:
		_prop("furn_planta", Vector2(pp.x * T + 8, pp.y * T + 14), 4.0)
	_prop("p_banco", Vector2(22 * T + 8, 32 * T + 12), 0.0)
	_prop("p_banco", Vector2(27 * T + 8, 32 * T + 12), 0.0)
	_prop("quadro_missoes", Vector2(26 * T, 27 * T + 10), 0.0)
	var board := Interior.Spot.new("Ler o mural da Academia", func() -> void: _read_board(), 20.0)
	board.position = Vector2(26 * T, 28 * T + 4)
	world.add_child(board)
	for lx in [8, 20, 30, 41]:
		_prop("lampiao", Vector2(lx * T + 8, 17 * T + 14), 0.0)
		Fx.make_light(world, Vector2(lx * T + 8, 17 * T), Color(1.0, 0.78, 0.45), 0.6, 0.45)
	var title := UI.label("Castelo de Fontelúcida", Color("e4dcff"), 1)
	title.size = Vector2(240, 14)
	title.position = Vector2(25 * T - 120, 30 * T + 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("101828"))
	title.add_theme_constant_override("outline_size", 3)
	title.z_index = 60
	add_child(title)


func _read_board() -> void:
	var lines: Array = [["narr", "MURAL DA ACADEMIA: \"Reitoria no fim do corredor central. Aulas na Sala de Aula, corredor do meio. Refeitório aberto o dia todo.\""]]
	if Story.in_academy_act():
		lines.append(["narr", "Seu objetivo agora: " + Story.objective_text()])
	lines.append(["narr", "Embaixo, alguém escreveu a lápis: \"Quem estuda um pouco todo dia não precisa virar a noite.\""])
	await Story.say(lines)


func _build_npcs() -> void:
	var ways: Array = []
	for r in HALLS:
		ways.append(Vector2((int(r[0]) + int(r[2]) + 1) * T / 2.0, (int(r[1]) + int(r[3]) + 1) * T / 2.0))
	var guard := NPC.new()
	guard.custom_look = Ally.look_of("soldado")
	guard.mode = "static"
	guard.position = Vector2(21 * T + 8, 31 * T)
	guard.lines = ["Bem-vind" + ("a" if str(Story.st().get("gender", "m")) == "f" else "o") + " ao Castelo de Fontelúcida.", "As salas têm o nome em cima da porta.", "Correr no corredor, só em dia de prova."]
	world.add_child(guard)
	var people := [
		["Boy", Vector2(10, 16), ["Atrasado para a aula do Mestre Lin!", "Você viu meu caderno?"]],
		["Villager4", Vector2(36, 6), ["A Secretaria só abre o horário depois do almoço.", "Fiz 4 pomodoros hoje!"]],
		["Woman", Vector2(30, 26), ["O dormitório é silencioso de tarde. Ótimo para revisar.", "A Sala Comum tem lareira no inverno."]],
		["OldMan", Vector2(40, 16), ["No meu tempo, a Reitoria era uma sala de mapas.", "Respire antes de responder."]],
		["Child", Vector2(20, 26), ["Por que o castelo tem tantas portas?", "Eu quero ser professora!"]],
		["Monk", Vector2(5, 12), ["Silêncio também é estudo.", "A biblioteca guarda livros mais velhos que o castelo."]],
		["Villager2", Vector2(44, 20), ["O refeitório hoje tem sopa de abóbora.", "Ainda me perco nesses corredores."]],
	]
	for p in people:
		var n := NPC.create(world, str(p[0]), Vector2((p[1] as Vector2).x * T + 8, (p[1] as Vector2).y * T + 8), "wander")
		n.lines = p[2]
		n.wander_points = ways
		n.wander_radius = 90.0
		n.move_speed = 16.0


# ================================================================== Jogador e mapa
func _spawn_player() -> void:
	var spawn := Vector2(25 * T, 32 * T)
	if Game.castle_spawn.begins_with("door:"):
		spawn = door_spawns.get(Game.castle_spawn.substr(5), spawn)
	player = Player.spawn(world, spawn)
	player.facing = Vector2.UP
	player.set_camera_limits(Rect2(0, 0, W * T, H * T))


func map_landmarks() -> Array:
	var out: Array = []
	for d in DOORS:
		var pos: Vector2 = door_spawns.get(str(d[0]), Vector2.ZERO)
		out.append([str(d[0]), str(d[1]), pos])
	for sid in STORY_IDS:
		out.append([str(sid), "", door_spawns.get(STORY_IDS[sid], Vector2.ZERO)])
	out.append(["saida_castelo", "Saída para o pátio", Vector2(25 * T, (H - 1) * T)])
	return out


## Alvo que não está dentro do castelo (jardim, estação...): a seta aponta para a saída.
func objective_fallback(_id: String) -> Variant:
	return Vector2(25 * T, (H - 1) * T)
