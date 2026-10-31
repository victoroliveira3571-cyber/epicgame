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
var close_button: Button
var _rebuilding: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.02, 0.04, 0.62)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	panel = UI.window_panel(win_size)
	panel.position = ((UI.SIZE - win_size) / 2.0).round()
	add_child(panel)
	var title := UI.label(win_title, UI.C_ORANGE_L)
	title.position = Vector2(12, 7)
	panel.add_child(title)
	var close := UI.button("X", Callable(), 14)
	close_button = close
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
	LpcW.item_icons_ready.connect(_on_state_changed)   # ícones de equipamento acabaram de ser montados


func _exit_tree() -> void:
	if GameState.stats_changed.is_connected(_on_state_changed):
		GameState.stats_changed.disconnect(_on_state_changed)
	if LpcW.item_icons_ready.is_connected(_on_state_changed):
		LpcW.item_icons_ready.disconnect(_on_state_changed)


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


## Atributos de um equipamento já com o aprimoramento (+N).
static func equip_stats(item_id: String) -> Dictionary:
	var out := {}
	var it: Dictionary = Data.get_item(item_id)
	if it.is_empty():
		return out
	var mult := 1.0 + Data.UPGRADE_STAT_BONUS * float(GameState.upgrade_level(item_id))
	for k in ["atk", "def", "hp", "speed", "crit", "luck"]:
		var v := float(it.get(k, 0.0))
		if v > 0.0:
			out[k] = v * mult
	return out


const COMPARE_STATS := [["atk", "Ataque"], ["def", "Defesa"], ["hp", "Vida"], ["speed", "Velocidade"], ["crit", "Crítico %"], ["luck", "Sorte %"]]


## Painel de comparação: item escolhido x item equipado no mesmo espaço, lado a lado, com a diferença.
static func compare_card(new_id: String, cur_id: String) -> PanelContainer:
	var card := UI.card(Color("231f1c"), UI.C_ORANGE)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := UI.vbox(3)
	card.add_child(v)
	v.add_child(UI.label("Comparar  -  %s" % Data.SLOT_NAMES.get(Data.slot_of(new_id), ""), UI.C_ORANGE_L))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 2)
	v.add_child(grid)
	# cabeçalho: ícone e nome de cada item
	grid.add_child(UI.label("", UI.C_DIM))
	for id in [new_id, cur_id]:
		var col := UI.vbox(1)
		if id != "":
			col.add_child(UI.icon(Pix.item_icon(id), 22))
			var lvl := GameState.upgrade_level(id)
			col.add_child(UI.wrap_label(Data.item_name(id) + (" +%d" % lvl if lvl > 0 else ""), UI.item_color(id), 74))
		else:
			col.add_child(UI.label("(vazio)", UI.C_DIM))
		col.add_child(UI.label("Escolhido" if id == new_id else "Equipado", UI.C_DIM))
		grid.add_child(col)
	grid.add_child(UI.label("Dif.", UI.C_DIM))
	var a := equip_stats(new_id)
	var b := equip_stats(cur_id)
	var total := 0
	for pair in COMPARE_STATS:
		var k: String = pair[0]
		if not a.has(k) and not b.has(k):
			continue
		var va := float(a.get(k, 0.0))
		var vb := float(b.get(k, 0.0))
		var diff := va - vb
		grid.add_child(UI.label(pair[1], UI.C_DIM))
		grid.add_child(UI.label(_fmt_stat(va) if a.has(k) else "-", UI.C_TEXT))
		grid.add_child(UI.label(_fmt_stat(vb) if b.has(k) else "-", UI.C_TEXT))
		var col2 := UI.C_GOOD if diff > 0.04 else UI.C_BAD if diff < -0.04 else UI.C_DIM
		grid.add_child(UI.label(("+" if diff > 0.04 else "") + _fmt_stat(diff) if absf(diff) > 0.04 else "=", col2))
		total += 1 if diff > 0.04 else -1 if diff < -0.04 else 0
	v.add_child(UI.hline(UI.C_LINE))
	if not Data.class_can_use(GameState.player_class, new_id):
		v.add_child(UI.label("Sua classe não pode usar.", UI.C_BAD))
	elif cur_id == "":
		v.add_child(UI.label("Espaço vazio: só ganha.", UI.C_GOOD))
	else:
		v.add_child(UI.label("Melhor no geral" if total > 0 else "Pior no geral" if total < 0 else "Troca equilibrada",
			UI.C_GOOD if total > 0 else UI.C_BAD if total < 0 else UI.C_DIM))
	return card


static func _fmt_stat(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return ("%.1f" % v).replace(".", ",")


## Prova de promoção aberta (também aparece na Guilda): metas, progresso e o botão Promover.
static func trial_box(parent: Control, width: float) -> void:
	var tr := GameState.promotion_trial()
	var tier := GameState.promotion_tier()
	if tr.is_empty():
		if tier >= Data.PROMOTION_LEVELS.size():
			parent.add_child(UI.wrap_label("Todas as promoções concluídas. Lenda!", UI.C_GOLD, width))
		else:
			parent.add_child(UI.wrap_label("Próxima prova no nível %d." % Data.PROMOTION_LEVELS[tier], UI.C_DIM, width))
		return
	var t := int(tr["tier"])
	parent.add_child(UI.label("Prova: %s" % Data.PROMOTION_TITLES[GameState.player_class][t - 1], UI.C_ORANGE_L))
	var p := GameState.trial_progress()
	for pair in [["monsters", "Monstros"], ["focus", "Minutos de foco"], ["bosses", "Chefes"]]:
		var got := int(p[pair[0]][0])
		var goal := int(p[pair[0]][1])
		if goal <= 0:
			continue
		parent.add_child(UI.label("%s: %d / %d" % [pair[1], mini(got, goal), goal], UI.C_GOOD if got >= goal else UI.C_TEXT))
	var b := UI.button("Promover", func() -> void:
		if GameState.promote():
			Audio.jingle("levelup")
			HUD.floor_banner("Promoção!", GameState.class_title()), 80)
	b.disabled = not GameState.can_promote()
	parent.add_child(b)


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
