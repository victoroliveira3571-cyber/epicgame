extends Node

## Personagens LPC do mundo (autoload `LpcW`): catálogo (assets/lpcw/catalog.json, gerado por
## tools/build_lpc_world.py), aparência (look), paletas e montagem das camadas numa só textura
## pela GPU (SubViewport), com cache. O herói, os NPCs, os oponentes da Arena e os retratos dos
## diálogos usam a mesma montagem, então o rosto do diálogo é o mesmo do mundo.
##
## look = {
##   body: "male"|"female", head: id de catalog.heads, skin, eyes, hair_pal (paletas do LPC),
##   brows: "thick"|"thin"|"", expr: expressão do rosto no mundo,
##   equip: {slot: id da peça} (slots do guarda-roupa), colors: {id: paleta de tecido ou hex},
##   extras: [[id, cor], ...] (peças a mais, ex.: avental), gear: {armor/helmet/boots/shield: tier},
##   weapon: "sword"|"dagger"|"staff"|"bow"|"spear"|"", wrinkles: bool, scale: float }

const DIR := "res://assets/lpcw/"
const CELL := 64
const ATLAS := Vector2i(1024, 1792)
const NPC_H := 512              # NPCs só usam andar/parado/gesto/sentar/dano (metade de cima)
const WORLD_SCALE := 0.5        # 1 px do mundo = 2 px do LPC
const DIRS := {"up": 0, "left": 1, "down": 2, "right": 3}
## Expressões do retrato, na ordem da tira de retratos.
const PORTRAIT_EXPR := ["neutral", "happy", "sad", "anger", "shock", "blush", "closed", "shame", "eyeroll", "look_l", "look_r", "closing"]
const PORTRAIT_SRC := Rect2(9 * 64, 2 * 64, 64, 64)    # quadro "parado, de frente"
## Animações: x da coluna 0, y da linha de cima, quadros, linhas (1 = só de frente), célula, fps, repete
const ANIMS := {
	"walk": [0, 0, 9, 4, 64, 11.0, true], "idle": [576, 0, 2, 4, 64, 1.6, true],
	"emote": [704, 0, 3, 4, 64, 6.0, false], "combat": [896, 0, 2, 4, 64, 3.0, true],
	"sit": [0, 256, 3, 4, 64, 0.0, false], "hurt": [192, 256, 6, 1, 64, 12.0, false],
	"spellcast": [576, 256, 7, 4, 64, 16.0, false], "shoot": [0, 512, 13, 4, 64, 28.0, false],
	"slash": [0, 768, 6, 4, 128, 22.0, false], "thrust": [0, 1280, 8, 4, 128, 20.0, false],
}

