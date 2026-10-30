class_name Pix
extends RefCounted

## Utilitários de arte: carrega texturas com cache, monta SpriteFrames a partir
## das folhas do Ninja Adventure e entrega a fonte pixel do jogo.

const BASE := "res://assets/ninja/"
const DIRS := ["down", "up", "left", "right"]

static var _tex_cache: Dictionary = {}
static var _frames_cache: Dictionary = {}
static var _fonts: Dictionary = {}


static func tex(rel: String) -> Texture2D:
	if _tex_cache.has(rel):
		return _tex_cache[rel]
	var path := BASE + rel
	if not path.ends_with(".png") and not path.ends_with(".ogg") and not path.ends_with(".wav"):
		path += ".png"
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	else:
		push_warning("[Pix] textura não encontrada: " + path)
	_tex_cache[rel] = t
	return t


static func atlas(rel: String, rect: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex(rel)
	a.region = rect
	return a


## Ícone de item (16x16 para armas/itens, 16x16 para ícones de skill).
static func item_icon(item_id: String) -> Texture2D:
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty():
		return null
	var icon: String = it.get("icon", "")
	if icon.begins_with("items/") and icon.count("/") == 1:
		return tex("skill_icons/" + icon)
	return tex(icon)


static func skill_icon(rel: String) -> Texture2D:
	return tex("skill_icons/" + rel)


static func dir_name(v: Vector2) -> String:
	if absf(v.x) > absf(v.y):
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


## Folha 4 colunas (baixo, cima, esquerda, direita) x N linhas de 16x16 (personagens e monstros).
## Gera idle_<dir>, walk_<dir> (4 quadros) e, se a folha tem, attack_<dir>.
static func actor_frames(sheet_rel: String, cell: int = 16) -> SpriteFrames:
	var key := "actor:" + sheet_rel
	if _frames_cache.has(key):
		return _frames_cache[key]
	var t := tex(sheet_rel)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	if t == null:
		_frames_cache[key] = sf
		return sf
	var rows := int(t.get_height() / cell)
	for d in 4:
		var dn: String = DIRS[d]
		sf.add_animation("idle_" + dn)
		sf.set_animation_speed("idle_" + dn, 4.0)
		sf.set_animation_loop("idle_" + dn, true)
		sf.add_frame("idle_" + dn, atlas(sheet_rel, Rect2(d * cell, 0, cell, cell)))
		sf.add_animation("walk_" + dn)
		sf.set_animation_speed("walk_" + dn, 8.0)
		sf.set_animation_loop("walk_" + dn, true)
		for r in mini(4, rows):
			sf.add_frame("walk_" + dn, atlas(sheet_rel, Rect2(d * cell, r * cell, cell, cell)))
		if rows >= 5:
			sf.add_animation("attack_" + dn)
			sf.set_animation_speed("attack_" + dn, 8.0)
			sf.set_animation_loop("attack_" + dn, false)
			sf.add_frame("attack_" + dn, atlas(sheet_rel, Rect2(d * cell, 4 * cell, cell, cell)))
	_frames_cache[key] = sf
	return sf


## Tira horizontal com `count` quadros de largura `fw` (altura = altura da imagem).
static func strip_frames(rel: String, fw: int, count: int, fps: float, loop: bool = true, anim: String = "default") -> SpriteFrames:
	var key := "strip:%s:%d:%d:%s" % [rel, fw, count, anim]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var t := tex(rel)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation(anim)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, loop)
	if t != null:
		var fh := t.get_height()
		for i in count:
			sf.add_frame(anim, atlas(rel, Rect2(i * fw, 0, fw, fh)))
	_frames_cache[key] = sf
	return sf


## Bichinhos: folha de 2 quadros 16x16 (walk) + idle com o primeiro quadro.
static func animal_frames(sheet: String) -> SpriteFrames:
	var key := "animal:" + sheet
	if _frames_cache.has(key):
		return _frames_cache[key]
	var rel := "animals/%s.png" % sheet
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("walk")
	sf.set_animation_speed("walk", 5.0)
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 1.0)
	var t := tex(rel)
	if t != null:
		var count := maxi(1, int(t.get_width() / 16))
		for i in count:
			sf.add_frame("walk", atlas(rel, Rect2(i * 16, 0, 16, t.get_height())))
		sf.add_frame("idle", atlas(rel, Rect2(0, 0, 16, t.get_height())))
	_frames_cache[key] = sf
	return sf


## Chefes: várias tiras (idle/walk/hit) em um único SpriteFrames.
static func boss_frames(boss_id: String) -> SpriteFrames:
	var key := "boss:" + boss_id
	if _frames_cache.has(key):
		return _frames_cache[key]
	var b: Dictionary = Data.BOSSES[boss_id]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in b["anims"]:
		var spec: Array = b["anims"][anim]
		var rel := "bosses/%s_%s.png" % [b["folder"], spec[0]]
		var t := tex(rel)
		sf.add_animation(anim)
		sf.set_animation_speed(anim, float(spec[3]))
		sf.set_animation_loop(anim, anim != "hit")
		if t == null:
			continue
		var fw: int = spec[1]
		var count: int = mini(spec[2], int(t.get_width() / fw))
		for i in count:
			sf.add_frame(anim, atlas(rel, Rect2(i * fw, 0, fw, t.get_height())))
	_frames_cache[key] = sf
	return sf


## Efeito de sprite (FX): tira de quadros quadrados ou com largura dada.
static func fx_frames(rel: String, fw: int, fps: float = 16.0, anim: String = "fx") -> SpriteFrames:
	var t := tex(rel)
	var count := 1
	if t != null and fw > 0:
		count = maxi(1, int(t.get_width() / fw))
	return strip_frames(rel, fw, count, fps, false, anim)


## Fonte pixel própria (tools/gen_font.py). level 1 = 12 px, 2 = 24 px, 3 = 36 px.
static func font(level: int = 2) -> FontFile:
	level = clampi(level, 1, 3)
	if not _fonts.has(level):
		_fonts[level] = load("res://assets/ui/pf%d.fnt" % (12 * level))
	return _fonts[level]


static func font_px(level: int = 2) -> int:
	return 12 * clampi(level, 1, 3)


## Cor da raridade de um item.
static func rarity_color(item_id: String) -> Color:
	var it: Dictionary = Data.get_item(item_id)
	return Data.RARITY_COLORS[int(it.get("rarity", 0))]
