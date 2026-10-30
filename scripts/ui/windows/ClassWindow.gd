extends UIWindow

## Escolha da classe, no registro da Guilda (capítulo 1). A arma de madeira inicial depende dela.

var _picked: String = ""


func _init() -> void:
	win_title = "Registro da Guilda: escolha sua classe"
	win_size = Vector2(600, 320)


func build() -> void:
	var intro := UI.label("Você ganha uma arma de madeira da classe (escudeiro e paladino: escudo). Escolha definitiva.", UI.C_DIM)
	add_to_body(intro, Vector2(2, 0))
	var ids := Data.CLASSES.keys()
	for i in ids.size():
		var id: String = ids[i]
		var c: Dictionary = Data.CLASSES[id]
		var col := i % 3
		var row := i / 3
		var card := UI.card(UI.C_PANEL, UI.C_ORANGE if id == _picked else UI.C_LINE)
		card.custom_minimum_size = Vector2(186, 124)
		card.size = card.custom_minimum_size
		add_to_body(card, Vector2(col * 192, 18 + row * 130))
		var v := UI.vbox(2)
		card.add_child(v)
		var head := UI.hbox(6)
		v.add_child(head)
		var spr := UI.icon(Pix.atlas("chars/%s.png" % c["sheet"], Rect2(0, 0, 16, 16)), 32)
		head.add_child(spr)
		var names := UI.vbox(0)
		head.add_child(names)
		names.add_child(UI.label(c["name"], UI.C_ORANGE_L))
		var style := "À distância" if c["ranged"] else "Corpo a corpo"
		names.add_child(UI.label(style, UI.C_DIM))
		v.add_child(UI.wrap_label(c["desc"], UI.C_TEXT, 170))
		var sk: Dictionary = Data.SKILLS[c["skill"]]
		var skl := UI.hbox(3)
		skl.add_child(UI.icon(Pix.skill_icon(sk["icon"]), 14))
		skl.add_child(UI.label(sk["name"], UI.C_XP))
		v.add_child(skl)
		v.add_child(UI.label("Vida %d  Ataque %d  Def %d" % [c["hp"], c["atk"], c["def"]], UI.C_DIM))
		v.add_child(UI.label(c["passive_text"], UI.C_GOOD))
		var btn := UI.button("Escolher", func() -> void: _choose(id), 60)
		v.add_child(btn)


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
