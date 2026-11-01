class_name TileComposer
extends RefCounted

## Monta o chão dos mapas em uma única imagem grande (rápido e sem emendas):
##  - cidade: grama + caminhos de terra e lagos com autotile por quadrantes
##  - masmorra: lajotas, paredes de tijolo, sombras e detalhes por bioma
## Os blocos de origem vêm dos tilesets do Ninja Adventure (16x16 por tile).

const T := 16

static var _img_cache: Dictionary = {}

# Cores por bioma (as mesmas usadas em tools/gen_dungeon_tiles.py): topo da parede e borda clara
const STYLE_TOP := [Color8(36, 30, 42), Color8(28, 34, 42), Color8(22, 32, 24), Color8(36, 16, 20)]
const STYLE_LIP := [Color8(170, 146, 128), Color8(170, 188, 182), Color8(150, 182, 112), Color8(240, 150, 96)]
const OUTLINE := Color8(20, 20, 32)


static func src_img(path: String) -> Image:
	if _img_cache.has(path):
		return _img_cache[path]
	var tex: Texture2D = load(path)
	var im: Image = null
	if tex != null:
		im = tex.get_image()
		im.convert(Image.FORMAT_RGBA8)
	_img_cache[path] = im
	return im


static func tileset(name: String) -> Image:
	return src_img("res://assets/ninja/tiles/%s.png" % name)


static func new_canvas(wt: int, ht: int) -> Image:
	var im := Image.create(wt * T, ht * T, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 1))
	return im


static func blit(canvas: Image, src: Image, tx: int, ty: int, dx: int, dy: int) -> void:
	canvas.blit_rect(src, Rect2i(tx * T, ty * T, T, T), Vector2i(dx * T, dy * T))


static func blend(canvas: Image, src: Image, tx: int, ty: int, dx: int, dy: int) -> void:
	canvas.blend_rect(src, Rect2i(tx * T, ty * T, T, T), Vector2i(dx * T, dy * T))


static func _blit_quad(canvas: Image, src: Image, tile: Vector2i, quad: int, dx: int, dy: int) -> void:
	var qx := (quad % 2) * 8
	var qy := (quad / 2) * 8
	canvas.blit_rect(src, Rect2i(tile.x * T + qx, tile.y * T + qy, 8, 8), Vector2i(dx * T + qx, dy * T + qy))


## Autotile por quadrantes. `mask` tem w*h entradas (true = região). Fora do mapa conta como "dentro",
## assim caminhos que chegam na borda não ganham acabamento. `origin` é o canto do bloco 3x3 no tileset;
## os cantos internos ficam em (+5,+1) (+6,+1) (+5,+2) (+6,+2) — layout padrão do Ninja Adventure.
static func autotile(canvas: Image, src: Image, mask: PackedByteArray, w: int, h: int, origin: Vector2i) -> void:
	var o := origin
	var outer := {
		"TL": o + Vector2i(0, 0), "T": o + Vector2i(1, 0), "TR": o + Vector2i(2, 0),
		"L": o + Vector2i(0, 1), "C": o + Vector2i(1, 1), "R": o + Vector2i(2, 1),
		"BL": o + Vector2i(0, 2), "B": o + Vector2i(1, 2), "BR": o + Vector2i(2, 2),
	}
	var inner := [o + Vector2i(6, 2), o + Vector2i(5, 2), o + Vector2i(6, 1), o + Vector2i(5, 1)]  # grama em TL, TR, BL, BR
	for y in h:
		for x in w:
			if mask[y * w + x] == 0:
				continue
			for q in 4:
				var vy := -1 if q < 2 else 1
				var hx := -1 if q % 2 == 0 else 1
				var v_in := _in(mask, w, h, x, y + vy)
				var h_in := _in(mask, w, h, x + hx, y)
				var d_in := _in(mask, w, h, x + hx, y + vy)
				var tile: Vector2i
				if v_in and h_in:
					tile = outer["C"] if d_in else inner[q]
				elif h_in:
					tile = outer["T"] if q < 2 else outer["B"]
				elif v_in:
					tile = outer["L"] if q % 2 == 0 else outer["R"]
				else:
					tile = [outer["TL"], outer["TR"], outer["BL"], outer["BR"]][q]
				_blit_quad(canvas, src, tile, q, x, y)


