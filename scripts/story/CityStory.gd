class_name CityStory
extends RefCounted

## v3.2: histórias das cidades novas: a carruagem do Tobias e o fragmento de memória do pai de cada cidade.
## Cada fragmento pede horas de foco acumuladas (CityData.FRAGMENT_HOURS) e a soma dos três abre as Profundezas.


static func fragments() -> int:
	var n := 0
	for id in CityData.ORDER:
		if Story.flag("frag_" + id, false):
			n += 1
	return n


static func talk(npc: String) -> void:
	match npc:
		"cocheiro":
			await _coach()
		"capitao":
			await _fragment("porto")
		"granito":
			await _fragment("pedralta")
		"reitora":
			await _fragment("academia")


# ------------------------------------------------------------------ Carruagem
static func _coach() -> void:
	if Story.chapter() < 6:
		await Story.say(CityData.COCHEIRO_NO)
		return
	var names := ["Porto Névoa", "Pedralta", "Academia de Fontelúcida", "Ficar em Focus Town"]
	var marks := []
	for id in CityData.ORDER:
		marks.append(" (fragmento obtido)" if Story.flag("frag_" + id, false) else "")
	Story.set_flag("carruagem", -1)
	await Story.say([
		["cocheiro", "Uma carruagem, um crédito de estudo. Para onde, {heroi}?"],
		{"choice": ["%s%s" % [names[0], marks[0]], "%s%s" % [names[1], marks[1]], "%s%s" % [names[2], marks[2]], names[3]], "key": "carruagem"},
	])
	var pick := int(Story.flag("carruagem", 3))
	if pick < 0 or pick >= CityData.ORDER.size():
		return
	var id: String = CityData.ORDER[pick]
	if Story.credits() < Story.entry_cost("cidade_" + id, 1):
		await Story.say([["cocheiro", "Sem crédito, sem estrada. Estude no Pomodoro e volte."]])
		HUD.show_toast("Faltam créditos: %d min de foco para o próximo." % Story.minutes_to_next_credit(), UI.C_ENERGY)
		return
	Story.pay_entry("cidade_" + id, 1)
	await Story.say([["cocheiro", "Segure firme. Lá vamos nós!"]])
	Game.go_to_city(id)


# ------------------------------------------------------------------ Fragmentos
static func _fragment(city: String) -> void:
	var f: Dictionary = CityData.FRAGMENTS[city]
	var need: float = CityData.FRAGMENT_HOURS[city]
	if Story.flag("frag_" + city, false):
		await Story.say([[_who(city), "Aquele fragmento é seu agora. O que o pai escreveu, você guarda; o que falta escrever é com você."]])
		return
	if not Story.flag("fraginit_" + city, false):
		Story.set_flag("fraginit_" + city, true)
		await Story.say(f["intro"])
	if Story.focus_hours() + 0.0001 < need:
		var hours := str(int(need)) if absf(need - round(need)) < 0.05 else ("%.1f" % need).replace(".", ",")
		var lines: Array = (f["locked"] as Array).duplicate(true)
		lines[0][1] = str(lines[0][1]) % hours
		await Story.say(lines)
		HUD.show_toast("Foco acumulado: %s h de %s h." % [Story._hours_text(), hours], UI.C_ENERGY)
		return
	await Story.say(f["memory"])
	_reward(city)
	await Story.say([["narr", str(f["reward_text"])]])
	if fragments() >= CityData.ORDER.size() and not Story.flag("fragmentos_completos", false):
		Story.set_flag("fragmentos_completos", true)
		await Story.say([
			["narr", "A bússola de latão esquenta na sua mão. As três memórias do {pai} se juntam numa só: um caminho que desce, mais fundo do que a Parte 1 foi."],
			["heroi", "Agora eu sei por onde ele foi. As Profundezas inteiras estão abertas."],
		])


static func _who(city: String) -> String:
	return {"porto": "capitao", "pedralta": "granito", "academia": "reitora"}[city]


static func _reward(city: String) -> void:
	Story.set_flag("frag_" + city, true)
	Story.st()["credits"] = Story.credits() + 1
	GameState.add_xp(int(round(float(Data.xp_for_level(GameState.level)) * 0.6)), false)
	GameState.add_gold(150 + GameState.level * 20)
	var tier := mini(7, Data.max_tier_for_level(GameState.level) + 1)
	var item := Loot.roll_equipment(0, tier)
	if item != "":
		GameState.add_item(item, 1, true)
		HUD.show_toast("Recebeu: %s" % Data.item_name(item), UI.C_GOLD)
	Audio.jingle("success2", -4.0)
	HUD.show_toast("Fragmento %d de 3 obtido!" % fragments(), UI.C_GOLD)
	Story._save()
