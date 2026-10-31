extends UIWindow

## Casa: móveis dão bônus permanentes. Descansar recupera toda a vida.


func _init() -> void:
	win_title = "Casa"
	win_size = Vector2(540, 310)


func build() -> void:
	add_to_body(UI.label("Ouro: %s" % UI.fmt_int(GameState.gold), UI.C_GOLD), Vector2(0, 0))
	var rest := UI.button("Descansar (vida cheia)", func() -> void:
		GameState.full_heal()
		Audio.sfx("heal")
		HUD.show_toast("Você descansou.", UI.C_GOOD), 0)
	rest.disabled = GameState.hp >= GameState.get_max_hp()
	rest.position = Vector2(350, -2)
	body.add_child(rest)
	var wardrobe := UI.button("Guarda-roupa", func() -> void: HUD.open_window("guarda_roupa"), 80)
	wardrobe.position = Vector2(262, -2)
	body.add_child(wardrobe)
	var col := scroll_column(Vector2(0, 20), Vector2(520, 252))
	for id in Data.FURNITURE_ORDER:
		var f: Dictionary = Data.FURNITURE[id]
		var owned := GameState.owns_furniture(id)
		var price := int(f["price"])
		var icon := Interior.prop_tex(f["icon"])
		col.add_child(list_row(icon, f["name"], UI.C_GOOD if owned else UI.C_TEXT, f["desc"],
			"" if owned else UI.fmt_int(price), UI.C_GOLD if GameState.gold >= price else UI.C_BAD,
			"Comprado" if owned else "Comprar", func() -> void:
				if GameState.buy_furniture(id):
					Audio.sfx2("moedas", -6.0), owned or GameState.gold < price, 520))
