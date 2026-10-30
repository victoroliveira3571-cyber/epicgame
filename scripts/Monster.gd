extends Area2D

## Monstro da masmorra. Fica parado no ponto de origem até o jogador entrar
## no raio de detecção; aí persegue. Se o jogador fugir (sai do raio de
## desistência) ou o monstro se afastar demais de casa, volta pro lugar.
## Revida com dano de contato enquanto o jogador ficar perto. Morre quando a
## vida chega a 0 e solta ouro (sempre) + um item (às vezes).

@export var monster_name: String = "Monstro"
@export var max_hp: int = 30
@export var contact_damage: int = 5
@export var gold_drop_min: int = 5
@export var gold_drop_max: int = 15
@export var drop_chance: float = 0.3
@export var drop_item_id: String = "pocao_vida"
@export var move_speed: float = 70.0
@export var detection_radius: float = 220.0
@export var give_up_radius: float = 340.0
@export var leash_radius: float = 420.0

enum State { IDLE, CHASE, RETURN }
const STOP_DISTANCE := 26.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_bar_fg: ColorRect = $HPBarFg
@onready var damage_timer: Timer = $DamageTimer

var hp: int
var state: int = State.IDLE
var home_position: Vector2


func _ready() -> void:
	add_to_group("monster")
	hp = max_hp
	home_position = position
	damage_timer.timeout.connect(_on_damage_tick)


func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var player_dist := INF
	if player and GameState.is_alive():
		player_dist = global_position.distance_to(player.global_position)

	match state:
		State.IDLE:
			if player_dist <= detection_radius:
				state = State.CHASE
		State.CHASE:
			if player_dist > give_up_radius or position.distance_to(home_position) > leash_radius:
				state = State.RETURN
			elif player_dist > STOP_DISTANCE:
				_move_toward(player.global_position, delta)
		State.RETURN:
			if position.distance_to(home_position) <= 4.0:
				position = home_position
				state = State.IDLE
			else:
				_move_toward(get_parent().to_global(home_position), delta)


func _move_toward(target_global: Vector2, delta: float) -> void:
	var direction := (target_global - global_position).normalized()
	global_position += direction * move_speed * delta
	if absf(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = max(hp - amount, 0)
	_update_hp_bar()
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("spawn_float_text"):
		hud.spawn_float_text("-%d" % amount, Color(1, 0.85, 0.3), global_position + Vector2(0, -50))
	sprite.modulate = Color(1, 0.4, 0.4)
	_play_hud_sfx("hit")
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(sprite):
		sprite.modulate = Color(1, 1, 1)
	if hp <= 0:
		_die()


func _update_hp_bar() -> void:
	var ratio: float = float(hp) / float(max_hp)
	hp_bar_fg.scale.x = clamp(ratio, 0.0, 1.0)


func _die() -> void:
	var gold_amount := randi_range(gold_drop_min, gold_drop_max)
	GameState.add_gold(gold_amount)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("spawn_float_text"):
		hud.spawn_float_text("+%d ouro" % gold_amount, Color(1, 0.9, 0.35), global_position + Vector2(0, -50))
	if randf() < drop_chance:
		GameState.add_item(drop_item_id, 1)
	GameState.register_monster_defeated()
	_play_hud_sfx("coin")
	queue_free()


func _play_hud_sfx(which: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("play_named_sfx"):
		hud.play_named_sfx(which)


func _on_damage_tick() -> void:
	if hp <= 0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and GameState.is_alive():
			GameState.take_damage(contact_damage)
