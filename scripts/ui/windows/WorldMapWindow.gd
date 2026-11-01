class_name WorldMapWindow
extends UIWindow

## v3.7: mapa-múndi de Vicerus (história v4, seção 2). Reinos, lugares e estradas, onde você está, o próximo
## objetivo e o que ainda está trancado (e por quê). As estradas mostram o perigo do caminho: viagens de
## carruagem podem ter emboscada (Game.travel_road). Abre pelo mapa grande (M) ou pela carruagem do Tobias.
## Desenho só com formas da interface (sem arte nova); provisório até um pack de mapa (Kenney Fantasy UI Borders).

## id -> [nome, posição no mapa (0..1), reino, cor do reino, rótulo embaixo (true) ou em cima]
const PLACES := {
	"casa": ["Casa da família", Vector2(0.34, 0.56), "Floresta entre os reinos", Color("5aa05a"), true],
	"floresta": ["Floresta", Vector2(0.46, 0.46), "Floresta entre os reinos", Color("5aa05a"), false],
	"focus": ["Focus Town", Vector2(0.60, 0.54), "Fronteira de Masmoreum", Color("b07ad0"), true],
	"masmorra": ["Masmorra de Masmoreum", Vector2(0.66, 0.74), "Masmoreum", Color("8a5ab0"), true],
	"academia": ["Academia de Fontelúcida", Vector2(0.30, 0.30), "Filus, reino do estudo", Color("7ac0e0")],
	"porto": ["Porto Névoa", Vector2(0.20, 0.72), "A Costa", Color("4a8ee0")],
	"pedralta": ["Pedralta", Vector2(0.72, 0.22), "Rocuetos, reino militar", Color("c8c8d8")],
	"vila_neve": ["Vila da Neve", Vector2(0.86, 0.12), "Gelo", Color("eaf4ff")],
	"oasis": ["Oásis de Areia Doce", Vector2(0.86, 0.80), "Deserto", Color("e0b860")],
}
## estradas: [de, para, perigo 1..5]
const ROADS := [["casa", "floresta", 1], ["floresta", "focus", 1], ["focus", "masmorra", 4], ["focus", "academia", 2],
	["focus", "porto", 2], ["focus", "pedralta", 3], ["pedralta", "vila_neve", 4], ["focus", "oasis", 3], ["academia", "porto", 2]]

var _canvas: Control


class Canvas extends Control:
	var here: String = ""
	var goal: String = ""
	var open: Dictionary = {}

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("1c2a24"))
		var f := Pix.font(1)
		var t := Time.get_ticks_msec() / 1000.0
		# manchas dos reinos
		for id in WorldMapWindow.PLACES:
			var p: Array = WorldMapWindow.PLACES[id]
			draw_circle((p[1] as Vector2) * size, 46.0, Color(p[3] as Color, 0.12))
		# estradas com perigo (pontinhos vermelhos = monstros no caminho)
		for r in WorldMapWindow.ROADS:
			var a: Vector2 = (WorldMapWindow.PLACES[r[0]][1] as Vector2) * size
			var b: Vector2 = (WorldMapWindow.PLACES[r[1]][1] as Vector2) * size
			var ok: bool = bool(open.get(r[0], false)) and bool(open.get(r[1], false))
			var col := Color("d8b878") if ok else Color(0.4, 0.4, 0.4, 0.6)
			var n := int(a.distance_to(b) / 7.0)
			for i in n:
				if i % 2 == 0:
					draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 2.0)
			for d in int(r[2]):
				var m := a.lerp(b, 0.35 + 0.08 * d)
				draw_circle(m + Vector2(0, -5), 2.0, Color(0.9, 0.25, 0.2, 0.85 if ok else 0.3))
		# lugares
		for id in WorldMapWindow.PLACES:
			var p2: Array = WorldMapWindow.PLACES[id]
			var c: Vector2 = (p2[1] as Vector2) * size
			var ok2: bool = bool(open.get(id, false))
			if id == goal:
				draw_circle(c, 11.0 + sin(t * 5.0) * 2.0, Color(UI.C_GOLD, 0.35))
			draw_circle(c, 7.0, (p2[3] as Color) if ok2 else Color(0.35, 0.35, 0.38))
			draw_arc(c, 7.0, 0, TAU, 20, UI.C_LINE, 1.5)
			if id == here:
				draw_circle(c, 3.0 + sin(t * 8.0), Color(1, 1, 1))
			var name: String = p2[0] + ("" if ok2 else " (trancado)")
			var w := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var below: bool = p2.size() > 4 and bool(p2[4])
			var tp := c + Vector2(-w / 2.0, 20 if below else -12)
			tp.x = clampf(tp.x, 2.0, size.x - w - 2.0)
			draw_string_outline(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0.06, 0.05, 0.04))
			draw_string(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UI.C_GOLD if id == goal else (Color("fff1c9") if ok2 else UI.C_DIM))
		draw_rect(Rect2(Vector2.ZERO, size), UI.C_ORANGE, false, 1.0)


