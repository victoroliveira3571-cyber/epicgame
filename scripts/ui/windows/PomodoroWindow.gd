extends UIWindow

## Pomodoro: escolhe o tempo de foco, a pausa e o cenário. Com o foco rodando, a janela
## mostra a animação do seu personagem estudando no cenário escolhido.

const FOCUS_PRESETS := [15, 25, 45, 60]
const BREAK_PRESETS := [5, 10, 15, 20]

var focus_min: int = 25
var break_min: int = 5
var scene_id: String = "cafeteria"
var _view_key: String = ""
var _scene: StudyScene
var _time_label: Label
var _status_label: Label
var _bar: UI.Bar
var _pause_btn: Button


func _init() -> void:
	win_title = "Pomodoro"
	win_size = Vector2(620, 346)


func build() -> void:
	focus_min = int(GameState.pomo_cfg.get("focus", 25))
	break_min = int(GameState.pomo_cfg.get("break", 5))
	scene_id = str(GameState.pomo_cfg.get("scene", "cafeteria"))
	if not StudyScene.SCENES.has(scene_id):
		scene_id = "cafeteria"
	_view_key = _current_key()
	_scene = null
	if HUD.pomo_state == "idle":
		_build_settings()
	else:
		_build_running()


func _current_key() -> String:
	return "idle" if HUD.pomo_state == "idle" else "run"


func refresh() -> void:
	pass  # o estado do jogo não muda esta janela; ela se atualiza em _process


func _exit_tree() -> void:
	Audio.set_ambience("")
	super()


func _process(_delta: float) -> void:
	# a cena da natureza ganha o som de fundo enquanto o foco roda
	Audio.set_ambience("ambience_nature" if (_view_key == "run" and scene_id == "natureza") else "", -16.0)
	if _current_key() != _view_key and body != null:
		rebuild()
		return
	if _view_key == "run" and _time_label != null:
		_time_label.text = UI.fmt_time(HUD.pomo_left)
		var st := HUD.pomo_state
		_status_label.text = {"focus": "FOCO", "break": "PAUSA", "paused": "PAUSADO"}.get(st, "")
		_pause_btn.text = "Seguir" if st == "paused" else "Pausar"
		_bar.fill = UI.C_GOOD if (st == "break" or (st == "paused" and false)) else UI.C_ORANGE
		_bar.set_ratio(1.0 - HUD.pomo_left / maxf(HUD.pomo_total, 1.0))
		if _scene != null:
			_scene.state = st


# ------------------------------------------------------------------ configuração
func _build_settings() -> void:
	var left := UI.vbox(4)
	add_to_body(left, Vector2(0, 0))
	left.add_child(UI.label("Tempo de foco (minutos)", UI.C_ORANGE_L))
	left.add_child(_stepper(FOCUS_PRESETS, focus_min, 5, 5, 180, func(v: int) -> void:
		focus_min = v
		_save()
		rebuild()))
	left.add_child(UI.spacer(2))
	left.add_child(UI.label("Tempo de pausa (minutos)", UI.C_ORANGE_L))
	left.add_child(_stepper(BREAK_PRESETS, break_min, 1, 1, 60, func(v: int) -> void:
		break_min = v
		_save()
		rebuild()))
	left.add_child(UI.spacer(2))
	left.add_child(UI.label("Cenário", UI.C_ORANGE_L))
	var grid := GridContainer.new()
	grid.columns = 2
	for sid in StudyScene.ORDER:
		var b := UI.button(StudyScene.SCENES[sid]["name"], func() -> void:
			scene_id = sid
			_save()
			rebuild(), 128)
		b.disabled = sid == scene_id
		grid.add_child(b)
	left.add_child(grid)
	left.add_child(UI.spacer(4))
	var xp := int(round(focus_min * 4.0))
	var gold := int(round(focus_min * 2.0))
	left.add_child(UI.label("Recompensa: %d XP, %d ouro, +%d energia" % [xp, gold, Data.ENERGY_PER_FOCUS], UI.C_GOLD))
	left.add_child(UI.label("Cancelar no meio não dá recompensa (e não pune).", UI.C_DIM))
	left.add_child(UI.spacer(4))
	var start_row := UI.hbox(6)
	left.add_child(start_row)
	start_row.add_child(UI.button("Iniciar foco (%d min)" % focus_min, func() -> void:
		HUD.pomodoro_start(focus_min, break_min), 150))
	start_row.add_child(UI.button("Histórico", func() -> void: HUD.open_window("historico"), 70))
	left.add_child(UI.spacer(4))
	left.add_child(UI.label("Som", UI.C_ORANGE_L))
	left.add_child(_sound_controls(true))
	# prévia viva do cenário
	var preview := Control.new()
	preview.position = Vector2(284, 0)
	preview.custom_minimum_size = Vector2(316, 158)
	preview.size = Vector2(316, 158)
	preview.clip_contents = true
	body.add_child(preview)
	var sc := _make_scene()
	sc.scale = Vector2(316.0 / StudyScene.W, 316.0 / StudyScene.W)
	preview.add_child(sc)
	var frame := Panel.new()
	frame.position = preview.position - Vector2(2, 2)
	frame.size = Vector2(320, 162)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.flat(Color.TRANSPARENT, UI.C_ORANGE, 2))
	body.add_child(frame)
	add_to_body(UI.label(StudyScene.SCENES[scene_id]["name"], UI.C_ORANGE_L), Vector2(284, 166))
	add_to_body(UI.wrap_label(StudyScene.SCENES[scene_id]["desc"], UI.C_DIM, 316), Vector2(284, 180))
	add_to_body(UI.wrap_label("Dica: com o foco rodando, esta janela mostra %s estudando. Feche com Esc para voltar ao jogo; o tempo continua." % _hero_name(), UI.C_DIM, 316), Vector2(284, 214))


