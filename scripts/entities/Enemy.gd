class_name Enemy
extends CharacterBody2D

## Monstro da masmorra. O comportamento vem de Data.MONSTERS[behavior]:
##  melee   persegue, prepara o golpe (telegrafado) e investe
##  charger mira, trava e dispara em linha reta (bate na parede e fica atordoado)
##  ranged  mantém distância e atira
##  flyer   voa em curvas e dá mordidas rápidas
##  hopper  anda em pulos e causa dano ao cair em cima
## Escala com o andar (vida, dano, recompensas). "Elite" = versão rara e mais forte.

signal died(enemy: Enemy)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, DEAD }

var def_id: String = "slime"
var data: Dictionary = {}
var floor_n: int = 1
var is_elite: bool = false
var is_boss: bool = false
var display_name: String = ""
var max_hp: float = 20.0
var hp: float = 20.0
var contact_dmg: float = 5.0
var move_speed: float = 30.0
var body_radius: float = 5.0
var behavior: String = "melee"
var aggro_radius: float = 120.0
var leash_radius: float = 260.0
var xp_reward: int = 5
var gold_range: Array = [1, 4]
var drop_bonus: float = 0.0

var state: int = State.IDLE
var state_time: float = 0.0
var attack_cd: float = 0.6
var stun_time: float = 0.0
var knock: Vector2 = Vector2.ZERO
var home: Vector2
var move_dir: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.DOWN
var attack_dir: Vector2 = Vector2.ZERO
var did_hit_this_attack: bool = false
var wander_timer: float = 0.0
var wander_dir: Vector2 = Vector2.ZERO
var sprite: AnimatedSprite2D
var bar: Node2D
var shadow: Sprite2D
var light: PointLight2D
var dungeon: Node = null
var _los_timer: float = 0.0
var _has_los: bool = false
var _path: PackedVector2Array = PackedVector2Array()
var _path_timer: float = 0.0
var _shown_bar_time: float = 0.0
var _hop_phase: float = 0.0
var _wobble: float = randf() * 10.0
var _bob_t: float = 0.0
var base_scale: float = 1.0
var charge_stunned: bool = false


static func spawn(parent: Node, id: String, pos: Vector2, floor_number: int, elite: bool = false) -> Enemy:
	var e := Enemy.new()
	e.def_id = id
	e.floor_n = floor_number
	e.is_elite = elite
	e.position = pos
	parent.add_child(e)
	return e


func _setup_stats() -> void:
	data = Data.MONSTERS[def_id]
	display_name = data["name"]
	behavior = data["behavior"]
	body_radius = float(data.get("radius", 5.0))
	base_scale = float(data.get("scale", 1.0))
	max_hp = float(data["hp"]) * Data.floor_scale_hp(floor_n)
	contact_dmg = float(data["dmg"]) * Data.floor_scale_dmg(floor_n)
	move_speed = float(data["speed"])
	xp_reward = int(round(float(data["xp"]) * Data.floor_scale_reward(floor_n)))
	gold_range = data["gold"].duplicate()
	if is_elite:
		max_hp *= 2.3
		contact_dmg *= 1.3
		move_speed *= 1.12
		xp_reward *= 3
		base_scale *= 1.25
		display_name = "%s Elite" % display_name
	hp = max_hp
	aggro_radius = 120.0 if behavior != "ranged" else 150.0


func _ready() -> void:
	_setup_stats()
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home = position
	dungeon = get_tree().get_first_node_in_group("dungeon")
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = body_radius * 0.85 * base_scale
	col.shape = shape
	col.position = Vector2(0, -3)
	add_child(col)
	shadow = Fx.make_shadow(self, (10.0 + body_radius) * base_scale, -1.0)
	sprite = AnimatedSprite2D.new()
	_build_sprite()
	sprite.position = Vector2(0, -8 * base_scale)
	sprite.scale = Vector2(base_scale, base_scale)
	add_child(sprite)
	_start_anim()
	bar = EnemyBar.new()
	bar.enemy = self
	bar.position = Vector2(0, -16 * base_scale - 5)
	bar.z_index = 5
	add_child(bar)
	if is_elite:
		sprite.modulate = Color(1.25, 0.8, 0.8)
		light = Fx.make_light(self, Vector2(0, -6), Color(1.0, 0.35, 0.3), 0.5, 0.7)
	wander_timer = randf_range(0.5, 2.5)
	_spawn_pop()


