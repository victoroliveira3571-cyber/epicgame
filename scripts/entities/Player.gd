class_name Player
extends CharacterBody2D

## Jogador: movimento em 4 direções, ataque (corpo a corpo em arco ou projétil com
## mira assistida), rolamento com invulnerabilidade, habilidade de classe,
## poção/comida e interação com [E]. Controlado pelas ações do InputMap (Game.gd).

signal attacked
signal skill_used(cooldown: float)
signal dodged(cooldown: float)

enum State { NORMAL, DODGE, SKILL, DEAD }

const BODY_RADIUS := 4.5
const DODGE_TIME := 0.22
const DODGE_SPEED := 190.0
const DODGE_COOLDOWN := 0.75
const INVULN_AFTER_HIT := 0.55
const ACCEL := 900.0
const FRICTION := 1100.0
const ATTACK_CD := {"sword": 0.36, "dagger": 0.26, "staff": 0.5, "bow": 0.4}
const MELEE_REACH := {"sword": 27.0, "dagger": 22.0}
const MELEE_ARC := {"sword": 115.0, "dagger": 95.0}
const CAMERA_ZOOM := 3.0

var state: int = State.NORMAL
var facing: Vector2 = Vector2.DOWN
var invuln: float = 0.0
var attack_cd_left: float = 0.0
var dodge_cd_left: float = 0.0
var skill_cd_left: float = 0.0
var slot_cd_left: Dictionary = {"skill2": 0.0, "skill3": 0.0, "skill_book": 0.0}   # recarga das habilidades R, X e da magia do livro (Z)
var combo: int = 0
var combo_timer: float = 0.0
var swing_time: float = 0.0
var dodge_time_left: float = 0.0
var dodge_dir: Vector2 = Vector2.ZERO
var knock: Vector2 = Vector2.ZERO
var move_vel: Vector2 = Vector2.ZERO
var skill_lock: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var interact_target: Interactable = null
var _prompt_timer: float = 0.0
var _last_prompt: String = "<none>"
var _step_timer: float = 0.0
var _ghost_timer: float = 0.0
var _anim_lock: float = 0.0
var _attack_speed: float = 1.0

var sprite: LpcActor
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var camera: Camera2D
var shadow: Sprite2D
var aura_fx: AnimatedSprite2D = null
var world: Node = null


static func spawn(parent: Node, pos: Vector2) -> Player:
	var p := Player.new()
	p.position = pos
	parent.add_child(p)
	p.world = parent
	return p


func _ready() -> void:
	add_to_group("player")
	add_to_group("speaker_heroi")
	world = get_parent()
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = BODY_RADIUS
	col.shape = shape
	col.position = Vector2(0, -3)
	add_child(col)
	shadow = Fx.make_shadow(self, 13.0, 0.0)
	sprite = LpcActor.make(self, Looks.hero(), true)
	sprite.play("idle_down")
	weapon_pivot = Node2D.new()
	weapon_pivot.position = Vector2(0, -8)
	weapon_pivot.visible = false
	weapon_pivot.z_index = 1
	add_child(weapon_pivot)
	weapon_sprite = Sprite2D.new()
	weapon_sprite.centered = true
	weapon_pivot.add_child(weapon_sprite)
	camera = Camera2D.new()
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	camera.position = Vector2(0, -12)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 9.0
	add_child(camera)
	camera.make_current()
	GameState.player_died.connect(_on_died)
	GameState.stats_changed.connect(_refresh_equipment_visual)
	_refresh_equipment_visual()
	Pet.attach_to.call_deferred(self)


## Folha do personagem: a da classe ou, antes do registro na Guilda, a de aprendiz.
func _sheet_path() -> String:
	if GameState.has_chosen_class():
		return "chars/%s.png" % Data.CLASSES[GameState.player_class]["sheet"]
	return "chars/Villager5.png"