var _cat: Dictionary = {}
var _shader: Shader
var _cache: Dictionary = {}        # chave -> Texture2D
var _waiting: Dictionary = {}      # chave -> [Callable]
var _queue: Array = []             # [chave, look, modo]
var _busy: bool = false
var _ramps: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if FileAccess.file_exists(DIR + "catalog.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "catalog.json"))
		if typeof(parsed) == TYPE_DICTIONARY:
			_cat = parsed
	_shader = load(DIR + "lpc_ramp.gdshader")
	prewarm_item_icons.call_deferred()


func available() -> bool:
	return not _cat.is_empty() and DisplayServer.get_name() != "headless"


func catalog() -> Dictionary:
	return _cat


func part(id: String) -> Dictionary:
	return _cat.get("parts", {}).get(id, {})


func palettes(material: String) -> Dictionary:
	return _cat.get("palettes", {}).get(material, {})


## Tons de pele, olhos e cabelo oferecidos ao jogador (nomes do LPC -> nome no jogo).
const SKINS := [["light", "Clara"], ["amber", "Âmbar"], ["olive", "Oliva"], ["taupe", "Morena"], ["bronze", "Bronze"],
	["brown", "Marrom"], ["black", "Escura"], ["lavender", "Lavanda"], ["blue", "Azulada"], ["green", "Verde"]]
const EYES := [["brown", "Castanhos"], ["blue", "Azuis"], ["green", "Verdes"], ["gray", "Cinza"], ["yellow", "Âmbar"],
	["orange", "Mel"], ["purple", "Violeta"], ["red", "Vermelhos"]]
const HAIRS := [["black", "Preto"], ["raven", "Azulado"], ["dark_brown", "Castanho escuro"], ["chestnut", "Castanho"],
	["light_brown", "Castanho claro"], ["redhead", "Ruivo"], ["ginger", "Acobreado"], ["carrot", "Cenoura"],
	["blonde", "Loiro"], ["sandy", "Areia"], ["platinum", "Platinado"], ["white", "Branco"], ["gray", "Grisalho"],
	["dark_gray", "Grafite"], ["pink", "Rosa"], ["rose", "Rosé"], ["purple", "Roxo"], ["violet", "Violeta"],
	["blue", "Azul"], ["navy", "Marinho"], ["green", "Verde"]]
const CLOTHS := [["white", "Branco"], ["gray", "Cinza"], ["slate", "Ardósia"], ["charcoal", "Carvão"], ["black", "Preto"],
	["red", "Vermelho"], ["maroon", "Vinho"], ["rose", "Rosé"], ["pink", "Rosa"], ["orange", "Laranja"],
	["yellow", "Amarelo"], ["tan", "Areia"], ["brown", "Marrom"], ["leather", "Couro"], ["walnut", "Nogueira"],
	["forest", "Floresta"], ["green", "Verde"], ["teal", "Petróleo"], ["sky", "Céu"], ["blue", "Azul"],
	["bluegray", "Azul-cinza"], ["navy", "Marinho"], ["lavender", "Lavanda"], ["purple", "Roxo"]]


# ================================================================== Aparência
## Visual inicial. Masculino: corpo forte, sobrancelha grossa. Feminino: cabelo longo, blusa e saia.
func default_look(body: String = "muscular") -> Dictionary:
	if body == "female":
		return {"body": "female", "head": "human_female", "skin": "light", "eyes": "brown", "hair_pal": "dark_brown",
			"brows": "thin", "equip": {"cabelo": "cab_longo", "torso": "blusa_ombro", "pernas": "saia", "pes": "sapatilha"},
			"colors": {"blusa_ombro": "rose", "saia": "navy", "sapatilha": "maroon"}}
	return {"body": body, "head": "human_male", "skin": "light", "eyes": "brown", "hair_pal": "dark_brown", "brows": "thick",
		"equip": {"cabelo": "cab_liso", "torso": "camiseta", "pernas": "calca", "pes": "bota"},
		"colors": {"camiseta": "blue", "calca": "navy", "bota": "leather"}}


func resolve(look: Dictionary) -> Dictionary:
	var out := default_look()
	for k in look:
		out[k] = look[k]
	if not look.has("hair_pal") and look.has("hair_color"):
		out["hair_pal"] = nearest_hair(str(look["hair_color"]))
	if str(out.get("body", "male")) not in ["male", "female", "muscular"]:
		out["body"] = "male"
	if not out.has("head") or not _cat.get("heads", {}).has(str(out["head"])):
		out["head"] = "human_female" if out["body"] == "female" else "human_male"
	return out


## Paleta de cabelo do LPC mais parecida com uma cor hex (visuais antigos guardavam hex).
func nearest_hair(hex: String) -> String:
	var want := Color(hex)
	var best := "dark_brown"
	var best_d := INF
	for name in palettes("hair"):
		var c := Color(str(palettes("hair")[name][3]))
		var d := Vector3(c.r - want.r, c.g - want.g, c.b - want.b).length()
		if d < best_d:
			best_d = d
			best = name
	return best


## Cor de exibição (para amostras na interface) de uma paleta.
func swatch(material: String, name: String) -> Color:
	var p: Array = palettes(material).get(name, [])
	if not p.is_empty():
		return Color(str(p[mini(3, p.size() - 1)] if p.size() > 3 else p[p.size() / 2 + 1 if p.size() > 2 else 0]))
	return Color(name) if name.is_valid_html_color() else Color.WHITE


# ================================================================== Camadas
## [{file, z, ramp(Texture2D)}] da mais funda para a mais à frente.
func layers(look_in: Dictionary, expr_override: String = "") -> Array:
	var look := resolve(look_in)
	var body: String = look["body"]
	# corpo forte: base própria; roupas e cabeças são as masculinas
	var bt: String = "male" if body == "muscular" else body
	var out: Array = []
	var base_ramp := _ramp(look, "")
	for l in _cat.get("bodies", {}).get(body, _cat.get("bodies", {}).get(bt, [])):
		out.append(_lay(l, base_ramp))
	var equip: Dictionary = look.get("equip", {})
	var gear: Dictionary = look.get("gear", {})
	var hidden := {}
	var head_swap := false
	for slot in equip:
		var p := part(str(equip[slot]))
		for h in p.get("hides", []):
			hidden[h] = true
		if p.get("head", false):
			head_swap = true
	if int(gear.get("helmet", -1)) >= 0:
		hidden["cabeca"] = true
		hidden["cabelo"] = true
	if int(gear.get("armor", -1)) >= 0:
		hidden["torso_over"] = true
	var head: Dictionary = _cat.get("heads", {}).get(str(look["head"]), {})
	if not head_swap:
		for l in head.get(bt, []):
			out.append(_lay(l, base_ramp))
		var expr := expr_override if expr_override != "" else str(look.get("expr", "neutral"))
		var eyes: Dictionary = _cat.get("eyes", {}).get(str(head.get("eyes", "adult")), {})
		if eyes.has("default"):
			out.append(_lay(eyes["default"], base_ramp))
		var faces: Dictionary = _cat.get("faces", {}).get(str(head.get("faces", "male")), {})
		var face: Variant = faces.get(expr, faces.get("neutral"))
		if face != null:
			out.append(_lay(face, base_ramp))
		if look.get("wrinkles", false) and _cat.get("wrinkles") != null:
			out.append(_lay(_cat["wrinkles"], base_ramp))
		var brows := str(look.get("brows", ""))
		if brows != "" and _cat.get("brows", {}).get(brows) != null:
			out.append(_lay(_cat["brows"][brows], base_ramp))
	for slot in equip:
		var id := str(equip[slot])
		var p := part(id)
		if p.is_empty() or (hidden.has(slot) and slot != "fantasia"):
			continue
		var r := _ramp(look, _item_color(look, id, p))
		for l in p.get("layers", {}).get(bt, []):
			out.append(_lay(l, r))
	for ex in look.get("extras", []):
		var id2 := str(ex[0])
		var p2 := part(id2)
		var r2 := _ramp(look, str(ex[1]) if ex.size() > 1 else "")
		for l in p2.get("layers", {}).get(bt, []):
			out.append(_lay(l, r2))
	for slot in ["boots", "armor", "helmet", "shield"]:
		var t := int(gear.get(slot, -1))
		var tiers: Array = _cat.get("equip", {}).get(slot, [])
		if t < 0 or tiers.is_empty():
			continue
		var e: Dictionary = tiers[clampi(t, 0, tiers.size() - 1)]
		var col := str(e.get("palette", ""))
		var r3 := _ramp(look, col, str(e.get("material", "")))
		for l in e.get("layers", {}).get(bt, []):
			out.append(_lay(l, r3))
		if slot == "armor" and t >= 3:
			var legs: Array = _cat.get("equip", {}).get("legs_heavy", [])
			if not legs.is_empty():
				for l in legs[0].get("layers", {}).get(bt, []):
					out.append(_lay(l, r3))
	var wid := weapon_visual(str(look.get("weapon", "")))
	if wid != "":
		var wpal := str(look.get("weapon_pal", ""))
		var wr := _ramp(look, wpal, "metal") if wpal != "" else base_ramp
		for l in _cat.get("weapons", {}).get(wid, []):
			out.append(_lay(l, wr))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["z"]) < int(b["z"]))
	return out


