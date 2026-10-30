extends Node
func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	var tr: TextureRect = HUD.window.get_node("Paisagem")
	print("[dbg] tr size=", tr.size, " pos=", tr.position, " tex=", tr.texture, " vis=", tr.visible, " modulate=", tr.modulate, " win size=", HUD.window.size, " root=", HUD.root.size)
