extends UIWindow

## Personagem (C): atributos, habilidade da classe e talentos; aba "Habilidades" com os marcos de
## cada 10 níveis e a promoção de classe; aba "Pets e história" com o rank, créditos de estudo,
## horas de foco e a escolha do pet que acompanha o herói.

var mode: String = "atributos"


func _init() -> void:
	win_title = "Personagem"
	win_size = Vector2(560, 300)


func build() -> void:
	if mode == "pets" or not GameState.has_chosen_class():
		_pets()
		return
	if mode == "habilidades":
		_skills()
		return
	if mode == "patentes":
		_ranks()
		return
	var pb := UI.button("Patentes  >", func() -> void:
		mode = "patentes"
		rebuild(), 90)
	add_to_body(pb, Vector2(208, 244))
	var sw := UI.button("Pets e história  >", func() -> void:
		mode = "pets"
		rebuild(), 120)
	add_to_body(sw, Vector2(410, 244))
	var sb := UI.button("Habilidades  >", func() -> void:
		mode = "habilidades"
		rebuild(), 100)
	add_to_body(sb, Vector2(304, 244))
	var cls: Dictionary = Data.CLASSES[GameState.player_class]
	var st := GameState.get_stats()
	# --- coluna esquerda: identidade e atributos
	var left := UI.vbox(3)
	add_to_body(left, Vector2(0, 0))
	var head := UI.hbox(8)
	left.add_child(head)
	var face := LpcPortrait.new()
	face.crop = Rect2(16, 8, 32, 32)
	face.px_scale = 1.0
	face.custom_minimum_size = Vector2(32, 32)
	face.clip_contents = true
	face.set_look(Looks.hero())
	head.add_child(face)
	var hv := UI.vbox(0)
	head.add_child(hv)
	hv.add_child(UI.label("%s  Nível %d" % [GameState.class_title(), GameState.level], UI.C_ORANGE_L))
	hv.add_child(UI.label("XP %s / %s" % [UI.fmt_int(GameState.xp), UI.fmt_int(GameState.xp_to_next)], UI.C_XP))
	hv.add_child(UI.label(cls["passive_text"], UI.C_GOOD))
	left.add_child(UI.hline())
	var rows := [
		["Vida", "%d / %d" % [GameState.hp, GameState.get_max_hp()], UI.C_HP],
		["Ataque", _n(st["atk"]), UI.C_TEXT],
		["Defesa", _n(st["def"]), UI.C_TEXT],
		["Velocidade", _n(st["speed"]), UI.C_TEXT],
		["Crítico", "%s%%  (dano x%s)" % [_n(st["crit"]), _n(st["crit_dmg"])], UI.C_TEXT],
		["Sorte", _n(st["luck"]), UI.C_TEXT],
		["Regeneração", "%s/s" % _n(st["regen"]), UI.C_TEXT],
		["Bônus de XP", "%d%%" % int(round(st["xp_pct"] * 100.0)), UI.C_XP],
		["Bônus de ouro", "%d%%" % int(round(st["gold_pct"] * 100.0 + st["luck"])), UI.C_GOLD],
		["Fome", "%d / 100" % GameState.hunger, UI.C_FOOD],
	]
	for r in rows:
		var row := UI.hbox(0)
		var k := UI.label(r[0], UI.C_DIM)
		k.custom_minimum_size.x = 92
		row.add_child(k)
		row.add_child(UI.label(r[1], r[2]))
		left.add_child(row)
	if GameState.hunger <= 0:
		left.add_child(UI.wrap_label("Com fome: ataque -20% e recompensas de foco pela metade.", UI.C_BAD, 200))
	left.add_child(UI.hline())
	var sk: Dictionary = Data.SKILLS[cls["skill"]]
	var skh := UI.hbox(5)
	left.add_child(skh)
	skh.add_child(UI.icon(Pix.skill_icon(sk["icon"]), 20))
	var skv := UI.vbox(0)
	skh.add_child(skv)
	skv.add_child(UI.label("%s  [1]  recarga %ds" % [sk["name"], int(sk["cd"])], UI.C_XP))
	skv.add_child(UI.wrap_label(sk["desc"], UI.C_DIM, 190))
	# --- coluna direita: talentos
	var right := UI.vbox(4)
	add_to_body(right, Vector2(250, 0))
	right.add_child(UI.label("Talentos  -  pontos livres: %d" % GameState.talent_points, UI.C_GOLD if GameState.talent_points > 0 else UI.C_DIM))
	right.add_child(UI.hline())
	for tid in Data.TALENT_ORDER:
		var t: Dictionary = Data.TALENTS[tid]
		var card := UI.card(UI.C_PANEL, UI.C_LINE)
		card.custom_minimum_size = Vector2(300, 32)
		right.add_child(card)
		var h := UI.hbox(6)
		card.add_child(h)
		h.add_child(UI.icon(Pix.skill_icon(t["icon"]), 20))
		var tv := UI.vbox(0)
		tv.custom_minimum_size.x = 232
		h.add_child(tv)
		tv.add_child(UI.label("%s  (%d)" % [t["name"], int(GameState.talents.get(tid, 0))], UI.C_ORANGE_L))
		tv.add_child(UI.label(t["desc"], UI.C_DIM))
		var plus := UI.button("+", func() -> void:
			if GameState.spend_talent(tid):
				Audio.sfx("star", -4.0), 18)
		plus.disabled = GameState.talent_points <= 0
		h.add_child(plus)
	var rs := UI.hbox(6)
	right.add_child(rs)
	var cost := GameState.respec_cost()
	var rb := UI.button("Redistribuir (%d ouro)" % cost, func() -> void:
		HUD.confirm("Redistribuir todos os talentos por %d de ouro?" % cost, func() -> void: GameState.respec_talents()), 0)
	rb.disabled = GameState.gold < cost or GameState.talents.is_empty()
	rs.add_child(rb)


