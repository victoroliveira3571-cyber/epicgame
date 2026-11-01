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
	{"title": "Ateliê da Costureira", "npc": "costureira", "floor": "floor_wood", "wall": "wall_cream", "size": Vector2i(16, 12),
		"lines": ["Entre! Cuidado com os alfinetes.", "Capa nova? Volte quando juntar fichas de estilo.", "A Dona Marta manda lembranças."]},
	{"title": "Estalagem do Viajante", "npc": "estalajadeiro", "floor": "floor_wood_dark", "wall": "wall_red", "size": Vector2i(26, 17),
		"lines": ["Os quartos estão cheios hoje!", "Quem sobe a masmorra dorme melhor.", "Já ouvi histórias do chefe do andar 5."]},
	{"title": "Casa do Mestre Lin", "npc": "Master", "floor": "floor_stone", "wall": "wall_stone", "size": Vector2i(16, 10),
		"lines": ["Respire fundo. Um pomodoro por vez.", "A mente calma corta mais fundo.", "Hoje meditei por 25 minutos."]},
	{"title": "Salão do Clã", "npc": "mestre_cla", "floor": "floor_wood_dark", "wall": "wall_red", "size": Vector2i(26, 14),
		"lines": ["Aqui treinamos de madrugada.", "Honra vem da disciplina.", "Mostre o que você aprendeu na Arena."]},
]