func _build_sprite() -> void:
	var folder := "chars" if data.get("kind", "") == "char" else "monsters"
	sprite.sprite_frames = Pix.actor_frames("%s/%s.png" % [folder, data["sheet"]])


func _start_anim() -> void:
	sprite.play("walk_down")
	sprite.pause()


func _ai_boss(_delta: float, _dist: float, _pp: Vector2) -> void:
	pass


func _spawn_pop() -> void:
	sprite.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(base_scale, base_scale), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func is_targetable() -> bool:
	return state != State.DEAD


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


# ====================================================================== IA
func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	var player := get_player()
	_los_timer -= delta
	attack_cd -= delta
	state_time -= delta
	_shown_bar_time -= delta
	var me := global_position
	var dist := INF
	var pp := Vector2.ZERO
	if player != null and not player.is_dead():
		pp = player.global_position
		dist = me.distance_to(pp)
	# longe e parado: dorme (economiza processamento)
	if state == State.IDLE and dist > 340.0 and knock.length() < 5.0:
		return
	if stun_time > 0.0:
		stun_time -= delta
		move_dir = Vector2.ZERO
		_apply_motion(delta, 0.0)
		_animate()
		return
	move_dir = Vector2.ZERO
	match behavior:
		"melee":
			_ai_melee(delta, dist, pp)
		"charger":
			_ai_charger(delta, dist, pp)
		"ranged":
			_ai_ranged(delta, dist, pp)
		"flyer":
			_ai_flyer(delta, dist, pp)
		"hopper":
			_ai_hopper(delta, dist, pp)
		"boss":
			_ai_boss(delta, dist, pp)
		_:
			_ai_melee(delta, dist, pp)
	_apply_motion(delta, 1.0)
	_animate()


func _apply_motion(delta: float, speed_mult: float) -> void:
	var v := move_dir * move_speed * speed_mult
	v += knock
	v += _separation() * 22.0
	velocity = v
	knock = knock.move_toward(Vector2.ZERO, 520.0 * delta)
	move_and_slide()


func _separation() -> Vector2:
	var push := Vector2.ZERO
	for o in get_tree().get_nodes_in_group("enemy"):
		if o == self or not is_instance_valid(o):
			continue
		var d := global_position - (o as Node2D).global_position
		var l := d.length()
		if l < 9.0 and l > 0.01:
			push += d / l * (9.0 - l) / 9.0
	return push


func _animate() -> void:
	if state == State.DEAD:
		return
	var dir_src := facing
	var dn := Pix.dir_name(dir_src)
	var anim := "walk_" + dn
	if sprite.animation != anim:
		sprite.play(anim)
	var moving := velocity.length() > 6.0
	if moving and state != State.WINDUP:
		if not sprite.is_playing():
			sprite.play(anim)
		sprite.speed_scale = clampf(velocity.length() / 30.0, 0.8, 2.2)
	elif behavior == "flyer" and state != State.DEAD:
		if not sprite.is_playing():
			sprite.play(anim)
		sprite.speed_scale = 1.4
	else:
		if sprite.is_playing() and behavior != "flyer":
			sprite.pause()
	# flutuar (voadores)
	if behavior == "flyer":
		_bob_t += get_physics_process_delta_time()
		sprite.position.y = (-10.0 + sin(_bob_t * 7.0) * 1.5) * base_scale


func _check_los(target: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -3), target + Vector2(0, -3), 1)
	return space.intersect_ray(q).is_empty()


func _toward(target: Vector2, delta: float) -> Vector2:
	if _los_timer <= 0.0:
		_has_los = _check_los(target)
		_los_timer = 0.18
	if _has_los or dungeon == null or not dungeon.has_method("path_to"):
		return (target - global_position).normalized()
	_path_timer -= delta
	if _path_timer <= 0.0 or _path.size() == 0:
		_path = dungeon.path_to(global_position, target)
		_path_timer = 0.5
	while _path.size() > 0 and global_position.distance_to(_path[0]) < 5.0:
		_path.remove_at(0)
	if _path.size() == 0:
		return (target - global_position).normalized()
	return (_path[0] - global_position).normalized()


func _alert() -> void:
	var emote := Sprite2D.new()
	emote.texture = Pix.tex("ui/emote/emote22.png")
	emote.position = Vector2(0, -22 * base_scale)
	emote.z_index = 100
	emote.scale = Vector2(0.3, 0.3)
	add_child(emote)
	var tw := emote.create_tween()
	tw.tween_property(emote, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.5)
	tw.tween_property(emote, "modulate:a", 0.0, 0.15)
	tw.tween_callback(emote.queue_free)


