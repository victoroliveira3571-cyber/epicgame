extends Node2D

## A cidade: gramado e caminhos montados com autotile, prédios, árvores, lago,
## aldeões e animais passeando, ciclo de dia/noite pelo relógio do computador.

const W := 64
const H := 50
const T := 16
const SPINE_X := 32          # tile central da estrada norte-sul
const AVENUE_Y := 26         # linha central da avenida
const GATE_Y := 47

var rng := RandomNumberGenerator.new()
var world: Node2D
var player: Player
var canvas_mod: CanvasModulate
var buildings: Dictionary = {}
var door_spawns: Dictionary = {}   # id do interior -> onde o jogador reaparece ao sair
var dirt := PackedByteArray()
var water := PackedByteArray()
var reserved := PackedByteArray()
var road_points: Array = []
var placed_points: Array = []
var daylight_timer: float = 0.0
var forced_hour: float = -1.0
var minimap_tex: Texture2D       # chão da cidade em miniatura (minimapa do HUD)

const BUILDING_DEFS := [
	{"id": "casa", "name": "Casa", "prop": "b_casa_laranja", "tile": Vector2i(14, 25), "door_dx": -8.0,
		"npc": "OldWoman", "npc_dx": 36.0, "lines": ["Descanse, você merece.", "Em casa tudo fica melhor.", "Uma casa bonita rende bons hábitos."]},
	{"id": "restaurante", "name": "Pousada Pão Quente", "prop": "b_padaria", "tile": Vector2i(23, 25), "door_dx": 0.0,
		"npc": "Woman", "npc_dx": -30.0, "lines": ["Fome? Tenho pratos quentes!", "Comer bem rende mais foco.", "Hoje tem macarrão!"]},
	{"id": "loja", "name": "Loja de Armas", "prop": "b_casa_empena", "tile": Vector2i(42, 25), "door_dx": 0.0,
		"npc": "Villager4", "npc_dx": 30.0, "lines": ["Armas novas chegaram!", "Equipamento bom salva vidas.", "Só vendo o que presta."]},
	{"id": "forja", "name": "Ferreiro", "prop": "b_forja", "tile": Vector2i(51, 25), "door_dx": 0.0,
		"npc": "Caveman", "npc_dx": -30.0, "lines": ["Traga barras e ouro.", "Aprimoro qualquer arma.", "Ferro quente, trabalho bom."]},
	{"id": "biblioteca", "name": "Biblioteca", "prop": "b_salao_vermelho", "tile": Vector2i(22, 17), "door_dx": 0.0, "tint": Color(0.72, 0.86, 1.0),
		"npc": "Master", "npc_dx": 36.0, "lines": ["Silêncio, por favor... aqui se estuda.", "Cada livro é uma aventura.", "As mesas lá dentro estão livres."]},
	{"id": "guilda", "name": "Guilda dos Aventureiros", "prop": "h_salao_madeira", "tile": Vector2i(32, 17), "door_dx": 0.0,
		"npc": "OldMan3", "npc_dx": 44.0, "lines": ["Bem-vindo, aventureiro!", "A masmorra espera por você.", "Quem foca, conquista."]},
]
const HOUSE_DEFS := [
	{"prop": "b_casa_creme", "tile": Vector2i(14, 37)}, {"prop": "b_estalagem", "tile": Vector2i(22, 37)},
	{"prop": "b_casa_laranja2", "tile": Vector2i(43, 37)}, {"prop": "b_salao_vermelho", "tile": Vector2i(52, 37)},
]
const TREE_PROPS := ["n_arvore_redonda", "n_arvore_redonda2", "n_arvore_redonda3", "n_arvore_grande", "n_arvore_pinheiro", "n_arvore_raiz", "n_arvores_trio", "n_pinheiros_trio"]
const BORDER_TREES := ["n_arvore_grande", "n_arvore_redonda", "n_arvores_trio", "n_arvores_trio_b", "n_pinheiros_trio", "n_arvore_pinheiro", "n_arvore_redonda2"]
const WANDERERS := ["Villager", "Villager2", "Villager3", "Child", "OldMan", "Villager5"]


