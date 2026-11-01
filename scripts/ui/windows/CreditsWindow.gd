extends UIWindow

## Créditos (menu de pausa): arte, músicas, sons e os autores das roupas LPC (Lpc.credit_lines()).
## Lista completa com arquivos e licenças em ASSETS.md.

const SECTIONS := [
	["Arte", [
		"Ninja Adventure Asset Pack - pixel-boy e AAA (CC0): cidade, masmorra, monstros, itens, UI e efeitos.",
		"Cenários do Pomodoro, interiores e paisagens: arte própria gerada por scripts (tools/).",
		"Herói com roupas: Universal LPC Spritesheet Character Generator (autores abaixo).",
		"Ícones do laboratório: 496 RPG icons (OpenGameArt, CC0).",
		"Móveis da casa: LPC House Interior (Tuomo Untinen, Lanea Zimmerman e outros; CC-BY-SA 3.0 / GPL), LPC Upholstery (OpenGameArt) e Tables & Stools (Jordan Irwin; CC-BY 3.0 / OGA-BY 3.0), reduzidos e recoloridos.",
		"Rei Demônio: chifres e cauda de Nila122 (bluecarrot16, JaidynReiman), asas de morcego de ElizaWy (JaidynReiman); OGA-BY 3.0 / CC-BY-SA 3.0 / GPL 3.0.",
	]],
	["Músicas do Pomodoro (Pixabay)", [
		"Lo-fi: soundsurfer \"lofi\", Leberch \"differently (slowed + reverb)\", the_mountain \"study session\", sub_clair \"background music instrumental\".",
		"Piano: harumachimusic \"peaceful garden\", Leberch \"ambient piano\".",
		"Motivação: AudioAtlant \"rebel moon\", bombinsound \"corporate motivation\" (2 versões).",
	]],
	["Músicas do jogo", [
		"kiravale, Watermelon Beats, Forgotten Hero Records, Deuslower, kaazoom e Ninja Adventure.",
	]],
	["Sons", [
		"freesound_community, freesound_gamestudio, coghezzi, composiia, benvibrant, kaazoom, 666herohero e Ninja Adventure.",
		"Sons de ambiente provisórios do Pomodoro: sintetizados (tools/gen_pomodoro_sfx.py).",
	]],
	["Mini-jogos", [
		"Forja: kanmandev (Blacksmith), Anvil 2 (OpenGameArt, CC0), life-in-pixels (Sword and hammer character).",
		"Cozinha: Lucky Loops (64 Food Icons), Luca Pixel (CC0), ElectrikJelli, caldeirão CC0 (OpenGameArt).",
		"Estações animadas (forno, bigorna, fogão, mesa de alquimia): Pixel Crawler, de Anokolisa.",
		"Laboratório: Gelidus Canimons (Potion Pack), mak993 (Pixel Potions), Codiacs (Codi's Potion Essentials, CC-BY 4.0).",
	]],
]


func _init() -> void:
	win_title = "Créditos"
	win_size = Vector2(560, 320)


func build() -> void:
	var col := scroll_column(Vector2(0, 0), Vector2(body.size.x, body.size.y))
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN   # deixa espaço para a barra de rolagem
	col.custom_minimum_size.x = body.size.x - 16
	for sec in SECTIONS:
		col.add_child(UI.label(sec[0], UI.C_ORANGE_L))
		for line in sec[1]:
			col.add_child(UI.wrap_label(line, UI.C_TEXT, body.size.x - 30))
		col.add_child(UI.spacer(4))
	var lpc := Lpc.credit_lines()
	# autores das peças do mundo (corpos, rostos, armaduras, armas) somados aos do guarda-roupa
	var world_lpc := LpcW.credit_lines()
	var authors: Array = (lpc[0] as Array).duplicate()
	for a in world_lpc[0]:
		if not authors.has(a):
			authors.append(a)
	var lic: Array = (lpc[1] as Array).duplicate()
	for l in world_lpc[1]:
		if not lic.has(l):
			lic.append(l)
	authors.sort_custom(func(x: String, y: String) -> bool: return x.to_lower() < y.to_lower())
	lpc = [authors, lic]
	if not (lpc[0] as Array).is_empty():
		col.add_child(UI.label("Personagens LPC (corpos, rostos, roupas, armaduras e armas) - autores", UI.C_ORANGE_L))
		col.add_child(UI.wrap_label(", ".join(lpc[0]), UI.C_TEXT, body.size.x - 30))
		col.add_child(UI.spacer(2))
		col.add_child(UI.label("Licenças: " + ", ".join(lpc[1]), UI.C_DIM))
		col.add_child(UI.wrap_label("Fonte: github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator (CREDITS.csv).", UI.C_DIM, body.size.x - 30))
