extends UIWindow

## Escolha da classe (primeira vez que o jogo abre). Não fecha sem escolher.

var _picked: String = ""


func _init() -> void:
	win_title = "Escolha sua classe"
	win_size = Vector2(600, 320)
	close_on_escape = false


func build() -> void:
	close_button.visible = false
	var intro := UI.label("Quem vai explorar a masmorra? A escolha é definitiva.", UI.C_DIM)
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
		GameState.choose_class(id)
		HUD.close_window()
		Game.go_to_town("start"))
