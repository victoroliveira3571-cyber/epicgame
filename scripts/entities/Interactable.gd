class_name Interactable
extends Node2D

## Base de tudo que o jogador aciona com [E]: portas, baús, escadas, portal...
## O jogador procura o Interactable mais próximo dentro de `interact_range`.

signal interacted(player: Node)

@export var interact_range: float = 18.0
var prompt_text: String = "Interagir"
var enabled: bool = true


func _ready() -> void:
	add_to_group("interactable")


## Texto mostrado acima do jogador quando este é o alvo ("" = não mostra).
func get_prompt() -> String:
	return "[E] " + prompt_text if enabled else ""


func can_interact(_player: Node) -> bool:
	return enabled


func interact(player: Node) -> void:
	interacted.emit(player)


## Ponto (em coordenadas globais) usado para medir a distância.
func focus_point() -> Vector2:
	return global_position
