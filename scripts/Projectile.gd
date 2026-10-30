extends Area2D

## Flecha/magia disparada pelas classes à distância (mago/arqueiro).
## Viaja em linha reta e causa dano ao primeiro monstro que acertar.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 320.0
var damage: int = 10
var lifetime: float = 1.2


func _ready() -> void:
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
