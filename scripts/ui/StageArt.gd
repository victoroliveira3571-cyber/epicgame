class_name StageArt
extends RefCounted

## Fundos pintados por código das cenas de diálogo e dos momentos pontuais (Stage.gd, Cutscene.gd).
## Tudo em coordenadas de 640x360. Camadas de profundidade (céu, serra, árvores, chão), luzes com brilho,
## poeira/vaga-lumes/fumaça animados e vinheta. `paint(ci, setting, t)` desenha o fundo inteiro;
## GROUND_Y é a linha onde os personagens ficam de pé.

const W := 640.0
const H := 360.0
const GROUND_Y := 246.0

# configurações aceitas por paint(): town_day, town_dusk, town_night, forest, forest_deep, swamp, clearing,
# ruins, dungeon, throne, inn, guild, library, forge, weapons, arena, home, jail, gate_forest, gate_dungeon


## Número pseudoaleatório estável (0..1) para espalhar detalhes sem sorteio a cada quadro.
static func rn(i: float) -> float:
	return fposmod(sin(i * 12.9898 + 4.1414) * 43758.5453, 1.0)


# ================================================================== Ferramentas
static func vgrad(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color, steps: int = 28) -> void:
	for i in steps:
		var f0 := float(i) / float(steps)
		var c := top.lerp(bottom, f0)
		ci.draw_rect(Rect2(rect.position.x, rect.position.y + rect.size.y * f0, rect.size.x, rect.size.y / float(steps) + 1.0), c)


static func glow(ci: CanvasItem, p: Vector2, radius: float, col: Color, layers: int = 7) -> void:
	# muitas camadas bem fracas: o brilho fica liso, sem anéis visíveis
	var n := maxi(layers * 3, 18)
	for i in n:
		var f := float(i) / float(n)
		ci.draw_circle(p, radius * (1.0 - f * 0.95), Color(col.r, col.g, col.b, col.a * (0.9 / float(n)) * (0.6 + 1.6 * f)))


static func vignette(ci: CanvasItem, strength: float = 0.55) -> void:
	var a := strength * 0.55
	var edge := 110.0
	var c0 := Color(0, 0, 0, a)
	var c1 := Color(0, 0, 0, 0)
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(edge, 0), Vector2(edge, H), Vector2(0, H)]), PackedColorArray([c0, c1, c1, c0]))
	ci.draw_polygon(PackedVector2Array([Vector2(W - edge, 0), Vector2(W, 0), Vector2(W, H), Vector2(W - edge, H)]), PackedColorArray([c1, c0, c0, c1]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 80), Vector2(0, 80)]), PackedColorArray([c0, c0, c1, c1]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, H - 90), Vector2(W, H - 90), Vector2(W, H), Vector2(0, H)]), PackedColorArray([c1, c1, c0, c0]))


static func light_shaft(ci: CanvasItem, top_x: float, bottom_x: float, y0: float, y1: float, width: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(top_x - width * 0.3, y0), Vector2(top_x + width * 0.3, y0), Vector2(bottom_x + width, y1), Vector2(bottom_x - width, y1)])
	var cols := PackedColorArray([Color(col.r, col.g, col.b, col.a), Color(col.r, col.g, col.b, col.a), Color(col.r, col.g, col.b, 0.0), Color(col.r, col.g, col.b, 0.0)])
	ci.draw_polygon(pts, cols)


static func motes(ci: CanvasItem, t: float, col: Color, n: int, seed_v: float, area: Rect2, speed: float = 6.0) -> void:
	for i in n:
		var s := seed_v + float(i)
		var x := area.position.x + fposmod(rn(s) * area.size.x + t * speed * (0.4 + rn(s + 9.0)), area.size.x)
		var y := area.position.y + fposmod(rn(s + 3.0) * area.size.y - t * speed * 0.35 * (0.5 + rn(s + 5.0)), area.size.y)
		var tw := 0.5 + 0.5 * sin(t * (1.2 + rn(s + 1.0) * 2.0) + s)
		ci.draw_circle(Vector2(x, y), 0.8 + rn(s + 7.0) * 1.0, Color(col.r, col.g, col.b, col.a * tw))


static func fireflies(ci: CanvasItem, t: float, n: int, seed_v: float, area: Rect2) -> void:
	for i in n:
		var s := seed_v + float(i)
		var x := area.position.x + rn(s) * area.size.x + sin(t * 0.6 + s) * 14.0
		var y := area.position.y + rn(s + 3.0) * area.size.y + cos(t * 0.5 + s * 1.7) * 8.0
		var tw := 0.5 + 0.5 * sin(t * 1.8 + s * 2.0)
		glow(ci, Vector2(x, y), 7.0, Color(0.85, 1.0, 0.45, 0.9 * tw), 4)
		ci.draw_circle(Vector2(x, y), 1.1, Color(1, 1, 0.8, tw))


static func mist(ci: CanvasItem, t: float, y: float, col: Color, n: int, seed_v: float) -> void:
	for i in n:
		var s := seed_v + float(i)
		var x := fposmod(rn(s) * (W + 240.0) + t * (4.0 + rn(s + 2.0) * 6.0), W + 240.0) - 120.0
		var w := 90.0 + rn(s + 4.0) * 140.0
		for k in 4:
			ci.draw_circle(Vector2(x, y + rn(s + 6.0) * 26.0 + k * 3.0), w * (0.5 - k * 0.08), Color(col.r, col.g, col.b, col.a * (0.25 + k * 0.1)))


static func hills(ci: CanvasItem, base_y: float, amp: float, col: Color, seed_v: float, freq: float = 0.011) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, H))
	var x := 0.0
	while x <= W + 8.0:
		pts.append(Vector2(x, base_y - amp * (0.5 + 0.5 * sin(x * freq + seed_v)) - amp * 0.4 * sin(x * freq * 2.3 + seed_v * 1.7)))
		x += 8.0
	pts.append(Vector2(W + 8.0, H))
	ci.draw_colored_polygon(pts, col)


static func pines(ci: CanvasItem, base_y: float, t: float, col: Color, count: int, hmin: float, hmax: float, seed_v: float, sway: float = 1.0) -> void:
	for i in count:
		var s := seed_v + float(i)
		var x := fposmod(rn(s) * (W + 80.0) - 40.0, W + 80.0) - 20.0
		var h := hmin + rn(s + 1.0) * (hmax - hmin)
		var w := h * (0.34 + rn(s + 2.0) * 0.12)
		var sw := sin(t * 0.7 + s) * sway
		for k in 4:
			var f := float(k) / 4.0
			var ty := base_y - h * (1.0 - f * 0.72)
			var half := w * (0.35 + f * 0.65)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x + sw * (1.0 - f), ty - h * 0.2), Vector2(x - half, ty + h * 0.27), Vector2(x + half, ty + h * 0.27)]), col)
		ci.draw_rect(Rect2(x - 2.0, base_y - h * 0.12, 4.0, h * 0.12), col.darkened(0.25))


