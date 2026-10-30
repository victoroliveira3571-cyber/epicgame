class_name StudyScene
extends Control

## Cenas animadas (vetoriais, sem pixelização) do herói estudando. Desenhadas em 1200x600
## px lógicos; quem usa pode escalar o Control. Cenários: estudo, cafeteria, natureza, livraria.

const W := 1200.0
const H := 600.0
const SCENES := {
	"estudo": {"name": "Torre de estudo", "desc": "Vela acesa e pergaminhos; à noite, chuva na janela."},
	"cafeteria": {"name": "Cafeteria medieval", "desc": "Taverna aconchegante com lareira e caneca quente."},
	"natureza": {"name": "Na natureza", "desc": "Sob a árvore, perto do lago, numa manhã de sol."},
	"livraria": {"name": "Livraria", "desc": "Estantes até o teto e luz dourada da tarde."},
}
const ORDER := ["estudo", "cafeteria", "natureza", "livraria"]
const HS := 1.6          # escala do herói nas cenas

# Pixel art (tools/gen_pomodoro_bg.py e gen_pomodoro_fx.py): fundo 400x208 em escala 3, subido 12 px.
const ART_DIR := "res://assets/custom/pomodoro/"
const ART_SCALE := 3.0
const ART_OFFSET_Y := -12.0
# Onde o herói fica em cada cena (quadril, escala HS) e se senta em cadeira ou no chão.
const HERO_SPOT := {
	"livraria": [Vector2(480, 432), "chair"], "cafeteria": [Vector2(480, 447), "chair"],
	"natureza": [Vector2(490, 520), "ground"], "estudo": [Vector2(450, 441), "chair"],
}
# Animações sobre o fundo: [sprite, x_arte, y_arte (canto superior esquerdo), fase]
const FX_SPOTS := {
	"cafeteria": [["lareira", 323, 125, 0.0], ["vela", 281, 115, 0.3],
		["vela_pequena", 182, 30, 0.1], ["vela_pequena", 191, 31, 0.5], ["vela_pequena", 200, 32, 0.9],
		["vela_pequena", 209, 31, 0.2], ["vela_pequena", 218, 30, 0.6], ["vapor", 232, 117, 0.0]],
	"livraria": [["vapor", 229, 112, 0.0]],
	"estudo": [["vela", 331, 115, 0.0], ["vapor", 288, 116, 0.4]],
	"natureza": [["vapor", 260, 150, 0.0], ["agua", 170, 136, 0.0], ["agua", 250, 141, 0.4], ["agua", 330, 137, 0.7]],
}

var scene_id: String = "cafeteria"
var class_id: String = "cavaleiro"
var state: String = "focus"       # focus | break | paused | idle
var look: Dictionary = {}         # visual LPC do herói (GameState.look); vazio = padrão
var use_lpc: bool = true          # herói LPC em camadas (false = herói antigo por classe)
var t: float = 0.0
static var _art_cache: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta * (0.25 if state == "paused" else 1.0)
	queue_redraw()


func pose() -> String:
	if state == "break":
		return "sip"
	if scene_id == "cafeteria" and fmod(t, 16.0) > 11.5:
		return "sip"
	if scene_id == "natureza" or scene_id == "livraria":
		return "read"
	return "write"


func _draw() -> void:
	if _art(art_id()) != null:
		_draw_art()
	else:
		_draw_procedural()
	# névoa leve de vinheta
	ArtKit.vgrad(self, Rect2(0, 0, W, 70), Color(0, 0, 0, 0.28), Color(0, 0, 0, 0))
	ArtKit.vgrad(self, Rect2(0, H - 90, W, 90), Color(0, 0, 0, 0), Color(0, 0, 0, 0.3))


## Nome do arquivo de fundo: a torre de estudo tem versão noturna (de 18h às 6h).
func art_id() -> String:
	if scene_id == "estudo":
		var hour := int(Time.get_time_dict_from_system()["hour"])
		if (hour >= 18 or hour < 6) and _art("estudo_noite") != null:
			return "estudo_noite"
	return scene_id


static func _art(name: String) -> Texture2D:
	if _art_cache.has(name):
		return _art_cache[name]
	var path := ART_DIR + name + ".png"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_art_cache[name] = tex
	return tex


static func _fx_info(name: String) -> Dictionary:
	var key := "fx_info:" + name
	if _art_cache.has(key):
		return _art_cache[key]
	var info := {}
	var path := ART_DIR + (name if name.begins_with("hero/") else "fx/" + name) + ".json"
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) == TYPE_DICTIONARY:
			info = parsed
	_art_cache[key] = info
	return info


func art_pos(ax: float, ay: float) -> Vector2:
	return Vector2(ax * ART_SCALE, ay * ART_SCALE + ART_OFFSET_Y)


## Desenha um quadro de uma animação (pixel art, escala 3) com o canto em pos (coordenadas da cena).
func fx(name: String, pos: Vector2, phase: float = 0.0, speed: float = 1.0) -> void:
	var tex := _art("fx/" + name)
	var info := _fx_info(name)
	if tex == null or info.is_empty():
		return
	var n := int(info["frames"])
	var fw := float(info["w"])
	var fh := float(info["h"])
	var frame := int(floor((t * speed + phase) * float(info["fps"]))) % n
	draw_texture_rect_region(tex, Rect2(pos, Vector2(fw, fh) * ART_SCALE), Rect2(frame * fw, 0, fw, fh))


func _draw_art() -> void:
	var id := art_id()
	draw_texture_rect(_art(id), Rect2(0, ART_OFFSET_Y, 400 * ART_SCALE, 208 * ART_SCALE), false)
	for spot in FX_SPOTS.get(scene_id, []):
		fx(spot[0], art_pos(spot[1], spot[2]), spot[3])
	_ambient_fx(id)
	var spot_h: Array = HERO_SPOT.get(scene_id, [Vector2(500, 440), "chair"])
	var hero_pos: Vector2 = spot_h[0]
	var sit: String = spot_h[1]
	var p := pose()
	if sit == "ground" and p == "write":
		p = "read"
	var lpc_hero := use_lpc and Lpc.available()
	var pixel_hero := lpc_hero or _hero_art(p, sit) != null
	if lpc_hero:
		_draw_lpc_hero(hero_pos, p, sit)
	elif pixel_hero:
		_draw_hero_art(hero_pos, p, sit)
	else:
		ArtKit.hero(self, class_id, hero_pos, HS, t, p, sit)
	var fg := _art(id + "_fg")
	if fg != null:
		draw_texture_rect(fg, Rect2(0, ART_OFFSET_Y, 400 * ART_SCALE, 208 * ART_SCALE), false)
	if not pixel_hero:
		var hand := ArtKit.hero_hand(hero_pos, HS, t, p, sit)
		match p:
			"sip":
				_mug(hand + Vector2(10, -14))
			"read":
				_book_in_hand(hand + (Vector2(-6, 10) if sit == "ground" else Vector2.ZERO))
			_:
				_pen(hand)


