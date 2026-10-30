extends Node

const OUT := "/private/tmp/claude-501/-Users-victor-Desktop-EPICGAME/e3184624-fc7c-45f0-b2d1-ae52c5b12071/scratchpad/"

func run(dev: Node) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 200
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color("2a1d2e")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(bg)
	var base: FontFile = load("res://assets/ui/NormalFont.ttf")
	var variants := {}
	var a: FontFile = base.duplicate(); a.antialiasing = TextServer.FONT_ANTIALIASING_GRAY; a.hinting = TextServer.HINTING_NORMAL; a.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	variants["gray+normal hint"] = a
	var b: FontFile = base.duplicate(); b.antialiasing = TextServer.FONT_ANTIALIASING_NONE; b.hinting = TextServer.HINTING_NORMAL; b.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	variants["none+normal hint"] = b
	var c: FontFile = base.duplicate(); c.antialiasing = TextServer.FONT_ANTIALIASING_NONE; c.hinting = TextServer.HINTING_NONE; c.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	variants["none+none hint"] = c
	var d: FontFile = base.duplicate(); d.antialiasing = TextServer.FONT_ANTIALIASING_GRAY; d.hinting = TextServer.HINTING_NONE; d.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	variants["gray+none hint+subpx"] = d
	var y := 6.0
	var sample := "Guilda dos Aventureiros - Nível 5 áçãõ 0123 Poção i l t"
	for k in variants:
		for sz in [8, 16, 24]:
			var l := Label.new()
			l.text = "%s %d: %s" % [k, sz, sample]
			l.add_theme_font_override("font", variants[k])
			l.add_theme_font_size_override("font_size", sz)
			l.add_theme_color_override("font_color", Color.WHITE)
			l.position = Vector2(10, y)
			cl.add_child(l)
			y += sz + 8
		y += 10
	await dev.wait(0.4)
	await dev.shot(OUT + "font_test2.png")