func refresh_sheet() -> void:
	sprite.refresh(Looks.hero())
	sprite.play("idle_" + Pix.dir_name(facing))


func set_camera_limits(rect: Rect2) -> void:
	camera.limit_left = int(rect.position.x)
	camera.limit_top = int(rect.position.y)
	camera.limit_right = int(rect.end.x)
	camera.limit_bottom = int(rect.end.y)


func _refresh_equipment_visual() -> void:
	# a arma e a armadura fazem parte do visual LPC (Looks.hero), montado de novo quando mudam
	weapon_sprite.texture = null
	if sprite != null:
		var lk := Looks.hero()
		if LpcW.look_key(lk, "full") != LpcW.look_key(sprite.look, "full"):
			sprite.refresh(lk)


# ====================================================================== Loop
var _step_t: float = 0.0


## Som da magia de explosão: relâmpago, magia forte (várias explosões ou dano alto) ou fogo.
func _blast_sound(sk: Dictionary) -> String:
	if int(sk.get("repeat", 1)) > 1 or float(sk.get("mult", 1.0)) >= 3.0:
		return "magia_forte"
	return "magia_raio" if str(sk.get("fx", "")) == "thunder" else "magia_fogo"


## Passos do herói (andando, não rolando): o som segue o lugar. Na floresta, a zona escolhe
## entre grama e árvores (Audio.forest_step, ajustado por Forest._check_zone).
func _footsteps(delta: float, speed_now: float) -> void:
	if speed_now < 40.0:
		_step_t = 0.0
		return
	_step_t -= delta
	if _step_t > 0.0:
		return
	_step_t = 0.42 * (120.0 / maxf(speed_now, 60.0))
	var id := "passos_heroi"
	match HUD.scene_kind:
		"dungeon":
			id = "passos_masmorra"
		"forest":
			id = Audio.forest_step
		"interior":
			id = "passos_interior"
	Audio.novo(id, -10.0, 0.06)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		return
	_tick_timers(delta)
	var locked := Game.input_locked or get_tree().paused
	var input := Vector2.ZERO if locked else Game.move_vector()
	var speed := GameState.stat("speed")

	match state:
		State.NORMAL:
			var slow := 0.55 if swing_time > 0.0 else 1.0
			var target := input * speed * slow
			if input.length() > 0.1:
				move_vel = move_vel.move_toward(target, ACCEL * delta)
				facing = input.normalized() if input.length() > 0.5 else facing
			else:
				move_vel = move_vel.move_toward(Vector2.ZERO, FRICTION * delta)
			velocity = move_vel + knock
			knock = knock.move_toward(Vector2.ZERO, 600.0 * delta)
			move_and_slide()
			# só anda quando há comando de movimento: a inércia (move_vel) ainda alta ao parar não conta
			_footsteps(delta, move_vel.length() if input.length() > 0.1 else 0.0)
			if not locked:
				_handle_actions()
		State.DODGE:
			velocity = dodge_dir * DODGE_SPEED
			move_and_slide()
			_ghost_timer -= delta
			if _ghost_timer <= 0.0:
				_ghost_timer = 0.035
				_spawn_ghost()
			dodge_time_left -= delta
			if dodge_time_left <= 0.0:
				state = State.NORMAL
				move_vel = dodge_dir * speed * 0.6
		State.SKILL:
			velocity = dash_dir
			move_and_slide()
			skill_lock -= delta
			if skill_lock <= 0.0:
				state = State.NORMAL
				dash_dir = Vector2.ZERO
				move_vel = Vector2.ZERO
	_update_animation(input)
	_update_interaction(delta, locked)


