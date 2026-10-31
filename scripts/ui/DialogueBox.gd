class_name DialogueBox
extends Control

## Caixa de diálogo da história (640x360). Três estilos:
##  fala (say/tip/mem/boss): balão claro com rabicho apontando para o retrato LPC animado
##    (expressão, piscar, balanço ao falar) e plaquinha com o nome. O herói fala do lado direito.
##  narração (narr): faixa escura de tinta com bordas douradas, texto claro centralizado, sem retrato.
##  pensamento (think): nuvem lilás com bolinhas até o retrato do herói.
## Texto longo é dividido em páginas que cabem no balão (nunca transborda). Falas aceitam
## expressão: ["mae@sad", "..."] ou ["tip:marta@happy", "..."]; sem ela, a expressão vem do texto.
## Enquanto a conversa corre, o NPC que fala vira para quem ouve, gesticula, pula, balança e
## mostra emotes (ver _direct). [E], Espaço, Enter ou clique avançam.

signal finished

const FONT_PX := 12
const LINE_H := 15
const CHARS_PER_SEC := 55.0
const TEXT_COLOR := Color("2a1d2e")
const SAY_LINES := 4
const NARR_LINES := 3
# fala: retrato à esquerda (ou à direita para o herói)
const PORTRAIT := Vector2(82, 82)
const BALLOON_Y := 266.0
const BALLOON_H := 84.0
const EMOTE := {"excl": 22, "quest": 25, "heart": 27, "broken": 26, "dots": 20, "angry": 29, "happy": 8, "sad": 16, "note": 24}

var lines: Array = []
var index: int = -1
var typing: bool = false
var shown: float = 0.0
var choosing: bool = false
var pages: Array = []
var page: int = 0

var _kind: String = "say"
var _who: String = ""
var _right: bool = false
var _veil: ColorRect
var _balloon: Panel
var _tail: Control
var _frame: Panel
var _portrait: LpcPortrait
var _tab: Panel
var _tab_label: Label
var _narr: Panel
var _ornament: Control
var _text: Label
var _more: Label
var _page_label: Label
var _choices: VBoxContainer
var _blink: float = 0.0
var _last_tick: int = -1
var _last_speaker: Node2D = null


class Tail extends Control:
	var fill: Color = Color("fbf3e2")
	var line: Color = Color("2a1d2e")
	var right: bool = false
	var thought: bool = false

	func _draw() -> void:
		if thought:
			# bolinhas da nuvem de pensamento
			var pts := [Vector2(14, 22), Vector2(7, 30), Vector2(2, 36)]
			var rs := [5.0, 3.5, 2.2]
			for i in 3:
				var p: Vector2 = pts[i]
				if right:
					p.x = size.x - p.x
				draw_circle(p, rs[i] + 1.0, line)
				draw_circle(p, rs[i], fill)
			return
		var tip := Vector2(0, 18)
		var a := Vector2(16, 8)
		var b := Vector2(16, 26)
		if right:
			tip.x = size.x
			a.x = size.x - 16
			b.x = size.x - 16
		draw_colored_polygon(PackedVector2Array([tip, a, b]), line)
		var k := 1.0 if not right else -1.0
		draw_colored_polygon(PackedVector2Array([tip + Vector2(3 * k, 0), a + Vector2(0, 2), b + Vector2(0, -2)]), fill)


