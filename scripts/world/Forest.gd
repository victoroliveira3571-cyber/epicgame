extends Node2D

## A floresta (expansão da história): mapa grande a oeste da cidade, com cinco zonas de
## dificuldade crescente (Data.FOREST_ZONES):
##   Borda da Floresta (leste, perto da cidade) > Clareira das Casas > rio e ponte >
##   Mata Profunda (norte) e Pântano da Névoa (sul) > Ruínas sob as Raízes (oeste).
## Entrada pela cidade com pedágio de 1 crédito (Osvaldo). Ervas, casas, caçadores e os
## eventos dos capítulos 1 e 2 moram aqui. Mesma interface de minimapa da cidade (grupo "town").

const W := 112
const H := 72
const T := 16
const PATH_Y := 36              # linha da trilha principal (leste-oeste)
const RIVER_X := 46             # rio (colunas RIVER_X..RIVER_X+2), ponte na trilha
const RUINS_X := 17             # oeste disto: ruínas

var rng := RandomNumberGenerator.new()
var world: Node2D
var player: Player
var canvas_mod: CanvasModulate
var buildings: Dictionary = {}
var minimap_tex: Texture2D
var dirt := PackedByteArray()
var water := PackedByteArray()
var stone := PackedByteArray()
var dark := PackedByteArray()
var reserved := PackedByteArray()
var placed_points: Array = []
var door_spawns: Dictionary = {}
var forced_hour: float = -1.0
var _zone: String = ""
var _zone_timer: float = 0.0
var _daylight_timer: float = 0.0
var _barrier: StaticBody2D = null
var _pietro_c1: NPC = null
var _leaving: bool = false

const TREES_LIGHT := ["n_arvore_redonda", "n_arvore_redonda2", "n_arvore_redonda3", "n_arvore_grande", "n_arvores_trio", "n_arvore_rosa"]
const TREES_DARK := ["n_arvore_pinheiro", "n_pinheiros_trio", "n_arvore_grande", "n_arvore_raiz", "n_arvores_trio_b", "n_arvore_seca"]
const BUSHES := ["n_arbusto1", "n_arbusto2", "n_arbusto3", "n_arbusto4", "n_arbusto5", "n_mato1", "n_mato2", "n_mato3", "n_mato4"]
const ROCKS := ["n_pedra_cinza", "n_pedra_cinza_p1", "n_pedra_cinza_p2", "n_pedra_marrom", "n_pedra_marrom_p1", "n_pedra_marrom_p3", "n_toco1", "n_toco2"]


func _ready() -> void:
	rng.seed = 20261101
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			forced_hour = float(arg.substr(7))
	add_to_group("town")
	add_to_group("forest")
	_build_masks()
	var img := TileComposer.compose_forest(W, H, dirt, water, stone, dark, rng)
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
	_build_bounds()
	_build_water_colliders()
	_build_houses()
	_build_ruins()
	if Story.step() == "c1_portao":
		Story.set_step("c1_ervas")
	_build_story()
	_build_decor()
	_build_sounds()
	_build_herbs()
	_build_monsters()
	_build_fog()
	_spawn_player()
	canvas_mod = CanvasModulate.new()
	add_child(canvas_mod)
	_update_daylight()
	Audio.play_music("ambience_nature")
	HUD.on_scene_ready("forest")


func _process(delta: float) -> void:
	_daylight_timer -= delta
	if _daylight_timer <= 0.0:
		_daylight_timer = 4.0
		_update_daylight()
	_zone_timer -= delta
	if _zone_timer <= 0.0 and player != null:
		_zone_timer = 0.4
		_check_zone()
		_check_story_triggers()
	if player != null and not _leaving and player.global_position.x > (W - 2) * T:
		_leaving = true
		Game.go_to_town("forest")


# ================================================================== Máscaras
func _idx(x: int, y: int) -> int:
	return y * W + x


func _fill(mask: PackedByteArray, x0: int, y0: int, x1: int, y1: int, v: int = 1) -> void:
	for y in range(maxi(y0, 0), mini(y1, H - 1) + 1):
		for x in range(maxi(x0, 0), mini(x1, W - 1) + 1):
			mask[_idx(x, y)] = v


