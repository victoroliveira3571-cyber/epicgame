extends Node2D

## v3.2: cenário das cidades novas (Porto Névoa, Pedralta, Academia de Fontelúcida). Um só script para as três:
## monta tudo a partir de CityData.CITIES[Game.city_id] (chão por bioma, água, prédios, moradores, minério).
## Mesma interface do minimapa e do mapa grande que Town e Forest (W, H, T, minimap_tex, buildings, map_landmarks).

const T := 16

var W: int = 60
var H: int = 44
var city: Dictionary = {}
var city_id: String = ""
var rng := RandomNumberGenerator.new()
var world: Node2D
var player: Player
var canvas_mod: CanvasModulate
var buildings: Dictionary = {}
var door_spawns: Dictionary = {}
var minimap_tex: Texture2D
var water := PackedByteArray()
var path_mask := PackedByteArray()
var piers := PackedByteArray()
var forced_hour: float = -1.0
var _daylight_timer: float = 0.0
var _leaving: bool = false
var _ore_nodes: Array = []
var extra_landmarks: Array = []    # v3.7: pontos da história no mapa (jardim, centro de treinamento, caverna)
var no_collide := PackedByteArray()  # v3.7: água sob pontes (desenhada, mas dá para andar por cima)


func _ready() -> void:
	city_id = Game.city_id if CityData.CITIES.has(Game.city_id) else "porto"
	city = CityData.get_city(city_id)
	W = int(city["W"])
	H = int(city["H"])
	rng.seed = hash(city_id) & 0x7fffffff
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			forced_hour = float(arg.substr(7))
	add_to_group("town")
	add_to_group("city")
	_build_masks()
	var layers: Array = []
	if water.count(1) > 0:
		layers.append({"mask": water, "set": "water", "origin": Vector2i(0, 6)})
	layers.append({"mask": path_mask, "set": str(city["path_set"]), "origin": city["path_origin"]})
	var img := TileComposer.compose_city(W, H, int(city["base_row"]), layers, rng, city["tint"])
	_stamp_fort_bridge(img)
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
	_build_piers()
	_build_buildings()
	_build_fort()
	_build_castle()
	_build_gardens()
	_build_npcs()
	_build_decor()
	_build_ore()
	_build_anim_decor()
	_build_story()
	_build_exit()
	_build_title()
	_spawn_player()
	canvas_mod = CanvasModulate.new()
	add_child(canvas_mod)
	_update_daylight()
	Audio.play_music(str(city.get("music", "town")))
	Audio.set_place_loop("")
	if str(city.get("ambience", "")) != "":
		Audio.emitter(world, Vector2(W * T / 2.0, (H - 4) * T), str(city["ambience"]), -14.0, true, 0.0, 400.0)
	HUD.on_scene_ready("town")


func _process(delta: float) -> void:
	_daylight_timer -= delta
	if _daylight_timer <= 0.0:
		_daylight_timer = 4.0
		_update_daylight()
	if player == null or _leaving:
		return
	var p := player.global_position
	var out := false
	match str(city["exit"]):
		"west":
			out = p.x < 1.5 * T
		"east":
			out = p.x > (W - 1.5) * T
		"south":
			out = p.y > (H - 1.5) * T
		_:
			out = p.y < 1.5 * T
	if out:
		_leaving = true
		if city_id == "estrada" and Game.road_dest != "" and CityData.CITIES.has(Game.road_dest):
			var d := Game.road_dest
			Game.road_dest = ""
			Game.go_to_city(d)
		else:
			Game.go_to_town("city")


# ================================================================== Máscaras
func _idx(x: int, y: int) -> int:
	return y * W + x


func _fill(mask: PackedByteArray, r: Array, v: int = 1) -> void:
	for y in range(maxi(int(r[1]), 0), mini(int(r[3]), H - 1) + 1):
		for x in range(maxi(int(r[0]), 0), mini(int(r[2]), W - 1) + 1):
			mask[_idx(x, y)] = v