static func _in(mask: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return true
	return mask[y * w + x] != 0


# ================================================================== Masmorra
static var _shadow_n: Image = null
static var _shadow_side: Image = null


static func _shadows() -> void:
	if _shadow_n != null:
		return
	_shadow_n = Image.create(T, 5, false, Image.FORMAT_RGBA8)
	_shadow_n.fill(Color(0, 0, 0, 0))
	var alphas := [0.45, 0.32, 0.2, 0.1, 0.05]
	for y in 5:
		for x in T:
			_shadow_n.set_pixel(x, y, Color(0, 0, 0, alphas[y]))
	_shadow_side = Image.create(4, T, false, Image.FORMAT_RGBA8)
	_shadow_side.fill(Color(0, 0, 0, 0))
	var sa := [0.34, 0.2, 0.1, 0.04]
	for x in 4:
		for y in T:
			_shadow_side.set_pixel(x, y, Color(0, 0, 0, sa[x]))


## cells: w*h (0 = parede, 1 = chão). room_of: w*h com o id do cômodo (0 = corredor) para variar o chão.
static func compose_dungeon(cells: PackedByteArray, w: int, h: int, style: int, room_of: PackedInt32Array, rng: RandomNumberGenerator) -> Image:
	_shadows()
	var canvas := new_canvas(w, h)
	var top_c: Color = STYLE_TOP[style]
	var lip_c: Color = STYLE_LIP[style]
	var floors: Array[Image] = []
	for i in 4:
		floors.append(src_img("res://assets/dungeon/s%d_floor%d.png" % [style, i]))
	var face: Array[Image] = [src_img("res://assets/dungeon/s%d_face0.png" % style), src_img("res://assets/dungeon/s%d_face1.png" % style)]
	var top_img := src_img("res://assets/dungeon/s%d_top.png" % style)
	var decals: Array[Image] = []
	for i in 6:
		decals.append(src_img("res://assets/dungeon/s%d_decal%d.png" % [style, i]))

	var is_floor := func(x: int, y: int) -> bool:
		if x < 0 or y < 0 or x >= w or y >= h:
			return false
		return cells[y * w + x] == 1

	for y in h:
		for x in w:
			var idx := y * w + x
			if cells[idx] == 1:
				var pat: Image = floors[(room_of[idx] * 3 + 1) % 4] if room_of[idx] > 0 else floors[0]
				canvas.blit_rect(pat, Rect2i((x % 4) * T, (y % 4) * T, T, T), Vector2i(x * T, y * T))
			else:
				if is_floor.call(x, y + 1):
					var f: Image = face[1] if rng.randf() < 0.18 else face[0]
					canvas.blit_rect(f, Rect2i(0, 0, T, T), Vector2i(x * T, y * T))
				else:
					canvas.blit_rect(top_img, Rect2i(0, 0, T, T), Vector2i(x * T, y * T))
	# bordas claras no topo das paredes, sombras de contato e detalhes
	for y in h:
		for x in w:
			var idx := y * w + x
			var px := x * T
			var py := y * T
			if cells[idx] == 0:
				var south_floor: bool = is_floor.call(x, y + 1)
				if is_floor.call(x, y - 1):  # parede com chão ao norte: aro no topo
					canvas.fill_rect(Rect2i(px, py, T, 1), OUTLINE)
					canvas.fill_rect(Rect2i(px, py + 1, T, 2), lip_c.darkened(0.15))
				if is_floor.call(x - 1, y):
					canvas.fill_rect(Rect2i(px, py, 1, T if not south_floor else T - 1), OUTLINE)
					canvas.fill_rect(Rect2i(px + 1, py, 2, T - 1 if south_floor else T), lip_c.darkened(0.25))
				if is_floor.call(x + 1, y):
					canvas.fill_rect(Rect2i(px + T - 1, py, 1, T if not south_floor else T - 1), OUTLINE)
					canvas.fill_rect(Rect2i(px + T - 3, py, 2, T - 1 if south_floor else T), lip_c.darkened(0.25))
			else:
				if not is_floor.call(x, y - 1):
					canvas.blend_rect(_shadow_n, Rect2i(0, 0, T, 5), Vector2i(px, py))
				if not is_floor.call(x - 1, y):
					canvas.blend_rect(_shadow_side, Rect2i(0, 0, 4, T), Vector2i(px, py))
				if not is_floor.call(x + 1, y):
					var flipped := _shadow_side.duplicate()
					flipped.flip_x()
					canvas.blend_rect(flipped, Rect2i(0, 0, 4, T), Vector2i(px + T - 4, py))
				if rng.randf() < 0.07:
					var d: Image = decals[rng.randi() % decals.size()]
					canvas.blend_rect(d, Rect2i(0, 0, T, T), Vector2i(px, py))
	return canvas


# ===================================================================== Floresta
## Gramado + trilhas de terra + rio/pântano + chão de pedra das ruínas. `dark` (0..255 por tile)
## escurece a mata fechada e o pântano.
## v3.7 (referências do Victor): manchas de grama escura com borda suave, canteiros de flores agrupados,
## nenúfares e pedras nas lagoas (`ponds`), penhascos com face de pedra (`high` = platô, `skip` = onde a face
## não é desenhada: cascata e escadas) e a mata fechada escurecendo a borda do mapa.
static func compose_forest(w: int, h: int, dirt: PackedByteArray, water: PackedByteArray, stone: PackedByteArray,
		dark: PackedByteArray, rng: RandomNumberGenerator, high: PackedByteArray = PackedByteArray(),
		skip: PackedByteArray = PackedByteArray(), ponds: PackedByteArray = PackedByteArray()) -> Image:
	var canvas := new_canvas(w, h)
	var floor_set := tileset("TilesetFloor")
	var water_set := tileset("TilesetWater")
	var nature := tileset("TilesetNature")
	var grass_variants := [Vector2i(0, 12), Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12)]
	for y in h:
		for x in w:
			var g: Vector2i = grass_variants[rng.randi() % grass_variants.size()]
			blit(canvas, floor_set, g.x, g.y, x, y)
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.09
	var bloom := FastNoiseLite.new()
	bloom.seed = rng.randi()
	bloom.frequency = 0.16
	_grass_patches(canvas, floor_set, w, h, noise)
	var details := [Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10)]
	var flowers := [Vector2i(0, 11), Vector2i(1, 11), Vector2i(2, 11), Vector2i(3, 11), Vector2i(6, 11)]
	for y in h:
		for x in w:
			var i := y * w + x
			if dirt[i] != 0 or water[i] != 0 or stone[i] != 0:
				continue
			var r := rng.randf()
			# canteiros: as flores nascem em grupos (ruído), não espalhadas uma a uma
			var in_bed := bloom.get_noise_2d(x, y) > 0.42 and dark[i] < 70
			if in_bed and r < 0.55:
				var fb: Vector2i = flowers[absi(x * 7 + y * 3 + int(bloom.get_noise_2d(y, x) * 10.0)) % flowers.size()]
				blend(canvas, nature, fb.x, fb.y, x, y)
			elif r < 0.08:
				var d: Vector2i = details[rng.randi() % details.size()]
				blend(canvas, nature, d.x, d.y, x, y)
			elif r < 0.09 and dark[i] < 60:
				var f: Vector2i = flowers[rng.randi() % flowers.size()]
				blend(canvas, nature, f.x, f.y, x, y)
	autotile(canvas, floor_set, dirt, w, h, Vector2i(0, 7))
	var stone_img := src_img("res://assets/custom/tiles/TilesetFloorStone.png")
	autotile(canvas, stone_img if stone_img != null else floor_set, stone, w, h, Vector2i(0, 7))
	autotile(canvas, water_set, water, w, h, Vector2i(0, 6))
	# nenúfares e pedras só no miolo das lagoas (o tile do pack já vem com o azul da água)
	if ponds.size() == w * h:
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var pi := y * w + x
				if ponds[pi] == 0 or water[pi] == 0:
					continue
				if water[pi - 1] == 0 or water[pi + 1] == 0 or water[pi - w] == 0 or water[pi + w] == 0:
					continue
				var pr := rng.randf()
				if pr < 0.16:
					blit(canvas, water_set, 11, 3, x, y)
				elif pr < 0.2:
					blit(canvas, water_set, 12, 0, x, y)
	if high.size() == w * h:
		cliffs(canvas, high, skip if skip.size() == w * h else PackedByteArray(), w, h)
	# sombra da mata: escurece por tile, com borda suave
	var shade := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := float(dark[y * w + x]) / 255.0
			# mata fechada na borda do mapa: escurece até quase preto nos 3 tiles de fora
			var edge_d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if edge_d < 3:
				a = maxf(a, [0.78, 0.5, 0.22][edge_d])
			if a <= 0.0:
				continue
			shade.fill(Color(0.02, 0.06, 0.05, a))
			canvas.blend_rect(shade, Rect2i(0, 0, T, T), Vector2i(x * T, y * T))
	return canvas