## Herói LPC em camadas (Lpc.gd), de lado, com o quadril em `hip`. Pisca de vez em quando e
## segura o livro (foco) ou a caneca (pausa) no colo; os objetos são pixel art na mesma escala.
func _draw_lpc_hero(hip: Vector2, p: String, sit: String) -> void:
	var kind := "ground" if sit == "ground" else "chair"
	var frame := Lpc.F_GROUND if kind == "ground" else Lpc.F_CHAIR
	var blink := fmod(t + 1.3, 4.7) < 0.14
	var top := (hip - Lpc.anchor(kind) * ART_SCALE).round()
	Lpc.draw(self, top, ART_SCALE, frame, Lpc.layers(look, blink))
	# mãos no colo (coordenadas do quadro 64x64)
	var hand := Vector2(38, 44) if kind == "chair" else Vector2(33, 50)
	if p == "sip":
		_px_mug(top, hand + Vector2(0, -6))
	else:
		_px_book(top, hand + Vector2(-3, -6))


## Retângulo em "pixels de arte" relativos ao canto do quadro do herói.
func _px(top: Vector2, x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(top + Vector2(x, y) * ART_SCALE, Vector2(w, h) * ART_SCALE), c)


func _px_book(top: Vector2, at: Vector2) -> void:
	var x := at.x
	var y := at.y
	_px(top, x - 1, y + 1, 13, 6, Color("2b1e24"))           # contorno
	_px(top, x, y + 2, 11, 4, Color("2f5d62"))               # capa
	_px(top, x, y, 5, 4, Color("fff3d4"))                    # página esquerda
	_px(top, x + 6, y, 5, 4, Color("f3e3bd"))                # página direita
	_px(top, x + 5, y, 1, 5, Color("8a6a4a"))                # lombada
	for k in 2:
		_px(top, x + 1, y + 1 + k * 2, 3, 1, Color("b9a888"))
		_px(top, x + 7, y + 1 + k * 2, 3, 1, Color("b9a888"))
	if fmod(t, 9.0) > 8.4:                                    # vira a página
		_px(top, x + 6, y - 2, 3, 5, Color("fff8e6"))


func _px_mug(top: Vector2, at: Vector2) -> void:
	_px(top, at.x - 1, at.y - 1, 7, 8, Color("2b1e24"))
	_px(top, at.x, at.y, 5, 6, Color("c58a3a"))
	_px(top, at.x, at.y, 5, 1, Color("6b3a20"))
	_px(top, at.x + 5, at.y + 1, 2, 3, Color("2b1e24"))
	_px(top, at.x + 5, at.y + 2, 1, 1, Color("c58a3a"))
	var ph := fmod(t * 0.8, 1.0)
	var steam := Color(1, 1, 1, 0.55 * (1.0 - ph))
	_px(top, at.x + 1 + round(sin(t * 3.0)), at.y - 3 - ph * 5.0, 1, 2, steam)
	_px(top, at.x + 3 + round(sin(t * 3.0 + 1.5)), at.y - 4 - ph * 4.0, 1, 2, steam)


## Herói em pixel art (tools/gen_pomodoro_hero.py): folha de 6 quadros por classe/pose/assento.
func _hero_art(p: String, sit: String) -> Texture2D:
	return _art("hero/%s_%s_%s" % [class_id, p, sit])


func _draw_hero_art(hip: Vector2, p: String, sit: String) -> void:
	var key := "hero/%s_%s_%s" % [class_id, p, sit]
	var tex := _art(key)
	var info := _fx_info(key)
	if tex == null or info.is_empty():
		return
	var fw := float(info["w"])
	var fh := float(info["h"])
	var frame := int(floor(t * float(info["fps"]))) % int(info["frames"])
	var origin := hip - Vector2(float(info["ax"]), float(info["ay"])) * ART_SCALE
	draw_texture_rect_region(tex, Rect2(origin, Vector2(fw, fh) * ART_SCALE), Rect2(frame * fw, 0, fw, fh))


## Partículas que andam pela cena (folhas, poeira na luz, chuva na janela).
func _ambient_fx(id: String) -> void:
	match id:
		"natureza":
			for i in 6:
				var ph := fmod(t * 0.1 + float(i) * 0.17, 1.0)
				var ax := 60.0 + float(i) * 9.0 + sin(ph * 10.0 + float(i)) * 14.0 + ph * 40.0
				var ay := 70.0 + ph * 110.0
				fx("folha", art_pos(ax, ay), float(i) * 0.3)
			for i in 5:
				fx("poeira", art_pos(150.0 + float(i) * 47.0, 158.0 + float(i % 3) * 9.0), float(i) * 0.4, 0.6)
		"livraria", "estudo", "cafeteria":
			var area := Rect2(160, 110, 160, 70) if id != "cafeteria" else Rect2(40, 60, 240, 90)
			for i in 7:
				var ax := area.position.x + fmod(ArtKit.rnd(i) * area.size.x + t * 3.0, area.size.x)
				var ay := area.position.y + fmod(ArtKit.rnd(i + 20) * area.size.y + sin(t * 0.5 + float(i)) * 6.0, area.size.y)
				fx("poeira", art_pos(floorf(ax), floorf(ay)), float(i) * 0.37, 0.5)
		"estudo_noite":
			var win := Rect2(110, 27, 128, 101)
			for gy in 2:
				for gx in 2:
					var tex := _art("fx/chuva")
					var info := _fx_info("chuva")
					if tex == null or info.is_empty():
						continue
					var frame := int(floor(t * float(info["fps"]))) % int(info["frames"])
					var tw := minf(64.0, win.size.x - gx * 64.0)
					var th := minf(64.0, win.size.y - gy * 64.0)
					draw_texture_rect_region(tex, Rect2(art_pos(win.position.x + gx * 64.0, win.position.y + gy * 64.0), Vector2(tw, th) * ART_SCALE),
						Rect2(frame * 64.0, 0, tw, th))


func _draw_procedural() -> void:
	match scene_id:
		"estudo":
			_draw_study()
		"natureza":
			_draw_nature()
		"livraria":
			_draw_bookstore()
		_:
			_draw_cafe()


# ================================================================== utilidades
func glow(p: Vector2, r: float, c: Color, a: float = 0.5) -> void:
	for i in 12:
		var k := float(i) / 12.0
		draw_circle(p, r * (1.0 - k), Color(c.r, c.g, c.b, a * 0.085))


func flicker(seed_i: int = 0, speed: float = 1.0) -> float:
	return 0.85 + 0.1 * sin(t * 9.0 * speed + seed_i) + 0.06 * sin(t * 23.0 * speed + seed_i * 2.0)


func steam(base: Vector2, count: int = 4, rise: float = 46.0, alpha: float = 0.35) -> void:
	for i in count:
		var ph := fmod(t * 0.45 + float(i) / float(count), 1.0)
		var x := base.x + sin(ph * 7.0 + float(i)) * 6.0
		var y := base.y - ph * rise
		draw_circle(Vector2(x, y), 4.0 + ph * 7.0, Color(1, 1, 1, alpha * (1.0 - ph)))


func books_row(r: Rect2, seed_i: int, palette: Array) -> void:
	var x := r.position.x + 4.0
	var i := seed_i
	while x < r.end.x - 14.0:
		i += 1
		var bw := 11.0 + ArtKit.rnd(i) * 11.0
		var bh := r.size.y * (0.68 + ArtKit.rnd(i + 99) * 0.3)
		var c := Color(palette[int(ArtKit.rnd(i + 5) * palette.size()) % palette.size()])
		if ArtKit.rnd(i + 31) > 0.9:
			x += bw * 1.2
			continue
		ArtKit.rrect(self, Rect2(x, r.end.y - bh, bw, bh), 2, c)
		draw_rect(Rect2(x + 2, r.end.y - bh + 5, bw - 4, 2), Color(1, 1, 1, 0.22))
		draw_rect(Rect2(x + 2, r.end.y - 14, bw - 4, 3), Color(1, 0.9, 0.5, 0.35))
		x += bw + 1.5


