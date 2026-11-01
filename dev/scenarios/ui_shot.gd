extends Node

## Abre janelas da interface e tira prints. Uso: --scenario=ui_shot -- --wins=inventario,personagem
var OUT: String = ProjectSettings.globalize_path("res://_shots/")

func run(dev: Node) -> void:
	var wins: PackedStringArray = ["inventario", "personagem"]
	var lvl := 12
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--wins="):
			wins = arg.substr(7).split(",")
		if arg.begins_with("--level="):
			lvl = int(arg.substr(8))
	GameState.debug_reset()
	Story.dev_start()
	if "classe" not in wins:
		GameState.choose_class("cavaleiro")
		GameState.level = lvl
		GameState.talent_points = 4
		GameState.gold = 1234
		GameState.energy = 6
		for id in ["pocao_vida", "pocao_media", "pao", "onigiri", "macarrao", "barra_cobre", "barra_ferro", "gema_verde"]:
			GameState.add_item(id, 3, true)
		for id in ["esp_ferro" , "espada_ferro", "elmo_ferro", "armadura_ferro", "botas_ferro", "amuleto_ferro"]:
			if not Data.get_item(id).is_empty():
				GameState.add_item(id, 1, true)
		GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	await dev.shot(OUT + "ui_hud.png")
	for w in wins:
		HUD.open_window(w)
		await dev.wait(0.5)
		await dev.shot(OUT + "ui_%s.png" % w)
		HUD.close_window()
		await dev.wait(0.2)
