extends Node

## v3.2: prints das cidades de dia (use --hour=12) em pontos de interesse.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"
const SPOTS := {
	"porto": [[28, 27], [30, 38]], "pedralta": [[28, 24], [28, 12]], "academia": [[28, 22], [30, 33]],
}


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	GameState.mark_dirty()
	get_tree().reload_current_scene()
	await dev.wait(1.2)
	# estação de carruagens na cidade
	var tob := get_tree().get_nodes_in_group("speaker_cocheiro")
	if not tob.is_empty():
		var pl := get_tree().get_first_node_in_group("player") as Node2D
		pl.global_position = (tob[0] as Node2D).global_position + Vector2(0, 36)
		await dev.wait(0.8)
		await dev.shot(OUT + "city_estacao.png")
	for id in CityData.ORDER:
		Game.go_to_city(id)
		await dev.wait(4.0)
		var sc := get_tree().current_scene
		var i := 0
		for p in SPOTS[id]:
			sc.player.global_position = Vector2(p[0] * 16 + 8, p[1] * 16)
			await dev.wait(0.8)
			await dev.shot(OUT + "city_%s_%d.png" % [id, i])
			i += 1