func _tick_timers(delta: float) -> void:
	invuln = maxf(invuln - delta, 0.0)
	attack_cd_left = maxf(attack_cd_left - delta, 0.0)
	dodge_cd_left = maxf(dodge_cd_left - delta, 0.0)
	skill_cd_left = maxf(skill_cd_left - delta, 0.0)
	for k in slot_cd_left:
		slot_cd_left[k] = maxf(float(slot_cd_left[k]) - delta, 0.0)
	swing_time = maxf(swing_time - delta, 0.0)
	_anim_lock = maxf(_anim_lock - delta, 0.0)
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	# pisca durante a invulnerabilidade de dano
	if invuln > 0.0 and state != State.DODGE:
		sprite.modulate.a = 0.45 if int(invuln * 18.0) % 2 == 0 else 1.0
	elif state != State.DODGE:
		sprite.modulate.a = 1.0
	if GameState.hunger <= 0 and invuln <= 0.0:
		sprite.modulate = Color(1.0, 0.7, 0.7, sprite.modulate.a)


func _handle_actions() -> void:
	if not GameState.has_chosen_class():
		return
	if Input.is_action_just_pressed("dodge") and dodge_cd_left <= 0.0:
		_start_dodge()
		return
	if Input.is_action_just_pressed("skill") and skill_cd_left <= 0.0:
		_cast_skill()
		return
	for slot in slot_cd_left:
		if Input.is_action_just_pressed(slot) and float(slot_cd_left[slot]) <= 0.0 and GameState.slot_skill(slot) != "":
			_cast_slot(slot)
			return
	if Input.is_action_pressed("attack") and attack_cd_left <= 0.0:
		_attack()
	if Input.is_action_just_pressed("potion"):
		_use_quick("potion")
	if Input.is_action_just_pressed("eat"):
		_use_quick("food")


func _update_animation(input: Vector2) -> void:
	var dn := Pix.dir_name(facing)
	var moving := input.length() > 0.1 and state == State.NORMAL
	var anim := ""
	if _anim_lock > 0.0:
		anim = sprite.base_anim() + "_" + dn
	elif state == State.DODGE:
		anim = "walk_" + dn
	elif moving:
		anim = "walk_" + dn
	else:
		anim = "idle_" + dn
	sprite.speed_scale = 2.4 if state == State.DODGE else (_attack_speed if _anim_lock > 0.0 else 1.0)
	if sprite.animation != anim:
		sprite.play(anim)
	if moving:
		_step_timer -= get_physics_process_delta_time()
		if _step_timer <= 0.0:
			_step_timer = 0.26
			var puff := Fx.fx(world, "smoke", global_position + Vector2(0, -1), 0.4, 0.0, Color(1, 1, 1, 0.35))
			if puff != null:
				puff.z_index = 0


# ===================================================================== Ataque
func _roll_damage(mult: float) -> Array:
	var st := GameState.get_stats()
	var base: float = float(st["atk"]) * mult * randf_range(0.9, 1.1)
	var is_crit := randf() * 100.0 < float(st["crit"])
	if is_crit:
		base *= float(st["crit_dmg"])
	return [maxf(1.0, base), is_crit]


func _family() -> String:
	return Data.CLASSES.get(GameState.player_class, {}).get("weapon", "sword")


func _attack() -> void:
	var family := _family()
	attack_cd_left = float(ATTACK_CD.get(family, 0.38))
	combo_timer = 0.7
	combo += 1
	var heavy := combo >= 3
	if heavy:
		combo = 0
	swing_time = 0.16
	_play_attack_anim(family, heavy)
	attacked.emit()
	if Data.CLASSES[GameState.player_class]["ranged"]:
		Audio.sfx("swing3" if heavy else ("swing1" if combo % 2 == 1 else "swing2"), -4.0)
	else:
		Audio.novo("ataque_espada", -4.0)
	if Data.CLASSES[GameState.player_class]["ranged"]:
		_shoot(heavy)
	else:
		_melee(family, heavy)


