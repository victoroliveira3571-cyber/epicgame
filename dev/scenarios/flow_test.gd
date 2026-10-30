extends Node

## Fluxo completo: cidade -> masmorra (andar 1) -> morte -> cidade com resumo da expedição.
const OUT := "/private/tmp/claude-501/-Users-victor-Desktop-EPICGAME/fb73ee53-e2fb-41d8-854a-a4ec864f0bcc/scratchpad/"

func run(dev: Node) -> void:
	GameState.debug_reset()
	GameState.choose_class("mago")
	GameState.level = 6
	GameState.energy = 4
	GameState.mark_dirty()
	GameState.full_heal()
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	print("[flow] cidade ok, energia=", GameState.energy)
	Game.enter_dungeon(1)
	await dev.wait(2.5)
	print("[flow] masmorra: inimigos=", get_tree().get_nodes_in_group("enemy").size(), " energia=", GameState.energy)
	# luta de verdade: teleporta perto de um inimigo, ataca e usa a skill
	var d := get_tree().get_first_node_in_group("dungeon")
	var e: Node2D = get_tree().get_first_node_in_group("enemy")
	d.player.global_position = e.global_position + Vector2(-40, 0)
	for i in 8:
		Input.action_press("attack")
		await dev.wait(0.12)
		Input.action_release("attack")
		await dev.wait(0.2)
	Input.action_press("skill")
	await dev.wait(0.1)
	Input.action_release("skill")
	await dev.wait(0.8)
	print("[flow] kills=", Game.run.get("kills"), " xp=", Game.run.get("xp"), " ouro=", Game.run.get("gold"))
	await dev.shot(OUT + "flow_1_fight.png")
	GameState.take_damage(99999)
	await dev.wait(4.0)
	print("[flow] cena atual: ", get_tree().current_scene.name, " janela=", HUD.window_id, " class_hp=", GameState.hp)
	await dev.shot(OUT + "flow_2_summary.png")
	HUD.close_window()
	await dev.wait(0.5)
	print("[flow] fim: in_dungeon=", GameState.in_dungeon, " paused=", get_tree().paused)
