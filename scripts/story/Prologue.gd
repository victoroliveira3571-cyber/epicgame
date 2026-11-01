class_name Prologue
extends Node

## v3.7: prólogo da história v4, top-down na casa da família (nada de cena de lado): berço, montagem do pai
## estudando, montagem do herói crescendo e treinando com a arma da classe e a tarde de chuva em que o pai sai.
## Os personagens andam, viram uns para os outros e reagem; a narração usa os balões de diálogo.
## Provisórios (HISTORIA_V4.md, seção 15): o berço é a cama pequena com manta; o herói criança usa o corpo
## infantil do LPC; o adolescente é o herói adulto um pouco menor. Esc pula o prólogo.

var room: Interior
var mom: NPC
var dad: NPC
var kid: NPC
var _skip: bool = false
var _fade: ColorRect
var _layer: CanvasLayer
var _mod: CanvasModulate
var _mod_color: Color = Color.WHITE

const CRADLE := Vector2(66, 96)
const TABLE_SEAT := Vector2(198, 146)
const DOOR := Vector2(160, 178)


static func start(r: Interior) -> void:
	var p := Prologue.new()
	p.room = r
	r.add_child(p)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 40   # acima do mundo, abaixo do HUD (balões e cartão "Anos depois" aparecem sobre o escuro)
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.size = Vector2(4000, 4000)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)
	for c in room.get_children():
		if c is CanvasModulate:
			_mod = c
			_mod_color = c.color
	_run.call_deferred()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE and not _skip:
		_skip = true
		get_viewport().set_input_as_handled()
		HUD.show_toast("Pulando as lembranças...", UI.C_DIM)


# ================================================================== Roteiro
func _run() -> void:
	Game.cutscene = true
	Game.input_locked = true
	HUD.set_top_hidden(true)
	HUD.set_bottom_hidden(true)
	var pl := room.player
	pl.visible = false
	pl.remove_from_group("speaker_heroi")
	pl.global_position = Vector2(110, 120)
	pl.camera.reset_smoothing()
	mom = _find_mom()
	if mom != null:
		mom.mode = "cutscene"
	dad = _npc_look("pai", Vector2(88, 108))
	dad.add_to_group("speaker_pai")
	await _wait(0.3)
	HUD.show_toast("Esc pula o prólogo.", UI.C_DIM)
	if not _skip:
		await _scene_cradle()
	if not _skip:
		await _montage_father()
	if not _skip:
		await _montage_training()
	if not _skip:
		await _scene_departure()
	await _finish()


## Cena 0: o berço. O bebê não fala; os balões de pensamento mostram o que ele pensa.
func _scene_cradle() -> void:
	_place(mom, Vector2(48, 112), "up")
	_place(dad, Vector2(86, 110), "up")
	await _fade_to(0.0, 1.2)
	await _wait(0.4)
	mom.face(CRADLE)
	dad.face(CRADLE)
	await _say(StoryV4.BERCO.slice(0, 3))
	if _skip:
		return
	# o pai arruma a manta
	await _walk(dad, Vector2(76, 104), 22.0)
	dad.actor.gesture()
	await _say(StoryV4.BERCO.slice(3, 8))
	if _skip:
		return
	await _flash(Color(1, 1, 1), 1.0)
	await _say(StoryV4.BERCO.slice(8))
	await _fade_to(1.0, 0.8)


## Montagem 1: o pai estudando à mesa; a cada corte o herói está mais velho.
func _montage_father() -> void:
	var female := str(Story.st().get("gender", "m")) == "f"
	kid = _npc_custom(LpcW.child_look(GameState.look, female), Vector2(176, 150))
	kid.add_to_group("speaker_heroi")
	_place(dad, TABLE_SEAT, "right")
	dad.actor.hold_last = true
	dad.actor.play("sit_right")
	_place(mom, Vector2(118, 112), "down")
	var cuts := [[0.8, Vector2(172, 156), StoryV4.PAI_ESTUDA_1], [0.9, Vector2(184, 150), StoryV4.PAI_ESTUDA_2], [1.0, Vector2(200, 134), StoryV4.PAI_ESTUDA_3]]
	for i in cuts.size():
		if _skip:
			return
		var cut: Array = cuts[i]
		kid.scale = Vector2(cut[0], cut[0])
		_place(kid, cut[1], "right")
		kid.face(TABLE_SEAT + Vector2(10, -6))
		HUD.floor_banner("Anos depois" if i > 0 else "Na infância", "")
		await _fade_to(0.0, 0.7)
		await _wait(0.3)
		await _say(cut[2])
		await _fade_to(1.0, 0.6)
	dad.actor.hold_last = false
	dad.actor.play("idle_down")


## Montagem 2: o herói cresce treinando com a arma da classe (criança, adolescente, adulto).
func _montage_training() -> void:
	var cls: Dictionary = Data.CLASSES.get(GameState.player_class, {})
	var family := str(cls.get("weapon", "sword"))
	var key := "shield" if GameState.player_class in ["escudeiro", "paladino"] else family
	var anim: String = {"sword": "slash", "dagger": "slash", "bow": "shoot", "staff": "spellcast"}.get(family, "slash")
	_place(dad, Vector2(120, 92), "down")
	_place(mom, Vector2(214, 112), "left")
	var adult := _npc_custom(Looks.hero(), Vector2(160, 120))
	adult.visible = false
	var line: Array = [["narr", str(StoryV4.TREINO.get(key, StoryV4.TREINO["sword"]))]]
	var stages := [[kid, 1.0], [adult, 0.9], [adult, 1.0]]
	for i in stages.size():
		if _skip:
			break
		var who: NPC = stages[i][0]
		kid.visible = who == kid
		adult.visible = who == adult
		who.scale = Vector2(stages[i][1], stages[i][1])
		_place(who, Vector2(160, 122), "down")
		if who == adult:
			kid.remove_from_group("speaker_heroi")
			adult.add_to_group("speaker_heroi")
		await _fade_to(0.0, 0.6)
		for k in 2:
			who.actor.play(anim + "_" + ["down", "right"][k], true)
			await _wait(0.6)
		if i == 0:
			await _say(line)
		elif i == stages.size() - 1:
			mom.face(who.global_position)
			await _say(StoryV4.TREINO_FIM)
		else:
			await _wait(0.5)
		await _fade_to(1.0, 0.5)
	adult.queue_free()
	kid.visible = true
	kid.scale = Vector2.ONE
	if not kid.is_in_group("speaker_heroi"):
		kid.add_to_group("speaker_heroi")