func dust(area: Rect2, n: int, c: Color, speed: float = 1.0) -> void:
	for i in n:
		var ph := fmod(t * 0.03 * speed + ArtKit.rnd(i * 3) , 1.0)
		var x := area.position.x + fmod(ArtKit.rnd(i) * area.size.x + sin(t * 0.4 + float(i)) * 22.0 + t * 4.0 * speed, area.size.x)
		var y := area.position.y + fmod(ArtKit.rnd(i + 50) * area.size.y + ph * 50.0, area.size.y)
		var a := (0.25 + 0.35 * sin(t * 1.3 + float(i))) * c.a
		draw_circle(Vector2(x, y), 1.4 + ArtKit.rnd(i + 9) * 1.6, Color(c.r, c.g, c.b, maxf(a, 0.05)))


func plank_floor(top: float, c1: Color, c2: Color) -> void:
	ArtKit.vgrad(self, Rect2(0, top, W, H - top), c1, c2)
	var x := 0.0
	var i := 0
	while x < W:
		var wd := 90.0 + ArtKit.rnd(i) * 60.0
		draw_line(Vector2(x, top), Vector2(x - 40, H), Color(0, 0, 0, 0.22), 2.0)
		draw_line(Vector2(x + 2, top), Vector2(x - 38, H), Color(1, 1, 1, 0.05), 1.0)
		x += wd
		i += 1
	draw_line(Vector2(0, top), Vector2(W, top), Color(0, 0, 0, 0.35), 3.0)


func cat(p: Vector2, sc: float, fur: Color) -> void:
	var breath := sin(t * 1.4) * 1.5
	ArtKit.ellipse(self, p + Vector2(0, 6), 36 * sc, 6 * sc, Color(0, 0, 0, 0.2))
	ArtKit.ellipse(self, p + Vector2(0, -12 * sc - breath * 0.4), 34 * sc, 17 * sc + breath * 0.3, fur)
	ArtKit.ellipse(self, p + Vector2(-26 * sc, -8 * sc), 13 * sc, 12 * sc, fur)
	ArtKit.poly(self, [p + Vector2(-36 * sc, -16 * sc), p + Vector2(-33 * sc, -30 * sc), p + Vector2(-26 * sc, -18 * sc)], fur.darkened(0.1))
	ArtKit.poly(self, [p + Vector2(-22 * sc, -18 * sc), p + Vector2(-17 * sc, -30 * sc), p + Vector2(-14 * sc, -16 * sc)], fur.darkened(0.1))
	draw_arc(p + Vector2(-30 * sc, -9 * sc), 3.5 * sc, 0.1, PI - 0.1, 8, Color("3a2418"), 1.6, true)
	draw_arc(p + Vector2(-21 * sc, -9 * sc), 3.5 * sc, 0.1, PI - 0.1, 8, Color("3a2418"), 1.6, true)
	var tail := [p + Vector2(30 * sc, -6 * sc), p + Vector2((50 + sin(t * 1.5) * 6) * sc, -16 * sc), p + Vector2((62 + sin(t * 1.5 + 1) * 9) * sc, -34 * sc), p + Vector2((58 + sin(t * 1.5 + 2) * 12) * sc, -50 * sc)]
	ArtKit.smooth(self, tail, 7 * sc, fur)
	for k in 3:
		draw_line(p + Vector2((-4 + k * 12) * sc, -26 * sc), p + Vector2((-2 + k * 12) * sc, -14 * sc), fur.darkened(0.25), 2.0, true)


# ================================================================== LIVRARIA
func _draw_bookstore() -> void:
	var pal := ["8c2f39", "2f5d62", "c7923e", "3d3a6b", "5b7a3a", "a8543a", "6b3a5a", "d6c08a", "27485e"]
	ArtKit.vgrad(self, Rect2(0, 0, W, 470), Color("5b3a28"), Color("3a2418"))
	# estantes laterais
	for side in [0, 1]:
		var x0 := 0.0 if side == 0 else 880.0
		ArtKit.rrect(self, Rect2(x0, 10, 320, 470), 4, Color("2d1b12"))
		for r in 5:
			var y := 24.0 + float(r) * 90.0
			ArtKit.rect(self, Rect2(x0 + 10, y, 300, 80), Color("1d120c"))
			books_row(Rect2(x0 + 12, y + 2, 296, 78), r * 17 + side * 101, pal)
			ArtKit.rect(self, Rect2(x0 + 6, y + 80, 308, 9), Color("6b4430"))
			ArtKit.rect(self, Rect2(x0 + 6, y + 80, 308, 2), Color("8a5a3e"))
	# janela em arco com luz da tarde
	var wc := Vector2(600, 190)
	ArtKit.vgrad(self, Rect2(448, 108, 304, 200), Color("ffd78a"), Color("f6a35a"))
	ArtKit.ellipse(self, Vector2(600, 108), 152, 92, Color("ffd78a"))
	glow(Vector2(660, 190), 120, Color("fff0b0"), 0.6)
	draw_circle(Vector2(670, 175), 30, Color("fff4c8"))
	for i in 3:
		var cx := fmod(t * (10 + i * 4) + i * 160.0, 420.0) + 410.0
		ArtKit.ellipse(self, Vector2(cx, 150 + i * 36), 46, 11, Color(1, 1, 1, 0.55))
	draw_arc(Vector2(600, 108), 152, PI, TAU, 40, Color("3a2418"), 10.0, true)
	draw_rect(Rect2(444, 104, 10, 210), Color("3a2418"))
	draw_rect(Rect2(746, 104, 10, 210), Color("3a2418"))
	draw_rect(Rect2(444, 300, 312, 14), Color("4a3022"))
	draw_rect(Rect2(595, 20, 10, 288), Color("3a2418"))
	draw_rect(Rect2(448, 190, 304, 8), Color("3a2418"))
	# raio de luz na sala
	ArtKit.poly(self, [Vector2(470, 308), Vector2(740, 308), Vector2(1020, 560), Vector2(560, 560)], Color(1.0, 0.85, 0.5, 0.11))
	dust(Rect2(480, 310, 520, 250), 34, Color("ffe9a8", 1.0), 1.0)
	plank_floor(470, Color("6b4630"), Color("3d2618"))
	# escada encostada na estante
	draw_line(Vector2(300, 90), Vector2(372, 480), Color("a8743f"), 8, true)
	draw_line(Vector2(330, 90), Vector2(400, 480), Color("a8743f"), 8, true)
	for i in 8:
		var y := 130.0 + float(i) * 46.0
		draw_line(Vector2(304 + (y - 90) * 0.185, y), Vector2(332 + (y - 90) * 0.185, y), Color("7a4e2c"), 6, true)
	# lanterna pendurada
	var lp := Vector2(600, 40)
	draw_line(Vector2(600, 0), lp, Color("2a1a10"), 3)
	ArtKit.rrect(self, Rect2(lp.x - 18, lp.y, 36, 46), 6, Color("c58a3a"))
	ArtKit.rrect(self, Rect2(lp.x - 12, lp.y + 8, 24, 30), 4, Color(1, 0.88, 0.5))
	glow(lp + Vector2(0, 26), 190, Color("ffc467"), 0.55 * flicker())
	# mesa
	var hero_pos := Vector2(500, 432)
	_chair_back(Vector2(420, 440))
	ArtKit.hero(self, class_id, hero_pos, HS, t, pose(), "chair")
	var top := 408.0
	ArtKit.rrect(self, Rect2(520, top, 520, 22), 6, Color("94603a"))
	ArtKit.rect(self, Rect2(528, top, 504, 4), Color("b9814e"))
	ArtKit.rect(self, Rect2(540, top + 22, 480, 70), Color("6f4529"))
	ArtKit.rect(self, Rect2(540, top + 22, 480, 4), Color("4a2d1a"))
	ArtKit.rect(self, Rect2(560, top + 92, 22, 70), Color("5a361f"))
	ArtKit.rect(self, Rect2(980, top + 92, 22, 70), Color("5a361f"))
	# livro aberto, pilha de livros, lâmpada, xícara e gato
	var hand := ArtKit.hero_hand(hero_pos, HS, t, pose())
	if pose() == "read":
		_open_book(Vector2(594, top - 4), 1.0)
		_book_in_hand(hand)
	elif pose() == "sip":
		_mug(hand + Vector2(10, -12))
		_open_book(Vector2(594, top - 4), 1.0)
	else:
		_open_book(Vector2(594, top - 4), 1.0)
		_pen(hand)
	for k in 4:
		var bw := 120.0 - float(k) * 8.0
		ArtKit.rrect(self, Rect2(790 - (bw - 100) / 2.0, top - 22 - float(k) * 20.0, bw, 20), 3, Color(pal[k * 2 % pal.size()]))
		draw_rect(Rect2(792 - (bw - 100) / 2.0, top - 21 - float(k) * 20.0, bw - 6, 3), Color(1, 1, 1, 0.2))
	_desk_lamp(Vector2(940, top), "7a9a52")
	_mug(Vector2(700, top - 8))
	steam(Vector2(700, top - 24), 4, 40)
	cat(Vector2(1000, top + 2), 0.9, Color("d98f4a"))