static func round_trees(ci: CanvasItem, base_y: float, t: float, trunk: Color, leaves: Color, count: int, hmin: float, hmax: float, seed_v: float) -> void:
	for i in count:
		var s := seed_v + float(i)
		var x := fposmod(rn(s) * (W + 100.0) - 50.0, W + 100.0) - 20.0
		var h := hmin + rn(s + 1.0) * (hmax - hmin)
		ci.draw_rect(Rect2(x - h * 0.05, base_y - h * 0.5, h * 0.1, h * 0.5), trunk)
		var sw := sin(t * 0.6 + s) * 1.2
		for k in 5:
			var ang := float(k) / 5.0 * TAU + rn(s + 4.0) * 3.0
			ci.draw_circle(Vector2(x + sw + cos(ang) * h * 0.22, base_y - h * 0.62 + sin(ang) * h * 0.14), h * 0.2, leaves.lerp(leaves.lightened(0.18), rn(s + float(k))))
		ci.draw_circle(Vector2(x + sw, base_y - h * 0.68), h * 0.24, leaves.lightened(0.1))


static func bricks(ci: CanvasItem, rect: Rect2, base: Color, mortar: Color, seed_v: float, bw: float = 28.0, bh: float = 14.0) -> void:
	ci.draw_rect(rect, mortar)
	var row := 0
	var y := rect.position.y
	while y < rect.end.y:
		var off := (bw * 0.5) if row % 2 == 1 else 0.0
		var x := rect.position.x - off
		var col_i := 0
		while x < rect.end.x:
			var c := base.lerp(base.lightened(0.15) if rn(seed_v + row * 31.0 + col_i) > 0.5 else base.darkened(0.15), 0.4 + rn(seed_v + col_i * 7.0 + row) * 0.4)
			var bx := maxf(x + 1.0, rect.position.x)
			var bx2 := minf(x + bw - 1.0, rect.end.x)
			if bx2 > bx:
				ci.draw_rect(Rect2(bx, y + 1.0, bx2 - bx, minf(bh - 2.0, rect.end.y - y - 1.0)), c)
				ci.draw_rect(Rect2(bx, y + 1.0, bx2 - bx, 2.0), Color(1, 1, 1, 0.06))
			x += bw
			col_i += 1
		y += bh
		row += 1


static func planks(ci: CanvasItem, rect: Rect2, base: Color, seed_v: float, ph: float = 12.0) -> void:
	var i := 0
	var y := rect.position.y
	while y < rect.end.y:
		var c := base.lerp(base.lightened(0.12), rn(seed_v + float(i)))
		ci.draw_rect(Rect2(rect.position.x, y, rect.size.x, ph - 1.0), c)
		ci.draw_rect(Rect2(rect.position.x, y + ph - 1.0, rect.size.x, 1.0), base.darkened(0.45))
		var x := rect.position.x + rn(seed_v + float(i) * 3.0) * 60.0
		while x < rect.end.x:
			ci.draw_rect(Rect2(x, y, 1.0, ph - 1.0), base.darkened(0.35))
			x += 70.0 + rn(seed_v + x) * 90.0
		y += ph
		i += 1


static func wall_planks(ci: CanvasItem, rect: Rect2, base: Color, seed_v: float) -> void:
	var x := rect.position.x
	var i := 0
	while x < rect.end.x:
		var w := 22.0 + rn(seed_v + float(i)) * 6.0
		ci.draw_rect(Rect2(x, rect.position.y, w - 1.0, rect.size.y), base.lerp(base.lightened(0.1), rn(seed_v + float(i) * 2.0)))
		ci.draw_rect(Rect2(x + w - 1.0, rect.position.y, 1.0, rect.size.y), base.darkened(0.4))
		x += w
		i += 1


static func window_frame(ci: CanvasItem, r: Rect2, sky_top: Color, sky_bot: Color, frame: Color, t: float, day: bool = true) -> void:
	vgrad(ci, r, sky_top, sky_bot, 10)
	if day:
		glow(ci, r.position + Vector2(r.size.x * 0.7, r.size.y * 0.3), r.size.x * 0.4, Color(1.0, 0.95, 0.7, 0.8), 4)
	else:
		for i in 6:
			ci.draw_circle(r.position + Vector2(rn(float(i)) * r.size.x, rn(float(i) + 7.0) * r.size.y * 0.7), 0.9, Color(1, 1, 0.9, 0.5 + 0.5 * sin(t * 2.0 + float(i))))
	ci.draw_rect(r, frame, false, 4.0)
	ci.draw_rect(Rect2(r.position.x + r.size.x / 2.0 - 2.0, r.position.y, 4.0, r.size.y), frame)
	ci.draw_rect(Rect2(r.position.x, r.position.y + r.size.y / 2.0 - 2.0, r.size.x, 4.0), frame)
	ci.draw_rect(Rect2(r.position.x - 5.0, r.end.y, r.size.x + 10.0, 5.0), frame.lightened(0.15))


static func torch(ci: CanvasItem, p: Vector2, t: float, size: float = 1.0) -> void:
	ci.draw_rect(Rect2(p.x - 2.0 * size, p.y, 4.0 * size, 26.0 * size), Color("3a2418"))
	ci.draw_rect(Rect2(p.x - 5.0 * size, p.y - 3.0 * size, 10.0 * size, 5.0 * size), Color("5a5a60"))
	var fl := 1.0 + sin(t * 14.0 + p.x) * 0.12 + sin(t * 23.0 + p.x * 2.0) * 0.08
	glow(ci, p + Vector2(0, -10.0 * size), 62.0 * size * fl, Color(1.0, 0.62, 0.25, 0.9), 8)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - 4.5 * size, p.y - 3.0 * size), Vector2(p.x + 4.5 * size, p.y - 3.0 * size), Vector2(p.x + 1.0, p.y - 20.0 * size * fl), Vector2(p.x - 1.0, p.y - 18.0 * size * fl)]), Color("ff9a2e"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - 2.5 * size, p.y - 3.0 * size), Vector2(p.x + 2.5 * size, p.y - 3.0 * size), Vector2(p.x, p.y - 13.0 * size * fl)]), Color("ffe08a"))


