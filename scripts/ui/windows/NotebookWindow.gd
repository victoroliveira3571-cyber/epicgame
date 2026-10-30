extends UIWindow

## Caderno do herói (tecla N): cartas de lembrança (pergunta, resposta, palavras-chave), a
## revisão do dia (caixas 1 a 5) e o formulário de carta nova. Os chefes sorteiam perguntas
## daqui (Recall.gd / MECANICAS_RECUPERACAO.md).

var tab: int = 0
var _q: LineEdit
var _a: LineEdit
var _k: LineEdit
var _msg: Label
# revisão
var _review: Array = []
var _review_i: int = 0
var _review_shown: bool = false


func _init() -> void:
	win_title = "Caderno do herói"
	win_size = Vector2(540, 300)


func refresh() -> void:
	pass  # os campos de texto não podem ser recriados enquanto o jogador digita


func build() -> void:
	var due := Recall.due_user_cards().size()
	tab_bar(["Cartas", "Nova carta", "Revisar (%d)" % due], tab, func(i: int) -> void:
		tab = i
		_review = []
		rebuild(), Vector2(0, 0), 100)
	match tab:
		0:
			_list()
		1:
			_new_card()
		2:
			_review_tab()


func _list() -> void:
	var cards: Array = GameState.story.get("cards", [])
	var info := UI.label("%d cartas. Os chefes sorteiam perguntas daqui; as de caixa baixa aparecem primeiro." % cards.size(), UI.C_DIM)
	add_to_body(info, Vector2(0, 22))
	var col := scroll_column(Vector2(0, 38), Vector2(520, 224))
	if cards.is_empty():
		col.add_child(UI.wrap_label("Seu Caderno está vazio. Crie cartas na aba \"Nova carta\" com perguntas do que você estuda de verdade: uma ideia por carta, pergunta curta.", UI.C_TEXT, 500))
		return
	for c in cards:
		var card: Dictionary = c
		var row := UI.card(UI.C_PANEL, UI.C_LINE)
		row.custom_minimum_size = Vector2(504, 28)
		var h := UI.hbox(6)
		row.add_child(h)
		var box := UI.label("Cx %d" % int(card.get("box", 1)), UI.C_ORANGE_L)
		box.custom_minimum_size.x = 34
		h.add_child(box)
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.wrap_label(String(card.get("q", "")), UI.C_TEXT, 380))
		var keys := ", ".join(card.get("k", []))
		v.add_child(UI.wrap_label("R: %s%s" % [card.get("a", ""), ("   [%s]" % keys) if keys != "" else ""], UI.C_DIM, 380))
		var cid := String(card.get("id", ""))
		h.add_child(UI.button("Apagar", func() -> void:
			HUD.confirm("Apagar esta carta?", func() -> void:
				Recall.remove_card(cid)
				rebuild()), 50))
		col.add_child(row)


func _new_card() -> void:
	var v := UI.vbox(5)
	add_to_body(v, Vector2(0, 24))
	v.add_child(UI.wrap_label("Escreva uma pergunta do que você está estudando. Na batalha, você responde de memória.", UI.C_DIM, 510))
	_q = _field(v, "Pergunta", "Ex.: O que é mitose?")
	_a = _field(v, "Resposta", "Ex.: Divisão que gera duas células iguais")
	_k = _field(v, "Palavras-chave", "Ex.: duas, iguais  (separe por vírgula; opcional)")
	v.add_child(UI.wrap_label("As palavras-chave decidem o acerto: todas = acerto, metade ou mais = acerto parcial. Sem palavras-chave, valem as palavras longas da resposta. Acentos e maiúsculas não importam.", UI.C_DIM, 510))
	_msg = UI.label("", UI.C_GOOD)
	v.add_child(_msg)
	v.add_child(UI.button("Guardar carta", func() -> void: _save_card(), 110))
	_q.call_deferred("grab_focus")


func _field(parent: Control, title: String, hint: String) -> LineEdit:
	var h := UI.hbox(6)
	parent.add_child(h)
	var l := UI.label(title, UI.C_TEXT)
	l.custom_minimum_size.x = 96
	h.add_child(l)
	var e := LineEdit.new()
	e.custom_minimum_size = Vector2(400, 18)
	e.placeholder_text = hint
	e.max_length = 140
	h.add_child(e)
	return e


func _save_card() -> void:
	if _q.text.strip_edges() == "" or _a.text.strip_edges() == "":
		_msg.text = "Escreva a pergunta e a resposta."
		_msg.add_theme_color_override("font_color", UI.C_BAD)
		Audio.sfx("ui_error", -4.0)
		return
	Recall.add_card(_q.text, _a.text, _k.text)
	Audio.sfx("ui_ok", -2.0)
	_q.text = ""
	_a.text = ""
	_k.text = ""
	_msg.text = "Carta guardada! (%d no Caderno)" % (GameState.story.get("cards", []) as Array).size()
	_msg.add_theme_color_override("font_color", UI.C_GOOD)
	_q.grab_focus()
	Story.on_card_created()


func _review_tab() -> void:
	if _review.is_empty():
		_review = Recall.due_user_cards()
		_review_i = 0
		_review_shown = false
	var v := UI.vbox(6)
	add_to_body(v, Vector2(0, 26))
	if _review_i >= _review.size():
		v.add_child(UI.wrap_label("Nada para revisar agora. Cartas erradas voltam depois do próximo foco; as certas voltam em 2, 4, 8 e 16 dias.", UI.C_TEXT, 510))
		return
	var card: Dictionary = _review[_review_i]
	v.add_child(UI.label("Carta %d de %d  -  caixa %d" % [_review_i + 1, _review.size(), Recall.box_of(card)], UI.C_ORANGE_L))
	v.add_child(UI.wrap_label(String(card.get("q", "")), UI.C_TEXT, 510))
	if not _review_shown:
		v.add_child(UI.label("Tente lembrar a resposta antes de mostrar.", UI.C_DIM))
		v.add_child(UI.button("Mostrar resposta", func() -> void:
			_review_shown = true
			rebuild(), 120))
		return
	v.add_child(UI.wrap_label("Resposta: " + String(card.get("a", "")), UI.C_GOOD, 510))
	v.add_child(UI.label("Você lembrou?", UI.C_DIM))
	var h := UI.hbox(6)
	v.add_child(h)
	h.add_child(UI.button("Lembrei", func() -> void: _rate(card, "full"), 80))
	h.add_child(UI.button("Mais ou menos", func() -> void: _rate(card, "partial"), 100))
	h.add_child(UI.button("Não lembrei", func() -> void: _rate(card, "wrong"), 90))


func _rate(card: Dictionary, result: String) -> void:
	Recall.record(card, result)
	if result == "full":
		GameState.add_xp(3, false)
	_review_i += 1
	_review_shown = false
	rebuild()
