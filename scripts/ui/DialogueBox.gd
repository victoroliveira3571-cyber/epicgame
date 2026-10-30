class_name DialogueBox
extends Control

## Caixa de diálogo da história (embaixo da tela, 640x360): retrato no quadro, nome na aba,
## texto letra por letra e escolhas. Tipos de fala (StoryData): fala, narração, dica de estudo,
## memória (tom sépia) e chefe (aba vermelha). [E], Espaço, Enter ou clique avançam.

signal finished

const BOX_POS := Vector2(24, 272)
const BOX_SIZE := Vector2(592, 80)
const TEXT_COLOR := Color("2a1d2e")
const CHARS_PER_SEC := 55.0

var lines: Array = []
var index: int = -1
var typing: bool = false
var shown: float = 0.0
var choosing: bool = false

var _box: NinePatchRect
var _tab: Panel
var _tab_label: Label
var _face_frame: TextureRect
var _face: TextureRect
var _text: Label
var _more: Label
var _choices: VBoxContainer
var _blink: float = 0.0
var _last_tick: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.18)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	_box = NinePatchRect.new()
	_box.texture = Pix.tex("ui/dialog/DialogueBoxSimple.png")
	_box.patch_margin_left = 7
	_box.patch_margin_right = 7
	_box.patch_margin_top = 7
	_box.patch_margin_bottom = 7
	_box.position = BOX_POS
	_box.size = BOX_SIZE
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_tab = Panel.new()
	_tab.position = BOX_POS + Vector2(10, -13)
	_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tab)
	_tab_label = UI.label("", Color("fff1c9"))
	_tab_label.position = Vector2(6, 0)
	_tab.add_child(_tab_label)
	_face_frame = TextureRect.new()
	_face_frame.texture = Pix.tex("ui/dialog/FacesetBox.png")
	_face_frame.position = BOX_POS + Vector2(9, 16)
	_face_frame.size = Vector2(48, 48)
	_face_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face_frame)
	_face = TextureRect.new()
	_face.position = _face_frame.position + Vector2(5, 5)
	_face.size = Vector2(38, 38)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face)
	_text = UI.label("", TEXT_COLOR)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	_more = UI.label("E  >", Color("8f5545"))
	_more.position = BOX_POS + BOX_SIZE - Vector2(34, 18)
	add_child(_more)
	_choices = UI.vbox(3)
	_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_choices)


func start(dialog_lines: Array) -> void:
	lines = dialog_lines
	index = -1
	_next()


func _process(delta: float) -> void:
	_blink += delta
	if typing:
		shown += delta * CHARS_PER_SEC
		_text.visible_characters = int(shown)
		if int(shown) / 4 != _last_tick:
			_last_tick = int(shown) / 4
			Audio.sfx("talk", -18.0, 0.25)
		if _text.visible_characters >= _text.get_total_character_count():
			typing = false
			_text.visible_characters = -1
	_more.visible = not typing and not choosing and int(_blink * 2.5) % 2 == 0


func _input(ev: InputEvent) -> void:
	if choosing:
		return
	var go := false
	if ev is InputEventKey and ev.pressed and not ev.echo:
		go = ev.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_J]
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		go = true
	if not go:
		return
	get_viewport().set_input_as_handled()
	if typing:
		typing = false
		_text.visible_characters = -1
	else:
		_next()


func _next() -> void:
	index += 1
	if index >= lines.size():
		finished.emit()
		return
	var entry: Variant = lines[index]
	if entry is Dictionary and (entry as Dictionary).has("choice"):
		_show_choice(entry)
		return
	var who: String = String(entry[0])
	var text: String = Story.fmt(String(entry[1]))
	var kind := "say"
	if who.contains(":"):
		kind = who.get_slice(":", 0)
		who = who.get_slice(":", 1)
	if who == "narr":
		kind = "narr"
	_show_line(kind, who, text)


func _speaker_face(who: String) -> Texture2D:
	var sp: Dictionary = StoryData.SPEAKERS.get(who, {})
	var face := String(sp.get("face", ""))
	if face == "":
		return null
	if face == "hero":
		var sheet := "Villager5"
		if GameState.has_chosen_class():
			sheet = Data.CLASSES[GameState.player_class]["sheet"]
		return Pix.tex("chars/%s_face.png" % sheet)
	return Pix.tex(face)


func _show_line(kind: String, who: String, text: String) -> void:
	choosing = false
	var sp: Dictionary = StoryData.SPEAKERS.get(who, {})
	var name_text := Story.fmt(String(sp.get("name", "")))
	var tab_color := Color("8f5545")
	var box_tint := Color.WHITE
	match kind:
		"tip":
			name_text = "Dica de estudo  -  " + name_text
			tab_color = Color("3f7a52")
			box_tint = Color(0.86, 1.0, 0.88)
		"mem":
			name_text = "Lembrança  -  " + name_text
			tab_color = Color("7a6040")
			box_tint = Color(1.0, 0.9, 0.72)
		"boss":
			tab_color = Color("9a2a2a")
			box_tint = Color(1.0, 0.86, 0.86)
		"narr":
			name_text = ""
	_box.modulate = box_tint
	var face := _speaker_face(who) if kind != "narr" else null
	_face.texture = face
	_face.modulate = sp.get("tint", Color.WHITE)
	if kind == "mem":
		_face.modulate = Color(1.0, 0.85, 0.65)
	_face.visible = face != null
	_face_frame.visible = face != null
	_tab.visible = name_text != ""
	_tab_label.text = name_text
	var w := Pix.font(1).get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12
	_tab.size = Vector2(w, 14)
	_tab.add_theme_stylebox_override("panel", UI.flat(tab_color, Color("2a1d2e"), 1))
	var left := 66.0 if face != null else 14.0
	_text.position = BOX_POS + Vector2(left, 12)
	_text.size = Vector2(BOX_SIZE.x - left - 14, BOX_SIZE.y - 18)
	_text.custom_minimum_size = Vector2(BOX_SIZE.x - left - 14, 0)
	_text.text = text
	_text.add_theme_color_override("font_color", TEXT_COLOR if kind != "narr" else Color("4a3a40"))
	_text.visible_characters = 0
	shown = 0.0
	typing = true


func _show_choice(entry: Dictionary) -> void:
	choosing = true
	typing = false
	_text.visible_characters = -1
	for c in _choices.get_children():
		c.queue_free()
	var opts: Array = entry["choice"]
	var key := String(entry.get("key", ""))
	for i in opts.size():
		var b := UI.button(Story.fmt(String(opts[i])), Callable(), 200)
		b.pressed.connect(func() -> void:
			Audio.sfx("ui_ok", -4.0)
			if key != "":
				Story.set_flag(key, i)
			for c in _choices.get_children():
				c.queue_free()
			choosing = false
			_next())
		_choices.add_child(b)
	_choices.position = Vector2(BOX_POS.x + BOX_SIZE.x - 210, BOX_POS.y - 8 - 20 * opts.size())
