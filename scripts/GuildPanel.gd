extends PanelContainer

## Janela da Guilda dos Aventureiros: lista fixa de missões (GameState.MISSIONS).
## O texto de cada missão vem direto do GameState, então editar uma missão
## só precisa mudar os dados lá — esta tela se atualiza sozinha.

@onready var rows: Array[Dictionary] = [
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row1/InfoLabel1, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row1/StatusLabel1, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row1/ClaimButton1},
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row2/InfoLabel2, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row2/StatusLabel2, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row2/ClaimButton2},
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row3/InfoLabel3, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row3/StatusLabel3, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row3/ClaimButton3},
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row4/InfoLabel4, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row4/StatusLabel4, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row4/ClaimButton4},
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row5/InfoLabel5, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row5/StatusLabel5, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row5/ClaimButton5},
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row6/InfoLabel6, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row6/StatusLabel6, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row6/ClaimButton6},
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row7/InfoLabel7, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row7/StatusLabel7, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row7/ClaimButton7},
	{"info": $Margin/VBox/MissionsScroll/MissionsVBox/Row8/InfoLabel8, "status": $Margin/VBox/MissionsScroll/MissionsVBox/Row8/StatusLabel8, "button": $Margin/VBox/MissionsScroll/MissionsVBox/Row8/ClaimButton8},
]

@onready var close_button: Button = $Margin/VBox/CloseButton
@onready var dungeon_button: Button = $Margin/VBox/DungeonButton


func _ready() -> void:
	for i in GameState.MISSIONS.size():
		var m: Dictionary = GameState.MISSIONS[i]
		var reward_parts: Array[String] = []
		if int(m["gold"]) > 0:
			reward_parts.append("%d ouro" % int(m["gold"]))
		if int(m["xp"]) > 0:
			reward_parts.append("%d XP" % int(m["xp"]))
		rows[i]["info"].text = "%s — %s\nRecompensa: %s" % [m["title"], m["desc"], ", ".join(reward_parts)]
		rows[i]["button"].pressed.connect(_on_claim_pressed.bind(m["id"]))

	close_button.pressed.connect(_on_close_pressed)
	dungeon_button.pressed.connect(_on_dungeon_pressed)
	GameState.stats_changed.connect(_refresh)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for i in GameState.MISSIONS.size():
		var mission_id: String = GameState.MISSIONS[i]["id"]
		var claimed: bool = GameState.is_mission_claimed(mission_id)
		var complete: bool = GameState.is_mission_complete(mission_id)
		if claimed:
			rows[i]["status"].text = "Resgatada"
		elif complete:
			rows[i]["status"].text = "Pronta!"
		else:
			rows[i]["status"].text = "Em andamento"
		rows[i]["button"].disabled = claimed or not complete


func _on_claim_pressed(mission_id: String) -> void:
	GameState.claim_mission(mission_id)


func _on_close_pressed() -> void:
	visible = false


func _on_dungeon_pressed() -> void:
	visible = false
	get_tree().change_scene_to_file("res://scenes/Dungeon.tscn")
