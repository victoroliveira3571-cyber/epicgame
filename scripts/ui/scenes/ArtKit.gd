class_name ArtKit
extends RefCounted

## Ferramentas de desenho vetorial (sem pixelização) para as cenas de estudo e o herói
## animado. Tudo recebe o CanvasItem onde desenhar. Coordenadas em px lógicos da cena.

static var _boxes: Dictionary = {}

# Aparência de cada classe (cores de pele, cabelo e roupa) para o herói vetorial.
const LOOKS := {
	"cavaleiro": {"skin": "f0c4a0", "hair": "5b3a22", "style": "short", "outfit": "8795a0", "accent": "d3dde2", "dark": "4b5862", "boots": "3a2c28", "extra": "plate"},
	"paladino": {"skin": "f4d0b0", "hair": "ebc45c", "style": "medium", "outfit": "e1b23c", "accent": "fff1bd", "dark": "9c7420", "boots": "5b3a22", "extra": "tabard"},
	"assassino": {"skin": "e8bd98", "hair": "1e1f2c", "style": "hood", "outfit": "2e3040", "accent": "a23a54", "dark": "191a26", "boots": "15161e", "extra": "scarf"},
	"escudeiro": {"skin": "f1c29a", "hair": "c9522c", "style": "spiky", "outfit": "dcd6c4", "accent": "3a70aa", "dark": "9d977f", "boots": "4a3528", "extra": "vest"},
	"mago": {"skin": "f5cfb8", "hair": "d8506c", "style": "long", "outfit": "6c4cac", "accent": "f3c452", "dark": "46307c", "boots": "3a2848", "extra": "robe"},
	"arqueiro": {"skin": "efbd98", "hair": "c9522c", "style": "hood", "outfit": "4f8c4a", "accent": "8e5f2c", "dark": "33602f", "boots": "4a3322", "extra": "quiver"},
}


static func col(hex: String, a: float = 1.0) -> Color:
	var c := Color(hex)
	c.a = a
	return c


static func poly(ci: CanvasItem, pts: Array, c: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), c)


static func ellipse_pts(center: Vector2, rx: float, ry: float, n: int = 32, rot: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		out.append(center + p.rotated(rot))
	return out


static func ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, c: Color, rot: float = 0.0) -> void:
	ci.draw_colored_polygon(ellipse_pts(center, rx, ry, 32, rot), c)


static func circle(ci: CanvasItem, center: Vector2, r: float, c: Color) -> void:
	ci.draw_circle(center, r, c)


static func rect(ci: CanvasItem, r: Rect2, c: Color) -> void:
	ci.draw_rect(r, c)


static func rrect(ci: CanvasItem, r: Rect2, radius: float, c: Color, border: Color = Color.TRANSPARENT, border_w: int = 0) -> void:
	var key := "%s|%d|%s|%d" % [c.to_html(), int(radius), border.to_html(), border_w]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = c
		sb.set_corner_radius_all(int(radius))
		sb.set_border_width_all(border_w)
		sb.border_color = border
		sb.anti_aliasing = true
		_boxes[key] = sb
	ci.draw_style_box(sb, r)


## Retângulo com degradê vertical (cima -> baixo).
static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


static func hgrad(ci: CanvasItem, r: Rect2, left: Color, right: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([left, right, right, left]))


## Linha grossa com pontas arredondadas.
static func limb(ci: CanvasItem, a: Vector2, b: Vector2, width: float, c: Color) -> void:
	ci.draw_line(a, b, c, width, true)
	ci.draw_circle(a, width / 2.0, c)
	ci.draw_circle(b, width / 2.0, c)


## Caminho suavizado (Catmull-Rom) para tecidos, caudas, galhos...
static func smooth(ci: CanvasItem, pts: Array, width: float, c: Color) -> void:
	var out := PackedVector2Array()
	for i in range(pts.size() - 1):
		var p0: Vector2 = pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[i + 1]
		var p3: Vector2 = pts[mini(i + 2, pts.size() - 1)]
		for k in 6:
			out.append(_cr(p0, p1, p2, p3, float(k) / 6.0))
	out.append(pts[pts.size() - 1])
	ci.draw_polyline(out, c, width, true)


