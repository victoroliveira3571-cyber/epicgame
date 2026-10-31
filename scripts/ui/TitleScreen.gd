extends CanvasLayer

## Menu inicial (cena de abertura): Novo jogo, Carregar jogo e Sair, com os 3 espaços de save.
## Novo jogo: escolhe um espaço (vazio, ou sobrescreve com confirmação) e abre a criação do
## personagem. Carregar: escolhe um espaço com jogo e entra na cidade. Desenhado em 640x360.

const TOWN := "res://scenes/Main.tscn"

var root: Control
var _menu: VBoxContainer
var _slots_panel: Panel
var _mode: String = ""          # "novo" | "carregar"
var _t: float = 0.0
var _walkers: Array = []


func _ready() -> void:
	layer = 10
	scale = Vector2(2, 2)
	# testes automáticos (--save=) pulam o menu
	if GameState.slot == -1:
		get_tree().change_scene_to_file.call_deferred(TOWN)
		return
	HUD.on_scene_ready("")
	Audio.play_music("title")
	Audio.set_place_loop("")
	root = Control.new()
	root.size = UI.SIZE
	root.theme = UI.theme()
	add_child(root)
	_background()
	_title()
	_build_menu()


func _background() -> void:
	var hour := int(Time.get_time_dict_from_system()["hour"])
	var name := "campo_dia" if hour >= 7 and hour < 17 else ("mar_entardecer" if hour >= 17 and hour < 20 else "montanhas_noite")
	var path := "res://assets/custom/paisagem/%s.png" % name
	if ResourceLoader.exists(path):
		var tr := TextureRect.new()
		tr.texture = load(path)
		tr.size = UI.SIZE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		root.add_child(tr)
	var veil := ColorRect.new()
	veil.color = Color(0.04, 0.03, 0.07, 0.45)
	veil.size = UI.SIZE
	root.add_child(veil)
	# aventureiros andando no chão do menu
	var ground := ColorRect.new()
	ground.color = Color(0.05, 0.04, 0.06, 0.55)
	ground.position = Vector2(0, 300)
	ground.size = Vector2(640, 60)
	root.add_child(ground)
	for key in ["pietro", "helena", "ivo", "lin", "marta"]:
		var p := AppearanceEditor.Preview.new()
		p.size = Vector2(70, 80)
		p.px = 1.0
		p.set_meta("speed", randf_range(14.0, 22.0))
		p.position = Vector2(randf_range(-60, 640), 238)
		p.set_look(Looks.of(key))
		p.draw_frame = false
		p.fixed_row = 3
		root.add_child(p)
		_walkers.append(p)


func _title() -> void:
	var t := UI.label("Focus Town", Color("ffd36a"), 3)
	t.size = Vector2(640, 40)
	t.position = Vector2(0, 26)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	t.add_theme_constant_override("shadow_offset_x", 2)
	t.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(t)
	var s := UI.label("Estude de verdade. Recupere as páginas da cidade.", Color("f4ecda"))
	s.size = Vector2(640, 14)
	s.position = Vector2(0, 70)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	s.add_theme_constant_override("shadow_offset_x", 1)
	s.add_theme_constant_override("shadow_offset_y", 1)
	root.add_child(s)


func _build_menu() -> void:
	_menu = UI.vbox(6)
	_menu.position = Vector2(250, 110)
	root.add_child(_menu)
	_menu.add_child(UI.button("Novo jogo", func() -> void: _open_slots("novo"), 140))
	var load := UI.button("Carregar jogo", func() -> void: _open_slots("carregar"), 140)
	load.disabled = not _any_saved()
	_menu.add_child(load)
	_menu.add_child(UI.button("Sair", func() -> void: get_tree().quit(), 140))
	var ver := UI.label("v3  -  3 espaços de save", Color(1, 1, 1, 0.5))
	ver.position = Vector2(8, 344)
	root.add_child(ver)


func _any_saved() -> bool:
	for n in range(1, GameState.SLOT_COUNT + 1):
		if not GameState.slot_info(n).is_empty():
			return true
	return false


func _process(delta: float) -> void:
	_t += delta
	for p in _walkers:
		var w := p as Control
		w.position.x += float(w.get_meta("speed")) * delta
		if w.position.x > 660:
			w.position.x = -80