## Tamanho de cada sala (tiles) e pisos.
const ROOMS := {
	"casa": [24, 14, "floor_wood", "wall_cream"], "restaurante": [28, 16, "floor_wood_dark", "wall_red"],
	"guilda": [32, 18, "floor_stone", "wall_stone"], "biblioteca": [30, 17, "floor_wood_dark", "wall_cream"],
	"casa_familia": [20, 12, "floor_wood", "wall_cream"], "casa_pai": [16, 10, "floor_wood_dark", "wall_stone"],
	"forja": [18, 11, "floor_stone", "wall_stone"], "loja": [20, 13, "floor_wood", "wall_red"],
	"arena": [30, 18, "floor_sand", "wall_stone"], "delegacia": [22, 13, "floor_stone", "wall_stone"],
	"laboratorio": [24, 14, "floor_stone", "wall_cream"],
	# v3.7: salas dos turnos de ofício (WorkShift)
	"turno_cozinha": [22, 13, "floor_wood_dark", "wall_red"], "turno_forja": [22, 13, "floor_stone", "wall_stone"],
	# v3.7: salas do Castelo de Fontelúcida (AcademyCastle)
	"acad_reitoria": [20, 12, "floor_wood_dark", "wall_stone"], "acad_aula": [24, 14, "floor_wood", "wall_cream"],
	"acad_secretaria": [16, 11, "floor_wood", "wall_cream"], "acad_bibliotecario": [14, 10, "floor_wood_dark", "wall_cream"],
	"acad_refeitorio": [26, 15, "floor_stone", "wall_red"], "acad_alojamento": [18, 11, "floor_wood_dark", "wall_stone"],
	"acad_quarto": [12, 9, "floor_wood", "wall_cream"], "acad_dormitorio": [22, 12, "floor_wood", "wall_cream"],
	"acad_comum": [20, 12, "floor_wood_dark", "wall_red"], "acad_lab": [18, 11, "floor_stone", "wall_stone"],
	# v3.7: sala do trono de Pedralta e a cabana do Pietro (antes eram portas trancadas)
	"castelo_rocuetos": [24, 15, "floor_stone", "wall_stone"], "cabana_pietro": [16, 10, "floor_wood_dark", "wall_stone"],
}
## v3.7: casas de morador das cidades (Interior "morador_<cidade>_<prédio>"): piso/parede por região e falas.
const MORADOR_STYLE := {
	"porto": ["floor_wood", "wall_cream"], "pedralta": ["floor_stone", "wall_stone"],
	"vila_neve": ["floor_wood_dark", "wall_stone"], "oasis": ["floor_sand", "wall_cream"],
}
const MORADOR_LINES := {
	"porto": ["A maré hoje está boa para a pesca.", "Feche a porta, o vento do mar entra!", "Meu avô dizia: rede remendada pesca mais.", "O Capitão Maré conta histórias no cais."],
	"pedralta": ["Aqui em cima o fogo da lareira nunca apaga.", "Meu martelo tem mais anos que você.", "Rocuetos se ergue de pedra e disciplina.", "O sino da forja marca as horas da cidade."],
	"vila_neve": ["Tire a neve das botas, por favor.", "Dizem que o Pé Grande uiva nas noites sem lua.", "Chá quente e cobertor: o segredo do inverno.", "O Ancião sabe tudo sobre a caverna."],
	"oasis": ["Água é ouro por aqui.", "As caravanas chegam no fim da tarde.", "Sombra boa, conversa boa.", "Cuidado com as cobras perto das dunas."],
}
const MORADOR_SHEETS := ["Villager", "Villager2", "Villager3", "Villager4", "Woman", "OldMan", "OldWoman", "Boy"]
const ACAD_TITLES := {
	"acad_reitoria": "Reitoria", "acad_aula": "Sala de Aula", "acad_secretaria": "Secretaria da Academia",
	"acad_bibliotecario": "Sala do Bibliotecário", "acad_refeitorio": "Refeitório", "acad_alojamento": "Alojamento dos Mestres",
	"acad_quarto": "Meu Quarto", "acad_dormitorio": "Dormitório", "acad_comum": "Sala Comum", "acad_lab": "Laboratório de Alquimia",
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
## v3.7 (referência do Victor, casa com vários cômodos): paredes internas por sala, em tiles.
## {"h": [x0, x1, y]} = parede de frente (2 tiles de altura, com o friso em cima); {"v": [x, y0, y1]} = parede fina.
const PARTITIONS := {
	"casa_npc_1": [{"h": [1, 3, 7]}, {"h": [6, 11, 7]}, {"h": [14, 19, 7]}, {"h": [22, 24, 7]},
		{"v": [8, 2, 6]}, {"v": [16, 2, 6]}],
}
var partitions: Array = []
var owner_npc: NPC = null


## Textura de um móvel/objeto: primeiro assets/custom/props (arte própria), depois assets/ninja/props.
static func prop_tex(name: String) -> Texture2D:
	if BuildingFactory.is_factory_name(name):
		return BuildingFactory.texture(name)
	if name.begins_with("tile_") or name.begins_with("plot_") or name.begins_with("counterv_") or name.begins_with("descstairs_"):
		return _tileset_prop(name)
	var custom := "res://assets/custom/props/%s.png" % name
	if ResourceLoader.exists(custom):
		return load(custom)
	return Pix.tex("props/%s.png" % name)


static var _tileset_cache: Dictionary = {}


## v3.7: peças recortadas direto dos tilesets do Ninja Adventure.
##   "tile_<Tileset>_<x>_<y>_<w>_<h>" = região do tileset (em tiles), ex. "tile_TilesetHouse_29_20_3_3" (arco de pedra);
##   "plot_<w>_<h>" = canteiro de horta (terra arada do TilesetField em 9 partes, com a borda da frente);
##   "counterv_<px>" = balcão lateral (de pé), recortado das pontas do balcão i_counter do Ninja;
##   "descstairs_<w>_<h>" = escada descendo para o escuro (degraus da ponte de pedra + degradê), entrada de masmorra.
static func _tileset_prop(name: String) -> Texture2D:
	if _tileset_cache.has(name):
		return _tileset_cache[name]
	var p := name.split("_")
	var img: Image = null
	if p[0] == "tile" and p.size() >= 6:
		var src := TileComposer.tileset(p[1])
		if src != null:
			img = src.get_region(Rect2i(int(p[2]) * T, int(p[3]) * T, int(p[4]) * T, int(p[5]) * T))
	elif p[0] == "counterv" and p.size() >= 2:
		var hpx := maxi(int(p[1]), 8)
		var ct: Texture2D = Pix.tex("props/i_counter.png")
		if ct != null:
			var src_c := ct.get_image()
			src_c.convert(Image.FORMAT_RGBA8)
			var cw := src_c.get_width()
			img = Image.create(10, hpx, false, Image.FORMAT_RGBA8)
			for y in hpx:
				var sy := 0 if y == 0 else (7 if y % 12 == 6 else 4)
				for x in 10:
					var sx := x if x < 5 else cw - 10 + x
					img.set_pixel(x, y, src_c.get_pixel(sx, sy))
	elif p[0] == "descstairs" and p.size() >= 3:
		var sw := int(p[1])
		var sh := int(p[2])
		var house := TileComposer.tileset("TilesetHouse")
		img = Image.create(sw, sh, false, Image.FORMAT_RGBA8)
		var x_src := 11 * T + (32 - sw) / 2
		for y in sh:
			var row := 19 * T + 4 + (y % 32)
			var k := clampf(1.0 - float(y) / float(sh), 0.0, 1.0)
			var dark := 0.18 + 0.8 * pow(k, 1.3)
			for x in sw:
				var c := house.get_pixel(x_src + x, row)
				var edge := 0.25 if (x < 2 or x >= sw - 2) else 0.0
				c = c.darkened(clampf(dark + edge, 0.0, 0.97))
				c.a = 1.0
				img.set_pixel(x, y, c)
	elif p[0] == "plot" and p.size() >= 3:
		var wt := maxi(int(p[1]), 2)
		var ht := maxi(int(p[2]), 2)
		var field := TileComposer.tileset("TilesetField")
		img = Image.create(wt * T, ht * T, false, Image.FORMAT_RGBA8)
		for y in ht:
			for x in wt:
				var sx := 0 if x == 0 else (2 if x == wt - 1 else 1)
				var sy := 0 if y == 0 else (2 if y == ht - 1 else 1)
				img.blit_rect(field, Rect2i(sx * T, sy * T, T, T), Vector2i(x * T, y * T))
	var tex: Texture2D = ImageTexture.create_from_image(img) if img != null else null
	_tileset_cache[name] = tex
	return tex


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
	elif id.begins_with("turno_"):
		WorkShift.attach(self)
	elif id.begins_with("acad_"):
		_build_academy_room()
	elif id.begins_with("morador_"):
		_build_morador()
	elif id == "castelo_rocuetos":
		_build_throne_room()
	elif id == "cabana_pietro":
		_build_pietro_cabin()
	else:
		_build_resident_house()
	_spawn_player()
	var mod := CanvasModulate.new()
	mod.color = Color(0.72, 0.7, 0.76) if id == "casa_pai" else Color(1.0, 0.94, 0.86)
	add_child(mod)
	Audio.play_music("musica_laboratorio" if id == "laboratorio" else ("interior_taverna" if id in ["restaurante", "casa_npc_1", "turno_cozinha"] else ("home" if id == "casa_familia" else "interior_manor")))
	Audio.set_place_loop("biblioteca_escrita" if id == "biblioteca" else ("ferraria_ambiente" if id in ["forja", "turno_forja"] else ("lareira_casa" if id.begins_with("casa") else "")))
	HUD.on_scene_ready("interior")
	if id == "casa_familia" and Story.step() == "p_prologo":
		Prologue.start(self)
	elif id == "casa_familia" and Story.step() in ["c1_casa", "a_casa"]:
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
	partitions = PARTITIONS.get(id, [])
	if id.begins_with("morador_"):
		var hh := absi(hash(id))
		var city := id.split("_")[1] if id.split("_").size() > 1 else "porto"
		var st: Array = MORADOR_STYLE.get(city, ["floor_wood", "wall_cream"])
		cols = 14 + hh % 5
		rows = 9 + (hh / 7) % 3
		floor_tex = str(st[0])
		wall_tex = str(st[1])
		return
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
	_draw_partitions(img, wall_img, edge, lip)
	# tapete de entrada na porta
	img.fill_rect(Rect2i(door_x0 + 2, (rows - 1) * T - 5, DOOR_W * T - 4, 5), Color("7a3a34"))
	img.fill_rect(Rect2i(door_x0 + 2, (rows - 1) * T - 5, DOOR_W * T - 4, 1), Color("b25a4a"))
	return img


## Paredes internas: a de frente repete a textura da parede de cima (2 tiles) com um friso escuro por cima e
## sombra no piso; a fina é uma viga escura vista de cima com friso claro dos dois lados.
func _draw_partitions(img: Image, wall_img: Image, edge: Color, lip: Color) -> void:
	for p in partitions:
		if (p as Dictionary).has("h"):
			var a: Array = p["h"]
			var x0 := int(a[0]) * T
			var x1 := (int(a[1]) + 1) * T
			var y := int(a[2]) * T
			for x in range(int(a[0]), int(a[1]) + 1):
				img.blit_rect(wall_img, Rect2i(0, 0, T, T * WALL_H), Vector2i(x * T, y))
			img.fill_rect(Rect2i(x0, y - 4, x1 - x0, 4), edge)
			img.fill_rect(Rect2i(x0, y - 1, x1 - x0, 1), lip)
			for i in 5:
				var dk := 0.28 - float(i) * 0.05
				for px in range(x0, x1):
					var pv := Vector2i(px, y + WALL_H * T + i)
					if pv.y < img.get_height():
						img.set_pixelv(pv, img.get_pixelv(pv).darkened(dk))
		else:
			var v: Array = p["v"]
			var vx := int(v[0]) * T + 4
			var vy0 := int(v[1]) * T - 4
			var vh := (int(v[2]) - int(v[1]) + 1) * T + 4
			img.fill_rect(Rect2i(vx, vy0, 8, vh), edge)
			img.fill_rect(Rect2i(vx, vy0, 1, vh), lip)
			img.fill_rect(Rect2i(vx + 7, vy0, 1, vh), lip)


func _block_partitions() -> void:
	for p in partitions:
		if (p as Dictionary).has("h"):
			var a: Array = p["h"]
			_block(Rect2(int(a[0]) * T, int(a[2]) * T - 4, (int(a[1]) - int(a[0]) + 1) * T, WALL_H * T + 2))
		else:
			var v: Array = p["v"]
			_block(Rect2(int(v[0]) * T + 4, int(v[1]) * T - 4, 8, (int(v[2]) - int(v[1]) + 1) * T + 4))


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
	_block_partitions()


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
	if id.begins_with("turno_"):
		player.global_position.y -= 18.0
		for c in get_children():
			if c is WorkShift:
				(c as WorkShift).request_exit()
		return
	if id == "casa_familia" and Story.step() in ["c1_casa", "a_casa", "p_prologo"]:
		HUD.set_prompt("")
		HUD.show_toast("Fale com %s antes de partir." % Story.fmt("{mae}"), UI.C_ORANGE_L)
		player.global_position.y -= 18.0
		return
	_ending = true
	Audio.sfx("ui_close", -4.0)
	# prólogo: da casa da família a trilha leva direto a Focus Town
	if id == "casa_familia" and not Story.flag("saiu_casa"):
		Story.set_flag("saiu_casa")
		await Story.say(StoryV4.SAIDA_CASA if Story.step() == "a_viagem" else StoryData.DIALOGS["c1_saida"])
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


## v3.7 (pedido do Victor): balcão fechado dos lados. `n` peças de balcão na frente (linha `front_y`) e duas
## laterais que voltam até a parede ou divisória de trás (`back_y`), com colisão no retângulo inteiro: quem atende
## fica "dentro" do balcão, como nas referências.
func booth(cx: float, front_y: float, back_y: float, n: int = 2) -> void:
	var pw := 45.0
	var total := n * pw
	var x0 := cx - total / 2.0
	for i in n:
		prop("i_counter", Vector2(x0 + pw * (i + 0.5), front_y), false)
	var side_len := int(front_y - 10.0 - back_y)
	if side_len > 8:
		for sx in [x0 + 5.0, x0 + total - 5.0]:
			prop("counterv_%d" % side_len, Vector2(sx, front_y - 8.0), false)
	_block(Rect2(x0, back_y, total, front_y - back_y))


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


## v3.7: raio de sol (ou de lua, à noite) entrando pela janela: luz aditiva inclinada com poeira no ar.
func sunbeam(x: float, length: float = 110.0, width: float = 22.0) -> void:
	var hour := float(Time.get_time_dict_from_system()["hour"])
	var day := hour >= 7.0 and hour < 18.0
	var col := Color(1.0, 0.9, 0.62) if day else Color(0.62, 0.72, 1.0)
	var a := 0.16 if day else 0.07
	var top := 36.0
	var slant := length * 0.32
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(x - width / 2.0, top), Vector2(x + width / 2.0, top),
		Vector2(x + width / 2.0 + slant + 8.0, top + length), Vector2(x - width / 2.0 + slant - 8.0, top + length)])
	poly.vertex_colors = PackedColorArray([Color(col, a), Color(col, a), Color(col, a * 0.2), Color(col, a * 0.2)])
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	poly.material = mat
	poly.z_index = 20
	add_child(poly)
	if not day:
		return
	var dust := CPUParticles2D.new()
	dust.position = Vector2(x + slant * 0.5, top + length * 0.5)
	dust.z_index = 21
	dust.amount = 7
	dust.lifetime = 5.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(width * 0.5, length * 0.4)
	dust.direction = Vector2(0.3, 1)
	dust.spread = 40.0
	dust.initial_velocity_min = 1.0
	dust.initial_velocity_max = 4.0
	dust.gravity = Vector2.ZERO
	dust.color = Color(1.0, 0.95, 0.8, 0.55)
	add_child(dust)