static func _cr(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


## Pseudo-aleatório determinístico (0..1) a partir de um inteiro.
static func rnd(seed_i: int) -> float:
	var x := sin(float(seed_i) * 127.1 + 311.7) * 43758.5453
	return x - floorf(x)


# ================================================================== Herói
## Desenha o herói sentado, de perfil olhando para a direita. `pos` = quadril; `s` = escala.
## pose: write | read | sip. sit: chair | ground.
static func hero(ci: CanvasItem, class_id: String, pos: Vector2, s: float, t: float, pose: String = "write", sit: String = "chair") -> void:
	var look: Dictionary = LOOKS.get(class_id, LOOKS["cavaleiro"])
	var skin := col(look["skin"])
	var hair := col(look["hair"])
	var outfit := col(look["outfit"])
	var accent := col(look["accent"])
	var dark := col(look["dark"])
	var boots := col(look["boots"])
	var style: String = look["style"]
	var extra: String = look["extra"]
	ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	var breath := sin(t * 1.5) * 1.1
	var nod := sin(t * 0.8) * 1.2
	# --- sombra no chão/assento
	ellipse(ci, Vector2(24, 56 if sit == "chair" else 8), 70, 8, Color(0, 0, 0, 0.18))
	# --- pernas
	var knee := Vector2(44, 2)
	var foot := Vector2(50, 50)
	if sit == "ground":
		knee = Vector2(40, -30)
		foot = Vector2(82, 4)
		limb(ci, Vector2(-4, 2), Vector2(86, 6), 14, dark.darkened(0.2))      # perna de trás, esticada
		limb(ci, Vector2(-2, 0), knee, 16, dark)
		limb(ci, knee, foot, 14, dark)
		ellipse(ci, foot + Vector2(8, 2), 12, 6.5, boots)
		ellipse(ci, Vector2(92, 8), 12, 6.5, boots.darkened(0.2))
	else:
		limb(ci, Vector2(-2, 0), Vector2(40, 4), 16, dark.darkened(0.15))
		limb(ci, Vector2(40, 4), Vector2(44, 52), 13, dark.darkened(0.15))
		ellipse(ci, Vector2(52, 56), 12, 6, boots.darkened(0.15))
		limb(ci, Vector2(0, -2), knee, 17, dark)
		limb(ci, knee, foot, 14, dark)
		ellipse(ci, foot + Vector2(8, 5), 12.5, 6.5, boots)
	# --- manto/capa atrás (mago e arqueiro)
	if extra == "robe":
		poly(ci, [Vector2(-22, -50), Vector2(-34, 6), Vector2(8, 8), Vector2(10, -50)], dark)
	# --- tronco
	var top_y := -58.0 + breath * 0.6
	var torso: Array = [Vector2(-17, 4), Vector2(17, 4), Vector2(15, -28), Vector2(11, top_y), Vector2(-11, top_y), Vector2(-19, -28)]
	poly(ci, torso, outfit)
	poly(ci, [Vector2(-19, -28), Vector2(-11, top_y), Vector2(-4, top_y), Vector2(-9, -28), Vector2(-9, 4), Vector2(-17, 4)], outfit.darkened(0.14))
	match extra:
		"plate":
			poly(ci, [Vector2(-14, -50), Vector2(12, -50), Vector2(12, -24), Vector2(0, -16), Vector2(-14, -24)], accent.darkened(0.1))
			limb(ci, Vector2(-6, -46), Vector2(-6, -24), 2.2, Color(1, 1, 1, 0.5))
			rect(ci, Rect2(-17, -6, 34, 6), dark)
			circle(ci, Vector2(0, -3), 3, accent)
		"tabard":
			poly(ci, [Vector2(-8, -56), Vector2(8, -56), Vector2(10, 4), Vector2(-10, 4)], accent)
			rect(ci, Rect2(-2, -44, 4, 22), outfit)
			rect(ci, Rect2(-7, -37, 14, 4), outfit)
			rect(ci, Rect2(-17, -8, 34, 5), dark)
		"scarf":
			poly(ci, [Vector2(-12, -58), Vector2(14, -58), Vector2(16, -48), Vector2(-14, -48)], accent)
			poly(ci, [Vector2(-14, -50), Vector2(-26, -34 + sin(t * 2.0) * 3), Vector2(-20, -52)], accent.darkened(0.2))
			rect(ci, Rect2(-17, -8, 34, 5), dark)
		"vest":
			poly(ci, [Vector2(-14, -52), Vector2(14, -52), Vector2(14, 2), Vector2(-14, 2)], accent)
			rect(ci, Rect2(-2, -50, 4, 50), outfit)
			rect(ci, Rect2(-17, -8, 34, 5), dark)
		"robe":
			poly(ci, [Vector2(-14, -52), Vector2(14, -52), Vector2(16, 4), Vector2(-16, 4)], outfit.lightened(0.05))
			rect(ci, Rect2(-17, -14, 34, 5), accent)
			circle(ci, Vector2(0, -11), 3.5, accent.lightened(0.2))
			poly(ci, [Vector2(-14, -56), Vector2(14, -56), Vector2(0, -42)], accent)
		"quiver":
			poly(ci, [Vector2(-20, -52), Vector2(-10, -64), Vector2(-4, -60), Vector2(-14, -44)], accent.darkened(0.3))
			limb(ci, Vector2(-12, -62), Vector2(8, -20), 3, accent)
			rect(ci, Rect2(-17, -8, 34, 5), accent.darkened(0.2))
	# --- cabeça
	var head := Vector2(8, -82 + nod * 0.5 + breath * 0.4)
	if pose == "write":
		head += Vector2(3, 3)
	var neck_c := skin.darkened(0.08)
	rect(ci, Rect2(head.x - 8, head.y + 12, 13, 18), neck_c)
	# cabelo de trás
	if style == "long":
		poly(ci, [head + Vector2(-20, -8), head + Vector2(-30, 34), head + Vector2(-8, 40), head + Vector2(2, 10)], hair.darkened(0.15))
	elif style == "medium":
		poly(ci, [head + Vector2(-20, -8), head + Vector2(-26, 24), head + Vector2(-6, 28), head + Vector2(0, 6)], hair.darkened(0.12))
	if style == "hood":
		circle(ci, head + Vector2(-4, -1), 25, outfit.darkened(0.1))
		poly(ci, [head + Vector2(-20, 10), head + Vector2(-24, 34), head + Vector2(8, 30), head + Vector2(10, 12)], outfit.darkened(0.1))
	ellipse(ci, head + Vector2(-2, 0), 20, 21, hair.darkened(0.1) if style != "hood" else skin)
	# rosto
	ellipse(ci, head + Vector2(3, 3), 18.5, 20, skin)
	ellipse(ci, head + Vector2(-13, 4), 4, 5.5, skin.darkened(0.06))          # orelha
	# bochecha, nariz e boca
	circle(ci, head + Vector2(11, 12), 4.2, Color("ff8f8f", 0.28))
	poly(ci, [head + Vector2(19, 2), head + Vector2(24, 8), head + Vector2(19, 9)], skin.darkened(0.04))
	var smile := 0.6 if pose != "sip" else 1.0
	ci.draw_arc(head + Vector2(11, 15), 4.5, 0.25, PI * 0.5 + smile, 10, Color("8a4a3a"), 1.6, true)
	# olho (pisca a cada ~4 s; olha para baixo ao escrever)
	var blink := fmod(t + 1.3, 4.2) > 4.05
	var eye := head + Vector2(11, 1)
	var look_dy := 2.0 if pose == "write" else (1.0 if pose == "read" else 0.0)
	var ery := 1.2 if blink else 5.6
	ellipse(ci, eye, 4.6, ery, Color("ffffff"))
	if not blink:
		circle(ci, eye + Vector2(1.5, look_dy), 3.1, Color("2a1e3a"))
		circle(ci, eye + Vector2(2.4, look_dy - 1.2), 1.1, Color("ffffff"))
	ci.draw_arc(eye + Vector2(0, -2), 6.2, PI * 1.12, PI * 1.9, 8, hair.darkened(0.35), 1.8, true)   # sobrancelha
	if extra == "scarf":     # máscara do assassino
		poly(ci, [head + Vector2(-14, 8), head + Vector2(20, 8), head + Vector2(18, 26), head + Vector2(-8, 28)], accent.darkened(0.15))
	# franja / cabelo da frente
	var fringe: Array = [head + Vector2(-19, 0), head + Vector2(-16, -20), head + Vector2(2, -25), head + Vector2(20, -14), head + Vector2(22, -6),
		head + Vector2(14, -10), head + Vector2(9, -2), head + Vector2(2, -12), head + Vector2(-6, -4), head + Vector2(-12, 4)]
	if style == "hood":
		poly(ci, [head + Vector2(-20, -4), head + Vector2(-12, -26), head + Vector2(8, -27), head + Vector2(24, -12), head + Vector2(23, -4),
			head + Vector2(14, -12), head + Vector2(-2, -15), head + Vector2(-14, -8)], outfit)
		if look["hair"] == "c9522c":
			poly(ci, [head + Vector2(6, -14), head + Vector2(18, -8), head + Vector2(12, -2)], hair)
	else:
		poly(ci, fringe, hair)
		ci.draw_polyline(PackedVector2Array([head + Vector2(-10, -16), head + Vector2(0, -21), head + Vector2(10, -17)]), hair.lightened(0.25), 1.6, true)
	if style == "spiky":
		for i in 5:
			var bx := head.x - 16 + float(i) * 9.0
			poly(ci, [Vector2(bx, head.y - 20), Vector2(bx + 4, head.y - 36 + float(i % 2) * 4), Vector2(bx + 10, head.y - 18)], hair)
		rect(ci, Rect2(head.x - 18, head.y - 8, 40, 5), accent)    # faixa
	if extra == "robe":          # chapéu de mago
		ellipse(ci, head + Vector2(2, -17), 29, 6.5, dark)
		poly(ci, [head + Vector2(-17, -18), head + Vector2(21, -18), head + Vector2(10, -56 + nod), head + Vector2(-2, -64 + nod)], outfit)
		rect(ci, Rect2(head.x - 17, head.y - 23, 38, 5), accent)
		poly(ci, [head + Vector2(10, -56 + nod), head + Vector2(-2, -64 + nod), head + Vector2(20, -72 + nod)], outfit)
	if extra == "plate" and style == "short":
		pass
	# --- braços
	var shoulder := Vector2(1, -50 + breath * 0.4)
	var elbow := Vector2(24, -24)
	var hand := Vector2(52, -14)
	match pose:
		"write":
			hand = Vector2(54 + sin(t * 2.3) * 5.0, -13 + sin(t * 4.6) * 1.2)
			elbow = Vector2(26, -25)
		"read":
			elbow = Vector2(26, -26) if sit == "chair" else Vector2(30, -22)
			hand = Vector2(48, -42) if sit == "chair" else Vector2(52, -34)
		"sip":
			elbow = Vector2(26, -34)
			hand = Vector2(34, -70 + sin(t * 1.2) * 1.5)
	limb(ci, shoulder, elbow, 11.5, outfit.darkened(0.08))
	limb(ci, elbow, hand, 10, outfit)
	circle(ci, hand, 6, skin)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Posição global (no espaço da cena) da mão do herói — usada para encaixar pena, livro e caneca.
static func hero_hand(pos: Vector2, s: float, t: float, pose: String, sit: String = "chair") -> Vector2:
	var hand := Vector2(52, -14)
	match pose:
		"write":
			hand = Vector2(54 + sin(t * 2.3) * 5.0, -13 + sin(t * 4.6) * 1.2)
		"read":
			hand = Vector2(48, -42) if sit == "chair" else Vector2(52, -34)
		"sip":
			hand = Vector2(34, -70 + sin(t * 1.2) * 1.5)
	return pos + hand * s
