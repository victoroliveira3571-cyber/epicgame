class_name BuildingFactory
extends RefCounted

## v3.3: monta casas a partir das peças do Kenney Tiny Town (CC0, assets/custom/city/kenney_tiny_town.png).
## O nome do prop define a casa: "k_<parede>_<telhado>_<largura em tiles>", por exemplo "k_pedra_cinza_5"
## (parede de pedra, telhado cinza, 5 tiles de largura) ou "k_tijolo_vermelho_6". Também: "k_cerca_<n>" (cerca),
## "k_cercav_<n>" (cerca em pé, de cima para baixo; v3.7) e "k_placa".

const SHEET := "res://assets/custom/city/kenney_tiny_town.png"
const COLS := 12
const T := 16
static var _cache: Dictionary = {}
static var _sheet: Image = null

## tiles do Tiny Town (índice = linha * 12 + coluna)
const ROOF := {
	"vermelho": {"a": [52, 53, 54], "b": [64, 65, 66], "chimney": 55},
	"cinza": {"a": [48, 49, 50], "b": [60, 61, 62], "chimney": 51},
}
const WALL := {
	"tijolo": {"plain": [72, 73, 75], "window": 84, "door": 86},
	"pedra": {"plain": [76, 77, 79], "window": 88, "door": 90},
}


static func is_factory_name(name: String) -> bool:
	return name.begins_with("k_")


static func texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var img := _build(name)
	var t: Texture2D = ImageTexture.create_from_image(img) if img != null else null
	_cache[name] = t
	return t


static func _tile(i: int) -> Image:
	if _sheet == null:
		_sheet = TileComposer.src_img(SHEET)
	return _sheet.get_region(Rect2i((i % COLS) * T, (i / COLS) * T, T, T))


static func _put(canvas: Image, i: int, tx: int, ty: int) -> void:
	canvas.blit_rect(_tile(i), Rect2i(0, 0, T, T), Vector2i(tx * T, ty * T))


static func _row(canvas: Image, ids: Array, w: int, ty: int) -> void:
	for x in w:
		_put(canvas, int(ids[0] if x == 0 else (ids[2] if x == w - 1 else ids[1])), x, ty)


static func _build(name: String) -> Image:
	var parts := name.split("_")
	if parts[1] == "cerca":
		var n := int(parts[2]) if parts.size() > 2 else 3
		var f := Image.create(n * T, T, false, Image.FORMAT_RGBA8)
		for x in n:
			_put(f, 80 if x == 0 else (82 if x == n - 1 else 81), x, 0)
		return f
	if parts[1] == "cercav":
		var nv := int(parts[2]) if parts.size() > 2 else 3
		var fv := Image.create(T, nv * T, false, Image.FORMAT_RGBA8)
		for y in nv:
			_put(fv, 47 if y == 0 else (71 if y == nv - 1 else 59), 0, y)
		return fv
	if parts[1] == "placa":
		var s := Image.create(T, T, false, Image.FORMAT_RGBA8)
		_put(s, 83, 0, 0)
		return s
	# casa: k_<parede>_<telhado>_<largura>
	var wall: Dictionary = WALL.get(parts[1], WALL["pedra"])
	var roof: Dictionary = ROOF.get(parts[2], ROOF["cinza"])
	var w := clampi(int(parts[3]) if parts.size() > 3 else 5, 3, 9)
	var h := 4
	var img := Image.create(w * T, h * T, false, Image.FORMAT_RGBA8)
	_row(img, roof["a"], w, 0)
	_row(img, roof["b"], w, 1)
	if w >= 5:
		_put(img, int(roof["chimney"]), w - 2, 0)
	_row(img, wall["plain"], w, 2)
	_row(img, wall["plain"], w, 3)
	# fachada: janelas nas pontas, porta no meio
	var door_x := w / 2
	for x in range(1, w - 1):
		if x == door_x:
			_put(img, int(wall["door"]), x, 3)
		elif x == 1 or x == w - 2:
			_put(img, int(wall["window"]), x, 3)
			if w >= 7 and x == 1:
				_put(img, int(wall["window"]), 1, 2)
	return img
