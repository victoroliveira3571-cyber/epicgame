class_name Loot
extends RefCounted

## Tabelas de drop: o que monstros, chefes e baús soltam, conforme o andar e a classe.


static func drop_from_enemy(e: Enemy) -> void:
	var world := e.get_parent()
	var pos := e.global_position
	var lm := Data.floor_scale_reward(e.floor_n)
	var gold_total := float(randi_range(int(e.gold_range[0]), int(e.gold_range[1]))) * lm
	if e.is_elite:
		gold_total *= 2.5
	if e.is_boss:
		gold_total *= 1.0
	spawn_gold(world, pos, int(round(gold_total)))
	var luck_bonus := GameState.stat("luck") * 0.006
	if e.is_boss:
		_boss_loot(world, pos, e.floor_n)
		return
	var chance := 0.17 + luck_bonus + (0.5 if e.is_elite else 0.0)
	if randf() < chance:
		var id := roll_item(e.floor_n, e.is_elite)
		if id != "":
			Pickup.spawn(world, pos, "item", 1, id)
	if randf() < 0.09 + luck_bonus * 0.5:
		Pickup.spawn(world, pos, "heart", 1)


static func spawn_gold(world: Node, pos: Vector2, total: int) -> void:
	if total <= 0:
		return
	var n := clampi(total / 5 + 1, 1, 6)
	var each := maxi(1, total / n)
	for i in n:
		Pickup.spawn(world, pos, "gold", each if i < n - 1 else maxi(1, total - each * (n - 1)))


static func _boss_loot(world: Node, pos: Vector2, floor_n: int) -> void:
	var tier := mini(5, (floor_n - 1) / 3 + 1)
	var gear := roll_equipment(floor_n, tier)
	if gear != "":
		Pickup.spawn(world, pos, "item", 1, gear)
	if randf() < 0.6:
		var gear2 := roll_equipment(floor_n, maxi(0, tier - 1))
		if gear2 != "":
			Pickup.spawn(world, pos, "item", 1, gear2)
	for i in 3:
		Pickup.spawn(world, pos, "item", 1, roll_material(floor_n))
	Pickup.spawn(world, pos, "item", 1, "pocao_media" if floor_n >= 4 else "pocao_vida")
	Pickup.spawn(world, pos, "heart", 1)


## Item aleatório adequado ao andar.
static func roll_item(floor_n: int, elite: bool = false) -> String:
	var r := randf() * 100.0
	if elite:
		r *= 0.7  # elites favorecem equipamento
	if r < 36.0:
		var tier := _roll_tier(floor_n)
		return roll_equipment(floor_n, tier)
	if r < 60.0:
		return roll_potion(floor_n)
	if r < 86.0:
		return roll_material(floor_n)
	return "pao" if randf() < 0.6 else "onigiri"


static func _roll_tier(floor_n: int) -> int:
	var max_tier := mini(5, (floor_n - 1) / 3)
	var r := randf()
	var t := max_tier
	if r > 0.5:
		t -= 1
	if r > 0.8:
		t -= 1
	return maxi(0, t)


static func roll_equipment(_floor_n: int, tier: int) -> String:
	var pool: Array = []
	for slot in Data.EQUIP_SLOTS:
		for it in Data.ITEMS.values():
			if it["kind"] == "equip" and int(it["tier"]) == tier and it["slot"] == slot and Data.class_can_use(GameState.player_class, it["id"]):
				pool.append(it["id"])
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


static func roll_potion(floor_n: int) -> String:
	var r := randf()
	if floor_n >= 10 and r > 0.93:
		return "pocao_grande"
	if floor_n >= 4 and r > 0.7:
		return "pocao_media"
	return "pocao_vida"


static func roll_material(floor_n: int) -> String:
	var r := randf()
	if floor_n <= 5:
		if r < 0.75:
			return "barra_cobre"
		return "barra_ferro" if floor_n >= 3 else "barra_cobre"
	if floor_n <= 10:
		if r < 0.5:
			return "barra_ferro"
		return "barra_prata" if r < 0.85 else "gema_verde"
	if floor_n <= 15:
		if r < 0.45:
			return "barra_prata"
		return "barra_ouro" if r < 0.85 else "gema_roxa"
	if r < 0.4:
		return "barra_ouro"
	return "barra_mithril" if r < 0.8 else "gema_vermelha"
