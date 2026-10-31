class_name Stage
extends Control

## Palco das conversas: quando um NPC da história, o dono de uma loja ou um chefe fala, a tela vira uma
## cena de lado (fundo pintado por StageArt, barras de cinema, luz e poeira) com o herói à esquerda e quem
## fala à direita, grandes e animados. Quem fala avança e gesticula; o outro escurece e acena. A caixa de
## diálogo (DialogueBox) continua por cima, por isso o palco fica logo abaixo dela no HUD.
##
## Uso (HUD.dialogue): Stage.wanted(lines) decide; HUD cria o palco antes da caixa e chama focus() a cada fala.

const W := 640.0
const H := 360.0
const SCALE := 4.4              # tamanho do personagem LPC na cena
const HERO_X := 176.0
const OTHER_X := 452.0
const FEET_Y := 238.0           # base dos pés (o chão pintado começa um pouco acima)

var setting: String = "home"
var t: float = 0.0
var bars: float = 0.0
var hero: Node2D = null
var other: Node2D = null
var other_id: String = ""
var _speaker: String = ""        # "" = ninguém (narração)
var _dim_hero: float = 1.0
var _dim_other: float = 1.0
var _closing: bool = false
var _flash: float = 0.0


## Só abre palco quando alguém da história/loja/chefe fala (não gente de rua, pets nem só o herói).
static func wanted(lines: Array) -> bool:
	for e in lines:
		if e is Dictionary:
			continue
		var who := str((e as Array)[0])
		if who.contains("@"):
			who = who.get_slice("@", 0)
		if who.contains(":"):
			who = who.get_slice(":", 1)
		if who in ["narr", "heroi", "", "espelho"] or who.begins_with("rua_") or Data.PETS.has(who):
			continue
		return true
	return false


## Cenário pela cena atual (e por quem fala: chefes têm cenário próprio).
static func pick_setting(tree: SceneTree, who: String) -> String:
	match who:
		"rei":
			return "throne"
		"sentinela":
			return "ruins"
		"espirito":
			return "forest_deep"
		"cavaleiro":
			return "dungeon"
		"bibliotecario":
			return "library"
	var scene := tree.current_scene
	if scene == null:
		return "home"
	if scene is Interior:
		match (scene as Interior).id:
			"restaurante", "casa_npc_1":
				return "inn"
			"guilda":
				return "guild"
			"biblioteca":
				return "library"
			"forja":
				return "forge"
			"loja":
				return "weapons"
			"arena":
				return "arena"
			"delegacia":
				return "jail"
			"laboratorio":
				return "lab"
			_:
				return "home"
	if scene.is_in_group("dungeon"):
		return "dungeon"
	if scene.is_in_group("forest"):
		match str(scene.get("_zone")):
			"clareira":
				return "clearing"
			"mata":
				return "forest_deep"
			"pantano":
				return "swamp"
			"ruinas":
				return "ruins"
			_:
				return "forest"
	var h := float(Time.get_time_dict_from_system()["hour"])
	if scene.get("forced_hour") != null and float(scene.get("forced_hour")) >= 0.0:
		h = float(scene.get("forced_hour"))
	if h >= 20.0 or h < 5.5:
		return "town_night"
	if h >= 17.5:
		return "town_dusk"
	return "town_day"


