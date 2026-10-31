class_name AppearanceEditor
extends HBoxContainer

## Editor de aparência do herói (criação do personagem e espelho de casa): corpo, tom de pele,
## olhos, estilo e cor do cabelo, barba e sobrancelha, com prévia LPC girando e andando.
## `look` guarda o resultado (formato do LpcW); `changed` avisa a cada troca.

signal changed

var look: Dictionary = {}
var preview: Preview
var _rows: VBoxContainer


## Prévia: o personagem andando e virando para os 4 lados.
class Preview extends Control:
	var look: Dictionary = {}
	var px: float = 2.0
	var draw_frame: bool = true
	var fixed_row: int = -1          # -1 = gira pelos 4 lados; 3 = só andando para a direita
	var _tex: Texture2D
	var _key: String = ""
	var _t: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_look(lk: Dictionary) -> void:
		look = lk
		var key := LpcW.look_key(lk, "npc")
		_key = key
		var cached := LpcW.cached(lk, "npc")
		if cached != null:
			_tex = cached
		else:
			LpcW.request(lk, "npc", func(t: Texture2D) -> void:
				if is_instance_valid(self) and key == _key:
					_tex = t)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var floor_y := size.y - 10.0
		if draw_frame:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.07, 0.1, 0.55))
			draw_rect(Rect2(Vector2.ZERO, size), Color(UI.C_ORANGE, 0.6), false, 1.0)
			draw_rect(Rect2(8, floor_y - 2, size.x - 16, 2), Color(0, 0, 0, 0.25))
		if _tex == null:
			return
		var dirs := [2, 3, 0, 1]
		var row: int = dirs[int(_t / 1.6) % 4] if fixed_row < 0 else fixed_row
		var col := 1 + int(_t * 9.0) % 8
		var src := Rect2(col * 64, row * 64, 64, 64)
		var dst := Rect2(Vector2((size.x - 64 * px) / 2.0, floor_y - 62 * px), Vector2(64, 64) * px)
		draw_texture_rect_region(_tex, dst, src)


func _init() -> void:
	add_theme_constant_override("separation", 8)


func setup(initial: Dictionary) -> void:
	look = LpcW.resolve(initial)
	preview = Preview.new()
	preview.custom_minimum_size = Vector2(110, 150)
	preview.px = 1.7
	add_child(preview)
	_rows = UI.vbox(2)
	add_child(_rows)
	_rebuild()


func _hair_ids() -> Array:
	var out: Array = []
	var parts: Dictionary = LpcW.catalog().get("parts", {})
	for id in parts:
		if parts[id].get("cat", "") == "cabelo":
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool: return str(parts[a]["name"]) < str(parts[b]["name"]))
	return out


func _beard_ids() -> Array:
	var out: Array = [""]
	var parts: Dictionary = LpcW.catalog().get("parts", {})
	for id in parts:
		if parts[id].get("cat", "") == "barba":
			out.append(id)
	return out


func _rebuild() -> void:
	for c in _rows.get_children():
		c.queue_free()
	var eq: Dictionary = look.get("equip", {})
	_row("Corpo", ["muscular", "male", "female"], ["Masculino forte", "Masculino", "Feminino"], str(look.get("body", "muscular")), func(v: String) -> void:
		look["body"] = v
		look["head"] = "human_female" if v == "female" else "human_male"
		look["brows"] = "thin" if v == "female" else "thick")
	_row_pal("Pele", LpcW.SKINS, "body", "skin")
	_row_pal("Olhos", LpcW.EYES, "eye", "eyes")
	var hair := _hair_ids()
	var hair_names: Array = []
	for id in hair:
		hair_names.append(str(LpcW.part(id).get("name", id)))
	_row("Cabelo", hair, hair_names, str(eq.get("cabelo", "cab_liso")), func(v: String) -> void:
		var e: Dictionary = look.get("equip", {})
		e["cabelo"] = v
		look["equip"] = e)
	_row_pal("Cor do cabelo", LpcW.HAIRS, "hair", "hair_pal")
	var beards := _beard_ids()
	var beard_names: Array = []
	for id in beards:
		beard_names.append("Nenhuma" if id == "" else str(LpcW.part(id).get("name", id)))
	_row("Barba", beards, beard_names, str(eq.get("barba", "")), func(v: String) -> void:
		var e: Dictionary = look.get("equip", {})
		if v == "":
			e.erase("barba")
		else:
			e["barba"] = v
		look["equip"] = e)
	_row("Sobrancelha", ["thin", "thick", ""], ["Fina", "Grossa", "Nenhuma"], str(look.get("brows", "thin")), func(v: String) -> void:
		look["brows"] = v)
	var rnd := UI.button("Sortear", func() -> void: _randomize(), 70)
	_rows.add_child(rnd)
	preview.set_look(look)


