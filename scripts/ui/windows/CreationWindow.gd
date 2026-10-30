extends UIWindow

## Criação do personagem (jogo novo): nome do herói, como ele é chamado e os nomes do pai e
## da mãe. A classe é escolhida depois, na Guilda (capítulo 1).

var _hero: LineEdit
var _father: LineEdit
var _mother: LineEdit
var _gender: String = "m"
var _error: Label


func _init() -> void:
	win_title = "Focus Town  -  Novo jogo"
	win_size = Vector2(420, 226)
	close_on_escape = false


func build() -> void:
	close_button.visible = false
	_add_landscape()
	var v := UI.vbox(5)
	add_to_body(v, Vector2(4, 0))
	v.add_child(UI.wrap_label("Um Rei Demônio roubou as páginas do conhecimento de Focus Town. Cada hora de estudo de verdade é a única forma de recuperá-las.", UI.C_DIM, 392))
	v.add_child(UI.hline())
	_hero = _field(v, "Nome do herói", "Ex.: Ana, Léo...")
	var g := UI.hbox(6)
	v.add_child(g)
	var gl := UI.label("Tratamento", UI.C_TEXT)
	gl.custom_minimum_size.x = 110
	g.add_child(gl)
	var b_m := UI.button("Ele", Callable(), 50)
	var b_f := UI.button("Ela", Callable(), 50)
	b_m.disabled = _gender == "m"
	b_f.disabled = _gender == "f"
	b_m.pressed.connect(func() -> void:
		_gender = "m"
		b_m.disabled = true
		b_f.disabled = false)
	b_f.pressed.connect(func() -> void:
		_gender = "f"
		b_f.disabled = true
		b_m.disabled = false)
	g.add_child(b_m)
	g.add_child(b_f)
	_father = _field(v, "Nome do pai", "O pai que desapareceu")
	_mother = _field(v, "Nome da mãe", "A mãe que ficou na floresta")
	_error = UI.label("", UI.C_BAD)
	v.add_child(_error)
	var start := UI.button("Começar a aventura", func() -> void: _start(), 150)
	v.add_child(start)
	_hero.call_deferred("grab_focus")


func refresh() -> void:
	pass  # não reconstruir enquanto o jogador digita


func _field(parent: Control, title: String, hint: String) -> LineEdit:
	var h := UI.hbox(6)
	parent.add_child(h)
	var l := UI.label(title, UI.C_TEXT)
	l.custom_minimum_size.x = 110
	h.add_child(l)
	var e := LineEdit.new()
	e.custom_minimum_size = Vector2(220, 18)
	e.placeholder_text = hint
	e.max_length = 18
	h.add_child(e)
	return e


func _start() -> void:
	var hero := _hero.text.strip_edges()
	var father := _father.text.strip_edges()
	var mother := _mother.text.strip_edges()
	if hero == "" or father == "" or mother == "":
		_error.text = "Preencha os três nomes."
		Audio.sfx("ui_error", -4.0)
		return
	Audio.sfx("magic_select", -2.0)
	GameState.debug_reset()
	GameState.gold = 25
	Story.start_new_game(hero, father, mother, _gender)
	HUD.close_window()
	Game.enter_interior("casa_familia")


func _add_landscape() -> void:
	var hour := int(Time.get_time_dict_from_system()["hour"])
	var name := "campo_dia" if hour >= 7 and hour < 17 else ("mar_entardecer" if hour >= 17 and hour < 20 else "montanhas_noite")
	var path := "res://assets/custom/paisagem/%s.png" % name
	if not ResourceLoader.exists(path) or has_node("Paisagem"):
		return
	var tr := TextureRect.new()
	tr.name = "Paisagem"
	tr.texture = load(path)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	move_child(tr, 0)
