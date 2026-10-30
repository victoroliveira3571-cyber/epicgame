extends Node

## Imprime vida/dano/XP/ouro dos monstros e chefes por andar com as fórmulas reais.
func run(_dev: Node) -> void:
	for f in [1, 3, 5, 8, 10, 15, 20, 25, 30]:
		var biome := Data.biome_for_floor(f)
		var hp := 0.0
		var dm := 0.0
		var xp := 0.0
		var gd := 0.0
		var n := 0
		for id in biome["enemies"]:
			var e := Enemy.new()
			e.def_id = id
			e.floor_n = f
			e._setup_stats()
			hp += e.max_hp
			dm += e.contact_dmg
			xp += e.xp_reward
			gd += (float(e.gold_range[0]) + float(e.gold_range[1])) / 2.0 * Data.floor_scale_reward(f)
			n += 1
			e.free()
		var line := "andar %2d %-16s hp %6.0f dano %5.1f xp %5.0f ouro %5.1f" % [f, biome["name"], hp / n, dm / n, xp / n, gd / n]
		if Data.is_boss_floor(f):
			var b := Boss.new()
			b.boss_id = Data.boss_for_floor(f)
			b.floor_n = f
			b._setup_stats()
			line += "  | chefe %s hp %.0f dano %.1f xp %d ouro %d-%d" % [b.display_name, b.max_hp, b.contact_dmg, b.xp_reward,
				int(b.gold_range[0] * Data.floor_scale_reward(f)), int(b.gold_range[1] * Data.floor_scale_reward(f))]
			b.free()
		print("[bal] ", line)
