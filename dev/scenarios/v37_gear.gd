extends Node

## v3.7: galeria das armaduras por classe (LpcW.CLASS_GEAR). Uma linha por classe, uma coluna por tier
## (armadura + capacete + botas do mesmo tier), masculino e feminino. Print em _shots/v37_gear_<corpo>.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")
const CLASSES := ["cavaleiro", "escudeiro", "paladino", "arqueiro", "assassino", "mago"]


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	for body in ["male", "female"]:
		var stage := Node2D.new()
		get_tree().current_scene.add_child(stage)
		var bg := ColorRect.new()
		bg.color = Color(0.35, 0.42, 0.33)
		bg.size = Vector2(2000, 2000)
		bg.position = Vector2(-500, -500)
		bg.z_index = -10
		stage.add_child(bg)
		var actors: Array = []
		for r in CLASSES.size():
			for t in 8:
				var lk := LpcW.default_look(body)
				lk["gear"] = {"armor": t, "helmet": t, "boots": t, "shield": t} if CLASSES[r] in ["escudeiro", "paladino"] else {"armor": t, "helmet": t, "boots": t}
				lk["gear_family"] = LpcW.gear_family(CLASSES[r])
				lk["weapon"] = str(Data.CLASSES[CLASSES[r]]["weapon"])
				var a := LpcActor.make(stage, lk, false)
				a.position = Vector2(40 + t * 44, 52 + r * 40)
				actors.append(a)
				var lab := Label.new()
				lab.text = CLASSES[r] if t == 0 else ""
				if r == 0:
					var tl := Label.new()
					tl.text = Data.TIER_NAMES[t]
					tl.position = a.position + Vector2(-16, -46)
					tl.add_theme_font_size_override("font_size", 6)
					stage.add_child(tl)
				lab.position = a.position + Vector2(-38, -30)
				lab.add_theme_font_size_override("font_size", 6)
				stage.add_child(lab)
		var cam := Camera2D.new()
		cam.zoom = Vector2(2.2, 2.2)
		cam.position = Vector2(190, 150)
		stage.add_child(cam)
		cam.make_current()
		HUD.set_scene_kind("")
		await dev.wait(8.0)
		await dev.shot(OUT + "v37_gear_%s.png" % body)
		stage.queue_free()
		await dev.wait(0.3)
