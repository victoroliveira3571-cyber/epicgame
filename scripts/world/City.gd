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
	_build_npcs()
	_build_decor()
	_build_ore()
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
		Game.go_to_town("city")


# ================================================================== Máscaras
func _idx(x: int, y: int) -> int:
	return y * W + x


func _fill(mask: PackedByteArray, r: Array, v: int = 1) -> void:
	for y in range(maxi(int(r[1]), 0), mini(int(r[3]), H - 1) + 1):
		for x in range(maxi(int(r[0]), 0), mini(int(r[2]), W - 1) + 1):
			mask[_idx(x, y)] = v


func _build_masks() -> void:
	for m in [water, path_mask, piers]:
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
		_add_prop(str(d[0]), _tile_pos(int(t[0]), int(t[1])), 5.0, tint)


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


func _build_exit() -> void:
	var sp: Vector2i = city["spawn"]
	var pos := _tile_pos(sp.x, sp.y)
	var txt := "Estrada para Focus Town"
	var off := Vector2(0, -52)
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
	return out


# ================================================================== Jogador
func _spawn_player() -> void:
	var sp: Vector2i = city["spawn"]
	var spawn := _tile_pos(sp.x, sp.y)
	if Game.city_spawn.begins_with("door:"):
		spawn = door_spawns.get(Game.city_spawn.substr(5), spawn)
	player = Player.spawn(world, spawn)
	player.set_camera_limits(Rect2(0, 0, W * T, H * T))
	match str(city["exit"]):
		"west":
			player.facing = Vector2.RIGHT
		"east":
			player.facing = Vector2.LEFT
		"south":
			player.facing = Vector2.UP


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