func _build_masks() -> void:
	for m in [water, path_mask, piers, no_collide]:
		m.resize(W * H)
		m.fill(0)
	for r in city["paths"]:
		_fill(path_mask, r)
	for r in city["water"]:
		_fill(water, r)
	for r in city["piers"]:
		_fill(piers, r)
		_fill(water, r, 0)     # a doca fica sobre a água: tira da máscara para dar para andar
		_fill(path_mask, r, 0)
	# v3.7: fosso na frente da muralha (a ponte de pedra cruza no portão)
	var f: Dictionary = city.get("fort", {})
	if not f.is_empty() and bool(f.get("moat", false)):
		var my := int(f["wall_y"]) + 3
		_fill(water, [0, my, W - 1, my + 1])
		_fill(path_mask, [0, my, W - 1, my + 1], 0)
		var gx := int(f["gate_x"])
		_fill(no_collide, [gx, my, gx + 1, my + 1])


func _tile_pos(tx: float, ty: float) -> Vector2:
	return Vector2(tx * T + 8, ty * T + 12)


func _build_bounds() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var m := 2 * T
	for r in [Rect2(-64, -64, W * T + 128, 64 + m), Rect2(-64, H * T - m, W * T + 128, 64 + m),
			Rect2(-64, -64, 64 + m, H * T + 128), Rect2(W * T - m, -64, 64 + m, H * T + 128)]:
		# a saída da cidade fica sem parede
		var skip := false
		match str(city["exit"]):
			"west":
				skip = r.position.x == -64 and r.size.y > r.size.x
			"east":
				skip = r.position.x == W * T - m
			"south":
				skip = r.position.y == H * T - m and r.size.x > r.size.y
		if skip:
			continue
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
			if water[_idx(x, y)] != 0 and no_collide[_idx(x, y)] == 0:
				var x0 := x
				while x < W and water[_idx(x, y)] != 0 and no_collide[_idx(x, y)] == 0:
					x += 1
				var c := CollisionShape2D.new()
				var s := RectangleShape2D.new()
				s.size = Vector2((x - x0) * T - 4, T - 4)
				c.shape = s
				c.position = Vector2(x0 * T + (x - x0) * T / 2.0, y * T + T / 2.0)
				body.add_child(c)
			else:
				x += 1


