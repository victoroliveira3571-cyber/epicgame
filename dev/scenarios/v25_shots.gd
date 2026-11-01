extends Node

## Prints: biblioteca (marca de estudo) e casa no modo Decorar (v2.7).

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	Game.enter_interior("casa")
	await dev.wait(1.8)
	await dev.shot(OUT + "v27_casa.png")
	GameState.furniture = ["sofa"]
	var room := get_tree().current_scene as Interior
	room.housing.set_active(true)
	await dev.wait(0.6)
	await dev.shot(OUT + "v27_casa_decorar.png")
	room.housing.set_active(false)
	await dev.wait(0.3)
	print("[v27] minimapa visível após sair: ", HUD._minimap.visible, " cartão: ", HUD._card.visible)
