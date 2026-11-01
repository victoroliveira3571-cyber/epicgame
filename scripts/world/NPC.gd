class_name NPC
extends CharacterBody2D

## Aldeões e animais da cidade. Modos:
##  static : fica parado, vira para o jogador e solta falas/emotes quando ele chega perto
##  wander : passeia entre pontos da estrada
##  sit    : sentado (taverna, biblioteca); vira a cabeça e gesticula
##  animal : bichinho de 2 quadros (galinha, gato, cachorro...) que anda e para
## Pessoas usam o personagem LPC (Looks.of(sheet)); quem não tem look usa a folha antiga.
## Parados respiram, olham em volta e gesticulam; nos diálogos a DialogueBox os anima.

var sheet: String = "Villager"
var mode: String = "static"        # static | wander | sit | animal | chase | cutscene (v3.7: só o roteiro move)
var custom_look: Dictionary = {}   # v3.7: visual LPC próprio (criança do prólogo, colegas), no lugar de Looks
var move_speed: float = 16.0
var wander_points: Array = []
var wander_radius: float = 140.0
var lines: Array = []
var greet_emotes: Array = [8, 11, 18, 27, 21]
var animal_flip_right: bool = true  # a folha original olha para a esquerda

var sprite: Node2D               # LpcActor (pessoas) ou AnimatedSprite2D (animais)
var actor: LpcActor = null
var look_key: String = ""
var sit_dir: String = "down"
var _fidget: float = 4.0
var home: Vector2
var target: Vector2
var moving: bool = false
var wait_time: float = 1.0
var dir_name: String = "down"
var talk_cd: float = 3.0
var stuck_time: float = 0.0
var bubble: Control = null
var emote: Sprite2D = null
# --- agressão: moradores podem ser feridos (a lei cuida do resto, ver Law)
var hp: float = 40.0
var max_hp: float = 40.0
var body_radius: float = 5.0
var downed: bool = false
var is_police: bool = false
var retaliating: bool = false      # virou lutador hostil (floresta/masmorra)
var _hits_taken: int = 0
var _alarmed: bool = false
var _chase_say_cd: float = 0.0


static func create(parent: Node, sheet_name: String, pos: Vector2, npc_mode: String = "static", look_id: String = "") -> NPC:
	var n := NPC.new()
	n.sheet = sheet_name
	n.look_key = look_id
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
	if mode == "animal":
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = Pix.animal_frames(sheet)
		anim.position = Vector2(0, -8)
		Fx.make_shadow(self, 9.0, 0.0)
		anim.play("idle")
		sprite = anim
		add_child(sprite)
	elif not custom_look.is_empty():
		Fx.make_shadow(self, 11.0, 0.0)
		actor = LpcActor.make(self, custom_look, true)
		sprite = actor
		actor.play("idle_down")
	elif Looks.has(look_key if look_key != "" else sheet):
		Fx.make_shadow(self, 11.0, 0.0)
		actor = LpcActor.make(self, Looks.of(look_key if look_key != "" else sheet))
		sprite = actor
		if mode == "sit":
			actor.hold_last = true
			actor.play("sit_" + sit_dir)
		else:
			actor.play("idle_down")
	else:
		var anim2 := AnimatedSprite2D.new()
		anim2.sprite_frames = Pix.actor_frames("chars/%s.png" % sheet)
		anim2.position = Vector2(0, -9)
		Fx.make_shadow(self, 11.0, 0.0)
		anim2.play("idle_down")
		sprite = anim2
		add_child(sprite)
	wait_time = randf_range(0.5, 3.0)
	talk_cd = randf_range(1.0, 4.0)
	if mode != "animal":
		add_to_group("npc_hit")
		_add_street_chat.call_deferred()


