class_name QuizPanel
extends Control

## Pergunta de memória dos chefes (MECANICAS_RECUPERACAO.md). Formatos:
##  bank  = lacuna com banco de palavras (3 opções + "Não lembro")
##  type  = digitar a palavra que falta
##  free  = pergunta livre (Caderno do jogador ou banco embutido)
## Sem tempo limite. Dica gradual reduz o dano do acerto para 75%.
## Resultado: {"result": "full" | "partial" | "wrong" | "skip", "hints": n}

signal done(result: Dictionary)

const SIZE := Vector2(380, 200)

var card: Dictionary = {}
var title_text: String = "Pergunta de memória"
var hints: int = 0
var _panel: Panel
var _body: VBoxContainer
var _edit: LineEdit
var _hint_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.02, 0.01, 0.04, 0.6)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	_panel = UI.window_panel(SIZE)
	_panel.position = ((UI.SIZE - SIZE) / 2.0).round() - Vector2(0, 20)
	add_child(_panel)
	_body = UI.vbox(5)
	_body.position = Vector2(12, 8)
	_body.size = SIZE - Vector2(24, 16)
	_panel.add_child(_body)


func start(c: Dictionary, title: String) -> void:
	card = c
	title_text = title
	_ask()


func _clear() -> void:
	for ch in _body.get_children():
		_body.remove_child(ch)
		ch.queue_free()


func _ask() -> void:
	_clear()
	_body.add_child(UI.label(title_text, UI.C_ORANGE_L))
	var src := "Do seu Caderno" if card.get("src", "") == "user" else "Do banco da história"
	_body.add_child(UI.label("%s  -  caixa %d" % [src, Recall.box_of(card)], UI.C_DIM))
	_body.add_child(UI.hline())
	_body.add_child(UI.wrap_label(Story.fmt(String(card.get("q", ""))), UI.C_TEXT, SIZE.x - 30))
	_body.add_child(UI.spacer(4))
	if card.has("opts"):
		var opts: Array = (card["opts"] as Array).duplicate()
		opts.shuffle()
		var row := UI.hbox(6)
		_body.add_child(row)
		for o in opts:
			var txt := String(o)
			row.add_child(UI.button(txt, func() -> void: _answer(txt), 90))
		_body.add_child(UI.spacer(2))
		_body.add_child(UI.button("Não lembro", func() -> void: _skip(), 90))
		return
	_edit = LineEdit.new()
	_edit.custom_minimum_size = Vector2(SIZE.x - 30, 18)
	_edit.placeholder_text = "Escreva de memória e aperte Enter"
	_edit.text_submitted.connect(func(t: String) -> void: _answer(t))
	_body.add_child(_edit)
	_hint_label = UI.wrap_label("", UI.C_XP, SIZE.x - 30)
	_body.add_child(_hint_label)
	var row2 := UI.hbox(6)
	_body.add_child(row2)
	row2.add_child(UI.button("Responder", func() -> void: _answer(_edit.text), 80))
	row2.add_child(UI.button("Dica", func() -> void: _hint(), 50))
	row2.add_child(UI.button("Não lembro", func() -> void: _skip(), 80))
	_edit.call_deferred("grab_focus")


func _hint() -> void:
	if hints >= 2:
		return
	hints += 1
	Audio.sfx("ui_tab", -4.0)
	_hint_label.text = Recall.hint(card, hints) + "  (com dica, o golpe tira 75%)"


func _answer(text: String) -> void:
	if text.strip_edges() == "":
		return
	var g := Recall.grade(text, card)
	_feedback(String(g["result"]), text)


func _skip() -> void:
	_feedback("skip", "")


func _feedback(result: String, typed: String) -> void:
	Recall.record(card, "wrong" if result == "skip" else result)
	_clear()
	var head := ""
	var color := UI.C_TEXT
	match result:
		"full":
			head = "Você lembrou! Golpe de memória!"
			color = UI.C_GOOD
			Audio.sfx("star", -2.0)
		"partial":
			head = "Quase! Acerto parcial: meio golpe."
			color = UI.C_GOLD
			Audio.sfx("bonus", -4.0)
		"wrong":
			head = "Não foi dessa vez. O chefe aproveita a brecha!"
			color = UI.C_BAD
			Audio.sfx("ui_error", -2.0)
		_:
			head = "Tudo bem não lembrar. Veja a resposta: ela volta para revisão."
			color = UI.C_DIM
			Audio.sfx("ui_back", -4.0)
	_body.add_child(UI.label(head, color))
	_body.add_child(UI.hline())
	if typed != "":
		_body.add_child(UI.wrap_label("Sua resposta: " + typed, UI.C_DIM, SIZE.x - 30))
	_body.add_child(UI.wrap_label("Resposta: " + Story.fmt(String(card.get("a", ""))), UI.C_TEXT, SIZE.x - 30))
	if result != "full":
		_body.add_child(UI.label("Esta carta volta para a caixa 1 e reaparece depois do próximo foco." if result != "partial" else "Esta carta fica na mesma caixa.", UI.C_DIM))
	_body.add_child(UI.spacer(4))
	var res := {"result": result, "hints": hints}
	var cont := UI.button("Continuar a luta", func() -> void: done.emit(res), 120)
	_body.add_child(cont)