static func banner(ci: CanvasItem, p: Vector2, w: float, h: float, col: Color, t: float, emblem: Color = Color("e8c25a")) -> void:
	var sw := sin(t * 1.2 + p.x) * 2.0
	ci.draw_rect(Rect2(p.x - w / 2.0 - 4.0, p.y - 4.0, w + 8.0, 5.0), Color("3a2418"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w / 2.0, p.y), Vector2(p.x + w / 2.0, p.y), Vector2(p.x + w / 2.0 + sw, p.y + h * 0.86), Vector2(p.x + sw * 0.5, p.y + h), Vector2(p.x - w / 2.0 + sw, p.y + h * 0.86)]), col)
	ci.draw_circle(Vector2(p.x + sw * 0.4, p.y + h * 0.36), w * 0.18, emblem)
	ci.draw_circle(Vector2(p.x + sw * 0.4, p.y + h * 0.36), w * 0.1, col)


static func column(ci: CanvasItem, x: float, y0: float, y1: float, w: float, col: Color) -> void:
	ci.draw_rect(Rect2(x - w / 2.0, y0, w, y1 - y0), col)
	ci.draw_rect(Rect2(x - w / 2.0, y0, w * 0.3, y1 - y0), col.lightened(0.12))
	ci.draw_rect(Rect2(x + w * 0.25, y0, w * 0.25, y1 - y0), col.darkened(0.2))
	ci.draw_rect(Rect2(x - w * 0.7, y0 - 8.0, w * 1.4, 9.0), col.lightened(0.05))
	ci.draw_rect(Rect2(x - w * 0.7, y1 - 6.0, w * 1.4, 7.0), col.darkened(0.05))


static func arch(ci: CanvasItem, cx: float, base_y: float, half_w: float, height: float, col: Color, hole: Color) -> void:
	ci.draw_rect(Rect2(cx - half_w - 14.0, base_y - height, 14.0, height), col)
	ci.draw_rect(Rect2(cx + half_w, base_y - height, 14.0, height), col)
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + PI * float(i) / 20.0
		pts.append(Vector2(cx + cos(a) * (half_w + 14.0), base_y - height + sin(a) * (half_w + 14.0)))
	pts.append(Vector2(cx + half_w + 14.0, base_y - height))
	pts.append(Vector2(cx - half_w - 14.0, base_y - height))
	ci.draw_colored_polygon(pts, col)
	var inner := PackedVector2Array()
	inner.append(Vector2(cx - half_w, base_y))
	for i in 21:
		var a2 := PI + PI * float(i) / 20.0
		inner.append(Vector2(cx + cos(a2) * half_w, base_y - height + sin(a2) * half_w))
	inner.append(Vector2(cx + half_w, base_y))
	ci.draw_colored_polygon(inner, hole)


static func bookshelf(ci: CanvasItem, r: Rect2, wood: Color, seed_v: float) -> void:
	ci.draw_rect(r, wood.darkened(0.5))
	var shelves := 4
	var sh := r.size.y / float(shelves)
	for s in shelves:
		var y := r.position.y + sh * float(s)
		var x := r.position.x + 3.0
		var i := 0
		while x < r.end.x - 4.0:
			var bw := 4.0 + rn(seed_v + float(s * 40 + i)) * 4.0
			var bh := sh * (0.55 + rn(seed_v + float(s * 40 + i) + 3.0) * 0.35)
			var c := Color.from_hsv(rn(seed_v + float(s * 40 + i) + 5.0), 0.55, 0.55 + rn(seed_v + float(i)) * 0.3)
			ci.draw_rect(Rect2(x, y + sh - 4.0 - bh, bw - 1.0, bh), c)
			x += bw
			i += 1
		ci.draw_rect(Rect2(r.position.x, y + sh - 4.0, r.size.x, 4.0), wood)
	ci.draw_rect(r, wood, false, 3.0)


# ================================================================== Pintura principal
static func paint(ci: CanvasItem, setting: String, t: float) -> void:
	match setting:
		"town_day", "town_dusk", "town_night":
			_town(ci, setting, t)
		"forest", "forest_deep", "swamp", "clearing":
			_forest(ci, setting, t)
		"ruins":
			_ruins(ci, t)
		"dungeon":
			_dungeon(ci, t)
		"throne":
			_throne(ci, t)
		"inn":
			_inn(ci, t)
		"guild":
			_guild(ci, t)
		"library":
			_library(ci, t)
		"forge":
			_forge(ci, t)
		"weapons":
			_weapons(ci, t)
		"arena":
			_arena(ci, t)
		"jail":
			_jail(ci, t)
		"gate_forest":
			_forest(ci, "forest", t)
			_gate(ci, t, true)
		"gate_dungeon":
			_dungeon(ci, t)
			_gate(ci, t, false)
		_:
			_home(ci, t)
	vignette(ci, 0.7)