func _melee(family: String, heavy: bool) -> void:
	var reach: float = float(MELEE_REACH.get(family, 26.0)) * (1.25 if heavy else 1.0)
	var arc: float = float(MELEE_ARC.get(family, 110.0)) * (1.2 if heavy else 1.0)
	var dir := facing.normalized()
	# pequeno impulso para frente (sensação de peso)
	knock += dir * (85.0 if heavy else 45.0)
	_swing_visual(dir, heavy)
	var fx_name := "slash2" if heavy else "slash"
	var fx_pos := global_position + Vector2(0, -13) + dir * (14.0 if family == "sword" else 11.0)
	var fx_node := Fx.fx(world, fx_name, fx_pos, 1.0 if not heavy else 1.35, dir.angle(), Color(1, 1, 1, 0.95))
	if fx_node != null and combo % 2 == 0 and not heavy:
		fx_node.flip_v = true
	await get_tree().create_timer(0.06).timeout
	if state == State.DEAD:
		return
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("npc_hit"):
		if not is_instance_valid(e) or not e.has_method("take_hit"):
			continue
		if e.has_method("is_targetable") and not e.is_targetable():
			continue
		var v: Vector2 = e.global_position + Vector2(0, -4) - (global_position + Vector2(0, -6))
		if v.length() > reach + float(e.get("body_radius")):
			continue
		if absf(dir.angle_to(v)) > deg_to_rad(arc * 0.5) and v.length() > float(e.get("body_radius")) + 6.0:
			continue
		var roll := _roll_damage(1.35 if heavy else 1.0)
		e.take_hit(roll[0], v.normalized() * (130.0 if heavy else 80.0), roll[1], global_position)
		hit_any = true
	if hit_any:
		Fx.shake_camera(camera, 1.5 if heavy else 0.8, 0.12)
		if heavy:
			Game.hit_stop(0.05)


## Animação LPC do golpe da classe, ajustada para caber no tempo de recarga do ataque.
func _play_attack_anim(family: String, heavy: bool) -> void:
	var base := LpcW.weapon_anim(str(sprite.look.get("weapon", family)))
	if family == "dagger" and heavy:
		base = "thrust"
	var cd := float(ATTACK_CD.get(family, 0.38))
	var length := sprite.anim_length(base)
	_attack_speed = maxf(length / maxf(cd * 0.92, 0.1), 1.0)
	_anim_lock = length / _attack_speed
	sprite.play(base + "_" + Pix.dir_name(facing), true)


func _swing_visual(dir: Vector2, heavy: bool) -> void:
	if weapon_sprite.texture == null:
		return
	weapon_pivot.visible = true
	var base := dir.angle() + PI / 2.0
	var sweep := deg_to_rad(95.0 if heavy else 75.0)
	var flip := -1.0 if combo % 2 == 0 else 1.0
	weapon_sprite.position = Vector2(0, -9)
	weapon_pivot.rotation = base - sweep * flip
	var tw := create_tween()
	tw.tween_property(weapon_pivot, "rotation", base + sweep * flip, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: weapon_pivot.visible = false)


func _best_target(max_dist: float, cone_deg: float) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	var origin := global_position + Vector2(0, -6)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e):
			continue
		if e.has_method("is_targetable") and not e.is_targetable():
			continue
		var v: Vector2 = e.global_position + Vector2(0, -4) - origin
		var d := v.length()
		if d > max_dist:
			continue
		var ang := absf(facing.angle_to(v))
		if ang > deg_to_rad(cone_deg):
			continue
		var score := d + ang * 70.0
		if score < best_score:
			best_score = score
			best = e
	return best


func _aim_direction() -> Vector2:
	var t := _best_target(230.0, 60.0)
	if t != null:
		return ((t.global_position + Vector2(0, -4)) - (global_position + Vector2(0, -6))).normalized()
	return facing.normalized()


