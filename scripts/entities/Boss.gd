class_name Boss
extends Enemy

## Chefe de andar. Tem 4 padrões de ataque telegrafados (pisão, investida, rajada de
## projéteis, invocação) e uma segunda fase abaixo de 50% de vida.

var boss_id: String = "slime_gigante"
var boss_data: Dictionary = {}
var active: bool = false
var busy: bool = false
var charging: bool = false
var phase: int = 1
var forced_move: Vector2 = Vector2.ZERO
var minions: Array = []
var frame_h: float = 32.0
var _bar_timer: float = 0.0

signal activated(boss: Boss)


static func spawn_boss(parent: Node, id: String, pos: Vector2, floor_number: int) -> Boss:
	var b := Boss.new()
	b.boss_id = id
	b.floor_n = floor_number
	b.is_boss = true
	b.position = pos
	parent.add_child(b)
	return b


func _setup_stats() -> void:
	boss_data = Data.BOSSES[boss_id]
	data = boss_data
	is_boss = true
	display_name = boss_data["name"]
	behavior = "boss"
	body_radius = float(boss_data["radius"])
	var cycle := maxi(0, (floor_n / 5 - 1) / Data.BOSS_ORDER.size())
	var mult := 1.0 + 0.35 * float(cycle)
	max_hp = float(boss_data["hp"]) * mult
	hp = max_hp
	contact_dmg = float(boss_data["dmg"]) * mult
	move_speed = float(boss_data["speed"])
	xp_reward = int(round(float(boss_data["xp"]) * mult))
	gold_range = boss_data["gold"].duplicate()
	aggro_radius = 170.0
	leash_radius = 400.0
	base_scale = 1.0
	attack_cd = 1.5


func _build_sprite() -> void:
	sprite.sprite_frames = Pix.boss_frames(boss_id)
	var t: Texture2D = sprite.sprite_frames.get_frame_texture("idle", 0)
	frame_h = float(t.get_height()) if t != null else 32.0


func _start_anim() -> void:
	sprite.position = Vector2(0, -frame_h / 2.0 + 3.0)
	sprite.play("idle")


func _ready() -> void:
	super()
	sprite.position = Vector2(0, -frame_h / 2.0 + 3.0)
	if shadow != null:
		shadow.scale = Vector2(body_radius * 2.4 / 16.0, body_radius * 2.4 / 16.0)
	bar.position = Vector2(0, -frame_h - 4.0)


func _animate() -> void:
	if state == State.DEAD:
		return
	var want := "walk" if velocity.length() > 8.0 else "idle"
	if sprite.animation == "hit" and sprite.is_playing():
		return
	if sprite.animation != want:
		sprite.play(want)
	if absf(facing.x) > 0.2:
		sprite.flip_h = facing.x < 0.0


# ================================================================ Controle
func _activate() -> void:
	active = true
	activated.emit(self)
	Audio.sfx("voice3", -2.0)
	Fx.shake_camera(get_player().camera, 3.0, 0.4)
	HUD.show_boss(display_name, hp / max_hp)
	Audio.play_music("boss")
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.18, 1.18), 0.12)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.2)


func _ai_boss(delta: float, dist: float, pp: Vector2) -> void:
	_bar_timer -= delta
	if _bar_timer <= 0.0:
		_bar_timer = 0.1
		HUD.update_boss(hp / max_hp)
	if not active:
		if dist < aggro_radius:
			_activate()
		return
	if busy:
		move_dir = forced_move
		if charging:
			_attack_overlap(18.0, 1.35)
		return
	facing = (pp - global_position).normalized()
	if dist > 34.0:
		move_dir = _toward(pp, delta) * (1.0 if phase == 1 else 1.3)
	if attack_cd <= 0.0:
		_start_pattern(pp)


