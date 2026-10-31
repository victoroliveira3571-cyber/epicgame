extends UIWindow

## Espelho (casa do herói e casa da família): muda a aparência a qualquer momento, de graça.
## Roupas continuam no Guarda-roupa; aqui só corpo, pele, olhos, cabelo, barba e sobrancelha.

var _editor: AppearanceEditor


func _init() -> void:
	win_title = "Espelho  -  Aparência"
	win_size = Vector2(380, 220)


func build() -> void:
	var v := UI.vbox(4)
	add_to_body(v, Vector2(4, 0))
	_editor = AppearanceEditor.new()
	v.add_child(_editor)
	_editor.setup(Looks.hero())
	var h := UI.hbox(6)
	v.add_child(h)
	h.add_child(UI.button("Salvar", func() -> void:
		GameState.set_appearance(_editor.look)
		var p := get_tree().get_first_node_in_group("player") as Player
		if p != null:
			p.refresh_sheet()
		Audio.sfx("magic_select", -4.0)
		HUD.show_toast("Visual atualizado!", UI.C_GOOD)
		HUD.close_window(), 80))
	h.add_child(UI.button("Roupas", func() -> void:
		HUD.close_window()
		HUD.open_window("guarda_roupa"), 80))


func refresh() -> void:
	pass