# ------------------------------------------------------------------ Patentes (v3.7)
## Todas as patentes num lugar só: estudo, Guilda/Exército, classe, Arena e ofícios.
func _ranks() -> void:
	var back := UI.button("<  Atributos", func() -> void:
		mode = "atributos"
		rebuild(), 90)
	add_to_body(back, Vector2(450, 244))
	var v := UI.vbox(4)
	add_to_body(v, Vector2(0, 0))
	v.add_child(UI.label("Patentes de %s" % Story.hero_name(), UI.C_ORANGE_L, 2))
	v.add_child(UI.hline())
	var sr := Story.study_rank()
	var nxt := "rank máximo" if sr >= Data.STUDY_RANKS.size() - 1 else "%s h de %s h para %s" % [Story._hours_text(), str(Data.STUDY_RANKS[sr + 1][0]).trim_suffix(".0"), Data.STUDY_RANKS[sr + 1][1]]
	_rank_row(v, "Rank de Estudo", "%s  (+%d%% XP)" % [Story.study_rank_name(), int(Data.STUDY_RANK_XP * 100.0 * sr)], nxt, UI.C_GOLD)
	var pth := Story.path()
	if pth == "exercito":
		_rank_row(v, "Exército de Rocuetos", ArmyStory.patente_name(), "%d de %d patentes" % [ArmyStory.patente() + 1, StoryV4.PATENTES.size()], UI.C_HP)
	elif pth == "aventureiro":
		_rank_row(v, "Guilda dos Aventureiros", Story.rank_name(), "ranks F, E, D, C, B, A e S", UI.C_ORANGE_L)
	else:
		_rank_row(v, "Academia de Fontelúcida", Story.rank_name(), "a Formatura decide o caminho", UI.C_XP)
	_rank_row(v, "Classe", GameState.class_title() if GameState.has_chosen_class() else "-", "promoções nos níveis 25, 50, 75 e 100", UI.C_TEXT)
	_rank_row(v, "Arena", Arena.rank_name(), "Bronze, Prata, Ouro, Platina, Lenda", UI.C_XP)
	v.add_child(UI.hline())
	v.add_child(UI.label("Ofícios (o do seu caminho rende o dobro)", UI.C_DIM))
	for pid in Data.PROFESSIONS:
		var info: Dictionary = Data.PROFESSIONS[pid]
		var home := " *" if GameState.is_path_profession(pid) else ""
		_rank_row(v, str(info["name"]) + home, GameState.profession_rank_name(pid), str(info["where"]), UI.C_GOOD)