## Cena 1: a saída do pai, numa tarde de chuva. Ele deixa a bússola com o herói; a mãe a guarda.
func _scene_departure() -> void:
	Audio.set_place_loop("pomodoro_chuva", -8.0)
	_tint(Color(0.55, 0.58, 0.74))
	_place(kid, Vector2(150, 140), "down")
	_place(mom, Vector2(126, 128), "right")
	_place(dad, Vector2(160, 158), "up")
	await _fade_to(0.0, 1.0)
	await _flash(Color(0.85, 0.9, 1.0), 0.35)
	await _say(StoryV4.SAIDA_PAI.slice(0, 4))
	if _skip:
		return
	await _walk(dad, Vector2(156, 148), 20.0)
	dad.face(kid.global_position)
	kid.face(dad.global_position)
	await _say(StoryV4.SAIDA_PAI.slice(4))
	if _skip:
		return
	await _walk(dad, DOOR + Vector2(0, -6), 26.0)
	var tw := create_tween()
	tw.tween_property(dad, "modulate:a", 0.0, 0.6)
	await tw.finished
	dad.visible = false
	await _flash(Color(0.85, 0.9, 1.0), 0.3)
	await _wait(0.6)
	mom.face(kid.global_position)
	await _walk(mom, Vector2(140, 136), 20.0)
	await _say(StoryV4.SAIDA_PAI_FIM.slice(0, 2))
	await _walk(mom, Vector2(160, 72), 24.0)
	mom.face(Vector2(160, 40))
	await _say(StoryV4.SAIDA_PAI_FIM.slice(2))
	await _fade_to(1.0, 1.0)


## Fim: volta ao presente, o herói adulto em casa. A mãe espera para a despedida (passo a_casa).
func _finish() -> void:
	if _fade.color.a < 0.99:
		await _fade_to(1.0, 0.5)
	Audio.set_place_loop("lareira_casa")
	_tint(_mod_color)
	if is_instance_valid(dad):
		dad.queue_free()
	if is_instance_valid(kid):
		kid.queue_free()
	var pl := room.player
	pl.visible = true
	pl.add_to_group("speaker_heroi")
	pl.global_position = Vector2(150, 140)
	pl.camera.reset_smoothing()
	if mom != null:
		_place(mom, Vector2(118, 112), "down")
		mom.mode = "static"
	Story.set_flag("prologo_visto")
	Story.st()["step"] = "a_casa"
	Story._save()
	HUD.set_top_hidden(false)
	HUD.set_bottom_hidden(false)
	HUD.floor_banner(StoryV4.PHASES["academia"]["title"], "Hoje")
	await _fade_to(0.0, 1.0)
	Game.cutscene = false
	Game.input_locked = false
	_skip = false
	await _wait(0.6)
	Story.talk("mae")
	queue_free()


# ================================================================== Ferramentas
func _find_mom() -> NPC:
	for n in get_tree().get_nodes_in_group("speaker_mae"):
		if n is NPC:
			return n
	return null


func _npc_look(key: String, pos: Vector2) -> NPC:
	var n := NPC.create(room.world, "Villager", pos, "cutscene", key)
	return n


func _npc_custom(look: Dictionary, pos: Vector2) -> NPC:
	var n := NPC.new()
	n.custom_look = look
	n.mode = "cutscene"
	n.position = pos
	room.world.add_child(n)
	return n


func _place(n: NPC, pos: Vector2, dir: String) -> void:
	if n == null:
		return
	n.position = pos
	n.visible = true
	n.modulate.a = 1.0
	if n.actor != null and not n.actor.hold_last:
		n.actor.play("idle_" + dir)
	n.dir_name = dir


func _walk(n: NPC, to: Vector2, spd: float) -> void:
	if n == null or _skip:
		return
	var v := to - n.position
	if v.length() < 1.0:
		return
	n.actor.hold_last = false
	n.actor.play("walk_" + Pix.dir_name(v))
	var tw := create_tween()
	tw.tween_property(n, "position", to, v.length() / spd)
	await tw.finished
	n.actor.play("idle_" + Pix.dir_name(v))


func _say(lines: Array) -> void:
	if _skip or lines.is_empty():
		return
	await HUD.dialogue(lines)
	Game.input_locked = true


func _wait(t: float) -> void:
	if _skip:
		return
	await get_tree().create_timer(t, true, false, true).timeout


func _fade_to(alpha: float, t: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, 0.05 if _skip else t)
	await tw.finished


func _flash(col: Color, t: float) -> void:
	if _skip:
		return
	var r := ColorRect.new()
	r.color = Color(col, 0.0)
	r.size = Vector2(4000, 4000)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "color:a", 0.85, t * 0.25)
	tw.tween_property(r, "color:a", 0.0, t * 0.75)
	await tw.finished
	r.queue_free()


func _tint(c: Color) -> void:
	if _mod != null:
		create_tween().tween_property(_mod, "color", c, 0.8)
