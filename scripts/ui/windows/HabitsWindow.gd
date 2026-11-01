extends UIWindow

## Hábitos (T): hábitos diários (5 iniciais, até 12) com sequência e dificuldade. Cada marcação dá XP e ouro.

var _editing: LineEdit = null


func _init() -> void:
	win_title = "Hábitos"
	win_size = Vector2(540, 310)


func refresh() -> void:
	# não reconstrói enquanto o jogador digita um nome
	if _editing != null and is_instance_valid(_editing) and _editing.has_focus():
		return
	rebuild()


func build() -> void:
	add_to_body(UI.label("Uma marcação por dia. Sequência e dificuldade rendem mais.", UI.C_DIM), Vector2(0, 0))
	var add := UI.button("+ Novo", func() -> void:
		if not GameState.add_habit():
			Audio.sfx("ui_error"), 54)
	add.disabled = GameState.habits.size() >= Data.HABIT_MAX
	add_to_body(add, Vector2(466, -2))
	var col := scroll_column(Vector2(0, 18), Vector2(520, 254))
	for i in GameState.habits.size():
		var h: Dictionary = GameState.habits[i]
		var done := GameState.is_habit_completed_today(i)
		var card := UI.card(UI.C_PANEL, UI.C_GOOD if done else UI.C_LINE)
		card.custom_minimum_size = Vector2(504, 42)
		col.add_child(card)
		var row := UI.hbox(8)
		card.add_child(row)
		var left := UI.vbox(2)
		left.custom_minimum_size.x = 190
		row.add_child(left)
		var name_edit := LineEdit.new()
		name_edit.text = h["name"]
		name_edit.max_length = 26
		name_edit.custom_minimum_size = Vector2(180, 16)
		name_edit.add_theme_font_override("font", Pix.font(1))
		name_edit.add_theme_font_size_override("font_size", 12)
		name_edit.text_submitted.connect(func(t: String) -> void:
			GameState.rename_habit(i, t)
			name_edit.release_focus())
		name_edit.focus_entered.connect(func() -> void: _editing = name_edit)
		name_edit.focus_exited.connect(func() -> void: GameState.rename_habit(i, name_edit.text))
		left.add_child(name_edit)
		left.add_child(UI.label("Total: %d   Melhor sequência: %d" % [int(h.get("total_completions", 0)), int(h.get("best_streak", 0))], UI.C_DIM))
		var streak := int(h.get("streak", 0))
		if not done and h.get("last_completed_date", "") != "" and streak > 0:
			var days := _days_since(h["last_completed_date"])
			if days > 1:
				streak = 0
		var sv := UI.vbox(0)
		sv.custom_minimum_size.x = 100
		row.add_child(sv)
		sv.add_child(UI.label("Sequência: %d" % streak, UI.C_ORANGE_L if streak > 0 else UI.C_DIM))
		var bonus := int((streak + (0 if done else 1)) / 5.0)
		var m := GameState.habit_mult(i)
		sv.add_child(UI.label("+%d XP +%d ouro" % [int(round(float(8 + bonus * 3) * m)), int(round(float(6 + bonus * 4) * m))], UI.C_DIM))
		var dl := int(h.get("difficulty", 1))
		var db := UI.button(Data.HABIT_DIFF_NAMES[dl], func() -> void:
			Audio.ui_click()
			GameState.set_habit_difficulty(i, (dl + 1) % 3), 56)
		db.tooltip_text = "Dificuldade do hábito: quanto mais difícil, mais XP e ouro"
		row.add_child(db)
		var b := UI.button("Feito hoje" if done else "Marcar", func() -> void: _mark(i), 70)
		b.disabled = done
		row.add_child(b)
		var rm := UI.button("X", func() -> void:
			HUD.confirm("Apagar o hábito \"%s\"?" % str(h["name"]), func() -> void: GameState.remove_habit(i)), 16)
		rm.disabled = GameState.habits.size() <= 1
		row.add_child(rm)


func _days_since(date_str: String) -> int:
	var then := Time.get_unix_time_from_datetime_string(date_str + " 00:00:00")
	var now := Time.get_unix_time_from_datetime_string(Time.get_date_string_from_system() + " 00:00:00")
	return int(round((now - then) / 86400.0))


func _mark(i: int) -> void:
	var r := GameState.complete_habit(i)
	if r.is_empty():
		Audio.sfx("ui_error")
		return
	Audio.jingle("success")
	Audio.sfx("star", -6.0)
	HUD.show_toast("Hábito marcado! +%d XP  +%d ouro  (sequência %d)" % [r["xp"], r["gold"], r["streak"]], UI.C_GOLD)
