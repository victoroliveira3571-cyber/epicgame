class_name MgArt
extends RefCounted

## v3.1: arte dos mini-jogos (assets/custom/minigames, packs baixados em 01/11/2026) e a tela de desenho
## que os três jogos compartilham. Créditos no ASSETS.md.

const DIR := "res://assets/custom/minigames/"
static var _cache: Dictionary = {}


static func tex(file: String) -> Texture2D:
	if not _cache.has(file):
		_cache[file] = load(DIR + file) if ResourceLoader.exists(DIR + file) else null
	return _cache[file]


## Recorte (col, row) de uma folha de células quadradas.
static func cell(file: String, col: int, row: int, size: int = 16) -> Texture2D:
	var t := tex(file)
	if t == null:
		return null
	var key := "%s:%d:%d:%d" % [file, col, row, size]
	if not _cache.has(key):
		var a := AtlasTexture.new()
		a.atlas = t
		a.region = Rect2(col * size, row * size, size, size)
		_cache[key] = a
	return _cache[key]


## Quadro i de uma tira horizontal (largura w, altura h).
static func frame(file: String, i: int, w: int, h: int) -> Texture2D:
	var t := tex(file)
	if t == null:
		return null
	var key := "%s:f%d:%d:%d" % [file, i, w, h]
	if not _cache.has(key):
		var a := AtlasTexture.new()
		a.atlas = t
		a.region = Rect2(i * w, 0, w, h)
		_cache[key] = a
	return _cache[key]


## Quadro `i` de uma folha em grade (`cols` colunas, quadros de w x h).
static func sheet(file: String, i: int, cols: int, w: int, h: int) -> Texture2D:
	var t := tex(file)
	if t == null:
		return null
	var key := "%s:s%d:%d:%d:%d" % [file, i, cols, w, h]
	if not _cache.has(key):
		var a := AtlasTexture.new()
		a.atlas = t
		a.region = Rect2((i % cols) * w, (i / cols) * h, w, h)
		_cache[key] = a
	return _cache[key]


static func face(sheet: String) -> Texture2D:
	return Pix.tex("chars/%s_face.png" % sheet)


## Desenha `t` com o canto superior esquerdo em `pos`, ampliado `k` vezes (inteiro, sem borrar).
static func blit(c: CanvasItem, t: Texture2D, pos: Vector2, k: float, mod: Color = Color.WHITE) -> void:
	if t != null:
		c.draw_texture_rect(t, Rect2(pos, t.get_size() * k), false, mod)


## Tela dos mini-jogos: desenha por `painter(canvas)` e avisa cliques nas áreas de `hits`.
class Canvas extends Control:
	signal clicked(id: String)
	var painter: Callable
	var hits: Array = []          # [{rect: Rect2, id: String}]
	var hover: String = ""

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_STOP

	func hit_area(r: Rect2, id: String) -> void:
		hits.append({"rect": r, "id": id})

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseMotion:
			var h := _at(ev.position)
			if h != hover:
				hover = h
				queue_redraw()
		elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var id := _at(ev.position)
			if id != "":
				clicked.emit(id)

	func _at(p: Vector2) -> String:
		for i in range(hits.size() - 1, -1, -1):
			if (hits[i]["rect"] as Rect2).has_point(p):
				return str(hits[i]["id"])
		return ""

	func _draw() -> void:
		hits.clear()
		if painter.is_valid():
			painter.call(self)

	func text(s: String, pos: Vector2, col: Color = UI.C_TEXT, size: int = 12, outline: bool = true) -> void:
		var f := Pix.font(1)
		if outline:
			draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0.1, 0.06, 0.04))
		draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

	func bar(r: Rect2, ratio: float, col: Color) -> void:
		draw_rect(r, Color("1d1a18"))
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(ratio, 0.0, 1.0), r.size.y)), col)
		draw_rect(r, UI.C_LINE, false, 1.0)