# ------------------------------------------------------------------ Cidade (céu, serra, casas, rua)
static func _town(ci: CanvasItem, setting: String, t: float) -> void:
	var night := setting == "town_night"
	var dusk := setting == "town_dusk"
	var top := Color("6fb4ea")
	var bot := Color("fdeab8")
	if dusk:
		top = Color("5a5aa8")
		bot = Color("ffb072")
	if night:
		top = Color("0b1030")
		bot = Color("2c3466")
	vgrad(ci, Rect2(0, 0, W, 200), top, bot, 36)
	if night:
		for i in 60:
			ci.draw_circle(Vector2(rn(float(i)) * W, rn(float(i) + 40.0) * 150.0), 0.7 + rn(float(i) + 3.0) * 0.8, Color(1, 1, 0.92, 0.35 + 0.5 * abs(sin(t * 1.3 + float(i)))))
		glow(ci, Vector2(500, 52), 46.0, Color(0.9, 0.93, 1.0, 0.9), 6)
		ci.draw_circle(Vector2(500, 52), 15.0, Color("eef0ff"))
		ci.draw_circle(Vector2(505, 49), 13.0, Color("1c2350"))
	elif dusk:
		glow(ci, Vector2(120, 168), 90.0, Color(1.0, 0.7, 0.35, 0.9), 7)
		ci.draw_circle(Vector2(120, 168), 24.0, Color("ffd39a"))
	else:
		glow(ci, Vector2(520, 46), 80.0, Color(1.0, 0.95, 0.7, 0.9), 7)
		ci.draw_circle(Vector2(520, 46), 21.0, Color("fff4c2"))
	for i in 5:
		var cx := fposmod(rn(float(i) * 3.0) * (W + 200.0) + t * (3.0 + float(i)), W + 200.0) - 100.0
		var cc := Color(1, 1, 1, 0.55) if not night else Color(0.45, 0.5, 0.75, 0.35)
		var cy := 30.0 + rn(float(i) + 9.0) * 90.0
		for k in 4:
			ci.draw_circle(Vector2(cx + k * 16.0, cy + sin(float(k)) * 4.0), 15.0 - k * 1.5, cc)
	var far := Color("7d9bc4") if not night else Color("1b2146")
	var mid := Color("5c8a5a") if not night else Color("141c3a")
	if dusk:
		far = Color("8a6aa0")
		mid = Color("4a5a60")
	hills(ci, 198.0, 28.0, far, 1.0, 0.008)
	hills(ci, 216.0, 22.0, mid, 4.0, 0.012)
	# casas ao fundo
	for i in 7:
		var x := 20.0 + float(i) * 92.0 + rn(float(i)) * 20.0
		var hw := 30.0 + rn(float(i) + 2.0) * 16.0
		var hh := 36.0 + rn(float(i) + 5.0) * 22.0
		var wall := Color("d9c4a0") if not night else Color("2a2e52")
		if dusk:
			wall = Color("b8987c")
		var roof := Color("b4553a") if i % 2 == 0 else Color("4f6f9a")
		if night:
			roof = roof.darkened(0.6)
		ci.draw_rect(Rect2(x - hw / 2.0, 222.0 - hh, hw, hh), wall)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - hw / 2.0 - 5.0, 222.0 - hh), Vector2(x + hw / 2.0 + 5.0, 222.0 - hh), Vector2(x, 222.0 - hh - hw * 0.45)]), roof)
		var lit := night or dusk
		for wxi in 2:
			var wc := Color("ffd26a") if lit else Color("7aa6d0")
			ci.draw_rect(Rect2(x - hw / 2.0 + 6.0 + float(wxi) * (hw * 0.45), 222.0 - hh + 10.0, 8.0, 10.0), wc)
			if lit:
				glow(ci, Vector2(x - hw / 2.0 + 10.0 + float(wxi) * (hw * 0.45), 222.0 - hh + 15.0), 14.0, Color(1.0, 0.8, 0.4, 0.5), 3)
		ci.draw_rect(Rect2(x - 4.0, 222.0 - 14.0, 8.0, 14.0), wall.darkened(0.45))
	round_trees(ci, 228.0, t, Color("5a3a24") if not night else Color("1c1a2c"), Color("5f9a4a") if not night else Color("1a3a3a"), 6, 56.0, 84.0, 21.0)
	# rua de pedra
	var g_top := Color("9a8f86") if not night else Color("3a3c52")
	var g_bot := Color("6c635e") if not night else Color("22243a")
	vgrad(ci, Rect2(0, 228, W, 132), g_top, g_bot, 18)
	for row in 7:
		var y := 232.0 + float(row) * float(row) * 2.4 + float(row) * 6.0
		var step := 24.0 + float(row) * 9.0
		ci.draw_rect(Rect2(0, y, W, 1.2), Color(0, 0, 0, 0.18))
		var x := -fposmod(float(row) * 11.0, step)
		while x < W:
			ci.draw_rect(Rect2(x, y, 1.2, 8.0 + float(row) * 4.0), Color(0, 0, 0, 0.14))
			x += step
	# postes de luz
	for lx in [96.0, 548.0]:
		ci.draw_rect(Rect2(lx - 2.0, 150.0, 4.0, 82.0), Color("2a2430"))
		ci.draw_rect(Rect2(lx - 7.0, 142.0, 14.0, 14.0), Color("2a2430"))
		ci.draw_rect(Rect2(lx - 5.0, 144.0, 10.0, 10.0), Color("ffdc82") if (night or dusk) else Color("e8d9a8"))
		if night or dusk:
			glow(ci, Vector2(lx, 150.0), 74.0, Color(1.0, 0.8, 0.45, 0.8), 8)
	motes(ci, t, Color(1, 1, 0.9, 0.5), 22, 3.0, Rect2(0, 80, W, 160), 4.0)


# ------------------------------------------------------------------ Florestas
static func _forest(ci: CanvasItem, setting: String, t: float) -> void:
	var deep := setting == "forest_deep"
	var swamp := setting == "swamp"
	var clear := setting == "clearing"
	var top := Color("8ad0f2")
	var bot := Color("e9f5c8")
	if deep:
		top = Color("1b3a3a")
		bot = Color("3d6a5a")
	if swamp:
		top = Color("24352c")
		bot = Color("58704a")
	if clear:
		top = Color("7ec8f2")
		bot = Color("fff0b8")
	vgrad(ci, Rect2(0, 0, W, 230), top, bot, 32)
	if clear:
		glow(ci, Vector2(470, 40), 90.0, Color(1.0, 0.95, 0.7, 0.9), 7)
	hills(ci, 190.0, 30.0, Color("5f8f6a") if not (deep or swamp) else Color("27463f"), 2.0, 0.009)
	pines(ci, 200.0, t, Color("3f7050") if not (deep or swamp) else Color("1d3a36"), 18, 70.0, 110.0, 5.0, 0.6)
	pines(ci, 222.0, t, Color("2e5a3e") if not (deep or swamp) else Color("14302d"), 12, 100.0, 150.0, 40.0, 1.0)
	if swamp:
		mist(ci, t, 214.0, Color(0.7, 0.85, 0.6, 0.45), 6, 3.0)
	# raios de luz
	if not swamp:
		for i in 4:
			var sx := 90.0 + float(i) * 150.0 + sin(t * 0.3 + float(i)) * 14.0
			light_shaft(ci, sx, sx - 60.0, -10.0, 250.0, 36.0, Color(1.0, 0.95, 0.65, 0.10 if not deep else 0.06))
	var gtop := Color("5f9a4e") if not (deep or swamp) else Color("2b4f40")
	var gbot := Color("3a6a34") if not (deep or swamp) else Color("162c26")
	if clear:
		gtop = Color("86c45a")
		gbot = Color("4a8238")
	vgrad(ci, Rect2(0, 232, W, 128), gtop, gbot, 14)
	# trilha de terra
	ci.draw_colored_polygon(PackedVector2Array([Vector2(210, 360), Vector2(300, 232), Vector2(380, 232), Vector2(520, 360)]), Color("8a6a46") if not deep else Color("4a3a2c"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(260, 360), Vector2(320, 240), Vector2(360, 240), Vector2(450, 360)]), Color("a68058") if not deep else Color("5a4636"))
	for i in 38:
		var gx := rn(float(i) * 1.7) * W
		var gy := 238.0 + rn(float(i) * 2.3) * 118.0
		var sc := 0.6 + (gy - 232.0) / 110.0
		var gc := Color("7ac45a") if not (deep or swamp) else Color("3d7a58")
		for b in 3:
			ci.draw_line(Vector2(gx, gy), Vector2(gx - 3.0 * sc + float(b) * 3.0 * sc + sin(t + float(i)) * 1.2, gy - 7.0 * sc), gc, 1.5)
	if clear:
		for i in 22:
			var fx := rn(float(i) + 70.0) * W
			var fy := 250.0 + rn(float(i) + 80.0) * 100.0
			ci.draw_circle(Vector2(fx, fy), 2.0, [Color("ffd84a"), Color("ff7ab0"), Color("ffffff")][i % 3])
	# árvores grossas da frente (enquadram a cena)
	for side in [-1.0, 1.0]:
		var bx := 38.0 if side < 0.0 else W - 38.0
		ci.draw_rect(Rect2(bx - 24.0, -10.0, 48.0, 280.0), Color("3a2818") if not (deep or swamp) else Color("1a1814"))
		ci.draw_rect(Rect2(bx - 24.0 + (0.0 if side < 0.0 else 30.0), -10.0, 18.0, 280.0), Color("5a3e24") if not (deep or swamp) else Color("2a241c"))
		for k in 7:
			ci.draw_circle(Vector2(bx + side * float(k) * 12.0, 8.0 + float(k % 2) * 14.0), 46.0 - float(k) * 3.0, Color("3a7a46") if not (deep or swamp) else Color("1d4a40"))
	if swamp:
		for i in 5:
			var px := 100.0 + float(i) * 110.0
			ci.draw_rect(Rect2(px, 292.0, 70.0, 10.0), Color(0.3, 0.45, 0.4, 0.55))
			for r_i in 5:
				ci.draw_line(Vector2(px + float(r_i) * 14.0, 292.0), Vector2(px + float(r_i) * 14.0 + sin(t + float(r_i)) * 2.0, 270.0 - rn(float(r_i) + float(i)) * 14.0), Color("6a8a50"), 2.0)
		mist(ci, t, 252.0, Color(0.75, 0.9, 0.7, 0.4), 5, 11.0)
	elif deep:
		mist(ci, t, 240.0, Color(0.6, 0.8, 0.85, 0.35), 5, 7.0)
	fireflies(ci, t, 16 if (deep or swamp) else 8, 31.0, Rect2(0, 120, W, 160))
	motes(ci, t, Color(1, 1, 0.8, 0.6), 18, 6.0, Rect2(0, 40, W, 200), 5.0)


