class_name Ally
extends CharacterBody2D

## v3.7: colega que luta ao lado do herói (batalhas em grupo da Academia e patrulhas do Exército).
## Segue o herói; quando há monstro perto, vai até ele e ataca de tempos em tempos (corpo a corpo ou magia/flecha
## à distância). Os monstros continuam mirando só o herói: o aliado ajuda, não vira alvo nem morre.

const FOLLOW_DIST := 26.0
const ENGAGE_RADIUS := 150.0

var ally_id: String = "nina"
var display: String = ""
var kind: String = "melee"         # melee | ranged
var dmg_mult: float = 0.6          # fração do ataque do herói por golpe
var speed: float = 52.0
var actor: LpcActor
var offset: Vector2 = Vector2(-18, 10)
var _cd: float = 0.0
var _target: Enemy = null
var _scan: float = 0.0
var _label: Label


static func spawn(parent: Node, id: String, pos: Vector2, follow_offset: Vector2 = Vector2(-18, 10)) -> Ally:
	var a := Ally.new()
	a.ally_id = id
	a.position = pos
	a.offset = follow_offset
	parent.add_child(a)
	return a


## Visual LPC do colega (StoryV4.COLEGAS): look da bíblia (Looks) ou montado com as peças do guarda-roupa.
static func look_of(id: String) -> Dictionary:
	var d: Dictionary = StoryV4.COLEGAS.get(id, {})
	if d.has("look") and Looks.has(str(d["look"])):
		var lk: Dictionary = Looks.of(str(d["look"])).duplicate(true)
		if str(d.get("weapon", "")) != "":
			lk["weapon"] = str(d["weapon"])
		return lk
	var body := str(d.get("body", "male"))
	var lk2 := LpcW.default_look(body)
	lk2["hair_pal"] = str(d.get("hair_pal", "dark_brown"))
	var eq: Dictionary = lk2.get("equip", {})
	if d.has("hair"):
		eq["cabelo"] = str(d["hair"])
	if d.has("torso"):
		eq["torso"] = str(d["torso"])
		var cols: Dictionary = lk2.get("colors", {})
		cols[str(d["torso"])] = str(d.get("torso_color", "white"))
		lk2["colors"] = cols
	lk2["equip"] = eq
	lk2["weapon"] = str(d.get("weapon", ""))
	if d.has("gear"):
		lk2["gear"] = d["gear"]
	return lk2


func _ready() -> void:
	var d: Dictionary = StoryV4.COLEGAS.get(ally_id, {})
	display = str(d.get("name", ally_id))
	kind = str(d.get("kind", "melee"))
	dmg_mult = float(d.get("dmg", 0.6))
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 3.5
	col.shape = shape
	col.position = Vector2(0, -2)
	add_child(col)
	Fx.make_shadow(self, 11.0, 0.0)
	actor = LpcActor.make(self, look_of(ally_id), true)
	actor.play("idle_down")
	add_to_group("ally")
	add_to_group("speaker_" + ally_id)
	_label = Label.new()
	_label.text = display
	_label.add_theme_font_override("font", Pix.font(1))
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color("bfe8ff"))
	_label.add_theme_color_override("font_outline_color", Color("101828"))
	_label.add_theme_constant_override("outline_size", 3)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(80, 14)
	_label.position = Vector2(-40, -44)
	_label.scale = Vector2(0.5, 0.5)
	_label.position = Vector2(-20, -40)
	add_child(_label)


func _physics_process(delta: float) -> void:
	if Game.input_locked or get_tree().paused:
		velocity = Vector2.ZERO
		return
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	if pl == null:
		return
	_cd -= delta
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.3
		_target = _pick_target(pl)
	if _target != null and is_instance_valid(_target) and _target.state != Enemy.State.DEAD:
		var v := _target.global_position - global_position
		var reach := 18.0 if kind == "melee" else 90.0
		if v.length() > reach:
			_move(v.normalized() * speed)
		else:
			velocity = Vector2.ZERO
			_face(v)
			if _cd <= 0.0:
				_attack(_target, v)
		return
	# sem monstro: acompanha o herói
	var spot := pl.global_position + offset
	var w := spot - global_position
	if w.length() > FOLLOW_DIST * 0.6:
		_move(w.normalized() * minf(speed * (1.6 if w.length() > 80.0 else 1.0), w.length() * 4.0))
		if w.length() > 260.0:
			global_position = spot   # ficou para trás (porta, ponte): reaparece ao lado
	else:
		velocity = Vector2.ZERO
		if actor.base_anim() == "walk":
			actor.play("idle_" + actor.dir_name())


func _pick_target(pl: Node2D) -> Enemy:
	var best: Enemy = null
	var best_d := ENGAGE_RADIUS * ENGAGE_RADIUS
	for e in get_tree().get_nodes_in_group("enemy"):
		var en := e as Enemy
		if en == null or en.state == Enemy.State.DEAD:
			continue
		var d := en.global_position.distance_squared_to(pl.global_position)
		if d < best_d:
			best_d = d
			best = en
	return best


func _move(v: Vector2) -> void:
	velocity = v
	move_and_slide()
	_face(v)
	actor.play("walk_" + Pix.dir_name(v))


func _face(v: Vector2) -> void:
	if v.length() > 0.01 and actor.base_anim() != "walk":
		actor.play("idle_" + Pix.dir_name(v))


func _attack(target: Enemy, v: Vector2) -> void:
	_cd = 1.25 if kind == "melee" else 1.6
	var dn := Pix.dir_name(v)
	var w := str(StoryV4.COLEGAS.get(ally_id, {}).get("weapon", ""))
	var anim := "slash_" if kind == "melee" else ("shoot_" if w == "bow" else "spellcast_")
	actor.play(anim + dn, true)
	var dmg := maxf(2.0, float(GameState.stat("atk")) * dmg_mult)
	var hit_at := target.global_position + Vector2(0, -8)
	if kind == "ranged":
		Fx.ring(get_parent(), hit_at, 10.0, Color(0.7, 0.9, 1.0), 0.25, 1.5)
	else:
		Fx.burst(get_parent(), hit_at, Color(1, 0.95, 0.7), 4, 24.0, 0.2)
	target.take_hit(dmg, v.normalized() * 40.0, false, global_position)