func _ready() -> void:
	rng.seed = 20261030
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			forced_hour = float(arg.substr(7))
	_build_masks()
	add_to_group("town")
	var img := TileComposer.compose_town(W, H, dirt, water, rng)
	var small := img.duplicate() as Image
	small.resize(int(W * 2), int(H * 2), Image.INTERPOLATE_BILINEAR)
	minimap_tex = ImageTexture.create_from_image(small)
	var ground := Sprite2D.new()
	ground.texture = ImageTexture.create_from_image(img)
	ground.centered = false
	ground.z_index = -100
	add_child(ground)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_build_bounds()
	_build_water_colliders()
	_build_buildings()
	_build_gate()
	_build_forest_gate()
	_build_decor()
	_build_npcs()
	_build_ambient()
	_spawn_player()
	canvas_mod = CanvasModulate.new()
	add_child(canvas_mod)
	_update_daylight()
	Audio.play_music("town")
	HUD.on_scene_ready("town")
	GameState.check_daily_reset()
	# o jogo foi fechado no prólogo: volta para a casa da família
	if Story.started() and Story.step() == "c1_casa":
		Game.enter_interior.call_deferred("casa_familia")


func _process(delta: float) -> void:
	daylight_timer -= delta
	if daylight_timer <= 0.0:
		daylight_timer = 4.0
		_update_daylight()


# ================================================================== Máscaras
func _idx(x: int, y: int) -> int:
	return y * W + x


func _rect_fill(mask: PackedByteArray, x0: int, y0: int, x1: int, y1: int, v: int = 1) -> void:
	for y in range(maxi(y0, 0), mini(y1, H - 1) + 1):
		for x in range(maxi(x0, 0), mini(x1, W - 1) + 1):
			mask[_idx(x, y)] = v


func _build_masks() -> void:
	dirt.resize(W * H)
	water.resize(W * H)
	reserved.resize(W * H)
	dirt.fill(0)
	water.fill(0)
	reserved.fill(0)
	# avenida, rua de baixo, espinha norte-sul e praça
	_rect_fill(dirt, 2, AVENUE_Y - 1, 57, AVENUE_Y + 1)
	_rect_fill(dirt, 8, 37, 56, 39)
	_rect_fill(dirt, SPINE_X - 1, 17, SPINE_X + 1, 47)
	_rect_fill(dirt, 27, 22, 37, 30)
	_rect_fill(dirt, 21, 18, 23, AVENUE_Y - 1)   # caminho até a biblioteca
	# lago esquerdo e lagoa direita
	_rect_fill(water, 8, 30, 16, 35)
	_rect_fill(water, 47, 31, 52, 35)
	# reservas: caminhos (com folga), lagos, prédios
	for y in H:
		for x in W:
			if dirt[_idx(x, y)] != 0 or water[_idx(x, y)] != 0:
				_rect_fill(reserved, x - 1, y - 1, x + 1, y + 1)
	_rect_fill(reserved, 0, 0, W - 1, 3)
	_rect_fill(reserved, 0, H - 4, W - 1, H - 1)
	_rect_fill(reserved, 0, 0, 3, H - 1)
	_rect_fill(reserved, W - 4, 0, W - 1, H - 1)
	for d in BUILDING_DEFS:
		var t: Vector2i = d["tile"]
		_rect_fill(reserved, t.x - 4, t.y - 6, t.x + 4, t.y + 1)
	for d in HOUSE_DEFS:
		var t2: Vector2i = d["tile"]
		_rect_fill(reserved, t2.x - 4, t2.y - 5, t2.x + 4, t2.y + 1)
	for y in H:
		for x in W:
			if dirt[_idx(x, y)] != 0 and y >= 22 and y <= 30 and x >= 27 and x <= 37 and x != SPINE_X:
				continue
			if dirt[_idx(x, y)] != 0 and y > 4 and y < H - 4:
				road_points.append(Vector2(x * T + 8, y * T + 12))


func _build_bounds() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var margin := 3 * T
	var rects := [
		Rect2(-64, -64, W * T + 128, 64 + margin),                 # topo
		Rect2(-64, H * T - margin, W * T + 128, 64 + margin),      # baixo
		Rect2(-64, -64, 64 + margin, H * T + 128),                 # esquerda
		Rect2(W * T - margin, -64, 64 + margin, H * T + 128),      # direita
	]
	for r in rects:
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = r.size
		c.shape = s
		c.position = r.position + r.size / 2.0
		body.add_child(c)


func _build_water_colliders() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for rect in [Rect2i(8, 30, 9, 6), Rect2i(47, 31, 6, 5)]:
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = Vector2(rect.size.x * T - 6, rect.size.y * T - 6)
		c.shape = s
		c.position = Vector2(rect.position.x * T + rect.size.x * T / 2.0, rect.position.y * T + rect.size.y * T / 2.0)
		body.add_child(c)


