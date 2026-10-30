class_name UI
extends RefCounted

## Tema e peças de interface compartilhadas. Toda a UI é desenhada em 640x360 (a camada
## do HUD tem escala 2), então a fonte de 12 px e os tiles de 16 px ficam nítidos.

const SIZE := Vector2(640, 360)

const C_BG := Color("1d1a18")
const C_PANEL := Color("2a2521")
const C_PANEL2 := Color("363029")
const C_LINE := Color("131b1b")
const C_ORANGE := Color("e8703a")
const C_ORANGE_L := Color("ffa95a")
const C_TEXT := Color("f4ecda")
const C_DIM := Color("a89f8c")
const C_GOOD := Color("8ee28e")
const C_BAD := Color("ff7a6a")
const C_GOLD := Color("ffd35a")
const C_XP := Color("7cc4ff")
const C_HP := Color("e0463a")
const C_ENERGY := Color("ffe14d")
const C_FOOD := Color("e8a64a")

static var _theme: Theme = null
static var _tex_cache: Dictionary = {}


static func _ui_tex(name: String) -> Texture2D:
	return Pix.tex("ui/theme/%s.png" % name)


static func box_tex(name: String, margin: int, content: Vector4 = Vector4(0, 0, 0, 0), draw_center: bool = true) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _ui_tex(name)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	sb.draw_center = draw_center
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return sb


