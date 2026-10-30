extends UIWindow

## Créditos (menu de pausa): arte, músicas, sons e os autores das roupas LPC (Lpc.credit_lines()).
## Lista completa com arquivos e licenças em ASSETS.md.

const SECTIONS := [
	["Arte", [
		"Ninja Adventure Asset Pack - pixel-boy e AAA (CC0): cidade, masmorra, monstros, itens, UI e efeitos.",
		"Cenários do Pomodoro, interiores e paisagens: arte própria gerada por scripts (tools/).",
		"Herói com roupas: Universal LPC Spritesheet Character Generator (autores abaixo).",
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
	if not (lpc[0] as Array).is_empty():
		col.add_child(UI.label("Roupas e corpos LPC - autores", UI.C_ORANGE_L))
		col.add_child(UI.wrap_label(", ".join(lpc[0]), UI.C_TEXT, body.size.x - 30))
		col.add_child(UI.spacer(2))
		col.add_child(UI.label("Licenças: " + ", ".join(lpc[1]), UI.C_DIM))
		col.add_child(UI.wrap_label("Fonte: github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator (CREDITS.csv).", UI.C_DIM, body.size.x - 30))
