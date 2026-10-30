class_name NPC
extends CharacterBody2D

## Aldeões e animais da cidade. Modos:
##  static : fica parado, vira para o jogador e solta falas/emotes quando ele chega perto
##  wander : passeia entre pontos da estrada
##  animal : bichinho de 2 quadros (galinha, gato, cachorro...) que anda e para

var sheet: String = "Villager"
var mode: String = "static"
var move_speed: float = 16.0
var wander_points: Array = []
var wander_radius: float = 140.0
var lines: Array = []
var greet_emotes: Array = [8, 11, 18, 27, 21]
var animal_flip_right: bool = true  # a folha original olha para a esquerda

var sprite: AnimatedSprite2D
var home: Vector2
var target: Vector2
var moving: bool = false
var wait_time: float = 1.0
var dir_name: String = "down"
var talk_cd: float = 3.0
var stuck_time: float = 0.0
var bubble: Control = null
var emote: Sprite2D = null


static func create(parent: Node, sheet_name: String, pos: Vector2, npc_mode: String = "static") -> NPC:
	var n := NPC.new()
	n.sheet = sheet_name
	n.mode = npc_mode
	n.position = pos
	parent.add_child(n)
	return n


func _ready() -> void:
	home = position
	collision_layer = 0
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 3.5
	col.shape = shape
	col.position = Vector2(0, -2)
	add_child(col)
	sprite = AnimatedSprite2D.new()
	if mode == "animal":
		sprite.sprite_frames = Pix.animal_frames(sheet)
		sprite.position = Vector2(0, -8)
		Fx.make_shadow(self, 9.0, 0.0)
		sprite.play("idle")
	else:
		sprite.sprite_frames = Pix.actor_frames("chars/%s.png" % sheet)
		sprite.position = Vector2(0, -9)
		Fx.make_shadow(self, 11.0, 0.0)
		sprite.play("idle_down")
	add_child(sprite)
	wait_time = randf_range(0.5, 3.0)
	talk_cd = randf_range(1.0, 4.0)


func _physics_process(delta: float) -> void:
	if mode == "static":
		_face_player_if_near()
	else:
		_wander(delta)
	_social(delta)


func _face_player_if_near() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var v := p.global_position - global_position
	if v.length() < 48.0:
		var dn := Pix.dir_name(v)
		if dn != dir_name:
			dir_name = dn
			sprite.play("idle_" + dn)


func _wander(delta: float) -> void:
	if moving:
		var v := target - global_position
		if v.length() < 3.0:
			moving = false
			velocity = Vector2.ZERO
			wait_time = randf_range(1.5, 5.0)
			_play_idle()
			return
		velocity = v.normalized() * move_speed
		move_and_slide()
		if get_real_velocity().length() < move_speed * 0.25:
			stuck_time += delta
			if stuck_time > 0.7:
				moving = false
				stuck_time = 0.0
				wait_time = 0.4
				_play_idle()
		else:
			stuck_time = 0.0
		_play_walk(v)
	else:
		wait_time -= delta
		if wait_time <= 0.0:
			_pick_target()


func _pick_target() -> void:
	var candidates: Array = []
	for pt in wander_points:
		if (pt as Vector2).distance_to(home) <= wander_radius:
			candidates.append(pt)
	if candidates.is_empty():
		target = home + Vector2(randf_range(-30, 30), randf_range(-20, 20))
	else:
		target = candidates[randi() % candidates.size()]
	moving = true


func _play_walk(v: Vector2) -> void:
	if mode == "animal":
		if sprite.animation != "walk":
			sprite.play("walk")
		if absf(v.x) > 0.5:
			sprite.flip_h = v.x > 0.0 if animal_flip_right else v.x < 0.0
	else:
		var dn := Pix.dir_name(v)
		var anim := "walk_" + dn
		if sprite.animation != anim:
			sprite.play(anim)
		dir_name = dn


func _play_idle() -> void:
	if mode == "animal":
		sprite.play("idle")
	else:
		sprite.play("idle_" + dir_name)


# --- fala e emotes quando o jogador chega perto
func _social(delta: float) -> void:
	talk_cd -= delta
	if mode == "animal" or talk_cd > 0.0:
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null or global_position.distance_to(p.global_position) > 36.0:
		return
	talk_cd = randf_range(9.0, 16.0)
	if not lines.is_empty() and randf() < 0.55:
		_say(lines[randi() % lines.size()])
	else:
		_show_emote(greet_emotes[randi() % greet_emotes.size()])


func _show_emote(index: int) -> void:
	if emote != null and is_instance_valid(emote):
		emote.queue_free()
	emote = Sprite2D.new()
	emote.texture = Pix.tex("ui/emote/emote%d.png" % index)
	emote.position = Vector2(0, -24)
	emote.z_index = 100
	emote.scale = Vector2(0.2, 0.2)
	add_child(emote)
	var tw := emote.create_tween()
	tw.tween_property(emote, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6)
	tw.tween_property(emote, "modulate:a", 0.0, 0.25)
	tw.tween_callback(emote.queue_free)


func _say(text: String) -> void:
	Audio.sfx("talk", -8.0, 0.2)
	if bubble != null and is_instance_valid(bubble):
		bubble.queue_free()
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Pix.font(1))
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color("2a1d2e"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fdeed4")
	sb.border_color = Color("2a1d2e")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.set_content_margin_all(2)
	l.add_theme_stylebox_override("normal", sb)
	l.z_index = 120
	l.position = Vector2(-text.length() * 3.0, -38)
	add_child(l)
	bubble = l
	var tw := l.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)