# ------------------------------------------------------------------ Ruínas
static func _ruins(ci: CanvasItem, t: float) -> void:
	vgrad(ci, Rect2(0, 0, W, 250), Color("11182c"), Color("2a3c4e"), 30)
	for i in 40:
		ci.draw_circle(Vector2(rn(float(i)) * W, rn(float(i) + 30.0) * 90.0), 0.8, Color(1, 1, 1, 0.3 + 0.4 * abs(sin(t + float(i)))))
	pines(ci, 210.0, t, Color("0f2024"), 14, 80.0, 130.0, 70.0, 0.4)
	for x in [90.0, 230.0, 410.0, 550.0]:
		var h := 150.0 + rn(x) * 40.0
		var broken := rn(x + 3.0) > 0.5
		column(ci, x, 246.0 - (h if not broken else h * 0.55), 246.0, 30.0, Color("6a7a82"))
	arch(ci, 320.0, 246.0, 62.0, 120.0, Color("56666e"), Color("0a1018"))
	glow(ci, Vector2(320, 190), 90.0, Color(0.5, 0.8, 1.0, 0.55), 8)
	vgrad(ci, Rect2(0, 246, W, 114), Color("3c4a52"), Color("181e26"), 14)
	for i in 20:
		var sx := rn(float(i) * 5.0) * W
		ci.draw_rect(Rect2(sx, 252.0 + rn(float(i)) * 90.0, 36.0, 1.5), Color(0, 0, 0, 0.35))
	for i in 14:
		var vx := rn(float(i) + 90.0) * W
		ci.draw_circle(Vector2(vx, 246.0 + rn(float(i)) * 6.0), 6.0, Color(0.2, 0.4, 0.25, 0.8))
	mist(ci, t, 250.0, Color(0.55, 0.75, 0.9, 0.35), 5, 21.0)
	fireflies(ci, t, 10, 51.0, Rect2(40, 90, 560, 170))
	motes(ci, t, Color(0.7, 0.9, 1.0, 0.6), 22, 8.0, Rect2(0, 20, W, 220), 4.0)


# ------------------------------------------------------------------ Masmorra
static func _dungeon(ci: CanvasItem, t: float) -> void:
	bricks(ci, Rect2(0, 0, W, 252), Color("4a4650"), Color("1c1a22"), 3.0)
	vgrad(ci, Rect2(0, 0, W, 252), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.1), 16)
	for x in [120.0, 320.0, 520.0]:
		arch(ci, x, 252.0, 40.0, 150.0, Color("5a5660"), Color("0a0910"))
	for x in [60.0, 220.0, 420.0, 580.0]:
		torch(ci, Vector2(x, 112.0), t)
	# correntes
	for x in [170.0, 470.0]:
		for k in 8:
			ci.draw_circle(Vector2(x + sin(t * 0.8 + float(k)) * 1.5, 10.0 + float(k) * 7.0), 3.0, Color("6a6a74"))
	vgrad(ci, Rect2(0, 252, W, 108), Color("3a3640"), Color("14121a"), 14)
	for row in 5:
		ci.draw_rect(Rect2(0, 256.0 + float(row) * float(row) * 4.0 + float(row) * 6.0, W, 1.5), Color(0, 0, 0, 0.35))
	mist(ci, t, 262.0, Color(0.6, 0.55, 0.7, 0.35), 5, 31.0)
	motes(ci, t, Color(1, 0.85, 0.6, 0.6), 16, 9.0, Rect2(0, 60, W, 200), 4.0)