func _ellipse(mask: PackedByteArray, cx: float, cy: float, rx: float, ry: float, v: int = 1) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if x < 0 or y < 0 or x >= W or y >= H:
				continue
			var dx := (float(x) - cx) / rx
			var dy := (float(y) - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				mask[_idx(x, y)] = v


## Zona de um tile (para monstros, ervas e o aviso de zona).
func zone_at(tx: int, ty: int) -> String:
	if tx >= 78:
		return "borda"
	if tx > RIVER_X + 2:
		return "clareira"
	if tx <= RUINS_X and ty >= 24 and ty <= 48:
		return "ruinas"
	if ty > PATH_Y + 6:
		return "pantano"
	return "mata"


func _build_masks() -> void:
	for m in [dirt, water, stone, dark, reserved]:
		m.resize(W * H)
		m.fill(0)
	# trilha principal (leste-oeste) com curvas suaves
	for x in range(4, W):
		var wob := int(round(sin(float(x) * 0.13) * 1.6))
		_fill(dirt, x, PATH_Y - 1 + wob, x, PATH_Y + 1 + wob)
	# ramos: árvore marcada (norte da Borda), toca da loba (sul da Clareira), pântano, mata
	_fill(dirt, 85, 12, 87, PATH_Y)
	_ellipse(dirt, 86, 11, 5.0, 3.5)
	_fill(dirt, 61, PATH_Y, 63, 60)
	_ellipse(dirt, 62, 61, 4.0, 2.5)
	_fill(dirt, 31, PATH_Y, 32, 58)
	_fill(dirt, 27, 14, 28, PATH_Y)
	# Clareira das Casas: campo aberto
	_ellipse(dirt, 64, 36, 10.0, 7.0)
	# rio (norte-sul) e lagoas do pântano
	for y in H:
		var bend := int(round(sin(float(y) * 0.2) * 1.2))
		_fill(water, RIVER_X + bend, y, RIVER_X + 2 + bend, y)
	for pond in [Vector4(24, 52, 4, 3), Vector4(37, 56, 5, 3), Vector4(26, 63, 5, 3), Vector4(39, 66, 4, 2), Vector4(20, 45, 2, 2)]:
		_ellipse(water, pond.x, pond.y, pond.z, pond.w)
	# ponte: a trilha passa por cima do rio
	for y in range(PATH_Y - 1, PATH_Y + 2):
		for x in range(RIVER_X - 2, RIVER_X + 5):
			water[_idx(x, y)] = 0
			dirt[_idx(x, y)] = 1
	# ruínas: chão de pedra
	_ellipse(stone, 9, 36, 8.0, 9.0)
	_fill(stone, 14, PATH_Y - 1, 18, PATH_Y + 1)
	for y in H:
		for x in W:
			var i := _idx(x, y)
			if stone[i] != 0:
				dirt[i] = 0
				water[i] = 0
	# sombra da mata e do pântano
	for y in H:
		for x in W:
			var z := zone_at(x, y)
			var a := 0
			if z == "mata":
				a = 105
			elif z == "pantano":
				a = 115
			elif z == "ruinas":
				a = 70
			elif z == "clareira" and x < 54:
				a = 30
			dark[_idx(x, y)] = a
	_blur_dark(6)
	# reservas: caminhos e água com folga, bordas
	for y in H:
		for x in W:
			if dirt[_idx(x, y)] != 0 or water[_idx(x, y)] != 0 or stone[_idx(x, y)] != 0:
				_fill(reserved, x - 1, y - 1, x + 1, y + 1)
	_fill(reserved, 52, 22, 76, 50)     # a clareira fica aberta (casas e acampamento)


## Suaviza a sombra entre zonas (borda, clareira, mata, pântano): a luz muda aos poucos, sem degrau.
func _blur_dark(radius: int) -> void:
	for _pass in 2:
		var tmp := PackedByteArray()
		tmp.resize(W * H)
		for y in H:
			for x in W:
				var sum := 0
				var n := 0
				for k in range(-radius, radius + 1):
					var xx := clampi(x + k, 0, W - 1)
					sum += dark[_idx(xx, y)]
					n += 1
				tmp[_idx(x, y)] = sum / n
		for y in H:
			for x in W:
				var sum2 := 0
				var n2 := 0
				for k in range(-radius, radius + 1):
					var yy := clampi(y + k, 0, H - 1)
					sum2 += tmp[_idx(x, yy)]
					n2 += 1
				dark[_idx(x, y)] = sum2 / n2


func _build_bounds() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var m := 2 * T
	for r in [Rect2(-64, -64, W * T + 128, 64 + m), Rect2(-64, H * T - m, W * T + 128, 64 + m),
			Rect2(-64, -64, 64 + m, H * T + 128), Rect2(W * T + 2, -64, 64, H * T + 128)]:
		var c := CollisionShape2D.new()
		var s := RectangleShape2D.new()
		s.size = r.size
		c.shape = s
		c.position = r.position + r.size / 2.0
		body.add_child(c)


func _build_water_colliders() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	for y in H:
		var x := 0
		while x < W:
			if water[_idx(x, y)] != 0:
				var x0 := x
				while x < W and water[_idx(x, y)] != 0:
					x += 1
				var c := CollisionShape2D.new()
				var s := RectangleShape2D.new()
				s.size = Vector2((x - x0) * T - 4, T - 4)
				c.shape = s
				c.position = Vector2(x0 * T + (x - x0) * T / 2.0, y * T + T / 2.0)
				body.add_child(c)
			else:
				x += 1


# ================================================================== Peças
func _add_prop(prop: String, pos: Vector2, collide_radius: float = 0.0, tint: Color = Color.WHITE) -> Node2D:
	var tex := Interior.prop_tex(prop)
	var holder := Node2D.new()
	holder.position = pos.round()
	world.add_child(holder)
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.modulate = tint
	var sz := tex.get_size() if tex != null else Vector2(16, 16)
	s.offset = Vector2(-sz.x / 2.0, -sz.y)
	holder.add_child(s)
	if collide_radius > 0.0:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var c := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = collide_radius
		c.shape = circle
		c.position = Vector2(0, -collide_radius)
		body.add_child(c)
		holder.add_child(body)
	return holder


func _tile_pos(tx: float, ty: float) -> Vector2:
	return Vector2(tx * T + 8, ty * T + 12)


func _free(x: int, y: int, min_d: float, pt: Vector2) -> bool:
	if x < 2 or y < 2 or x > W - 3 or y > H - 3:
		return false
	if reserved[_idx(x, y)] != 0:
		return false
	for p in placed_points:
		if (p as Vector2).distance_to(pt) < min_d:
			return false
	return true


func _random_spot(zone: String, min_d: float = 0.0, on_path_ok: bool = false) -> Vector2:
	for _i in 200:
		var x := rng.randi_range(3, W - 4)
		var y := rng.randi_range(3, H - 4)
		if zone != "" and zone_at(x, y) != zone:
			continue
		var i := _idx(x, y)
		if water[i] != 0:
			continue
		if not on_path_ok and reserved[i] != 0 and dirt[i] == 0 and stone[i] == 0:
			continue
		var pt := Vector2(x * T + rng.randi_range(3, 13), y * T + rng.randi_range(4, 14))
		var ok := true
		for p in placed_points:
			if (p as Vector2).distance_to(pt) < min_d:
				ok = false
				break
		if ok:
			return pt
	return _tile_pos(64, PATH_Y)


## Locais nomeados para o mapa grande (tecla M): [id, nome, posição em px].
func map_landmarks() -> Array:
	var out: Array = []
	for id in buildings:
		var b: Node2D = buildings[id]
		out.append([str(id), str(b.get("display_name")), b.position])
	for l in [["saida_cidade", "Saída para Focus Town", Vector2(W - 5, PATH_Y)], ["borda", "Borda da Floresta", Vector2(95, PATH_Y)],
			["clareira", "Clareira das Casas", Vector2(64, 36)], ["acampamento", "Acampamento dos Caçadores", Vector2(62, 42)],
			["arvore_marcada", "Árvore Marcada", Vector2(86, 11)], ["toca", "Toca da Loba", Vector2(62, 61)],
			["ponte", "Ponte do Rio", Vector2(RIVER_X + 1, PATH_Y)], ["mata", "Mata Profunda", Vector2(30, 22)],
			["pantano", "Pântano da Névoa", Vector2(30, 60)], ["ruinas", "Ruínas sob as Raízes", Vector2(9, 36)]]:
		out.append([l[0], l[1], (l[2] as Vector2) * float(T) + Vector2(8, 8)])
	return out


# ================================================================== Casas e ruínas
func _build_houses() -> void:
	var defs := [
		{"id": "casa_familia", "title": "Casa da Família", "prop": "b_casa_creme", "tile": Vector2i(58, 30), "interior": "casa_familia"},
		{"id": "casa_pai", "title": "Casa Abandonada", "prop": "b_casa_laranja2", "tile": Vector2i(71, 30), "interior": "casa_pai", "tint": Color(0.7, 0.66, 0.62)},
		{"id": "cabana", "title": "Cabana do Pietro", "prop": "b_estalagem", "tile": Vector2i(70, 45), "interior": ""},
	]
	for d in defs:
		var t: Vector2i = d["tile"]
		var pos := Vector2(t.x * T + 8, t.y * T)
		var b := Building.create(world, d["id"], d["title"], d["prop"], pos, 0.0, d["interior"])
		b.return_scene = "forest"
		if d.has("tint") and b.sprite != null:
			b.sprite.modulate = d["tint"]
		if d["interior"] == "":
			b.door.enabled = false
		buildings[d["id"]] = b
		door_spawns[d["interior"]] = pos + Vector2(0, 24)
		for yy in range(t.y - 5, t.y + 2):
			for xx in range(t.x - 4, t.x + 5):
				if xx >= 0 and yy >= 0 and xx < W and yy < H:
					reserved[_idx(xx, yy)] = 1
	# acampamento dos caçadores: fogueira, caixotes, barris e o mural
	var camp := _tile_pos(62, 42)
	var fire := DungeonObjects.Torch.new()
	fire.position = camp
	world.add_child(fire)
	fire.scale = Vector2(1.8, 1.8)
	for o in [["i_crate", Vector2(-26, -4)], ["i_barrel", Vector2(28, -6)], ["i_barrel2", Vector2(36, 4)], ["i_sack", Vector2(-34, 8)], ["i_stool", Vector2(-12, 10)], ["i_stool", Vector2(14, 10)]]:
		_add_prop(o[0], camp + o[1], 5.0)
	_add_prop("quadro_missoes", camp + Vector2(0, -26), 6.0)
	# varal e cercas perto das casas
	# cerca de ferro: uma peça só (ela já tem ~68 px; empilhar várias virava uma grade preta sobre a casa)
	_add_prop("h_cerca_ferro", _tile_pos(52, 33), 4.0, Color(0.75, 0.6, 0.45))


func _build_ruins() -> void:
	# árvore gigante na entrada das ruínas e pilares/estátuas no salão de pedra
	_add_prop("n_arvore_raiz", _tile_pos(16, 31), 10.0, Color(0.85, 0.85, 0.9))
	_add_prop("n_arvore_raiz", _tile_pos(16, 41), 10.0, Color(0.85, 0.85, 0.9))
	for p in [Vector2(4, 30), Vector2(14, 30), Vector2(4, 42), Vector2(14, 42), Vector2(9, 28)]:
		_add_prop("h_estatua_pequena_verde" if int(p.x) % 2 == 0 else "h_estatua_pequena", _tile_pos(p.x, p.y), 6.0, Color(0.8, 0.82, 0.9))
	for p2 in [Vector2(3, 36), Vector2(15, 36)]:
		_add_prop("h_estatua_grande_verde", _tile_pos(p2.x, p2.y), 8.0, Color(0.75, 0.78, 0.86))
	var lbl := Label.new()
	lbl.text = "Ruínas sob as Raízes"
	lbl.add_theme_font_override("font", Pix.font(1))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("cfe3ff"))
	lbl.add_theme_color_override("font_outline_color", Color("101828"))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.position = _tile_pos(15, 34) + Vector2(-60, -60)
	lbl.size = Vector2(120, 14)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.z_index = 60
	world.add_child(lbl)


