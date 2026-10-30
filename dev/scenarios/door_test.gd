extends Node

## Entra e sai dos interiores pelas portas da cidade (e confirma que nada está bloqueado por nível).
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("paladino")
	GameState.level = 1
	GameState.buy_furniture("cama") if GameState.gold >= 60 else null
	get_tree().reload_current_scene()
	await dev.wait(1.0)
	var town := get_tree().current_scene
	var doors: Array = []
	for n in get_tree().get_nodes_in_group("interactable"):
		if n.has_method("get_prompt") and n.get("building") != null:
			doors.append(n)
	print("[door] portas na cidade: ", doors.size())
	for d in doors:
		var b: Building = d.building
		print("[door] ", b.building_id, " interior='", b.interior_id, "' prompt=", d.get_prompt(), " pode=", d.can_interact(null))
	var targets := ["casa", "restaurante", "guilda", "casa_npc_0", "casa_npc_3"]
	for t in targets:
		var found: Interactable = null
		for d in get_tree().get_nodes_in_group("interactable"):
			if d.get("building") != null and d.building.interior_id == t:
				found = d
		if found == null:
			print("[door] FALTOU porta para ", t)
			continue
		found.interact(null)
		await dev.wait(1.6)
		print("[door] dentro de ", t, ": cena=", get_tree().current_scene.name, " id=", Game.interior_id)
		var interior: Interior = get_tree().current_scene
		interior._leave()
		await dev.wait(1.6)
		var pl: Player = get_tree().get_first_node_in_group("player")
		print("[door] voltou: cena=", get_tree().current_scene.name, " jogador em ", pl.global_position.round())
		await dev.wait(0.2)
