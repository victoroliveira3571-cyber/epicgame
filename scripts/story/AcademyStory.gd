class_name AcademyStory
extends RefCounted

## v3.7: Ato 2 da história v4: a Academia primária de aventureiros de Fontelúcida (reino de Filus).
## Matrícula com a Reitora Aurora, aula do Mestre Lin (professor da Academia), três missões no Jardim da Academia
## liberadas por horas de foco (0,5 h, 1 h e 1,5 h desde a matrícula), com colegas lutando junto (Nina, Tomé e,
## na última, o rival Ivo), a Formatura (2 horas seguidas de foco) e a escolha entre Guilda e Exército.
## Estado em Story.st()["academia"]: m (missão 0..2), on (missão em andamento), kills, done, base_min (foco na
## matrícula), streak/end/best (sequência de foco em minutos).

const STREAK_GOAL := 120          # minutos seguidos para a Formatura
const STREAK_GRACE := 15 * 60     # folga além da pausa configurada entre dois focos (s)
const GARDEN := Rect2i(4, 48, 47, 9)   # Jardim da Academia, em tiles (x, y, largura, altura)
const GATE_X := 40


static func d() -> Dictionary:
	var a: Dictionary = Story.st().get("academia", {})
	if a.is_empty():
		a = {"m": 0, "on": false, "kills": 0, "done": false, "base_min": Story.focus_minutes(), "streak": 0, "end": 0, "best": 0}
		Story.st()["academia"] = a
	return a


static func handles(npc: String) -> bool:
	if npc in ["lin_a", "ivo_a", "nina", "tome"]:
		return true
	return npc == "reitora" and (Story.in_academy_act() or Story.step() == "a_escolha")


static func hours_since_enroll() -> float:
	return float(Story.focus_minutes() - int(d().get("base_min", 0))) / 60.0


static func _h(v: float) -> String:
	return str(int(v)) if absf(v - round(v)) < 0.05 else ("%.1f" % v).replace(".", ",")


# ================================================================== Objetivo
static func mission() -> Dictionary:
	return StoryV4.JARDIM[clampi(int(d()["m"]), 0, StoryV4.JARDIM.size() - 1)]


static func objective_text() -> String:
	var a := d()
	var m := mission()
	if bool(a["on"]):
		return "%s no Jardim da Academia (%d/%d)" % [m["title"], int(a["kills"]), int(m["count"])]
	if bool(a["done"]):
		return "Missão cumprida! Volte e conte ao Mestre Lin (Salão dos Mestres)"
	return "Missão do jardim %d de 3: %s. Fale com Mestre Lin (pede %s h de foco; você tem %s h)" % [
		int(a["m"]) + 1, m["title"], _h(float(m["hours"])), _h(hours_since_enroll())]


static func objective_target() -> String:
	return "jardim" if bool(d()["on"]) else "classe"


static func streak_text() -> String:
	return "melhor sequência: %d de %d min" % [mini(int(d().get("best", 0)), STREAK_GOAL), STREAK_GOAL]


# ================================================================== Conversas
static func talk(npc: String) -> void:
	var s := Story.step()
	match npc:
		"reitora":
			await _talk_reitora(s)
		"lin_a":
			await _talk_lin(s)
		"ivo_a":
			await Story.say([["ivo", "Estudando de novo? Eu treino. No fim a gente vê quem passa na Formatura."]] if s != "a_formatura"
				else [["ivo", "Duas horas seguidas... Tá. Eu também estou tentando. Não conta para ninguém."]])
		"nina":
			await Story.say([["nina@happy", "Quando abrir a próxima missão do jardim, me chama! Eu cuido da luz, você cuida do resto."]])
		"tome":
			await Story.say([["tome", "Eu estudo melhor de manhã. À tarde eu só penso em gosma."]])


static func _talk_reitora(s: String) -> void:
	match s:
		"a_viagem", "a_matricula":
			await Story.say(StoryV4.MATRICULA)
			d()["base_min"] = Story.focus_minutes()
			Story.set_step("a_aula")
		"a_formatura":
			if int(d().get("best", 0)) >= STREAK_GOAL:
				await Story.say(StoryV4.FORMATURA_OK)
				GameState.add_xp(150, false)
				GameState.add_gold(120)
				Story.set_flag("formatura")
				Story.st()["step"] = "a_escolha"
				Story._save()
				await choose_path()
			else:
				var lines: Array = StoryV4.FORMATURA_FALTA.duplicate(true)
				lines[0][1] = str(lines[0][1]).replace("{sequencia}", "%d min" % int(d().get("best", 0)))
				await Story.say(lines)
		"a_escolha":
			await choose_path()
		_:
			await Story.say([["reitora", "Estude, aprenda a lutar ao lado dos colegas e, quando o Mestre Lin disser, venha para a Formatura."]])


