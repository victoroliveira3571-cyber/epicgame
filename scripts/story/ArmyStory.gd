class_name ArmyStory
extends RefCounted

## v3.7: caminho B da história v4: o Exército de Rocuetos. Centro de treinamento em Pedralta (capital militar),
## patentes de Recruta a Marquês, patrulhas na floresta e cruzadas contra chefes (duelo, como o Torneio), cada
## cruzada com uma pista pequena do pai, e a cruzada final contra o Rei Demônio em Masmoreum, sem o pai no fim.
## Estado em Story.st()["exercito"]: patente (0..9), on (missão em andamento), kills, done.
## Provisórios (seção 15): o centro de treinamento usa os bonecos de treino que o jogo já tem.

const BRIGIDA_TILE := Vector2i(46, 21)
const DUMMIES := [Vector2i(42, 22), Vector2i(43, 23), Vector2i(50, 22)]
## Patente mínima para entrar em cada zona da floresta (a insígnia vale como passe).
const ZONE_PATENTE := {"borda": 0, "clareira": 0, "mata": 2, "pantano": 3, "ruinas": 4}


static func d() -> Dictionary:
	var a: Dictionary = Story.st().get("exercito", {})
	if a.is_empty():
		a = {"patente": 0, "on": false, "kills": 0, "done": false}
		Story.st()["exercito"] = a
	return a


static func handles(npc: String) -> bool:
	return npc == "brigida"


static func patente() -> int:
	return int(d().get("patente", 0))


static func patente_name() -> String:
	return StoryV4.patente_name(patente())


static func zone_ok(zone: String) -> bool:
	return patente() >= int(ZONE_PATENTE.get(zone, 0))


static func mission() -> Dictionary:
	var i := patente()
	return StoryV4.MISSOES_EXERCITO[i] if i < StoryV4.MISSOES_EXERCITO.size() else {}


static func _h(v: float) -> String:
	return str(int(v)) if absf(v - round(v)) < 0.05 else ("%.1f" % v).replace(".", ",")


# ================================================================== Objetivo
static func objective_text() -> String:
	var a := d()
	var m := mission()
	if m.is_empty():
		return "Fale com a Comandante Brígida em Pedralta"
	if bool(a["done"]):
		return "Missão cumprida! Volte à Comandante Brígida em Pedralta"
	if bool(a["on"]):
		if str(m["kind"]) == "patrulha":
			var zn: String = Data.FOREST_ZONES[m["zone"]]["name"]
			return "%s: %d/%d monstros em %s" % [m["title"], int(a["kills"]), int(m["count"]), zn]
		return "%s: fale com a Comandante Brígida para marchar" % m["title"]
	return "%s: %s. Fale com a Comandante Brígida (pede %s h de foco; você tem %s h)" % [patente_name(), m["title"], _h(float(m["hours"])), Story._hours_text()]


static func objective_target() -> String:
	var a := d()
	var m := mission()
	if bool(a["on"]) and not m.is_empty() and str(m["kind"]) == "patrulha":
		var scene := Story.get_tree().current_scene
		if scene != null and scene.is_in_group("forest"):
			return str(m["zone"])
		return "trilha_floresta"
	return "centro_treino"


# ================================================================== Conversas
static func talk(_npc: String) -> void:
	var s := Story.step()
	var a := d()
	match s:
		"b_alistar":
			await Story.say(StoryV4.ALISTAMENTO)
			a["patente"] = 0
			Story.set_flag("insignia")
			GameState.add_gold(40)
			Story.set_step("b_missao")
		"b_missao":
			await _mission_talk()
		"b_cruzada_final":
			if Story.focus_hours() + 0.0001 < 8.0:
				await Story.say(StoryV4.CRUZADA_FINAL_FALTA)
				return
			await Story.say(StoryV4.CRUZADA_FINAL)
			Game.start_duel("rei_demonio", {"banner": ["Cruzada Final", "Masmoreum: o Trono Sem Luz"], "return": "pedralta"})
		"fim_b":
			await Story.say([["brigida", "Marquês. A casa ao sul está pronta e a sua mãe já plantou metade do jardim. O reino agradece."]])
		_:
			await Story.say([["brigida", "Pedralta treina quem estuda. Se um dia quiser servir Rocuetos, a porta do centro de treinamento está aberta."]])


static func _mission_talk() -> void:
	var a := d()
	var m := mission()
	if m.is_empty():
		Story.set_step("b_cruzada_final")
		await talk("brigida")
		return
	if bool(a["done"]):
		await _promote()
		return
	if bool(a["on"]):
		if str(m["kind"]) == "cruzada":
			await Story.say([["brigida", "A tropa está pronta. Marchamos agora."]])
			_start_crusade(m)
		else:
			await Story.say([["brigida", "A patrulha ainda não terminou: %d de %d. A trilha fica a oeste de Focus Town." % [int(a["kills"]), int(m["count"])]]])
		return
	var need := float(m["hours"])
	if Story.focus_hours() + 0.0001 < need:
		await Story.say([["brigida", "%s pede %s h de foco acumuladas. Você tem %s h. Soldado que não estuda vira estatística." % [m["title"], _h(need), Story._hours_text()]]])
		HUD.show_toast("Foco acumulado: %s h de %s h." % [Story._hours_text(), _h(need)], UI.C_ENERGY)
		return
	await Story.say(m["brief"])
	a["on"] = true
	a["kills"] = 0
	a["done"] = false
	Story._save()
	if str(m["kind"]) == "cruzada":
		_start_crusade(m)
	else:
		HUD.show_toast("Patrulha: %s. A insígnia abre a trilha da floresta (oeste de Focus Town)." % m["title"], UI.C_ORANGE_L)