func open_stage(place: String) -> void:
	setting = place
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(W, H)
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0.0
	hero = _make_actor("heroi")
	if hero != null:
		hero.position = Vector2(HERO_X - 90.0, FEET_Y)
		_face(hero, "right")
		var tw := create_tween().set_parallel(true)
		tw.tween_property(hero, "position:x", HERO_X, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tf := create_tween().set_parallel(true)
	tf.tween_property(self, "modulate:a", 1.0, 0.35)
	tf.tween_property(self, "bars", 1.0, 0.5)


func close_stage() -> void:
	if _closing:
		return
	_closing = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_property(self, "bars", 0.0, 0.3)
	await tw.finished
	queue_free()


## Cada fala: `who` fala (ou "" na narração). `vis` = Looks.speaker_visual do falante.
func focus(who: String, vis: Dictionary) -> void:
	if _closing:
		return
	_speaker = who
	if who != "" and who != "heroi" and who != "espelho" and who != other_id:
		_swap_other(who, vis)
	if who == "heroi" and hero != null and hero is LpcActor:
		(hero as LpcActor).gesture()
		_pulse(hero)
	elif who != "" and other != null and other is LpcActor and who == other_id:
		(other as LpcActor).gesture()
		_pulse(other)
	elif who != "" and other != null and who == other_id:
		_pulse(other)
	if who != "" and who != "heroi" and hero is LpcActor:
		(hero as LpcActor).nod()
	elif who == "heroi" and other is LpcActor:
		(other as LpcActor).nod()


func _pulse(n: Node2D) -> void:
	var tw := create_tween()
	var y0 := n.position.y
	tw.tween_property(n, "position:y", y0 - 3.0, 0.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position:y", y0, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _swap_other(who: String, vis: Dictionary) -> void:
	var old := other
	other_id = who
	other = _make_actor(who, vis)
	if other == null:
		return
	other.position = Vector2(OTHER_X + 120.0, FEET_Y)
	_face(other, "left")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(other, "position:x", OTHER_X, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if old != null and is_instance_valid(old):
		var to := create_tween().set_parallel(true)
		to.tween_property(old, "position:x", OTHER_X + 140.0, 0.4)
		to.tween_property(old, "modulate:a", 0.0, 0.4)
		to.chain().tween_callback(old.queue_free)
	_flash = 1.0


func _face(n: Node2D, dir: String) -> void:
	if n is LpcActor:
		(n as LpcActor).play("idle_" + dir)
	else:
		for c in n.get_children():
			if c is AnimatedSprite2D:
				(c as AnimatedSprite2D).flip_h = (dir == "right")
			elif c is Sprite2D:
				(c as Sprite2D).flip_h = (dir == "left")


## Personagem grande: LPC (pessoas), sprite de chefe (monstros) ou o rosto ampliado (pets).
func _make_actor(who: String, vis_in: Dictionary = {}) -> Node2D:
	var vis := vis_in if not vis_in.is_empty() else Looks.speaker_visual(who)
	var holder := Node2D.new()
	if vis.has("look"):
		var lk: Dictionary = (vis["look"] as Dictionary).duplicate(true)
		lk.erase("scale")
		holder.queue_free()
		var a := LpcActor.make(self, lk, true)
		a.scale = Vector2(SCALE, SCALE) * (1.22 if who == "rei" else 1.0)
		a.self_modulate = vis.get("tint", Color.WHITE)
		return a
	var boss_id: String = Looks.SPEAKER_BOSS.get(who, "")
	if boss_id != "":
		var b: Dictionary = Data.boss_def(boss_id)
		var frames: SpriteFrames = Pix.actor_frames("chars/%s.png" % b["char"]) if b.has("char") else Pix.boss_frames(boss_id)
		var sp := AnimatedSprite2D.new()
		sp.sprite_frames = frames
		var anim := "idle" if frames.has_animation("idle") else ("idle_down" if frames.has_animation("idle_down") else frames.get_animation_names()[0])
		sp.play(anim)
		var th := 16.0
		var ft: Texture2D = frames.get_frame_texture(anim, 0)
		if ft != null:
			th = float(ft.get_height())
		var k := clampf(150.0 / maxf(th, 8.0), 3.0, 6.0)
		sp.scale = Vector2(k, k)
		sp.position = Vector2(0, -th * k * 0.5)
		sp.modulate = vis.get("tint", Color.WHITE)
		holder.add_child(sp)
		add_child(holder)
		return holder
	if vis.has("face"):
		var s := Sprite2D.new()
		s.texture = vis["face"]
		var ts := s.texture.get_size()
		var k2 := 120.0 / maxf(ts.y, 8.0)
		s.scale = Vector2(k2, k2)
		s.position = Vector2(0, -60.0)
		s.modulate = vis.get("tint", Color.WHITE)
		holder.add_child(s)
		add_child(holder)
		return holder
	holder.queue_free()
	return null


func _process(delta: float) -> void:
	t += delta
	_flash = maxf(_flash - delta * 2.0, 0.0)
	var hero_active := _speaker == "heroi" or _speaker == "espelho"
	var other_active := _speaker != "" and not hero_active
	_dim_hero = lerpf(_dim_hero, 1.0 if (hero_active or _speaker == "") else 0.62, minf(1.0, delta * 8.0))
	_dim_other = lerpf(_dim_other, 1.0 if (other_active or _speaker == "") else 0.62, minf(1.0, delta * 8.0))
	if hero != null:
		hero.modulate = Color(_dim_hero, _dim_hero, _dim_hero * 1.05, 1.0)
	if other != null and is_instance_valid(other):
		other.modulate = Color(_dim_other, _dim_other, _dim_other * 1.05, other.modulate.a)
	queue_redraw()


func _draw() -> void:
	StageArt.paint(self, setting, t)
	# sombras e luz de contorno sob os atores
	for pair in [[hero, _dim_hero], [other, _dim_other]]:
		var n: Node2D = pair[0]
		if n == null or not is_instance_valid(n):
			continue
		var p := n.position
		draw_set_transform(Vector2(p.x, p.y + 2.0), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, 46.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# clarão ao entrar um falante novo
	if _flash > 0.0 and other != null and is_instance_valid(other):
		StageArt.glow(self, other.position + Vector2(0, -60), 120.0, Color(1, 1, 0.85, 0.5 * _flash), 5)
	# barras de cinema
	var bh := 30.0 * bars
	draw_rect(Rect2(0, 0, W, bh), Color.BLACK)
	draw_rect(Rect2(0, H - bh, W, bh), Color.BLACK)