# ================================================================== Espaços
func _open_slots(mode: String) -> void:
	_mode = mode
	Audio.sfx2("ui_pack1", -8.0)
	_menu.visible = false
	if _slots_panel != null:
		_slots_panel.queue_free()
	_slots_panel = UI.window_panel(Vector2(520, 230))
	_slots_panel.position = Vector2(60, 100)
	root.add_child(_slots_panel)
	var title := UI.label("Novo jogo: escolha um espaço" if mode == "novo" else "Carregar jogo", UI.C_ORANGE_L)
	title.position = Vector2(12, 7)
	_slots_panel.add_child(title)
	var v := UI.vbox(6)
	v.position = Vector2(10, 28)
	_slots_panel.add_child(v)
	for n in range(1, GameState.SLOT_COUNT + 1):
		v.add_child(_slot_row(n))
	var back := UI.button("Voltar", func() -> void: _close_slots(), 70)
	back.position = Vector2(440, 200)
	_slots_panel.add_child(back)


func _close_slots() -> void:
	Audio.sfx("ui_back", -6.0)
	if _slots_panel != null:
		_slots_panel.queue_free()
		_slots_panel = null
	_menu.visible = true


func _slot_row(n: int) -> Control:
	var info := GameState.slot_info(n)
	var card := UI.card()
	card.custom_minimum_size = Vector2(500, 52)
	var h := UI.hbox(8)
	card.add_child(h)
	var face := LpcPortrait.new()
	face.crop = Rect2(16, 8, 32, 32)
	face.px_scale = 1.25
	face.custom_minimum_size = Vector2(40, 40)
	face.clip_contents = true
	h.add_child(face)
	var v := UI.vbox(1)
	v.custom_minimum_size.x = 330
	h.add_child(v)
	if info.is_empty():
		v.add_child(UI.label("Espaço %d  -  vazio" % n, UI.C_DIM))
		v.add_child(UI.label("Nenhum jogo gravado aqui.", UI.C_DIM))
	elif info.get("broken", false):
		v.add_child(UI.label("Espaço %d  -  arquivo danificado" % n, UI.C_BAD))
	else:
		var lk: Dictionary = info["look"]
		if lk.is_empty():
			lk = LpcW.default_look("female" if info["gender"] == "f" else "muscular")
		face.set_look(lk)
		var cls: String = str(Data.CLASSES.get(info["class"], {}).get("name", "Aprendiz"))
		v.add_child(UI.label("Espaço %d  -  %s, %s Nv %d" % [n, info["hero"], cls, info["level"]], UI.C_TEXT))
		var when := Time.get_datetime_string_from_unix_time(int(info["saved"]) + _tz_offset(), true).replace("T", " ")
		v.add_child(UI.label("Capítulo %d  -  %s ouro  -  %s de jogo  -  salvo em %s" % [
			info["chapter"], UI.fmt_int(info["gold"]), _hours(float(info["playtime"])), when.substr(0, 16)], UI.C_DIM))
	var buttons := UI.vbox(2)
	h.add_child(buttons)
	if _mode == "novo":
		buttons.add_child(UI.button("Começar" if info.is_empty() else "Sobrescrever", func() -> void: _new_game(n, info.is_empty()), 90))
	else:
		var play := UI.button("Jogar", func() -> void: _load(n), 90)
		play.disabled = info.is_empty() or info.get("broken", false)
		buttons.add_child(play)
		if not info.is_empty():
			buttons.add_child(UI.button("Apagar", func() -> void:
				HUD.confirm("Apagar o jogo do espaço %d? Não dá para desfazer." % n, func() -> void:
					GameState.delete_slot(n)
					_open_slots(_mode)), 90))
	return card


func _tz_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _hours(sec: float) -> String:
	var m := int(sec / 60.0)
	return "%dh%02d" % [m / 60, m % 60]


func _new_game(n: int, empty: bool) -> void:
	if not empty:
		HUD.confirm("Sobrescrever o jogo do espaço %d? O progresso antigo será perdido." % n, func() -> void: _start_new(n))
		return
	_start_new(n)


func _start_new(n: int) -> void:
	Audio.sfx("magic_select", -4.0)
	GameState.use_new_slot(n)
	if _slots_panel != null:
		_slots_panel.queue_free()
		_slots_panel = null
	HUD.open_window("criacao")


func _load(n: int) -> void:
	if not GameState.use_slot(n):
		Audio.sfx("ui_error")
		return
	Audio.sfx("magic_select", -4.0)
	Game.go_to_town("start")


## A criação foi fechada sem começar: volta ao menu.
func show_menu() -> void:
	GameState.slot = 0
	GameState.save_path = ""
	_menu.visible = true
