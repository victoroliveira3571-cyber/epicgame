extends Node

func run(dev: Node) -> void:
	var f: FontFile = load("res://assets/ui/NormalFont.ttf")
	var missing := ""
	for ch in "áàâãéêíóôõúçÁÉÍÓÚÇ—✓🔥⚡♥★●→×·…":
		if not f.has_char(ord(ch)):
			missing += ch
	print("[smoke_font] glifos ausentes: ", missing)
	await dev.wait(0.5)
	await dev.shot("/private/tmp/claude-501/-Users-victor-Desktop-EPICGAME/e3184624-fc7c-45f0-b2d1-ae52c5b12071/scratchpad/shot_smoke.png")
