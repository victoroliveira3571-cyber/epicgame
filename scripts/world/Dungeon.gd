extends Node2D

## Um andar da masmorra: gera as salas, monta o chão e as paredes, posiciona monstros,
## baús, santuário, tochas e escadas, e mantém o mapa explorado para o minimapa.

signal boss_defeated
signal explored_changed

const T := 16
const REVEAL_RADIUS := 7
const AMBIENT := [Color(0.5, 0.52, 0.68), Color(0.46, 0.55, 0.72), Color(0.46, 0.62, 0.52), Color(0.68, 0.46, 0.42)]
const LIGHT_TINT := [Color(1.0, 0.92, 0.8), Color(0.85, 0.95, 1.0), Color(0.9, 1.0, 0.8), Color(1.0, 0.8, 0.6)]

var floor_n: int = 1
var power: int = 1                # força dos monstros (Data.floor_power)
var duel_boss: String = ""        # duelo da história (Torneio): arena só com o rival
var biome: Dictionary = {}
var style: int = 0
var boss_floor: bool = false
var rng := RandomNumberGenerator.new()
var gen: Dictionary = {}
var w: int = 0
var h: int = 0
var cells := PackedByteArray()
var explored := PackedByteArray()
var world: Node2D
var player: Player
var astar: AStarGrid2D
var boss: Boss = null
var stairs_down: DungeonObjects.Stairs
var stairs_up: DungeonObjects.Stairs
var start_cell: Vector2i
var _reveal_timer: float = 0.0
var _ending: bool = false


func _ready() -> void:
	add_to_group("dungeon")
	rng.randomize()
	_ensure_run()
	floor_n = maxi(1, Game.current_floor)
	duel_boss = String(Game.run.get("duel", ""))
	biome = Data.floor_info(floor_n)
	power = Data.floor_power(floor_n)
	style = int(biome["style"])
	boss_floor = biome.has("boss") or duel_boss != ""
	if duel_boss != "":
		style = 0
		power = int(Data.boss_def(duel_boss).get("power", 9))
	gen = DungeonGen.generate(floor_n, rng, boss_floor)
	w = gen["w"]
	h = gen["h"]
	cells = gen["cells"]
	explored.resize(w * h)
	explored.fill(0)
	var img := TileComposer.compose_dungeon(cells, w, h, style, gen["room_of"], rng)
	var ground := Sprite2D.new()
	ground.texture = ImageTexture.create_from_image(img)
	ground.centered = false
	ground.z_index = -100
	add_child(ground)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	# goteira ecoando nas salas de pedra (som do Victor)
	var drip := AudioStreamPlayer.new()
	var st: AudioStream = load(Audio.SFX2_DIR + "amb_goteira.wav")
	if st is AudioStreamWAV:
		st = (st as AudioStreamWAV).duplicate()
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = int(st.get_length() * st.mix_rate)
	drip.stream = st
	drip.volume_db = -18.0
	add_child(drip)
	drip.play()
	_build_colliders()
	_build_astar()
	_place_start()
	_place_torches()
	if boss_floor:
		_populate_boss()
	else:
		_populate_rooms()
		_story_objects()
	_spawn_player()
	var mod := CanvasModulate.new()
	mod.color = AMBIENT[style]
	add_child(mod)
	Audio.play_music(biome["music"])
	HUD.on_scene_ready("dungeon")
	if duel_boss != "":
		HUD.floor_banner("Torneio das Guildas", "Duelo contra Ivo")
	else:
		var subtitle: String = biome["name"] if not boss_floor else "%s - covil do chefe" % biome["name"]
		HUD.floor_banner("Andar %d" % floor_n, subtitle)
	GameState.player_died.connect(_on_player_died, CONNECT_ONE_SHOT)
	_reveal()
	_story_on_enter()


func _process(delta: float) -> void:
	if not Game.run.is_empty():
		Game.run["time"] = float(Game.run.get("time", 0.0)) + delta
	_reveal_timer -= delta
	if _reveal_timer <= 0.0:
		_reveal_timer = 0.25
		_reveal()