class Ornament extends Control:
	func _draw() -> void:
		var c := Color("c9a45c")
		var mid := size.x / 2.0
		for dx in [-1.0, 1.0]:
			draw_line(Vector2(mid + dx * 10, 3), Vector2(mid + dx * 70, 3), Color(c, 0.6), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(mid, 0), Vector2(mid + 4, 3), Vector2(mid, 6), Vector2(mid - 4, 3)]), c)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_veil = ColorRect.new()
	_veil.color = Color(0, 0, 0, 0.0)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	create_tween().tween_property(_veil, "color:a", 0.22, 0.25)
	# --- narração
	_narr = Panel.new()
	_narr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ns := UI.flat(Color(0.075, 0.07, 0.13, 0.93), Color("c9a45c"), 1)
	ns.set_corner_radius_all(3)
	ns.shadow_color = Color(0, 0, 0, 0.4)
	ns.shadow_size = 6
	_narr.add_theme_stylebox_override("panel", ns)
	add_child(_narr)
	_ornament = Ornament.new()
	_ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ornament)
	# --- fala
	_balloon = Panel.new()
	_balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_balloon)
	_tail = Tail.new()
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tail.size = Vector2(20, 40)
	add_child(_tail)
	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = PORTRAIT
	add_child(_frame)
	_portrait = LpcPortrait.new()
	_portrait.crop = Rect2(14, 4, 36, 36)
	_portrait.px_scale = 2.0
	_portrait.size = Vector2(72, 72)
	_portrait.clip_contents = true
	add_child(_portrait)
	_tab = Panel.new()
	_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tab)
	_tab_label = UI.label("", Color("fff1c9"))
	_tab_label.position = Vector2(7, 1)
	_tab.add_child(_tab_label)
	_text = UI.label("", TEXT_COLOR)
	_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_constant_override("line_spacing", LINE_H - int(Pix.font(1).get_height(FONT_PX)))
	add_child(_text)
	_more = UI.label("E  >", Color("8f5545"))
	add_child(_more)
	_page_label = UI.label("", Color("8f5545"))
	add_child(_page_label)
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
			if _kind != "narr":
				Audio.sfx("talk", -18.0, 0.25)
		if _text.visible_characters >= _text.get_total_character_count():
			_finish_typing()
	_more.visible = not typing and not choosing and int(_blink * 2.5) % 2 == 0


func _finish_typing() -> void:
	typing = false
	_text.visible_characters = -1
	_portrait.talking = false


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
		_finish_typing()
	elif page + 1 < pages.size():
		page += 1
		_show_page()
	else:
		_next()


func _next() -> void:
	index += 1
	if index >= lines.size():
		_release_actors()
		finished.emit()
		return
	var entry: Variant = lines[index]
	if entry is Dictionary and (entry as Dictionary).has("choice"):
		_show_choice(entry)
		return
	var who: String = String(entry[0])
	var text: String = Story.fmt(String(entry[1]))
	var kind := "say"
	var expr := ""
	if who.contains("@"):
		expr = who.get_slice("@", 1)
		who = who.get_slice("@", 0)
	if who.contains(":"):
		kind = who.get_slice(":", 0)
		who = who.get_slice(":", 1)
	if who == "narr":
		kind = "narr"
	if expr == "":
		expr = auto_expr(text, kind)
	_show_line(kind, who, text, expr)


## Expressão pelo texto quando a fala não traz uma.
static func auto_expr(text: String, kind: String) -> String:
	var t := text.to_lower()
	if kind == "boss":
		return "anger"
	if kind == "mem":
		return "sad" if _has_any(t, ["chuva", "saudade", "sumiu", "perd"]) else "neutral"
	if _has_any(t, ["morr", "triste", "saudade", "sinto muito", "perdi", "sumiu", "desapareceu", "não volt", "chorar", "sozinh"]):
		return "sad"
	if _has_any(t, ["o quê", "como assim", "?!", "!?", "não acredito", "impossível"]):
		return "shock"
	if t.contains("!") and _has_any(t, ["pare", "chega", "nunca", "saia", "idiota", "covarde", "não!"]):
		return "anger"
	if _has_any(t, ["obrigad", "ótimo", "parabéns", "haha", "que bom", "adoro", "bem-vind", "pronto.", "conseguiu", "boa!"]):
		return "happy"
	if t.begins_with("...") or t.ends_with("..."):
		return "shame"
	return "neutral"


static func _has_any(t: String, words: Array) -> bool:
	for w in words:
		if t.contains(w):
			return true
	return false


