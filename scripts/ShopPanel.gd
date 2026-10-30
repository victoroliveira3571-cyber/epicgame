extends PanelContainer

## Janela da Loja de Armas: compra os 3 itens fixos (GameState.SHOP_ITEMS),
## vende de volta qualquer item do inventário por metade do preço, e
## equipa/desequipa os itens de equipamento (efeito real em ataque/vida).

@onready var buy_labels: Array[Label] = [
	$Margin/VBox/BuyRow1/ItemLabel1,
	$Margin/VBox/BuyRow2/ItemLabel2,
	$Margin/VBox/BuyRow3/ItemLabel3,
]
@onready var buy_buttons: Array[Button] = [
	$Margin/VBox/BuyRow1/BuyButton1,
	$Margin/VBox/BuyRow2/BuyButton2,
	$Margin/VBox/BuyRow3/BuyButton3,
]

## equip_button fica null na linha do Pão (não é equipável).
@onready var sell_rows: Array[Dictionary] = [
	{"item_id": "pao", "label": $Margin/VBox/SellRow1/SellLabel1, "button": $Margin/VBox/SellRow1/SellButton1, "equip_button": null},
	{"item_id": "espada_madeira", "label": $Margin/VBox/SellRow2/SellLabel2, "button": $Margin/VBox/SellRow2/SellButton2, "equip_button": $Margin/VBox/SellRow2/EquipButton2},
	{"item_id": "escudo_couro", "label": $Margin/VBox/SellRow3/SellLabel3, "button": $Margin/VBox/SellRow3/SellButton3, "equip_button": $Margin/VBox/SellRow3/EquipButton3},
	{"item_id": "armadura_couro", "label": $Margin/VBox/SellRow4/SellLabel4, "button": $Margin/VBox/SellRow4/SellButton4, "equip_button": $Margin/VBox/SellRow4/EquipButton4},
]

@onready var equipped_summary_label: Label = $Margin/VBox/EquippedSummaryLabel
@onready var close_button: Button = $Margin/VBox/CloseButton


func _ready() -> void:
	for i in GameState.SHOP_ITEMS.size():
		var item: Dictionary = GameState.SHOP_ITEMS[i]
		buy_labels[i].text = "%s — %d ouro" % [item["name"], item["price"]]
		buy_buttons[i].pressed.connect(_on_buy_pressed.bind(item["id"]))

	for row in sell_rows:
		row["button"].pressed.connect(_on_sell_pressed.bind(row["item_id"]))
		if row["equip_button"] != null:
			row["equip_button"].pressed.connect(_on_equip_pressed.bind(row["item_id"]))

	close_button.pressed.connect(_on_close_pressed)
	GameState.stats_changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for i in GameState.SHOP_ITEMS.size():
		var item: Dictionary = GameState.SHOP_ITEMS[i]
		buy_buttons[i].disabled = GameState.gold < int(item["price"])

	for row in sell_rows:
		var item_id: String = row["item_id"]
		var qty: int = GameState.inventory.get(item_id, 0)
		var item_name: String = GameState.ITEM_NAMES.get(item_id, item_id)
		var sell_price: int = GameState.get_item_sell_price(item_id)
		var equipped: bool = GameState.is_item_equipped(item_id)
		row["label"].text = "%s x%d (vende por %d)%s" % [
			item_name, qty, sell_price, "  [equipado]" if equipped else ""
		]
		row["button"].disabled = qty <= 0 or equipped  # não vende o que está equipado
		if row["equip_button"] != null:
			row["equip_button"].text = "Desequipar" if equipped else "Equipar"
			row["equip_button"].disabled = qty <= 0 and not equipped

	_refresh_equipped_summary()


func _refresh_equipped_summary() -> void:
	var weapon := _equipped_name("weapon")
	var shield := _equipped_name("shield")
	var armor := _equipped_name("armor")
	equipped_summary_label.text = "Equipado: arma %s / escudo %s / armadura %s" % [weapon, shield, armor]


func _equipped_name(slot: String) -> String:
	var item_id: String = GameState.equipped.get(slot, "")
	if item_id == "":
		return "—"
	return GameState.ITEM_NAMES.get(item_id, item_id)


func _on_buy_pressed(item_id: String) -> void:
	GameState.buy_shop_item(item_id)


func _on_sell_pressed(item_id: String) -> void:
	GameState.sell_item(item_id)


func _on_equip_pressed(item_id: String) -> void:
	if GameState.is_item_equipped(item_id):
		var slot: String = ""
		for shop_item in GameState.SHOP_ITEMS:
			if shop_item["id"] == item_id:
				slot = shop_item["slot"]
				break
		GameState.unequip_slot(slot)
	else:
		GameState.equip_item(item_id)


func _on_close_pressed() -> void:
	visible = false
