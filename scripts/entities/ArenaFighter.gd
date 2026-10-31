class_name ArenaFighter
extends CharacterBody2D

## Oponente da Arena: aventureiro LPC com arma, controlado pelo jogo. Corpo a corpo: aproxima,
## anda em volta, telegrafa o golpe (brilho + "!") e ataca; à distância: mantém distância e
## atira. Rola para o lado quando o jogador ataca perto (chance pela dificuldade).
## Fica no grupo "enemy" para os golpes do jogador o acertarem (take_hit).

signal defeated

enum State { WAIT, MOVE, WINDUP, ATTACK, RECOVER, DODGE, DOWN }

var opp: Dictionary = {}
var hp: float = 100.0
var max_hp: float = 100.0
var body_radius: float = 6.0
var state: int = State.WAIT
var actor: LpcActor
var player: Player
var _t: float = 0.0
var _strafe: float = 1.0
var _dodge_dir: Vector2 = Vector2.ZERO
var _knock: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.LEFT
var _shot_cd: float = 1.0


static func spawn(parent: Node, data: Dictionary, pos: Vector2) -> ArenaFighter:
	var f := ArenaFighter.new()
	f.opp = data
	f.position = pos
	parent.add_child(f)
	return f


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var col := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 4.5
	col.shape = sh
	col.position = Vector2(0, -3)
	add_child(col)
	Fx.make_shadow(self, 13.0, 0.0)
	actor = LpcActor.make(self, opp["look"], true)
	actor.play("combat_left")
	max_hp = float(opp["hp"])
	hp = max_hp
	_strafe = 1.0 if randf() < 0.5 else -1.0
	player = get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.attacked.connect(_on_player_attack)


func begin() -> void:
	state = State.MOVE
	_t = 0.0


func is_targetable() -> bool:
	return state != State.DOWN and state != State.WAIT


func _physics_process(delta: float) -> void:
	if state == State.WAIT or state == State.DOWN or player == null or not is_instance_valid(player):
		return
	_t += delta
	_shot_cd -= delta
	var to_p := player.global_position - global_position
	var dist := to_p.length()
	var dir := to_p / maxf(dist, 0.01)
	var vel := Vector2.ZERO
	var speed := float(opp["speed"])
	match state:
		State.MOVE:
			_facing = dir
			if opp["ranged"]:
				# arqueiro/mago: fica a 80-120 px e anda de lado
				var want := 100.0
				vel = dir * (speed if dist > want + 20.0 else (-speed * 0.9 if dist < want - 25.0 else 0.0))
				vel += dir.orthogonal() * _strafe * speed * 0.55
				if _shot_cd <= 0.0 and dist < 190.0:
					_start_windup(0.45)
			else:
				if dist > 26.0:
					vel = dir * speed
					if dist < 60.0:
						vel += dir.orthogonal() * _strafe * speed * 0.35
				else:
					vel = dir.orthogonal() * _strafe * speed * 0.4
					if _t > randf_range(0.15, 0.5) / float(opp["aggro"]):
						_start_windup(0.42 - float(opp["diff"]) * 0.06)
			if randf() < delta * 0.4:
				_strafe = -_strafe
			actor.play(("walk_" if vel.length() > 4.0 else "combat_") + Pix.dir_name(_facing))
		State.WINDUP:
			actor.play("combat_" + Pix.dir_name(_facing))
			if _t >= 0.0:
				_attack()
		State.ATTACK:
			pass
		State.RECOVER:
			if _t > 0.0:
				state = State.MOVE
				_t = 0.0
		State.DODGE:
			vel = _dodge_dir * 170.0
			if _t > 0.22:
				state = State.MOVE
				_t = 0.0
	velocity = vel + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()