# ================================================================== Decoração
## Sons: rio (vários pontos), pássaros/grilos/coruja, ovelhas ao longe na Clareira, goteira nas Ruínas.
func _build_sounds() -> void:
	var amb := Ambience.new()
	amb.bird_every = 6.0
	world.add_child(amb)
	for ty in [12, 30, 48, 62]:
		Audio.emitter(world, Vector2((RIVER_X + 1) * T, ty * T), "amb_margem", -10.0, true, 0.0, 200.0)
	Audio.emitter(world, Vector2(64 * T, 30 * T), "ovelha", -14.0, false, 22.0, 260.0)
	Audio.emitter(world, Vector2(8 * T, 36 * T), "amb_goteira", -8.0, true, 0.0, 220.0)


func _build_decor() -> void:
	# borda densa de árvores em volta do mapa
	var x := -8.0
	while x < W * T + 8:
		_add_prop(TREES_DARK[rng.randi() % TREES_DARK.size()], Vector2(x, rng.randf_range(20, 40)))
		_add_prop(TREES_DARK[rng.randi() % TREES_DARK.size()], Vector2(x, H * T - rng.randf_range(0, 20)))
		x += rng.randf_range(20, 30)
	var y := 40.0
	while y < H * T - 20:
		_add_prop(TREES_DARK[rng.randi() % TREES_DARK.size()], Vector2(rng.randf_range(0, 24), y))
		y += rng.randf_range(20, 30)
	# árvores por zona: mais fechado quanto mais fundo
	var density := {"borda": 0.07, "clareira": 0.05, "mata": 0.2, "pantano": 0.1, "ruinas": 0.03}
	for ty in range(3, H - 3):
		for tx in range(3, W - 3):
			var z := zone_at(tx, ty)
			if rng.randf() > float(density[z]):
				continue
			var pt := Vector2(tx * T + rng.randi_range(2, 14), ty * T + rng.randi_range(4, 15))
			if not _free(tx, ty, 26.0, pt):
				continue
			var list: Array = TREES_LIGHT if z == "borda" or z == "clareira" else TREES_DARK
			var prop: String = list[rng.randi() % list.size()]
			var tint := Color.WHITE if z == "borda" or z == "clareira" else Color(0.78, 0.85, 0.82)
			var tex := Interior.prop_tex(prop)
			_add_prop(prop, pt, clampf(tex.get_size().x * 0.14, 3.5, 9.0) if tex != null else 4.0, tint)
			placed_points.append(pt)
	for _i in 120:
		var z2: String = ["borda", "clareira", "mata", "pantano"][rng.randi() % 4]
		var p := _random_spot(z2, 18.0)
		var bush: String = BUSHES[rng.randi() % BUSHES.size()]
		var btex := Interior.prop_tex(bush)
		_add_prop(bush, p, clampf((btex.get_size().x if btex != null else 16.0) * 0.2, 3.0, 6.0))   # arbusto: pequeno obstáculo
		placed_points.append(p)
	for _i in 40:
		var p2 := _random_spot("", 30.0)
		var rock: String = ROCKS[rng.randi() % ROCKS.size()]
		var rtex := Interior.prop_tex(rock)
		_add_prop(rock, p2, clampf((rtex.get_size().x if rtex != null else 16.0) * 0.3, 4.0, 10.0))
		placed_points.append(p2)
	for _i in 18:
		var p3 := _random_spot("borda" if rng.randf() < 0.6 else "clareira", 30.0)
		_add_prop(["n_flor_girassol", "n_flor_margarida", "n_flor_trevo", "n_flor_vermelha", "n_frutas_bush1", "n_frutas_bush3"][rng.randi() % 6], p3)
	for _i in 10:
		var p4 := _random_spot("pantano", 24.0)
		_add_prop(["n_cristal1", "n_cristal2", "n_mato5", "n_mato6"][rng.randi() % 4], p4, 0.0, Color(0.7, 0.85, 1.0))