static func _talk_lin(s: String) -> void:
	match s:
		"a_aula":
			await Story.say(StoryV4.AULA)
			var a := d()
			a["m"] = 0
			a["on"] = false
			a["done"] = false
			Story.set_step("a_jardim")
		"a_jardim":
			await _mission_talk()
		"a_formatura":
			await Story.say([["lin", "Duas horas seguidas. Respire antes de começar: inspire em 4, segure 4, solte em 6."],
				["lin", "Pausas curtas não quebram a sequência. Descartar ou parar o foco antes da hora, sim."]])
		_:
			await Story.say("lin_dica")


static func _mission_talk() -> void:
	var a := d()
	var m := mission()
	if bool(a["on"]):
		await Story.say([["lin", "O jardim fica ao sul, depois da cerca. %d de %d até agora." % [int(a["kills"]), int(m["count"])]]])
		return
	if bool(a["done"]):
		await Story.say(m["end"])
		GameState.add_xp(40 + 30 * int(a["m"]), false)
		GameState.add_gold(30 + 20 * int(a["m"]))
		a["done"] = false
		a["kills"] = 0
		a["m"] = int(a["m"]) + 1
		_dismiss_allies()
		if int(a["m"]) >= StoryV4.JARDIM.size():
			a["m"] = StoryV4.JARDIM.size() - 1
			await Story.say(StoryV4.FORMATURA_INICIO)
			a["best"] = 0
			Story.set_step("a_formatura")
		else:
			Story._save()
			HUD.show_toast("Próxima missão do jardim: %s (pede %s h de foco)." % [mission()["title"], _h(float(mission()["hours"]))], UI.C_ORANGE_L)
		_respawn_static_classmates()
		return
	var need := float(m["hours"])
	if hours_since_enroll() + 0.0001 < need:
		await Story.say([["lin", "Ainda não. A missão \"%s\" pede %s h de foco desde a matrícula; você tem %s h." % [m["title"], _h(need), _h(hours_since_enroll())]],
			["lin", "Abra o Pomodoro (P). O jardim espera."]])
		HUD.show_toast("Foco desde a matrícula: %s h de %s h." % [_h(hours_since_enroll()), _h(need)], UI.C_ENERGY)
		return
	await Story.say(m["start"])
	a["on"] = true
	a["kills"] = 0
	a["done"] = false
	Story._save()
	var scene := Story.get_tree().current_scene
	if scene != null and scene.has_method("is_academy") and scene.is_academy():
		spawn_mission(scene)


# ================================================================== Jardim (cena)
## Chamado pela cidade da Academia ao montar a cena: cerca e placa do jardim, professores e colegas.
static func decorate(city: Node) -> void:
	var T: int = city.T
	# cerca do jardim (linha 47) com o portão na trilha
	var body := StaticBody2D.new()
	body.collision_layer = 1
	city.world.add_child(body)
	for seg in [[2, GATE_X - 1], [GATE_X + 2, city.W - 3]]:
		var x0: int = seg[0]
		var x1: int = seg[1]
		var x := x0
		while x <= x1:
			var n := mini(6, x1 - x + 1)
			city._add_prop("k_cerca_%d" % n, Vector2((x + n / 2.0) * T, 47 * T + 12))
			x += n
		var c := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2((x1 - x0 + 1) * T, 6)
		c.shape = r
		c.position = Vector2((x0 + (x1 - x0 + 1) / 2.0) * T, 47 * T + 9)
		body.add_child(c)
	city._label("Jardim da Academia", Vector2((GATE_X + 1) * T, 46 * T - 20), Color("d9ffc2"))
	city.extra_landmarks.append(["jardim", "Jardim da Academia", Vector2((GATE_X + 1) * T, 52 * T)])
	if not Story.in_academy_act():
		return
	if Story.step() == "a_viagem":
		# chegou pela estrada sem passar pela carruagem: segue para a matrícula
		Story.st()["step"] = "a_matricula"
		Story._save()
	# v3.7: o Mestre Lin dá aula dentro do castelo (Interior "acad_aula"); no pátio ficam Ivo e os colegas
	if not (bool(d()["on"]) and mission().has("boss")):
		var ivo := NPC.create(city.world, "Boy", city._tile_pos(36, 27), "static", "ivo")
		StoryProp.talker(ivo, "ivo_a", "Ivo")
		ivo.add_to_group("speaker_ivo")
	if Story.step() == "a_jardim" and bool(d()["on"]):
		spawn_mission(city)
	else:
		_static_classmates(city)


static func _static_classmates(city: Node) -> void:
	for pair in [["nina", Vector2(38, 45)], ["tome", Vector2(44, 45)]]:
		var n := NPC.new()
		n.custom_look = Ally.look_of(str(pair[0]))
		n.mode = "static"
		n.position = city._tile_pos((pair[1] as Vector2).x, (pair[1] as Vector2).y)
		city.world.add_child(n)
		n.add_to_group("academia_colega")
		StoryProp.talker(n, str(pair[0]), str(StoryV4.COLEGAS[pair[0]]["name"]))


