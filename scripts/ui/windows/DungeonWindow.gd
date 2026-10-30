extends UIWindow

## Portão da Masmorra: escolhe o andar inicial (checkpoints a cada chefe) e entra.

var start_floor: int = 1


func _init() -> void:
	win_title = "Portão da Masmorra"
	win_size = Vector2(420, 250)


func _max_start() -> int:
	return maxi(1, ((GameState.best_floor - 1) / 5) * 5 + 1)


func build() -> void:
	start_floor = clampi(start_floor, 1, _max_start())
	var biome := Data.biome_for_floor(start_floor)
	var boss_floor := ((start_floor - 1) / 5 + 1) * 5
	var boss: Dictionary = Data.BOSSES[Data.boss_for_floor(boss_floor)]
	var v := UI.vbox(5)
	add_to_body(v, Vector2(0, 0))
	v.add_child(UI.label("Melhor andar alcançado: %d" % GameState.best_floor, UI.C_DIM))
	v.add_child(UI.hline())
	var sel := UI.hbox(8)
	v.add_child(sel)
	var prev := UI.button("<", func() -> void:
		start_floor -= 5
		rebuild(), 22)
	prev.disabled = start_floor <= 1
	sel.add_child(prev)
	var f := UI.label("Começar no andar %d" % start_floor, UI.C_ORANGE_L, 1)
	f.custom_minimum_size.x = 160
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sel.add_child(f)
	var nxt := UI.button(">", func() -> void:
		start_floor += 5
		rebuild(), 22)
	nxt.disabled = start_floor >= _max_start()
	sel.add_child(nxt)
	v.add_child(UI.label("Bioma: %s" % biome["name"], UI.C_TEXT))
	v.add_child(UI.label("Chefe do andar %d: %s" % [boss_floor, boss["name"]], UI.C_BAD))
	v.add_child(UI.wrap_label("Derrote o chefe para liberar a escada. Novos pontos de partida aparecem a cada chefe derrotado.", UI.C_DIM, 390))
	v.add_child(UI.hline())
	var en := UI.hbox(2)
	v.add_child(en)
	en.add_child(UI.label("Energia: ", UI.C_TEXT))
	for i in Data.ENERGY_MAX:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(8, 8)
		pip.color = UI.C_ENERGY if i < GameState.energy else Color("3a3426")
		en.add_child(pip)
	v.add_child(UI.wrap_label("Custo da expedição: %d de energia. Energia vem de sessões de foco (+%d) e hábitos (+%d)." % [Data.ENERGY_PER_RUN, Data.ENERGY_PER_FOCUS, Data.ENERGY_PER_HABIT], UI.C_DIM, 390))
	v.add_child(UI.spacer(4))
	var go := UI.button("Entrar na masmorra", func() -> void:
		var floor_to_go := start_floor
		HUD.close_window()
		Game.enter_dungeon(floor_to_go), 140)
	go.disabled = not Game.can_enter_dungeon()
	v.add_child(go)
	if not Game.can_enter_dungeon():
		v.add_child(UI.wrap_label("Sem energia! Complete uma sessão de foco (P) ou marque hábitos (T).", UI.C_BAD, 390))