## Neblina: manchas claras que andam devagar na mata e no pântano.
func _build_fog() -> void:
	for _i in 26:
		var z := "mata" if rng.randf() < 0.55 else "pantano"
		var f := Fog.new()
		f.position = _random_spot(z, 0.0, true)
		f.home = f.position
		add_child(f)


class Fog extends Node2D:
	var home: Vector2
	var t: float = randf() * 20.0
	var r: float = randf_range(28.0, 52.0)

	func _ready() -> void:
		z_index = 40

	func _process(delta: float) -> void:
		t += delta * 0.25
		position = home + Vector2(sin(t) * 30.0, cos(t * 0.7) * 14.0)
		modulate.a = 0.10 + 0.05 * sin(t * 2.0)
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, r, Color(0.85, 0.9, 1.0, 0.55))
		draw_circle(Vector2(r * 0.6, -r * 0.2), r * 0.7, Color(0.85, 0.9, 1.0, 0.45))


# ================================================================== Ervas e monstros
func _build_herbs() -> void:
	var counts := {"borda": 10, "clareira": 7, "mata": 5, "pantano": 4}
	for z in counts:
		for _i in int(counts[z]):
			var p := _random_spot(z, 22.0)
			var herb := StoryProp.make_herb()
			herb.position = p
			world.add_child(herb)
			placed_points.append(p)


