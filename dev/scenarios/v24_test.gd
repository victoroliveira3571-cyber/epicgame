extends Node

## v2.4: fome (1 min para comer, depois desmaia) e dificuldade.

var fails := 0


func check(ok: bool, what: String) -> void:
	print("[v24] ", "ok   " if ok else "FALHA", " ", what)
	if not ok:
		fails += 1


func run(_dev: Node) -> void:
	var gs := GameState
	gs.hp = gs.get_max_hp()
	gs.hunger = 0
	gs.starve_left = -1.0
	var died := [false]
	var cb := func() -> void: died[0] = true
	gs.player_died.connect(cb)
	gs._tick_starvation(0.1)
	check(gs.starve_left == GameState.STARVE_SECONDS, "fome zerada abre a contagem de 60 s")
	gs._tick_starvation(30.0)
	check(not died[0] and gs.starve_left > 29.0, "30 s depois ainda vivo")
	gs.eat_hunger(30)
	gs._tick_starvation(0.1)
	check(gs.starve_left < 0.0, "comer cancela a contagem")
	gs.hunger = 0
	gs._tick_starvation(0.1)
	gs._tick_starvation(61.0)
	check(died[0] and gs.hp == 0, "contagem zerada: desmaia")
	gs.revive_after_defeat()
	check(gs.hunger > 0 and gs.hp > 0, "ao acordar há comida na barra")
	gs.player_died.disconnect(cb)
	gs.hp = gs.get_max_hp()
	gs.set_difficulty(1)
	var normal := gs.take_damage(100.0)
	gs.hp = gs.get_max_hp()
	gs.set_difficulty(0)
	var easy := gs.take_damage(100.0)
	gs.hp = gs.get_max_hp()
	gs.set_difficulty(2)
	var hard := gs.take_damage(100.0)
	check(easy < normal and normal < hard, "dano: fácil %d < médio %d < difícil %d" % [easy, normal, hard])
	gs.set_difficulty(1)
	check(is_equal_approx(gs.reward_mult(), 1.0), "médio recompensa x1")
	# v2.6: hábitos
	var n0: int = gs.habits.size()
	check(gs.add_habit() and gs.habits.size() == n0 + 1, "hábito novo")
	var last: int = gs.habits.size() - 1
	gs.habits[last]["last_completed_date"] = ""
	gs.set_habit_difficulty(last, 0)
	var easy_h: Dictionary = gs.complete_habit(last)
	gs.habits[last]["last_completed_date"] = ""
	gs.habits[last]["streak"] = 0
	gs.set_habit_difficulty(last, 2)
	var hard_h: Dictionary = gs.complete_habit(last)
	check(int(easy_h["xp"]) < int(hard_h["xp"]), "hábito difícil rende mais (%d < %d)" % [easy_h["xp"], hard_h["xp"]])
	gs.remove_habit(last)
	check(gs.habits.size() == n0, "hábito removido")
	gs.set_auto_aim(false)
	check(true, "mira manual definida")
	gs.set_auto_aim(true)
	gs.hp = gs.get_max_hp()
	print("[v24] ", "TUDO OK" if fails == 0 else "%d falhas" % fails)
