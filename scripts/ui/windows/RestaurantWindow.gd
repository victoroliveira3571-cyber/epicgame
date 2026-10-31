extends UIWindow

## Restaurante: comer na hora (mata a fome e dá buff) ou levar a comida na mochila.


func _init() -> void:
	win_title = "Restaurante"
	win_size = Vector2(540, 310)


func build() -> void:
	add_to_body(UI.label("Fome: %d / 100" % GameState.hunger, UI.C_FOOD), Vector2(0, 0))
	add_to_body(UI.label("Ouro: %s" % UI.fmt_int(GameState.gold), UI.C_GOLD), Vector2(400, 0))
	var bar := UI.Bar.new(Vector2(200, 6), UI.C_FOOD)
	bar.shown_ratio = GameState.hunger / 100.0
	bar.set_ratio(GameState.hunger / 100.0)
	bar.back = Color("2a1c0c")
	add_to_body(bar, Vector2(100, 4))
	var col := scroll_column(Vector2(0, 20), Vector2(520, 252))
	for id in Data.RESTAURANT_MENU:
		var it: Dictionary = Data.get_item(id)
		var req := int(it.get("shop_level", 1))
		var price := int(it["price"])
		var locked := GameState.level < req
		var sub: String = it["desc"] if not locked else "Disponível no nível %d" % req
		var row := list_row(Pix.item_icon(id), it["name"], UI.C_TEXT if not locked else UI.C_DIM, sub,
			"%s" % UI.fmt_int(price), UI.C_GOLD if GameState.gold >= price else UI.C_BAD,
			"Comer", func() -> void: _eat_here(id), locked or GameState.gold < price, 520)
		var h := row.get_child(0) as HBoxContainer
		var take := UI.button("Levar", func() -> void:
			if GameState.buy_item(id, 1):
				Audio.sfx2("moedas", -8.0)
				Audio.sfx2("servir_agua", -10.0)
			else:
				Audio.sfx("ui_error"), 44)
		take.disabled = locked or GameState.gold < price
		h.add_child(take)
		col.add_child(row)


func _eat_here(id: String) -> void:
	var it: Dictionary = Data.get_item(id)
	if GameState.hunger >= 100 and not it.has("buff"):
		HUD.show_toast("Você já está sem fome.", UI.C_DIM)
		Audio.sfx("ui_error")
		return
	if not GameState.spend_gold(int(it["price"])):
		Audio.sfx("ui_error")
		return
	GameState.eat_hunger(int(it.get("hunger", 0)))
	if it.has("buff"):
		GameState.add_buff(it["buff"], float(it.get("buff_time", 300.0)))
	GameState.bump("meals")
	Audio.sfx("powerup", -3.0)
	HUD.show_toast("%s: fome +%d" % [it["name"], int(it.get("hunger", 0))], UI.C_FOOD)
