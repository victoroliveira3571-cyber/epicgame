class_name Lpc
extends RefCounted

## Herói em camadas do pacote LPC (tools/build_lpc.py gera assets/lpc/ e o catalog.json).
## Cada imagem é uma tira de 11 quadros 64x64: 0 = sentado na cadeira, 1 = sentado no chão,
## 2..10 = andando para a direita. Peças de pano e cabelo vêm em cinza e são multiplicadas pela cor.

const DIR := "res://assets/lpc/"
const FRAME := 64
const CREDITS_PER_MINUTE := 1
const F_CHAIR := 0
const F_GROUND := 1
const F_WALK := 2
const WALK_COUNT := 9
const DEFAULT_CLOTH := "f2efe6"

static var _cat: Dictionary = {}
static var _tex: Dictionary = {}


static func available() -> bool:
	return not catalog().is_empty()


static func catalog() -> Dictionary:
	if _cat.is_empty() and FileAccess.file_exists(DIR + "catalog.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "catalog.json"))
		if typeof(parsed) == TYPE_DICTIONARY:
			_cat = parsed
	return _cat


static func item(item_id: String) -> Dictionary:
	return catalog().get("items", {}).get(item_id, {})


## [[id, nome, slot], ...] na ordem da loja.
static func categories() -> Array:
	return catalog().get("categories", [])


static func category_slot(cat_id: String) -> String:
	for c in categories():
		if c[0] == cat_id:
			return c[2]
	return ""


static func slot_of(item_id: String) -> String:
	return category_slot(str(item(item_id).get("cat", "")))


static func items_in(cat_id: String) -> Array:
	var out: Array = []
	var items: Dictionary = catalog().get("items", {})
	for id in items:
		if items[id]["cat"] == cat_id:
			out.append(id)
	return out


static func dyes() -> Array:
	return catalog().get("dyes", [])


static func hair_colors() -> Array:
	return catalog().get("hair_colors", [])


static func anchor(kind: String) -> Vector2:
	var a: Array = catalog().get("anchor", {}).get(kind, [32, 48])
	return Vector2(float(a[0]), float(a[1]))


## Visual inicial: cabelo liso castanho, camiseta, calça e sapato (peças grátis).
static func default_look() -> Dictionary:
	return {
		"body": "male", "hair_color": "6b4430",
		"equip": {"cabelo": "cab_liso", "torso": "camiseta", "pernas": "calca", "pes": "sapato"},
		"colors": {},
	}


## Junta o visual salvo com o padrão (chaves que faltam).
static func resolve(look: Dictionary) -> Dictionary:
	var out := default_look()
	for k in look:
		out[k] = look[k]
	return out


static func item_color(look: Dictionary, item_id: String) -> String:
	var it := item(item_id)
	if it.get("cat", "") in ["cabelo", "barba"]:
		return str(look.get("hair_color", "6b4430"))
	return str(look.get("colors", {}).get(item_id, it.get("color", DEFAULT_CLOTH)))


static func texture(file: String) -> Texture2D:
	if not _tex.has(file):
		var path := DIR + file
		_tex[file] = load(path) if ResourceLoader.exists(path) else null
	return _tex[file]


## Camadas do visual, da mais funda para a mais à frente: [{tex, z, color}].
## `preview` = peça vestida só para a prévia da loja (sem comprar).
## Se o personagem do mundo (LpcW) já está montado, devolve uma camada só com o atlas dele
## (mesma pele, olhos e cabelo do mundo); senão pede a montagem e usa as camadas antigas.
static func layers(look_in: Dictionary, blink: bool = false, preview: String = "") -> Array:
	if LpcW.available():
		var lk: Dictionary = LpcW.resolve(look_in).duplicate(true)
		if preview != "" and not item(preview).is_empty():
			var eq: Dictionary = lk.get("equip", {})
			eq[slot_of(preview)] = preview
			lk["equip"] = eq
		lk.erase("gear")
		lk["weapon"] = ""
		if blink:
			lk["expr"] = "closed"
		var tex := LpcW.cached(lk, "npc")
		if tex != null:
			return [{"tex": tex, "z": 0, "color": Color.WHITE, "atlas": true}]
		LpcW.request(lk, "npc", func(_t: Texture2D) -> void: pass)
	return _old_layers(look_in, blink, preview)


static func _old_layers(look_in: Dictionary, blink: bool = false, preview: String = "") -> Array:
	var look := resolve(look_in)
	var body: String = look.get("body", "male")
	if body != "male" and body != "female":
		body = "male"
	var equip: Dictionary = (look.get("equip", {}) as Dictionary).duplicate()
	if preview != "" and not item(preview).is_empty():
		equip[slot_of(preview)] = preview
	var hidden := {}
	var head_swap := false
	for slot in equip:
		var it := item(str(equip[slot]))
		for h in it.get("hides", []):
			hidden[h] = true
		if it.get("head", false):
			head_swap = true
	var out: Array = []
	var base: Dictionary = catalog().get("base", {})
	for l in base.get(body, []):
		if head_swap and str(l["file"]).begins_with("head_heads"):
			continue
		out.append({"tex": texture(l["file"]), "z": int(l["z"]), "color": Color.WHITE})
	var eyes: Dictionary = base.get("eyes", {})
	if not eyes.is_empty():
		out.append({"tex": texture(eyes["blink"] if blink else eyes["file"]), "z": int(eyes["z"]), "color": Color.WHITE})
	for slot in equip:
		var id := str(equip[slot])
		var it := item(id)
		if it.is_empty() or (hidden.has(slot) and slot != "fantasia"):
			continue
		var col := Color(item_color(look, id))
		for l in it["layers"].get(body, []):
			out.append({"tex": texture(l["file"]), "z": int(l["z"]), "color": col if l["tint"] else Color.WHITE})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["z"] < b["z"])
	return out


## Desenha o herói com o canto superior esquerdo do quadro em `top_left`.
static func draw(ci: CanvasItem, top_left: Vector2, scale: float, frame: int, lays: Array) -> void:
	var dst := Rect2(top_left, Vector2(FRAME, FRAME) * scale)
	var src := Rect2(frame * FRAME, 0, FRAME, FRAME)
	if not lays.is_empty() and lays[0].get("atlas", false):
		# atlas do LpcW: sentado (linha "direita" do grupo sit) e andando para a direita
		if frame == F_CHAIR:
			src = Rect2(2 * FRAME, 448, FRAME, FRAME)
		elif frame == F_GROUND:
			src = Rect2(1 * FRAME, 448, FRAME, FRAME)
		else:
			src = Rect2((frame - F_WALK) * FRAME, 192, FRAME, FRAME)
	for l in lays:
		if l["tex"] != null:
			ci.draw_texture_rect_region(l["tex"], dst, src, l["color"])


## Lista de créditos das peças LPC (para a tela de Créditos e o ASSETS.md).
static func credit_lines() -> Array:
	var authors := {}
	var licenses := {}
	for k in catalog().get("credits", {}):
		var c: Dictionary = catalog()["credits"][k]
		for a in c.get("authors", []):
			authors[a] = true
		for l in c.get("licenses", []):
			licenses[l] = true
	var a_list := authors.keys()
	a_list.sort_custom(func(x: String, y: String) -> bool: return x.to_lower() < y.to_lower())
	var l_list := licenses.keys()
	l_list.sort()
	return [a_list, l_list]
