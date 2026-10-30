extends UIWindow

## Pausa (Esc): continuar, volume, controles, voltar à cidade e sair.


func _init() -> void:
	win_title = "Pausa"
	win_size = Vector2(440, 290)


func build() -> void:
	var v := UI.vbox(5)
	add_to_body(v, Vector2(0, 0))
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(UI.button("Continuar", func() -> void: HUD.close_window(), 90))
	if GameState.in_dungeon:
		top.add_child(UI.button("Voltar à cidade", func() -> void:
			HUD.confirm("Abandonar a expedição e voltar para a cidade? Você mantém o que coletou.", func() -> void:
				HUD.close_window()
				Game.finish_run(false)), 100))
	top.add_child(UI.button("Créditos", func() -> void: HUD.open_window("creditos"), 60))
	top.add_child(UI.button("Salvar e sair", func() -> void:
		GameState.save_now()
		get_tree().quit(), 90))
	v.add_child(UI.hline())
	v.add_child(_slider("Volume geral", GameState.audio_volume, func(x: float) -> void: GameState.set_audio_volume(x)))
	v.add_child(_slider("Volume da música", GameState.music_volume, func(x: float) -> void: GameState.set_music_volume(x)))
	# o botão é criado antes do clique ser ligado: a função precisa enxergar o botão já pronto
	var mute := UI.button("Som: ligado" if not GameState.audio_muted else "Som: desligado", Callable(), 100)
	mute.pressed.connect(func() -> void:
		Audio.ui_click()
		GameState.set_audio_muted(not GameState.audio_muted)
		mute.text = "Som: ligado" if not GameState.audio_muted else "Som: desligado")
	var music := UI.button("Música: ligada" if GameState.music_on else "Música: desligada", Callable(), 100)
	music.pressed.connect(func() -> void:
		Audio.ui_click()
		GameState.set_music_on(not GameState.music_on)
		music.text = "Música: ligada" if GameState.music_on else "Música: desligada")
	var toggles := UI.hbox(6)
	toggles.add_child(mute)
	toggles.add_child(music)
	v.add_child(toggles)
	v.add_child(UI.hline())
	v.add_child(UI.label("Controles", UI.C_ORANGE_L))
	var keys := [
		["WASD / setas", "Mover"], ["Espaço / J", "Atacar"], ["Shift / K", "Rolar"], ["Q / L", "Habilidade da classe"],
		["E", "Interagir"], ["H", "Poção"], ["F", "Comer"], ["I", "Inventário"], ["C", "Personagem"],
		["T", "Hábitos"], ["G", "Missões"], ["P", "Pomodoro"], ["Esc", "Pausa"],
	]
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 1)
	v.add_child(grid)
	for k in keys:
		var kl := UI.label(k[0], UI.C_ORANGE_L)
		kl.custom_minimum_size.x = 80
		grid.add_child(kl)
		var dl := UI.label(k[1], UI.C_DIM)
		dl.custom_minimum_size.x = 120
		grid.add_child(dl)


func refresh() -> void:
	pass  # sliders mexem no estado: não reconstruir enquanto arrasta


func _slider(title: String, value: float, on_change: Callable) -> Control:
	var h := UI.hbox(8)
	var l := UI.label(title, UI.C_TEXT)
	l.custom_minimum_size.x = 100
	h.add_child(l)
	var s := UI.slider(value, on_change, 200)
	h.add_child(s)
	return h