func _row(title: String, values: Array, names: Array, current: String, on_set: Callable, swatch_mat: String = "") -> void:
	var h := UI.hbox(3)
	_rows.add_child(h)
	var l := UI.label(title, UI.C_DIM)
	l.custom_minimum_size.x = 82
	h.add_child(l)
	var idx := maxi(values.find(current), 0)
	var name_l := UI.label(str(names[idx]), UI.C_TEXT)
	name_l.custom_minimum_size.x = 104
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sw := ColorRect.new()
	sw.custom_minimum_size = Vector2(10, 10)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.color = Color.TRANSPARENT
	if swatch_mat != "":
		sw.color = LpcW.swatch(swatch_mat, str(values[idx]))
	var step := func(d: int) -> void:
		var i := (maxi(values.find(_current_of(title, values)), 0) + d + values.size()) % values.size()
		on_set.call(str(values[i]))
		name_l.text = str(names[i])
		if swatch_mat != "":
			sw.color = LpcW.swatch(swatch_mat, str(values[i]))
		Audio.sfx2("ui_pack5", -10.0)
		preview.set_look(look)
		changed.emit()
	h.add_child(UI.button("<", func() -> void: step.call(-1), 16))
	h.add_child(sw)
	h.add_child(name_l)
	h.add_child(UI.button(">", func() -> void: step.call(1), 16))


func _row_pal(title: String, options: Array, material: String, key: String) -> void:
	var values: Array = []
	var names: Array = []
	for o in options:
		values.append(o[0])
		names.append(o[1])
	_row(title, values, names, str(look.get(key, values[0])), func(v: String) -> void: look[key] = v, material)


## Valor atual de uma linha (para os botões < > continuarem de onde estão).
func _current_of(title: String, values: Array) -> String:
	var eq: Dictionary = look.get("equip", {})
	match title:
		"Corpo":
			return str(look.get("body", "male"))
		"Pele":
			return str(look.get("skin", ""))
		"Olhos":
			return str(look.get("eyes", ""))
		"Cabelo":
			return str(eq.get("cabelo", ""))
		"Cor do cabelo":
			return str(look.get("hair_pal", ""))
		"Barba":
			return str(eq.get("barba", ""))
		"Sobrancelha":
			return str(look.get("brows", ""))
	return str(values[0])


func _randomize() -> void:
	look["skin"] = LpcW.SKINS[randi() % 7][0]
	look["eyes"] = LpcW.EYES[randi() % LpcW.EYES.size()][0]
	look["hair_pal"] = LpcW.HAIRS[randi() % 14][0]
	var e: Dictionary = look.get("equip", {})
	var hair := _hair_ids()
	e["cabelo"] = hair[randi() % hair.size()]
	if look.get("body", "male") == "male" and randf() < 0.35:
		var b := _beard_ids()
		e["barba"] = b[1 + randi() % (b.size() - 1)]
	else:
		e.erase("barba")
	look["equip"] = e
	Audio.sfx("magic_select", -8.0)
	_rebuild()
	changed.emit()
