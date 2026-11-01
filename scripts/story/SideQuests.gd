class_name SideQuests
extends RefCounted

## v3.7: side quests da história v4 (seção 8). Não mudam a história principal; dão uma magia (tecla 4) e uma
## armadura única. Aparecem no quadro de missões especiais (Guilda de Focus Town e Centro de Treinamento de
## Pedralta) a partir do Rank E (Guilda) ou da patente de Cabo (Exército). Cada uma pode ser feita uma vez.
##   Caça ao Bruxo do Submundo: rastro de monstros enormes na Mata Profunda, depois o bruxo nas Ruínas.
##   Incursão ao Pé Grande: a Vila da Neve pede ajuda; o Pé Grande espera na caverna.
## Provisórios (seção 15): o bruxo usa o Necromante do Dungeon Tileset II (ampliado); o Pé Grande usa o Guaxinim
## Gigante do Ninja Adventure tingido de branco, até a compra do pack de iéti.
## Estado em Story.st()["side"]: {"bruxo": etapa, "pe_grande": etapa, "kills": n}; etapa 0 = não aceita,
## 1 = rastro / ir à vila, 2 = chefe, 3 = concluída.

const QUESTS := {
	"bruxo": {"title": "Caça ao Bruxo do Submundo", "spell": "trevas", "armor": "manto_cacador",
		"offer": [
			["narr", "Um cartaz rasgado no quadro: \"Monstros enormes na Mata Profunda. Um bruxo os cria. Recompensa a quem o detiver.\""],
		],
		"accept": [["narr", "Você arranca o cartaz. O rastro começa na Mata Profunda: três monstros enormes rondam por lá."]],
		"stage2": [["narr", "O último monstro cai e deixa um rastro de fumaça violeta indo para o oeste, para as Ruínas sob as Raízes."]],
		"victory": [
			["narr", "O Bruxo do Submundo se desfaz em fumaça. No chão, um manto escuro e um livro de capa negra."],
			["narr", "O livro ensina Magia Sombria. O manto guarda o cheiro de quem caçou bruxos antes de você."],
		]},
	"pe_grande": {"title": "Incursão ao Pé Grande", "spell": "nevasca", "armor": "pele_pe_grande",
		"offer": [
			["narr", "Um bilhete trêmulo no quadro: \"A Vila da Neve pede socorro. Um Pé Grande desceu da caverna e já levou três moradores.\""],
		],
		"accept": [["narr", "Você guarda o bilhete. A Vila da Neve fica nas montanhas de Rocuetos: a carruagem do Tobias leva até lá."]],
		"village": [
			["anciao", "Você veio pelo bilhete? Graças aos céus. O Pé Grande vive na caverna acima da vila."],
			["anciao", "É branco como a neve e grande como uma casa. Leve isto: chá quente. Lá dentro o frio corta."],
		],
		"victory": [
			["narr", "O Pé Grande tomba na neve da caverna. Os moradores levados estavam presos atrás do gelo: vivos."],
			["anciao", "Você salvou a vila. Fique com a pele dele, ela aquece mais que dez cobertores. E aprenda o sopro do gelo, como os antigos caçadores."],
		]},
}

const SPEAKERS := {"anciao": {"name": "Ancião Bóris"}}


static func d() -> Dictionary:
	var a: Dictionary = Story.st().get("side", {})
	if a.is_empty():
		a = {"bruxo": 0, "pe_grande": 0, "kills": 0}
		Story.st()["side"] = a
	return a


static func stage(q: String) -> int:
	return int(d().get(q, 0))


static func available() -> bool:
	if Story.path() == "exercito":
		return ArmyStory.patente() >= 2
	return Story.path() == "aventureiro" and Story.rank() >= 1


## Quadro de missões especiais: oferece as side quests e lembra das que estão em andamento.
static func board() -> void:
	if not available():
		await Story.say([["narr", "Cartazes de missões especiais. \"Somente Rank E ou maior, ou patente de Cabo do Exército.\""]])
		return
	var open: Array = []
	for q in QUESTS:
		if stage(q) == 0:
			open.append(q)
	var lines: Array = []
	for q in QUESTS:
		var st := stage(q)
		if st > 0 and st < 3:
			lines.append(["narr", "Em andamento: %s. %s" % [QUESTS[q]["title"], _hint(q)]])
	if open.is_empty():
		if lines.is_empty():
			lines.append(["narr", "Você já cumpriu todas as missões especiais deste quadro."])
		await Story.say(lines)
		return
	var names: Array = []
	for q in open:
		names.append(QUESTS[q]["title"])
	names.append("Agora não")
	Story.set_flag("quadro_side", -1)
	lines.append_array(QUESTS[open[0]]["offer"] if open.size() == 1 else [["narr", "Há cartazes novos no quadro de missões especiais."]])
	lines.append({"choice": names, "key": "quadro_side"})
	await Story.say(lines)
	var pick := int(Story.flag("quadro_side", -1))
	if pick < 0 or pick >= open.size():
		return
	var q2: String = open[pick]
	d()[q2] = 1
	Story._save()
	await Story.say(QUESTS[q2]["accept"])
	HUD.show_toast("Missão especial aceita: %s" % QUESTS[q2]["title"], UI.C_GOLD)