# ================================================================== Prédios
func _build_buildings() -> void:
	for d in BUILDING_DEFS:
		var t: Vector2i = d["tile"]
		var pos := Vector2(t.x * T + 8, t.y * T)
		var interior: String = d["id"] if d["id"] in ["casa", "restaurante", "guilda", "biblioteca"] else ""
		var b := Building.create(world, d["id"], d["name"], d["prop"], pos, d["door_dx"], interior)
		if d.has("tint") and b.sprite != null:
			b.sprite.modulate = d["tint"]
		buildings[d["id"]] = b
		if interior != "":
			door_spawns[interior] = pos + Vector2(d["door_dx"], 24)
		var npc := NPC.create(world, d["npc"], pos + Vector2(d["npc_dx"], 10), "static")
		npc.lines = d["lines"]
	for i in HOUSE_DEFS.size():
		var d: Dictionary = HOUSE_DEFS[i]
		var t: Vector2i = d["tile"]
		var pos := Vector2(t.x * T + 8, t.y * T)
		var key := "casa_npc_%d" % i
		var b := Building.create(world, "casa_npc", Interior.house_title(i), d["prop"], pos, 0.0, key)
		b.label.visible = false
		door_spawns[key] = pos + Vector2(0, 24)


func _build_gate() -> void:
	var pos := Vector2(SPINE_X * T + 8, GATE_Y * T)
	_add_prop("h_torii", pos, 0.0)
	# colunas de colisão do portal (deixa o vão central livre)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	world.add_child(body)
	for dx in [-13.0, 13.0]:
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = Vector2(5, 8)
		c.shape = s
		c.position = pos + Vector2(dx, -5)
		body.add_child(c)
	_add_prop("h_estatua_pequena", pos + Vector2(-34, 4), 6.0)
	_add_prop("h_estatua_pequena", pos + Vector2(34, 4), 6.0)
	var trigger := GateTrigger.new()
	trigger.position = pos + Vector2(0, 4)
	trigger.interact_range = 22.0
	world.add_child(trigger)
	Fx.make_light(world, pos + Vector2(0, -10), Color(1.0, 0.45, 0.35), 0.7, 0.0).name = "GateLight"
	var l := Label.new()
	l.text = "Portão da Masmorra"
	l.add_theme_font_override("font", Pix.font(1))
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color("ffd9c2"))
	l.add_theme_color_override("font_outline_color", Color("2a1018"))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(200, 14)
	l.position = pos + Vector2(-100, -48)
	l.z_index = 60
	world.add_child(l)


class GateTrigger extends Interactable:
	func _init() -> void:
		prompt_text = "Entrar na masmorra"

	func interact(_player: Node) -> void:
		Audio.sfx("ui_open", -4.0)
		HUD.open_window("dungeon")


# ============================================================ Trilha da Floresta
## Saída oeste da avenida: Osvaldo cobra o pedágio (1 crédito por dia) e leva à floresta.
func _build_forest_gate() -> void:
	var pos := Vector2(4 * T, AVENUE_Y * T + 8)
	for dy in [-30.0, -18.0, 26.0, 38.0]:
		_add_prop("h_cerca_ferro", pos + Vector2(2, dy), 4.0)
	_add_prop("i_board", pos + Vector2(26, -26), 4.0)
	_add_prop("i_barrel", pos + Vector2(30, 30), 5.0)
	var osv := NPC.create(world, "OldMan", pos + Vector2(14, -14), "static")
	osv.lines = ["Pedágio da floresta: 1 crédito.", "Estudou hoje?", "Cuidado com os lobos."]
	StoryProp.talker(osv, "osvaldo", "Osvaldo (Trilha da Floresta)")
	var l := Label.new()
	l.text = "Trilha da Floresta"
	l.add_theme_font_override("font", Pix.font(1))
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color("d9ffc2"))
	l.add_theme_color_override("font_outline_color", Color("10200f"))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(160, 14)
	l.position = pos + Vector2(-40, -52)
	l.z_index = 60
	world.add_child(l)
	# Ivo passeia pela cidade depois do exame de Rank E
	if Story.chapter() >= 2 and Story.step() not in ["c2_exame"]:
		var ivo := NPC.create(world, "NinjaBlue2", Vector2(SPINE_X * T + 40, 21 * T), "wander")
		ivo.wander_points = road_points
		ivo.wander_radius = 120.0
		ivo.move_speed = 22.0
		ivo.lines = ["Hoje eu ganho de você.", "Já fez seu foco de hoje?"]
		StoryProp.talker(ivo, "ivo", "Ivo")