func _shoot(heavy: bool) -> void:
	var dir := _aim_direction()
	facing = dir
	var is_mage: bool = GameState.player_class == "mago"
	var roll := _roll_damage(1.3 if heavy else 1.0)
	var origin := global_position + Vector2(0, -14) + dir * 8.0
	var p := Projectile.make(world, origin, dir, Projectile.Kind.ORB if is_mage else Projectile.Kind.ARROW, roll[0], true)
	p.crit = roll[1]
	p.speed = 190.0 if is_mage else 250.0
	p.lifetime = 1.0 if is_mage else 1.1
	p.pierce = 1 if is_mage else 0
	p.knockback = 70.0
	p.radius = 4.5
	if is_mage:
		Audio.novo("ataque_mago", -4.0)
	else:
		Audio.sfx("launch", -2.0)
	knock -= dir * 25.0
	_swing_visual(dir, false)


# ===================================================================== Rolamento
func _start_dodge() -> void:
	var input := Game.move_vector()
	dodge_dir = input.normalized() if input.length() > 0.1 else facing.normalized()
	facing = dodge_dir
	state = State.DODGE
	dodge_time_left = DODGE_TIME
	dodge_cd_left = DODGE_COOLDOWN
	invuln = DODGE_TIME + 0.06
	_ghost_timer = 0.0
	knock = Vector2.ZERO
	Audio.sfx2("whoosh", -6.0, 0.12)
	dodged.emit(DODGE_COOLDOWN)
	Fx.fx(world, "smoke", global_position + Vector2(0, -2), 0.7, 0.0, Color(1, 1, 1, 0.6))


func _spawn_ghost() -> void:
	var tex: Texture2D = sprite.snapshot()
	if tex == null:
		return
	var g := Sprite2D.new()
	g.texture = tex
	g.centered = false
	g.scale = sprite.sprite.scale
	g.offset = sprite.sprite.offset
	g.global_position = sprite.global_position
	g.modulate = Color(0.6, 0.8, 1.0, 0.55)
	g.z_index = -1
	world.add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)


func is_invulnerable() -> bool:
	return invuln > 0.0 or state == State.DODGE or state == State.DEAD


# ================================================================== Habilidades
func _cast_skill() -> void:
	var skill_id: String = Data.CLASSES[GameState.player_class]["skill"]
	var cd: float = GameState.skill_cooldown("skill")
	var pw: float = GameState.skill_power("skill")   # maestria do nível 50
	skill_cd_left = cd
	skill_used.emit(cd)
	var skill_anim: String = {"giro": "slash", "luz": "spellcast", "sombra": "thrust", "muralha": "spellcast",
		"meteoro": "thrust", "chuva": "shoot"}.get(skill_id, "spellcast")
	_attack_speed = 1.5
	_anim_lock = sprite.anim_length(skill_anim) / _attack_speed
	sprite.play(skill_anim + "_" + Pix.dir_name(facing), true)
	var center := global_position + Vector2(0, -10)
	match skill_id:
		"giro":
			Audio.sfx("swing_combo", -2.0)
			Fx.fx(world, "circular", center, 1.7, 0.0, Color(1, 0.95, 0.8))
			Fx.ring(world, center, 30.0, Color(1, 0.9, 0.6), 0.25)
			_area_damage(center, 30.0, 1.8 * pw, 140.0)
			Fx.shake_camera(camera, 2.0, 0.15)
			invuln = maxf(invuln, 0.15)
		"luz":
			Audio.novo("magia_cura", -3.0)
			Fx.fx(world, "aura", center + Vector2(0, -2), 1.8, 0.0, Color(1, 0.95, 0.6))
			Fx.ring(world, center, 42.0, Color(1, 0.95, 0.6), 0.4)
			GameState.heal(int(GameState.get_max_hp() * 0.3))
			Fx.float_text(world, "+%d" % int(GameState.get_max_hp() * 0.3), center + Vector2(0, -14), Color("7ef08a"), 8)
			_area_damage(center, 42.0, 1.2 * pw, 70.0)
		"sombra":
			Audio.sfx("spirit")
			var dir := facing.normalized()
			state = State.SKILL
			dash_dir = dir * 330.0
			skill_lock = 0.17
			invuln = 0.3
			Fx.fx(world, "smoke", global_position + Vector2(0, -4), 1.0, 0.0, Color(0.5, 0.4, 0.7, 0.8))
			_dash_damage(dir, 2.2 * pw)
		"muralha":
			Audio.sfx("magic2")
			GameState.add_buff("muralha", 4.0)
			Fx.fx(world, "shield", center, 1.5, 0.0, Color(0.7, 0.85, 1.0))
			Fx.ring(world, center, 36.0, Color(0.6, 0.8, 1.0), 0.3)
			_area_damage(center, 34.0, 0.6 * pw, 180.0)
		"meteoro":
			var t := _best_target(190.0, 70.0)
			var target_pos: Vector2 = (t.global_position + Vector2(0, -4)) if t != null else (center + facing.normalized() * 70.0)
			Audio.sfx("magic3")
			var warn := Fx.fx(world, "circle_o", target_pos, 1.4, 0.0, Color(1, 0.6, 0.4, 0.9))
			await get_tree().create_timer(0.32).timeout
			if state == State.DEAD:
				return
			Audio.sfx("explosion", -2.0)
			Fx.fx(world, "explosion", target_pos + Vector2(0, -6), 1.6)
			Fx.shake_camera(camera, 3.0, 0.2)
			_area_damage(target_pos, 36.0, 2.6 * pw, 160.0)
		"chuva":
			Audio.sfx("launch")
			var base_dir := _aim_direction()
			facing = base_dir
			for i in 7:
				var a := deg_to_rad(-42.0 + 14.0 * i)
				var roll := _roll_damage(1.0 * pw)
				var p := Projectile.make(world, global_position + Vector2(0, -14) + base_dir * 6.0, base_dir.rotated(a), Projectile.Kind.ARROW, roll[0], true)
				p.crit = roll[1]
				p.speed = 260.0
				p.lifetime = 0.9
				p.knockback = 60.0
			_swing_visual(base_dir, false)