## Família da classe ("sword") ou visual direto ("longsword") -> visual do catálogo.
func weapon_visual(w: String) -> String:
	if w == "":
		return ""
	if _cat.get("weapons", {}).has(w):
		return w
	return str(_cat.get("weapon_default", {}).get(w, ""))


## Animação de ataque de cada visual de arma.
func weapon_anim(w: String) -> String:
	var v := weapon_visual(w)
	if v in ["staff", "gnarled", "loop", "s_staff", "diamond", "crystal", "diamond_gold", "spear"]:
		return "thrust"
	if v.begins_with("recurve") or v.begins_with("great") or v.begins_with("bow"):
		return "shoot"
	return "slash"


func _item_color(look: Dictionary, id: String, p: Dictionary) -> String:
	if p.get("cat", "") in ["cabelo", "barba"]:
		return ""
	var c: Variant = look.get("colors", {}).get(id, p.get("color", ""))
	return str(c)


func _lay(l: Dictionary, ramp: Texture2D) -> Dictionary:
	# a cor da peça só vale para a camada que tem cor de peça; o resto usa a paleta-base dela
	var r := ramp
	var rname := str(l.get("ramp", ""))
	if rname.contains(":") and ramp.has_meta("item_default"):
		r = _ramp_with_item(ramp, rname)
	return {"file": str(l["file"]), "z": int(l["z"]), "ramp": r}


