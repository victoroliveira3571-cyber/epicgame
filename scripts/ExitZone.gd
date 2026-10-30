extends Area2D

## Zona de saída da masmorra: o jogador anda em cima dela e volta pra cidade.

@export var target_scene: String = "res://scenes/Main.tscn"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Trocar de cena durante o callback de física não é permitido —
		# adia pra depois do passo de física atual.
		get_tree().change_scene_to_file.call_deferred(target_scene)