func _chair_back(p: Vector2) -> void:
	ArtKit.rrect(self, Rect2(p.x - 14, p.y - 130, 18, 150), 6, Color("5d3a22"))
	ArtKit.rrect(self, Rect2(p.x - 10, p.y - 122, 8, 120), 3, Color("7a4e2c"))
	ArtKit.rrect(self, Rect2(p.x - 20, p.y + 20, 120, 16), 5, Color("5d3a22"))


func _open_book(p: Vector2, sc: float) -> void:
	var l: Array = [p + Vector2(0, 0) * sc, p + Vector2(52, -10) * sc, p + Vector2(52, 4) * sc, p + Vector2(0, 14) * sc]
	var r: Array = [p + Vector2(52, -10) * sc, p + Vector2(104, 0) * sc, p + Vector2(104, 14) * sc, p + Vector2(52, 4) * sc]
	ArtKit.poly(self, [p + Vector2(-4, 14) * sc, p + Vector2(52, 8) * sc, p + Vector2(108, 14) * sc, p + Vector2(108, 20) * sc, p + Vector2(52, 14) * sc, p + Vector2(-4, 20) * sc], Color("6b2f34"))
	ArtKit.poly(self, l, Color("f6ecd2"))
	ArtKit.poly(self, r, Color("fff6dc"))
	for k in 4:
		draw_line(p + Vector2(6, 2 + k * 3) * sc, p + Vector2(46, -5 + k * 3) * sc, Color("a89f84"), 1.2, true)
		draw_line(p + Vector2(58, -5 + k * 3) * sc, p + Vector2(98, 2 + k * 3) * sc, Color("a89f84"), 1.2, true)


func _book_in_hand(hand: Vector2) -> void:
	var flip := fmod(t, 7.0) > 6.4
	ArtKit.rrect(self, Rect2(hand.x - 4, hand.y - 34, 54, 40), 4, Color("2f5d62"))
	ArtKit.rrect(self, Rect2(hand.x + 0, hand.y - 30, 48, 32), 3, Color("fff3d4"))
	if flip:
		ArtKit.poly(self, [hand + Vector2(24, -30), hand + Vector2(24, 2), hand + Vector2(4, -4), hand + Vector2(8, -34)], Color("e6d9b4"))
	ArtKit.circle(self, hand, 8, Color(ArtKit.LOOKS[class_id]["skin"]))


func _pen(hand: Vector2) -> void:
	draw_line(hand + Vector2(-2, 2), hand + Vector2(18, -22), Color("f5f0e6"), 3.0, true)
	draw_line(hand + Vector2(16, -20), hand + Vector2(24, -34), Color("e9e1d0"), 4.0, true)
	draw_circle(hand + Vector2(-2, 3), 2.2, Color("20202a"))


func _mug(p: Vector2) -> void:
	ArtKit.rrect(self, Rect2(p.x - 14, p.y - 20, 28, 26), 5, Color("c9a06a"))
	ArtKit.rect(self, Rect2(p.x - 12, p.y - 16, 24, 4), Color("7a4a2a"))
	draw_arc(p + Vector2(16, -8), 8, -PI / 2.0, PI / 2.0, 10, Color("c9a06a"), 4.0, true)


func _desk_lamp(p: Vector2, shade_hex: String) -> void:
	ArtKit.ellipse(self, p + Vector2(0, -4), 26, 6, Color("2a2a2a"))
	draw_line(p + Vector2(0, -4), p + Vector2(-6, -70), Color("c9a24a"), 5, true)
	draw_line(p + Vector2(-6, -70), p + Vector2(20, -96), Color("c9a24a"), 5, true)
	ArtKit.poly(self, [p + Vector2(8, -104), p + Vector2(46, -98), p + Vector2(60, -78), p + Vector2(20, -76)], Color(shade_hex))
	glow(p + Vector2(34, -70), 140, Color("ffe4a0"), 0.55 * flicker(3, 0.2))