func _start_windup(time: float) -> void:
	state = State.WINDUP
	_t = -time
	# aviso do golpe: brilho e "!" acima da cabeça
	Fx.flash(actor, Color(1.8, 1.6, 1.0), time)
	var e := Sprite2D.new()
	e.texture = Pix.tex("ui/emote/emote22.png")
	e.position = Vector2(0, -36)
	e.scale = Vector2(0.6, 0.6)
	e.z_index = 100
	add_child(e)
	var tw := e.create_tween()
	tw.tween_property(e, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(time)
	tw.tween_callback(e.queue_free)


func _attack() -> void:
	state = State.ATTACK
	var dn := Pix.dir_name(_facing)
	var w: String = opp["weapon"]
	var base := LpcW.weapon_anim(w)
	actor.speed_scale = 1.4
	actor.play(base + "_" + dn, true)
	var arena := get_parent()
	if opp["ranged"]:
		await get_tree().create_timer(0.22).timeout
		if state == State.DOWN:
			return
		var aim := (player.global_position + Vector2(0, -12) - (global_position + Vector2(0, -14))).normalized()
		var p := Projectile.make(arena, global_position + Vector2(0, -14) + aim * 8.0, aim,
			Projectile.Kind.ORB if w == "staff" else Projectile.Kind.ARROW, float(opp["dmg"]), false)
		p.speed = 150.0 if w == "staff" else 210.0
		p.lifetime = 1.4
		Audio.sfx("magic1" if w == "staff" else "launch", -6.0)
		_shot_cd = randf_range(1.1, 1.9) / float(opp["aggro"])
	else:
		Audio.sfx("swing1" if randf() < 0.5 else "swing2", -6.0)
		_knock += _facing * 60.0
		var reach := 30.0 if w == "spear" else 25.0
		Fx.fx(arena, "slash", global_position + Vector2(0, -13) + _facing * 14.0, 1.0, _facing.angle(), Color(1, 0.85, 0.8, 0.9))
		await get_tree().create_timer(0.08).timeout
		if state == State.DOWN:
			return
		var v := player.global_position - global_position
		if v.length() < reach + 6.0 and absf(_facing.angle_to(v)) < deg_to_rad(70.0):
			player.hurt(float(opp["dmg"]), global_position, 110.0)
	await get_tree().create_timer(0.25).timeout
	actor.speed_scale = 1.0
	if state == State.ATTACK:
		state = State.RECOVER
		_t = -randf_range(0.35, 0.8) / float(opp["aggro"])


func _on_player_attack() -> void:
	if state != State.MOVE or player == null:
		return
	if global_position.distance_to(player.global_position) > 46.0:
		return
	if randf() < float(opp["dodge"]):
		var away := (global_position - player.global_position).normalized()
		_dodge_dir = (away.orthogonal() * (_strafe) + away * 0.6).normalized()
		state = State.DODGE
		_t = 0.0
		Audio.sfx2("whoosh", -12.0, 0.15)
		Fx.fx(get_parent(), "smoke", global_position + Vector2(0, -2), 0.6, 0.0, Color(1, 1, 1, 0.5))


func take_hit(amount: float, kb: Vector2, crit: bool, _from: Vector2 = Vector2.ZERO) -> void:
	if not is_targetable():
		return
	if state == State.DODGE:
		Fx.float_text(get_parent(), "Esquivou!", global_position + Vector2(0, -36), Color("c9c4b8"))
		return
	hp -= amount
	_knock += kb * 0.8
	Fx.float_text(get_parent(), "%d%s" % [int(round(amount)), "!" if crit else ""], global_position + Vector2(randf_range(-4, 4), -34),
		Color("ffd84a") if crit else Color.WHITE, 2 if crit else 1, 16.0)
	Fx.flash(actor, Color(2.6, 1.0, 1.0), 0.1)
	Fx.fx(get_parent(), "spark", global_position + Vector2(0, -14), 0.7)
	Audio.sfx("hit_crit" if crit else ["hit1", "hit2", "hit3"][randi() % 3], -4.0)
	if crit:
		Audio.sfx2("impacto", -10.0, 0.1)
	HUD.update_boss(clampf(hp / max_hp, 0.0, 1.0))
	if state == State.WINDUP and crit:
		state = State.RECOVER
		_t = -0.3
	if hp <= 0.0:
		_go_down()


func _go_down() -> void:
	state = State.DOWN
	remove_from_group("enemy")
	actor.hold_last = true
	actor.speed_scale = 1.0
	actor.play("hurt_down", true)
	Audio.sfx2("impacto_grande", -8.0)
	Game.hit_stop(0.12)
	defeated.emit()


## Fim do duelo com derrota do jogador: o oponente comemora.
func celebrate() -> void:
	state = State.WAIT
	actor.play("emote_down", true)
	actor.hop(4.0)
