extends Node

## Galeria dos cenários do palco de diálogos. Prints em _shots/stage_<cenario>.png.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	Law.data()["jail_left"] = 0
	Game.go_to_town("start")
	await dev.wait(2.0)
	var pairs := [["town_day", "marta"], ["town_dusk", "helena"], ["town_night", "pietro"], ["forest", "osvaldo"], ["forest_deep", "espirito"],
		["swamp", "lin"], ["clearing", "brisa"], ["ruins", "sentinela"], ["dungeon", "cavaleiro"], ["throne", "rei"], ["inn", "estalajadeiro"],
		["guild", "helena"], ["library", "bibliotecaria"], ["forge", "ferreiro"], ["weapons", "armeiro"], ["arena", "arena"], ["home", "mae"], ["jail", "guarda"]]
	for p in pairs:
		var st := Stage.new()
		HUD.root.add_child(st)
		st.open_stage(p[0])
		await dev.wait(0.9)
		st.focus(p[1], Looks.speaker_visual(p[1]))
		await dev.wait(1.2)
		await dev.shot(OUT + "stage_%s.png" % p[0])
		st.queue_free()
	print("[stage] ok")