func _wander_idle(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(1.2, 3.0)
		if randf() < 0.5:
			wander_dir = Vector2.ZERO
		else:
			wander_dir = Vector2.from_angle(randf() * TAU)
		if global_position.distance_to(home) > 40.0:
			wander_dir = (home - global_position).normalized()
	move_dir = wander_dir * 0.35
	if move_dir != Vector2.ZERO:
		facing = move_dir


func _try_aggro(dist: float, pp: Vector2) -> bool:
	if dist > aggro_radius:
		return false
	if _los_timer <= 0.0:
		_has_los = _check_los(pp)
		_los_timer = 0.18
	if _has_los or dist < 40.0:
		state = State.CHASE
		_alert()
		Audio.sfx("alert", -12.0, 0.1)
		_wake_nearby()
		return true
	return false


## Acordar vizinhos próximos (um grupo age junto).
func _wake_nearby() -> void:
	for o in get_tree().get_nodes_in_group("enemy"):
		var e := o as Enemy
		if e != null and e != self and e.state == State.IDLE and e.global_position.distance_to(global_position) < 70.0:
			e.state = State.CHASE


func _lose_target(dist: float) -> bool:
	if dist > leash_radius * 1.4 or global_position.distance_to(home) > leash_radius * 2.0:
		state = State.IDLE
		return true
	return false


# ---------------------------------------------------------------- melee
func _ai_melee(delta: float, dist: float, pp: Vector2) -> void:
	match state:
		State.IDLE:
			_wander_idle(delta)
			_try_aggro(dist, pp)
		State.CHASE:
			if _lose_target(dist):
				return
			facing = (pp - global_position).normalized()
			var reach := 15.0 + body_radius * base_scale * 0.5
			if dist <= reach + 5.0 and attack_cd <= 0.0:
				_begin_windup(pp, 0.38)
			else:
				move_dir = _toward(pp, delta) if dist > reach - 2.0 else Vector2.ZERO
				facing = move_dir if move_dir != Vector2.ZERO else facing
		State.WINDUP:
			if state_time <= 0.0:
				state = State.ATTACK
				state_time = 0.14
				did_hit_this_attack = false
				knock = attack_dir * 150.0
				Audio.sfx("swing2", -10.0, 0.15)
				Fx.fx(get_parent(), "claw", global_position + Vector2(0, -6) + attack_dir * 11.0, 0.8, attack_dir.angle(), Color(1, 0.85, 0.8))
		State.ATTACK:
			_attack_overlap(18.0 + body_radius * 0.3, 1.0)
			if state_time <= 0.0:
				state = State.RECOVER
				state_time = 0.45
				attack_cd = randf_range(0.7, 1.2)
		State.RECOVER:
			if state_time <= 0.0:
				state = State.CHASE


func _begin_windup(pp: Vector2, duration: float) -> void:
	state = State.WINDUP
	state_time = duration
	attack_dir = (pp - global_position).normalized()
	facing = attack_dir
	sprite.modulate = Color(1.9, 1.9, 1.9)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1.25, 0.8, 0.8) if is_elite else Color.WHITE, duration)
	knock = -attack_dir * 40.0  # recua antes de investir


func _attack_overlap(reach: float, mult: float) -> void:
	if did_hit_this_attack:
		return
	var player := get_player()
	if player == null or player.is_dead():
		return
	if global_position.distance_to(player.global_position) <= reach:
		if player.hurt(contact_dmg * mult, global_position, 100.0):
			did_hit_this_attack = true


# -------------------------------------------------------------- charger
func _ai_charger(delta: float, dist: float, pp: Vector2) -> void:
	match state:
		State.IDLE:
			_wander_idle(delta)
			_try_aggro(dist, pp)
		State.CHASE:
			if _lose_target(dist):
				return
			facing = (pp - global_position).normalized()
			if dist < 95.0 and attack_cd <= 0.0 and _has_los:
				_begin_windup(pp, 0.6)
				Audio.sfx("alert2", -10.0)
			else:
				move_dir = _toward(pp, delta)
				facing = move_dir if move_dir != Vector2.ZERO else facing
		State.WINDUP:
			sprite.position.x = sin(Time.get_ticks_msec() * 0.06) * 0.8
			if state_time <= 0.0:
				sprite.position.x = 0.0
				state = State.ATTACK
				state_time = 0.55
				did_hit_this_attack = false
				charge_stunned = false
		State.ATTACK:
			move_dir = attack_dir * 4.4
			var before := global_position
			_attack_overlap(14.0, 1.2)
			if state_time <= 0.0 or (get_real_velocity().length() < 20.0 and state_time < 0.5):
				if state_time > 0.05:
					# bateu na parede: atordoado
					Fx.burst(get_parent(), global_position + Vector2(0, -6), Color(1, 1, 1), 6, 40.0, 0.3)
					Fx.float_text(get_parent(), "Zzz", global_position + Vector2(0, -20), Color("ffe08a"))
					state = State.RECOVER
					state_time = 1.1
					Audio.sfx("thud", -4.0)
				else:
					state = State.RECOVER
					state_time = 0.5
				attack_cd = randf_range(1.2, 2.0)
		State.RECOVER:
			if state_time <= 0.0:
				state = State.CHASE


