extends Node2D

## Prédio da cidade. Fica bloqueado (cinza, com cadeado) até o jogador
## atingir o nível necessário. O Restaurante (building_id = "restaurante")
## já tem uma função real: comprar Pão com [E] pra guardar no inventário.
## As outras funções (loja, missões) chegam em versões futuras.

@export var building_name: String = "Prédio"
@export var hint_text: String = "Em breve nesta versão"
@export var building_color: Color = Color(0.55, 0.4, 0.25)
@export var required_level: int = 1
@export var building_id: String = ""  # "restaurante" = pode comprar Pão

const BREAD_COST := 8

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var hint_label: Label = $HintLabel
@onready var area: Area2D = $Area2D

var player_inside: bool = false
var e_was_pressed: bool = false


func _ready() -> void:
	GameState.stats_changed.connect(_refresh_visual)
	_refresh_visual()
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	var e_pressed := Input.is_physical_key_pressed(KEY_E)
	if e_pressed and not e_was_pressed and player_inside and _is_unlocked():
		_interact()
	e_was_pressed = e_pressed


func _is_unlocked() -> bool:
	return GameState.level >= required_level


func _refresh_visual() -> void:
	if _is_unlocked():
		label.text = building_name
		sprite.modulate = building_color
	else:
		label.text = "🔒 Nível %d" % required_level
		sprite.modulate = building_color.darkened(0.6)
	if player_inside:
		_update_hint()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		hint_label.visible = true
		_update_hint()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		hint_label.visible = false


func _update_hint() -> void:
	if not _is_unlocked():
		hint_label.text = "Desbloqueia no Nível %d" % required_level
	elif building_id == "restaurante":
		hint_label.text = "[E] Comprar Pão (%d ouro)" % BREAD_COST
	elif building_id == "loja":
		hint_label.text = "[E] Abrir a loja"
	elif building_id == "guilda":
		hint_label.text = "[E] Ver missões da Guilda"
	elif building_id == "casa":
		if GameState.casa_decorada:
			hint_label.text = "Casa decorada (fome gasta menos)"
		else:
			hint_label.text = "[E] Comprar mobília (%d ouro, reduz fome gasta)" % GameState.FURNITURE_COST
	else:
		hint_label.text = hint_text


func _interact() -> void:
	if building_id == "restaurante":
		if GameState.spend_gold(BREAD_COST):
			GameState.add_item(GameState.ITEM_BREAD, 1)
			hint_label.text = "Comprou Pão! [F] pra comer quando quiser"
		else:
			hint_label.text = "Ouro insuficiente (precisa de %d)" % BREAD_COST
	elif building_id == "casa":
		if GameState.buy_furniture():
			hint_label.text = "Mobília comprada! Fome gasta menos agora"
		else:
			hint_label.text = "Ouro insuficiente (precisa de %d)" % GameState.FURNITURE_COST
	elif building_id == "loja" or building_id == "guilda":
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			if building_id == "loja":
				hud.toggle_shop()
			else:
				hud.toggle_guild()
