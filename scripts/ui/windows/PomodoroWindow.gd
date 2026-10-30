extends UIWindow

## Pomodoro: escolhe o tempo de foco, a pausa e o cenário. Com o foco rodando, a janela
## mostra o personagem estudando no cenário escolhido, com uma barra de controles embaixo
## e o painel "Sons" (playlist do cenário + sons de ambiente, ver PomoSound).

const FOCUS_PRESETS := [15, 25, 45, 60]
const BREAK_PRESETS := [5, 10, 15, 20]
const VIEW := Vector2(600, 282)        # área da cena no modo foco
const SCENE_CROP_TOP := 16.0           # corta um pouco do teto para caber a barra de controles
const MIXER_W := 232.0

var focus_min: int = 25
var break_min: int = 5
var scene_id: String = "cafeteria"
var _view_key: String = ""
var _scene: StudyScene
var _time_label: Label
var _status_label: Label
var _bar: UI.Bar
var _pause_btn: Button
var _finish_btn: Button
var _mixer: Control
var _mixer_open: bool = false
var _track_label: Label


## Botão liga/desliga com uma luz (verde = ligado), para o estado ficar claro.
class Toggle extends Button:
	var on: bool = false
	var label_on: String = ""
	var label_off: String = ""

	func _init(text_on: String, text_off: String, value: bool, width: float) -> void:
		label_on = text_on
		label_off = text_off
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(width, 16)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		clip_text = true
		text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		set_on(value)

	func set_on(v: bool) -> void:
		on = v
		text = "    " + (label_on if on else label_off)
		modulate = Color.WHITE if on else Color(0.78, 0.74, 0.7)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2(6, size.y / 2.0 - 3), Vector2(6, 6))
		draw_rect(r.grow(1), Color("1a1412"))
		draw_rect(r, UI.C_GOOD if on else Color("6a2a24"))
		if on:
			draw_rect(Rect2(r.position, Vector2(2, 2)), Color(1, 1, 1, 0.6))


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
	_mixer = null
	_track_label = null
	if HUD.pomo_state == "idle":
		_build_settings()
	else:
		_build_running()
	if _mixer_open:
		_open_mixer()


func _current_key() -> String:
	return "idle" if HUD.pomo_state == "idle" else "run"


func refresh() -> void:
	pass  # o estado do jogo não muda esta janela; ela se atualiza em _process


func _process(_delta: float) -> void:
	if _current_key() != _view_key and body != null:
		rebuild()
		return
	if _track_label != null:
		var title := Audio.pomo_track_title()
		_track_label.text = ("Tocando: " + title) if title != "" else _no_track_text()
	if _view_key == "run" and _time_label != null:
		_time_label.text = UI.fmt_time(HUD.pomo_left)
		var st := HUD.pomo_state
		_status_label.text = {"focus": "FOCO", "break": "PAUSA", "paused": "PAUSADO"}.get(st, "")
		_pause_btn.text = "Seguir" if st == "paused" else "Pausar"
		_finish_btn.text = "Finalizar" if HUD.is_focus_running() else "Fim da pausa"
		_bar.fill = UI.C_GOOD if st == "break" else UI.C_ORANGE
		_bar.set_ratio(1.0 - HUD.pomo_left / maxf(HUD.pomo_total, 1.0))
		if _scene != null and _scene.state != st:
			_scene.state = st


