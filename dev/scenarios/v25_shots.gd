extends Node

## Prints da Pausa e dos Hábitos (v2.5/v2.6).

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	await dev.wait(1.0)
	HUD.open_window("pausa")
	await dev.wait(0.5)
	await dev.shot(OUT + "v26_pausa.png")
	HUD.close_window()
	HUD.open_window("habitos")
	await dev.wait(0.5)
	await dev.shot(OUT + "v26_habitos.png")