func _rank_row(parent: Control, title: String, value: String, note: String, col: Color) -> void:
	var h := UI.hbox(6)
	var t := UI.label(title, UI.C_DIM)
	t.custom_minimum_size.x = 150
	h.add_child(t)
	var vl := UI.label(value, col)
	vl.custom_minimum_size.x = 170
	h.add_child(vl)
	h.add_child(UI.label(note, UI.C_DIM))
	parent.add_child(h)


# ------------------------------------------------------------------ Habilidades e promoção
func _skills() -> void:
	var back := UI.button("<  Atributos", func() -> void:
		mode = "atributos"
		rebuild(), 90)
	add_to_body(back, Vector2(450, 244))
	add_to_body(UI.label("Magia inicial [2] + uma habilidade nova a cada 10 níveis", UI.C_DIM), Vector2(0, 0))
	var col := scroll_column(Vector2(0, 16), Vector2(326, 246))
	var prog := GameState.class_progression()
	var got := GameState.skill_milestones()
	for i in prog.size():
		var e: Dictionary = prog[i]
		var lv: int = Data.SKILL_LEVELS[i]
		var title := ""
		var desc := str(e.get("desc", ""))
		var icon := ""
		match str(e["type"]):
			"active":
				var sk: Dictionary = Data.SKILLS[e["skill"]]
				title = "%s  [%s]" % [sk["name"], Data.SKILL_KEYS[e["slot"]]]
				desc = "%s Recarga %ds." % [sk["desc"], int(sk["cd"])]
				icon = sk["icon"]
			"passive":
				title = "%s (passiva)" % e["name"]
				icon = e["icon"]
			_:
				var base: String = GameState.slot_skill(e["slot"]) if GameState.slot_skill(e["slot"]) != "" else str(Data.CLASSES[GameState.player_class]["skill"])
				title = "Maestria [%s]" % Data.SKILL_KEYS[e["slot"]]
				icon = Data.SKILLS[base]["icon"] if e["slot"] == "skill" else "spell/Upgrade"
		var have := i < got
		var card := UI.card(UI.C_PANEL, UI.C_ORANGE if have else UI.C_LINE)
		card.custom_minimum_size = Vector2(316, 30)
		var h := UI.hbox(6)
		card.add_child(h)
		var ic := UI.icon(Pix.skill_icon(icon), 18)
		ic.modulate = Color.WHITE if have else Color(1, 1, 1, 0.35)
		h.add_child(ic)
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label(("Inicial  %s" % title) if i == 0 else "Nv %d  %s" % [lv, title], UI.C_XP if have else UI.C_DIM))
		v.add_child(UI.wrap_label(desc, UI.C_TEXT if have else UI.C_DIM, 240))
		var st := UI.label("Liberada" if have else "Nível %d" % lv, UI.C_GOOD if have else UI.C_DIM)
		h.add_child(st)
		col.add_child(card)
	# --- promoção
	var right := UI.vbox(3)
	add_to_body(right, Vector2(336, 0))
	right.add_child(UI.label("Promoção de classe", UI.C_ORANGE_L))
	right.add_child(UI.label(GameState.class_title(), UI.C_GOLD))
	right.add_child(UI.hline())
	var tier := GameState.promotion_tier()
	var titles: Array = Data.PROMOTION_TITLES[GameState.player_class]
	for i in titles.size():
		var done := i < tier
		right.add_child(UI.label("Nv %d  %s" % [Data.PROMOTION_LEVELS[i], titles[i]], UI.C_GOOD if done else (UI.C_TEXT if i == tier else UI.C_DIM)))
	right.add_child(UI.wrap_label("Cada promoção: +5% de ataque, defesa e vida.", UI.C_DIM, 196))
	right.add_child(UI.hline())
	UIWindow.trial_box(right, 196)


func _n(v: float) -> String:
	if absf(v - round(v)) < 0.05:
		return str(int(round(v)))
	return ("%.1f" % v).replace(".", ",")



