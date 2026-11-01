class_name Law
extends RefCounted

## A lei de Focus Town: bater em aldeões chama o guarda; matar um morador (ou seu duelo na floresta e na
## masmorra) é crime grave. A pena é paga em MINUTOS DE FOCO no Pomodoro, dentro da cela da delegacia:
##  - agressão: cadeia de 90 min de foco (v3.7; antes 30 min, subindo 15 a cada prisão);
##  - morte de um NPC: 3 horas (180 min), o NPC se regenera, a pena fica.
## Enquanto houver pena, os minutos de foco pagam a pena primeiro e só o que sobra vira crédito de estudo
## (Story.add_focus_minutes). O estado fica em Story.st()["law"].

const BASE_FINE := 90
const FINE_STEP := 0
const MURDER_FINE := 180


static var wants_murder: bool = false      # o policial que vem agora prende por homicídio
static var _cop: NPC = null


static func data() -> Dictionary:
	var st := Story.st()
	if not st.has("law"):
		st["law"] = {"arrests": 0, "murders": 0, "jail_left": 0, "jail_total": 0}
	return st["law"]


static func is_jailed() -> bool:
	return Story.started() and int(data().get("jail_left", 0)) > 0


static func jail_left() -> int:
	return int(data().get("jail_left", 0))


## Multa da próxima agressão.
static func next_fine() -> int:
	return BASE_FINE + FINE_STEP * int(data().get("arrests", 0))


static func arrest(reason: String) -> void:
	if not Story.started() or is_jailed() or Game.transitioning:
		return
	var d := data()
	var fine := MURDER_FINE if reason == "murder" else next_fine()
	if reason == "murder":
		d["murders"] = int(d.get("murders", 0)) + 1
	d["arrests"] = int(d.get("arrests", 0)) + 1
	d["jail_left"] = fine
	d["jail_total"] = fine
	wants_murder = false
	Story._save()
	if GameState.hp <= 0:
		GameState.revive_after_defeat()
	Game.go_to_jail(fine, reason)


## Chamado por Story.add_focus_minutes: devolve os minutos que sobraram depois de pagar a pena.
static func pay_with_focus(minutes: int) -> int:
	var left := jail_left()
	if left <= 0 or minutes <= 0:
		return minutes
	var pay := mini(minutes, left)
	var d := data()
	d["jail_left"] = left - pay
	if int(d["jail_left"]) <= 0:
		HUD.show_toast("Pena cumprida! O guarda abre a cela.", UI.C_GOOD)
		Audio.jingle("success2", -4.0)
	else:
		HUD.show_toast("Pena paga: -%d min. Faltam %d min de foco." % [pay, int(d["jail_left"])], UI.C_ENERGY)
	return minutes - pay


## Um morador foi ferido: ele grita e o guarda da cidade vem.
static func on_npc_hurt(npc: NPC) -> void:
	if npc._alarmed:
		return
	npc._alarmed = true
	npc._say("Socorro! Guarda!")
	npc.get_tree().create_timer(1.1).timeout.connect(func() -> void: _summon(npc))


## O morador desmaiou: crime grave (3 h de foco). Ele se regenera, a pena fica.
static func on_npc_downed(npc: NPC) -> void:
	wants_murder = true
	npc.show_emote(16)
	npc.get_tree().create_timer(0.6).timeout.connect(func() -> void: _summon(npc))


static func _summon(near: Node2D) -> void:
	if is_jailed() or not is_instance_valid(near) or (_cop != null and is_instance_valid(_cop)):
		return
	var scene := near.get_tree().current_scene
	var pl := near.get_tree().get_first_node_in_group("player") as Node2D
	if pl == null:
		return
	var world := near.get_parent()
	var from := pl.global_position + Vector2(130, 0).rotated(randf() * TAU)
	if scene is Interior:
		var room := scene as Interior
		from = Vector2(float(room.cols / 2) * Interior.T, float(room.rows) * Interior.T - 20.0)
	_cop = NPC.create(world, "guarda", from, "chase")
	_cop.is_police = true
	_cop.remove_from_group("npc_hit")
	_cop.show_emote(8)
	HUD.show_toast("Um guarda foi chamado! Fuja ou aceite a prisão.", UI.C_BAD)
	Audio.sfx("ui_error", -6.0)


static func status_text() -> String:
	return "Pena: %d min de foco" % jail_left() if is_jailed() else ""
