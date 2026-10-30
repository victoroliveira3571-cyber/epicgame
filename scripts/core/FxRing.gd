extends Node2D

## Anel desenhado em código (usado por Fx.ring).

var radius: float = 2.0:
	set(v):
		radius = v
		queue_redraw()
var color: Color = Color.WHITE
var width: float = 1.5


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, color, width, false)