func _init() -> void:
	win_title = "Vicerus  -  mapa-múndi"
	win_size = Vector2(620, 346)


func refresh() -> void:
	pass


## Onde o herói está agora (id do mapa-múndi).
static func here_id() -> String:
	var scene := Game.get_tree().current_scene
	if scene == null:
		return "focus"
	if scene.is_in_group("city"):
		return Game.city_id
	if scene.is_in_group("forest"):
		return "floresta"
	if scene.is_in_group("dungeon"):
		return "masmorra"
	if scene.is_in_group("interior"):
		return "casa" if Game.interior_id == "casa_familia" else ("floresta" if Game.interior_return == "forest" else ("academia" if Game.interior_return == "city" and Game.city_id == "academia" else "focus"))
	return "focus"


## Lugar do próximo objetivo da história ("" = nenhum).
static func goal_id() -> String:
	var s := Story.step()
	if s in ["a_casa", "p_prologo"]:
		return "casa"
	if s.begins_with("a_") and s != "a_viagem":
		return "academia"
	if s == "a_viagem":
		return "focus"
	if s.begins_with("b_"):
		return "pedralta" if not (s == "b_missao" and ArmyStory.objective_target() == "trilha_floresta") else "floresta"
	var t := Story.objective_target()
	if t in ["borda", "clareira", "arvore_marcada", "toca", "ponte", "mata", "pantano", "ruinas", "acampamento"]:
		return "floresta"
	if t == "portao_masmorra":
		return "masmorra"
	if t != "":
		return "focus"
	return ""


## O que já está aberto (e o motivo de quem está trancado).
static func open_places() -> Dictionary:
	var o := {"casa": true, "focus": true}
	o["floresta"] = Story.has_trail_pass()
	o["masmorra"] = Story.chapter() >= 3 or Story.path() == "exercito" and Story.step() == "b_cruzada_final"
	o["academia"] = not Story.step().begins_with("p_") and Story.step() != "a_casa"
	o["pedralta"] = Story.path() == "exercito" or Story.part1_done()
	o["porto"] = Story.part1_done()
	o["oasis"] = Story.part1_done()
	o["vila_neve"] = SideQuests.stage("pe_grande") >= 1 or Story.part1_done()
	return o


static func lock_reason(id: String) -> String:
	match id:
		"floresta":
			return "Precisa do cartão da Guilda ou da insígnia do Exército."
		"masmorra":
			return "A masmorra abre no capítulo 3 (ou na cruzada final do Exército)."
		"academia":
			return "Abre depois da despedida da família."
		"pedralta":
			return "Recrutas do Exército vão de graça; os outros, depois da Parte 1."
		"porto", "oasis":
			return "As rotas de comércio abrem depois da Parte 1."
		"vila_neve":
			return "A Vila da Neve pede ajuda no quadro de missões especiais."
	return ""


func build() -> void:
	_canvas = Canvas.new()
	_canvas.size = Vector2(400, 306)
	_canvas.custom_minimum_size = _canvas.size
	_canvas.here = here_id()
	_canvas.goal = goal_id()
	_canvas.open = open_places()
	add_to_body(_canvas, Vector2(0, 0))
	var side := UI.vbox(2)
	add_to_body(side, Vector2(410, 0))
	side.add_child(UI.label("Você está em", UI.C_DIM))
	side.add_child(UI.label(str(PLACES.get(_canvas.here, ["?"])[0]), UI.C_TEXT))
	side.add_child(UI.label(str(PLACES.get(_canvas.here, ["", Vector2.ZERO, ""])[2]), UI.C_DIM))
	side.add_child(UI.hline())
	if Story.started():
		side.add_child(UI.label("Objetivo", UI.C_GOLD))
		side.add_child(UI.wrap_label(Story.objective_text(), UI.C_TEXT, 190))
		side.add_child(UI.hline())
	side.add_child(UI.label("Trancados", UI.C_ORANGE_L))
	for id in PLACES:
		if not bool(_canvas.open.get(id, false)):
			side.add_child(UI.wrap_label("%s: %s" % [PLACES[id][0], lock_reason(id)], UI.C_DIM, 190))
	side.add_child(UI.hline())
	side.add_child(UI.wrap_label("Pontos vermelhos nas estradas = monstros no caminho. Viagens de carruagem podem ter emboscada.", UI.C_DIM, 190))
	if get_tree().get_first_node_in_group("town") != null or get_tree().get_first_node_in_group("dungeon") != null:
		add_to_body(UI.button("< Mapa local", func() -> void: HUD.open_window("mapa"), 90), Vector2(410, 286))


func _process(_delta: float) -> void:
	if _canvas != null:
		_canvas.queue_redraw()