func _start_pattern(pp: Vector2) -> void:
	busy = true
	var patterns: Array = boss_data["patterns"]
	var pick: String = patterns[randi() % patterns.size()]
	if pick == "summon" and _alive_minions() >= 4:
		pick = "burst"
	match pick:
		"slam":
			await _pat_slam()
		"charge":
			await _pat_charge(pp)
		"burst":
			await _pat_burst()
		"summon":
			await _pat_summon()
	if state == State.DEAD or not is_inside_tree():
		return
	busy = false
	charging = false
	forced_move = Vector2.ZERO
	attack_cd = (2.2 if phase == 1 else 1.3) * randf_range(0.85, 1.2)


func _wait(t: float) -> bool:
	await get_tree().create_timer(t).timeout
	return state != State.DEAD and is_inside_tree()


func _alive_minions() -> int:
	var n := 0
	for m in minions:
		if is_instance_valid(m) and (m as Enemy).state != State.DEAD:
			n += 1
	return n


# ================================================================= Padrões
func _pat_slam() -> void:
	var warn := Warn.circle(get_parent(), global_position, 50.0, 0.8)
	_flash_windup(0.8)
	Audio.sfx("alert2", -6.0)
	if not await _wait(0.8):
		return
	var center := global_position
	Fx.ring(get_parent(), center + Vector2(0, -2), 54.0, Color(1, 0.75, 0.4), 0.4, 2.0)
	Fx.fx(get_parent(), "rock", center + Vector2(0, -8), 1.2)
	Audio.sfx("explosion", -3.0)
	Fx.shake_camera(get_player().camera, 4.0, 0.3)
	var p := get_player()
	if p != null and not p.is_dead() and p.global_position.distance_to(center) <= 52.0:
		p.hurt(contact_dmg * 1.25, center, 160.0)
	if phase == 2:
		_ring_of_projectiles(8, randf() * TAU, 0.5)
	if not await _wait(0.35):
		return


func _pat_charge(pp: Vector2) -> void:
	var dir := (pp - global_position).normalized()
	var warn := Warn.line(get_parent(), global_position, dir, 130.0, 14.0, 0.75)
	_flash_windup(0.75)
	Audio.sfx("alert2", -6.0)
	facing = dir
	if not await _wait(0.75):
		return
	charging = true
	did_hit_this_attack = false
	forced_move = dir * 5.5
	Audio.sfx("swing3", -2.0)
	var t := 0.0
	while t < 0.6:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if state == State.DEAD or not is_inside_tree():
			return
		if t > 0.1 and get_real_velocity().length() < 25.0:
			# bateu na parede: atordoado e vulnerável
			charging = false
			forced_move = Vector2.ZERO
			Fx.float_text(get_parent(), "Zzz", global_position + Vector2(0, -frame_h), Color("ffe08a"), 2)
			Fx.shake_camera(get_player().camera, 3.0, 0.25)
			Audio.sfx("thud", -2.0)
			if not await _wait(1.2):
				return
			return
	charging = false
	forced_move = Vector2.ZERO
	if not await _wait(0.4):
		return


func _pat_burst() -> void:
	_flash_windup(0.5)
	if not await _wait(0.5):
		return
	var waves := 3 if phase == 1 else 5
	var count := 10 if phase == 1 else 14
	for i in waves:
		_ring_of_projectiles(count, float(i) * 0.4, 0.55)
		Audio.sfx("magic2", -6.0)
		if not await _wait(0.45 if phase == 1 else 0.32):
			return


func _pat_summon() -> void:
	_flash_windup(0.6)
	Audio.sfx("spirit")
	Fx.ring(get_parent(), global_position + Vector2(0, -4), 38.0, Color(0.8, 0.5, 1.0), 0.5, 2.0)
	if not await _wait(0.6):
		return
	var summon_id: String = boss_data.get("summon", "slime")
	var count := 3 if phase == 1 else 4
	for i in count:
		var a := TAU * float(i) / float(count) + randf() * 0.5
		var pos := global_position + Vector2(cos(a), sin(a)) * 34.0
		if dungeon != null and dungeon.has_method("is_floor_at") and not dungeon.is_floor_at(pos):
			pos = global_position
		var m := Enemy.spawn(get_parent(), summon_id, pos, maxi(1, floor_n - 2))
		m.state = Enemy.State.CHASE
		minions.append(m)
		Fx.fx(get_parent(), "smoke", pos + Vector2(0, -6), 0.8, 0.0, Color(0.8, 0.6, 1.0))
	if not await _wait(0.5):
		return


