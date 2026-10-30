extends UIWindow

## Caixa de preocupações (Mestre Lin, capítulo 3): antes de um foco, escreva o que está pesando
## na cabeça, feche a caixa e volte a estudar. É uma versão curta da escrita expressiva; a pesquisa
## mostra efeito pequeno, mas real, na ansiedade antes de provas. O texto fica só no save local.

var _edit: TextEdit


func _init() -> void:
	win_title = "Caixa de preocupações"
	win_size = Vector2(440, 270)


func refresh() -> void:
	pass  # não reconstruir enquanto o jogador escreve


func build() -> void:
	var v := UI.vbox(5)
	add_to_body(v, Vector2(0, 0))
	v.add_child(UI.wrap_label("Escreva o que está te preocupando agora, sem filtro e sem corrigir. Depois feche a caixa: o que está escrito não precisa ocupar sua cabeça durante o foco.", UI.C_DIM, 416))
	_edit = TextEdit.new()
	_edit.custom_minimum_size = Vector2(416, 120)
	_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_edit.placeholder_text = "Ex.: Tenho prova sexta e não sei se dá tempo..."
	_edit.add_theme_font_override("font", Pix.font(1))
	_edit.add_theme_font_size_override("font_size", 12)
	_edit.add_theme_stylebox_override("normal", UI.flat(UI.C_BG, UI.C_ORANGE, 1, Vector4(5, 3, 5, 3)))
	_edit.add_theme_stylebox_override("focus", UI.flat(UI.C_BG, UI.C_ORANGE_L, 1, Vector4(5, 3, 5, 3)))
	v.add_child(_edit)
	var worries: Array = GameState.story.get("worries", [])
	v.add_child(UI.label("Você já fechou a caixa %d vezes." % worries.size(), UI.C_DIM))
	var row := UI.hbox(6)
	v.add_child(row)
	row.add_child(UI.button("Fechar a caixa e estudar", func() -> void: _close_box(), 150))
	row.add_child(UI.button("Voltar ao Pomodoro", func() -> void: HUD.open_window("pomodoro"), 120))
	if not worries.is_empty():
		row.add_child(UI.button("Apagar tudo", func() -> void:
			HUD.confirm("Apagar todos os textos guardados na caixa?", func() -> void:
				GameState.story["worries"] = []
				GameState.save_game()
				rebuild()), 80))
	_edit.call_deferred("grab_focus")


func _close_box() -> void:
	var text := _edit.text.strip_edges()
	if text != "":
		var worries: Array = GameState.story.get("worries", [])
		worries.append({"d": Time.get_date_string_from_system(), "t": text})
		while worries.size() > 30:
			worries.pop_front()
		GameState.story["worries"] = worries
		GameState.save_game()
	Audio.sfx("chest", -4.0)
	HUD.show_toast("Caixa fechada. Respire fundo e comece o foco.", UI.C_GOOD)
	HUD.open_window("pomodoro")
