extends Node

func run(dev: Node) -> void:
	var f: FontFile = load("res://assets/ui/NormalFont.ttf")
	var missing := ""
	for ch in "áàâãéêíóôõúçÁÉÍÓÚÇ—✓🔥⚡♥★●→×·…":
		if not f.has_char(ord(ch)):
			missing += ch
	print("[smoke_font] glifos ausentes: ", missing)
	await dev.wait(0.5)
	await dev.shot(ProjectSettings.globalize_path("res://_shots/shot_smoke.png"))