static func _hint(q: String) -> String:
	match [q, stage(q)]:
		["bruxo", 1]:
			return "Derrote os monstros enormes da Mata Profunda (%d/3)." % int(d().get("kills", 0))
		["bruxo", 2]:
			return "Enfrente o Bruxo do Submundo nas Ruínas sob as Raízes."
		["pe_grande", 1]:
			return "Vá à Vila da Neve (carruagem do Tobias) e fale com o Ancião Bóris."
		["pe_grande", 2]:
			return "Entre na caverna do Pé Grande, no alto da Vila da Neve."
	return ""


## Linha extra no painel de objetivo (side quest em andamento), ou "".
static func tracker_text() -> String:
	for q in QUESTS:
		var st := stage(q)
		if st > 0 and st < 3:
			return "%s: %s" % [QUESTS[q]["title"], _hint(q)]
	return ""


# ================================================================== Floresta (bruxo)
## Chamado pela floresta ao montar: monstros enormes na Mata (etapa 1) ou o bruxo nas Ruínas (etapa 2).
static func populate_forest(forest: Node) -> void:
	match stage("bruxo"):
		1:
			for i in maxi(0, 3 - int(d().get("kills", 0))):
				var p: Vector2 = forest._random_spot("mata", 40.0)
				var e := Enemy.spawn(forest.world, "ogro", p, 4, true)
				e.set_meta("sq_bruxo", true)
				e.display_name = "Monstro do Bruxo"
				e.respawn_s = 0.0
		2:
			var bp: Vector2 = forest._tile_pos(10, 34)
			var b := Enemy.spawn(forest.world, "necromante", bp, 6, true)
			b.set_meta("sq_bruxo_boss", true)
			b.display_name = "Bruxo do Submundo"
			b.respawn_s = 0.0
			b.scale = Vector2(1.6, 1.6)
			b.max_hp *= 3.0
			b.hp = b.max_hp
			for k in 2:
				var z := Enemy.spawn(forest.world, "ogro", bp + Vector2(-30 + 60 * k, 20), 5, false)
				z.respawn_s = 0.0


static func on_kill(e: Node) -> void:
	if e.has_meta("sq_bruxo") and stage("bruxo") == 1:
		d()["kills"] = int(d().get("kills", 0)) + 1
		if int(d()["kills"]) >= 3:
			d()["bruxo"] = 2
			d()["kills"] = 0
			Story._save()
			Story.say(QUESTS["bruxo"]["stage2"])
		else:
			HUD.show_toast("Rastro do bruxo: %d/3" % int(d()["kills"]), UI.C_ORANGE_L)
			Story._save()
	elif e.has_meta("sq_bruxo_boss") and stage("bruxo") == 2:
		_finish("bruxo")


static func on_boss_defeated(boss_id: String) -> bool:
	if boss_id == "pe_grande" and stage("pe_grande") == 2:
		_finish("pe_grande")
		return true
	return false


static func _finish(q: String) -> void:
	d()[q] = 3
	Story._save()
	var info: Dictionary = QUESTS[q]
	await Story.say(info["victory"])
	GameState.lab_data()["book_spell"] = str(info["spell"])
	GameState.add_item(str(info["armor"]), 1, true)
	GameState.add_xp(int(round(float(Data.xp_for_level(GameState.level)) * 0.5)), false)
	GameState.mark_dirty()
	GameState.stats_changed.emit()
	Audio.jingle("success2", -4.0)
	var sk: Dictionary = Data.SKILLS.get(str(info["spell"]), {})
	HUD.show_toast("Magia aprendida: %s (tecla 4). Armadura única: %s." % [sk.get("name", "?"), Data.item_name(str(info["armor"]))], UI.C_GOLD)


# ================================================================== Vila da Neve (Pé Grande)
static func talk_anciao() -> void:
	match stage("pe_grande"):
		1:
			await Story.say(QUESTS["pe_grande"]["village"])
			d()["pe_grande"] = 2
			Story._save()
		2:
			await Story.say([["anciao", "A caverna fica no alto da vila, depois das pedras. Volte inteir{o}."]])
		3:
			await Story.say([["anciao", "A vila dorme em paz desde que você passou por aqui."]])
		_:
			await Story.say([["anciao", "Bem-vind{o} à Vila da Neve. Aqui o frio ensina paciência."]])


static func enter_cave() -> void:
	if stage("pe_grande") != 2:
		await Story.say([["narr", "Uma caverna funda e gelada. Pegadas enormes na neve. Melhor não entrar sem motivo."]])
		return
	await Story.say([["narr", "O vento uiva lá dentro. Pegadas do tamanho de um escudo levam para o escuro."]])
	Game.start_duel("pe_grande", {"banner": ["Caverna do Pé Grande", "Incursão na Vila da Neve"], "return": "vila_neve"})
