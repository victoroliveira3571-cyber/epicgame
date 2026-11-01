extends UIWindow

## Criação do personagem (jogo novo): nome do herói, como ele é chamado, os nomes do pai e
## da mãe e a aparência (AppearanceEditor: pele, olhos, cabelo, barba). v3.7 (história v4): na segunda página
## o jogador escolhe a classe, que muda a infância no prólogo e a arma de madeira (antes era na Guilda).

var _hero: LineEdit
var _father: LineEdit
var _mother: LineEdit
var _gender: String = "m"
var _error: Label
var _editor: AppearanceEditor


func _init() -> void:
	win_title = "Focus Town  -  Novo jogo"
	win_size = Vector2(600, 300)
	close_on_escape = false


func build() -> void:
	close_button.visible = false
	_add_landscape()
	var v := UI.vbox(5)
	add_to_body(v, Vector2(4, 0))
	v.add_child(UI.wrap_label("Você renasce em Vicerus com as memórias de outro mundo. Um Rei Demônio roubou as páginas do conhecimento: cada hora de estudo de verdade é a única forma de recuperá-las.", UI.C_DIM, 226))
	v.add_child(UI.hline())
	_hero = _field(v, "Nome do herói", "Ex.: Ana, Léo...")
	var g := UI.hbox(6)
	v.add_child(g)
	var gl := UI.label("Tratamento", UI.C_TEXT)
	gl.custom_minimum_size.x = 76
	g.add_child(gl)
	var b_m := UI.button("Ele", Callable(), 50)
	var b_f := UI.button("Ela", Callable(), 50)
	b_m.disabled = _gender == "m"
	b_f.disabled = _gender == "f"
	b_m.pressed.connect(func() -> void:
		_gender = "m"
		b_m.disabled = true
		b_f.disabled = false
		_set_body("muscular"))
	b_f.pressed.connect(func() -> void:
		_gender = "f"
		b_f.disabled = true
		b_m.disabled = false
		_set_body("female"))
	g.add_child(b_m)
	g.add_child(b_f)
	_father = _field(v, "Nome do pai", "O pai que desapareceu")
	_mother = _field(v, "Nome da mãe", "A mãe que ficou na floresta")
	_error = UI.label("", UI.C_BAD)
	v.add_child(_error)
	var row := UI.hbox(6)
	v.add_child(row)
	row.add_child(UI.button("Próximo: escolher a classe", func() -> void: _start(), 170))
	var title_scene := get_tree().current_scene
	if title_scene != null and title_scene.has_method("show_menu"):
		row.add_child(UI.button("Voltar", func() -> void:
			HUD.close_window()
			title_scene.show_menu(), 60))
	# aparência
	var right := UI.vbox(3)
	add_to_body(right, Vector2(240, 0))
	right.add_child(UI.label("Aparência", UI.C_ORANGE_L))
	_editor = AppearanceEditor.new()
	right.add_child(_editor)
	var lk := LpcW.default_look("muscular")
	lk["skin"] = LpcW.SKINS[randi() % 7][0]
	lk["hair_pal"] = ["black", "dark_brown", "chestnut", "light_brown", "redhead", "blonde"][randi() % 6]
	_editor.setup(lk)
	_hero.call_deferred("grab_focus")


func _set_body(b: String) -> void:
	# troca para o visual-base do corpo, mantendo pele, olhos e cor do cabelo escolhidos
	var keep := {}
	for k in ["skin", "eyes", "hair_pal"]:
		keep[k] = _editor.look.get(k)
	var lk := LpcW.default_look(b)
	for k in keep:
		lk[k] = keep[k]
	_editor.look = lk
	_editor._rebuild()


func refresh() -> void:
	pass  # não reconstruir enquanto o jogador digita


func _field(parent: Control, title: String, hint: String) -> LineEdit:
	var h := UI.hbox(6)
	parent.add_child(h)
	var l := UI.label(title, UI.C_TEXT)
	l.custom_minimum_size.x = 76
	h.add_child(l)
	var e := LineEdit.new()
	e.custom_minimum_size = Vector2(146, 18)
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
	Audio.sfx("ui_ok", -4.0)
	_names = {"hero": hero, "father": father, "mother": mother}
	_show_classes()


var _names: Dictionary = {}
var _page: Control = null


## Segunda página: a classe (a mesma grade da janela de classe), com o herói já com a aparência escolhida.
func _show_classes() -> void:
	for c in body.get_children():
		c.visible = false
	_page = Control.new()
	_page.size = body.size
	body.add_child(_page)
	var top := UI.hbox(6)
	top.position = Vector2(2, 0)
	_page.add_child(top)
	var intro := UI.label("Escolha a classe de %s. Ela muda a infância e a arma de madeira. Escolha definitiva." % _names["hero"], UI.C_DIM)
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(intro)
	top.add_child(UI.button("Voltar", func() -> void:
		_page.queue_free()
		_page = null
		for c in body.get_children():
			c.visible = true, 50))
	var lk: Dictionary = _editor.look.duplicate(true)
	var sc := ClassWindow.make_grid(Vector2(body.size.x, body.size.y - 18), lk, "", func(id: String) -> void: _pick_class(id))
	sc.position = Vector2(0, 18)
	_page.add_child(sc)


func _pick_class(id: String) -> void:
	HUD.confirm("Jogar como %s? Não dá para trocar depois." % Data.CLASSES[id]["name"], func() -> void: _begin(id))


func _begin(class_id: String) -> void:
	Audio.sfx("magic_select", -2.0)
	GameState.debug_reset()
	GameState.gold = 25
	Story.start_new_game(str(_names["hero"]), str(_names["father"]), str(_names["mother"]), _gender)
	GameState.set_appearance(_editor.look)
	GameState.choose_class(class_id)
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