# ==================================================================== Decor
func _add_prop(prop: String, pos: Vector2, collide_radius: float = 0.0) -> Sprite2D:
	var tex := Pix.tex("props/%s.png" % prop)
	var holder := Node2D.new()
	holder.position = pos.round()
	world.add_child(holder)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var sz := tex.get_size() if tex != null else Vector2(16, 16)
	s.offset = Vector2(-sz.x / 2.0, -sz.y)
	holder.add_child(s)
	if collide_radius > 0.0:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var c := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = collide_radius
		c.shape = circle
		c.position = Vector2(0, -collide_radius)
		body.add_child(c)
		holder.add_child(body)
	return s


func _free_cell(x: int, y: int, min_d: float, pt: Vector2) -> bool:
	if x < 4 or y < 4 or x > W - 5 or y > H - 5:
		return false
	if reserved[_idx(x, y)] != 0:
		return false
	for p in placed_points:
		if (p as Vector2).distance_to(pt) < min_d:
			return false
	return true


func _scatter(props: Array, count: int, min_d: float, collide: bool, jitter: bool = true) -> void:
	var tries := count * 12
	var placed := 0
	while placed < count and tries > 0:
		tries -= 1
		var x := rng.randi_range(4, W - 5)
		var y := rng.randi_range(4, H - 5)
		var pt := Vector2(x * T + (rng.randi_range(2, 14) if jitter else 8), y * T + (rng.randi_range(4, 15) if jitter else 14))
		if not _free_cell(x, y, min_d, pt):
			continue
		var prop: String = props[rng.randi() % props.size()]
		var tex := Pix.tex("props/%s.png" % prop)
		var radius := 0.0
		if collide and tex != null:
			radius = clampf(tex.get_size().x * 0.14, 3.5, 9.0)
		_add_prop(prop, pt, radius)
		placed_points.append(pt)
		placed += 1


func _build_decor() -> void:
	# floresta nas bordas (sem colisão própria — as paredes invisíveis cuidam disso)
	var x := -10.0
	while x < W * T + 10:
		_add_prop(BORDER_TREES[rng.randi() % BORDER_TREES.size()], Vector2(x + rng.randf_range(-4, 4), rng.randf_range(26, 52)))
		_add_prop(BORDER_TREES[rng.randi() % BORDER_TREES.size()], Vector2(x + rng.randf_range(-4, 4), H * T - rng.randf_range(4, 30)))
		x += rng.randf_range(24, 34)
	var y := 60.0
	while y < H * T - 40:
		_add_prop(BORDER_TREES[rng.randi() % BORDER_TREES.size()], Vector2(rng.randf_range(-2, 40), y))
		_add_prop(BORDER_TREES[rng.randi() % BORDER_TREES.size()], Vector2(W * T - rng.randf_range(0, 40), y + 6.0))
		y += rng.randf_range(24, 34)
	# árvores, arbustos, pedras e frutas espalhados
	_scatter(TREE_PROPS, 34, 44.0, true)
	_scatter(["n_arbusto1", "n_arbusto2", "n_arbusto3", "n_arbusto4", "n_arbusto5"], 26, 18.0, false)
	_scatter(["n_pedra_cinza", "n_pedra_cinza_p1", "n_pedra_cinza_p2", "n_pedra_marrom", "n_pedra_marrom_p1", "n_pedra_marrom_p3"], 14, 30.0, true)
	_scatter(["n_frutas_bush1", "n_frutas_bush2", "n_frutas_bush3", "n_frutas_bush4", "n_frutas_bush5", "n_frutas_bush6", "n_frutas_bush_g1", "n_frutas_bush_g3"], 12, 34.0, true)
	_scatter(["n_cristal1", "n_cristal2", "n_cristal3", "n_cristal4", "n_toco1"], 8, 40.0, false)


# ===================================================================== Gente
func _build_npcs() -> void:
	var lines := ["Bom dia!", "Que tal uma sessão de foco?", "A cidade está tranquila.", "Cuidado na masmorra!", "Já comeu hoje?"]
	var picks := WANDERERS.duplicate()
	picks.shuffle()
	for i in 5:
		var pt: Vector2 = road_points[rng.randi() % road_points.size()]
		var n := NPC.create(world, picks[i % picks.size()], pt, "wander")
		n.wander_points = road_points
		n.wander_radius = 220.0
		n.move_speed = rng.randf_range(14.0, 20.0)
		n.lines = lines
	# bichinhos
	var animals := [["ChickenWhite", 1], ["ChickenBrown", 1], ["Cat", 1], ["Dog", 1]]
	for a in animals:
		for k in a[1]:
			var pos := _random_grass_near(Vector2(520, 460), 330.0)
			var n2 := NPC.create(world, a[0], pos, "animal")
			n2.wander_radius = 70.0
			n2.move_speed = 9.0 if a[0] in ["Pig", "Cow"] else 13.0
			n2.animal_flip_right = false
			n2.wander_points = []