# ================================================================== CAFETERIA
func _draw_cafe() -> void:
	ArtKit.vgrad(self, Rect2(0, 0, W, 470), Color("6b5a52"), Color("4a3b36"))
	# blocos de pedra
	for row in 9:
		var y := 90.0 + float(row) * 42.0
		var off := 0.0 if row % 2 == 0 else 40.0
		for col in 17:
			var x := float(col) * 80.0 - off
			ArtKit.rrect(self, Rect2(x + 2, y + 2, 76, 38), 5, Color(0.0, 0.0, 0.0, 0.0), Color(0, 0, 0, 0.22), 2)
			draw_rect(Rect2(x + 6, y + 6, 40, 3), Color(1, 1, 1, 0.04))
	# teto e vigas
	ArtKit.vgrad(self, Rect2(0, 0, W, 92), Color("2a1a12"), Color("4a3022"))
	for x in [230.0, 640.0, 1010.0]:
		ArtKit.rect(self, Rect2(x - 16, 80, 32, 400), Color("3a2418"))
		ArtKit.rect(self, Rect2(x - 16, 80, 6, 400), Color("5a3a28"))
	ArtKit.rect(self, Rect2(0, 76, W, 26), Color("3a2418"))
	ArtKit.rect(self, Rect2(0, 76, W, 5), Color("6a4630"))
	# janela com a vila ao entardecer
	ArtKit.vgrad(self, Rect2(80, 150, 190, 220), Color("5b7fb8"), Color("f0b472"))
	for i in 5:
		var hx := 90.0 + float(i) * 36.0
		var hh := 40.0 + ArtKit.rnd(i + 3) * 40.0
		ArtKit.rect(self, Rect2(hx, 370 - hh, 30, hh), Color("2a2438"))
		ArtKit.poly(self, [Vector2(hx - 3, 370 - hh), Vector2(hx + 15, 370 - hh - 20), Vector2(hx + 33, 370 - hh)], Color("3a2f4a"))
		ArtKit.rect(self, Rect2(hx + 10, 370 - hh + 12, 8, 10), Color("ffd27a", 0.9))
	draw_circle(Vector2(210, 200), 16, Color("fff0c8"))
	for k in 3:
		var bx := fmod(t * 18.0 + float(k) * 70.0, 220.0) + 60.0
		draw_arc(Vector2(bx, 190 + float(k) * 16.0), 7, PI * 1.1, PI * 1.9, 8, Color("2a2438"), 2.0, true)
	ArtKit.rrect(self, Rect2(74, 144, 202, 232), 12, Color(0, 0, 0, 0), Color("2a1a12"), 10)
	draw_rect(Rect2(172, 150, 8, 220), Color("2a1a12"))
	draw_rect(Rect2(80, 254, 190, 8), Color("2a1a12"))
	glow(Vector2(175, 260), 180, Color("ffb86a"), 0.22)
	# lareira
	_fireplace(Vector2(1030, 470))
	# panelas e ervas penduradas na viga
	for i in 6:
		var hx := 330.0 + float(i) * 70.0
		var sway := sin(t * 1.1 + float(i)) * 3.0
		draw_line(Vector2(hx, 100), Vector2(hx + sway, 140), Color("2a1a12"), 2)
		if i % 3 == 0:
			ArtKit.rrect(self, Rect2(hx + sway - 14, 140, 28, 26), 6, Color("8a8a92"))
			draw_arc(Vector2(hx + sway, 140), 10, PI, TAU, 8, Color("5a5a62"), 2.0, true)
		elif i % 3 == 1:
			for k in 3:
				draw_line(Vector2(hx + sway, 140), Vector2(hx + sway + (k - 1) * 8, 176), Color("5b8a3a"), 4, true)
		else:
			ArtKit.ellipse(self, Vector2(hx + sway, 152), 9, 12, Color("f1e3c4"))
	# lustre de velas
	_chandelier(Vector2(610, 90))
	plank_floor(470, Color("5a3a26"), Color("2e1c12"))
	# barris
	for bx in [50.0, 130.0]:
		ArtKit.rrect(self, Rect2(bx - 34, 420, 68, 90), 14, Color("7a4e2c"))
		draw_rect(Rect2(bx - 34, 440, 68, 6), Color("3a2418"))
		draw_rect(Rect2(bx - 34, 486, 68, 6), Color("3a2418"))
		draw_rect(Rect2(bx - 26, 426, 8, 78), Color(1, 1, 1, 0.1))
	# mesa e herói
	var hero_pos := Vector2(500, 440)
	ArtKit.rrect(self, Rect2(420, 478, 170, 20), 6, Color("6a4228"))     # banco
	ArtKit.rect(self, Rect2(436, 498, 14, 66), Color("4a2d1a"))
	ArtKit.rect(self, Rect2(556, 498, 14, 66), Color("4a2d1a"))
	ArtKit.hero(self, class_id, hero_pos, HS, t, pose(), "chair")
	var top := 424.0
	ArtKit.rrect(self, Rect2(540, top, 560, 24), 6, Color("8a5a36"))
	ArtKit.rect(self, Rect2(548, top, 544, 4), Color("b07a4a"))
	ArtKit.rect(self, Rect2(560, top + 24, 520, 22), Color("5a361f"))
	ArtKit.rect(self, Rect2(580, top + 46, 24, 120), Color("4a2d1a"))
	ArtKit.rect(self, Rect2(1040, top + 46, 24, 120), Color("4a2d1a"))
	ArtKit.poly(self, [Vector2(560, top + 2), Vector2(660, top + 2), Vector2(672, top - 12), Vector2(574, top - 12)], Color("f4e8c8"))
	var hand := ArtKit.hero_hand(hero_pos, HS, t, pose())
	if pose() == "sip":
		_mug(hand + Vector2(10, -14))
	else:
		_pen(hand)
		_mug(Vector2(760, top - 6))
		steam(Vector2(760, top - 22), 5, 52)
	# pão, tigela e velas
	ArtKit.ellipse(self, Vector2(860, top - 4), 38, 10, Color("e6d5b0"))
	ArtKit.ellipse(self, Vector2(860, top - 14), 28, 14, Color("c58a4a"))
	draw_line(Vector2(846, top - 22), Vector2(850, top - 12), Color("9a6a30"), 2, true)
	draw_line(Vector2(868, top - 22), Vector2(872, top - 12), Color("9a6a30"), 2, true)
	ArtKit.rrect(self, Rect2(948, top - 54, 22, 54), 4, Color("f4e8c8"))
	_flame(Vector2(959, top - 62), 1.0, 2)
	glow(Vector2(959, top - 60), 130, Color("ffb860"), 0.5 * flicker(2))
	ArtKit.rrect(self, Rect2(1030, top - 40, 22, 40), 4, Color("e8d8b4"))
	_flame(Vector2(1041, top - 48), 0.8, 5)
	glow(Vector2(1041, top - 46), 100, Color("ffb860"), 0.4 * flicker(5))
	dust(Rect2(300, 150, 700, 320), 24, Color("ffd9a0", 0.7), 0.6)


func _flame(p: Vector2, sc: float, seed_i: int) -> void:
	var f := flicker(seed_i, 1.2)
	var sway := sin(t * 7.0 + seed_i) * 2.0 * sc
	ArtKit.poly(self, [p + Vector2(-6, 0) * sc, p + Vector2(sway, -26 * sc * f), p + Vector2(6, 0) * sc, p + Vector2(0, 5) * sc], Color("ff8a2a"))
	ArtKit.poly(self, [p + Vector2(-3.5, 0) * sc, p + Vector2(sway * 0.6, -16 * sc * f), p + Vector2(3.5, 0) * sc, p + Vector2(0, 3) * sc], Color("ffd860"))