func _build_monsters() -> void:
	var counts := {"borda": 11, "clareira": 12, "mata": 16, "pantano": 12, "ruinas": 6}
	for z in counts:
		var zone: Dictionary = Data.FOREST_ZONES[z]
		var enemies: Array = zone["enemies"]
		for _i in int(counts[z]):
			var p := _random_spot(z, 40.0, z == "ruinas")
			if p.x > (W - 10) * T:
				continue   # nada colado na saída para a cidade
			var id: String = enemies[rng.randi() % enemies.size()]
			var elite: bool = rng.randf() < 0.06 and z != "borda"
			Enemy.spawn(world, id, p, int(zone["power"]) + rng.randi_range(0, 1), elite).respawn_s = Enemy.RESPAWN_TIME


# ================================================================== História
func _npc(sheet: String, tile: Vector2, id: String, title: String) -> NPC:
	var n := NPC.create(world, sheet, _tile_pos(tile.x, tile.y), "static")
	StoryProp.talker(n, id, title)
	return n


func _build_story() -> void:
	var s := Story.step()
	var ch := Story.chapter()
	# Pietro: na trilha da Borda no capítulo 1, no acampamento depois
	if s == "c1_ervas" and not Story.flag("pietro_c1"):
		_pietro_c1 = NPC.create(world, "Hunter", _tile_pos(93, PATH_Y - 2), "static")
	elif s not in ["c1_volta", "c4_pietro"]:   # nesses passos ele está na Guilda
		_npc("Hunter", Vector2(60, 41), "pietro", "Pietro")
	NPC.create(world, "Hunter", _tile_pos(65, 41), "static").lines = ["Boa caça hoje.", "A Mata Profunda engole quem anda sem luz.", "Ervas boas nascem perto da trilha."]
	# árvore marcada (norte da Borda)
	_add_prop("n_arvore_grande", _tile_pos(86, 8), 9.0, Color(0.8, 0.95, 0.8))
	if ch == 1 and s in ["c1_ervas", "c1_marca"]:
		var mark := StoryProp.make("Examinar a árvore marcada", func(me: StoryProp) -> void: _on_mark(me), null, 26.0)
		mark.position = _tile_pos(86, 9)
		world.add_child(mark)
	# Pena Dourada (exame de Rank E)
	if s == "c2_pena":
		var feather := StoryProp.make("Pegar a Pena Dourada", func(me: StoryProp) -> void:
			Audio.sfx("powerup", -2.0)
			me.vanish()
			await Story.say("c2_pena")
			Story.set_step("c2_entrega"), Pix.tex("items/resource/feather.png"), 18.0)
		feather.sprite.modulate = Color(1.4, 1.2, 0.4)
		feather.bob = true
		feather.position = _tile_pos(67, 26)
		world.add_child(feather)
		Fx.make_light(feather, Vector2(0, -8), Color(1.0, 0.85, 0.3), 0.6, 0.9)
		NPC.create(world, "NinjaBlue2", _tile_pos(69, 27), "static").lines = ["Ainda não acabou!", "Da próxima vez eu chego antes."]
	# toca da loba (capítulo 2)
	if s == "c2_brisa":
		var den := _tile_pos(62, 62)
		var mom := _wolf_sprite(den + Vector2(0, -6), 1.0)
		for k in 3:
			_wolf_sprite(den + Vector2(-16 + k * 16, 10), 0.6).set_meta("cub", true)
		var spot := StoryProp.make("Aproximar-se da toca", func(me: StoryProp) -> void: _on_den(me, mom), null, 30.0)
		spot.position = den + Vector2(0, 18)
		world.add_child(spot)
	# Mestre Lin: na ponte (capítulo 2) e na entrada das ruínas
	if s in ["c2_lin", "c2_carta"]:
		_npc("Master", Vector2(RIVER_X - 4, PATH_Y - 2), "lin", "Mestre Lin")
	elif s in ["c2_ruinas", "c2_sentinela"]:
		_npc("Master", Vector2(RUINS_X + 2, PATH_Y - 2), "lin", "Mestre Lin")
	# barreira da Mata: só Rank E ou maior
	if not Story.zone_unlocked("mata"):
		_barrier = StaticBody2D.new()
		_barrier.collision_layer = 1
		var c := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(10, 7 * T)
		c.shape = r
		c.position = Vector2((RIVER_X - 3) * T, PATH_Y * T + 8)
		_barrier.add_child(c)
		world.add_child(_barrier)
		var sign := StoryProp.make("Ler a placa", func(_me: StoryProp) -> void:
			Story.say([["narr", "\"Mata Profunda e Pântano da Névoa: somente aventureiros de Rank E ou maior. - A Guilda\""]]), null, 24.0, false)
		sign.position = _tile_pos(RIVER_X + 4, PATH_Y - 2)
		world.add_child(sign)
		_add_prop("i_board", sign.position, 4.0)
	# Sentinela de Pedra dorme no salão das ruínas até a hora dela
	if s in ["c2_ruinas", "c2_sentinela"]:
		var b := Boss.spawn_boss(world, "sentinela", _tile_pos(7, 36), int(Data.STORY_BOSSES["sentinela"]["power"]))
		b.died.connect(func(_e: Enemy) -> void: Story.on_boss_defeated("sentinela"))


