extends Node2D

## Só liga a música da cidade quando a cena carrega.

func _ready() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("play_music"):
		hud.play_music("town")