## Rampa 6x5: linha 1 pele, 2 olhos, 3 cabelo, 4 cor da peça. `item` = paleta de tecido/metal ou hex.
func _ramp(look: Dictionary, item: String, material: String = "cloth") -> Texture2D:
	var key := "%s|%s|%s|%s|%s" % [look.get("skin", ""), look.get("eyes", ""), look.get("hair_pal", ""), item, material]
	if _ramps.has(key):
		return _ramps[key]
	var img := Image.create(6, 5, false, Image.FORMAT_RGBA8)
	_fill_row(img, 1, palettes("body").get(str(look.get("skin", "light")), []))
	_fill_row(img, 2, palettes("eye").get(str(look.get("eyes", "brown")), []))
	_fill_row(img, 3, palettes("hair").get(str(look.get("hair_pal", "dark_brown")), []))
	var item_pal: Array = []
	if item != "":
		item_pal = palettes(material if material != "" else "cloth").get(item, [])
		if item_pal.is_empty():
			item_pal = palettes("cloth").get(item, palettes("metal").get(item, []))
		if item_pal.is_empty() and item.is_valid_html_color():
			item_pal = _ramp_from_hex(Color(item))
	_fill_row(img, 4, item_pal)
	var tex := ImageTexture.create_from_image(img)
	if item_pal.is_empty():
		tex.set_meta("item_default", true)
		tex.set_meta("look_key", [look.get("skin", ""), look.get("eyes", ""), look.get("hair_pal", "")])
	_ramps[key] = tex
	return tex


## Peça sem cor escolhida: usa a paleta-base que o build detectou (ex.: "metal:steel").
func _ramp_with_item(base: Texture2D, rname: String) -> Texture2D:
	var k: Array = base.get_meta("look_key", ["", "", ""])
	var mat := rname.get_slice(":", 0)
	var name := rname.get_slice(":", 1)
	if name == "gray":
		name = "gray" if palettes(mat).has("gray") else "white"
	return _ramp({"skin": k[0], "eyes": k[1], "hair_pal": k[2]}, name, mat)


func _ramp_from_hex(c: Color) -> Array:
	return [Color("281820").to_html(false), c.darkened(0.55).to_html(false), c.darkened(0.3).to_html(false),
		c.to_html(false), c.lightened(0.28).to_html(false), c.lightened(0.55).to_html(false)]


func _fill_row(img: Image, row: int, pal: Array) -> void:
	for i in 6:
		if i < pal.size():
			img.set_pixel(i, row, Color(str(pal[i])))


# ================================================================== Montagem (GPU)
## Pede a textura montada. modo: "full" (todas as animações), "npc" (metade de cima) ou "portrait"
## (tira de rostos, uma expressão por quadro de 64x64, na ordem de PORTRAIT_EXPR).
func request(look: Dictionary, mode: String, cb: Callable) -> void:
	var key := look_key(look, mode)
	if _cache.has(key):
		cb.call(_cache[key])
		return
	if not available():
		cb.call(null)
		return
	if _waiting.has(key):
		_waiting[key].append(cb)
		return
	_waiting[key] = [cb]
	_queue.append([key, look if mode == "item" else resolve(look), mode])
	if not _busy:
		_run_queue.call_deferred()


func cached(look: Dictionary, mode: String) -> Texture2D:
	return _cache.get(look_key(look, mode))


func look_key(look: Dictionary, mode: String) -> String:
	if mode == "item":
		return "item:%s:%s:%s" % [look["_item"], look["_bt"], item_frame(str(look["_item"]))]
	return mode + ":" + str(resolve(look).hash())