## Habilidades liberadas pela progressão (R no nível 10, X no 30): o comportamento vem de
## Data.SKILLS (kind nova/blast/dash/fan/buff) para balancear sem mexer aqui.
func _cast_slot(slot: String) -> void:
	var id := GameState.slot_skill(slot)
	var sk: Dictionary = Data.SKILLS[id]
	var pw := GameState.skill_power(slot)
	var cd := GameState.skill_cooldown(slot)
	slot_cd_left[slot] = cd
	var anim := str(sk.get("anim", "spellcast"))
	_attack_speed = 1.5
	_anim_lock = sprite.anim_length(anim) / _attack_speed
	sprite.play(anim + "_" + Pix.dir_name(facing), true)
	var center := global_position + Vector2(0, -10)
	var col: Color = sk.get("color", Color.WHITE)
	var mult := float(sk.get("mult", 1.0)) * pw
	if sk.has("buff"):
		GameState.add_buff(str(sk["buff"]), float(sk.get("buff_time", 6.0)))
	match str(sk.get("kind", "")):
		"nova":
			Audio.sfx("swing_combo" if anim == "slash" else "magic2", -2.0)
			if sk.has("fx"):
				Fx.fx(world, str(sk["fx"]), center, 1.7, 0.0, col)
			Fx.ring(world, center, float(sk["radius"]), col, 0.3)
			_area_damage(center, float(sk["radius"]), mult, float(sk.get("kb", 100.0)))
			Fx.shake_camera(camera, 2.0, 0.15)
			invuln = maxf(invuln, float(sk.get("invuln", 0.0)))
		"blast":
			var t := _best_target(190.0, 70.0)
			var aim: Vector2 = (t.global_position + Vector2(0, -4)) if t != null else (center + facing.normalized() * float(sk.get("dist", 60.0)))
			Audio.novo(_blast_sound(sk), -3.0)
			for i in int(sk.get("repeat", 1)):
				var at := aim + (Vector2(randf_range(-28.0, 28.0), randf_range(-18.0, 18.0)) if i > 0 else Vector2.ZERO)
				Fx.fx(world, "circle_o", at, 1.2, 0.0, Color(col, 0.9))
				await get_tree().create_timer(float(sk.get("delay", 0.2))).timeout
				if state == State.DEAD or not is_inside_tree():
					return
				Audio.sfx("explosion", -9.0)
				Fx.fx(world, str(sk.get("fx", "explosion")), at + Vector2(0, -6), 1.5, 0.0, col)
				Fx.shake_camera(camera, 2.5, 0.15)
				_area_damage(at, float(sk["radius"]), mult, float(sk.get("kb", 100.0)))
		"dash":
			var spd := float(sk.get("speed", 300.0))
			var dir := facing.normalized() * signf(spd)
			Audio.sfx("spirit")
			state = State.SKILL
			dash_dir = dir * absf(spd)
			skill_lock = 0.17
			invuln = maxf(invuln, 0.35)
			Fx.fx(world, "smoke", global_position + Vector2(0, -4), 1.0, 0.0, Color(0.8, 0.8, 0.9, 0.8))
			if mult > 0.0:
				_dash_damage(dir, mult)
		"fan":
			Audio.sfx("launch")
			var base_dir := _aim_direction()
			facing = base_dir
			var n := int(sk.get("count", 1))
			var spread := float(sk.get("spread", 0.0))
			for i in n:
				var a := deg_to_rad(-spread / 2.0 + (spread * i / float(n - 1) if n > 1 else spread / 2.0))
				var roll := _roll_damage(mult)
				var kind: int = Projectile.Kind.get(str(sk.get("proj", "ARROW")), Projectile.Kind.ARROW)
				var p := Projectile.make(world, global_position + Vector2(0, -14) + base_dir * 6.0, base_dir.rotated(a), kind, roll[0], true)
				p.crit = roll[1]
				p.speed = float(sk.get("speed", 260.0))
				p.lifetime = float(sk.get("range", 0.8))
				p.pierce = int(sk.get("pierce", 0))
				p.knockback = 60.0
			_swing_visual(base_dir, false)
		"buff":
			if sk.has("heal_pct"):
				Audio.novo("magia_cura", -3.0)
			else:
				Audio.sfx("magic2")
			Fx.fx(world, str(sk.get("fx", "aura")), center, 1.5, 0.0, col)
			Fx.ring(world, center, 36.0, col, 0.35)
			if sk.has("heal_pct"):
				var amount := int(GameState.get_max_hp() * float(sk["heal_pct"]))
				GameState.heal(amount)
				Fx.float_text(world, "+%d" % amount, center + Vector2(0, -14), Color("7ef08a"), 8)


