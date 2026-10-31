extends Node
func run(d: Node) -> void:
	var variants := []
	for k in 5:
		var lk := LpcW.default_look("female")
		lk["weapon"] = "arming"
		lk["gear"] = {"armor": 3, "helmet": 5, "shield": 3, "boots": 3}
		match k:
			1: lk["gear"].erase("shield")
			2: lk["gear"].erase("helmet")
			3: lk["weapon"] = ""
			4: lk["gear"] = {"shield": 3}
		variants.append(lk)
	var out := Image.create(64 * 5, 64, false, Image.FORMAT_RGBA8)
	var n := [0]
	for k in 5:
		var kk := k
		LpcW.request(variants[k], "full", func(t: Texture2D) -> void:
			out.blend_rect(t.get_image(), Rect2i(576, 128, 64, 64), Vector2i(kk * 64, 0))
			n[0] += 1)
	await d.wait(1.0)
	out.resize(640, 128, Image.INTERPOLATE_NEAREST)
	out.save_png("/Users/victor/Desktop/EPICGAME/game/_shots/dbg_variants.png")
	print("n=", n)