func _run_queue() -> void:
	_busy = true
	while not _queue.is_empty():
		# poucas camadas por quadro: montagens grandes demais no mesmo quadro perdiam camadas
		var batch: Array = []
		var budget := 0
		while not _queue.is_empty() and (batch.is_empty() or budget < 40):
			var job: Array = _queue.pop_front()
			batch.append(job)
			if job[2] == "item":
				budget += item_layers(str(job[1]["_item"]), str(job[1]["_bt"])).size()
			else:
				budget += layers(job[1]).size() * (PORTRAIT_EXPR.size() if job[2] == "portrait" else 1)
		var vps: Array = []
		for job in batch:
			vps.append(_make_viewport(job[1], job[2]))
		# texturas recém-carregadas só ficam prontas na GPU no quadro seguinte: espera e só então desenha
		await get_tree().process_frame
		await get_tree().process_frame
		for vp in vps:
			(vp as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		for i in batch.size():
			var vp: SubViewport = vps[i]
			var img := vp.get_texture().get_image()
			vp.queue_free()
			var tex: Texture2D = null
			if img != null and not img.is_empty():
				if batch[i][2] == "item":
					img = _icon_crop(img)
				tex = ImageTexture.create_from_image(img)
			var key: String = batch[i][0]
			_cache[key] = tex
			for cb in _waiting.get(key, []):
				if (cb as Callable).is_valid():
					(cb as Callable).call(tex)
			_waiting.erase(key)
	_busy = false


func _make_viewport(look: Dictionary, mode: String) -> SubViewport:
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(vp)
	if OS.get_cmdline_user_args().has("--lpc-debug"):
		print("[LpcW] compose ", mode, " layers=", layers(look).size(), " look=", look)
	if mode == "item":
		var frame := item_frame(str(look["_item"]))
		vp.size = Vector2i(frame.size)
		for l in item_layers(str(look["_item"]), str(look["_bt"])):
			var si := _sprite(l)
			si.region_enabled = true
			si.region_rect = frame
			var hi := Node2D.new()
			vp.add_child(hi)
			hi.add_child(si)
	elif mode == "portrait":
		vp.size = Vector2i(CELL * PORTRAIT_EXPR.size(), CELL)
		for i in PORTRAIT_EXPR.size():
			var holder := Node2D.new()
			holder.position = Vector2(i * CELL, 0)
			vp.add_child(holder)
			for l in layers(look, PORTRAIT_EXPR[i]):
				var s := _sprite(l)
				s.region_enabled = true
				s.region_rect = PORTRAIT_SRC
				var one := Node2D.new()
				holder.add_child(one)
				one.add_child(s)
	else:
		vp.size = Vector2i(ATLAS.x, NPC_H if mode == "npc" else ATLAS.y)
		for l in layers(look):
			var s2 := _sprite(l)
			if mode == "npc":
				s2.region_enabled = true
				s2.region_rect = Rect2(0, 0, ATLAS.x, NPC_H)
			# cada camada num nó próprio: muitas camadas irmãs no mesmo SubViewport sumiam na montagem
			var holder2 := Node2D.new()
			vp.add_child(holder2)
			holder2.add_child(s2)
	return vp


func _sprite(l: Dictionary) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.texture = load(DIR + str(l["file"]))
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("ramp", l["ramp"])
	s.material = m
	return s


# ================================================================== Ícones de itens
## O ícone de um equipamento é desenhado com as MESMAS camadas e cores que o herói veste no mapa
## (catálogo "equip"/"weapons" + Looks.WEAPON_VISUALS): o que aparece no inventário é o que aparece
## no corpo. Amuletos não aparecem no corpo e seguem com o ícone antigo.
signal item_icons_ready

const ICON_SLOTS := ["weapon", "armor", "helmet", "boots", "shield"]
## Quadro usado no ícone (escolhido para cada arma mostrar a peça inteira): armadura/capacete de frente,
## escudo e botas de lado, lâminas no meio do golpe, arcos no disparo, machado/maça andando.
var icon_frames := {"weapon": Rect2(256, 128, 64, 64), "shield": Rect2(0, 64, 64, 64), "boots": Rect2(0, 64, 64, 64)}
const ICON_WEAPON_FRAME := {"sword": Rect2(256, 1024, 128, 128), "dagger": Rect2(256, 1024, 128, 128),
	"bow": Rect2(512, 576, 64, 64), "staff": Rect2(0, 128, 64, 64)}
const ICON_VISUAL_FRAME := {"waraxe": Rect2(256, 128, 64, 64), "mace": Rect2(256, 128, 64, 64),
	"arming": Rect2(0, 64, 64, 64), "saber": Rect2(0, 64, 64, 64)}
const ICON_DEFAULT_FRAME := Rect2(576, 128, 64, 64)


func item_frame(item_id: String) -> Rect2:
	var it: Dictionary = Data.get_item(item_id)
	if str(it.get("slot", "")) == "weapon":
		var vis := str(Looks.WEAPON_VISUALS.get(item_id, [""])[0])
		if ICON_VISUAL_FRAME.has(vis):
			return ICON_VISUAL_FRAME[vis]
		if ICON_WEAPON_FRAME.has(str(it.get("family", ""))):
			return ICON_WEAPON_FRAME[str(it["family"])]
	return icon_frames.get(str(it.get("slot", "")), ICON_DEFAULT_FRAME)


## Camadas do equipamento sozinho (sem corpo), na ordem de profundidade do personagem.
func item_layers(item_id: String, bt: String = "male") -> Array:
	var it: Dictionary = Data.get_item(item_id)
	var slot := str(it.get("slot", ""))
	var base := {"skin": "light", "eyes": "brown", "hair_pal": "dark_brown"}
	var out: Array = []
	if slot == "weapon":
		var v: Array = Looks.WEAPON_VISUALS.get(item_id, [str(it.get("family", "")), ""])
		var wid := weapon_visual(str(v[0]))
		var wr := _ramp(base, str(v[1]), "metal") if str(v[1]) != "" else _ramp(base, "")
		for l in _cat.get("weapons", {}).get(wid, []):
			out.append(_lay(l, wr))
	elif slot in ["armor", "helmet", "boots", "shield"]:
		var tiers: Array = _cat.get("equip", {}).get(slot, [])
		if tiers.is_empty():
			return []
		var t := clampi(int(it.get("tier", 0)), 0, tiers.size() - 1)
		var e: Dictionary = tiers[t]
		var r := _ramp(base, str(e.get("palette", "")), str(e.get("material", "")))
		for l in e.get("layers", {}).get(bt, []):
			out.append(_lay(l, r))
		if slot == "armor" and t >= 3:
			var legs: Array = _cat.get("equip", {}).get("legs_heavy", [])
			if not legs.is_empty():
				for l in legs[0].get("layers", {}).get(bt, []):
					out.append(_lay(l, r))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["z"]) < int(b["z"]))
	return out