## Tábuas de madeira sobre a água (chão, sem colisão).
func _build_piers() -> void:
	if piers.count(1) == 0:
		return
	var img := Image.create(W * T, H * T, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			if piers[_idx(x, y)] == 0:
				continue
			var px := x * T
			var py := y * T
			img.fill_rect(Rect2i(px, py, T, T), Color("9a6a3a"))
			img.fill_rect(Rect2i(px, py + 3, T, 1), Color("6e4824"))
			img.fill_rect(Rect2i(px, py + 8, T, 1), Color("6e4824"))
			img.fill_rect(Rect2i(px, py + 13, T, 1), Color("6e4824"))
			img.fill_rect(Rect2i(px + 1, py + 1, 1, 1), Color("c28e58"))
			img.fill_rect(Rect2i(px, py, 1, T), Color("4a2e14"))
			img.fill_rect(Rect2i(px + T - 1, py, 1, T), Color("4a2e14"))
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = false
	spr.z_index = -90
	add_child(spr)


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


func _label(text: String, pos: Vector2, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Pix.font(1))
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color("101828"))
	l.add_theme_constant_override("outline_size", 3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(200, 14)
	l.position = pos - Vector2(100, 0)
	l.z_index = 60
	world.add_child(l)


func _build_buildings() -> void:
	for d in city["buildings"]:
		var t: Array = d["tile"]
		var pos := Vector2(int(t[0]) * T + 8, int(t[1]) * T)
		var interior := str(d.get("interior", ""))
		var b := Building.create(world, str(d["id"]), str(d["title"]), str(d["prop"]), pos, 0.0, interior)
		b.return_scene = "city"
		if d.has("tint") and b.sprite != null:
			b.sprite.modulate = CityData.tint_of(d["tint"])
		if bool(d.get("closed", false)):
			b.door.enabled = false
		buildings[str(d["id"]) + ("_" + str(t[0]) if buildings.has(str(d["id"])) else "")] = b
		if interior != "":
			door_spawns[interior] = pos + Vector2(0, 24)


# ================================================================== Muralha, castelo e hortas (v3.7)
## Entrada de reino (referência do Victor): muralha com ameias de ponta a ponta na linha `wall_y` (3 tiles), portão
## com grade entre duas torres no vão `gate_x`..`gate_x + 1`, fosso com ponte de pedra do lado de fora, guardas,
## estandartes, tochas e bandeiras nas torres. Peças do Kenney Tiny Town (PROVISÓRIO, ver PROVISORIOS.md).
func _build_fort() -> void:
	var f: Dictionary = city.get("fort", {})
	if f.is_empty():
		return
	var wy := int(f["wall_y"])
	var gx := int(f["gate_x"])
	var g0 := gx - 3
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var base_y := (wy + 3) * T
	if g0 > 0:
		_add_prop("k_muralha_%d" % g0, Vector2(g0 * T / 2.0, base_y))
		_rect_collider(body, Rect2(0, wy * T, g0 * T, 3 * T))
	var r0 := g0 + 8
	if r0 < W:
		_add_prop("k_muralha_%d" % (W - r0), Vector2((r0 + (W - r0) / 2.0) * T, base_y))
		_rect_collider(body, Rect2(r0 * T, wy * T, (W - r0) * T, 3 * T))
	_add_prop("k_portao", Vector2((g0 + 4) * T, base_y))
	_rect_collider(body, Rect2(g0 * T, (wy - 2) * T, 3 * T, 5 * T))
	_rect_collider(body, Rect2((g0 + 5) * T, (wy - 2) * T, 3 * T, 5 * T))
	for tx in [g0 + 1.5, g0 + 6.5]:
		_flag(Vector2(tx * T, (wy - 2) * T + 4), str(f.get("flag", "FlagRed")))
	for bx in [g0 - 2, g0 + 10]:
		_add_prop("p_estandarte", Vector2(bx * T, base_y + 1))
	for tx2 in [gx * T - 6, (gx + 2) * T + 6]:
		var torch := DungeonObjects.Torch.new()
		torch.position = Vector2(tx2, base_y + 6)
		world.add_child(torch)
	var lines: Array = f.get("guard_lines", ["Bem-vindo. Mantenha a arma na bainha.", "Portão aberto do nascer ao pôr do sol."])
	for gxx in [g0 + 1, g0 + 6]:
		_guard(_tile_pos(gxx, wy - 3), lines)


func _stamp_fort_bridge(img: Image) -> void:
	var f: Dictionary = city.get("fort", {})
	if f.is_empty() or not bool(f.get("moat", false)):
		return
	var br := TileComposer.bridge_image(true, 2, false)
	img.blend_rect(br, Rect2i(Vector2i.ZERO, br.get_size()), Vector2i((int(f["gate_x"]) - 1) * T, (int(f["wall_y"]) + 3) * T))


## Castelo do rei (referência do Victor): prédio fechado com torres, bandeiras e dois guardas no portão.
func _build_castle() -> void:
	var c: Dictionary = city.get("castle", {})
	if c.is_empty():
		return
	var t: Array = c["tile"]
	var w := int(c.get("w", 15))
	var pos := Vector2(int(t[0]) * T + 8, int(t[1]) * T)
	var b := Building.create(world, "castelo", str(c["title"]), "k_castelo_%d" % w, pos, 0.0, "")
	b.return_scene = "city"
	b.door.enabled = false
	buildings["castelo"] = b
	var x0 := pos.x - w * T / 2.0
	for tx in [1.5, w - 1.5]:
		_flag(Vector2(x0 + tx * T, pos.y - 6 * T + 4), str(c.get("flag", "FlagRed")))
	_flag(Vector2(pos.x, pos.y - 6 * T + 2), str(c.get("flag", "FlagRed")))
	for dx in [-2.5, 2.5]:
		_guard(pos + Vector2(dx * T, 14), c.get("guard_lines", ["O rei recebe só com audiência marcada.", "Nem pense em subir nas ameias."]))
	for st in c.get("statues", []):
		_add_prop("h_estatua_pequena", _tile_pos(int(st[0]), int(st[1])), 6.0, Color(0.85, 0.88, 0.95))


## Hortas (referência das vilas): canteiro de terra arada do pack com mudas em fileiras e cerca opcional.
## [x, y, w, h, muda] em tiles (canto de cima à esquerda).
func _build_gardens() -> void:
	for g in city.get("gardens", []):
		var gx := int(g[0])
		var gy := int(g[1])
		var gw := int(g[2])
		var gh := int(g[3])
		var crop := str(g[4]) if g.size() > 4 else "n_frutas_bush1"
		var plot := _add_prop("plot_%d_%d" % [gw, gh], Vector2((gx + gw / 2.0) * T, (gy + gh) * T))
		plot.z_index = -1
		for yy in range(gy, gy + gh - 1):
			for xx in range(gx, gx + gw):
				if (xx - gx) % 2 == 0:
					_add_prop(crop, Vector2(xx * T + 8, yy * T + 14))
		var body := StaticBody2D.new()
		body.collision_layer = 1
		add_child(body)
		_rect_collider(body, Rect2(gx * T + 2, gy * T + 2, gw * T - 4, gh * T - 4))


func _rect_collider(body: StaticBody2D, r: Rect2) -> void:
	var c := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = r.size
	c.shape = s
	c.position = r.position + r.size / 2.0
	body.add_child(c)


## Bandeira tremulando (FlagRed/FlagBlue... do Ninja, 4 quadros de 16 px).
func _flag(pos: Vector2, sheet: String) -> void:
	var sf := SpriteFrames.new()
	sf.add_animation("wave")
	sf.set_animation_speed("wave", 6.0)
	var tex: Texture2D = load("res://assets/ninja/tiles/%s.png" % sheet)
	if tex == null:
		return
	for i in 4:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * 16, 0, 16, 16)
		sf.add_frame("wave", at)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = sf
	spr.position = pos
	spr.z_index = 55
	add_child(spr)
	spr.play("wave")
	spr.frame = rng.randi() % 4