static func _start_crusade(m: Dictionary) -> void:
	Game.start_duel(str(m["boss"]), {"banner": [str(m["title"]), "Cruzada do Exército de Rocuetos"], "return": "pedralta", "army": true})


static func _promote() -> void:
	var a := d()
	var m := mission()
	if m.has("clue"):
		await Story.say(m["clue"])
	a["patente"] = patente() + 1
	a["on"] = false
	a["done"] = false
	a["kills"] = 0
	GameState.add_xp(80 + 40 * patente(), false)
	GameState.add_gold(60 + 40 * patente())
	Audio.jingle("levelup", -4.0)
	var nome := patente_name()
	HUD.show_toast(Story.fmt(StoryV4.PROMOVIDO) % nome, UI.C_GOLD)
	await Story.say([["brigida", "%s. A insígnia é sua. Rocuetos lembra de quem cumpre ordens estudando." % nome]])
	if patente() >= StoryV4.PATENTES.size() - 1:
		Story.set_step("b_cruzada_final")
	else:
		Story._save()
		Story.changed.emit()


# ================================================================== Eventos
static func on_kill(e: Node) -> void:
	if Story.path() != "exercito" or Story.step() != "b_missao":
		return
	var a := d()
	var m := mission()
	if m.is_empty() or not bool(a["on"]) or str(m["kind"]) != "patrulha":
		return
	var scene := Story.get_tree().current_scene
	if scene == null or not scene.is_in_group("forest") or not scene.has_method("zone_at"):
		return
	var p: Vector2 = (e as Node2D).global_position
	var zone: String = scene.zone_at(clampi(int(p.x / 16.0), 0, scene.W - 1), clampi(int(p.y / 16.0), 0, scene.H - 1))
	if zone != str(m["zone"]):
		return
	a["kills"] = int(a["kills"]) + 1
	if int(a["kills"]) >= int(m["count"]):
		a["on"] = false
		a["done"] = true
		Audio.jingle("success", -4.0)
		HUD.show_toast("Patrulha cumprida! Volte à Comandante Brígida em Pedralta.", UI.C_GOLD)
	else:
		HUD.show_toast("%s: %d/%d" % [m["title"], int(a["kills"]), int(m["count"])], UI.C_ORANGE_L)
	Story._save()


## Chefe derrotado no caminho do Exército: cruzada comum (promove na volta) ou a cruzada final.
static func on_boss_defeated(boss_id: String) -> void:
	if boss_id == "rei_demonio" and Story.step() == "b_cruzada_final":
		await Story.say(StoryV4.VITORIA_B)
		GameState.add_xp(600, false)
		GameState.add_gold(800)
		Story.st()["chapter"] = 6
		Story.set_step("fim_b")
		return
	var a := d()
	var m := mission()
	if not m.is_empty() and str(m.get("boss", "")) == boss_id:
		a["on"] = false
		a["done"] = true
		Story._save()
		await Story.say([["narr", "Os estandartes de Rocuetos se erguem sobre o campo. A cruzada foi vencida."]])
		HUD.show_toast("Cruzada vencida! Volte à Comandante Brígida em Pedralta.", UI.C_GOLD)


# ================================================================== Pedralta (cena)
## Centro de treinamento e a Comandante Brígida (a qualquer momento: quem não escolheu o Exército ouve um convite).
static func decorate(city: Node) -> void:
	var T: int = city.T
	var pos: Vector2 = city._tile_pos(BRIGIDA_TILE.x, BRIGIDA_TILE.y)
	for dt in DUMMIES:
		city._add_prop("p_boneco_treino", city._tile_pos(dt.x, dt.y), 5.0)
	city._label("Centro de Treinamento", pos + Vector2(0, -44), Color("ffd2a8"))
	var b := NPC.new()
	b.custom_look = brigida_look()
	b.mode = "static"
	b.position = pos
	city.world.add_child(b)
	StoryProp.talker(b, "brigida", "Comandante Brígida")
	city.extra_landmarks.append(["centro_treino", "Centro de Treinamento", pos])
	if Story.path() == "exercito" and int(d().get("patente", 0)) >= 1:
		var sold := NPC.new()
		sold.custom_look = Ally.look_of("soldado")
		sold.mode = "static"
		sold.position = pos + Vector2(28, 10)
		city.world.add_child(sold)
		sold.lines = ["A Comandante grita, mas é justa.", "Estudei anatomia de ogro ontem. Não recomendo antes de dormir."]


static func brigida_look() -> Dictionary:
	var lk := LpcW.default_look("female")
	lk["hair_pal"] = "ash"
	var eq: Dictionary = lk["equip"]
	eq["cabelo"] = "cab_preso_baixo" if LpcW.part("cab_preso_baixo").size() > 0 else eq.get("cabelo", "cab_longo")
	lk["equip"] = eq
	lk["gear"] = {"armor": 3, "boots": 2}
	lk["gear_family"] = "escudeiro"
	lk["weapon"] = "spear"
	return lk
