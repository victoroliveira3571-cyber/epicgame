extends UIWindow

## Pausa (Esc): continuar, volume, controles, voltar à cidade e sair.


func _init() -> void:
	win_title = "Pausa  -  Focus Town v3"
	win_size = Vector2(440, 330)


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
	top.add_child(UI.button("Salvar jogo", func() -> void: _save(), 80))
	top.add_child(UI.button("Créditos", func() -> void: HUD.open_window("creditos"), 60))
	var bottom := UI.hbox(6)
	v.add_child(bottom)
	bottom.add_child(UI.button("Menu inicial", func() -> void:
		HUD.confirm("Salvar e voltar ao menu inicial? Um foco em andamento é finalizado e contado.", func() -> void:
			if HUD.pomo_state != "idle":
				HUD.pomodoro_finish()
				HUD.pomodoro_cancel()
			GameState.leave_slot()
			HUD.close_window()
			Game.go_to_title()), 90))
	bottom.add_child(UI.button("Salvar e sair", func() -> void:
		GameState.save_now()
		get_tree().quit(), 90))
	_saved_label = UI.label(_slot_text(), UI.C_DIM)
	bottom.add_child(_saved_label)
	v.add_child(UI.hline())
	v.add_child(_slider("Volume geral", GameState.audio_volume, func(x: float) -> void: GameState.set_audio_volume(x)))
	v.add_child(_slider("Volume da música", GameState.music_volume, func(x: float) -> void: GameState.set_music_volume(x)))
	v.add_child(_slider("Efeitos", GameState.sfx_volume, func(x: float) -> void: GameState.set_sfx_volume(x)))
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
	var diff := UI.button("Dificuldade: " + GameState.DIFFICULTY_NAMES[GameState.difficulty], Callable(), 130)
	diff.tooltip_text = "\n".join([GameState.difficulty_desc(0), GameState.difficulty_desc(1), GameState.difficulty_desc(2)])
	diff.pressed.connect(func() -> void:
		Audio.ui_click()
		GameState.set_difficulty((GameState.difficulty + 1) % 3)
		diff.text = "Dificuldade: " + GameState.DIFFICULTY_NAMES[GameState.difficulty]
		HUD.show_toast(GameState.difficulty_desc() + " Vale para os próximos monstros.", UI.C_XP))
	var toggles := UI.hbox(6)
	toggles.add_child(mute)
	toggles.add_child(music)
	toggles.add_child(diff)
	var aim := UI.button("Mira: automática" if GameState.auto_aim else "Mira: manual", Callable(), 120)
	aim.tooltip_text = "Automática: vira para o inimigo próximo ao atacar. Manual: ataca para onde você olha."
	aim.pressed.connect(func() -> void:
		Audio.ui_click()
		GameState.set_auto_aim(not GameState.auto_aim)
		aim.text = "Mira: automática" if GameState.auto_aim else "Mira: manual")
	var safe := UI.button("Zona segura: ligada" if GameState.safe_zone else "Zona segura: desligada", Callable(), 150)
	safe.tooltip_text = "Ligada: golpes não ferem moradores na cidade (evita prisão por acidente). Desligada: a lei volta a valer."
	safe.pressed.connect(func() -> void:
		Audio.ui_click()
		GameState.set_safe_zone(not GameState.safe_zone)
		safe.text = "Zona segura: ligada" if GameState.safe_zone else "Zona segura: desligada")
	var toggles2 := UI.hbox(6)
	toggles2.add_child(aim)
	toggles2.add_child(safe)
	v.add_child(toggles)
	v.add_child(toggles2)
	v.add_child(UI.hline())
	v.add_child(UI.label("Controles: clique na tecla e aperte a nova (Esc cancela)", UI.C_ORANGE_L))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 1)
	v.add_child(grid)
	for pair in Game.REBINDABLE:
		var action: String = pair[0]
		var dl := UI.label(pair[1], UI.C_DIM)
		dl.custom_minimum_size.x = 150
		grid.add_child(dl)
		var btn := UI.button(Game.key_name(action), Callable(), 60)
		btn.pressed.connect(func() -> void: _start_capture(action))
		_key_btns[action] = btn
		grid.add_child(btn)
	v.add_child(UI.button("Restaurar teclas padrão", func() -> void:
		Game.reset_keybinds()
		_refresh_keys()
		HUD.show_toast("Teclas voltaram ao padrão.", UI.C_GOOD), 180))


var _saved_label: Label
var _key_btns := {}    # ação -> botão com a tecla atual
var _capturing := ""   # ação que está esperando a nova tecla


func _start_capture(action: String) -> void:
	_capturing = action
	_key_btns[action].text = "..."
	get_viewport().gui_release_focus()
	HUD.show_toast("Aperte a nova tecla (Esc cancela).", UI.C_XP)


func _refresh_keys() -> void:
	for action in _key_btns:
		_key_btns[action].text = Game.key_name(action)


func _unhandled_key_input(ev: InputEvent) -> void:
	if _capturing == "" or not (ev is InputEventKey) or not ev.pressed or ev.echo:
		super(ev)
		return
	get_viewport().set_input_as_handled()
	var action := _capturing
	_capturing = ""
	if ev.keycode != KEY_ESCAPE:
		var key_txt := OS.get_keycode_string(ev.physical_keycode)
		for pair in Game.REBINDABLE:
			if pair[0] != action and Game.key_name(pair[0]) == key_txt:
				HUD.show_toast("Atenção: %s também usa essa tecla." % pair[1], UI.C_GOLD)
		Game.rebind(action, ev.physical_keycode)
	_refresh_keys()


func _slot_text() -> String:
	return "Espaço %d" % GameState.slot if GameState.slot >= 1 else "Jogo de teste"


## Grava agora no espaço em uso (o jogo também grava sozinho de tempos em tempos).
func _save() -> void:
	GameState.save_now()
	Audio.sfx2("ding", -8.0, 0.0)
	var t := Time.get_time_dict_from_system()
	_saved_label.text = "%s  -  salvo às %02d:%02d" % [_slot_text(), t["hour"], t["minute"]]
	_saved_label.add_theme_color_override("font_color", UI.C_GOOD)
	HUD.show_toast("Jogo salvo no %s." % _slot_text().to_lower(), UI.C_GOOD)


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