func _fireplace(base: Vector2) -> void:
	# base = centro do chão da lareira
	ArtKit.rect(self, Rect2(base.x - 130, 170, 260, 300), Color("5a4a44"))
	ArtKit.rrect(self, Rect2(base.x - 150, 150, 300, 40), 6, Color("7a645a"))
	ArtKit.rect(self, Rect2(base.x - 90, 280, 180, 190), Color("120c0c"))
	ArtKit.ellipse(self, Vector2(base.x, 280), 90, 40, Color("120c0c"))
	for i in 9:
		var bx := base.x - 112.0 + float(i) * 28.0
		ArtKit.rrect(self, Rect2(bx, 180 + float(i % 2) * 10, 26, 22), 3, Color("7a645a"))
		ArtKit.rrect(self, Rect2(bx, 250 + float(i % 3) * 4, 26, 22), 3, Color("6a5650"))
	# fogo
	glow(Vector2(base.x, 400), 280, Color("ff9a40"), 0.6 * flicker(1, 0.6))
	for k in 5:
		var ph := t * 6.0 + float(k) * 1.7
		var fx := base.x + (float(k) - 2.0) * 22.0
		var fh := 90.0 + sin(ph) * 14.0 + float(3 - absi(k - 2)) * 12.0
		ArtKit.poly(self, [Vector2(fx - 22, 466), Vector2(fx + sin(ph * 0.7) * 10, 466 - fh), Vector2(fx + 22, 466)], Color("e8531e"))
		ArtKit.poly(self, [Vector2(fx - 14, 466), Vector2(fx + sin(ph * 0.9) * 8, 466 - fh * 0.7), Vector2(fx + 14, 466)], Color("ffa22e"))
		ArtKit.poly(self, [Vector2(fx - 7, 466), Vector2(fx + sin(ph) * 5, 466 - fh * 0.42), Vector2(fx + 7, 466)], Color("ffe27a"))
	ArtKit.rrect(self, Rect2(base.x - 70, 456, 140, 18), 8, Color("3a2418"))
	for i in 10:
		var ph := fmod(t * 0.35 + ArtKit.rnd(i) , 1.0)
		draw_circle(Vector2(base.x - 40.0 + ArtKit.rnd(i + 7) * 80.0 + sin(t * 2.0 + float(i)) * 8.0, 420.0 - ph * 260.0), 2.0, Color(1.0, 0.7, 0.3, 1.0 - ph))
	# caldeirão
	draw_line(Vector2(base.x - 100, 190), Vector2(base.x - 100, 330), Color("2a2a2a"), 5)
	draw_line(Vector2(base.x - 100, 330), Vector2(base.x - 20, 330), Color("2a2a2a"), 5)
	ArtKit.ellipse(self, Vector2(base.x - 40, 364), 36, 28, Color("2e2e34"))
	ArtKit.ellipse(self, Vector2(base.x - 40, 342), 34, 8, Color("5a8a4a"))
	steam(Vector2(base.x - 40, 336), 5, 70, 0.3)


func _chandelier(p: Vector2) -> void:
	draw_line(Vector2(p.x, 80), p, Color("1d1410"), 3)
	draw_arc(p + Vector2(0, 26), 62, 0.15, PI - 0.15, 24, Color("2a1d16"), 7.0, true)
	for k in 5:
		var cx := p.x - 56.0 + float(k) * 28.0
		var cy := p.y + 26.0 + sin((float(k) - 2.0) * 0.5) * 4.0 + absf(float(k) - 2.0) * 8.0
		ArtKit.rrect(self, Rect2(cx - 4, cy - 18, 8, 18), 2, Color("f4e8c8"))
		_flame(Vector2(cx, cy - 20), 0.6, k + 10)
		glow(Vector2(cx, cy - 22), 70, Color("ffb860"), 0.3 * flicker(k + 10))


# ================================================================== NATUREZA
func _draw_nature() -> void:
	ArtKit.vgrad(self, Rect2(0, 0, W, 360), Color("79c6ee"), Color("fdf1c4"))
	# sol e raios
	var sun := Vector2(930, 120)
	glow(sun, 260, Color("fff2b0"), 0.7)
	for i in 14:
		var a := TAU * float(i) / 14.0 + t * 0.05
		draw_line(sun + Vector2(cos(a), sin(a)) * 60, sun + Vector2(cos(a), sin(a)) * (140 + 20 * sin(t + float(i))), Color(1, 0.97, 0.7, 0.28), 5, true)
	draw_circle(sun, 52, Color("fff6cc"))
	draw_circle(sun, 42, Color("ffe892"))
	# nuvens
	for i in 6:
		var cx := fmod(float(i) * 260.0 + t * (6.0 + float(i) * 1.5), W + 300.0) - 150.0
		var cy := 60.0 + float(i % 3) * 52.0
		for k in 5:
			ArtKit.ellipse(self, Vector2(cx + (float(k) - 2.0) * 26.0, cy + sin(float(k) * 1.5) * 8.0), 34 - absf(float(k) - 2.0) * 5.0, 20, Color(1, 1, 1, 0.9))
	# aves
	for i in 3:
		var bx := fmod(t * (34.0 + float(i) * 8.0) + float(i) * 300.0, W + 200.0) - 100.0
		var by := 150.0 + float(i) * 34.0 + sin(t * 1.3 + float(i)) * 10.0
		var fl := sin(t * 9.0 + float(i)) * 7.0
		draw_polyline(PackedVector2Array([Vector2(bx - 14, by + fl), Vector2(bx, by), Vector2(bx + 14, by + fl)]), Color("2a3a4a"), 2.4, true)
	# montanhas
	ArtKit.poly(self, [Vector2(0, 330), Vector2(120, 230), Vector2(230, 290), Vector2(400, 190), Vector2(560, 300), Vector2(720, 240), Vector2(900, 320), Vector2(1050, 250), Vector2(1200, 310), Vector2(1200, 360), Vector2(0, 360)], Color("8aa6cf", 0.85))
	ArtKit.poly(self, [Vector2(0, 350), Vector2(160, 290), Vector2(330, 340), Vector2(520, 270), Vector2(760, 345), Vector2(960, 285), Vector2(1200, 350), Vector2(1200, 380), Vector2(0, 380)], Color("6c9a8c"))
	# colinas
	var hill: Array = [Vector2(0, 600)]
	for i in 25:
		hill.append(Vector2(float(i) * 50.0, 372 + sin(float(i) * 0.5) * 18.0 + sin(float(i) * 0.23) * 12.0))
	hill.append(Vector2(1200, 600))
	ArtKit.poly(self, hill, Color("7fbf5a"))
	# lago
	ArtKit.vgrad(self, Rect2(460, 392, 740, 60), Color("6cc3e8"), Color("3f95c4"))
	for i in 18:
		var lx := 480.0 + fmod(float(i) * 61.0 + t * 12.0, 700.0)
		var ly := 400.0 + float(i % 5) * 10.0
		draw_line(Vector2(lx, ly), Vector2(lx + 20 + float(i % 3) * 6, ly), Color(1, 1, 1, 0.35 + 0.2 * sin(t * 2.0 + float(i))), 2.0, true)
	ArtKit.poly(self, [Vector2(440, 454), Vector2(470, 392), Vector2(1200, 392), Vector2(1200, 454)], Color(0, 0, 0, 0))
	# pradaria da frente
	ArtKit.vgrad(self, Rect2(0, 440, W, 160), Color("8ccb5e"), Color("4f9a42"))
	var edge: Array = [Vector2(0, 460)]
	for i in 25:
		edge.append(Vector2(float(i) * 50.0, 440 + sin(float(i) * 0.7 + 1.0) * 10.0))
	edge.append(Vector2(1200, 460))
	ArtKit.poly(self, edge + [Vector2(1200, 600), Vector2(0, 600)], Color("86c45a"))
	# árvore grande
	_big_tree(Vector2(250, 520))
	# manchas de luz que passam pelas folhas
	for i in 9:
		var sx := 330.0 + float(i) * 70.0 + sin(t * 0.7 + float(i)) * 8.0
		ArtKit.ellipse(self, Vector2(sx, 530.0 + float(i % 3) * 26.0), 22, 9, Color(1, 1, 0.75, 0.16))
	# manta, cesto e herói
	var hero_pos := Vector2(520, 520)
	ArtKit.poly(self, [Vector2(440, 520), Vector2(780, 520), Vector2(830, 570), Vector2(400, 570)], Color("c4453d"))
	for k in 8:
		draw_line(Vector2(440 + float(k) * 42.0, 520), Vector2(410 + float(k) * 50.0, 570), Color(1, 1, 1, 0.28), 6.0)
	for k in 3:
		draw_line(Vector2(430 + float(k) * 4, 535.0 + float(k) * 16.0), Vector2(800 + float(k) * 12, 535.0 + float(k) * 16.0), Color(1, 1, 1, 0.2), 5.0)
	ArtKit.hero(self, class_id, hero_pos, HS, t, pose() if pose() != "write" else "read", "ground")
	var hand := ArtKit.hero_hand(hero_pos, HS, t, "read" if pose() != "sip" else "sip", "ground")
	if pose() == "sip":
		_mug(hand + Vector2(10, -12))
	else:
		_book_in_hand(hand + Vector2(-6, 10))
	ArtKit.rrect(self, Rect2(700, 500, 70, 44), 10, Color("b9854a"))
	draw_arc(Vector2(735, 500), 28, PI, TAU, 14, Color("7a5230"), 5.0, true)
	ArtKit.rrect(self, Rect2(780, 520, 34, 30), 8, Color("f4f0e4"))
	steam(Vector2(797, 518), 3, 36, 0.3)
	# grama balançando, flores, borboletas e folhas caindo
	for i in 60:
		var gx := ArtKit.rnd(i) * W
		var gy := 470.0 + ArtKit.rnd(i + 40) * 125.0
		if gx > 400 and gx < 840 and gy > 515 and gy < 575:
			continue
		var sw := sin(t * 2.0 + gx * 0.02) * 4.0
		draw_line(Vector2(gx, gy), Vector2(gx + sw, gy - 14 - ArtKit.rnd(i + 3) * 8.0), Color("3f8a38"), 2.2, true)
		draw_line(Vector2(gx + 4, gy), Vector2(gx + 5 + sw, gy - 10), Color("5aa84a"), 2.0, true)
	for i in 22:
		var fx := ArtKit.rnd(i + 200) * W
		var fy := 480.0 + ArtKit.rnd(i + 230) * 110.0
		if fx > 400 and fx < 840 and fy > 505 and fy < 575:
			continue
		var c: Color = [Color("ffffff"), Color("ffd54a"), Color("ff7a9a"), Color("b58cff")][i % 4]
		draw_circle(Vector2(fx, fy), 4.0, c)
		draw_circle(Vector2(fx, fy), 1.6, Color("ffb020"))
	for i in 2:
		var bx := 560.0 + float(i) * 240.0 + sin(t * 0.6 + float(i) * 2.0) * 120.0
		var by := 420.0 + cos(t * 0.8 + float(i)) * 40.0 + float(i) * 30.0
		var wing := absf(sin(t * 14.0 + float(i))) * 11.0
		var bc := Color("ff9ad0") if i == 0 else Color("7ac8ff")
		ArtKit.ellipse(self, Vector2(bx - wing * 0.6, by), wing + 2.0, 7, bc)
		ArtKit.ellipse(self, Vector2(bx + wing * 0.6, by), wing + 2.0, 7, bc)
		draw_line(Vector2(bx, by - 5), Vector2(bx, by + 6), Color("2a2230"), 2.0, true)
	for i in 7:
		var ph := fmod(t * 0.12 + float(i) * 0.14, 1.0)
		var lx := 200.0 + float(i) * 52.0 + sin(ph * 12.0 + float(i)) * 40.0 + ph * 60.0
		var ly := 330.0 + ph * 240.0
		ArtKit.ellipse(self, Vector2(lx, ly), 7, 3.6, Color(0.55 + ArtKit.rnd(i) * 0.3, 0.75, 0.3, 1.0 - ph * 0.7), ph * 6.0)


