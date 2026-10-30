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
	top.add_child(UI.button("Salvar e sair", func() -> void:
		GameState.save_now()
		get_tree().quit(), 90))
	v.add_child(UI.hline())
	v.add_child(_slider("Volume geral", GameState.audio_volume, func(x: float) -> void: GameState.set_audio_volume(x)))
	v.add_child(_slider("Volume da música", GameState.music_volume, func(x: float) -> void: GameState.set_music_volume(x)))
	var mute: Button
	mute = UI.button("Som: ligado" if not GameState.audio_muted else "Som: desligado", func() -> void:
		GameState.set_audio_muted(not GameState.audio_muted)
		mute.text = "Som: ligado" if not GameState.audio_muted else "Som: desligado", 100)
	v.add_child(mute)
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
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(200, 12)
	s.focus_mode = Control.FOCUS_NONE
	s.add_theme_stylebox_override("slider", UI.flat(UI.C_PANEL2, UI.C_LINE, 1, Vector4(0, 2, 0, 2)))
	s.add_theme_stylebox_override("grabber_area", UI.flat(UI.C_ORANGE, Color.TRANSPARENT, 0, Vector4(0, 2, 0, 2)))
	s.add_theme_stylebox_override("grabber_area_highlight", UI.flat(UI.C_ORANGE_L, Color.TRANSPARENT, 0, Vector4(0, 2, 0, 2)))
	s.value_changed.connect(func(x: float) -> void: on_change.call(x))
	h.add_child(s)
	return h