# ------------------------------------------------------------------ Salão do trono
static func _throne(ci: CanvasItem, t: float) -> void:
	vgrad(ci, Rect2(0, 0, W, 252), Color("0a0612"), Color("2a1238"), 30)
	for x in [50.0, 170.0, 470.0, 590.0]:
		column(ci, x, 20.0, 252.0, 42.0, Color("2c2438"))
	arch(ci, 320.0, 252.0, 84.0, 170.0, Color("241c30"), Color("3a1048"))
	glow(ci, Vector2(320, 160), 130.0, Color(0.7, 0.2, 0.9, 0.75), 9)
	# trono ao fundo
	ci.draw_rect(Rect2(296, 150, 48, 80), Color("1a1224"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(296, 150), Vector2(320, 108), Vector2(344, 150)]), Color("1a1224"))
	ci.draw_rect(Rect2(286, 224, 68, 28), Color("241a30"))
	for x in [200.0, 440.0]:
		ci.draw_rect(Rect2(x - 7.0, 214.0, 14.0, 38.0), Color("3a3048"))
		var fl := 1.0 + sin(t * 12.0 + x) * 0.15
		glow(ci, Vector2(x, 206.0), 50.0 * fl, Color(0.75, 0.3, 1.0, 0.9), 8)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 8.0, 214.0), Vector2(x + 8.0, 214.0), Vector2(x, 188.0 * (1.0 - (fl - 1.0)))]), Color("b86aff"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 4.0, 214.0), Vector2(x + 4.0, 214.0), Vector2(x, 198.0)]), Color("f0d0ff"))
	vgrad(ci, Rect2(0, 252, W, 108), Color("1c1426"), Color("08040e"), 14)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(300, 252), Vector2(340, 252), Vector2(470, 360), Vector2(170, 360)]), Color("6a1830"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(308, 252), Vector2(332, 252), Vector2(420, 360), Vector2(220, 360)]), Color("8a2440"))
	mist(ci, t, 258.0, Color(0.6, 0.3, 0.8, 0.4), 6, 41.0)
	motes(ci, t, Color(0.9, 0.6, 1.0, 0.7), 26, 12.0, Rect2(0, 20, W, 260), 5.0)


# ------------------------------------------------------------------ Interiores
static func _inn(ci: CanvasItem, t: float) -> void:
	wall_planks(ci, Rect2(0, 0, W, 246), Color("7a4a2a"), 2.0)
	vgrad(ci, Rect2(0, 0, W, 246), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.0), 14)
	ci.draw_rect(Rect2(0, 100, W, 6), Color("4a2a16"))
	window_frame(ci, Rect2(60, 52, 96, 76), Color("2a3a6a"), Color("6a7aa8"), Color("3a2214"), t, false)
	window_frame(ci, Rect2(486, 52, 96, 76), Color("2a3a6a"), Color("6a7aa8"), Color("3a2214"), t, false)
	# lareira
	ci.draw_rect(Rect2(262, 70, 116, 176), Color("5a5560"))
	ci.draw_rect(Rect2(280, 120, 80, 126), Color("120a0a"))
	for k in 3:
		var fh := 40.0 + sin(t * 9.0 + float(k) * 2.0) * 7.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(292.0 + float(k) * 22.0, 246), Vector2(310.0 + float(k) * 22.0, 246), Vector2(301.0 + float(k) * 22.0, 246.0 - fh)]), Color("ff7a1e"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(298.0 + float(k) * 22.0, 246), Vector2(304.0 + float(k) * 22.0, 246), Vector2(301.0 + float(k) * 22.0, 246.0 - fh * 0.55)]), Color("ffe08a"))
	glow(ci, Vector2(320, 210), 160.0, Color(1.0, 0.55, 0.2, 0.7), 9)
	ci.draw_rect(Rect2(250, 62, 140, 10), Color("6a6570"))
	# lamparinas e barris
	for x in [200.0, 440.0]:
		ci.draw_line(Vector2(x, 0), Vector2(x, 54), Color("2a1810"), 2.0)
		ci.draw_rect(Rect2(x - 8.0, 54, 16, 14), Color("3a2418"))
		glow(ci, Vector2(x, 62), 80.0, Color(1.0, 0.78, 0.4, 0.8), 8)
		ci.draw_circle(Vector2(x, 62), 4.0, Color("fff0b0"))
	for bx in [30.0, 610.0]:
		ci.draw_rect(Rect2(bx - 24.0, 190.0, 48.0, 56.0), Color("6a4020"))
		for k in 3:
			ci.draw_rect(Rect2(bx - 24.0, 198.0 + float(k) * 18.0, 48.0, 4.0), Color("2a2a30"))
	planks(ci, Rect2(0, 246, W, 114), Color("8a5a34"), 11.0, 13.0)
	vgrad(ci, Rect2(0, 246, W, 114), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.45), 12)
	motes(ci, t, Color(1, 0.9, 0.6, 0.55), 20, 14.0, Rect2(0, 40, W, 200), 4.0)


static func _home(ci: CanvasItem, t: float) -> void:
	wall_planks(ci, Rect2(0, 0, W, 246), Color("a87a52"), 6.0)
	vgrad(ci, Rect2(0, 0, W, 246), Color(0, 0, 0, 0.25), Color(0, 0, 0, 0.0), 14)
	window_frame(ci, Rect2(70, 44, 120, 96), Color("7ec8f0"), Color("fff0c0"), Color("5a3a22"), t, true)
	light_shaft(ci, 130.0, 210.0, 140.0, 246.0, 70.0, Color(1.0, 0.95, 0.7, 0.14))
	ci.draw_rect(Rect2(260, 60, 10, 40), Color("3a2418"))
	# estante com livros e plantas
	bookshelf(ci, Rect2(380, 54, 120, 100), Color("6a4226"), 17.0)
	ci.draw_rect(Rect2(520, 120, 56, 90), Color("7a4a2a"))
	ci.draw_rect(Rect2(520, 120, 56, 90), Color("3a2214"), false, 3.0)
	ci.draw_circle(Vector2(548, 112), 16.0, Color("4a9a4a"))
	planks(ci, Rect2(0, 246, W, 114), Color("a06a3c"), 3.0, 14.0)
	# tapete
	ci.draw_colored_polygon(PackedVector2Array([Vector2(160, 262), Vector2(480, 262), Vector2(520, 340), Vector2(120, 340)]), Color("a3363a"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(180, 270), Vector2(460, 270), Vector2(492, 330), Vector2(148, 330)]), Color("c4585a"))
	vgrad(ci, Rect2(0, 246, W, 114), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.4), 12)
	motes(ci, t, Color(1, 0.95, 0.7, 0.6), 24, 15.0, Rect2(60, 60, 360, 200), 3.0)


static func _guild(ci: CanvasItem, t: float) -> void:
	bricks(ci, Rect2(0, 0, W, 246), Color("6a5a52"), Color("2a2220"), 8.0, 30.0, 15.0)
	vgrad(ci, Rect2(0, 0, W, 246), Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.0), 14)
	arch(ci, 320.0, 246.0, 70.0, 150.0, Color("7a6a60"), Color("5a7aa8"))
	glow(ci, Vector2(320, 150), 120.0, Color(1.0, 0.9, 0.6, 0.45), 8)
	# quadro de missões
	ci.draw_rect(Rect2(44, 66, 130, 100), Color("5a3a22"))
	ci.draw_rect(Rect2(50, 72, 118, 88), Color("a8844e"))
	for i in 8:
		var px := 56.0 + float(i % 4) * 28.0
		var py := 78.0 + float(i / 4) * 40.0
		ci.draw_rect(Rect2(px, py, 22, 30), Color("f1e5c6").darkened(rn(float(i)) * 0.1))
		ci.draw_circle(Vector2(px + 11.0, py + 3.0), 2.0, Color("c4453d"))
	banner(ci, Vector2(500, 36), 44.0, 120.0, Color("a8323a"), t)
	banner(ci, Vector2(580, 36), 44.0, 120.0, Color("2a4a8a"), t)
	for x in [232.0, 408.0]:
		torch(ci, Vector2(x, 96.0), t)
	planks(ci, Rect2(0, 246, W, 114), Color("6a4a30"), 5.0, 14.0)
	ci.draw_rect(Rect2(250, 246, 140, 114), Color("8a2a30"))
	vgrad(ci, Rect2(0, 246, W, 114), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.42), 12)
	motes(ci, t, Color(1, 0.9, 0.7, 0.5), 18, 16.0, Rect2(0, 40, W, 200), 3.0)


