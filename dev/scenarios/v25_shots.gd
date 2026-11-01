extends Node

## Prints v2.8: loja no nível 100 (8 tiers) e veio de minério na floresta.

const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.level = 100
	GameState.gold = 99999
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.5)
	HUD.open_window("loja")
	await dev.wait(0.6)
	var w: UIWindow = HUD.window
	for sc in w.body.get_children():
		if sc is ScrollContainer:
			(sc as ScrollContainer).scroll_vertical = 100000
	await dev.wait(0.3)
	await dev.shot(OUT + "v28_loja.png")
	HUD.close_window()
	Game.go_to_forest("town")
	await dev.wait(2.0)
	for n in get_tree().get_nodes_in_group("player")[0].get_parent().get_children():
		if n is StoryProp and str((n as StoryProp).text).begins_with("Minerar"):
			get_tree().get_first_node_in_group("player").global_position = (n as Node2D).global_position + Vector2(0, 14)
			break
	await dev.wait(1.0)
	await dev.shot(OUT + "v28_minerio.png")
