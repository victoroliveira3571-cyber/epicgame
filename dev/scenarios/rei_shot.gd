extends Node

## Rei Demônio (chifres, asas e cauda): quadros parado nas 4 direções, andando e conjurando.
const OUT := "/Users/victor/Desktop/EPICGAME/game/_shots/"

func run(d: Node) -> void:
	var look: Dictionary = Looks.of("rei_demonio")
	var frames := [Rect2i(576, 0, 64, 64), Rect2i(576, 64, 64, 64), Rect2i(576, 128, 64, 64), Rect2i(576, 192, 64, 64),
		Rect2i(192, 128, 64, 64), Rect2i(768, 384, 64, 64)]   # parado x4, andando (baixo), conjurando (baixo)
	var out := Image.create(64 * frames.size(), 64, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.35, 0.32, 0.3))
	var got := [false]
	LpcW.request(look, "full", func(t: Texture2D) -> void:
		var img := t.get_image()
		for i in frames.size():
			out.blend_rect(img, frames[i], Vector2i(i * 64, 0))
		got[0] = true)
	for i in 120:
		if got[0]:
			break
		await d.wait(0.1)
	out.resize(64 * frames.size() * 3, 192, Image.INTERPOLATE_NEAREST)
	out.save_png(OUT + "rei_demonio.png")
	print("rei ok=", got[0])