# ================================================================== Fala / narração
func _show_line(kind: String, who: String, text: String, expr: String) -> void:
	choosing = false
	_kind = kind
	_who = who
	var narr := kind == "narr"
	var thought := kind == "think"
	_right = who == "heroi" or thought
	_narr.visible = narr
	_ornament.visible = narr
	for n in [_balloon, _tail, _frame, _portrait, _tab]:
		n.visible = not narr
	if narr:
		_layout_narration(text)
		if index == 0 or (lines[index - 1] is Array and String(lines[index - 1][0]) != "narr"):
			Audio.sfx2("gota", -14.0, 0.1)
	else:
		_layout_speech(kind, who, text, expr)
		_direct(who, kind, expr, text)
	page = 0
	_show_page()


func _layout_narration(text: String) -> void:
	var w := 470.0
	pages = _paginate(text, w - 28.0, NARR_LINES)
	var h := 20.0 + LINE_H * mini(NARR_LINES, _max_lines(pages))
	var y := 352.0 - h
	_narr.position = Vector2(320 - w / 2.0, y)
	_narr.size = Vector2(w, h)
	_ornament.position = Vector2(320 - 80, y - 3)
	_ornament.size = Vector2(160, 7)
	_text.position = Vector2(320 - w / 2.0 + 14, y + 10)
	_text.size = Vector2(w - 28, h - 14)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.add_theme_color_override("font_color", Color("efe4c8"))
	_more.position = Vector2(320 + w / 2.0 - 30, y + h - 15)
	_more.add_theme_color_override("font_color", Color("c9a45c"))
	_page_label.position = Vector2(320 - w / 2.0 + 8, y + h - 15)
	_page_label.add_theme_color_override("font_color", Color("c9a45c"))
	_narr.modulate.a = 0.0
	create_tween().tween_property(_narr, "modulate:a", 1.0, 0.18)