## Plaquinha com o nome da seção/cômodo (texto pequeno no friso da parede).
func _section_label(text: String, x: float, y: float = 20.0) -> void:
	var l := UI.label(text, Color("ffe7b0"), 0)
	l.size = Vector2(90, 10)
	l.position = Vector2(x - 45, y - 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_outline_color", Color("2a1a14"))
	l.add_theme_constant_override("outline_size", 3)
	l.z_index = 50
	add_child(l)


## Bicho dormindo (gato da loja, pets que ficaram em casa): primeiro quadro do sprite do pack, respiração
## lenta e "z" subindo. `sheet_rel` = folha do pack (animals/*.png com 2 quadros ou folha de ator 4 direções).
func sleeping_pet(sheet_rel: String, pos: Vector2, cushion: bool = true, tint: Color = Color.WHITE) -> Node2D:
	if cushion:
		prop("lpc_pufe", pos + Vector2(0, 4), false, true)   # no chão (sob o bicho)
	var holder := Node2D.new()
	holder.position = pos
	world.add_child(holder)
	var tex := Pix.tex(sheet_rel)
	var spr := Sprite2D.new()
	if tex != null and tex.get_height() <= 20:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, 0, tex.get_height(), tex.get_height())
		spr.texture = at
	else:
		spr.texture = Pix.atlas(sheet_rel, Rect2(0, 0, 16, 16))
	spr.offset = Vector2(0, -7)
	spr.modulate = tint
	holder.add_child(spr)
	var tw := holder.create_tween().set_loops()
	tw.tween_property(spr, "scale", Vector2(1.04, 0.94), 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(spr, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_SINE)
	var t := Timer.new()
	t.wait_time = 2.2
	t.autostart = true
	holder.add_child(t)
	t.timeout.connect(func() -> void:
		var z := UI.label("z", Color(1, 1, 1, 0.9), 0)
		z.add_theme_font_size_override("font_size", 8)
		z.position = Vector2(4, -22)
		z.z_index = 30
		holder.add_child(z)
		var zt := z.create_tween()
		zt.tween_property(z, "position", Vector2(10, -38), 1.8)
		zt.parallel().tween_property(z, "modulate:a", 0.0, 1.8)
		zt.tween_callback(z.queue_free))
	return holder


# ================================================================== Biblioteca
func _build_library() -> void:
	# v3.7 (referências do Victor): estantes cobrindo a parede de cima, janelas com raio de sol e o relógio no
	# meio, fileiras de estantes à esquerda, sala de leitura com tapete à direita, balcão da bibliotecária ao centro.
	var w := cols * T
	var cx := w / 2.0
	for x in [32.0, 64.0, 96.0, 128.0, w - 128.0, w - 96.0, w - 64.0, w - 32.0]:
		prop("i_bookcase", Vector2(x, 62), false)
	_block(Rect2(16, 30, 128, 34))
	_block(Rect2(w - 144, 30, 128, 34))
	for wx in [cx - 52.0, cx + 52.0]:
		wall("p_janela", wx, 28)
		sunbeam(wx, 120.0)
	prop("furn_relogio", Vector2(cx, 64), true)
	Audio.emitter(world, Vector2(cx, 50), "amb_relogio", -14.0, true, 0.0, 180.0)
	prop("p_vaso_flores", Vector2(cx - 84, 62), false)
	prop("p_vaso_flores", Vector2(cx + 84, 62), false)
	# balcão da bibliotecária
	booth(cx, 112.0, 64.0, 2)
	shop_owner("bibliotecaria", "bibliotecaria", "Dona Celeste", Vector2(cx, 94),
		["Bem-vindo à biblioteca.", "As mesas de estudo estão livres.", "Um pomodoro por vez, sem pressa."])
	prop("p_livros", Vector2(cx - 32, 104), false)
	prop("lpc_abajur", Vector2(cx + 34, 104), false)
	light(Vector2(cx + 34, 92), Color(1.0, 0.8, 0.5), 0.6, 0.5)
	prop("i_desk_paper", Vector2(cx + 8, 104), false)
	# fileiras de estantes (corredores) à esquerda, com a placa da seção
	for ry in [150.0, 198.0]:
		for rx in [40.0, 72.0, 104.0, 136.0]:
			prop("i_bookcase", Vector2(rx, ry))
	prop("p_livros", Vector2(160, 212), false)
	prop("i_basket", Vector2(24, 232), false)
	prop("furn_planta", Vector2(24, 250))
	npc("Child", Vector2(88, 170), ["Shhh! Estou lendo.", "Achei um livro sobre a masmorra!"], "wander", 34.0)
	# sala de leitura: tapete, quatro mesas de estudo com vela e quem estuda nelas
	prop("p_tapete_azul", Vector2(w - 116, 196), false, true)
	prop("p_tapete_azul", Vector2(w - 116, 236), false, true)
	var tables := [Vector2(w - 156, 168), Vector2(w - 76, 168), Vector2(w - 156, 218), Vector2(w - 76, 218)]
	for t in tables:
		table_set(t, false, "p_livros", true)
		study_spot("livraria", t + Vector2(0, 14))
	sitter("aventureira_maga", tables[1] + Vector2(16, 6), "left", ["Shhh! Estou revisando.", "Ler também é treinar."])
	sitter("Villager", tables[2] + Vector2(-16, 6), "right", ["Mais uma página...", "Esse livro tem dragões!"])
	prop("lampiao", Vector2(w - 24, 250), false)
	light(Vector2(w - 24, 232), Color(1.0, 0.78, 0.45), 0.7, 0.5)
	prop("i_armchair", Vector2(cx - 60, 238))
	prop("lpc_mesa_centro", Vector2(cx - 36, 240), false)
	prop("p_planta_pequena", Vector2(cx + 40, 250), false)
	light(Vector2(cx, 150), Color(1.0, 0.86, 0.6), 2.8, 0.28)


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
	# v3.7 (referência do quarto do Victor): sol entrando pelas janelas e os companheiros que não estão com você
	# dormindo em almofadas no canto da casa
	sunbeam(70.0, 100.0)
	sunbeam(330.0, 100.0)
	var spots := [Vector2(64, 176), Vector2(92, 182), Vector2(w - 64, 176), Vector2(w - 92, 182)]
	var k := 0
	for pid in Story.pets():
		if pid == Story.active_pet() or not Data.PETS.has(pid) or k >= spots.size():
			continue
		var pd: Dictionary = Data.PETS[pid]
		var rel := ("animals/%s.png" if str(pd.get("kind", "")) == "animal" else "monsters/%s.png") % str(pd["sheet"])
		var pet_node := sleeping_pet(rel, spots[k], true, pd.get("tint", Color.WHITE))
		var talk := Spot.new("Fazer carinho em " + str(pd["name"]), func() -> void:
			HUD.show_toast("%s abre um olho, se espreguiça e volta a dormir." % str(pd["name"]), UI.C_GOOD), 18.0)
		pet_node.add_child(talk)
		k += 1
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
	booth(cx, 96.0, 32.0, 3)
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
	booth(cx, 104.0, 32.0, 3)
	var helena := npc("Princess", Vector2(cx, 84), ["Bem-vind" + ("a" if str(Story.st().get("gender", "m")) == "f" else "o") + " à Guilda!", "As missões do dia estão no quadro.", "Quem foca, conquista."])
	helena.add_to_group("speaker_helena")
	helena.use_look("helena")
	prop("i_desk_paper", Vector2(cx - 50, 96), false)
	prop("p_cofre", Vector2(cx + 50, 78))
	prop("p_vaso_flores", Vector2(cx + 20, 96), false)
	spot("Falar com Helena", Vector2(cx, 118), func() -> void: Story.talk("helena"), 22.0)
	spot("Missões da Guilda", Vector2(cx + 46, 118), func() -> void: HUD.open_window("guilda"), 18.0)
	_guild_story_npcs(cx, w)
	spot("Quadro de missões", Vector2(cx - 110, 70), func() -> void: HUD.open_window("guilda"), 24.0)
	# v3.7: o quadro da direita traz as missões especiais (side quests da história v4, a partir do Rank E)
	spot("Missões especiais", Vector2(cx + 110, 70), func() -> void: SideQuests.board(), 24.0)
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
	sunbeam(50.0, 80.0, 18.0)
	sunbeam(w - 50.0, 80.0, 18.0)
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
	# v3.7 (referência de organização do Victor): cada parede tem uma seção (espadas, escudos e arcos, lanças),
	# armaduras alinhadas na lateral, vitrine com o armeiro atrás, cofre e o gato da loja dormindo na almofada.
	var w := cols * T
	var cx := w / 2.0
	wall("p_tocha_parede", cx, 30)
	light(Vector2(cx, 20), Color(1.0, 0.6, 0.3), 0.6, 0.8)
	# seção das espadas (esquerda) e dos arcos (direita) na parede de cima
	prop("p_rack_espadas", Vector2(52, 64), false)
	prop("p_rack_espadas", Vector2(104, 64), false)
	wall("p_escudos_parede", cx, 26)
	prop("p_lancas", Vector2(w - 104, 66), false)
	wall("p_arcos_parede", w - 52, 28)
	prop("p_barril_espadas", Vector2(w - 52, 66), false)
	_block(Rect2(16, 30, w - 32, 36))
	_section_label("Espadas", 78)
	_section_label("Escudos", cx)
	_section_label("Arcos e lanças", w - 78)
	# armaduras em fila na lateral esquerda; caixotes de reposição na direita
	for ay in [104.0, 140.0, 176.0]:
		prop("p_armadura", Vector2(26, ay))
	prop("p_caixotes", Vector2(w - 30, 112))
	prop("i_crate", Vector2(w - 26, 150))
	prop("i_barrel", Vector2(w - 26, 176))
	# vitrine com o armeiro atrás e o cofre
	prop("p_vitrine", Vector2(cx, 120))
	for sx in [cx - 25.0, cx + 25.0]:   # v3.7: laterais fechando o espaço do armeiro até a parede
		prop("counterv_44", Vector2(sx, 110), false)
	_block(Rect2(cx - 30, 64, 60, 58))
	shop_owner("armeiro", "armeiro", "Otávio", Vector2(cx, 100), ["Espadas novas chegaram!", "Equipamento bom salva vidas.", "Só vendo o que presta."])
	spot("Comprar equipamento", Vector2(cx, 134), func() -> void: HUD.open_window("loja"), 22.0)
	prop("p_cofre", Vector2(cx + 40, 96))
	prop("p_livros", Vector2(cx - 36, 112), false)
	prop("p_tapete_grande", Vector2(cx, 156), false, true)
	sleeping_pet("animals/CatOrange.png", Vector2(cx + 74, 150), true)
	prop("p_planta_pequena", Vector2(w - 50, 182), false)
	prop("furn_planta", Vector2(52, 182))
	light(Vector2(cx, 110), Color(1.0, 0.82, 0.55), 1.8, 0.3)


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
	booth(w / 2.0 + 30, 104.0, 32.0, 2)
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


# ================================================================== Castelo da Academia (v3.7)
## Salas atrás das portas do AcademyCastle. Cada uma tem quem faz sentido estar lá e uma função: falar com a
## Reitora (matrícula/formatura), aula com o Mestre Lin, quadro de avisos, comida, descanso, estudo, alquimia.
func _build_academy_room() -> void:
	var w := cols * T
	var cx := w / 2.0
	match id:
		"acad_reitoria":
			_acad_reitoria(w, cx)
		"acad_aula":
			_acad_aula(w, cx)
		"acad_secretaria":
			_acad_secretaria(w, cx)
		"acad_bibliotecario":
			_acad_bibliotecario(w, cx)
		"acad_refeitorio":
			_acad_refeitorio(w, cx)
		"acad_alojamento":
			_acad_alojamento(w, cx)
		"acad_quarto":
			_acad_quarto(w, cx)
		"acad_dormitorio":
			_acad_dormitorio(w, cx)
		"acad_comum":
			_acad_comum(w, cx)
		"acad_lab":
			_acad_lab(w, cx)
	var title := UI.label(str(ACAD_TITLES.get(id, "")), Color("fff1c9"))
	title.size = Vector2(300, 14)
	title.position = Vector2(cx - 150, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 50
	add_child(title)


func _rest_spot(pos: Vector2, text: String = "Descansar") -> void:
	spot(text, pos, func() -> void:
		GameState.full_heal()
		Audio.sfx("sleep", -4.0)
		HUD.show_toast("Você descansou. Vida cheia!", UI.C_GOOD), 20.0)


func _acad_reitoria(w: float, cx: float) -> void:
	for wx in [60.0, w - 60.0]:
		wall("p_janela", wx, 28)
		sunbeam(wx, 100.0, 20.0)
	wall("p_estandarte_azul", cx - 40, 34)
	wall("p_estandarte_azul", cx + 40, 34)
	wall("i_painting", cx, 26)
	prop("i_bookcase", Vector2(30, 62), false)
	prop("i_bookcase", Vector2(62, 62), false)
	prop("furn_trofeu", Vector2(w - 40, 62), false)
	prop("p_cofre", Vector2(w - 70, 66))
	_block(Rect2(14, 30, 64, 34))
	prop("i_desk_paper", Vector2(cx, 104))
	prop("p_livros", Vector2(cx - 12, 95), false)
	prop("p_vela", Vector2(cx + 12, 94), false)
	light(Vector2(cx + 12, 86), Color(1.0, 0.78, 0.45), 0.5, 0.5)
	var r := npc("Woman", Vector2(cx, 86), ["Boas-vindas à Reitoria.", "Constância vence talento que não aparece."])
	r.add_to_group("speaker_reitora")
	StoryProp.talker(r, "reitora", "Reitora Aurora")
	prop("cadeira", Vector2(cx - 22, 126), false)
	prop("cadeira", Vector2(cx + 22, 126), false)
	prop("p_tapete_azul", Vector2(cx, 150), false, true)
	prop("furn_planta", Vector2(24, 170))
	prop("furn_planta", Vector2(w - 24, 170))
	light(Vector2(cx, 110), Color(1.0, 0.85, 0.6), 2.0, 0.3)


func _acad_aula(w: float, cx: float) -> void:
	wall("p_lab_quadro", cx, 30)
	for wx in [48.0, w - 48.0]:
		wall("p_janela", wx, 28)
		sunbeam(wx, 120.0, 20.0)
	prop("i_bookshelf_s", Vector2(90, 62), false)
	prop("i_bookshelf_s", Vector2(w - 90, 62), false)
	prop("furn_relogio", Vector2(w - 22, 64), true)
	prop("i_desk_paper", Vector2(cx, 100))
	prop("p_livros", Vector2(cx + 14, 91), false)
	if Story.in_academy_act():
		var lin := npc("Master", Vector2(cx, 84), ["Sente-se. A aula já vai começar.", "Pergunta boa vale mais que resposta pronta."])
		StoryProp.talker(lin, "lin_a", "Mestre Lin (professor)")
		lin.add_to_group("speaker_lin")
	else:
		npc("Monk2", Vector2(cx, 84), ["Hoje: como revisar sem reler. Pergunte-se, não releia.", "Explique em voz alta. Se travar, ali está a lacuna."])
	# carteiras dos alunos: 3 colunas x 2 fileiras, alguns alunos e duas carteiras livres para estudar
	var desks: Array = []
	for j in 2:
		for i in 3:
			desks.append(Vector2(cx - 110 + i * 110, 146 + j * 44))
	for k in desks.size():
		var dp: Vector2 = desks[k]
		prop("i_table", dp)
		prop("i_stool", dp + Vector2(0, 12), false)
		prop("p_livros", dp + Vector2(-4, -6), false)
	sitter("Villager2", desks[0] + Vector2(0, 12), "up", ["Anotando tudo!", "O Mestre Lin fala rápido."])
	sitter("Woman", desks[2] + Vector2(0, 12), "up", ["Se eu ensinar alguém, eu aprendo.", "Mapa mental é minha arma secreta."])
	sitter("Boy", desks[4] + Vector2(0, 12), "up", ["Zzz... estou acordado!", "Que horas acaba?"])
	study_spot("livraria", desks[1] + Vector2(0, 14))
	study_spot("livraria", desks[3] + Vector2(0, 14))
	light(Vector2(cx, 140), Color(1.0, 0.86, 0.6), 2.6, 0.28)


func _acad_secretaria(w: float, cx: float) -> void:
	wall("p_janela", 40, 28)
	sunbeam(40.0, 90.0, 18.0)
	prop("i_cabinet", Vector2(cx - 30, 62), false)
	prop("i_dresser", Vector2(cx + 30, 62), false)
	booth(cx, 104.0, 32.0, 2)
	prop("i_desk_paper", Vector2(cx - 20, 96), false)
	prop("p_vaso_flores", Vector2(cx + 24, 96), false)
	var sec := npc("Villager4", Vector2(cx, 82), ["Matrícula, bolsa, horário? É aqui.", "A Reitoria fica no fim do corredor central.", "As aulas são na Sala de Aula, corredor do meio."])
	sec.add_to_group("speaker_secretaria")
	prop("quadro_missoes", Vector2(w - 34, 72), false)
	spot("Ler o quadro de avisos", Vector2(w - 34, 86), func() -> void:
		var lines: Array = [["narr", "QUADRO DE AVISOS: 'Missões do jardim abrem com horas de foco desde a matrícula. Formatura: 2 horas seguidas.'"]]
		if Story.in_academy_act():
			lines.append(["narr", "Recado para você: " + Story.objective_text()])
		lines.append(["narr", "'Refeitório: sopa de abóbora. Dormitório: silêncio depois das dez.'"])
		await Story.say(lines), 20.0)
	prop("p_banco", Vector2(60, 150))
	sitter("Child", Vector2(52, 156), "right", ["Vim ver minha nota.", "Espero não estar de recuperação..."])
	prop("furn_planta", Vector2(w - 24, 150))
	light(Vector2(cx, 100), Color(1.0, 0.85, 0.6), 1.8, 0.3)


func _acad_bibliotecario(w: float, cx: float) -> void:
	wall("p_janela", cx, 28)
	sunbeam(cx, 80.0, 18.0)
	prop("i_bookcase", Vector2(30, 62), false)
	prop("i_bookcase", Vector2(w - 30, 62), false)
	_block(Rect2(14, 30, 32, 34))
	_block(Rect2(w - 46, 30, 32, 34))
	for bp in [Vector2(60, 70), Vector2(76, 74), Vector2(w - 64, 72), Vector2(cx + 30, 128), Vector2(40, 120)]:
		prop("p_livros", bp, false)
	prop("i_armchair", Vector2(cx - 40, 110))
	prop("lpc_abajur", Vector2(cx - 18, 108), false)
	light(Vector2(cx - 18, 96), Color(1.0, 0.78, 0.45), 0.6, 0.55)
	var ans := npc("OldMan2", Vector2(cx + 10, 100), [
		"Seu Anselmo, guardião dos livros fora do horário.",
		"Seu pai lia de pé, encostado naquela estante. Dizia que sentado dava sono.",
		"Releia menos, pergunte mais: feche o livro e tente lembrar.",
	])
	ans.add_to_group("speaker_anselmo")
	prop("i_desk_paper", Vector2(cx + 34, 140))
	study_spot("livraria", Vector2(cx + 34, 152))
	sleeping_pet("animals/CatBlack.png", Vector2(w - 40, 140), true)
	light(Vector2(cx, 100), Color(1.0, 0.82, 0.55), 1.4, 0.3)


func _acad_refeitorio(w: float, cx: float) -> void:
	prop("p_fogao", Vector2(cx - 40, 62), false)
	wall("p_panelas", cx - 40, 30)
	wall("p_prateleira_potes", cx + 40, 30)
	light(Vector2(cx - 40, 52), Color(1.0, 0.6, 0.3), 0.8, 0.7)
	booth(cx, 96.0, 32.0, 3)
	var cook := npc("OldWoman", Vector2(cx, 76), ["Sopa de abóbora pra quem estudou!", "Prato cheio, cabeça leve.", "Água também é comida, viu?"])
	cook.add_to_group("speaker_cozinheira")
	spot("Comprar comida", Vector2(cx, 110), func() -> void: HUD.open_window("restaurante"), 22.0)
	for wx in [40.0, w - 40.0]:
		wall("p_janela", wx, 28)
	# mesas compridas com alunos comendo
	var tables := [Vector2(cx - 120, 150), Vector2(cx, 150), Vector2(cx + 120, 150), Vector2(cx - 120, 200), Vector2(cx, 200), Vector2(cx + 120, 200)]
	for t in tables:
		table_set(t, false, "i_bowl1" if randi() % 2 == 0 else "i_mug", false)
	sitter("Villager3", tables[0] + Vector2(-16, 6), "right", ["Hmm, sopa.", "Depois daqui, revisão!"])
	sitter("Boy", tables[1] + Vector2(16, 6), "left", ["Ganhei repetição!", "Quem come bem estuda melhor."])
	sitter("Woman", tables[4] + Vector2(-16, 6), "right", ["Sabia que o cérebro gasta muita energia?", "Hora do lanche sagrado."])
	prop("i_barrel", Vector2(24, 230))
	prop("i_sack", Vector2(w - 24, 230))
	light(Vector2(cx, 160), Color(1.0, 0.82, 0.55), 2.6, 0.3)


func _acad_alojamento(w: float, cx: float) -> void:
	prop("furn_lareira", Vector2(cx, 60), true)
	light(Vector2(cx, 50), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	prop("p_cama_simples", Vector2(30, 100))
	prop("p_cama_simples", Vector2(w - 30, 100))
	prop("i_bookshelf_s", Vector2(70, 62), false)
	prop("i_shelf_s", Vector2(w - 70, 62), false)
	prop("lpc_mesa_redonda", Vector2(cx, 128))
	prop("p_cha", Vector2(cx - 4, 118), false)
	sitter("OldMan", Vector2(cx - 22, 134), "right", ["Chá? É o que move os mestres.", "Dei aula para metade dos aventureiros de Focus Town."])
	sitter("Monk", Vector2(cx + 22, 134), "left", ["Um bom mestre também tem dúvida.", "Shhh, a lareira está contando histórias."])
	prop("furn_planta", Vector2(24, 150))
	light(Vector2(cx, 110), Color(1.0, 0.8, 0.55), 1.8, 0.3)


func _acad_quarto(w: float, cx: float) -> void:
	wall("p_janela", cx + 30, 28)
	sunbeam(cx + 30, 70.0, 18.0)
	prop("furn_cama", Vector2(28, 92))
	_rest_spot(Vector2(28, 104), "Dormir na sua cama")
	prop("i_desk_paper", Vector2(cx + 34, 70))
	prop("p_livros", Vector2(cx + 24, 61), false)
	prop("p_vela", Vector2(cx + 46, 60), false)
	study_spot("casa", Vector2(cx + 34, 84))
	prop("i_chest", Vector2(w - 26, 112))
	prop("p_espelho", Vector2(cx - 10, 66))
	spot("Espelho (aparência)", Vector2(cx - 10, 78), func() -> void: HUD.open_window("aparencia"), 18.0)
	prop("furn_tapete", Vector2(cx, 112), false, true)
	prop("p_planta_pequena", Vector2(w - 24, 64), false)


func _acad_dormitorio(w: float, cx: float) -> void:
	for wx in [60.0, w - 60.0]:
		wall("p_janela", wx, 28)
	for i in 5:
		prop("p_cama_simples", Vector2(40 + i * 64, 92))
		prop("i_chest", Vector2(40 + i * 64, 122))
	_rest_spot(Vector2(40 + 2 * 64, 104), "Descansar numa cama livre")
	sitter("Villager2", Vector2(40 + 64, 104), "down", ["Revisão antes de dormir fixa melhor.", "Amanhã tem missão no jardim!"])
	sitter("Woman", Vector2(40 + 4 * 64, 104), "down", ["Dormir bem é metade da prova.", "Shhh, o Tomé já dormiu."])
	prop("p_tapete_grande", Vector2(cx, 160), false, true)
	prop("furn_planta", Vector2(24, 170))
	light(Vector2(cx, 120), Color(1.0, 0.82, 0.55), 2.2, 0.26)


func _acad_comum(w: float, cx: float) -> void:
	prop("furn_lareira", Vector2(cx, 60), true)
	light(Vector2(cx, 50), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	wall("p_janela", 50, 28)
	wall("p_janela", w - 50, 28)
	prop("lpc_sofa", Vector2(cx, 118))
	prop("lpc_poltrona", Vector2(cx - 50, 110))
	prop("lpc_poltrona", Vector2(cx + 50, 110))
	prop("lpc_mesa_centro", Vector2(cx, 100), false)
	prop("p_tapete_azul", Vector2(cx, 110), false, true)
	sitter("Boy", Vector2(cx - 50, 112), "right", ["Partida de perguntas: você topa?", "Quem errar paga o lanche."])
	sitter("Villager4", Vector2(cx + 50, 112), "left", ["Estudar em grupo rende mais.", "Explica de novo aquela parte?"])
	prop("i_bookcase", Vector2(30, 62), false)
	prop("i_table", Vector2(w - 60, 160))
	prop("i_stool", Vector2(w - 60, 172), false)
	study_spot("livraria", Vector2(w - 60, 174))
	prop("furn_planta", Vector2(24, 170))
	light(Vector2(cx, 120), Color(1.0, 0.8, 0.55), 2.0, 0.3)


func _acad_lab(w: float, cx: float) -> void:
	wall("p_lab_quadro", cx, 30)
	prop("p_lab_potes", Vector2(40, 62), false)
	prop("p_lab_bancada", Vector2(cx - 50, 110))
	prop("p_lab_caldeirao", Vector2(cx + 40, 110))
	light(Vector2(cx + 40, 96), Color(0.5, 1.0, 0.6), 0.7, 0.6)
	prop("p_prateleira_potes", Vector2(w - 50, 52), false, true)
	npc("NinjaMageOrange", Vector2(cx, 86), ["Mestra Sálvia, alquimia básica.", "Misture devagar e anote tudo.", "Errar a fórmula também ensina."])
	spot("Praticar a Fórmula Secreta (ofício)", Vector2(cx - 50, 124), func() -> void: HUD.open_window("mg_lab"), 20.0)
	prop("furn_planta", Vector2(24, 150))
	light(Vector2(cx, 110), Color(1.0, 0.85, 0.65), 1.6, 0.3)


# ================================================================== Casas de morador das cidades (v3.7)
func _morador_title(city: String, bid: String) -> String:
	for b in (CityData.CITIES.get(city, {}) as Dictionary).get("buildings", []):
		if str(b["id"]) == bid:
			return str(b["title"])
	return "Casa"


## Casa simples montada pelo nome: armazém e estábulo viram depósito, alojamento ganha várias camas, farol tem
## lampião, a casa do capitão tem mapas; as outras são casa de família com cama, mesa, estante e lareira/fogão.
func _build_morador() -> void:
	var parts := id.split("_")
	var city := parts[1] if parts.size() > 1 else "porto"
	var bid := "_".join(parts.slice(2)) if parts.size() > 2 else ""
	var title_text := _morador_title(city, bid)
	var w := cols * T
	var cx := w / 2.0
	var r := RandomNumberGenerator.new()
	r.seed = absi(hash(id))
	var low := title_text.to_lower()
	var cold := city in ["pedralta", "vila_neve"]
	wall("p_janela", 40, 28)
	wall("p_janela", w - 40, 28)
	sunbeam(40.0, 80.0, 18.0)
	if low.contains("armazém") or low.contains("estábulo"):
		for o in [["p_caixotes", Vector2(30, 70)], ["i_crate", Vector2(56, 74)], ["i_barrel", Vector2(w - 30, 70)], ["lpc_barris", Vector2(w - 60, 72)],
				["i_sack", Vector2(30, 120)], ["i_sack", Vector2(46, 126)], ["i_crate", Vector2(w - 34, 124)], ["i_barrel2", Vector2(cx + 30, 70)]]:
			prop(str(o[0]), o[1])
		npc(MORADOR_SHEETS[r.randi() % MORADOR_SHEETS.size()], Vector2(cx, 100), ["Cuidado com as caixas, estão empilhadas até o teto.", "Aqui guardo o que as caravanas e os barcos trazem."])
	elif low.contains("alojamento"):
		for i in 4:
			prop("p_cama_simples", Vector2(32 + i * 44, 92))
		_rest_spot(Vector2(32 + 44, 104), "Descansar numa cama livre")
		prop("i_chest", Vector2(w - 30, 120))
		npc("Villager2", Vector2(cx + 20, 124), ["Turno da noite na forja. Durmo de dia.", "Fique à vontade, só não ronque."])
	else:
		prop("p_cama_simples" if r.randf() < 0.5 else "furn_cama", Vector2(30, 96))
		prop("furn_lareira" if cold else "p_fogao", Vector2(cx, 60), true)
		if cold:
			light(Vector2(cx, 50), Color(1.0, 0.55, 0.25), 0.8, 0.8)
		prop("i_bookshelf_s" if r.randf() < 0.5 else "i_shelf_s", Vector2(w - 34, 62), false)
		table_set(Vector2(cx + 20, 120), r.randf() < 0.5, "i_bowl2", true)
		prop("furn_tapete" if r.randf() < 0.5 else "p_tapete_azul", Vector2(cx - 30, 120), false, true)
		prop("furn_planta", Vector2(w - 24, 130))
		if low.contains("capitão"):
			wall("i_painting", cx - 40, 26)
			wall("p_estandarte_azul", cx + 44, 34)
			prop("p_livros", Vector2(cx + 14, 112), false)
		elif low.contains("farol"):
			prop("lampiao", Vector2(w - 50, 70), false)
			light(Vector2(w - 50, 52), Color(1.0, 0.85, 0.5), 1.2, 0.8)
		elif low.contains("mineiro") or low.contains("forjador"):
			wall("p_ferramentas", cx - 50, 30)
			prop("p_lingotes", Vector2(60, 124), false)
		elif low.contains("peleteira"):
			prop("p_tecidos", Vector2(60, 64), false)
		var lines: Array = (MORADOR_LINES.get(city, ["Olá! Entre."]) as Array).duplicate()
		lines.shuffle()
		var who: String = MORADOR_SHEETS[r.randi() % MORADOR_SHEETS.size()]
		if low.contains("capitão") or low.contains("granito") or low.contains("ancião"):
			# o dono famoso está lá fora, na história; aqui fica a família
			lines = ["Ele saiu agora há pouco. Deve estar lá fora, na praça.", "Pode olhar, mas não mexa em nada, por favor."]
		npc(who, Vector2(cx - 30, 104), lines.slice(0, 3), "wander", 30.0)
	var title := UI.label(title_text, Color("fff1c9"))
	title.size = Vector2(300, 14)
	title.position = Vector2(cx - 150, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 50
	add_child(title)
	light(Vector2(cx, 100), Color(1.0, 0.82, 0.55), 1.6, 0.28)


## Sala do trono de Rocuetos (Pedralta). PROVISÓRIO: o rei usa o sprite "Noble" do Ninja e o trono é o sofá
## imperial do LPC, até chegar um pack com rei e sala do trono (ver PROVISORIOS.md).
func _build_throne_room() -> void:
	var w := cols * T
	var cx := w / 2.0
	for y in [210.0, 170.0, 130.0]:
		prop("p_tapete_grande", Vector2(cx, y), false, true)
	prop("lpc_sofa_imperial", Vector2(cx, 74))
	_block(Rect2(cx - 24, 50, 48, 26))
	for bx in [cx - 70.0, cx + 70.0, 40.0, w - 40.0]:
		wall("p_estandarte", bx, 34)
	for tx in [cx - 110.0, cx + 110.0]:
		wall("p_tocha_parede", tx, 30)
		light(Vector2(tx, 20), Color(1.0, 0.6, 0.3), 0.7, 0.8)
	var army := Story.path() == "exercito"
	var king_lines: Array = ["Rocuetos honra quem estuda e quem luta. Os dois sabem esperar.", "Um reino é um caderno: se ninguém escreve todo dia, ele apaga.", "A Comandante Brígida fala por mim no quartel."]
	if army:
		king_lines = ["%s! A notícia das suas vitórias chegou antes de você." % ArmyStory.patente_name(), "Rocuetos lembra de cada nome que serve com constância.", "Continue estudando: general que não lê perde a guerra."]
	var king := npc("Noble", Vector2(cx, 66), king_lines)
	king.add_to_group("speaker_rei_rocuetos")
	for gx in [cx - 46.0, cx + 46.0]:
		for gy in [120.0, 180.0]:
			var g := NPC.new()
			g.custom_look = Ally.look_of("soldado")
			g.mode = "static"
			g.position = Vector2(gx, gy)
			g.lines = ["...", "Silêncio na sala do trono."]
			world.add_child(g)
	prop("furn_trofeu", Vector2(30, 62), false)
	prop("p_armadura", Vector2(w - 30, 70))
	var title := UI.label("Sala do Trono de Rocuetos", Color("fff1c9"))
	title.size = Vector2(300, 14)
	title.position = Vector2(cx - 150, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 50
	add_child(title)
	light(Vector2(cx, 120), Color(1.0, 0.85, 0.6), 2.8, 0.3)


## Cabana do Pietro (floresta): cama, lareira, arcos na parede, mesa com mapa. Pietro passa o dia no acampamento.
func _build_pietro_cabin() -> void:
	var w := cols * T
	var cx := w / 2.0
	prop("furn_lareira", Vector2(cx, 60), true)
	light(Vector2(cx, 50), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	wall("p_arcos_parede", 50, 30)
	wall("p_ervas", w - 50, 26)
	prop("p_cama_simples", Vector2(30, 100))
	_rest_spot(Vector2(30, 112), "Descansar na cama do Pietro (ele deixou)")
	prop("i_table", Vector2(cx + 30, 118))
	prop("p_livros", Vector2(cx + 26, 110), false)
	prop("i_stool", Vector2(cx + 30, 132), false)
	prop("i_rack", Vector2(w - 34, 120), false)
	prop("i_barrel", Vector2(w - 26, 70))
	spot("Ler o bilhete na mesa", Vector2(cx + 30, 132), func() -> void:
		await Story.say([["narr", "Bilhete do Pietro: 'Se estiver cansad{o}, a cama é sua. Lobos não entram; ervas, sim. Volte com cuidado.'"]]), 18.0)
	var title := UI.label("Cabana do Pietro", Color("fff1c9"))
	title.size = Vector2(300, 14)
	title.position = Vector2(cx - 150, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.z_index = 50
	add_child(title)
	light(Vector2(cx, 100), Color(1.0, 0.8, 0.55), 1.6, 0.28)


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
	# v3.7 (referência do Victor): prateleiras de tecido dobrado na parede, cômoda e manequins em fila,
	# balcão com abajur e livro-caixa, gato dormindo e tapete na frente da mesa de costura.
	wall("p_janela", 40, 28)
	sunbeam(40.0, 90.0)
	prop("p_tecidos", Vector2(w / 2.0 - 18, 62), false)
	prop("p_tecidos", Vector2(w / 2.0 + 14, 62), false)
	prop("i_dresser_wide", Vector2(w / 2.0 + 52, 62), false)
	prop("p_novelos", Vector2(w / 2.0 + 52, 46), false)
	_block(Rect2(w / 2.0 - 34, 30, 102, 34))
	prop("furn_relogio", Vector2(w - 22, 64), true)
	for mx in [76.0, 100.0]:
		prop("p_manequim", Vector2(mx, 70))
	prop("p_espelho", Vector2(26, 70))
	prop("p_mesa_costura", Vector2(w / 2.0 - 10, 112))
	prop("i_stool", Vector2(w / 2.0 - 10, 126))
	prop("furn_tapete", Vector2(w / 2.0 - 10, 140), false, true)
	prop("p_roca", Vector2(30, 118))
	prop("p_novelos", Vector2(48, 128), false)
	# balcão: abajur, livro-caixa e a Rosa atrás
	booth(w - 62, 120.0, 64.0, 2)
	prop("lpc_abajur", Vector2(w - 64, 112), false)
	light(Vector2(w - 64, 100), Color(1.0, 0.8, 0.5), 0.5, 0.5)
	prop("p_livros", Vector2(w - 38, 112), false)
	shop_owner("costureira", "costureira", "Rosa", Vector2(w - 50, 100), h["lines"])
	prop("i_rack", Vector2(w / 2.0 + 30, 156), false)
	sleeping_pet("animals/Cat.png", Vector2(40, 156), true)
	prop("p_vaso_flores", Vector2(w - 22, 160), false)
	spot("Guarda-roupa da Rosa", Vector2(88, 84), func() -> void: HUD.open_window("guarda_roupa"), 18.0)
	# v3.7: ofício de Costureiro (mini-jogo de memória e precisão)
	spot("Costurar para a Rosa (ofício)", Vector2(w / 2.0 - 10, 134), func() -> void: HUD.open_window("mg_costura"), 18.0)
	light(Vector2(w / 2.0, 100), Color(1.0, 0.8, 0.55), 1.6, 0.3)


func _build_inn(h: Dictionary, w: float) -> void:
	# v3.7 (referência do Victor, casa com vários cômodos): dois quartos e a cozinha no fundo, separados por
	# paredes com vão de porta (PARTITIONS["casa_npc_1"]); salão com balcão, lareira, mesas e tapete na frente.
	# quarto 1 (tiles 1..7)
	wall("p_janela", 72, 28)
	sunbeam(72.0, 70.0, 18.0)
	prop("p_cama_simples", Vector2(32, 100))
	prop("p_cama_simples", Vector2(110, 100))
	prop("lpc_comoda", Vector2(30, 62), false)
	prop("furn_tapete", Vector2(72, 100), false, true)
	prop("i_chest", Vector2(110, 62))
	# quarto 2 (tiles 9..15)
	wall("p_janela", 208, 28)
	sunbeam(208.0, 70.0, 18.0)
	prop("p_cama_simples", Vector2(164, 100))
	prop("p_cama_simples", Vector2(240, 100))
	prop("lpc_armario", Vector2(166, 62), false)
	prop("p_planta_pequena", Vector2(240, 60), false)
	prop("i_rug_big", Vector2(204, 108), false, true)
	# cozinha (tiles 17..24)
	prop("p_fogao", Vector2(298, 66), false)
	wall("p_panelas", 298, 30)
	light(Vector2(298, 52), Color(1.0, 0.55, 0.25), 0.6, 0.7)
	prop("lpc_louceiro", Vector2(332, 62), false)
	wall("p_prateleira_potes", 368, 30)
	prop("i_table", Vector2(360, 100))
	prop("p_cha", Vector2(356, 92), false)
	prop("i_sack", Vector2(386, 70))
	prop("lpc_barris", Vector2(388, 104))
	_block(Rect2(272, 30, 128, 34))
	npc("Woman", Vector2(316, 88), ["Sopa de cogumelo no fogo!", "Quem estuda come melhor, eu garanto.", "Não mexe na panela, viu?"])
	for lb in [["Quarto 1", 72.0], ["Quarto 2", 208.0], ["Cozinha", 336.0]]:
		_section_label(str(lb[0]), float(lb[1]), 116.0)
	# salão: balcão no meio, lareira encostada na parede, mesas à direita, tapete na frente da porta
	var cx := w / 2.0
	booth(cx, 182.0, 146.0, 2)
	prop("p_livros", Vector2(cx - 30, 174), false)
	prop("p_vela", Vector2(cx + 14, 173), false)
	prop("i_mug", Vector2(cx + 30, 174), false)
	shop_owner("estalajadeiro", "estalajadeiro", "Bento", Vector2(cx, 166), h["lines"])
	prop("lpc_barris", Vector2(cx + 66, 180))
	prop("furn_lareira", Vector2(48, 162), true)
	light(Vector2(48, 150), Color(1.0, 0.55, 0.25), 0.9, 0.9)
	prop("p_banco", Vector2(48, 200))
	prop("p_tapete_grande", Vector2(cx, 222), false, true)
	table_set(Vector2(w - 92, 186), true, "i_mug", true)
	table_set(Vector2(w - 60, 232), false, "i_bowl1", false)
	sitter("aventureiro_samurai", Vector2(w - 76, 192), "left", ["Amanhã sigo para a Mata.", "Ouvi luzes no Pântano."])
	prop("furn_planta", Vector2(cx - 44, 258))
	prop("furn_planta", Vector2(cx + 44, 258))
	prop("i_barrel", Vector2(24, 254))
	prop("i_barrel2", Vector2(w - 24, 254))
	light(Vector2(cx, 200), Color(1.0, 0.8, 0.55), 2.2, 0.28)


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
