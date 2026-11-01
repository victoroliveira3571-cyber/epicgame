extends UIWindow

## Pomodoro: escolhe o tempo de foco, a pausa e o cenário. Com o foco rodando, a janela
## mostra o personagem estudando no cenário escolhido, com uma barra de controles embaixo
## e o painel "Sons" (playlist do cenário + sons de ambiente, ver PomoSound).

const FOCUS_PRESETS := [15, 25, 45, 60]
const BREAK_PRESETS := [5, 10, 15, 20]
const VIEW := Vector2(600, 282)        # área da cena no modo foco
const SCENE_CROP_TOP := 4.0            # corta só um fio do teto; o resto sai do chão, embaixo

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
var _worry_panel: Control
var _worry_edit: TextEdit
var _worry_open: bool = false


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
	_worry_panel = null
	if HUD.pomo_state == "idle":
		_build_settings()
	else:
		_build_running()
	if _worry_open and _view_key == "run":
		_toggle_worry(true)


func _current_key() -> String:
	return "idle" if HUD.pomo_state == "idle" else "run"


func refresh() -> void:
	pass  # o estado do jogo não muda esta janela; ela se atualiza em _process


func _process(_delta: float) -> void:
	if _current_key() != _view_key and body != null:
		rebuild()
		return
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
	if HUD.pomo_place != "":
		left.add_child(UI.wrap_label("%s (fixo: você está estudando neste lugar)" % StudyScene.SCENES[scene_id]["name"], UI.C_TEXT, 272))
	var grid := GridContainer.new()
	grid.visible = HUD.pomo_place == ""
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
	left.add_child(UI.wrap_label("Recompensa: %d XP, %d ouro, +%d fichas de estilo e +%d min para os créditos de estudo (1 crédito a cada %d min)" % [xp, gold, focus_min * Lpc.CREDITS_PER_MINUTE, focus_min, Data.MINUTES_PER_CREDIT], UI.C_GOLD, 272))
	left.add_child(UI.wrap_label("Pode finalizar antes: o tempo estudado conta (proporcional).", UI.C_DIM, 272))
	left.add_child(UI.spacer(4))
	var start_row := UI.hbox(4)
	left.add_child(start_row)
	start_row.add_child(UI.button("Iniciar foco (%d min)" % focus_min, func() -> void:
		HUD.pomodoro_start(focus_min, break_min), 130))
	start_row.add_child(UI.button("Histórico", func() -> void: HUD.open_window("historico"), 64))
	start_row.add_child(UI.button("Roupas", func() -> void: HUD.open_window("guarda_roupa"), 64))
	left.add_child(UI.button("Caixa de preocupações", func() -> void: HUD.open_window("preocupacoes"), 140))
	left.add_child(UI.spacer(6))
	left.add_child(UI.label("Som", UI.C_ORANGE_L))
	var snd := UI.hbox(4)
	left.add_child(snd)
	_sound_toggles(snd)
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
	var locked := HUD.pomo_place != ""
	if not locked:
		btns.add_child(UI.button("<", func() -> void: _step_scene(-1), 16))
	var sname := UI.label(StudyScene.SCENES[scene_id]["name"], UI.C_ORANGE_L)
	sname.custom_minimum_size.x = 104 if not locked else 140
	sname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btns.add_child(sname)
	if not locked:
		btns.add_child(UI.button(">", func() -> void: _step_scene(1), 16))
	btns.add_child(_sep())
	var worry_btn := UI.button("Preocupações", func() -> void: _toggle_worry(not _worry_open), 78)
	worry_btn.tooltip_text = "Anote o que está te distraindo sem sair do foco"
	btns.add_child(worry_btn)
	btns.add_child(UI.button("Histórico", func() -> void: HUD.open_window("historico"), 56))
	btns.add_child(UI.button("Voltar ao jogo", func() -> void: HUD.close_window(), 78))
	btns.position.x = roundf((VIEW.x - btns.get_combined_minimum_size().x) / 2.0)


func _sep() -> Control:
	var c := ColorRect.new()
	c.color = Color(UI.C_ORANGE, 0.5)
	c.custom_minimum_size = Vector2(1, 16)
	return c


## Relógio (tique-taque) como botão com luz.
func _sound_toggles(row: HBoxContainer) -> void:
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
## Caixa rápida de preocupações sobre a cena: anota o que distrai e volta ao estudo sem pausar o foco.
func _toggle_worry(open: bool) -> void:
	_worry_open = open
	if _worry_panel != null and is_instance_valid(_worry_panel):
		_worry_panel.queue_free()
		_worry_panel = null
	if not open:
		return
	var card := UI.card(Color(0.06, 0.05, 0.07, 0.94), UI.C_ORANGE)
	card.position = Vector2(8, 62)
	body.add_child(card)
	_worry_panel = card
	var v := UI.vbox(4)
	card.add_child(v)
	v.add_child(UI.label("Caixa de preocupações", UI.C_ORANGE_L))
	v.add_child(UI.wrap_label("Anotou, saiu da cabeça. Volte ao estudo.", UI.C_DIM, 230))
	_worry_edit = TextEdit.new()
	_worry_edit.custom_minimum_size = Vector2(230, 90)
	_worry_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_worry_edit.placeholder_text = "Preciso lembrar de..."
	_worry_edit.add_theme_font_override("font", Pix.font(1))
	_worry_edit.add_theme_font_size_override("font_size", 12)
	_worry_edit.add_theme_stylebox_override("normal", UI.flat(UI.C_BG, UI.C_ORANGE, 1, Vector4(5, 3, 5, 3)))
	_worry_edit.add_theme_stylebox_override("focus", UI.flat(UI.C_BG, UI.C_ORANGE_L, 1, Vector4(5, 3, 5, 3)))
	v.add_child(_worry_edit)
	var row := UI.hbox(4)
	v.add_child(row)
	row.add_child(UI.button("Guardar e fechar", func() -> void: _save_worry(), 100))
	row.add_child(UI.button("Fechar", func() -> void: _toggle_worry(false), 48))
	_worry_edit.call_deferred("grab_focus")


func _save_worry() -> void:
	var text := _worry_edit.text.strip_edges()
	if text != "":
		var worries: Array = GameState.story.get("worries", [])
		worries.append({"d": Time.get_date_string_from_system(), "t": text})
		while worries.size() > 30:
			worries.pop_front()
		GameState.story["worries"] = worries
		GameState.save_game()
		HUD.show_toast("Preocupação guardada. De volta ao foco.", UI.C_GOOD)
	_toggle_worry(false)