func _hero_name() -> String:
	return Data.CLASSES[GameState.player_class]["name"] if GameState.has_chosen_class() else "seu personagem"


func _stepper(presets: Array, value: int, step: int, lo: int, maxv: int, callback: Callable) -> Control:
	var row := UI.hbox(3)
	for p in presets:
		var b := UI.button(str(p), func() -> void: callback.call(p), 28)
		b.disabled = p == value
		row.add_child(b)
	var minus := UI.button("-", func() -> void: callback.call(clampi(value - step, lo, maxv)), 18)
	var plus := UI.button("+", func() -> void: callback.call(clampi(value + step, lo, maxv)), 18)
	row.add_child(minus)
	var v := UI.label("%d" % value, UI.C_TEXT)
	v.custom_minimum_size.x = 22
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(v)
	row.add_child(plus)
	return row


func _save() -> void:
	GameState.pomo_cfg["focus"] = focus_min
	GameState.pomo_cfg["break"] = break_min
	GameState.pomo_cfg["scene"] = scene_id
	GameState.save_game()


func _make_scene() -> StudyScene:
	var sc := StudyScene.new()
	sc.scene_id = scene_id
	sc.class_id = GameState.player_class if GameState.has_chosen_class() else "cavaleiro"
	sc.look = GameState.look
	sc.state = HUD.pomo_state if HUD.pomo_state != "idle" else "focus"
	return sc


# ------------------------------------------------------------------ foco em andamento
func _build_running() -> void:
	_scene = _make_scene()
	_scene.position = Vector2(0, 0)
	var holder := Control.new()
	holder.position = Vector2(0, 0)
	holder.custom_minimum_size = Vector2(600, 300)
	holder.size = Vector2(600, 300)
	holder.clip_contents = true
	body.add_child(holder)
	_scene.scale = Vector2(0.5, 0.5)
	holder.add_child(_scene)
	var frame := Panel.new()
	frame.position = Vector2(-2, -2)
	frame.size = Vector2(604, 304)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.flat(Color.TRANSPARENT, UI.C_ORANGE, 2))
	body.add_child(frame)
	# painel do tempo (canto superior esquerdo sobre a cena)
	var tag := UI.card(Color(0.06, 0.05, 0.07, 0.72), Color(UI.C_ORANGE, 0.8))
	tag.position = Vector2(10, 10)
	body.add_child(tag)
	var tv := UI.vbox(0)
	tag.add_child(tv)
	_status_label = UI.label("FOCO", UI.C_ORANGE_L)
	tv.add_child(_status_label)
	_time_label = UI.label("00:00", UI.C_TEXT, 2)
	tv.add_child(_time_label)
	_bar = UI.Bar.new(Vector2(96, 4), UI.C_ORANGE)
	tv.add_child(_bar)
	# som (canto superior direito)
	var snd := UI.card(Color(0.06, 0.05, 0.07, 0.72), Color(UI.C_ORANGE, 0.8))
	body.add_child(snd)
	snd.add_child(_sound_controls(false))
	snd.position = Vector2(600 - 10 - snd.get_combined_minimum_size().x, 10)
	# botões (canto inferior direito)
	var btns := UI.hbox(4)
	btns.position = Vector2(236, 278)
	body.add_child(btns)
	_pause_btn = UI.button("Pausar", func() -> void: HUD.pomodoro_toggle(), 56)
	btns.add_child(_pause_btn)
	btns.add_child(UI.button("Trocar cena", func() -> void: _next_scene(), 74))
	btns.add_child(UI.button("Cancelar", func() -> void:
		HUD.confirm("Cancelar o foco? Você perde a recompensa.", func() -> void: HUD.pomodoro_cancel()), 56))
	btns.add_child(UI.button("Histórico", func() -> void: HUD.open_window("historico"), 56))
	btns.add_child(UI.button("Voltar ao jogo", func() -> void: HUD.close_window(), 80))


## Música liga/desliga + volume e o tique-taque do relógio. `wide` = layout da tela de configuração.
func _sound_controls(wide: bool) -> Control:
	var v := UI.vbox(3)
	var row := UI.hbox(4)
	v.add_child(row)
	var music: Button
	music = UI.button(_music_text(), func() -> void:
		GameState.set_music_on(not GameState.music_on)
		music.text = _music_text(), 84)
	row.add_child(music)
	var vol := UI.slider(GameState.music_volume, func(x: float) -> void: GameState.set_music_volume(x), 90 if wide else 60)
	vol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vol.tooltip_text = "Volume da música"
	row.add_child(vol)
	var clock: Button
	clock = UI.button(_clock_text(), func() -> void:
		GameState.set_clock_on(not GameState.clock_on)
		clock.text = _clock_text(), 84)
	if wide:
		row.add_child(clock)
	else:
		v.add_child(clock)
	return v


func _music_text() -> String:
	return "Música: sim" if GameState.music_on else "Música: não"


func _clock_text() -> String:
	return "Relógio: sim" if GameState.clock_on else "Relógio: não"


func _next_scene() -> void:
	var i := StudyScene.ORDER.find(scene_id)
	scene_id = StudyScene.ORDER[(i + 1) % StudyScene.ORDER.size()]
	_save()
	if _scene != null:
		_scene.scene_id = scene_id
		_scene.t = 0.0
	Audio.sfx("magic_select", -6.0)
	HUD.show_toast("Cenário: %s" % StudyScene.SCENES[scene_id]["name"], UI.C_DIM)
