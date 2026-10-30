extends UIWindow

## Personagem (C): atributos, habilidade da classe e talentos; aba "Pets e história" com o
## rank, créditos de estudo, horas de foco e a escolha do pet que acompanha o herói.

var mode: String = "atributos"


func _init() -> void:
	win_title = "Personagem"
	win_size = Vector2(560, 300)


func build() -> void:
	if mode == "pets" or not GameState.has_chosen_class():
		_pets()
		return
	var sw := UI.button("Pets e história  >", func() -> void:
		mode = "pets"
		rebuild(), 120)
	add_to_body(sw, Vector2(410, 244))
	var cls: Dictionary = Data.CLASSES[GameState.player_class]
	var st := GameState.get_stats()
	# --- coluna esquerda: identidade e atributos
	var left := UI.vbox(3)
	add_to_body(left, Vector2(0, 0))
	var head := UI.hbox(8)
	left.add_child(head)
	head.add_child(UI.icon(Pix.atlas("chars/%s.png" % cls["sheet"], Rect2(0, 0, 16, 16)), 32))
	var hv := UI.vbox(0)
	head.add_child(hv)
	hv.add_child(UI.label("%s  Nível %d" % [cls["name"], GameState.level], UI.C_ORANGE_L))
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
	skv.add_child(UI.label("%s  [Q]  recarga %ds" % [sk["name"], int(sk["cd"])], UI.C_XP))
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
	left.add_child(UI.label("Cartas no Caderno: %d" % (GameState.story.get("cards", []) as Array).size(), UI.C_TEXT))
	left.add_child(UI.hline())
	left.add_child(UI.wrap_label("1 hora de foco = 1 crédito. Pedágios: floresta 1 por dia; andar N da masmorra custa N por dia (máximo 5). Os chefes pedem horas de foco acumuladas.", UI.C_DIM, 220))
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
		var ic := UI.icon(Pix.tex(pd["face"]) if has else null, 30)
		ic.modulate = pd.get("tint", Color.WHITE) if pid == "corvin" else Color.WHITE
		h.add_child(ic)
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
