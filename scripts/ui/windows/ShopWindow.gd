extends UIWindow

## Loja de Armas: compra equipamento e poções, vende o que sobra na mochila.

var tab: int = 0
var _scroll_keep: float = 0.0


func _init() -> void:
	win_title = "Loja de Armas"
	win_size = Vector2(540, 310)


func build() -> void:
	tab_bar(["Equipamento", "Poções", "Vender"], tab, func(i: int) -> void:
		tab = i
		rebuild(), Vector2(0, 0), 90)
	add_to_body(UI.label("Ouro: %s" % UI.fmt_int(GameState.gold), UI.C_GOLD), Vector2(400, 3))
	var col := scroll_column(Vector2(0, 22), Vector2(520, 250))
	match tab:
		0:
			_equipment(col)
		1:
			_potions(col)
		2:
			_sell(col)


func _equipment(col: VBoxContainer) -> void:
	var max_tier := Data.max_tier_for_level(GameState.level)
	for tier in range(max_tier + 1):
		for id in Data.shop_equipment(GameState.player_class, tier):
			var it: Dictionary = Data.get_item(id)
			var price := int(it["price"])
			var owned := GameState.count_item(id)
			col.add_child(list_row(Pix.item_icon(id), it["name"], UI.item_color(id),
				"%s - %s" % [Data.SLOT_NAMES.get(it["slot"], ""), it["desc"]],
				"%s" % UI.fmt_int(price), UI.C_GOLD if GameState.gold >= price else UI.C_BAD,
				"Comprar" if owned == 0 else "Mais um (%d)" % owned, func() -> void: _buy(id), GameState.gold < price, 500))
	if max_tier < Data.TIER_UNLOCK_LEVEL.size() - 1:
		col.add_child(UI.label("Próximo tier de equipamentos no nível %d." % Data.TIER_UNLOCK_LEVEL[max_tier + 1], UI.C_DIM))


func _potions(col: VBoxContainer) -> void:
	for id in Data.SHOP_POTIONS:
		var it: Dictionary = Data.get_item(id)
		var req := int(it.get("shop_level", 1))
		var price := int(it["price"])
		var locked := GameState.level < req
		col.add_child(list_row(Pix.item_icon(id), it["name"], UI.C_TEXT if not locked else UI.C_DIM,
			it["desc"] if not locked else "Disponível no nível %d" % req,
			"%s" % UI.fmt_int(price), UI.C_GOLD if GameState.gold >= price else UI.C_BAD,
			"Comprar", func() -> void: _buy(id), locked or GameState.gold < price, 500))
		if GameState.count_item(id) > 0:
			col.get_child(col.get_child_count() - 1).tooltip_text = "Você tem %d" % GameState.count_item(id)


func _sell(col: VBoxContainer) -> void:
	var ids: Array = GameState.inventory.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return str(Data.item_name(a)) < str(Data.item_name(b)))
	var any := false
	for id in ids:
		var it: Dictionary = Data.get_item(id)
		if it.is_empty():
			continue
		var price := GameState.sell_price(id)
		var blocked := GameState.is_equipped(id) and GameState.count_item(id) <= 1
		var lvl := GameState.upgrade_level(id)
		var title: String = "%s%s  x%d" % [it["name"], " +%d" % lvl if lvl > 0 else "", GameState.count_item(id)]
		col.add_child(list_row(Pix.item_icon(id), title, UI.item_color(id), "Equipado" if blocked else "",
			"%s" % UI.fmt_int(price), UI.C_GOLD, "Vender", func() -> void: _sell_one(id), blocked or price <= 0, 500))
		any = true
	if not any:
		col.add_child(UI.label("Nada para vender.", UI.C_DIM))


func _buy(id: String) -> void:
	if GameState.buy_item(id, 1):
		Audio.sfx("coin")
	else:
		Audio.sfx("ui_error")


func _sell_one(id: String) -> void:
	if GameState.sell_item(id):
		Audio.sfx("coin_big", -4.0)
	else:
		Audio.sfx("ui_error")
