extends UIWindow

## Recall ativo no fim de cada foco: escreva, sem olhar nada, o que você entendeu do bloco.
## Não fecha enquanto o texto não tiver Data.RECALL_MIN_CHARS caracteres (nem com Esc). O pedido
## fica guardado em pomo_cfg["recall_pending"], então fechar o jogo no meio não escapa dele.

var _edit: TextEdit
var _count: Label
var _done: Button


func _init() -> void:
	win_title = "Recall: o que você entendeu?"
	win_size = Vector2(500, 300)
	close_on_escape = false


func refresh() -> void:
	pass  # não reconstruir enquanto o jogador escreve


func build() -> void:
	close_button.visible = false
	var pending: Dictionary = HUD.recall_pending()
	var v := UI.vbox(5)
	add_to_body(v, Vector2(0, 0))
	v.add_child(UI.wrap_label("Você estudou %d min. Sem olhar o material, escreva com suas palavras o que entendeu deste bloco: ideias principais, como se explicasse a alguém. Lembrar sem consultar é o que fixa. Não dá para pular." % int(pending.get("minutes", 0)), UI.C_DIM, 476))
	_edit = TextEdit.new()
	_edit.custom_minimum_size = Vector2(476, 130)
	_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_edit.placeholder_text = "O que eu entendi foi..."
	_edit.add_theme_font_override("font", Pix.font(1))
	_edit.add_theme_font_size_override("font_size", 12)
	_edit.add_theme_stylebox_override("normal", UI.flat(UI.C_BG, UI.C_ORANGE, 1, Vector4(5, 3, 5, 3)))
	_edit.add_theme_stylebox_override("focus", UI.flat(UI.C_BG, UI.C_ORANGE_L, 1, Vector4(5, 3, 5, 3)))
	_edit.text_changed.connect(_update)
	v.add_child(_edit)
	var row := UI.hbox(8)
	v.add_child(row)
	_count = UI.label("", UI.C_DIM)
	_count.custom_minimum_size.x = 300
	row.add_child(_count)
	_done = UI.button("Guardar recall", func() -> void: _submit(), 110)
	row.add_child(_done)
	_update()
	_edit.call_deferred("grab_focus")


func _chars() -> int:
	return _edit.text.strip_edges().length()


func _update() -> void:
	var n := _chars()
	var need := Data.RECALL_MIN_CHARS
	_done.disabled = n < need
	_count.text = "%d / %d caracteres" % [n, need] if n < need else "%d caracteres: pronto." % n
	_count.add_theme_color_override("font_color", UI.C_GOOD if n >= need else UI.C_BAD)


func _submit() -> void:
	if _chars() < Data.RECALL_MIN_CHARS:
		return
	HUD.recall_submit(_edit.text.strip_edges())
