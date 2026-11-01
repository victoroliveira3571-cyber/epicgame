extends Node

## v3.2: gera o chão de teste de cada bioma de cidade (prints em _shots/city_ground_*.png).
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"


func run(_dev: Node) -> void:
	var w := 40
	var h := 22
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var path := PackedByteArray()
	var water := PackedByteArray()
	path.resize(w * h)
	water.resize(w * h)
	for x in w:
		for y in range(10, 13):
			path[y * w + x] = 1
	for x in range(26, 38):
		for y in range(3, 9):
			water[y * w + x] = 1
	var setups := {
		"porto": [12, [{"mask": water, "set": "water", "origin": Vector2i(0, 6)}, {"mask": path, "set": "floor", "origin": Vector2i(0, 0)}], Color.WHITE],
		"pedralta": [19, [{"mask": water, "set": "water", "origin": Vector2i(0, 6)}, {"mask": path, "set": "stone", "origin": Vector2i(0, 7)}], Color(0.9, 0.95, 1.0)],
		"academia": [12, [{"mask": water, "set": "water", "origin": Vector2i(0, 6)}, {"mask": path, "set": "stone", "origin": Vector2i(0, 7)}], Color(0.95, 0.95, 1.05)],
		"deserto": [5, [{"mask": water, "set": "water", "origin": Vector2i(0, 6)}, {"mask": path, "set": "floor", "origin": Vector2i(0, 7)}], Color.WHITE],
	}
	for k in setups:
		var s: Array = setups[k]
		var img := TileComposer.compose_city(w, h, s[0], s[1], rng, s[2])
		img.save_png(OUT + "city_ground_%s.png" % k)
		print("[city] ", k, " ", img.get_size())