static func flat(color: Color, border: Color = Color.TRANSPARENT, border_w: int = 0, pad: Vector4 = Vector4(4, 3, 4, 3)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = Pix.font(1)
	t.default_font_size = 12
	# Botão
	var btn_pad := Vector4(7, 3, 7, 4)
	t.set_stylebox("normal", "Button", box_tex("button_normal", 4, btn_pad))
	t.set_stylebox("hover", "Button", box_tex("button_hover", 4, btn_pad))
	t.set_stylebox("pressed", "Button", box_tex("button_pressed", 4, Vector4(7, 4, 7, 3)))
	t.set_stylebox("disabled", "Button", box_tex("button_disabled", 4, btn_pad))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color("2a1410"))
	t.set_color("font_hover_color", "Button", Color("2a1410"))
	t.set_color("font_pressed_color", "Button", Color("f4ecda"))
	t.set_color("font_disabled_color", "Button", Color("b9a98c"))
	t.set_color("font_focus_color", "Button", Color("2a1410"))
	# Rótulos, campo de texto, barra de rolagem
	t.set_color("font_color", "Label", C_TEXT)
	t.set_stylebox("normal", "LineEdit", flat(C_BG, C_ORANGE, 1, Vector4(5, 3, 5, 3)))
	t.set_stylebox("focus", "LineEdit", flat(C_BG, C_ORANGE_L, 1, Vector4(5, 3, 5, 3)))
	t.set_color("font_color", "LineEdit", C_TEXT)
	t.set_color("caret_color", "LineEdit", C_ORANGE_L)
	t.set_color("selection_color", "LineEdit", Color(C_ORANGE, 0.5))
	var grab := flat(C_ORANGE, Color.TRANSPARENT, 0, Vector4(2, 2, 2, 2))
	t.set_stylebox("scroll", "VScrollBar", flat(Color(0, 0, 0, 0.3), Color.TRANSPARENT, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", flat(C_ORANGE_L, Color.TRANSPARENT, 0, Vector4(2, 2, 2, 2)))
	t.set_stylebox("grabber_pressed", "VScrollBar", flat(C_ORANGE_L, Color.TRANSPARENT, 0, Vector4(2, 2, 2, 2)))
	t.set_constant("separation", "VBoxContainer", 3)
	t.set_constant("separation", "HBoxContainer", 4)
	t.set_constant("h_separation", "GridContainer", 3)
	t.set_constant("v_separation", "GridContainer", 3)
	_theme = t
	return t


# ================================================================== Fábricas
static func label(text: String, color: Color = C_TEXT, level: int = 1) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Pix.font(level))
	l.add_theme_font_size_override("font_size", Pix.font_px(level))
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func wrap_label(text: String, color: Color = C_TEXT, width: float = 200.0) -> Label:
	var l := label(text, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	return l


static func button(text: String, callback: Callable = Callable(), min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.custom_minimum_size = Vector2(min_w, 16)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if callback.is_valid():
		b.pressed.connect(func() -> void:
			Audio.sfx("ui_click", -4.0)
			callback.call())
	return b


static func hbox(sep: int = 4) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 3) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func spacer(h: float = 0.0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func hline(color: Color = C_ORANGE) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(color, 0.55)
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func icon(texture: Texture2D, px: float = 16.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = texture
	r.custom_minimum_size = Vector2(px, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Moldura de janela: fundo escuro + borda laranja do pacote. Devolve o painel (conteúdo vai em `margin`).
static func window_panel(size: Vector2) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = size
	p.size = size
	p.add_theme_stylebox_override("panel", flat(C_BG, Color.TRANSPARENT, 0))
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", box_tex("nine_path_panel", 5, Vector4(0, 0, 0, 0), false))
	p.add_child(frame)
	return p


## Caixa interna (cartão) com fundo levemente mais claro.
static func card(color: Color = C_PANEL, border: Color = C_LINE) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", flat(color, border, 1, Vector4(5, 4, 5, 4)))
	return pc


static func fmt_int(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if n < 0 else "") + out


static func fmt_time(seconds: float) -> String:
	var s := maxi(0, int(ceil(seconds)))
	return "%02d:%02d" % [s / 60, s % 60]


## Texto estilizado com a cor da raridade do item.
static func item_color(item_id: String) -> Color:
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty():
		return C_TEXT
	return Data.RARITY_COLORS[int(it.get("rarity", 0))]


## Barra simples (fundo escuro + preenchimento). Atualize `value` (0..1) chamando set_ratio.
class Bar extends Control:
	var ratio: float = 1.0
	var fill: Color = UI.C_HP
	var back: Color = Color("2a1218")
	var shown_ratio: float = 1.0
	var text: String = ""
	var font_color: Color = Color.WHITE

	func _init(size_px: Vector2 = Vector2(80, 8), fill_color: Color = UI.C_HP) -> void:
		custom_minimum_size = size_px
		size = size_px
		fill = fill_color
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_ratio(r: float, txt: String = "") -> void:
		ratio = clampf(r, 0.0, 1.0)
		text = txt
		queue_redraw()

	func _process(delta: float) -> void:
		if not is_equal_approx(shown_ratio, ratio):
			shown_ratio = lerpf(shown_ratio, ratio, minf(1.0, delta * 10.0))
			if absf(shown_ratio - ratio) < 0.002:
				shown_ratio = ratio
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), UI.C_LINE)
		draw_rect(Rect2(1, 1, w - 2, h - 2), back)
		var fw := (w - 2.0) * shown_ratio
		if fw >= 1.0:
			draw_rect(Rect2(1, 1, fw, h - 2), fill)
			draw_rect(Rect2(1, 1, fw, 1), fill.lightened(0.35))
		if text != "":
			var f := Pix.font(1)
			var sz := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			var pos := Vector2((w - sz.x) / 2.0, (h + 7.0) / 2.0 + 1.0 - 1.0)
			draw_string(f, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.8))
			draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, font_color)


## Casa de inventário: ícone + quantidade, borda por raridade, clicável.
class Slot extends Control:
	signal pressed
	signal hovered(on: bool)
	var item_id: String = ""
	var count: int = 0
	var selected: bool = false
	var equipped: bool = false
	var empty_icon: Texture2D = null
	var dim: bool = false
	var cell_px: float = 20.0

	func _init(px: float = 20.0) -> void:
		cell_px = px
		custom_minimum_size = Vector2(px, px)
		size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	func set_item(id: String, n: int = 1) -> void:
		item_id = id
		count = n
		queue_redraw()

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			Audio.sfx("ui_move", -6.0)
			pressed.emit()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			hovered.emit(true)
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			hovered.emit(false)
			queue_redraw()

	func _draw() -> void:
		var tex := Pix.tex("ui/theme/inventory_cell.png")
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false)
		if item_id == "" and empty_icon != null:
			draw_texture_rect(empty_icon, Rect2(Vector2(2, 2), size - Vector2(4, 4)), false, Color(1, 1, 1, 0.25))
		if item_id != "":
			var it: Texture2D = Pix.item_icon(item_id)
			if it != null:
				var isz := minf(size.x - 4.0, 16.0)
				var off := (size - Vector2(isz, isz)) / 2.0
				draw_texture_rect(it, Rect2(off.round(), Vector2(isz, isz)), false, Color(1, 1, 1, 0.45) if dim else Color.WHITE)
			var rc := UI.item_color(item_id)
			draw_rect(Rect2(1, 1, size.x - 2, 1), rc)
			draw_rect(Rect2(1, size.y - 2, size.x - 2, 1), Color(rc, 0.6))
			if count > 1:
				var f := Pix.font(1)
				var s := str(count)
				var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
				draw_string(f, Vector2(size.x - w - 1, size.y - 2) + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK)
				draw_string(f, Vector2(size.x - w - 1, size.y - 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			if equipped:
				draw_rect(Rect2(2, 2, 5, 5), UI.C_ORANGE)
				draw_rect(Rect2(3, 3, 3, 3), UI.C_TEXT)
		if selected:
			draw_rect(Rect2(0, 0, size.x, size.y), UI.C_ORANGE_L, false, 1.0)
			draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), UI.C_TEXT, false, 1.0)
		elif get_global_rect().has_point(get_global_mouse_position()):
			draw_rect(Rect2(0, 0, size.x, size.y), Color(1, 1, 1, 0.25), false, 1.0)
