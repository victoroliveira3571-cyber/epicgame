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
		"anciao":
			await SideQuests.talk_anciao()
		"caverna":
			await SideQuests.enter_cave()
		"quadro_side":
			await SideQuests.board()


# ------------------------------------------------------------------ Carruagem
## v3.7 (história v4): o destino depende da etapa. Na Academia a bolsa paga a viagem; recrutas do Exército vão de
## graça a Pedralta; a Vila da Neve abre com a side quest do Pé Grande; depois da Parte 1, tudo (1 crédito).
static func _destinations() -> Array:
	var out: Array = []   # [id, nome, custo]
	var s := Story.step()
	if Story.in_academy_act():
		if s.begins_with("a_") and s != "a_casa":
			out.append(["academia", "Academia de Fontelúcida (bolsa: grátis)", 0])
		return out
	if Story.path() == "exercito":
		out.append(["pedralta", "Pedralta (Exército: grátis)", 0])
	if Story.part1_done():
		for id in CityData.ORDER:
			if id != "pedralta" or Story.path() != "exercito":
				out.append([id, str(CityData.CITIES[id]["name"]) + (" (fragmento obtido)" if Story.flag("frag_" + id, false) else ""), 1])
		out.append(["oasis", str(CityData.CITIES["oasis"]["name"]), 1])
	elif Story.path() == "aventureiro":
		out.append(["academia", "Academia de Fontelúcida", 1])
	if SideQuests.stage("pe_grande") >= 1:
		out.append(["vila_neve", "Vila da Neve" + (" (missão especial)" if SideQuests.stage("pe_grande") < 3 else ""), 1])
	return out


const AMBUSH_CHANCE := 0.3


static func _coach() -> void:
	var dest := _destinations()
	if dest.is_empty():
		if Story.in_academy_act():
			await Story.say([["cocheiro", "Alunos da Academia viajam de graça, mas primeiro se despeça da família, jovem."]])
		else:
			await Story.say(CityData.COCHEIRO_NO)
		return
	var names: Array = []
	for dd in dest:
		names.append(str(dd[1]))
	names.append("Ficar em Focus Town")
	Story.set_flag("carruagem", -1)
	await Story.say([
		["cocheiro", "Carruagem para onde o estudo levar. Para onde, {heroi}?"],
		{"choice": names, "key": "carruagem"},
	])
	var pick := int(Story.flag("carruagem", names.size() - 1))
	if pick < 0 or pick >= dest.size():
		return
	var id: String = dest[pick][0]
	var cost: int = int(dest[pick][2])
	if cost > 0:
		if Story.credits() < Story.entry_cost("cidade_" + id, cost):
			await Story.say([["cocheiro", "Sem crédito, sem estrada. Estude no Pomodoro e volte."]])
			HUD.show_toast("Faltam créditos: %d min de foco para o próximo." % Story.minutes_to_next_credit(), UI.C_ENERGY)
			return
		Story.pay_entry("cidade_" + id, cost)
	elif Story.step() == "a_viagem":
		await Story.say(StoryV4.COCHEIRO_BOLSA)
	await Story.say([["cocheiro", "Segure firme. Lá vamos nós!"]])
	# v3.7: monstros no caminho. Viagens pagas podem ter emboscada (a primeira ida à Academia, não)
	if cost > 0 and randf() < AMBUSH_CHANCE:
		await Story.say([["cocheiro", "Ôa! Monstros na estrada! Desça e abra caminho, {heroi}; eu espero do outro lado."]])
		Game.travel_road(id)
		return
	Game.go_to_city(id)


# ------------------------------------------------------------------ Fragmentos
static func _fragment(city: String) -> void:
	if not Story.part1_done():
		# v4: as memórias do pai nas cidades vêm depois da Parte 1 (antes, só uma conversa)
		await Story.say([[_who(city), "Volte quando tiver enfrentado o que está no fundo de Masmoreum. Aí eu terei algo do seu pai para você."]])
		return
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
	return {"porto": "capitao", "pedralta": "granito", "academia": "reitora"}.get(city, "narr")


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