func _no_track_text() -> String:
	if HUD.pomo_state == "idle":
		return "A playlist toca quando o foco começa."
	if PomoSound.scene_genre(scene_id) == "jogo":
		return "Música do jogo."
	return "Sem faixas neste estilo."


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
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	for sid in StudyScene.ORDER:
		var b := UI.button(StudyScene.SCENES[sid]["name"], func() -> void:
			scene_id = sid
			_save()
			rebuild(), 132)
		b.disabled = sid == scene_id
		grid.add_child(b)
	left.add_child(grid)
	left.add_child(UI.spacer(4))
	var xp := int(round(focus_min * 4.0))
	var gold := int(round(focus_min * 2.0))
	left.add_child(UI.wrap_label("Recompensa: %d XP, %d ouro, +%d energia e +%d créditos de estudo" % [xp, gold, Data.ENERGY_PER_FOCUS, focus_min * Lpc.CREDITS_PER_MINUTE], UI.C_GOLD, 272))
	left.add_child(UI.wrap_label("Pode finalizar antes: o tempo estudado conta (proporcional).", UI.C_DIM, 272))
	left.add_child(UI.spacer(4))
	var start_row := UI.hbox(4)
	left.add_child(start_row)
	start_row.add_child(UI.button("Iniciar foco (%d min)" % focus_min, func() -> void:
		HUD.pomodoro_start(focus_min, break_min), 130))
	start_row.add_child(UI.button("Histórico", func() -> void: HUD.open_window("historico"), 64))
	start_row.add_child(UI.button("Roupas", func() -> void: HUD.open_window("guarda_roupa"), 64))
	left.add_child(UI.spacer(6))
	left.add_child(UI.label("Som", UI.C_ORANGE_L))
	var snd := UI.hbox(4)
	left.add_child(snd)
	_sound_toggles(snd)
	snd.add_child(UI.button("Músicas e sons", func() -> void: _toggle_mixer(), 88))
	# prévia viva do cenário
	var preview := Control.new()
	preview.position = Vector2(284, 0)
	preview.custom_minimum_size = Vector2(316, 158)
	preview.size = Vector2(316, 158)
	preview.clip_contents = true
	body.add_child(preview)
	var sc := _make_scene()
	sc.sounds = false
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
	var g := PomoSound.scene_genre(scene_id)
	var n := PomoSound.tracks(g).size()
	var info := "Música: %s" % PomoSound.genre_name(g) + ("" if g == "jogo" else " (%d faixas)" % n)
	add_to_body(UI.label(info, UI.C_TEXT), Vector2(284, 208))
	var layers: Array = []
	for l in PomoSound.scene_layers(scene_id):
		if l["on"] and l["id"] != "acoes":
			layers.append(l["name"])
	add_to_body(UI.wrap_label("Ambiente: " + (", ".join(layers) if not layers.is_empty() else "silêncio"), UI.C_DIM, 316), Vector2(284, 222))
	add_to_body(UI.wrap_label("Com o foco rodando, esta janela mostra %s estudando. Esc volta ao jogo; o tempo continua." % _hero_name(), UI.C_DIM, 316), Vector2(284, 252))


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
	Audio.pomo_update()


func _make_scene() -> StudyScene:
	var sc := StudyScene.new()
	sc.scene_id = scene_id
	sc.class_id = GameState.player_class if GameState.has_chosen_class() else "cavaleiro"
	sc.look = GameState.look
	sc.state = HUD.pomo_state if HUD.pomo_state != "idle" else "focus"
	sc.reset_hold()
	return sc