func _guard(pos: Vector2, lines: Array) -> void:
	var g := NPC.new()
	g.custom_look = Ally.look_of("soldado")
	g.mode = "static"
	g.position = pos
	g.lines = lines
	world.add_child(g)


func _build_npcs() -> void:
	var ways: Array = []
	for r in city["paths"]:
		ways.append(_tile_pos((int(r[0]) + int(r[2])) / 2.0, (int(r[1]) + int(r[3])) / 2.0))
	for d in city["npcs"]:
		var t: Array = d["tile"]
		var n := NPC.create(world, str(d["sheet"]), _tile_pos(int(t[0]), int(t[1])), str(d.get("mode", "static")))
		if d.has("lines"):
			n.lines = d["lines"]
		if str(d.get("mode", "static")) == "wander":
			n.wander_radius = 70.0
			n.move_speed = 16.0
			n.wander_points = ways
		if d.has("talk"):
			StoryProp.talker(n, str(d["talk"]), str(d.get("title", "")))


func _build_decor() -> void:
	for d in city["decor"]:
		var t: Array = d[1]
		var tint: Color = CityData.tint_of(d[2]) if d.size() > 2 else Color.WHITE
		var is_boat := str(d[0]).begins_with("barco_")
		var holder := _add_prop(str(d[0]), _tile_pos(int(t[0]), int(t[1])), 0.0 if is_boat else 5.0, tint)
		if is_boat:
			# o barco balança de leve no mar
			var tw := create_tween().set_loops()
			var y0 := holder.position.y
			tw.tween_property(holder, "position:y", y0 + 2.0, 1.4 + rng.randf() * 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(holder, "position:y", y0 - 1.0, 1.4 + rng.randf() * 0.6).set_trans(Tween.TRANS_SINE)


## v3.5: estações animadas do Pixel Crawler (forno de ferro, grelha, fogueira, bigorna, mesa de alquimia) como cenário vivo.
func _build_anim_decor() -> void:
	for d in city.get("anim", []):
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		sf.add_animation("loop")
		sf.set_animation_speed("loop", float(d["fps"]))
		sf.set_animation_loop("loop", true)
		for i in int(d["n"]):
			sf.add_frame("loop", MgArt.sheet(str(d["sheet"]), int(d["from"]) + i, int(d["cols"]), int(d["fw"]), int(d["fh"])))
		var t: Array = d["tile"]
		var holder := Node2D.new()
		holder.position = _tile_pos(int(t[0]), int(t[1])).round()
		world.add_child(holder)
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = sf
		spr.centered = true
		spr.offset = Vector2(0, -float(d["fh"]) / 2.0)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		holder.add_child(spr)
		spr.play("loop")
		spr.frame = rng.randi() % int(d["n"])
		var body := StaticBody2D.new()
		body.collision_layer = 1
		var c := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(minf(float(d["fw"]) - 8.0, 28.0), 10.0)
		c.shape = r
		c.position = Vector2(0, -5)
		body.add_child(c)
		holder.add_child(body)


## Veios de minério de Pedralta: metal fino (mithril, obsidiana, adamantium) para o aprimoramento.
func _build_ore() -> void:
	for o in city.get("ore", []):
		var t: Array = o[2]
		var p := _tile_pos(int(t[0]), int(t[1]))
		var tint := Color(0.7, 0.55, 0.95) if str(o[0]) == "barra_obsidiana" else (Color(0.5, 1.0, 0.85) if str(o[0]) == "barra_adamantium" else Color(0.6, 0.9, 1.0))
		var holder := _add_prop("n_pedra_cinza", p, 5.0, tint)
		var node := StoryProp.make("Minerar " + str(o[1]), Callable(), null, 22.0, false)
		node.position = p
		world.add_child(node)
		var item := str(o[0])
		var label := str(o[1])
		node.on_use = func(me: StoryProp) -> void: _mine(me, holder, item, label)


func _mine(me: StoryProp, holder: Node2D, item: String, label: String) -> void:
	if not me.enabled:
		return
	me.enabled = false
	var n := 1 + (1 if rng.randf() < 0.3 else 0)
	GameState.add_item(item, n, true)
	Audio.sfx2("bigorna1" if randf() < 0.5 else "bigorna2", -8.0, 0.08)
	Fx.burst(world, me.global_position + Vector2(0, -6), Color(1, 0.9, 0.6), 6, 30.0, 0.3)
	HUD.show_toast("+%d Barra de %s" % [n, label], UI.C_GOOD)
	holder.modulate = Color(0.5, 0.5, 0.5, 0.7)
	get_tree().create_timer(150.0).timeout.connect(func() -> void:
		if is_instance_valid(me):
			me.enabled = true
		if is_instance_valid(holder):
			holder.modulate = Color.WHITE)


## v3.7 (história v4): o que cada cidade ganha da história: Jardim e professores na Academia, Centro de
## Treinamento e quadro de missões especiais em Pedralta, a caverna do Pé Grande na Vila da Neve.
func _build_story() -> void:
	match city_id:
		"academia":
			AcademyStory.decorate(self)
		"pedralta":
			ArmyStory.decorate(self)
			var bp := _tile_pos(ArmyStory.BRIGIDA_TILE.x - 3, ArmyStory.BRIGIDA_TILE.y + 1)
			_add_prop("i_board", bp, 4.0)
			var board := StoryProp.make("Quadro de missões especiais", func(_me: StoryProp) -> void: SideQuests.board(), null, 22.0, false)
			board.position = bp
			world.add_child(board)
		"estrada":
			_build_road_ambush()
		"vila_neve":
			var c: Array = city.get("cave", [20, 6])
			var cp := _tile_pos(int(c[0]), int(c[1]))
			var hole := CaveMouth.new()
			hole.position = cp
			world.add_child(hole)
			var cave := StoryProp.make("Entrar na caverna", func(_me: StoryProp) -> void: SideQuests.enter_cave(), null, 24.0, false)
			cave.position = cp + Vector2(0, 6)
			world.add_child(cave)
			_label("Caverna do Pé Grande", cp + Vector2(0, -40), Color("cfe8ff"))
			extra_landmarks.append(["caverna", "Caverna do Pé Grande", cp])


## Boca de caverna provisória: sombra elíptica escura entre as pedras (o pack de neve ainda não entrou).
class CaveMouth extends Node2D:
	func _ready() -> void:
		z_index = -5

	func _draw() -> void:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a) * 18.0, sin(a) * 9.0 - 4.0))
		draw_colored_polygon(pts, Color(0.05, 0.06, 0.1, 0.92))
		var pts2 := PackedVector2Array()
		for i in 24:
			var a2 := TAU * i / 24.0
			pts2.append(Vector2(cos(a2) * 12.0, sin(a2) * 6.0 - 4.0))
		draw_colored_polygon(pts2, Color(0, 0, 0, 1))


