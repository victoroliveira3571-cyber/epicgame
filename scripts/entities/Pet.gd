class_name Pet
extends Node2D

## Companheiro do herói (Corvin, Brisa, Lúmen, Airevis; Data.PETS). Segue o jogador, ataca o
## inimigo mais próximo e recolhe moedas e itens caídos. Só um fica ativo por vez (Story.set_pet).

const ATTACK_RANGE := 80.0
const COLLECT_RANGE := 96.0

var pet_id: String = ""
var data: Dictionary = {}
var player: Player
var sprite: AnimatedSprite2D
var flyer: bool = true
var attack_cd: float = 1.0
var target: Node2D = null          # inimigo ou moeda que o pet está buscando
var mode: String = "follow"        # follow | strike | fetch
var _t: float = randf() * 10.0
var _scan: float = 0.0


## Troca o pet que acompanha o jogador (remove o antigo).
static func attach_to(p: Player) -> void:
	if p == null or not is_instance_valid(p) or not p.is_inside_tree():
		return
	for old in p.get_tree().get_nodes_in_group("pet"):
		old.queue_free()
	var id := Story.active_pet()
	if id == "" or not Data.PETS.has(id):
		return
	var pet := Pet.new()
	pet.pet_id = id
	pet.player = p
	pet.position = p.global_position + Vector2(-14, 4)
	p.get_parent().add_child(pet)


func _ready() -> void:
	add_to_group("pet")
	data = Data.PETS[pet_id]
	flyer = pet_id != "brisa"
	sprite = AnimatedSprite2D.new()
	if data["kind"] == "animal":
		sprite.sprite_frames = Pix.animal_frames(data["sheet"])
		sprite.play("walk")
	else:
		sprite.sprite_frames = Pix.actor_frames("monsters/%s.png" % data["sheet"])
		sprite.play("walk_down")
	sprite.modulate = data.get("tint", Color.WHITE)
	sprite.position = Vector2(0, -8)
	add_child(sprite)
	Fx.make_shadow(self, 8.0, 0.0)
	if pet_id == "airevis":
		Fx.make_light(self, Vector2(0, -10), Color(0.7, 0.85, 1.0), 0.45, 0.6)


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	_t += delta
	attack_cd -= delta
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.25
		_choose_target()
	var goal := _follow_point()
	var speed := 70.0
	if mode != "follow" and target != null and is_instance_valid(target):
		goal = target.global_position
		speed = 150.0 if mode == "strike" else 120.0
	var v := goal - global_position
	if v.length() > 260.0:
		global_position = player.global_position + Vector2(-12, 2)   # ficou para trás: reaparece ao lado
		v = Vector2.ZERO
	global_position += v.limit_length(speed * delta) if v.length() > 2.0 else Vector2.ZERO
	_animate(v)
	if mode == "strike" and target != null and is_instance_valid(target) and global_position.distance_to(target.global_position) < 10.0:
		_hit(target)
		mode = "follow"
		target = null
	elif mode == "fetch" and target != null and is_instance_valid(target) and global_position.distance_to(target.global_position) < 8.0:
		(target as Pickup).collect_by_pet(player)
		mode = "follow"
		target = null


func _follow_point() -> Vector2:
	var back := -player.facing.normalized() if player.facing.length() > 0.1 else Vector2.UP
	return player.global_position + back * 16.0 + back.orthogonal() * 8.0


func _choose_target() -> void:
	if mode != "follow" and target != null and is_instance_valid(target):
		if target is Enemy and (target as Enemy).state == Enemy.State.DEAD:
			mode = "follow"
		else:
			return
	mode = "follow"
	target = null
	# 1) moedas e itens no chão
	var best: Node2D = null
	var best_d := COLLECT_RANGE
	for pk in get_tree().get_nodes_in_group("pickup"):
		var n := pk as Pickup
		if n == null or n.age < 0.5:
			continue
		var d := n.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = n
	if best != null:
		target = best
		mode = "fetch"
		return
	# 2) inimigo perto do jogador
	if attack_cd > 0.0:
		return
	var enemy: Node2D = null
	var ed := ATTACK_RANGE
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Enemy
		if en == null or not en.is_targetable():
			continue
		if en is Boss and not (en as Boss).active:
			continue
		var d2 := en.global_position.distance_to(player.global_position)
		if d2 < ed:
			ed = d2
			enemy = en
	if enemy == null:
		return
	attack_cd = 1.6
	if data["attack"] == "orb":
		_shoot(enemy)
	else:
		target = enemy
		mode = "strike"


func _damage() -> float:
	var mult := 0.4 if data["attack"] == "bite" else (0.3 if data["attack"] == "dive" else 0.28)
	return maxf(1.0, GameState.get_attack_power() * mult)


func _hit(e: Node2D) -> void:
	if not e.has_method("take_hit"):
		return
	var dir := (e.global_position - global_position).normalized()
	e.take_hit(_damage(), dir * 50.0, false, global_position)
	Audio.sfx("bird" if pet_id == "corvin" else "growl", -10.0, 0.15)
	global_position -= dir * 10.0


func _shoot(e: Node2D) -> void:
	var origin := global_position + Vector2(0, -12)
	var dir := ((e.global_position + Vector2(0, -4)) - origin).normalized()
	var p := Projectile.make(get_parent(), origin, dir, Projectile.Kind.ORB, _damage(), true)
	p.speed = 170.0
	p.lifetime = 1.0
	p.radius = 4.0
	p.knockback = 30.0
	p.modulate = Color(0.7, 0.9, 1.0) if pet_id == "airevis" else Color(1.0, 0.95, 0.7)
	Audio.sfx("magic1", -12.0)


func _animate(v: Vector2) -> void:
	if flyer:
		sprite.position.y = -12.0 + sin(_t * 5.0) * 2.0
	if data["kind"] == "animal":
		if absf(v.x) > 0.5:
			sprite.flip_h = v.x > 0.0
		sprite.speed_scale = 1.5 if v.length() > 1.0 else 0.6
	else:
		var anim := "walk_" + Pix.dir_name(v if v.length() > 0.5 else Vector2.DOWN)
		if sprite.animation != anim:
			sprite.play(anim)