func _ring_of_projectiles(count: int, offset: float, dmg_mult: float) -> void:
	for i in count:
		var a := offset + TAU * float(i) / float(count)
		var dir := Vector2.from_angle(a)
		var p := Projectile.make(get_parent(), global_position + Vector2(0, -frame_h * 0.4) + dir * 8.0, dir, Projectile.Kind.PURPLE, contact_dmg * dmg_mult, false)
		p.speed = 62.0 + (14.0 if phase == 2 else 0.0)
		p.lifetime = 3.2
		p.radius = 4.5
		p.knockback = 80.0


func _flash_windup(duration: float) -> void:
	var tw := create_tween()
	var n := int(duration / 0.1)
	for i in n:
		tw.tween_property(sprite, "modulate", Color(2.0, 1.6, 1.6) if i % 2 == 0 else Color.WHITE, 0.05)
		tw.tween_interval(0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE if phase == 1 else Color(1.3, 0.8, 0.8), 0.05)


# ================================================================== Dano
func take_hit(amount: float, kb: Vector2, crit: bool, from: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD:
		return
	if not active:
		_activate()
	super(amount, kb, crit, from)
	if state == State.DEAD:
		return
	if sprite.sprite_frames.has_animation("hit") and not busy:
		sprite.play("hit")
	HUD.update_boss(hp / max_hp)
	if phase == 1 and hp <= max_hp * 0.5:
		phase = 2
		move_speed *= 1.2
		sprite.modulate = Color(1.3, 0.8, 0.8)
		Fx.float_text(get_parent(), "Enfurecido!", global_position + Vector2(0, -frame_h - 6), Color("ff6a5a"), 2, 22.0, 1.2)
		Fx.ring(get_parent(), global_position + Vector2(0, -6), 60.0, Color(1, 0.3, 0.2), 0.5, 2.0)
		Audio.sfx("voice3", -2.0)
		Fx.shake_camera(get_player().camera, 4.0, 0.4)


func _die() -> void:
	HUD.hide_boss()
	for m in minions:
		if is_instance_valid(m) and (m as Enemy).state != State.DEAD:
			(m as Enemy).take_hit(99999.0, Vector2.ZERO, false)
	var w := get_parent()
	Audio.jingle("boss_clear")
	for i in 5:
		var off := Vector2(randf_range(-18, 18), randf_range(-frame_h, 0))
		Fx.fx(w, "explosion", global_position + off, 1.3)
	Fx.shake_camera(get_player().camera, 5.0, 0.6)
	Game.hit_stop(0.12)
	super()


# ================================================================ Avisos
class Warn extends Node2D:
	var kind: String = "circle"
	var radius: float = 40.0
	var dir: Vector2 = Vector2.RIGHT
	var length: float = 100.0
	var width: float = 12.0
	var life: float = 0.8
	var age: float = 0.0

	static func circle(parent: Node, pos: Vector2, r: float, time: float) -> Warn:
		var w := Warn.new()
		w.kind = "circle"
		w.radius = r
		w.life = time
		w.position = pos
		w.z_index = -2
		parent.add_child(w)
		return w

	static func line(parent: Node, pos: Vector2, d: Vector2, l: float, wd: float, time: float) -> Warn:
		var w := Warn.new()
		w.kind = "line"
		w.dir = d
		w.length = l
		w.width = wd
		w.life = time
		w.position = pos
		w.z_index = -2
		parent.add_child(w)
		return w

	func _process(delta: float) -> void:
		age += delta
		if age >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := age / life
		var a := 0.18 + 0.25 * t
		var c := Color(1.0, 0.25, 0.2, a)
		if kind == "circle":
			draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * t), c)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1, 0.4, 0.3, 0.8), 1.0)
		else:
			var side := dir.orthogonal() * width * 0.5
			var pts := PackedVector2Array([-side, side, dir * length + side, dir * length - side])
			draw_colored_polygon(pts, c)