## v3.7: emboscada na estrada (Game.travel_road): monstros do caminho conforme o destino; segue a pé pela borda leste.
const ROAD_FOES := {
	"academia": [2, ["lobo", "guaxinim", "slime_verde"]], "porto": [3, ["lobo", "guaxinim", "esqueleto"]],
	"pedralta": [4, ["lobo", "urso", "orc_guerreiro"]], "vila_neve": [5, ["zumbi_gelo", "lobo_sombra", "urso"]],
	"oasis": [4, ["cobra", "lagarto", "reptil"]],
}


func _build_road_ambush() -> void:
	var dest := Game.road_dest
	var info: Array = ROAD_FOES.get(dest, [3, ["lobo", "esqueleto"]])
	var n := 4 + int(info[0]) / 2
	for i in n:
		var p := _tile_pos(14 + rng.randi_range(0, 26), 8 + rng.randi_range(0, 6))
		var foes: Array = info[1]
		var e := Enemy.spawn(world, str(foes[rng.randi() % foes.size()]), p, int(info[0]), i == n - 1)
		e.respawn_s = 0.0
	var dname := str(CityData.CITIES.get(dest, {}).get("name", "Focus Town"))
	_label("Continuar para %s >" % dname, _tile_pos(W - 4, 9), Color("ffe9a8"))
	extra_landmarks.append(["destino", "Para " + dname, _tile_pos(W - 2, 11)])