## [E] "Conversar": gente comum conta uma história curta e uma frase motivacional (Street).
## Quem já tem "Falar com" (história, dono de loja) marca meta "has_talker" e fica de fora.
func _add_street_chat() -> void:
	if not is_inside_tree() or has_meta("has_talker") or is_police or mode in ["animal", "chase", "cutscene"]:
		return
	var p := StoryProp.make("Conversar", func(_me: StoryProp) -> void: Street.talk(self), null, 22.0, false)
	add_child(p)


## Passa a usar o visual de outro personagem (ex.: o morador vira o Osvaldo da história).
func use_look(key: String) -> void:
	if not Looks.has(key) or key == look_key:
		return
	look_key = key
	if actor != null:
		actor.refresh(Looks.of(key))


func _physics_process(delta: float) -> void:
	if talking or downed or mode == "cutscene":
		return
	if mode == "chase":
		_chase(delta)
		return
	if mode == "static":
		_face_player_if_near()
		_idle_life(delta)
	elif mode == "sit":
		_idle_life(delta)
	else:
		_wander(delta)
	_social(delta)


## Vida quando parado: olha para os lados, gesticula de vez em quando.
func _idle_life(delta: float) -> void:
	if actor == null:
		return
	_fidget -= delta
	if _fidget > 0.0:
		return
	_fidget = randf_range(4.0, 9.0)
	if mode == "sit":
		return
	var r := randf()
	if r < 0.35:
		actor.gesture()
	elif r < 0.7:
		var old := dir_name
		var side: String = ["left", "right"][randi() % 2]
		play_anim("idle_" + side)
		get_tree().create_timer(randf_range(0.8, 1.6)).timeout.connect(func() -> void:
			if is_instance_valid(self) and not talking:
				play_anim("idle_" + old))
	else:
		actor.nod()


## Durante uma conversa da história a DialogueBox controla o NPC (não anda nem vira sozinho).
var talking: bool = false


func play_anim(name: String) -> void:
	if actor != null:
		if mode == "sit" and not name.begins_with("sit"):
			return
		actor.play(name)
		dir_name = name.get_slice("_", 1) if name.contains("_") else dir_name
	elif sprite is AnimatedSprite2D:
		var a := sprite as AnimatedSprite2D
		if a.sprite_frames.has_animation(name):
			a.play(name)


func face(target: Vector2) -> void:
	var dn := Pix.dir_name(target - global_position)
	dir_name = dn
	if mode == "sit":
		return
	play_anim("idle_" + dn)


func _face_player_if_near() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var v := p.global_position - global_position
	if v.length() < 48.0:
		var dn := Pix.dir_name(v)
		if dn != dir_name:
			dir_name = dn
			play_anim("idle_" + dn)


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
		var a := sprite as AnimatedSprite2D
		if a.animation != "walk":
			a.play("walk")
		if absf(v.x) > 0.5:
			a.flip_h = v.x > 0.0 if animal_flip_right else v.x < 0.0
	else:
		var dn := Pix.dir_name(v)
		play_anim("walk_" + dn)
		dir_name = dn


func _play_idle() -> void:
	if mode == "animal":
		(sprite as AnimatedSprite2D).play("idle")
	else:
		play_anim("idle_" + dir_name)


# ================================================================== Agressão e lei
func is_targetable() -> bool:
	return not downed and not talking and not is_police and not retaliating and mode != "animal"


func take_hit(amount: float, kb: Vector2, _crit: bool, _from: Vector2 = Vector2.ZERO) -> void:
	if not is_targetable():
		return
	hp -= amount * 0.5
	_hits_taken += 1
	Fx.float_text(get_parent(), "%d" % int(round(amount * 0.5)), global_position + Vector2(randf_range(-4, 4), -34), Color("ffb0a0"), 1, 14.0)
	Fx.flash(actor if actor != null else sprite, Color(2.4, 1.2, 1.2), 0.1)
	Audio.sfx("hit1", -6.0)
	if actor != null:
		actor.shake()
	show_emote(7 if _hits_taken < 2 else 13)
	position += kb * 0.04
	var scene := get_tree().current_scene
	if scene != null and (scene.is_in_group("forest") or scene.is_in_group("dungeon")):
		_start_retaliation()
		return
	if hp <= 0.0:
		_go_down()
		Law.on_npc_downed(self)
	else:
		Law.on_npc_hurt(self)


