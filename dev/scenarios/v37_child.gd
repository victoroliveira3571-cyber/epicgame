extends Node

## v3.7: corpo de criança do LPC (prólogo). Menino e menina ao lado dos adultos, andando e parados.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	var stage := Node2D.new()
	get_tree().current_scene.add_child(stage)
	var bg := ColorRect.new()
	bg.color = Color(0.4, 0.45, 0.36)
	bg.size = Vector2(800, 600)
	bg.position = Vector2(-200, -200)
	bg.z_index = -10
	stage.add_child(bg)
	var adult_m := LpcW.default_look("muscular")
	var adult_f := LpcW.default_look("female")
	var looks := [LpcW.child_look(adult_m, false), LpcW.child_look(adult_f, true), adult_m, adult_f]
	for i in looks.size():
		for j in 2:
			var a := LpcActor.make(stage, looks[i], true)
			a.position = Vector2(30 + i * 40, 60 + j * 50)
			a.play("walk_down" if j == 0 else "slash_right")
	var cam := Camera2D.new()
	cam.zoom = Vector2(4, 4)
	cam.position = Vector2(90, 70)
	stage.add_child(cam)
	cam.make_current()
	await dev.wait(4.0)
	await dev.shot(OUT + "v37_child.png")