func is_academy() -> bool:
	return city_id == "academia"


func _build_exit() -> void:
	if city_id == "estrada":
		return
	var sp: Vector2i = city["spawn"]
	var pos := _tile_pos(sp.x, sp.y)
	var txt := "Estrada para Focus Town"
	var off := Vector2(0, -52)
	var f: Dictionary = city.get("fort", {})
	if not f.is_empty():
		# v3.7: com muralha, a placa da estrada fica do lado de fora, depois da ponte
		pos = Vector2((int(f["gate_x"]) + 1) * T, (int(f["wall_y"]) + 5) * T - 2)
		off = Vector2.ZERO
	_label(txt, pos + off, Color("d9ffc2"))


func _build_title() -> void:
	_label(str(city["name"]), Vector2(W * T / 2.0, 6 * T), city["label"])


# ================================================================== Mapa
func map_landmarks() -> Array:
	var out: Array = []
	for id in buildings:
		var b: Node2D = buildings[id]
		if str(b.get("display_name")) == "":
			continue
		out.append([str(id), str(b.get("display_name")), b.position])
	var sp: Vector2i = city["spawn"]
	out.append(["saida_cidade", "Estrada para Focus Town", Vector2(sp.x * T + 8, sp.y * T + 8)])
	out.append_array(extra_landmarks)
	return out


# ================================================================== Jogador
func _spawn_player() -> void:
	var sp: Vector2i = city["spawn"]
	var spawn := _tile_pos(sp.x, sp.y)
	if Game.city_spawn.begins_with("door:"):
		spawn = door_spawns.get(Game.city_spawn.substr(5), spawn)
	player = Player.spawn(world, spawn)
	player.set_camera_limits(Rect2(0, 0, W * T, H * T))
	GameState.player_died.connect(_on_player_died, CONNECT_ONE_SHOT)
	match str(city["exit"]):
		"west":
			player.facing = Vector2.RIGHT
		"east":
			player.facing = Vector2.LEFT
		"south":
			player.facing = Vector2.UP


## v3.7: cair numa cidade (Jardim da Academia) não trava mais o jogo: a enfermaria cuida e a cena recomeça.
## Sem perda de crédito: é treino de aluno.
func _on_player_died() -> void:
	if _leaving:
		return
	_leaving = true
	Audio.jingle("defeat", -4.0)
	await get_tree().create_timer(2.0).timeout
	GameState.revive_after_defeat()
	if city_id == "estrada":
		# caiu na emboscada: o Tobias volta com você para Focus Town (custa 1 crédito, como na floresta)
		Story.lose_credit_on_death()
		Game.road_dest = ""
		HUD.show_toast("Você desmaiou na estrada. O Tobias te levou de volta para Focus Town.", UI.C_BAD)
		Game.go_to_town("start")
		return
	HUD.show_toast("Você desmaiou. A enfermaria de %s cuidou de você." % str(city["name"]), UI.C_BAD)
	Game.go_to_city(city_id)


func _update_daylight() -> void:
	var hour := forced_hour
	if hour < 0.0:
		var t := Time.get_time_dict_from_system()
		hour = float(t["hour"]) + float(t["minute"]) / 60.0
	var night := Color(0.34, 0.38, 0.62)
	var day := Color(1, 1, 1)
	var c := day
	if hour < 5.0 or hour >= 21.0:
		c = night
	elif hour < 8.0:
		c = night.lerp(day, (hour - 5.0) / 3.0)
	elif hour >= 18.0:
		c = day.lerp(night, (hour - 18.0) / 3.0)
	canvas_mod.color = c
	for id in buildings:
		(buildings[id] as Building).set_night(clampf((0.5 - c.v) * 2.5, 0.0, 1.0))
