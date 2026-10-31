extends UIWindow

## Guarda-roupa: compra visuais do herói (LPC) com fichas de estilo (1 por minuto de foco),
## veste/tira, escolhe cores e mostra a prévia andando ou sentado. Abre pela Casa e pelo Pomodoro.

const ROW_H := 30.0

var cat_id: String = "cabelo"
var selected: String = ""
var walking: bool = true
var _scroll: ScrollContainer
var _scroll_v: int = 0


## Prévia do herói: anda (quadros 2..10) ou fica sentado; `crop` mostra só uma faixa do quadro.
class HeroView extends Control:
	var look: Dictionary = {}
	var preview: String = ""
	var walk: bool = true
	var px_scale: float = 2.0
	var crop_y: float = 0.0
	var t: float = 0.0

	func _process(delta: float) -> void:
		if walk:
			t += delta
			queue_redraw()

	func _draw() -> void:
		var frame := Lpc.F_WALK + int(t * 9.0) % Lpc.WALK_COUNT if walk else Lpc.F_CHAIR
		var w := Lpc.FRAME * px_scale
		var top := Vector2(roundf((size.x - w) / 2.0), -crop_y * px_scale)
		Lpc.draw(self, top, px_scale, frame, Lpc.layers(look, false, preview))


func _init() -> void:
	win_title = "Guarda-roupa"
	win_size = Vector2(620, 346)


func build() -> void:
	if Lpc.categories().is_empty():
		add_to_body(UI.label("Catálogo de roupas não encontrado (rode tools/build_lpc.py).", UI.C_BAD))
		return
	# cabeçalho
	add_to_body(UI.label("Fichas de estilo: %d" % GameState.study_credits, UI.C_GOLD), Vector2(0, 0))
	add_to_body(UI.label("Ganhe 1 crédito por minuto de foco no Pomodoro.", UI.C_DIM), Vector2(150, 0))
	# categorias
	var cats := UI.vbox(2)
	add_to_body(cats, Vector2(0, 16))
	for c in Lpc.categories():
		var cid: String = c[0]
		var b := UI.button(c[1], func() -> void:
			cat_id = cid
			selected = ""
			_scroll_v = 0
			rebuild(), 104)
		b.disabled = cid == cat_id
		cats.add_child(b)
	var body_btn := UI.button("Corpo: " + ("feminino" if _look().get("body", "male") == "female" else "masculino"), func() -> void:
		GameState.set_look_value("body", "male" if _look().get("body", "male") == "female" else "female"), 104)
	cats.add_child(UI.spacer(2))
	cats.add_child(body_btn)
	# peças
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(112, 16)
	_scroll.size = Vector2(290, 290)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	var col := UI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(col)
	var ids := Lpc.items_in(cat_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var pa := int(Lpc.item(a)["price"])
		var pb := int(Lpc.item(b)["price"])
		return pa < pb if pa != pb else str(Lpc.item(a)["name"]) < str(Lpc.item(b)["name"]))
	for id in ids:
		col.add_child(_item_row(id))
	_scroll.set_deferred("scroll_vertical", _scroll_v)
	# prévia e cores
	_build_preview()


func _look() -> Dictionary:
	return Lpc.resolve(GameState.look)