func _random_grass_near(center: Vector2, radius: float) -> Vector2:
	for _i in 60:
		var a := rng.randf() * TAU
		var r := rng.randf() * radius
		var p := center + Vector2(cos(a), sin(a) * 0.7) * r
		var tx := int(p.x / T)
		var ty := int(p.y / T)
		if tx < 5 or ty < 5 or tx > W - 6 or ty > H - 6:
			continue
		if water[_idx(tx, ty)] != 0 or reserved[_idx(tx, ty)] != 0 and dirt[_idx(tx, ty)] == 0:
			continue
		return p
	return center


func _build_ambient() -> void:
	# borboletas voando perto das flores
	for i in 6:
		var b := Butterfly.new()
		b.position = _random_grass_near(Vector2(520, 460), 380.0) + Vector2(0, -12)
		b.home = b.position
		add_child(b)


class Butterfly extends Node2D:
	var home: Vector2
	var t: float = randf() * 10.0
	var spr: AnimatedSprite2D
	var speed: float = randf_range(0.6, 1.1)
	var variant: String = ["Butterfly", "ButterflyBlue"][randi() % 2]

	func _ready() -> void:
		spr = AnimatedSprite2D.new()
		spr.sprite_frames = Pix.actor_frames("monsters/%s.png" % variant)
		spr.z_index = 30
		spr.scale = Vector2(0.8, 0.8)
		add_child(spr)
		spr.play("walk_down")
		spr.speed_scale = 1.8

	func _process(delta: float) -> void:
		t += delta * speed
		var target := home + Vector2(sin(t * 0.9) * 46.0, cos(t * 0.7) * 24.0 + sin(t * 2.3) * 4.0)
		var v := target - position
		position += v * minf(1.0, delta * 2.0)
		var dn := Pix.dir_name(v)
		var anim := "walk_" + dn
		if spr.animation != anim:
			spr.play(anim)


# ================================================================ Jogador
func _spawn_player() -> void:
	var spawn := Vector2(SPINE_X * T + 8, 29 * T)
	if Game.town_spawn == "gate":
		spawn = Vector2(SPINE_X * T + 8, (GATE_Y - 3) * T)
	elif Game.town_spawn == "forest":
		spawn = Vector2(6 * T, AVENUE_Y * T + 8)
	elif Game.town_spawn.begins_with("door:"):
		spawn = door_spawns.get(Game.town_spawn.substr(5), spawn)
	player = Player.spawn(world, spawn)
	player.set_camera_limits(Rect2(0, 0, W * T, H * T))


# ================================================================ Dia e noite
func _daylight_color(hour: float) -> Color:
	var night := Color(0.34, 0.38, 0.62)
	var dawn := Color(0.98, 0.84, 0.78)
	var day := Color(1, 1, 1)
	var dusk := Color(1.0, 0.76, 0.6)
	if hour < 5.0 or hour >= 21.0:
		return night
	if hour < 7.0:
		return night.lerp(dawn, (hour - 5.0) / 2.0)
	if hour < 9.0:
		return dawn.lerp(day, (hour - 7.0) / 2.0)
	if hour < 17.0:
		return day
	if hour < 19.0:
		return day.lerp(dusk, (hour - 17.0) / 2.0)
	return dusk.lerp(night, (hour - 19.0) / 2.0)


func _update_daylight() -> void:
	var hour := forced_hour
	if hour < 0.0:
		var t := Time.get_time_dict_from_system()
		hour = float(t["hour"]) + float(t["minute"]) / 60.0
	var c := _daylight_color(hour)
	canvas_mod.color = c
	var darkness := clampf((1.0 - c.r) * 1.6, 0.0, 1.0)
	for b in buildings.values():
		(b as Building).set_night(darkness)
	var gl := world.get_node_or_null("GateLight") as PointLight2D
	if gl != null:
		gl.energy = darkness * 0.9
	Audio.play_music("town_night" if darkness > 0.6 else "town")
