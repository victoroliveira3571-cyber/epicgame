extends CharacterBody2D

const SPEED := 160.0
const BREAD_HUNGER_RESTORE := 40
const POTION_HEAL := 30
const ATTACK_RANGE := 70.0
const ATTACK_COOLDOWN := 0.4
const PROJECTILE_SCENE := preload("res://scenes/Projectile.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

const SHAKE_DURATION := 0.25
const SHAKE_STRENGTH := 6.0

var f_was_pressed: bool = false
var h_was_pressed: bool = false
var space_was_pressed: bool = false
var attack_cooldown_left: float = 0.0
var facing_direction: Vector2 = Vector2.DOWN
var last_direction: String = "down"


func _ready() -> void:
	add_to_group("player")
	GameState.damage_taken.connect(_on_damage_taken)


func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_vector.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_vector.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_vector.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_vector.y += 1

	input_vector = input_vector.normalized()
	velocity = input_vector * SPEED
	move_and_slide()

	if input_vector.length() > 0.1:
		facing_direction = input_vector
		_update_direction(input_vector)
		var anim := "walk_" + last_direction
		if sprite.animation != anim:
			sprite.play(anim)
	else:
		var anim := "idle_" + last_direction
		if sprite.animation != anim:
			sprite.play(anim)

	var f_pressed := Input.is_physical_key_pressed(KEY_F)
	if f_pressed and not f_was_pressed:
		_try_eat()
	f_was_pressed = f_pressed

	var h_pressed := Input.is_physical_key_pressed(KEY_H)
	if h_pressed and not h_was_pressed:
		_try_heal()
	h_was_pressed = h_pressed

	attack_cooldown_left = max(attack_cooldown_left - delta, 0.0)
	var space_pressed := Input.is_physical_key_pressed(KEY_SPACE)
	if space_pressed and not space_was_pressed and attack_cooldown_left <= 0.0:
		_attack()
	space_was_pressed = space_pressed

	sprite.modulate = Color(1, 0.55, 0.55) if GameState.hunger <= 0 else Color(1, 1, 1)

	if not GameState.is_alive():
		_die_and_return_to_town()


func _on_damage_taken(_amount: int) -> void:
	var tween := create_tween()
	var steps := 5
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * SHAKE_STRENGTH * falloff
		tween.tween_property(camera, "offset", offset, SHAKE_DURATION / steps)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)


func _update_direction(input: Vector2) -> void:
	if abs(input.x) > abs(input.y):
		last_direction = "side"
		sprite.flip_h = input.x < 0
	elif input.y < 0:
		last_direction = "up"
	else:
		last_direction = "down"


func _try_eat() -> void:
	if GameState.hunger >= 100:
		return
	if GameState.remove_item(GameState.ITEM_BREAD, 1):
		GameState.eat_hunger(BREAD_HUNGER_RESTORE)


func _try_heal() -> void:
	if GameState.hp >= GameState.get_max_hp():
		return
	if GameState.remove_item(GameState.ITEM_POTION, 1):
		GameState.heal(POTION_HEAL)


func _attack() -> void:
	attack_cooldown_left = ATTACK_COOLDOWN
	if GameState.is_ranged_class():
		var projectile: Area2D = PROJECTILE_SCENE.instantiate()
		projectile.global_position = global_position
		projectile.direction = facing_direction
		projectile.damage = GameState.get_attack_power()
		get_parent().add_child(projectile)
	else:
		for monster in get_tree().get_nodes_in_group("monster"):
			if global_position.distance_to(monster.global_position) <= ATTACK_RANGE:
				monster.take_damage(GameState.get_attack_power())


func _die_and_return_to_town() -> void:
	GameState.revive_after_defeat()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
