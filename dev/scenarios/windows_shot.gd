extends Node

## Abre todas as janelas com conteúdo (Ferreiro com item escolhido, Resumo com itens etc.) e tira prints.
var OUT: String = ProjectSettings.globalize_path("res://_shots/")

func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	GameState.level = 14
	GameState.talent_points = 3
	GameState.gold = 4321
	GameState.energy = 5
	for id in ["pocao_vida", "pocao_media", "pao", "onigiri", "barra_cobre", "barra_ferro", "gema_verde"]:
		GameState.add_item(id, 4, true)
	for id in ["espada_ferro", "capacete_ferro", "escudo_ferro", "botas_ferro", "amuleto_cobre"]:
		GameState.add_item(id, 1, true)
		GameState.equip_item(id)
	GameState.add_item("botas_couro", 1, true)
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	for w in ["loja", "forja", "guilda", "dungeon", "habitos", "restaurante", "casa", "historico", "inventario", "personagem", "pausa"]:
		HUD.open_window(w)
		await dev.wait(0.4)
		if w == "forja":
			HUD.window.selected = "espada_ferro"
			HUD.window.rebuild()
			await dev.wait(0.2)
		await dev.shot(OUT + "win_%s.png" % w)
		HUD.close_window()
		await dev.wait(0.15)
	Game.last_run_summary = {"died": false, "start_floor": 3, "deepest": 6, "kills": 41, "bosses": 1, "chests": 3,
		"gold": 380, "xp": 925, "time": 612.0,
		"items": {"pocao_vida": 2, "barra_ferro": 3, "gema_verde": 1, "espada_ferro": 1, "botas_couro": 1, "pao": 4}}
	HUD.open_window("resumo")
	await dev.wait(0.4)
	await dev.shot(OUT + "win_resumo.png")
