extends Node

## Diagnóstico da passagem para a Mata Profunda (lado escuro): com Rank C, procura a barreira da
## Guilda e os colisores que bloqueiam a trilha. Saída só no console e um print.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(dev: Node) -> void:
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("cavaleiro")
	Story.st()["rank"] = 1   # Rank E: a Mata já deveria estar liberada
	Story.set_step("c2_lin")   # passo em que Mestre Lin fica na ponte
	GameState.mark_dirty()
	Game.go_to_forest("town")
	await dev.wait(2.5)
	var f := get_tree().current_scene
	var pl := get_tree().get_first_node_in_group("player") as Node2D
	print("[floresta] rank=", Story.rank(), " zona mata liberada=", Story.zone_unlocked("mata"))
	var barriers := 0
	for c in f.world.get_children():
		if c is StaticBody2D and c.get_child_count() > 0 and c.get_child(0) is CollisionShape2D:
			var sh = (c.get_child(0) as CollisionShape2D).shape
			if sh is RectangleShape2D and is_equal_approx((sh as RectangleShape2D).size.x, 10.0):
				barriers += 1
				print("[floresta] barreira encontrada em ", c.position, " tamanho ", (sh as RectangleShape2D).size)
	print("[floresta] barreiras com 10 px de largura: ", barriers, " | _barrier: ", f.get("_barrier"))
	var space := pl.get_world_2d().direct_space_state
	var blocked := []
	for row in [f.PATH_Y - 6, f.PATH_Y, f.PATH_Y + 6]:
		for col in range(f.RIVER_X - 6, f.RIVER_X + 30):
			var q := PhysicsPointQueryParameters2D.new()
			q.position = Vector2(col * 16 + 8, row * 16 + 12)
			q.collision_mask = 1
			var hits := space.intersect_point(q, 8)
			if not hits.is_empty():
				blocked.append([col, row, String(hits[0]["collider"].name)])
	print("[floresta] pontos bloqueados (coluna, linha, colisor): ", blocked.size())
	for b in blocked.slice(0, 40):
		print("[floresta]   ", b)
	pl.global_position = Vector2((f.RIVER_X + 8) * 16, f.PATH_Y * 16 + 12)
	await dev.wait(1.0)
	await dev.shot(OUT + "teste_floresta_mata.png")
	print("[floresta] posição final do jogador: ", pl.global_position)
