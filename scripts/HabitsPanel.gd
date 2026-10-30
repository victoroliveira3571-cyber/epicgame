extends PanelContainer

## Painel de Hábitos: 5 hábitos com nome editável, marcados uma vez por dia.
## Cada marcação dá XP/ouro e mantém uma sequência de dias — ver
## GameState.complete_habit() pra regra da sequência e da recompensa.

@onready var rows: Array[Dictionary] = [
	{"name_edit": $Margin/VBox/Row1/NameEdit, "streak": $Margin/VBox/Row1/StreakLabel, "button": $Margin/VBox/Row1/CompleteButton},
	{"name_edit": $Margin/VBox/Row2/NameEdit, "streak": $Margin/VBox/Row2/StreakLabel, "button": $Margin/VBox/Row2/CompleteButton},
	{"name_edit": $Margin/VBox/Row3/NameEdit, "streak": $Margin/VBox/Row3/StreakLabel, "button": $Margin/VBox/Row3/CompleteButton},
	{"name_edit": $Margin/VBox/Row4/NameEdit, "streak": $Margin/VBox/Row4/StreakLabel, "button": $Margin/VBox/Row4/CompleteButton},
	{"name_edit": $Margin/VBox/Row5/NameEdit, "streak": $Margin/VBox/Row5/StreakLabel, "button": $Margin/VBox/Row5/CompleteButton},
]

@onready var close_button: Button = $Margin/VBox/CloseButton


func _ready() -> void:
	for i in GameState.HABIT_SLOTS:
		rows[i]["name_edit"].text_submitted.connect(_on_name_submitted.bind(i))
		rows[i]["name_edit"].focus_exited.connect(_on_name_focus_exited.bind(i))
		rows[i]["button"].pressed.connect(_on_complete_pressed.bind(i))

	close_button.pressed.connect(_on_close_pressed)
	GameState.stats_changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for i in GameState.HABIT_SLOTS:
		if i >= GameState.habits.size():
			continue
		var habit: Dictionary = GameState.habits[i]
		var name_edit: LineEdit = rows[i]["name_edit"]
		if not name_edit.has_focus():
			name_edit.text = habit.get("name", "Hábito %d" % (i + 1))

		var streak: int = habit.get("streak", 0)
		var best: int = habit.get("best_streak", 0)
		rows[i]["streak"].text = "🔥 %d dia(s) (recorde: %d)" % [streak, best]

		var done_today: bool = GameState.is_habit_completed_today(i)
		rows[i]["button"].text = "Feito hoje ✓" if done_today else "Concluir hoje"
		rows[i]["button"].disabled = done_today


func _on_name_submitted(new_text: String, index: int) -> void:
	GameState.rename_habit(index, new_text)
	rows[index]["name_edit"].release_focus()


func _on_name_focus_exited(index: int) -> void:
	GameState.rename_habit(index, rows[index]["name_edit"].text)


func _on_complete_pressed(index: int) -> void:
	GameState.complete_habit(index)


func _on_close_pressed() -> void:
	visible = false