## Desmaia (não morre): se regenera depois de um tempo.
func _go_down() -> void:
	downed = true
	remove_from_group("npc_hit")
	moving = false
	velocity = Vector2.ZERO
	if actor != null:
		actor.hold_last = true
		actor.play("hurt_down", true)
	elif sprite is AnimatedSprite2D:
		(sprite as AnimatedSprite2D).modulate = Color(1, 0.6, 0.6)
	get_tree().create_timer(20.0).timeout.connect(_regenerate)


func _regenerate() -> void:
	if not is_instance_valid(self):
		return
	downed = false
	hp = max_hp
	_hits_taken = 0
	_alarmed = false
	add_to_group("npc_hit")
	if actor != null:
		actor.hold_last = false
		actor.play("idle_down", true)
	elif sprite is AnimatedSprite2D:
		(sprite as AnimatedSprite2D).modulate = Color.WHITE
	show_emote(22)


## Floresta e masmorra: quem apanha revida de verdade (ArenaFighter hostil). Se cair, é homicídio.
func _start_retaliation() -> void:
	if retaliating:
		return
	retaliating = true
	remove_from_group("npc_hit")
	var opp := Arena.npc_opponent(Looks.of(look_key if look_key != "" else sheet), GameState.level)
	var f := ArenaFighter.spawn(get_parent(), opp, global_position)
	f.hostile_npc = true
	visible = false
	set_physics_process(false)
	HUD.show_toast("O morador revida! Se derrubá-lo, você será preso por homicídio (3 h de foco).", UI.C_BAD)
	f.begin()
	f.defeated.connect(func() -> void:
		Law.arrest("murder")
		get_tree().create_timer(25.0).timeout.connect(_regenerate_after_fight))
	f.tree_exited.connect(func() -> void:
		if is_instance_valid(self) and retaliating and not downed and f.state != ArenaFighter.State.DOWN:
			_regenerate_after_fight())


func _regenerate_after_fight() -> void:
	if not is_instance_valid(self):
		return
	retaliating = false
	visible = true
	set_physics_process(true)
	hp = max_hp
	_hits_taken = 0
	add_to_group("npc_hit")


# ================================================================== Polícia
## Guarda que persegue o jogador depois de uma agressão e o prende ao alcançá-lo.
func _chase(delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var v := p.global_position - global_position
	_chase_say_cd -= delta
	if v.length() < 14.0:
		set_physics_process(false)
		Law.arrest("assault" if not Law.wants_murder else "murder")
		return
	velocity = v.normalized() * 84.0
	move_and_slide()
	_play_walk(v)
	if _chase_say_cd <= 0.0:
		_chase_say_cd = 2.5
		_say("Alto lá! Em nome da lei!")


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
	show_emote(index)


func show_emote(index: int) -> void:
	if emote != null and is_instance_valid(emote):
		emote.queue_free()
	emote = Sprite2D.new()
	emote.texture = Pix.tex("ui/emote/emote%d.png" % index)
	emote.position = Vector2(0, -34 if actor != null else -24)
	emote.z_index = 100
	emote.scale = Vector2(0.2, 0.2)
	add_child(emote)
	var tw := emote.create_tween()
	tw.tween_property(emote, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6)
	tw.tween_property(emote, "modulate:a", 0.0, 0.25)
	tw.tween_callback(emote.queue_free)


func _say(text: String) -> void:
	Audio.novo("npc_som", -8.0, 0.1, 0.8)
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
	l.position = Vector2(-text.length() * 3.0, -46 if actor != null else -38)
	add_child(l)
	bubble = l
	var tw := l.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)