func _pets() -> void:
	if GameState.has_chosen_class():
		var back := UI.button("<  Atributos", func() -> void:
			mode = "atributos"
			rebuild(), 90)
		add_to_body(back, Vector2(430, 244))
	var left := UI.vbox(3)
	add_to_body(left, Vector2(0, 0))
	left.add_child(UI.label(Story.hero_name(), UI.C_ORANGE_L))
	left.add_child(UI.label(Story.rank_name() + "  -  " + Story.chapter_title(), UI.C_TEXT))
	left.add_child(UI.hline())
	left.add_child(UI.label("Créditos de estudo: %d" % Story.credits(), UI.C_ENERGY))
	left.add_child(UI.label("Próximo crédito em %d min de foco" % Story.minutes_to_next_credit(), UI.C_DIM))
	left.add_child(UI.label("Horas de foco na história: %s h" % Story._hours_text(), UI.C_XP))
	var ad := Arena.data()
	left.add_child(UI.label("Arena: %s  (%d prestígio, %dV / %dD)" % [Arena.rank_name(), Arena.prestige(), int(ad.get("wins", 0)), int(ad.get("losses", 0))], Arena.rank_color()))
	left.add_child(UI.hline())
	left.add_child(UI.wrap_label("%d min de foco = 1 crédito. Cada entrada na floresta ou na masmorra custa 1 (escadas também). Morrer tira 1 e o saldo pode ficar negativo até você estudar. Chefes pedem horas de foco." % Data.MINUTES_PER_CREDIT, UI.C_DIM, 220))
	left.add_child(UI.hline())
	if Story.mother_path() != "":
		left.add_child(UI.wrap_label("Bênção da %s: %s." % [Story.fmt("{mae}"), StoryData.MAE_BONUS_TEXT[Story.mother_path()]], UI.C_GOLD, 220))
		left.add_child(UI.hline())
	left.add_child(UI.label("Objetivo:", UI.C_ORANGE_L))
	left.add_child(UI.wrap_label(Story.objective_text(), UI.C_TEXT, 220))
	var right := UI.vbox(4)
	add_to_body(right, Vector2(250, 0))
	right.add_child(UI.label("Pets (um acompanha você por vez)", UI.C_ORANGE_L))
	right.add_child(UI.hline())
	var owned: Array = Story.pets()
	for pid in Data.PET_ORDER:
		var pd: Dictionary = Data.PETS[pid]
		var has := owned.has(pid)
		var card := UI.card(UI.C_PANEL, UI.C_ORANGE if Story.active_pet() == pid else UI.C_LINE)
		card.custom_minimum_size = Vector2(300, 40)
		right.add_child(card)
		var h := UI.hbox(6)
		card.add_child(h)
		h.add_child(_pet_icon(pid, has))
		var v := UI.vbox(0)
		v.custom_minimum_size.x = 196
		h.add_child(v)
		v.add_child(UI.label(pd["name"] if has else "???", UI.C_ORANGE_L if has else UI.C_DIM))
		v.add_child(UI.wrap_label(pd["desc"] if has else "Ainda não encontrado. Siga a história.", UI.C_DIM, 196))
		if has:
			var active: bool = Story.active_pet() == pid
			h.add_child(UI.button("Guardar" if active else "Levar", func() -> void:
				Story.set_pet("" if active else pid)
				rebuild(), 56))


## v3.0: ícone do pet com a animação do próprio sprite (antes era uma foto estática do rosto).
func _pet_icon(pid: String, has: bool) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(34, 34)
	if not has:
		return box
	var pd: Dictionary = Data.PETS[pid]
	var spr := AnimatedSprite2D.new()
	if pd["kind"] == "animal":
		spr.sprite_frames = Pix.animal_frames(pd["sheet"])
		spr.play("walk")
		spr.speed_scale = 0.7
	else:
		spr.sprite_frames = Pix.actor_frames("monsters/%s.png" % pd["sheet"])
		spr.play("walk_down")
		spr.speed_scale = 0.7
	spr.modulate = pd.get("tint", Color.WHITE)
	spr.scale = Vector2(1.9, 1.9)
	spr.position = Vector2(17, 17)
	box.add_child(spr)
	return box