# ------------------------------------------------------------------ foco em andamento
func _build_running() -> void:
	var holder := Control.new()
	holder.custom_minimum_size = VIEW
	holder.size = VIEW
	holder.clip_contents = true
	body.add_child(holder)
	_scene = _make_scene()
	_scene.scale = Vector2(0.5, 0.5)
	_scene.position = Vector2(0, -SCENE_CROP_TOP)
	holder.add_child(_scene)
	var frame := Panel.new()
	frame.position = Vector2(-2, -2)
	frame.size = VIEW + Vector2(4, 4)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UI.flat(Color.TRANSPARENT, UI.C_ORANGE, 2))
	body.add_child(frame)
	# tempo (canto superior esquerdo)
	var tag := UI.card(Color(0.06, 0.05, 0.07, 0.78), Color(UI.C_ORANGE, 0.8))
	tag.position = Vector2(8, 8)
	body.add_child(tag)
	var tv := UI.vbox(1)
	tag.add_child(tv)
	_status_label = UI.label("FOCO", UI.C_ORANGE_L)
	tv.add_child(_status_label)
	_time_label = UI.label("00:00", UI.C_TEXT, 2)
	tv.add_child(_time_label)
	_bar = UI.Bar.new(Vector2(96, 4), UI.C_ORANGE)
	tv.add_child(_bar)
	# som rápido (canto superior direito)
	var snd := UI.card(Color(0.06, 0.05, 0.07, 0.78), Color(UI.C_ORANGE, 0.8))
	body.add_child(snd)
	var sv := UI.hbox(3)
	snd.add_child(sv)
	_sound_toggles(sv)
	snd.position = Vector2(VIEW.x - 8 - snd.get_combined_minimum_size().x, 8)
	# barra de controles centralizada embaixo da cena
	var bar_box := Control.new()
	bar_box.position = Vector2(0, VIEW.y + 5)
	bar_box.size = Vector2(VIEW.x, 18)
	body.add_child(bar_box)
	var btns := UI.hbox(4)
	bar_box.add_child(btns)
	_pause_btn = UI.button("Pausar", func() -> void: HUD.pomodoro_toggle(), 54)
	_pause_btn.tooltip_text = "Pausar/seguir o tempo (P)"
	btns.add_child(_pause_btn)
	_finish_btn = UI.button("Finalizar", func() -> void: HUD.pomodoro_stop_prompt(), 68)
	_finish_btn.tooltip_text = "Termina agora e conta o tempo já estudado"
	btns.add_child(_finish_btn)
	var discard := UI.button("Descartar", func() -> void:
		HUD.confirm("Descartar este foco? O tempo estudado não será contado.", func() -> void: HUD.pomodoro_cancel()), 62)
	discard.disabled = not HUD.is_focus_running()
	btns.add_child(discard)
	btns.add_child(_sep())
	btns.add_child(UI.button("<", func() -> void: _step_scene(-1), 16))
	var sname := UI.label(StudyScene.SCENES[scene_id]["name"], UI.C_ORANGE_L)
	sname.custom_minimum_size.x = 104
	sname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btns.add_child(sname)
	btns.add_child(UI.button(">", func() -> void: _step_scene(1), 16))
	btns.add_child(_sep())
	btns.add_child(UI.button("Sons", func() -> void: _toggle_mixer(), 40))
	btns.add_child(UI.button("Histórico", func() -> void: HUD.open_window("historico"), 56))
	btns.add_child(UI.button("Voltar ao jogo", func() -> void: HUD.close_window(), 78))
	btns.position.x = roundf((VIEW.x - btns.get_combined_minimum_size().x) / 2.0)


func _sep() -> Control:
	var c := ColorRect.new()
	c.color = Color(UI.C_ORANGE, 0.5)
	c.custom_minimum_size = Vector2(1, 16)
	return c


## Música (liga/desliga) e relógio (tique-taque) como botões com luz.
func _sound_toggles(row: HBoxContainer) -> void:
	var music := Toggle.new("Música", "Música", GameState.music_on, 80)
	music.tooltip_text = "Liga/desliga a música"
	music.pressed.connect(func() -> void:
		Audio.ui_click()
		GameState.set_music_on(not GameState.music_on)
		music.set_on(GameState.music_on))
	row.add_child(music)
	var clock := Toggle.new("Relógio", "Relógio", GameState.clock_on, 86)
	clock.tooltip_text = "Tique-taque do relógio durante o foco"
	clock.pressed.connect(func() -> void:
		Audio.ui_click()
		GameState.set_clock_on(not GameState.clock_on)
		clock.set_on(GameState.clock_on))
	row.add_child(clock)


func _step_scene(d: int) -> void:
	var i := StudyScene.ORDER.find(scene_id)
	scene_id = StudyScene.ORDER[(i + d + StudyScene.ORDER.size()) % StudyScene.ORDER.size()]
	_save()
	Audio.sfx("magic_select", -6.0)
	rebuild()