func _on_mark(me: StoryProp) -> void:
	if Story.step() != "c1_marca":
		await Story.say([["narr", "Uma seta gravada na casca aponta para o norte. Corvin ainda não te trouxe até aqui: termine de colher as ervas e ajude quem precisa na trilha."]])
		me.enabled = true
		return
	await Story.say("c1_marca")
	if not Story.boss_ready("espirito_cacador"):
		await Story.say([["narr", "O espírito some na névoa. Ele exige 1 hora de foco acumulada (você tem %s h)." % Story._hours_text()]])
		me.enabled = true
		return
	var b := Boss.spawn_boss(world, "espirito_cacador", _tile_pos(86, 12), int(Data.STORY_BOSSES["espirito_cacador"]["power"]))
	b.died.connect(func(_e: Enemy) -> void: Story.on_boss_defeated("espirito_cacador"))
	me.queue_free()


## Loba e filhotes na toca (só imagem: a loba vira inimiga se o jogador escolher lutar).
func _wolf_sprite(pos: Vector2, k: float) -> Node2D:
	var holder := Node2D.new()
	holder.position = pos
	world.add_child(holder)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = Pix.actor_frames("monsters/Beast2.png")
	spr.play("walk_down")
	spr.speed_scale = 0.4
	spr.scale = Vector2(k, k)
	spr.position = Vector2(0, -8 * k)
	spr.self_modulate = Color(1.1, 1.1, 1.2)
	holder.add_child(spr)
	Fx.make_shadow(holder, 10.0 * k, 0.0)
	return holder


