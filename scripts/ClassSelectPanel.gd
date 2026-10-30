extends PanelContainer

## Tela de escolha de classe — aparece uma única vez, no primeiro boot
## (GameState.player_class ainda vazio). Depois de escolher, nunca mais volta.

@onready var buttons: Dictionary = {
	"cavaleiro": $Margin/VBox/Grid/CavaleiroButton,
	"paladino": $Margin/VBox/Grid/PaladinoButton,
	"assassino": $Margin/VBox/Grid/AssassinoButton,
	"escudeiro": $Margin/VBox/Grid/EscudeiroButton,
	"mago": $Margin/VBox/Grid/MagoButton,
	"arqueiro": $Margin/VBox/Grid/ArqueiroButton,
}


func _ready() -> void:
	GameState.stats_changed.connect(_on_stats_changed)
	for class_id in buttons.keys():
		var info: Dictionary = GameState.CLASSES[class_id]
		var style: String = "Corpo a corpo" if info["melee"] else "À distância"
		buttons[class_id].text = "%s\n%s · Ataque %d · Vida %d" % [
			info["name"], style, info["attack"], info["max_hp"]
		]
		buttons[class_id].pressed.connect(_on_class_pressed.bind(class_id))


func _on_class_pressed(class_id: String) -> void:
	GameState.set_class(class_id)
	visible = false


## Rede de segurança: se a classe acabar sendo escolhida por outro caminho
## (ex.: carregando um save que já tem classe), some mesmo assim.
func _on_stats_changed() -> void:
	if GameState.has_chosen_class():
		visible = false