## Manchas de grama mais escura (TilesetFloor, variação verde-escura) com borda suave: cada quadrante de 8 px
## recebe a grama escura com opacidade conforme o ruído, então a mancha não fica em degraus de tile.
static func _grass_patches(canvas: Image, floor_set: Image, w: int, h: int, noise: FastNoiseLite) -> void:
	var levels: Array[Image] = []
	for a in [0.35, 0.65, 0.9]:
		var tile := floor_set.get_region(Rect2i(11 * T, 12 * T, T, T))
		for py in T:
			for px in T:
				var c := tile.get_pixel(px, py)
				c.a *= a
				tile.set_pixel(px, py, c)
		levels.append(tile)
	for y in h * 2:
		for x in w * 2:
			var n := noise.get_noise_2d(x * 0.5, y * 0.5)
			var lv := -1
			if n > 0.38:
				lv = 2
			elif n > 0.3:
				lv = 1
			elif n > 0.24:
				lv = 0
			if lv < 0:
				continue
			var qx := (x % 2) * 8
			var qy := (y % 2) * 8
			canvas.blend_rect(levels[lv], Rect2i(qx, qy, 8, 8), Vector2i(x * 8, y * 8))


# ===================================================================== Penhascos (TilesetRelief)
static var _relief: Image = null