func _on_den(me: StoryProp, mom: Node2D) -> void:
	await Story.say("c2_brisa")
	if int(Story.flag("brisa_luta", 0)) == 0:
		await Story.say("c2_brisa_poupa")
		Story.give_pet("brisa")
		Story.set_step("c2_lin")
		mom.queue_free()
		me.queue_free()
		return
	await Story.say("c2_brisa_luta")
	var pos := mom.global_position
	mom.queue_free()
	var wolf := Enemy.spawn(world, "lobo", pos, 4, true)
	wolf.display_name = "Loba da Toca"
	wolf.died.connect(func(_e: Enemy) -> void:
		await get_tree().create_timer(0.8).timeout
		await Story.say("c2_brisa_derrota")
		GameState.add_gold(60)
		Story.set_step("c2_lin"))
	me.queue_free()


## Gatilhos por posição: Pietro sendo atacado (capítulo 1) e a entrada das ruínas (capítulo 2).
func _check_story_triggers() -> void:
	if Story.is_busy() or HUD.is_dialogue_open():
		return
	var pp := player.global_position
	if _pietro_c1 != null and is_instance_valid(_pietro_c1) and Story.step() == "c1_ervas" and not Story.flag("pietro_c1"):
		if pp.distance_to(_pietro_c1.global_position) < 90.0:
			Story.set_flag("pietro_c1")
			_pietro_event()
	if Story.step() == "c2_ruinas" and pp.x < (RUINS_X + 1) * T:
		Story.set_step("c2_sentinela")
		Story.say("c2_ruinas")