# ------------------------------------------------------------------ painel de sons
func _toggle_mixer() -> void:
	_mixer_open = not _mixer_open
	if _mixer_open:
		_open_mixer()
	elif _mixer != null:
		_mixer.queue_free()
		_mixer = null
		_track_label = null


func _open_mixer() -> void:
	if _mixer != null:
		_mixer.queue_free()
	var card := UI.card(Color(0.07, 0.06, 0.07, 0.94), UI.C_ORANGE)
	card.custom_minimum_size.x = MIXER_W
	body.add_child(card)
	_mixer = card
	var v := UI.vbox(3)
	card.add_child(v)
	var head := UI.hbox(4)
	v.add_child(head)
	var t := UI.label("Sons: " + StudyScene.SCENES[scene_id]["name"], UI.C_ORANGE_L)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UI.button("X", func() -> void: _toggle_mixer(), 14))
	v.add_child(UI.label("Música do cenário", UI.C_TEXT))
	var gg := GridContainer.new()
	gg.columns = 3
	gg.add_theme_constant_override("h_separation", 3)
	gg.add_theme_constant_override("v_separation", 3)
	v.add_child(gg)
	var cur := PomoSound.scene_genre(scene_id)
	for g in PomoSound.GENRES:
		var gid: String = g[0]
		var n := PomoSound.tracks(gid).size()
		var b := UI.button(g[1], func() -> void:
			PomoSound.set_scene_genre(scene_id, gid)
			Audio.pomo_update()
			_open_mixer(), 66)
		b.disabled = gid == cur
		if gid != "jogo" and n == 0:
			b.disabled = true
			b.tooltip_text = "Sem faixas em assets/audio/pomodoro/musica/%s/" % gid
		gg.add_child(b)
	var tr := UI.hbox(4)
	v.add_child(tr)
	_track_label = UI.label("", UI.C_DIM)
	_track_label.custom_minimum_size.x = MIXER_W - 62
	_track_label.clip_text = true
	_track_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tr.add_child(_track_label)
	var nxt := UI.button("Próxima", func() -> void: Audio.pomo_next(), 48)
	nxt.disabled = HUD.pomo_state == "idle" or cur == "jogo"
	tr.add_child(nxt)
	var vr := UI.hbox(6)
	v.add_child(vr)
	var vl := UI.label("Volume", UI.C_TEXT)
	vl.custom_minimum_size.x = 64
	vr.add_child(vl)
	var vs := UI.slider(GameState.music_volume, func(x: float) -> void: GameState.set_music_volume(x), MIXER_W - 82)
	vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vr.add_child(vs)
	v.add_child(UI.hline())
	v.add_child(UI.label("Sons do ambiente", UI.C_TEXT))
	for l in PomoSound.scene_layers(scene_id):
		var id: String = l["id"]
		var row := UI.hbox(6)
		v.add_child(row)
		var tg := Toggle.new(l["name"], l["name"], l["on"], 132)
		row.add_child(tg)
		var sl := UI.slider(float(l["v"]), func(x: float) -> void:
			PomoSound.set_layer(scene_id, id, tg.on, x)
			Audio.pomo_update(), MIXER_W - 150)
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sl)
		tg.pressed.connect(func() -> void:
			Audio.ui_click()
			tg.set_on(not tg.on)
			PomoSound.set_layer(scene_id, id, tg.on, sl.value)
			Audio.pomo_update())
	if HUD.pomo_state == "idle":
		v.add_child(UI.wrap_label("Os sons tocam junto com o foco.", UI.C_DIM, MIXER_W - 10))
	card.reset_size()
	var sz := card.get_combined_minimum_size()
	var avail_h := VIEW.y if _view_key == "run" else body.size.y
	card.position = Vector2(body.size.x - sz.x - (8 if _view_key == "run" else 0), roundf(maxf(0.0, (avail_h - sz.y) / 2.0)))