static func _library(ci: CanvasItem, t: float) -> void:
	vgrad(ci, Rect2(0, 0, W, 246), Color("2a1c14"), Color("4a3220"), 20)
	for i in 5:
		bookshelf(ci, Rect2(10.0 + float(i) * 128.0, 18.0, 116.0, 214.0), Color("5a3a22"), 30.0 + float(i) * 9.0)
	for x in [128.0, 384.0]:
		ci.draw_line(Vector2(x, 20), Vector2(x - 24.0, 232), Color("7a5a38"), 4.0)
		ci.draw_line(Vector2(x + 14.0, 20), Vector2(x - 10.0, 232), Color("7a5a38"), 4.0)
		for k in 8:
			var ly := 40.0 + float(k) * 24.0
			ci.draw_line(Vector2(x - float(k) * 3.0 + 2.0, ly), Vector2(x - float(k) * 3.0 + 14.0, ly), Color("5a3a22"), 3.0)
	for x in [256.0, 512.0]:
		ci.draw_line(Vector2(x, 0), Vector2(x, 70), Color("1a1008"), 1.5)
		ci.draw_rect(Rect2(x - 12.0, 70, 24, 8), Color("2a6a4a"))
		glow(ci, Vector2(x, 82), 90.0, Color(1.0, 0.85, 0.45, 0.7), 8)
	light_shaft(ci, 320.0, 290.0, -10.0, 246.0, 34.0, Color(1.0, 0.92, 0.65, 0.16))
	planks(ci, Rect2(0, 246, W, 114), Color("6a4224"), 9.0, 13.0)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(190, 262), Vector2(450, 262), Vector2(500, 340), Vector2(140, 340)]), Color("2a4a8a"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(210, 270), Vector2(430, 270), Vector2(468, 330), Vector2(172, 330)]), Color("3a62a8"))
	vgrad(ci, Rect2(0, 246, W, 114), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.42), 12)
	motes(ci, t, Color(1, 0.95, 0.75, 0.7), 36, 17.0, Rect2(200, 0, 260, 250), 3.0)


static func _forge(ci: CanvasItem, t: float) -> void:
	bricks(ci, Rect2(0, 0, W, 246), Color("5a4038"), Color("1e1412"), 12.0, 26.0, 13.0)
	vgrad(ci, Rect2(0, 0, W, 246), Color(0, 0, 0, 0.5), Color(0.2, 0.05, 0.0, 0.1), 14)
	# fornalha
	ci.draw_rect(Rect2(230, 80, 180, 170), Color("3a2c2a"))
	ci.draw_rect(Rect2(254, 130, 132, 120), Color("1a0804"))
	var fl := 1.0 + sin(t * 8.0) * 0.1
	glow(ci, Vector2(320, 190), 190.0 * fl, Color(1.0, 0.4, 0.1, 0.85), 10)
	for k in 6:
		var fh := 50.0 + sin(t * 10.0 + float(k) * 1.9) * 9.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(262.0 + float(k) * 20.0, 250), Vector2(284.0 + float(k) * 20.0, 250), Vector2(273.0 + float(k) * 20.0, 250.0 - fh)]), Color("ff5a1a"))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(268.0 + float(k) * 20.0, 250), Vector2(278.0 + float(k) * 20.0, 250), Vector2(273.0 + float(k) * 20.0, 250.0 - fh * 0.6)]), Color("ffd060"))
	ci.draw_rect(Rect2(214, 70, 212, 16), Color("4a3a38"))
	# ferramentas penduradas
	for i in 7:
		var x := 40.0 + float(i) * 22.0
		ci.draw_line(Vector2(x, 70), Vector2(x, 70.0 + 36.0 + rn(float(i)) * 30.0), Color("8a8a94"), 3.0)
		ci.draw_rect(Rect2(x - 5.0, 70.0 + 30.0 + rn(float(i)) * 30.0, 10, 10), Color("6a6a74"))
	for i in 5:
		var sx := 470.0 + float(i) * 26.0
		ci.draw_rect(Rect2(sx, 60.0, 4, 80.0), Color("b8c0cc"))
		ci.draw_rect(Rect2(sx - 6.0, 134.0, 16, 4), Color("5a4020"))
		ci.draw_rect(Rect2(sx, 138.0, 4, 14.0), Color("3a2418"))
	vgrad(ci, Rect2(0, 246, W, 114), Color("3a3030"), Color("120c0c"), 14)
	# bigorna
	ci.draw_rect(Rect2(110, 232, 70, 14), Color("4a4a54"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(100, 232), Vector2(190, 232), Vector2(176, 214), Vector2(116, 214)]), Color("5a5a66"))
	ci.draw_rect(Rect2(128, 246, 34, 20), Color("3a3a44"))
	for i in 30:
		var s := float(i)
		var life := fposmod(t * (0.7 + rn(s) * 0.8) + rn(s + 3.0), 1.0)
		var sx2 := 300.0 + (rn(s + 1.0) - 0.5) * 150.0 * life
		var sy := 200.0 - life * 130.0 * (0.5 + rn(s + 2.0))
		ci.draw_circle(Vector2(sx2, sy), 1.3, Color(1.0, 0.7 - life * 0.4, 0.2, 1.0 - life))


