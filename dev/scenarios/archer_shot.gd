extends Node
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("arqueiro")
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	var p: Player = get_tree().get_first_node_in_group("player")
	p.camera.zoom = Vector2(6, 6)
	Input.action_press("attack")
	await dev.wait(0.12)
	await dev.shot(OUT + "archer_1.png")
	Input.action_release("attack")
