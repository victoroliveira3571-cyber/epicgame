extends Area2D

## Baú colecionável: aperte [E] perto dele pra abrir uma vez só.
## Dá ouro sempre e, opcionalmente, um item.

@export var gold_reward: int = 10
@export var item_reward: String = ""  # vazio = só dá ouro

@onready var sprite: Sprite2D = $Sprite2D
@onready var hint_label: Label = $HintLabel

var opened: bool = false
var player_inside: bool = false
var e_was_pressed: bool = false

const CLOSED_TEXTURE := preload("res://assets/dungeon/chest_closed.png")
const OPEN_TEXTURE := preload("res://assets/dungeon/chest_open_full.png")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	var e_pressed := Input.is_physical_key_pressed(KEY_E)
	if e_pressed and not e_was_pressed and player_inside and not opened:
		_open()
	e_was_pressed = e_pressed


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if not opened:
			hint_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		hint_label.visible = false


func _open() -> void:
	opened = true
	sprite.texture = OPEN_TEXTURE
	hint_label.visible = false
	GameState.add_gold(gold_reward)
	if item_reward != "":
		GameState.add_item(item_reward, 1)
