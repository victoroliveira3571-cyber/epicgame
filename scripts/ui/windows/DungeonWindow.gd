extends UIWindow

## Portão da Masmorra: os 5 andares da história (e as Profundezas depois do Rei Demônio).
## Cada andar abre com o capítulo e cobra pedágio em créditos de estudo (andar N = N créditos,
## no máximo 5) a cada entrada; voltar ao mesmo andar no mesmo dia sai mais caro (Data.travel_cost).

var start_floor: int = 1


func _init() -> void:
	win_title = "Portão da Masmorra"
	win_size = Vector2(560, 290)


func _floors() -> Array:
	var out: Array = []
	for f in range(1, Data.STORY_LAST_FLOOR + 1):
		out.append(f)
	if Story.chapter() >= 6:
		for f2 in range(Data.STORY_LAST_FLOOR + 1, maxi(GameState.best_floor + 2, Data.STORY_LAST_FLOOR + 2)):
			out.append(f2)
	return out


func build() -> void:
	var floors := _floors()
	if not Story.floor_unlocked(start_floor):
		start_floor = 1
	var v := UI.vbox(4)
	add_to_body(v, Vector2(0, 0))
	v.add_child(UI.label("Créditos de estudo: %d  (%s)    Horas de foco: %s h" % [Story.credits(), "1 por entrada", Story._hours_text()], UI.C_ENERGY))
	v.add_child(UI.hline())
	var col := scroll_column(Vector2(0, 22), Vector2(540, 150))
	for f in floors:
		var info := Data.floor_info(f)
		var unlocked := Story.floor_unlocked(f)
		var sub := ""
		if not unlocked:
			sub = "Liberado no capítulo %d" % int(info.get("chapter", 6)) if f <= Data.STORY_LAST_FLOOR else "Chegue ao andar anterior"
		else:
			sub = "Entrada: 1 crédito"
		if info.has("boss"):
			var bd := Data.boss_def(info["boss"])
			sub += "  -  Chefe: %s" % bd.get("name", "")
			if bd.has("gate_hours"):
				sub += " (%d h de foco)" % int(bd["gate_hours"])
		var fnum: int = f
		var row := list_row(Pix.tex("props/stairs_down_%d.png" % int(info["style"])), "Andar %d: %s" % [f, info["name"]],
			UI.C_ORANGE_L if f == start_floor else (UI.C_TEXT if unlocked else UI.C_DIM), sub, "", UI.C_DIM,
			"Escolher" if f != start_floor else "Escolhido", func() -> void:
				start_floor = fnum
				rebuild(), not unlocked or f == start_floor, 520)
		col.add_child(row)
	var bottom := UI.vbox(3)
	add_to_body(bottom, Vector2(0, 178))
	var cost := Game.floor_entry_cost(start_floor)
	var can := Story.floor_unlocked(start_floor) and Story.credits() >= cost
	var label := "Entrar no andar %d (pagar %d)" % [start_floor, cost]
	var go := UI.button(label, func() -> void:
		var floor_to_go := start_floor
		HUD.close_window()
		Game.enter_dungeon(floor_to_go), 160)
	go.disabled = not can
	bottom.add_child(go)
	if not Story.floor_unlocked(1):
		bottom.add_child(UI.wrap_label("A masmorra abre no capítulo 3. Siga o objetivo da história.", UI.C_BAD, 530))
	elif not can:
		bottom.add_child(UI.wrap_label("Faltam créditos: estude no Pomodoro (P), 1 crédito a cada %d min de foco (faltam %d min)." % [Data.MINUTES_PER_CREDIT, Story.minutes_to_next_credit()], UI.C_BAD, 530))
	else:
		bottom.add_child(UI.wrap_label("Toda entrada custa 1 crédito, e descer pela escada também. Se você morrer, perde 1 crédito (o saldo pode ficar negativo).", UI.C_DIM, 530))