func _area_damage(center: Vector2, radius: float, mult: float, kb: float) -> void:
	var any := false
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or not e.has_method("take_hit"):
			continue
		if e.has_method("is_targetable") and not e.is_targetable():
			continue
		var v: Vector2 = e.global_position + Vector2(0, -4) - center
		if v.length() <= radius + float(e.get("body_radius")):
			var roll := _roll_damage(mult)
			e.take_hit(roll[0], v.normalized() * kb, roll[1], global_position)
			any = true
	if any:
		Game.hit_stop(0.04)


func _dash_damage(dir: Vector2, mult: float = 2.2) -> void:
	var hit: Dictionary = {}
	var steps := 7
	for i in steps:
		await get_tree().create_timer(0.025).timeout
		if state == State.DEAD:
			return
		for e in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(e) or hit.has(e.get_instance_id()) or not e.has_method("take_hit"):
				continue
			if e.has_method("is_targetable") and not e.is_targetable():
				continue
			if global_position.distance_to(e.global_position) <= 16.0 + float(e.get("body_radius")):
				hit[e.get_instance_id()] = true
				var roll := _roll_damage(mult)
				e.take_hit(roll[0], dir * 100.0, roll[1], global_position)
				Fx.fx(world, "cutx", e.global_position + Vector2(0, -6), 1.0)
				Game.hit_stop(0.04)