func _pietro_event() -> void:
	await Story.say("c1_pietro")
	var wolf := Enemy.spawn(world, "lobo_jovem", _pietro_c1.global_position + Vector2(26, 6), 2, false)
	wolf.state = Enemy.State.CHASE
	wolf.display_name = "Lobo Faminto"
	wolf.died.connect(func(_e: Enemy) -> void:
		await get_tree().create_timer(0.7).timeout
		await Story.say("c1_pietro2")
		Story.on_corvin()
		if _pietro_c1 != null and is_instance_valid(_pietro_c1):
			StoryProp.talker(_pietro_c1, "pietro", "Pietro"))


# ================================================================== Zonas
func _check_zone() -> void:
	var c := Vector2i(int(player.global_position.x / T), int(player.global_position.y / T))
	var z := zone_at(clampi(c.x, 0, W - 1), clampi(c.y, 0, H - 1))
	if z != _zone:
		var first := _zone == ""
		_zone = z
		if not first:
			var info: Dictionary = Data.FOREST_ZONES[z]
			HUD.floor_banner(info["name"], "Monstros nível %d a %d" % [int(info["power"]), int(info["power"]) + 1])
		Audio.play_music("dungeon3" if z == "pantano" else ("dungeon2" if z == "ruinas" else "ambience_nature"))


# ================================================================== Jogador
func _spawn_player() -> void:
	var spawn := _tile_pos(W - 5, PATH_Y)
	if Game.forest_spawn.begins_with("door:"):
		spawn = door_spawns.get(Game.forest_spawn.substr(5), spawn)
	player = Player.spawn(world, spawn)
	player.facing = Vector2.LEFT
	player.set_camera_limits(Rect2(0, 0, W * T, H * T))
	GameState.player_died.connect(_on_player_died, CONNECT_ONE_SHOT)


func _on_player_died() -> void:
	Audio.jingle("defeat", -4.0)
	await get_tree().create_timer(2.2).timeout
	Story.lose_credit_on_death()
	GameState.revive_after_defeat()
	HUD.show_toast("Você desmaiou na floresta. Pietro te trouxe de volta para a cidade.", UI.C_BAD)
	Game.go_to_town("forest")


# ================================================================ Dia e noite
func _update_daylight() -> void:
	var hour := forced_hour
	if hour < 0.0:
		var t := Time.get_time_dict_from_system()
		hour = float(t["hour"]) + float(t["minute"]) / 60.0
	var night := Color(0.3, 0.34, 0.56)
	var day := Color(0.96, 1.0, 0.94)
	var c := day
	if hour < 5.0 or hour >= 21.0:
		c = night
	elif hour < 8.0:
		c = night.lerp(day, (hour - 5.0) / 3.0)
	elif hour >= 18.0:
		c = day.lerp(night, (hour - 18.0) / 3.0)
	canvas_mod.color = c