static func _weapons(ci: CanvasItem, t: float) -> void:
	wall_planks(ci, Rect2(0, 0, W, 246), Color("6a3a2a"), 24.0)
	vgrad(ci, Rect2(0, 0, W, 246), Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.0), 14)
	# racks de armas
	for i in 4:
		var x := 40.0 + float(i) * 150.0
		ci.draw_rect(Rect2(x, 94, 110, 8), Color("2a1810"))
		for k in 5:
			var wx := x + 12.0 + float(k) * 20.0
			ci.draw_rect(Rect2(wx, 40.0 + float(i % 2) * 10.0, 5, 62), Color("c8d0dc"))
			ci.draw_rect(Rect2(wx - 5.0, 94.0, 15, 4), Color("8a6a30"))
	for x in [95.0, 545.0]:
		ci.draw_circle(Vector2(x, 160), 26.0, Color("8a2a2a"))
		ci.draw_circle(Vector2(x, 160), 26.0, Color("2a1810"), false, 3.0)
		ci.draw_circle(Vector2(x, 160), 10.0, Color("e0c060"))
	for x in [220.0, 420.0]:
		glow(ci, Vector2(x, 70), 110.0, Color(1.0, 0.82, 0.5, 0.8), 9)
	# balcão e vitrine
	ci.draw_rect(Rect2(250, 168, 140, 78), Color("5a3a22"))
	ci.draw_rect(Rect2(250, 168, 140, 8), Color("8a5a34"))
	ci.draw_rect(Rect2(260, 140, 120, 28), Color(0.7, 0.85, 1.0, 0.25))
	ci.draw_rect(Rect2(282, 148, 76, 4), Color("c8d0dc"))
	planks(ci, Rect2(0, 246, W, 114), Color("5a3a28"), 13.0, 14.0)
	vgrad(ci, Rect2(0, 246, W, 114), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.45), 12)
	motes(ci, t, Color(1, 0.95, 0.75, 0.55), 18, 18.0, Rect2(0, 30, W, 210), 3.0)


static func _arena(ci: CanvasItem, t: float) -> void:
	vgrad(ci, Rect2(0, 0, W, 200), Color("7ec8f0"), Color("fff0c8"), 24)
	glow(ci, Vector2(120, 48), 90.0, Color(1.0, 0.95, 0.7, 0.9), 7)
	# arquibancadas
	for tier in 5:
		var y := 100.0 + float(tier) * 24.0
		ci.draw_rect(Rect2(0, y, W, 24.0), Color("8a8078").darkened(float(tier) * 0.03))
		ci.draw_rect(Rect2(0, y, W, 3.0), Color("b8aea4"))
		for i in 34:
			var hx := 8.0 + float(i) * 19.0 + rn(float(tier * 40 + i)) * 6.0
			var hc := Color.from_hsv(rn(float(tier * 80 + i)), 0.5, 0.6 + rn(float(tier + i)) * 0.3)
			var bob := absf(sin(t * (2.0 + rn(float(i)) * 2.0) + float(i))) * 3.0 * (1.0 if (i + tier) % 3 == 0 else 0.0)
			ci.draw_rect(Rect2(hx, y + 10.0 - bob, 9.0, 12.0), hc)
			ci.draw_circle(Vector2(hx + 4.5, y + 7.0 - bob), 4.0, Color("e6c8a0"))
	banner(ci, Vector2(120, 30), 40.0, 100.0, Color("a8323a"), t)
	banner(ci, Vector2(520, 30), 40.0, 100.0, Color("2a4a8a"), t)
	ci.draw_rect(Rect2(0, 222, W, 26), Color("6a5a50"))
	ci.draw_rect(Rect2(0, 222, W, 3), Color("a89888"))
	vgrad(ci, Rect2(0, 248, W, 112), Color("d4b078"), Color("a0804c"), 12)
	for i in 70:
		ci.draw_circle(Vector2(rn(float(i) * 3.0) * W, 252.0 + rn(float(i) * 5.0) * 104.0), 1.0, Color(0.5, 0.35, 0.2, 0.35))
	motes(ci, t, Color(1, 0.9, 0.6, 0.5), 20, 19.0, Rect2(0, 150, W, 200), 8.0)


static func _jail(ci: CanvasItem, t: float) -> void:
	bricks(ci, Rect2(0, 0, W, 246), Color("585660"), Color("1c1a22"), 22.0, 30.0, 15.0)
	vgrad(ci, Rect2(0, 0, W, 246), Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.1), 14)
	window_frame(ci, Rect2(440, 40, 60, 44), Color("0a1030"), Color("3a4a80"), Color("202028"), t, false)
	for k in 4:
		ci.draw_rect(Rect2(448.0 + float(k) * 12.0, 40, 3, 44), Color("14141c"))
	light_shaft(ci, 470.0, 380.0, 84.0, 246.0, 38.0, Color(0.7, 0.8, 1.0, 0.13))
	for x in [210.0]:
		torch(ci, Vector2(x, 100.0), t)
	# grades da cela
	for k in 14:
		ci.draw_rect(Rect2(20.0 + float(k) * 20.0, 30, 6, 216), Color("14141a"))
		ci.draw_rect(Rect2(20.0 + float(k) * 20.0, 30, 2, 216), Color("3a3a46"))
	ci.draw_rect(Rect2(10, 30, 296, 8), Color("14141a"))
	ci.draw_rect(Rect2(10, 238, 296, 8), Color("14141a"))
	vgrad(ci, Rect2(0, 246, W, 114), Color("3a3640"), Color("14121a"), 14)
	ci.draw_rect(Rect2(540, 190, 90, 56), Color("4a4650"))
	mist(ci, t, 262.0, Color(0.6, 0.65, 0.8, 0.3), 4, 51.0)
	motes(ci, t, Color(0.85, 0.9, 1.0, 0.5), 20, 20.0, Rect2(300, 60, 300, 200), 3.0)


static func _gate(ci: CanvasItem, t: float, forest: bool) -> void:
	# portão de madeira/pedra no lado direito (pedágio)
	if forest:
		ci.draw_rect(Rect2(466, 90, 24, 160), Color("4a2e18"))
		ci.draw_rect(Rect2(574, 90, 24, 160), Color("4a2e18"))
		ci.draw_rect(Rect2(456, 80, 152, 20), Color("5c3a1e"))
		ci.draw_rect(Rect2(490, 96, 84, 154), Color("2a1a0e"))
		for k in 4:
			ci.draw_rect(Rect2(498.0 + float(k) * 22.0, 96, 4, 154), Color("5c3a1e"))
		ci.draw_rect(Rect2(470, 60, 120, 14), Color("e8c25a"))
	else:
		ci.draw_rect(Rect2(452, 70, 30, 180), Color("3a3640"))
		ci.draw_rect(Rect2(578, 70, 30, 180), Color("3a3640"))
		ci.draw_rect(Rect2(446, 60, 168, 20), Color("4a4650"))
		ci.draw_rect(Rect2(482, 80, 96, 170), Color("08060c"))
		glow(ci, Vector2(530, 160), 70.0, Color(0.6, 0.2, 0.8, 0.5), 7)
		torch(ci, Vector2(436, 120), t)
		torch(ci, Vector2(624, 120), t)