# ==================================================================== Consumíveis
func _use_quick(kind: String) -> void:
	var item_id := GameState.quick_potion() if kind == "potion" else GameState.quick_food()
	if item_id == "":
		Fx.float_text(world, "Sem %s" % ("poções" if kind == "potion" else "comida"), global_position + Vector2(0, -36), Color("ff9a8a"))
		Audio.sfx("ui_error", -4.0)
		return
	var before := GameState.hp
	if GameState.use_item(item_id):
		var it: Dictionary = Data.get_item(item_id)
		if kind == "potion":
			Audio.novo("pocao", -2.0)
			Fx.fx(world, "aura", global_position + Vector2(0, -14), 1.2, 0.0, Color(0.6, 1, 0.7))
			Fx.float_text(world, "+%d" % (GameState.hp - before), global_position + Vector2(0, -36), Color("7ef08a"), 8)
		else:
			Audio.novo("comida", -4.0)
			Fx.fx(world, "boost", global_position + Vector2(0, -16), 0.9, 0.0, Color(1, 0.9, 0.6))
			Fx.float_text(world, "Fome +%d" % int(it.get("hunger", 0)), global_position + Vector2(0, -36), Color("ffcf6a"), 8)
			if it.has("buff"):
				GameState.bump("meals")
	else:
		Fx.float_text(world, "Vida cheia" if kind == "potion" else "Sem fome", global_position + Vector2(0, -36), Color("c9c4b8"))


# ======================================================================== Dano
## Retorna true se o dano foi aplicado.
func hurt(raw_damage: float, from_pos: Vector2, knockback_strength: float = 90.0) -> bool:
	if is_invulnerable():
		return false
	var amount := GameState.take_damage(raw_damage)
	invuln = INVULN_AFTER_HIT
	var away := (global_position - from_pos).normalized()
	if away == Vector2.ZERO:
		away = -facing
	knock += away * knockback_strength * 1.6
	Fx.flash(sprite, Color(2.4, 0.9, 0.9), 0.14)
	Fx.shake_camera(camera, 2.5, 0.22)
	Fx.float_text(world, "-%d" % amount, global_position + Vector2(0, -36), Color("ff6a5a"), 8)
	Fx.burst(world, global_position + Vector2(0, -14), Color(1, 0.35, 0.3), 5, 34.0, 0.3)
	Audio.sfx("hurt", -2.0)
	Game.hit_stop(0.05)
	return true


func _on_died() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	weapon_pivot.visible = false
	sprite.hold_last = true
	sprite.speed_scale = 1.0
	sprite.play("hurt_down", true)
	sprite.modulate = Color.WHITE
	Audio.sfx("die")
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(0.6, 0.6, 0.7, 0.9), 0.5)


func is_dead() -> bool:
	return state == State.DEAD


# =================================================================== Interação
func _update_interaction(delta: float, locked: bool) -> void:
	_prompt_timer -= delta
	if _prompt_timer <= 0.0:
		_prompt_timer = 0.08
		interact_target = _find_interactable()
		var text := interact_target.get_prompt() if interact_target != null and not locked else ""
		if text != _last_prompt:
			_last_prompt = text
			HUD.set_prompt(text)
	if not locked and interact_target != null and Input.is_action_just_pressed("interact"):
		if is_instance_valid(interact_target) and interact_target.can_interact(self):
			interact_target.interact(self)


func _find_interactable() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	var p := global_position
	for n in get_tree().get_nodes_in_group("interactable"):
		var it := n as Interactable
		if it == null or not it.enabled:
			continue
		var d := p.distance_to(it.focus_point())
		if d <= it.interact_range and d < best_d:
			best_d = d
			best = it
	return best
