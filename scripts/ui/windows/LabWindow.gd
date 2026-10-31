extends UIWindow

## Bancada do Laboratório do Dr. Faísca: combina ingredientes que os monstros soltam (Data.LAB_DROP)
## em poções de cura, tônicos de estudo e Livros de Magia (Data.LAB_RECIPES). Livros pedem horas de
## foco acumuladas: a magia só sai para quem estudou. À direita: o que o item faz e o que falta.

var selected: int = 0


func _init() -> void:
	win_title = "Laboratório do Dr. Faísca  -  Bancada de preparos"
	win_size = Vector2(620, 320)


func build() -> void:
	var col := scroll_column(Vector2(0, 0), Vector2(346, 280))
	for i in Data.LAB_RECIPES.size():
		var r: Array = Data.LAB_RECIPES[i]
		var it: Dictionary = Data.get_item(str(r[0]))
		var ok := _can_make(i)
		var idx := i
		var row := list_row(Pix.item_icon(str(r[0])), "%s%s" % [it.get("name", r[0]), (" x%d" % int(r[1])) if int(r[1]) > 1 else ""],
			UI.C_ORANGE_L if i == selected else (UI.C_TEXT if ok else UI.C_DIM), _short_cost(i), "", UI.C_DIM,
			"Ver", func() -> void:
				selected = idx
				rebuild(), i == selected, 334)
		col.add_child(row)
	_detail()


func _detail() -> void:
	var r: Array = Data.LAB_RECIPES[selected]
	var it: Dictionary = Data.get_item(str(r[0]))
	var v := UI.vbox(4)
	add_to_body(v, Vector2(356, 0))
	var head := UI.hbox(6)
	v.add_child(head)
	head.add_child(UI.icon(Pix.item_icon(str(r[0])), 28))
	head.add_child(UI.label(str(it.get("name", r[0])), UI.C_GOLD))
	v.add_child(UI.wrap_label(str(it.get("desc", "")), UI.C_TEXT, 236))
	v.add_child(UI.hline())
	v.add_child(UI.label("Ingredientes", UI.C_ORANGE_L))
	var need: Dictionary = r[2]
	for ing in need:
		var have := GameState.count_item(ing)
		var want := int(need[ing])
		var line := UI.hbox(4)
		line.add_child(UI.icon(Pix.item_icon(ing), 16))
		line.add_child(UI.label("%s  %d/%d" % [Data.item_name(ing), have, want], UI.C_GOOD if have >= want else UI.C_BAD))
		v.add_child(line)
	var hours := int(r[3])
	if hours > 0:
		var got := Story.focus_hours()
		v.add_child(UI.label("Horas de foco: %s / %d h" % [Story._hours_text(), hours], UI.C_GOOD if got >= float(hours) else UI.C_BAD))
	var make := UI.button("Preparar", func() -> void: _make(selected), 110)
	make.disabled = not _can_make(selected)
	v.add_child(make)
	if not _can_make(selected):
		v.add_child(UI.wrap_label("Faltam ingredientes (derrote monstros na floresta e na masmorra) ou horas de foco (Pomodoro).", UI.C_DIM, 236))


func _short_cost(i: int) -> String:
	var r: Array = Data.LAB_RECIPES[i]
	var parts: Array = []
	for ing in r[2]:
		parts.append("%d %s" % [int(r[2][ing]), Data.item_name(ing).split(" ")[0].to_lower()])
	if int(r[3]) > 0:
		parts.append("%d h foco" % int(r[3]))
	return ", ".join(parts)


func _can_make(i: int) -> bool:
	var r: Array = Data.LAB_RECIPES[i]
	for ing in r[2]:
		if GameState.count_item(ing) < int(r[2][ing]):
			return false
	return Story.focus_hours() >= float(int(r[3]))


func _make(i: int) -> void:
	if not _can_make(i):
		Audio.sfx("ui_error")
		return
	var r: Array = Data.LAB_RECIPES[i]
	for ing in r[2]:
		GameState.remove_item(ing, int(r[2][ing]))
	GameState.add_item(str(r[0]), int(r[1]))
	Audio.sfx("magic2", -4.0)
	Audio.sfx("powerup", -8.0)
	HUD.show_toast("Preparado: %s! Dr. Faísca: \"%s\"" % [Data.item_name(str(r[0])), str(r[4])], UI.C_GOOD)
	GameState.save_game()
	rebuild()