## Quando o andar é aberto direto (testes), cria uma expedição vazia.
func _ensure_run() -> void:
	if not Game.run.is_empty():
		return
	if Game.current_floor <= 0:
		Game.current_floor = 1
	Game.run = {
		"start_floor": Game.current_floor, "kills": 0, "bosses": 0, "gold": 0, "xp": 0, "items": {},
		"time": 0.0, "chests": 0, "deepest": Game.current_floor, "died": false,
	}
	GameState.in_dungeon = true


# ================================================================== Mapa
func is_floor_cell(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return false
	return cells[y * w + x] == DungeonGen.FLOOR


func cell_of(pos: Vector2) -> Vector2i:
	return Vector2i(int(floorf(pos.x / T)), int(floorf(pos.y / T)))


func cell_center(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + T / 2.0, c.y * T + T / 2.0)


func is_floor_at(pos: Vector2) -> bool:
	var c := cell_of(pos)
	return is_floor_cell(c.x, c.y)


func map_size() -> Vector2i:
	return Vector2i(w, h)


func player_cell() -> Vector2i:
	if player == null:
		return start_cell
	return cell_of(player.global_position)


## Caminho entre duas posições do mundo (pontos no centro dos tiles). Vazio se não houver.
func path_to(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _nearest_walkable(cell_of(from))
	var b := _nearest_walkable(cell_of(to))
	if a.x < 0 or b.x < 0:
		return PackedVector2Array()
	var pts: PackedVector2Array = astar.get_point_path(a, b)
	if pts.size() > 0:
		pts.remove_at(0)
	return pts


func _nearest_walkable(c: Vector2i) -> Vector2i:
	if is_floor_cell(c.x, c.y):
		return c
	for r in range(1, 4):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if is_floor_cell(c.x + dx, c.y + dy):
					return Vector2i(c.x + dx, c.y + dy)
	return Vector2i(-1, -1)


func _build_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2(T, T)
	astar.offset = Vector2(T / 2.0, T / 2.0)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for y in h:
		for x in w:
			if not is_floor_cell(x, y):
				astar.set_point_solid(Vector2i(x, y), true)


func _reveal() -> void:
	var pc := player_cell()
	var changed := false
	for dy in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
		for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
			if dx * dx + dy * dy > REVEAL_RADIUS * REVEAL_RADIUS:
				continue
			var x := pc.x + dx
			var y := pc.y + dy
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			if explored[y * w + x] == 0:
				explored[y * w + x] = 1
				changed = true
	if changed:
		explored_changed.emit()


# ================================================================== Colisões
## Paredes vizinhas ao chão viram retângulos (uma faixa horizontal por linha).
func _build_colliders() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for y in h:
		var x := 0
		while x < w:
			if _is_solid_edge(x, y):
				var x0 := x
				while x < w and _is_solid_edge(x, y):
					x += 1
				var c := CollisionShape2D.new()
				var s := RectangleShape2D.new()
				s.size = Vector2((x - x0) * T, T)
				c.shape = s
				c.position = Vector2(x0 * T + (x - x0) * T / 2.0, y * T + T / 2.0)
				body.add_child(c)
			else:
				x += 1
	# moldura externa: nada escapa do mapa
	for r in [Rect2(-T * 3, -T * 3, (w + 6) * T, T * 3), Rect2(-T * 3, h * T, (w + 6) * T, T * 3),
			Rect2(-T * 3, 0, T * 3, h * T), Rect2(w * T, 0, T * 3, h * T)]:
		var c2 := CollisionShape2D.new()
		var s2 := RectangleShape2D.new()
		s2.size = r.size
		c2.shape = s2
		c2.position = r.position + r.size / 2.0
		body.add_child(c2)


func _is_solid_edge(x: int, y: int) -> bool:
	if is_floor_cell(x, y):
		return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if is_floor_cell(x + dx, y + dy):
				return true
	return false


# ================================================================== Colocação
func _room_cells(r: Rect2i, inset: int = 1) -> Array:
	var out: Array = []
	for y in range(r.position.y + inset, r.end.y - inset):
		for x in range(r.position.x + inset, r.end.x - inset):
			if is_floor_cell(x, y):
				out.append(Vector2i(x, y))
	return out


func _room_center(r: Rect2i) -> Vector2i:
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)


func _place_start() -> void:
	var rooms: Array = gen["rooms"]
	var r: Rect2i = rooms[gen["start_room"]]
	var c := _room_center(r)
	start_cell = c
	stairs_up = DungeonObjects.Stairs.new()
	stairs_up.kind = "up"
	stairs_up.style = style
	stairs_up.floor_n = floor_n
	stairs_up.position = cell_center(Vector2i(r.position.x + 2, c.y)) + Vector2(0, 6)
	world.add_child(stairs_up)
	start_cell = Vector2i(r.position.x + 3, c.y)


func _place_stairs_down(cell: Vector2i, locked: bool) -> void:
	stairs_down = DungeonObjects.Stairs.new()
	stairs_down.kind = "down"
	stairs_down.style = style
	stairs_down.floor_n = floor_n
	stairs_down.locked = locked
	stairs_down.position = cell_center(cell) + Vector2(0, 6)
	world.add_child(stairs_down)


func _place_torches() -> void:
	var deco := Node2D.new()
	deco.z_index = -90
	add_child(deco)
	var torches := {}
	for y in h:
		for x in w:
			# parede com chão ao sul: tocha no meio do paredão, nunca coladas
			if is_floor_cell(x, y) or not is_floor_cell(x, y + 1):
				continue
			if torches.has(Vector2i(x - 1, y)) or torches.has(Vector2i(x - 2, y)) or torches.has(Vector2i(x - 3, y)):
				continue
			if rng.randf() < 0.1:
				var t := DungeonObjects.Torch.new()
				t.position = Vector2(x * T + T / 2.0, y * T + 9)
				deco.add_child(t)
				torches[Vector2i(x, y)] = true


func _enemy_pool() -> Array:
	var all: Array = biome["enemies"]
	if Data.STORY_FLOORS.has(floor_n):
		return all
	var in_biome := (floor_n - 1) % 5
	var count := mini(all.size(), 2 + in_biome)
	return all.slice(0, count)


func _spawn_enemy(c: Vector2i, elite: bool = false) -> void:
	var pool := _enemy_pool()
	var id: String = pool[rng.randi() % pool.size()]
	var jitter := Vector2(rng.randf_range(-4, 4), rng.randf_range(-3, 3))
	Enemy.spawn(world, id, cell_center(c) + jitter, power, elite)


func _populate_rooms() -> void:
	var rooms: Array = gen["rooms"]
	var stairs_room: int = gen["stairs_room"]
	var treasure_room: int = gen["treasure_room"]
	var shrine_room: int = gen["shrine_room"]
	_place_stairs_down(_room_center(rooms[stairs_room]), false)
	var elite_chance := clampf(0.05 + 0.012 * float(power), 0.05, 0.22)
	for i in rooms.size():
		if i == gen["start_room"]:
			continue
		var r: Rect2i = rooms[i]
		var center := _room_center(r)
		var spots := _room_cells(r, 1)
		spots.shuffle()
		var keep_clear: Array[Vector2i] = [center]
		var guard := 0
		if i == treasure_room:
			var chest := DungeonObjects.Chest.new()
			chest.floor_n = power
			chest.big = rng.randf() < 0.35
			chest.position = cell_center(center) + Vector2(0, 6)
			world.add_child(chest)
			guard = 2
		elif i == shrine_room:
			var shrine := DungeonObjects.Shrine.new()
			shrine.position = cell_center(center) + Vector2(0, 6)
			world.add_child(shrine)
			guard = 1
		elif i != stairs_room and rng.randf() < 0.3:
			var side := DungeonObjects.Chest.new()
			side.floor_n = power
			var pick: Vector2i = spots[0] if spots.size() > 0 else center
			side.position = cell_center(pick) + Vector2(0, 6)
			world.add_child(side)
			spots.remove_at(0)
		var area := r.size.x * r.size.y
		var n := clampi(area / 24 + power / 6, 2, 9) + guard
		if i == stairs_room:
			n = clampi(n - 1, 2, 7)
		var placed := 0
		for c in spots:
			if placed >= n:
				break
			var near_clear := false
			for k in keep_clear:
				if absi(c.x - k.x) <= 2 and absi(c.y - k.y) <= 2:
					near_clear = true
			if near_clear:
				continue
			_spawn_enemy(c, rng.randf() < elite_chance and placed > 0)
			placed += 1


func _populate_boss() -> void:
	var rooms: Array = gen["rooms"]
	var arena: Rect2i = rooms[gen["boss_room"]]
	var center := _room_center(arena)
	var boss_id: String = duel_boss if duel_boss != "" else String(biome["boss"])
	boss = Boss.spawn_boss(world, boss_id, cell_center(center) + Vector2(0, 8), power)
	boss.died.connect(_on_boss_died)
	if duel_boss == "":
		_place_stairs_down(Vector2i(arena.end.x - 3, center.y), true)
	# tochas nos pilares dão leitura do campo de batalha
	for p in gen["pillars"]:
		var cell := Vector2i(p.x + 1, p.y + 2)
		if is_floor_cell(cell.x, cell.y):
			var t := DungeonObjects.Torch.new()
			t.position = cell_center(cell) + Vector2(-8, -4)
			world.add_child(t)


func _on_boss_died(_e: Enemy) -> void:
	boss_defeated.emit()
	if boss.boss_id == "rei_demonio":
		# o pai aparece no trono, com Aldric ao lado
		var at := boss.global_position
		var pai := NPC.create(world, "Noble", at + Vector2(0, -8), "static")
		pai.sprite.modulate = Color(0.85, 0.85, 0.9)
		NPC.create(world, "Knight", at + Vector2(34, 6), "static")
		Fx.ring(world, at + Vector2(0, -10), 40.0, Color(1.0, 0.95, 0.7), 0.8, 2.0)
	if Data.STORY_BOSSES.has(boss.boss_id):
		await Story.on_boss_defeated(boss.boss_id)
	if duel_boss != "":
		Game.finish_run(false)
		return
	if stairs_down != null:
		stairs_down.locked = false
		Fx.ring(world, stairs_down.global_position + Vector2(0, -6), 36.0, Color(1.0, 0.9, 0.5), 0.6, 2.0)
	GameState.toast.emit("O caminho para o próximo andar foi aberto!", Color("ffe08a"))
	Audio.play_music(biome["music"])


# ================================================================== Jogador
func _spawn_player() -> void:
	player = Player.spawn(world, cell_center(start_cell) + Vector2(0, 6))
	player.set_camera_limits(Rect2(0, 0, w * T, h * T))
	Fx.make_light(player, Vector2(0, -8), LIGHT_TINT[style], 1.9, 0.95)


func _on_player_died() -> void:
	if _ending:
		return
	_ending = true
	Audio.jingle("defeat", -4.0)
	await get_tree().create_timer(2.2).timeout
	Story.lose_credit_on_death()
	Game.finish_run(true)


# ================================================================== História
## Objetos da história num andar comum: as 3 páginas de Mestre Lin e o Ivo preso (andar 1).
func _story_objects() -> void:
	if floor_n != 1 or Story.chapter() != 3:
		return
	var rooms: Array = gen["rooms"]
	var order: Array = []
	for i in rooms.size():
		if i != gen["start_room"]:
			order.append(i)
	order.shuffle()
	var k := 0
	if Story.step() == "c3_paginas":
		for i in range(int(Story.st().get("pages", 0)), 3):
			if k >= order.size():
				break
			var page := StoryProp.make_page()
			var cells := _room_cells(rooms[order[k]], 2)
			page.position = cell_center(cells[rng.randi() % cells.size()] if not cells.is_empty() else _room_center(rooms[order[k]])) + Vector2(0, 6)
			world.add_child(page)
			k += 1
	if not Story.flag("ivo_evento") and k < order.size():
		var ivo := StoryProp.make_ivo_trap()
		ivo.position = cell_center(_room_center(rooms[order[k]])) + Vector2(0, 6)
		world.add_child(ivo)


## Falas ao chegar no andar (espelhos do andar 3, Ivo na escada do andar 5).
func _story_on_enter() -> void:
	await get_tree().create_timer(1.0).timeout
	if floor_n == 3 and Story.chapter() == 4 and not Story.flag("espelhos"):
		Story.set_flag("espelhos")
		await Story.say("c4_espelhos")
	elif floor_n == 5 and Story.step() == "c5_trono" and not Story.flag("escada_ivo"):
		Story.set_flag("escada_ivo")
		await Story.say("c5_escada")
