extends Node

var OUT: String = ProjectSettings.globalize_path("res://_shots/")


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("mago")
	Law.data()["jail_left"] = 0
	Game.go_to_town("start")
	await dev.wait(2.0)
	Cutscene.play("sit", {"setting": "library"})
	await dev.wait(1.6)
	await dev.shot(OUT + "cut_sit_1.png")
	await dev.wait(1.8)
	await dev.shot(OUT + "cut_sit_2.png")
	await dev.wait(2.5)
	Cutscene.play("toll", {"guard": "osvaldo", "setting": "gate_forest"})
	await dev.wait(2.1)
	await dev.shot(OUT + "cut_toll_1.png")
	await dev.wait(1.2)
	await dev.shot(OUT + "cut_toll_2.png")
	await dev.wait(3.0)
	print("[cut] ok")
