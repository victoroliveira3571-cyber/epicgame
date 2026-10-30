class_name Projectile
extends Node2D

## Projétil genérico: flechas e magias do jogador (acertam inimigos) e disparos
## de monstros/chefes (acertam o jogador). Para ao bater em parede.

enum Kind { ARROW, ORB, FIRE, SPORE, WATER, PURPLE, ROCK }

var dir: Vector2 = Vector2.RIGHT
var speed: float = 160.0
var damage: float = 10.0
var crit: bool = false
var from_player: bool = true
var pierce: int = 0
var lifetime: float = 1.4
var radius: float = 4.0
var knockback: float = 60.0
var kind: int = Kind.ARROW
var spin: float = 0.0  # rotação extra por segundo (shuriken, etc.)

var _sprite: AnimatedSprite2D
var _hit_ids: Dictionary = {}
var _age: float = 0.0


static func make(parent: Node, pos: Vector2, direction: Vector2, kind_: int, dmg: float, is_player: bool) -> Projectile:
	var p := Projectile.new()
	p.kind = kind_
	p.dir = direction.normalized()
	p.damage = dmg
	p.from_player = is_player
	p.position = pos
	p.z_index = 20
	parent.add_child(p)
	return p


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	var frames: SpriteFrames
	var tint := Color.WHITE
	var sc := 1.0
	match kind:
		Kind.ARROW:
			frames = Pix.strip_frames("fx/Projectile_Arrow.png", 13, 1, 1.0)
		Kind.ORB:
			frames = Pix.strip_frames("fx/Projectile_EnergyBall.png", 16, 4, 14.0)
			tint = Color(0.75, 0.6, 1.0)
		Kind.FIRE:
			frames = Pix.strip_frames("fx/Projectile_Fireball.png", 16, 4, 14.0)
		Kind.SPORE:
			frames = Pix.strip_frames("fx/Projectile_EnergyBall.png", 16, 4, 14.0)
			tint = Color(0.65, 1.0, 0.5)
		Kind.WATER:
			frames = Pix.strip_frames("fx/Projectile_EnergyBall.png", 16, 4, 14.0)
			tint = Color(0.5, 0.9, 1.0)
		Kind.PURPLE:
			frames = Pix.strip_frames("fx/Projectile_BigEnergyBall.png", 24, 4, 12.0)
			tint = Color(1.0, 0.55, 0.9)
			sc = 0.8
		Kind.ROCK:
			frames = Pix.strip_frames("fx/Projectile_SpriteSheetRock.png", 16, 4, 10.0)
		_:
			frames = Pix.strip_frames("fx/Projectile_Arrow.png", 13, 1, 1.0)
	_sprite.sprite_frames = frames
	_sprite.modulate = tint
	_sprite.scale = Vector2(sc, sc)
	add_child(_sprite)
	_sprite.play(frames.get_animation_names()[0])
	if kind == Kind.ARROW or kind == Kind.FIRE:
		rotation = dir.angle()
	if from_player and kind != Kind.ARROW:
		var light := Fx.make_light(self, Vector2.ZERO, Color(0.7, 0.6, 1.0) if kind == Kind.ORB else Color(1.0, 0.6, 0.3), 0.22, 0.8)
		light.range_item_cull_mask = 1


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		_expire()
		return
	var from := global_position
	var to := from + dir * speed * delta
	# parede?
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		global_position = hit["position"]
		_impact_wall()
		return
	global_position = to
	if spin != 0.0:
		rotation += spin * delta
	if from_player:
		for e in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(e) or _hit_ids.has(e.get_instance_id()):
				continue
			if e.has_method("is_targetable") and not e.is_targetable():
				continue
			var reach: float = radius + float(e.get("body_radius"))
			if global_position.distance_to(e.global_position + Vector2(0, -4)) <= reach:
				_hit_ids[e.get_instance_id()] = true
				e.take_hit(damage, dir * knockback, crit, global_position)
				if pierce <= 0:
					_impact_enemy()
					return
				pierce -= 1
	else:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and global_position.distance_to(player.global_position + Vector2(0, -6)) <= radius + 4.0:
			if player.hurt(damage, global_position, knockback):
				_impact_enemy()


func _impact_wall() -> void:
	Fx.burst(get_parent(), global_position, Color(1, 1, 1, 0.9), 4, 30.0, 0.25)
	queue_free()


func _impact_enemy() -> void:
	Fx.burst(get_parent(), global_position, Color(1, 0.9, 0.5), 5, 36.0, 0.25)
	queue_free()


func _expire() -> void:
	queue_free()
