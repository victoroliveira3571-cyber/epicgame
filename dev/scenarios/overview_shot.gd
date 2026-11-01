extends Node

## Visão geral de um mapa inteiro (câmera afastada), para conferir a disposição das casas.
## Uso: --scenario=overview_shot -- --map=town|forest|<cidade>
var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	var m := "town"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			m = a.substr(6)
	if m == "town":
		Game.go_to_town("start")
	elif m == "forest":
		Game.go_to_forest("town")
	else:
		Game.go_to_city(m)
	await dev.wait(3.5)
	var sc := get_tree().current_scene
	var sz := Vector2(int(sc.get("W")) * 16, int(sc.get("H")) * 16)
	var cam := Camera2D.new()
	cam.position = sz / 2.0
	cam.zoom = Vector2.ONE * minf(1280.0 / sz.x, 720.0 / sz.y)
	sc.add_child(cam)
	cam.make_current()
	HUD.visible = false
	for c in HUD.get_children():
		if c is CanvasItem:
			(c as CanvasItem).visible = false
	await dev.wait(0.6)
	await dev.shot(OUT + "overview_%s.png" % m)
	print("[ov] ok ", m)