func _layout_speech(kind: String, who: String, text: String, expr: String) -> void:
	var sp: Dictionary = StoryData.SPEAKERS.get(who, {})
	var name_text := Story.fmt(String(sp.get("name", "")))
	var tab_color := Color("8f5545")
	var fill := Color("fbf3e2")
	var text_col := TEXT_COLOR
	var frame_bg := Color("3b2c3a")
	match kind:
		"tip":
			name_text = "Dica de estudo  -  " + name_text
			tab_color = Color("3f7a52")
			fill = Color("e6f6e2")
			frame_bg = Color("2c4a36")
		"mem":
			name_text = "Lembrança  -  " + name_text
			tab_color = Color("7a6040")
			fill = Color("f4e2bf")
			frame_bg = Color("5a4630")
		"boss":
			tab_color = Color("9a2a2a")
			fill = Color("f8e0dc")
			frame_bg = Color("4a1a1e")
		"think":
			name_text = name_text + " (pensando)"
			tab_color = Color("6a5a9a")
			fill = Color("ece7f8")
			text_col = Color("3a2e5a")
			frame_bg = Color("3a3060")
	# retrato
	var px := 14.0 if not _right else 640.0 - 14.0 - PORTRAIT.x
	var py := BALLOON_Y - 10.0
	_frame.position = Vector2(px, py)
	var fs := UI.flat(frame_bg, Color("e8c88a"), 2)
	fs.set_corner_radius_all(4)
	fs.shadow_color = Color(0, 0, 0, 0.45)
	fs.shadow_size = 4
	_frame.add_theme_stylebox_override("panel", fs)
	_portrait.position = Vector2(px + 5, py + 5)
	var vis := _speaker_visual(who)
	var lk: Dictionary = vis.get("look", {})
	var face: Texture2D = vis.get("face", null)
	var vis_tint: Color = vis.get("tint", Color.WHITE)
	if not lk.is_empty():
		_portrait.set_look(lk)
	elif face != null:
		_portrait.set_fallback(face, vis_tint)
	else:
		_portrait.set_fallback(null)
	_portrait.tint = vis_tint * Color(1.0, 0.86, 0.7) if kind == "mem" else vis_tint
	_portrait.expr = expr
	_portrait.set_expr(expr)
	if kind == "think":
		_portrait.set_expr("closed" if expr == "neutral" else expr)
	var has_face := not lk.is_empty() or face != null
	_frame.visible = has_face
	_portrait.visible = has_face
	# balão
	var bx := px + PORTRAIT.x + 10.0 if not _right else 14.0
	if not has_face:
		bx = 40.0
	var bw := 640.0 - 14.0 - PORTRAIT.x - 10.0 - 14.0 if has_face else 560.0
	_balloon.position = Vector2(bx, BALLOON_Y)
	_balloon.size = Vector2(bw, BALLOON_H)
	var bs := UI.flat(fill, Color("2a1d2e"), 2)
	bs.set_corner_radius_all(14 if kind == "think" else 7)
	bs.shadow_color = Color(0, 0, 0, 0.35)
	bs.shadow_size = 3
	bs.shadow_offset = Vector2(1, 2)
	_balloon.add_theme_stylebox_override("panel", bs)
	var tl := _tail as Tail
	tl.fill = fill
	tl.right = _right
	tl.thought = kind == "think"
	tl.visible = has_face
	tl.position = Vector2(bx - 18.0, BALLOON_Y + 8.0) if not _right else Vector2(bx + bw - 2.0, BALLOON_Y + 8.0)
	tl.queue_redraw()
	# nome
	_tab.visible = name_text != ""
	_tab_label.text = name_text
	var w := Pix.font(1).get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX).x + 14
	_tab.size = Vector2(w, 15)
	var ts := UI.flat(tab_color, Color("2a1d2e"), 1)
	ts.set_corner_radius_all(5)
	_tab.add_theme_stylebox_override("panel", ts)
	_tab.position = Vector2(bx + 12.0 if not _right else bx + bw - w - 12.0, BALLOON_Y - 9.0)
	# texto
	var tw := bw - 28.0
	pages = _paginate(text, tw, SAY_LINES)
	_text.position = Vector2(bx + 14.0, BALLOON_Y + 11.0)
	_text.size = Vector2(tw, BALLOON_H - 16.0)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text.add_theme_color_override("font_color", text_col)
	_more.position = Vector2(bx + bw - 34.0, BALLOON_Y + BALLOON_H - 16.0)
	_more.add_theme_color_override("font_color", tab_color)
	_page_label.position = Vector2(bx + bw - 64.0, BALLOON_Y + BALLOON_H - 16.0)
	_page_label.add_theme_color_override("font_color", tab_color)
	if _balloon.scale.x < 1.0 or index == 0:
		_balloon.pivot_offset = Vector2(0 if not _right else bw, BALLOON_H / 2.0)
		_balloon.scale = Vector2(0.96, 0.96)
		create_tween().tween_property(_balloon, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_page() -> void:
	_text.text = String(pages[page]) if page < pages.size() else ""
	_text.visible_characters = 0
	_page_label.text = "%d/%d" % [page + 1, pages.size()] if pages.size() > 1 else ""
	shown = 0.0
	typing = true
	_portrait.talking = _kind != "narr" and _kind != "think"


## Divide o texto em páginas de até `max_lines` linhas que cabem em `width` (quebra por palavra).
func _paginate(text: String, width: float, max_lines: int) -> Array:
	var f := Pix.font(1)
	var all_lines: Array = []
	for para in text.split("\n"):
		var cur := ""
		for w in para.split(" ", false):
			var t: String = w if cur == "" else cur + " " + w
			if cur != "" and f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX).x > width - 2.0:
				all_lines.append(cur)
				cur = w
			else:
				cur = t
		all_lines.append(cur)
	var out: Array = []
	var i := 0
	while i < all_lines.size():
		var n := max_lines
		# evita deixar uma linha sozinha na última página
		if all_lines.size() - i == max_lines + 1 and max_lines > 2:
			n = max_lines - 1
		out.append("\n".join(all_lines.slice(i, i + n)))
		i += n
	return out if not out.is_empty() else [""]


func _max_lines(pg: Array) -> int:
	var m := 1
	for p in pg:
		m = maxi(m, String(p).count("\n") + 1)
	return m


# ================================================================== Retratos
## Retrato = o mesmo visual do personagem no mapa (Looks.speaker_visual é a fonte única).
func _speaker_visual(who: String) -> Dictionary:
	var live := _actor_of(who)
	return Looks.speaker_visual(who, _lpc_of(live) if live != null else null)