# --------------------------------------------------------------- ranged
func _ai_ranged(delta: float, dist: float, pp: Vector2) -> void:
	var want: float = float(data.get("range", 90.0))
	match state:
		State.IDLE:
			_wander_idle(delta)
			_try_aggro(dist, pp)
		State.CHASE:
			if _lose_target(dist):
				return
			var dir := (pp - global_position).normalized()
			facing = dir
			if dist < want * 0.55:
				move_dir = -dir * 0.8
			elif dist > want * 0.95 or not _has_los:
				move_dir = _toward(pp, delta) * 0.9
			else:
				move_dir = dir.orthogonal() * (0.35 if int(Time.get_ticks_msec() / 1500) % 2 == 0 else -0.35)
			if _los_timer <= 0.0:
				_has_los = _check_los(pp)
				_los_timer = 0.18
			if attack_cd <= 0.0 and dist <= want * 1.1 and _has_los:
				_begin_windup(pp, 0.45)
				move_dir = Vector2.ZERO
		State.WINDUP:
			if state_time <= 0.0:
				_shoot(pp)
				state = State.RECOVER
				state_time = 0.35
				attack_cd = float(data.get("cooldown", 2.2)) * randf_range(0.85, 1.15)
		State.RECOVER:
			if state_time <= 0.0:
				state = State.CHASE


func _shoot(pp: Vector2) -> void:
	var kind: String = data.get("proj", "orb")
	var pk := Projectile.Kind.ORB
	match kind:
		"spore":
			pk = Projectile.Kind.SPORE
		"water":
			pk = Projectile.Kind.WATER
		"fire":
			pk = Projectile.Kind.FIRE
		_:
			pk = Projectile.Kind.ORB
	var dir := (pp + Vector2(0, -6) - (global_position + Vector2(0, -8))).normalized()
	var p := Projectile.make(get_parent(), global_position + Vector2(0, -8) + dir * 6.0, dir, pk, contact_dmg, false)
	p.speed = 85.0 + minf(floor_n * 2.0, 40.0)
	p.lifetime = 2.4
	p.radius = 4.0
	p.knockback = 70.0
	Audio.sfx("magic1", -10.0, 0.12)


# ---------------------------------------------------------------- flyer
func _ai_flyer(delta: float, dist: float, pp: Vector2) -> void:
	match state:
		State.IDLE:
			_wander_idle(delta)
			move_dir *= 1.5
			_try_aggro(dist, pp)
		State.CHASE:
			if _lose_target(dist):
				return
			_wobble += delta * 5.0
			var dir := _toward(pp, delta)
			facing = dir if dir != Vector2.ZERO else facing
			move_dir = dir.rotated(sin(_wobble) * 0.9)
			if dist < 24.0 and attack_cd <= 0.0:
				_begin_windup(pp, 0.2)
		State.WINDUP:
			move_dir = Vector2.ZERO
			if state_time <= 0.0:
				state = State.ATTACK
				state_time = 0.28
				did_hit_this_attack = false
		State.ATTACK:
			move_dir = attack_dir * 3.2
			_attack_overlap(13.0, 1.0)
			if state_time <= 0.0:
				state = State.RECOVER
				state_time = 0.6
				attack_cd = randf_range(1.0, 1.6)
		State.RECOVER:
			move_dir = (-attack_dir).rotated(sin(_wobble) * 0.6) * 0.8
			if state_time <= 0.0:
				state = State.CHASE