func _item_row(id: String) -> Control:
	var it := Lpc.item(id)
	var owned := GameState.owns_look(id)
	var worn: bool = (_look().get("equip", {}) as Dictionary).get(Lpc.slot_of(id), "") == id
	var price := int(it["price"])
	var card := UI.card(UI.C_PANEL2 if id == selected else UI.C_PANEL, UI.C_ORANGE if id == selected else UI.C_LINE)
	card.custom_minimum_size = Vector2(282, ROW_H)
	var h := UI.hbox(6)
	card.add_child(h)
	var icon := HeroView.new()
	icon.custom_minimum_size = Vector2(30, 22)
	icon.clip_contents = true
	icon.walk = false
	icon.px_scale = 1.0
	icon.look = GameState.look
	icon.preview = id
	icon.crop_y = _icon_crop(Lpc.slot_of(id))
	h.add_child(icon)
	var v := UI.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UI.label(str(it["name"]), UI.C_GOOD if worn else UI.C_TEXT))
	var sub := "Vestindo" if worn else ("Seu" if owned else ("Grátis" if price == 0 else "%d fichas" % price))
	v.add_child(UI.label(sub, UI.C_GOOD if worn else (UI.C_DIM if owned else (UI.C_GOLD if GameState.study_credits >= price else UI.C_BAD))))
	var see := UI.button("Ver", func() -> void:
		selected = id
		_remember_scroll()
		rebuild(), 30)
	h.add_child(see)
	var act: Button
	if not owned:
		act = UI.button("Comprar", func() -> void:
			if GameState.buy_look(id):
				Audio.sfx2("moedas", -6.0)
				selected = id
				GameState.toggle_look(id)
				HUD.show_toast("Comprado: %s" % it["name"], UI.C_GOLD), 54)
		act.disabled = GameState.study_credits < price
	elif worn:
		act = UI.button("Tirar", func() -> void:
			selected = id
			GameState.toggle_look(id), 54)
		act.disabled = Lpc.slot_of(id) == "cabelo"
	else:
		act = UI.button("Vestir", func() -> void:
			selected = id
			Audio.sfx("ui_click", -4.0)
			GameState.toggle_look(id), 54)
	h.add_child(act)
	return card


func _icon_crop(slot: String) -> float:
	match slot:
		"pernas", "pes":
			return 34.0
		"torso", "fantasia":
			return 22.0
	return 8.0


func _remember_scroll() -> void:
	if _scroll != null:
		_scroll_v = _scroll.scroll_vertical


func refresh() -> void:
	_remember_scroll()
	rebuild()


func _build_preview() -> void:
	var x0 := 410.0
	var frame := Panel.new()
	frame.position = Vector2(x0, 16)
	frame.size = Vector2(190, 168)
	frame.add_theme_stylebox_override("panel", UI.flat(Color("3a2e2a"), UI.C_ORANGE, 2))
	body.add_child(frame)
	var view := HeroView.new()
	view.position = Vector2(x0 + 2, 18)
	view.size = Vector2(186, 164)
	view.clip_contents = true
	view.walk = walking
	view.px_scale = 2.5
	view.crop_y = 0.0
	view.look = GameState.look
	view.preview = selected
	body.add_child(view)
	var mode := UI.button("Sentado" if walking else "Andando", func() -> void:
		walking = not walking
		_remember_scroll()
		rebuild(), 60)
	add_to_body(mode, Vector2(x0 + 126, 20))
	var y := 190.0
	if selected == "":
		add_to_body(UI.wrap_label("Clique em Ver para provar uma peça. Comprar veste na hora.", UI.C_DIM, 190), Vector2(x0, y))
		return
	var it := Lpc.item(selected)
	add_to_body(UI.label(str(it["name"]), UI.C_ORANGE_L), Vector2(x0, y))
	y += 14
	var hair := str(it.get("cat", "")) in ["cabelo", "barba"]
	if not it.get("tint", false):
		add_to_body(UI.label("Cor fixa.", UI.C_DIM), Vector2(x0, y))
		return
	if not GameState.owns_look(selected):
		add_to_body(UI.wrap_label("Compre para escolher a cor.", UI.C_DIM, 190), Vector2(x0, y))
		return
	add_to_body(UI.label("Cor do cabelo" if hair else "Cor", UI.C_TEXT), Vector2(x0, y))
	y += 14
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	add_to_body(grid, Vector2(x0, y))
	var current := Lpc.item_color(_look(), selected)
	for d in (Lpc.hair_colors() if hair else Lpc.dyes()):
		var hex: String = d[1]
		var sw := Button.new()
		sw.focus_mode = Control.FOCUS_NONE
		sw.custom_minimum_size = Vector2(19, 14)
		sw.tooltip_text = d[0]
		sw.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var border := UI.C_ORANGE_L if hex == current else UI.C_LINE
		for st in ["normal", "hover", "pressed"]:
			sw.add_theme_stylebox_override(st, UI.flat(Color(hex), border if st != "hover" else UI.C_TEXT, 2 if hex == current or st == "hover" else 1))
		sw.pressed.connect(func() -> void:
			Audio.ui_click()
			if hair:
				GameState.set_look_value("hair_color", hex)
			else:
				GameState.set_look_color(selected, hex))
		grid.add_child(sw)