func _big_tree(base: Vector2) -> void:
	var sway := sin(t * 0.8) * 3.0
	ArtKit.poly(self, [base + Vector2(-34, 20), base + Vector2(-18, -150), base + Vector2(18, -150), base + Vector2(40, 20), base + Vector2(70, 34), base + Vector2(-70, 34)], Color("6a4630"))
	ArtKit.poly(self, [base + Vector2(-10, -150), base + Vector2(18, -150), base + Vector2(40, 20), base + Vector2(14, 20)], Color("52361f"))
	var cols := [Color("2f7a3a"), Color("3f9a44"), Color("57b254")]
	for layer in 3:
		for i in 9:
			var ang := TAU * float(i) / 9.0 + float(layer)
			var c := base + Vector2(cos(ang) * (110.0 - float(layer) * 30.0) + sway * float(layer + 1) * 0.6, -250.0 + sin(ang) * (70.0 - float(layer) * 16.0))
			draw_circle(c, 74.0 - float(layer) * 10.0, cols[layer])
	draw_circle(base + Vector2(sway, -260), 70, Color("57b254"))
	for i in 10:
		var hx := base.x - 90.0 + ArtKit.rnd(i + 300) * 180.0 + sway
		var hy := base.y - 320.0 + ArtKit.rnd(i + 320) * 120.0
		draw_circle(Vector2(hx, hy), 16.0, Color("86d46a", 0.55))
	ArtKit.ellipse(self, base + Vector2(0, 30), 150, 16, Color(0, 0, 0, 0.18))