# --------------------------------------------------------------- hopper
func _ai_hopper(delta: float, dist: float, pp: Vector2) -> void:
	match state:
		State.IDLE:
			_wander_idle(delta)
			_try_aggro(dist, pp)
		State.CHASE:
			if _lose_target(dist):
				return
			# ciclo: espera -> salto -> pouso
			if state_time <= 0.0:
				attack_dir = _toward(pp, delta)
				facing = attack_dir if attack_dir != Vector2.ZERO else facing
				state = State.WINDUP
				state_time = 0.32
				var tw := create_tween()
				tw.tween_property(sprite, "scale", Vector2(base_scale * 1.15, base_scale * 0.8), 0.28)
		State.WINDUP:
			if state_time <= 0.0:
				state = State.ATTACK
				state_time = 0.38
				did_hit_this_attack = false
				var tw2 := create_tween()
				tw2.tween_property(sprite, "scale", Vector2(base_scale * 0.9, base_scale * 1.15), 0.1)
				tw2.tween_property(sprite, "scale", Vector2(base_scale, base_scale), 0.25)
		State.ATTACK:
			var t := 1.0 - state_time / 0.38
			sprite.position.y = (-8.0 - sin(t * PI) * 7.0) * base_scale
			move_dir = attack_dir * 3.2
			if t > 0.55:
				_attack_overlap(12.0 + body_radius * 0.4, 1.0)
			if state_time <= 0.0:
				sprite.position.y = -8.0 * base_scale
				Fx.burst(get_parent(), global_position + Vector2(0, -1), Color(1, 1, 1, 0.6), 3, 20.0, 0.2)
				state = State.CHASE
				state_time = randf_range(0.35, 0.7)
		State.RECOVER:
			state = State.CHASE


# ====================================================================== Dano
func take_hit(amount: float, kb: Vector2, crit: bool, _from: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	_shown_bar_time = 2.5
	bar.queue_redraw()
	knock += kb * (0.35 if is_boss else 1.0) * (0.6 if state == State.WINDUP else 1.0)
	if not is_boss and state != State.ATTACK:
		stun_time = 0.1 if not crit else 0.18
	if state == State.IDLE:
		state = State.CHASE
		_wake_nearby()
	var w := get_parent()
	var text := "%d" % int(round(amount))
	Fx.float_text(w, text + ("!" if crit else ""), global_position + Vector2(randf_range(-4, 4), -14 * base_scale),
		Color("ffd84a") if crit else Color("ffffff"), 2 if crit else 1, 16.0 if crit else 12.0)
	Fx.flash(sprite, Color(2.6, 1.0, 1.0) if not crit else Color(3, 2.2, 0.8), 0.1)
	Fx.fx(w, "spark", global_position + Vector2(0, -7), 0.6 if not crit else 1.0)
	Audio.sfx("hit_crit" if crit else ["hit1", "hit2", "hit3"][randi() % 3], -3.0 if crit else -5.0)
	if hp <= 0.0:
		_die()


func _die() -> void:
	state = State.DEAD
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemy")
	bar.visible = false
	if light != null:
		light.queue_free()
	var w := get_parent()
	Audio.sfx("die", -4.0, 0.1)
	Fx.fx(w, "smoke", global_position + Vector2(0, -6), 1.0)
	Fx.burst(w, global_position + Vector2(0, -6), Color(1, 0.9, 0.6), 8, 50.0, 0.4)
	_award_and_drop()
	died.emit(self)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "scale", Vector2(base_scale * 1.3, 0.1), 0.18)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(queue_free)


func _award_and_drop() -> void:
	var gained_xp := GameState.add_xp(xp_reward)
	Game.run_add("xp", gained_xp)
	GameState.register_monster_defeated(is_boss)
	Game.run_add("kills")
	if is_boss:
		Game.run_add("bosses")
	Fx.float_text(get_parent(), "+%d XP" % gained_xp, global_position + Vector2(0, -22 * base_scale), Color("8fd4ff"), 1, 18.0, 0.9)
	Loot.drop_from_enemy(self)


# ==================================================================== Barra
class EnemyBar extends Node2D:
	var enemy: Enemy

	func _draw() -> void:
		if enemy == null or enemy.hp >= enemy.max_hp:
			return
		var w := 14.0 if not enemy.is_boss else 30.0
		var ratio := clampf(enemy.hp / enemy.max_hp, 0.0, 1.0)
		draw_rect(Rect2(-w / 2.0 - 1, -1, w + 2, 4), Color("1a1220"))
		draw_rect(Rect2(-w / 2.0, 0, w * ratio, 2), Color("e0463a") if not enemy.is_elite else Color("e066ff"))

	func _process(_delta: float) -> void:
		var want := enemy != null and enemy.hp < enemy.max_hp and enemy.state != Enemy.State.DEAD
		if want != visible:
			visible = want
		if visible:
			queue_redraw()