func _hero_bt() -> String:
	return "female" if str(resolve(Looks.hero()).get("body", "male")) == "female" else "male"


## Ícone LPC pronto (ou null enquanto monta / para itens sem visual no corpo).
func item_icon(item_id: String) -> Texture2D:
	if Data.slot_of(item_id) not in ICON_SLOTS or not available():
		return null
	var job := {"_item": item_id, "_bt": _hero_bt()}
	var key := look_key(job, "item")
	if _cache.has(key):
		return _cache[key]
	if not _waiting.has(key):
		request(job, "item", func(_t: Texture2D) -> void: _icon_done())
	return null


## Monta os ícones de todo o equipamento de uma vez (chamado ao abrir o jogo).
func prewarm_item_icons() -> void:
	for id in Data.ITEMS:
		item_icon(str(id))


var _icon_signal_queued := false


func _icon_done() -> void:
	if _icon_signal_queued:
		return
	_icon_signal_queued = true
	await get_tree().process_frame
	_icon_signal_queued = false
	item_icons_ready.emit()


## Recorta a área desenhada e centraliza num quadrado (o ícone não estica).
func _icon_crop(img: Image) -> Image:
	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return img
	var side := maxi(used.size.x, used.size.y) + 2
	var out := Image.create(side, side, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, used, Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2))
	return out


# ================================================================== Créditos
func credit_lines() -> Array:
	var c: Dictionary = _cat.get("credits", {})
	return [c.get("authors", []), c.get("licenses", [])]