# ================================================================== TORRE DE ESTUDO (noite de chuva)
func _draw_study() -> void:
	var lightning := maxf(0.0, 1.0 - fmod(t + 3.0, 11.0) * 6.0) if fmod(t + 3.0, 11.0) < 0.35 else 0.0
	ArtKit.vgrad(self, Rect2(0, 0, W, 470), Color("23264a"), Color("171a33"))
	for i in 8:
		var y := 30.0 + float(i) * 58.0
		draw_line(Vector2(0, y), Vector2(W, y), Color(1, 1, 1, 0.03), 2)
	# janela com noite chuvosa
	var win := Rect2(330, 70, 380, 300)
	ArtKit.vgrad(self, win, Color("0d1230"), Color("2b3668"))
	for i in 40:
		var sx := win.position.x + ArtKit.rnd(i) * win.size.x
		var sy := win.position.y + ArtKit.rnd(i + 70) * win.size.y * 0.7
		draw_circle(Vector2(sx, sy), 1.0 + ArtKit.rnd(i + 5) * 1.2, Color(1, 1, 0.9, 0.35 + 0.5 * absf(sin(t * 1.5 + float(i)))))
	var moon := Vector2(600, 150)
	glow(moon, 130, Color("c8d8ff"), 0.5)
	draw_circle(moon, 34, Color("f0f4ff"))
	draw_circle(moon + Vector2(14, -6), 30, Color("141a3c"))
	for i in 5:
		var cx := fmod(t * (8.0 + float(i) * 3.0) + float(i) * 120.0, 520.0) + 280.0
		ArtKit.ellipse(self, Vector2(cx, 120.0 + float(i) * 34.0), 62, 15, Color("3a4478", 0.7))
	for i in 70:
		var rx := win.position.x + fmod(ArtKit.rnd(i) * win.size.x + t * 70.0, win.size.x)
		var ry := win.position.y + fmod(ArtKit.rnd(i + 90) * win.size.y + t * 420.0, win.size.y)
		draw_line(Vector2(rx, ry), Vector2(rx - 6, ry + 20), Color("9fb8ff", 0.5), 1.6, true)
	for i in 6:
		var dx := win.position.x + 30.0 + ArtKit.rnd(i + 11) * 320.0
		var dy := win.position.y + fmod(ArtKit.rnd(i + 44) * 280.0 + t * 14.0 * (0.5 + ArtKit.rnd(i)), 290.0)
		ArtKit.ellipse(self, Vector2(dx, dy), 3, 5, Color(0.7, 0.85, 1.0, 0.5))
	if lightning > 0.0:
		ArtKit.rect(self, win, Color(0.85, 0.9, 1.0, 0.6 * lightning))
		ArtKit.rect(self, Rect2(0, 0, W, 470), Color(0.7, 0.8, 1.0, 0.1 * lightning))
	ArtKit.rrect(self, Rect2(win.position.x - 12, win.position.y - 12, win.size.x + 24, win.size.y + 24), 6, Color(0, 0, 0, 0), Color("4a3022"), 12)
	draw_rect(Rect2(win.position.x + win.size.x / 2.0 - 5, win.position.y, 10, win.size.y), Color("4a3022"))
	draw_rect(Rect2(win.position.x, win.position.y + 140, win.size.x, 10), Color("4a3022"))
	ArtKit.rect(self, Rect2(win.position.x - 24, win.end.y + 8, win.size.x + 48, 14), Color("5a3a28"))
	# estante, globo e coruja
	ArtKit.rrect(self, Rect2(850, 60, 300, 410), 4, Color("2a1c14"))
	var pal := ["8c2f39", "2f5d62", "c7923e", "3d3a6b", "5b7a3a", "6b3a5a", "27485e"]
	for r in 4:
		var y := 76.0 + float(r) * 98.0
		ArtKit.rect(self, Rect2(860, y, 280, 88), Color("171009"))
		if r == 1:
			ArtKit.circle(self, Vector2(920, y + 52), 28, Color("3a6a9a"))
			draw_arc(Vector2(920, y + 52), 28, 0.4, 2.6, 12, Color("8ab87a"), 6.0, true)
			draw_line(Vector2(920, y + 82), Vector2(920, y + 88), Color("c9a24a"), 4)
			for k in 3:
				ArtKit.rrect(self, Rect2(990 + float(k) * 40.0, y + 40, 28, 48), 8, Color(["6ad0a0", "d06a9a", "6aa0d0"][k], 0.9))
				draw_circle(Vector2(1004 + float(k) * 40.0, y + 52), 3.0, Color(1, 1, 1, 0.4 + 0.3 * sin(t * 2.0 + float(k))))
		else:
			books_row(Rect2(862, y + 2, 276, 86), r * 23, pal)
		ArtKit.rect(self, Rect2(854, y + 88, 292, 10), Color("5a3a28"))
	_owl(Vector2(1090, 74))
	# luz azulada no piso e chão
	plank_floor(470, Color("3a2a3a"), Color("1c141c"))
	ArtKit.poly(self, [Vector2(330, 372), Vector2(710, 372), Vector2(900, 560), Vector2(180, 560)], Color(0.55, 0.65, 1.0, 0.06 + 0.1 * lightning))
	# tapete
	ArtKit.ellipse(self, Vector2(520, 540), 280, 36, Color("5a2a4a", 0.85))
	ArtKit.ellipse(self, Vector2(520, 540), 240, 28, Color("7a3a5a", 0.6))
	# mesa, herói, vela e pergaminhos
	var hero_pos := Vector2(470, 442)
	_chair_back(Vector2(390, 450))
	ArtKit.hero(self, class_id, hero_pos, HS, t, pose(), "chair")
	var top := 418.0
	ArtKit.rrect(self, Rect2(490, top, 560, 22), 6, Color("7a4e30"))
	ArtKit.rect(self, Rect2(498, top, 544, 4), Color("a06c44"))
	ArtKit.rect(self, Rect2(510, top + 22, 520, 60), Color("55341f"))
	ArtKit.rect(self, Rect2(520, top + 82, 22, 90), Color("42281a"))
	ArtKit.rect(self, Rect2(998, top + 82, 22, 90), Color("42281a"))
	ArtKit.poly(self, [Vector2(520, top + 2), Vector2(640, top + 2), Vector2(652, top - 12), Vector2(534, top - 12)], Color("efe3c2"))
	var hand := ArtKit.hero_hand(hero_pos, HS, t, pose())
	if pose() == "sip":
		_mug(hand + Vector2(10, -14))
	else:
		_pen(hand)
		_mug(Vector2(880, top - 6))
		steam(Vector2(880, top - 22), 4, 44)
	# pilha de pergaminhos e tinteiro
	for k in 3:
		ArtKit.rrect(self, Rect2(700 + float(k) * 6.0, top - 18 - float(k) * 8.0, 110, 16), 8, Color("efe3c2"))
	ArtKit.rrect(self, Rect2(950, top - 24, 20, 24), 5, Color("1a1a2a"))
	draw_line(Vector2(960, top - 24), Vector2(982, top - 66), Color("f5f0e6"), 3, true)
	# vela grande
	ArtKit.rrect(self, Rect2(1000, top - 48, 24, 48), 4, Color("f1e5c6"))
	_flame(Vector2(1012, top - 56), 1.0, 7)
	glow(Vector2(1012, top - 54), 220, Color("ffb860"), 0.6 * flicker(7))
	glow(Vector2(1012, top - 54), 90, Color("ffe2a0"), 0.5 * flicker(7))
	dust(Rect2(420, 150, 620, 300), 22, Color("ffd9a0", 0.6), 0.5)
	# plantas penduradas
	for px in [90.0, 210.0]:
		draw_line(Vector2(px, 0), Vector2(px, 150), Color("2a1a10"), 2)
		ArtKit.rrect(self, Rect2(px - 28, 150, 56, 40), 12, Color("a8543a"))
		for k in 7:
			var a := -0.8 + float(k) * 0.28
			var l := 60.0 + ArtKit.rnd(k + int(px)) * 50.0
			ArtKit.smooth(self, [Vector2(px, 160), Vector2(px + cos(a + PI / 2.0) * 20.0 + sin(t + float(k)) * 4.0, 190 + l * 0.5), Vector2(px + cos(a + PI / 2.0) * 34.0, 200 + l)], 6.0, Color("3f8a48"))


func _owl(p: Vector2) -> void:
	draw_line(p + Vector2(-40, 36), p + Vector2(40, 36), Color("6a4630"), 6, true)
	ArtKit.ellipse(self, p + Vector2(0, 6), 24, 32, Color("8a6a4a"))
	ArtKit.ellipse(self, p + Vector2(0, 14), 15, 20, Color("d6c0a0"))
	ArtKit.poly(self, [p + Vector2(-20, -18), p + Vector2(-14, -32), p + Vector2(-6, -22)], Color("6a4630"))
	ArtKit.poly(self, [p + Vector2(20, -18), p + Vector2(14, -32), p + Vector2(6, -22)], Color("6a4630"))
	var blink := fmod(t + 2.0, 5.0) > 4.8
	for sx in [-9.0, 9.0]:
		ArtKit.circle(self, p + Vector2(sx, -8), 9, Color("f4e8a0"))
		if blink:
			draw_line(p + Vector2(sx - 6, -8), p + Vector2(sx + 6, -8), Color("3a2a1a"), 2, true)
		else:
			ArtKit.circle(self, p + Vector2(sx + sin(t * 0.5) * 2.0, -8), 4, Color("2a1a10"))
	ArtKit.poly(self, [p + Vector2(-3, -2), p + Vector2(3, -2), p + Vector2(0, 5)], Color("e0a040"))