static func _respawn_static_classmates() -> void:
	var scene := Story.get_tree().current_scene
	if scene != null and scene.has_method("is_academy") and scene.is_academy() and Story.in_academy_act():
		_static_classmates(scene)


static func _dismiss_allies() -> void:
	for a in Story.get_tree().get_nodes_in_group("ally"):
		a.queue_free()
	for n in Story.get_tree().get_nodes_in_group("academia_colega"):
		n.queue_free()


## Monstros da missão no jardim e os colegas como aliados.
static func spawn_mission(city: Node) -> void:
	var a := d()
	var m := mission()
	for n in Story.get_tree().get_nodes_in_group("academia_colega"):
		n.queue_free()
	var left := int(m["count"]) - int(a["kills"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + int(a["m"])
	for i in left:
		var tx := rng.randi_range(GARDEN.position.x + 2, GARDEN.end.x - 2)
		var ty := rng.randi_range(GARDEN.position.y + 1, GARDEN.end.y - 1)
		var boss := m.has("boss")
		var e := Enemy.spawn(city.world, str(m["monster"]), city._tile_pos(tx, ty), 3 if boss else 1, boss)
		e.set_meta("jardim", true)
		if boss:
			# o "rei" do jardim: gosma elite bem maior, com mais vida (os colegas ajudam)
			e.display_name = "Slime-Rei do Jardim"
			e.scale = Vector2(1.8, 1.8)
			e.max_hp *= 2.5
			e.hp = e.max_hp
	var pl := Story.get_tree().get_first_node_in_group("player") as Node2D
	var base: Vector2 = pl.global_position if pl != null else city._tile_pos(GATE_X, 44)
	var offs := [Vector2(-18, 10), Vector2(18, 10), Vector2(0, 18)]
	var allies: Array = m.get("allies", [])
	for i in allies.size():
		if Story.get_tree().get_nodes_in_group("speaker_" + str(allies[i])).filter(func(x: Node) -> bool: return x is Ally).is_empty():
			Ally.spawn(city.world, str(allies[i]), base + offs[i % offs.size()], offs[i % offs.size()])


static func on_kill(e: Node) -> void:
	if Story.step() != "a_jardim" or not e.has_meta("jardim"):
		return
	var a := d()
	if not bool(a["on"]):
		return
	var m := mission()
	a["kills"] = int(a["kills"]) + 1
	if int(a["kills"]) >= int(m["count"]):
		a["on"] = false
		a["done"] = true
		Audio.jingle("success", -4.0)
		HUD.show_toast("Missão cumprida! Volte e conte ao Mestre Lin.", UI.C_GOLD)
	else:
		HUD.show_toast("%s: %d/%d" % [m["title"], int(a["kills"]), int(m["count"])], UI.C_ORANGE_L)
	Story._save()


# ================================================================== Formatura (sequência de foco)
static func on_focus(minutes: int, early: bool) -> void:
	var a := d()
	if early:
		# finalizar antes da hora conta o tempo, mas é uma interrupção: a sequência recomeça
		if int(a.get("streak", 0)) > 0 and Story.step() == "a_formatura":
			HUD.show_toast("Foco finalizado antes da hora: a sequência da Formatura recomeça.", UI.C_DIM)
		a["streak"] = 0
		a["end"] = 0
		Story._save()
		return
	var now := int(Time.get_unix_time_from_system())
	var start := now - minutes * 60
	var allowed := int(GameState.pomo_cfg.get("break", 5)) * 60 + STREAK_GRACE
	if int(a.get("end", 0)) > 0 and start - int(a["end"]) <= allowed:
		a["streak"] = int(a.get("streak", 0)) + minutes
	else:
		a["streak"] = minutes
	a["end"] = now
	var was := int(a.get("best", 0))
	a["best"] = maxi(was, int(a["streak"]))
	if Story.step() == "a_formatura":
		if int(a["best"]) >= STREAK_GOAL and was < STREAK_GOAL:
			HUD.show_toast("Duas horas seguidas de foco! Fale com a Reitora Aurora.", UI.C_GOLD)
		elif int(a["best"]) < STREAK_GOAL:
			HUD.show_toast("Sequência da Formatura: %d de %d min." % [int(a["streak"]), STREAK_GOAL], UI.C_ENERGY)
	Story._save()


static func on_focus_break() -> void:
	var a := d()
	a["streak"] = 0
	a["end"] = 0
	Story._save()


# ================================================================== Escolha do caminho
static func choose_path() -> void:
	await Story.say(StoryV4.ESCOLHA)
	var pick := int(Story.flag("caminho", -1))
	if pick == 1:
		await Story.say(StoryV4.ESCOLHA_EXERCITO)
		Story.set_path("exercito")
		Story.set_step("b_alistar")
	else:
		await Story.say(StoryV4.ESCOLHA_GUILDA)
		Story.set_path("aventureiro")
		Story.start_chapter(1)
		Story.set_step("c1_marta")
