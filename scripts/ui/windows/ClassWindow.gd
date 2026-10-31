extends UIWindow

## Escolha da classe, no registro da Guilda (capítulo 1). A arma de madeira inicial depende dela.

var _picked: String = ""


func _init() -> void:
	win_title = "Registro da Guilda: escolha sua classe"
	win_size = Vector2(600, 340)


## Cartões numa grade com rolagem: a altura de cada um vem do conteúdo, então nenhum botão fica
## escondido atrás do cartão de baixo nem para fora da janela.
func build() -> void:
	var intro := UI.label("Você ganha uma arma de madeira da classe (escudeiro e paladino: escudo). Escolha definitiva.", UI.C_DIM)
	add_to_body(intro, Vector2(2, 0))
	var sc := ScrollContainer.new()
	sc.position = Vector2(0, 16)
	sc.size = Vector2(body.size.x, body.size.y - 16)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	sc.add_child(grid)
	for id in Data.CLASSES.keys():
		grid.add_child(_card(id))


func _card(id: String) -> PanelContainer:
	var c: Dictionary = Data.CLASSES[id]
	var card := UI.card(UI.C_PANEL, UI.C_ORANGE if id == _picked else UI.C_LINE)
	card.custom_minimum_size = Vector2(188, 0)
	var v := UI.vbox(2)
	card.add_child(v)
	var head := UI.hbox(6)
	v.add_child(head)
	# o seu herói segurando a arma de madeira da classe
	var pv := AppearanceEditor.Preview.new()
	pv.custom_minimum_size = Vector2(36, 40)
	pv.px = 0.62
	pv.draw_frame = false
	pv.fixed_row = 2
	var lk := Looks.hero()
	var start: Array = {"sword": ["arming", "ceramic"], "dagger": ["dagger", "ceramic"], "staff": ["gnarled", ""], "bow": ["recurve", ""]}.get(c["weapon"], ["", ""])
	lk["weapon"] = start[0]
	lk["weapon_pal"] = start[1]
	if c["sheet"] in ["KnightGold", "Boy"]:
		lk["gear"] = {"shield": 0}
	pv.set_look(lk)
	head.add_child(pv)
	var names := UI.vbox(0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	names.add_child(UI.label(c["name"], UI.C_ORANGE_L))
	names.add_child(UI.label("À distância" if c["ranged"] else "Corpo a corpo", UI.C_DIM))
	var btn := UI.button("Escolher", func() -> void: _choose(id), 56)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	names.add_child(btn)
	v.add_child(UI.wrap_label(c["desc"], UI.C_TEXT, 172))
	var sk: Dictionary = Data.SKILLS[c["skill"]]
	var skl := UI.hbox(3)
	skl.add_child(UI.icon(Pix.skill_icon(sk["icon"]), 14))
	skl.add_child(UI.label(sk["name"], UI.C_XP))
	v.add_child(skl)
	v.add_child(UI.label("Vida %d  Ataque %d  Def %d" % [c["hp"], c["atk"], c["def"]], UI.C_DIM))
	v.add_child(UI.wrap_label(c["passive_text"], UI.C_GOOD, 172))
	return card


func _choose(id: String) -> void:
	_picked = id
	HUD.confirm("Jogar como %s? Não dá para trocar depois." % Data.CLASSES[id]["name"], func() -> void:
		Audio.sfx("magic_select", -2.0)
		GameState.choose_class(id)
		HUD.close_window()
		var p := get_tree().get_first_node_in_group("player") as Player
		if p != null:
			p.refresh_sheet()
		Story.on_class_chosen())


## Paisagem em pixel art atrás da janela (campo de dia, mar ao entardecer, montanhas à noite).
func _add_landscape() -> void:
	if has_node("Paisagem"):
		return
	var hour := int(Time.get_time_dict_from_system()["hour"])
	var name := "campo_dia" if hour >= 7 and hour < 17 else ("mar_entardecer" if hour >= 17 and hour < 20 else "montanhas_noite")
	var path := "res://assets/custom/paisagem/%s.png" % name
	if not ResourceLoader.exists(path):
		return
	var tr := TextureRect.new()
	tr.name = "Paisagem"
	tr.texture = load(path)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	move_child(tr, 0)