# ================================================================== Direção (NPCs vivos)
func _actor_of(who: String) -> Node2D:
	var nodes := get_tree().get_nodes_in_group("speaker_" + who)
	return nodes[0] as Node2D if not nodes.is_empty() else null


## O personagem que fala vira para quem ouve e reage ao que diz; quem ouve vira para ele.
func _direct(who: String, kind: String, expr: String, text: String) -> void:
	var speaker := _actor_of(who)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if speaker == null:
		return
	var listener: Node2D = player if speaker != player else _last_speaker
	if speaker is NPC:
		(speaker as NPC).talking = true
	if listener != null and is_instance_valid(listener):
		_face(speaker, listener.global_position)
		_face(listener, speaker.global_position)
	if speaker != player:
		_last_speaker = speaker
	var actor := _lpc_of(speaker)
	var t := text.to_lower()
	match expr:
		"happy":
			if actor != null:
				actor.hop(2.5)
			if randf() < 0.5:
				_emote(speaker, EMOTE["happy"] if not t.contains("obrigad") else EMOTE["heart"])
		"shock":
			if actor != null:
				actor.hop(4.0)
			_emote(speaker, EMOTE["excl"])
		"anger":
			if actor != null:
				actor.shake(1.0, 0.35)
			_emote(speaker, EMOTE["angry"])
		"sad":
			if actor != null:
				actor.play("idle_down")
			_emote(speaker, EMOTE["sad"] if randf() < 0.5 else EMOTE["dots"])
		"shame":
			_emote(speaker, EMOTE["dots"])
		_:
			if t.ends_with("?"):
				if actor != null:
					actor.nod()
				if randf() < 0.45:
					_emote(speaker, EMOTE["quest"])
			elif actor != null:
				if randf() < 0.55:
					actor.gesture()
				else:
					actor.nod()
	if kind == "tip" and actor != null:
		actor.gesture()


func _lpc_of(n: Node2D) -> LpcActor:
	if n is NPC:
		return (n as NPC).actor
	if n is Player:
		return (n as Player).sprite
	return null


func _face(n: Node2D, target: Vector2) -> void:
	if n is NPC:
		(n as NPC).face(target)
	elif n is Player:
		var p := n as Player
		p.facing = (target - p.global_position).normalized()
		p.sprite.play("idle_" + Pix.dir_name(p.facing))


func _emote(n: Node2D, index_: int) -> void:
	if n is NPC:
		(n as NPC).show_emote(index_)
	elif n is Player:
		var e := Sprite2D.new()
		e.texture = Pix.tex("ui/emote/emote%d.png" % index_)
		e.position = Vector2(0, -34)
		e.z_index = 100
		e.scale = Vector2(0.2, 0.2)
		n.add_child(e)
		var tw := e.create_tween()
		tw.tween_property(e, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(1.4)
		tw.tween_property(e, "modulate:a", 0.0, 0.25)
		tw.tween_callback(e.queue_free)


## Fim da conversa: os NPCs da história voltam a viver sozinhos.
func _release_actors() -> void:
	for g in StoryData.SPEAKERS:
		for np2 in get_tree().get_nodes_in_group("speaker_" + str(g)):
			if np2 is NPC:
				(np2 as NPC).talking = false


# ================================================================== Escolhas
func _show_choice(entry: Dictionary) -> void:
	choosing = true
	typing = false
	_text.visible_characters = -1
	for c in _choices.get_children():
		c.queue_free()
	var opts: Array = entry["choice"]
	var key := String(entry.get("key", ""))
	for i in opts.size():
		var b := UI.button(Story.fmt(String(opts[i])), Callable(), 220)
		b.pressed.connect(func() -> void:
			Audio.sfx2("ui_pack4", -6.0)
			if key != "":
				Story.set_flag(key, i)
			for c in _choices.get_children():
				c.queue_free()
			choosing = false
			_next())
		_choices.add_child(b)
	_choices.position = Vector2(640 - 14 - 230, BALLOON_Y - 16 - 21 * opts.size())