## TilesetRelief do Ninja com o "chão" do platô (lilás / areia) e os vãos (azul-claro / laranja-claro)
## transparentes: assim a grama da floresta aparece no alto do platô e só o aro e a face são desenhados.
## Linhas 0..4 = penhasco de pedra cinza; 5..9 = penhasco de terra (o da floresta, como nas referências).
static func relief() -> Image:
	if _relief != null:
		return _relief
	_relief = tileset("TilesetRelief").duplicate()
	var keys := [Color8(242, 234, 241), Color8(184, 220, 229), Color8(255, 203, 141), Color8(242, 173, 125)]
	for y in _relief.get_height():
		for x in _relief.get_width():
			var c := _relief.get_pixel(x, y)
			for k in keys:
				if absf(c.r - k.r) < 0.02 and absf(c.g - k.g) < 0.02 and absf(c.b - k.b) < 0.02:
					_relief.set_pixel(x, y, Color(0, 0, 0, 0))
					break
	return _relief


static func _hi(high: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h:
		return true
	return high[y * w + x] != 0


## Tile (x, y) é face de penhasco: chão baixo logo abaixo de um platô (face de 2 tiles de altura).
static func is_face(high: PackedByteArray, w: int, h: int, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= w or y >= h or high[y * w + x] != 0:
		return false
	if y >= 1 and high[(y - 1) * w + x] != 0:
		return true
	return y >= 2 and high[(y - 1) * w + x] == 0 and high[(y - 2) * w + x] != 0


## Aro do platô (bloco 3x2 do TilesetRelief) e face de 2 tiles abaixo da borda sul (colunas 4..6).
## `row0` = 0 para pedra cinza, 5 para terra.
static func cliffs(canvas: Image, high: PackedByteArray, skip: PackedByteArray, w: int, h: int, row0: int = 5) -> void:
	var rel := relief()
	var has_skip := skip.size() == w * h
	for y in h:
		for x in w:
			var i := y * w + x
			if has_skip and skip[i] != 0:
				continue
			if high[i] != 0:
				var n := _hi(high, w, h, x, y - 1)
				var wl := _hi(high, w, h, x - 1, y)
				var e := _hi(high, w, h, x + 1, y)
				if n and wl and e:
					continue
				var row := 0 if not n else 1
				var col := 1 if not wl else (3 if not e else 2)
				blend(canvas, rel, col, row0 + row, x, y)
			elif is_face(high, w, h, x, y):
				var top := y >= 1 and high[(y - 1) * w + x] != 0
				var fl := is_face(high, w, h, x - 1, y) and not (has_skip and x >= 1 and skip[i - 1] != 0)
				var fr := is_face(high, w, h, x + 1, y) and not (has_skip and x + 1 < w and skip[i + 1] != 0)
				var col := 5
				if not fl:
					col = 4
				elif not fr:
					col = 6
				blend(canvas, rel, col, row0 + (0 if top else 2), x, y)


## Ponte do TilesetHouse (madeira 10..13 x 15..17, pedra 10..13 x 19..21): cabeceira + `length - 2` vãos do meio
## + cabeceira. Em pé ela corre norte-sul (corrimão dos lados); `horizontal` gira 90° para atravessar um rio
## norte-sul. A de pedra em pé serve de escadaria no penhasco.
static func bridge_image(stone: bool, length: int, horizontal: bool) -> Image:
	var house := tileset("TilesetHouse")
	var y0 := 19 if stone else 15
	var n := maxi(length, 2)
	var im := Image.create(4 * T, n * T, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	for k in n:
		var src_row := y0 + (0 if k == 0 else (2 if k == n - 1 else 1))
		im.blit_rect(house, Rect2i(10 * T, src_row * T, 4 * T, T), Vector2i(0, k * T))
	if horizontal:
		im.rotate_90(CLOCKWISE)
	return im


## Cascata: tiles de água do pack (TilesetWater, miolo azul) empilhados; o shader do Forest rola a imagem.
static func waterfall_image(cols: int, rows: int) -> Image:
	var water_set := tileset("TilesetWater")
	var im := Image.create(cols * T, rows * T, false, Image.FORMAT_RGBA8)
	for y in rows:
		for x in cols:
			im.blit_rect(water_set, Rect2i(11 * T, (1 + (y % 2)) * T, T, T), Vector2i(x * T, y * T))
	return im


# ===================================================================== Cidade
## Gramado: escolhe uma variação aleatória por tile. mask_dirt/mask_water marcam onde entram caminho e lago.
static func compose_town(w: int, h: int, dirt: PackedByteArray, water: PackedByteArray, rng: RandomNumberGenerator) -> Image:
	var canvas := new_canvas(w, h)
	var floor_set := tileset("TilesetFloor")
	var water_set := tileset("TilesetWater")
	var nature := tileset("TilesetNature")
	var grass_variants := [Vector2i(0, 12), Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12), Vector2i(4, 12), Vector2i(2, 11), Vector2i(3, 11)]
	var weights := [30, 30, 24, 24, 24, 7, 7]
	var total := 0
	for wgt in weights:
		total += wgt
	for y in h:
		for x in w:
			var r := rng.randi() % total
			var pick := 0
			for i in weights.size():
				r -= weights[i]
				if r < 0:
					pick = i
					break
			blit(canvas, floor_set, grass_variants[pick].x, grass_variants[pick].y, x, y)
	# detalhes de grama e flores (só onde não tem caminho/lago)
	var details := [Vector2i(3, 10), Vector2i(4, 10), Vector2i(5, 10), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10)]
	var flowers := [Vector2i(0, 11), Vector2i(1, 11), Vector2i(2, 11), Vector2i(3, 11), Vector2i(6, 11)]
	for y in h:
		for x in w:
			if dirt[y * w + x] != 0 or water[y * w + x] != 0:
				continue
			var r2 := rng.randf()
			if r2 < 0.05:
				var d: Vector2i = details[rng.randi() % details.size()]
				blend(canvas, nature, d.x, d.y, x, y)
			elif r2 < 0.075:
				var f: Vector2i = flowers[rng.randi() % flowers.size()]
				blend(canvas, nature, f.x, f.y, x, y)
	# caminhos de pedra (tools/gen_stone_path.py); cai na terra se a imagem faltar
	var stone := src_img("res://assets/custom/tiles/TilesetFloorStone.png")
	autotile(canvas, stone if stone != null else floor_set, dirt, w, h, Vector2i(0, 7))
	autotile(canvas, water_set, water, w, h, Vector2i(0, 6))
	return canvas


# ===================================================================== Cidades novas (v3.2)
## Chão de uma cidade: `base_row` é a linha do tile liso do bioma no TilesetFloor (grama 12, areia 5, neve 19),
## `layers` empilha manchas pela ordem: [{"mask": PackedByteArray, "set": "floor"|"stone"|"water", "origin": Vector2i}].
## `tint` colore o bioma inteiro (usado para dar clima: névoa do porto, frio da montanha).
static func compose_city(w: int, h: int, base_row: int, layers: Array, rng: RandomNumberGenerator, tint: Color = Color.WHITE) -> Image:
	var canvas := new_canvas(w, h)
	var floor_set := tileset("TilesetFloor")
	var water_set := tileset("TilesetWater")
	var nature := tileset("TilesetNature")
	for y in h:
		for x in w:
			blit(canvas, floor_set, rng.randi() % 5, base_row, x, y)
	var stone_img := src_img("res://assets/custom/tiles/TilesetFloorStone.png")
	for l in layers:
		var set_img: Image = floor_set
		match str(l["set"]):
			"water":
				set_img = water_set
			"stone":
				set_img = stone_img if stone_img != null else floor_set
		autotile(canvas, set_img, l["mask"], w, h, l["origin"])
	if tint != Color.WHITE:
		for y in canvas.get_height():
			for x in canvas.get_width():
				var c := canvas.get_pixel(x, y)
				canvas.set_pixel(x, y, Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a))
	return canvas

