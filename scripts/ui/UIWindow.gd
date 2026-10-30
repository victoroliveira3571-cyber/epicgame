class_name UIWindow
extends Control

## Base das janelas do jogo (inventário, loja, guilda...). Cobre a tela com um véu escuro,
## centraliza um painel com título e botão de fechar. As subclasses sobrescrevem
## `build()` (monta o conteúdo em `body`) e, se preciso, `refresh()`.

var win_id: String = ""
var win_title: String = "Janela"
var win_size: Vector2 = Vector2(520, 300)
var panel: Panel
var body: Control            # área útil abaixo do título
var close_on_escape: bool = true
var _rebuilding: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.02, 0.04, 0.62)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	panel = UI.window_panel(win_size)
	panel.position = ((UI.SIZE - win_size) / 2.0).round()
	add_child(panel)
	var title := UI.label(win_title, UI.C_ORANGE_L)
	title.position = Vector2(12, 7)
	panel.add_child(title)
	var close := UI.button("X", Callable(), 14)
	close.position = Vector2(win_size.x - 24, 5)
	close.pressed.connect(func() -> void:
		Audio.sfx("ui_close", -3.0)
		HUD.close_window())
	panel.add_child(close)
	var line := UI.hline()
	line.position = Vector2(8, 22)
	line.size = Vector2(win_size.x - 16, 1)
	panel.add_child(line)
	body = Control.new()
	body.position = Vector2(10, 27)
	body.size = Vector2(win_size.x - 20, win_size.y - 37)
	panel.add_child(body)
	build()
	GameState.stats_changed.connect(_on_state_changed)


func _exit_tree() -> void:
	if GameState.stats_changed.is_connected(_on_state_changed):
		GameState.stats_changed.disconnect(_on_state_changed)


func _on_state_changed() -> void:
	if _rebuilding:
		return
	refresh()


## Monta o conteúdo. Sobrescreva.
func build() -> void:
	pass


## Atualiza os valores quando o estado do jogo muda. Padrão: reconstrói tudo.
func refresh() -> void:
	rebuild()


func rebuild() -> void:
	_rebuilding = true
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	build()
	_rebuilding = false


func _unhandled_key_input(ev: InputEvent) -> void:
	if not close_on_escape:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		Audio.sfx("ui_close", -3.0)
		HUD.close_window()


# ------------------------------------------------------------------ Utilidades
## Texto de descrição de um item (nome colorido, tipo, atributos e preço).
static func item_text(item_id: String) -> String:
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty():
		return ""
	var lines: Array[String] = []
	var lvl := GameState.upgrade_level(item_id)
	var nm: String = it["name"] + (" +%d" % lvl if lvl > 0 else "")
	lines.append(nm)
	if it["kind"] == "equip":
		lines.append("%s - %s" % [Data.SLOT_NAMES.get(it["slot"], ""), Data.RARITY_NAMES[int(it.get("rarity", 0))]])
	var desc: String = it.get("desc", "")
	if desc != "":
		lines.append(desc)
	return "\n".join(lines)


func add_to_body(node: Control, pos: Vector2 = Vector2.ZERO) -> void:
	node.position = pos
	body.add_child(node)


## Linha de lista: ícone, título/subtítulo, texto à direita e um botão.
func list_row(icon_tex: Texture2D, title: String, title_color: Color, subtitle: String, right_text: String,
		right_color: Color, btn_text: String, callback: Callable, btn_disabled: bool, width: float) -> PanelContainer:
	var card := UI.card(UI.C_PANEL, UI.C_LINE)
	card.custom_minimum_size = Vector2(width, 28)
	var h := UI.hbox(6)
	card.add_child(h)
	var ic := UI.icon(icon_tex, 20)
	h.add_child(ic)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(title, title_color))
	if subtitle != "":
		v.add_child(UI.label(subtitle, UI.C_DIM))
	if right_text != "":
		var r := UI.label(right_text, right_color)
		r.custom_minimum_size.x = 64
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(r)
	if btn_text != "":
		var b := UI.button(btn_text, callback, 54)
		b.disabled = btn_disabled
		h.add_child(b)
	return card


## Área rolável com uma coluna; devolve a coluna para receber as linhas.
func scroll_column(pos: Vector2, area: Vector2) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.position = pos
	sc.size = area
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var col := UI.vbox(3)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(col)
	return col


func tab_bar(names: Array, current: int, on_pick: Callable, pos: Vector2 = Vector2.ZERO, tab_w: float = 70.0) -> void:
	var tabs := UI.hbox(2)
	add_to_body(tabs, pos)
	for i in names.size():
		var b := UI.button(names[i], func() -> void: on_pick.call(i), tab_w)
		b.disabled = i == current
		tabs.add_child(b)
