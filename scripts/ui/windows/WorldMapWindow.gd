class_name WorldMapWindow
extends UIWindow

## v3.7: mapa-múndi de Vicerus (história v4, seção 2). Reinos, lugares e estradas, onde você está, o próximo
## objetivo e o que ainda está trancado (e por quê). As estradas mostram o perigo do caminho: viagens de
## carruagem podem ter emboscada (Game.travel_road). Abre pelo mapa grande (M) ou pela carruagem do Tobias.
## Pergaminho montado com formas da interface e ícones dos packs (Ninja Adventure e Kenney Tiny Town); dá para trocar
## por um pack de mapa (Kenney Fantasy UI Borders, já na lista) sem mexer na lógica.

## id -> [nome, posição no mapa (0..1), reino, cor do reino, rótulo embaixo (true) ou em cima]
const PLACES := {
	"casa": ["Casa da família", Vector2(0.34, 0.56), "Floresta entre os reinos", Color("5aa05a"), true],
	"floresta": ["Floresta", Vector2(0.46, 0.46), "Floresta entre os reinos", Color("5aa05a"), false],
	"focus": ["Focus Town", Vector2(0.60, 0.54), "Fronteira de Masmoreum", Color("b07ad0"), true],
	"masmorra": ["Masmorra", Vector2(0.64, 0.76), "Masmoreum", Color("8a5ab0"), true],
	"academia": ["Academia", Vector2(0.30, 0.30), "Filus, reino do estudo", Color("7ac0e0"), true],
	"porto": ["Porto Névoa", Vector2(0.20, 0.72), "A Costa", Color("4a8ee0")],
	"pedralta": ["Pedralta", Vector2(0.72, 0.22), "Rocuetos, reino militar", Color("c8c8d8")],
	"vila_neve": ["Vila da Neve", Vector2(0.86, 0.12), "Gelo", Color("eaf4ff")],
	"oasis": ["Oásis", Vector2(0.86, 0.80), "Deserto", Color("e0b860"), true],
}
## estradas: [de, para, perigo 1..5]
const ROADS := [["casa", "floresta", 1], ["floresta", "focus", 1], ["focus", "masmorra", 4], ["focus", "academia", 2],
	["focus", "porto", 2], ["focus", "pedralta", 3], ["pedralta", "vila_neve", 4], ["focus", "oasis", 3], ["academia", "porto", 2]]

var _canvas: Control


## Litoral do continente de Vicerus (pontos de 0 a 1, sentido horário).
const COAST := [Vector2(0.18, 0.08), Vector2(0.30, 0.05), Vector2(0.42, 0.09), Vector2(0.55, 0.06), Vector2(0.68, 0.04),
	Vector2(0.80, 0.06), Vector2(0.92, 0.10), Vector2(0.95, 0.22), Vector2(0.90, 0.32), Vector2(0.94, 0.42), Vector2(0.91, 0.55),
	Vector2(0.95, 0.66), Vector2(0.93, 0.80), Vector2(0.95, 0.90), Vector2(0.84, 0.94), Vector2(0.70, 0.90), Vector2(0.58, 0.94),
	Vector2(0.46, 0.88), Vector2(0.36, 0.93), Vector2(0.27, 0.87), Vector2(0.21, 0.81), Vector2(0.12, 0.77), Vector2(0.15, 0.66),
	Vector2(0.09, 0.58), Vector2(0.13, 0.48), Vector2(0.08, 0.38), Vector2(0.12, 0.28), Vector2(0.07, 0.18)]
const RIVERS := [
	[Vector2(0.62, 0.11), Vector2(0.55, 0.20), Vector2(0.44, 0.25), Vector2(0.40, 0.36), Vector2(0.47, 0.44), Vector2(0.44, 0.58),
		Vector2(0.33, 0.68), Vector2(0.24, 0.75), Vector2(0.13, 0.77)],
	[Vector2(0.82, 0.20), Vector2(0.79, 0.34), Vector2(0.84, 0.48), Vector2(0.88, 0.58), Vector2(0.94, 0.62)],
]
const LAKES := [[Vector2(0.37, 0.22), Vector2(0.045, 0.03)], [Vector2(0.79, 0.86), Vector2(0.03, 0.022)]]
## regiões: [centro, raio (0..1), cor, nome do reino, onde escrever o nome (0..1)]
const REGIONS := [
	[Vector2(0.30, 0.26), 0.14, Color(0.55, 0.75, 0.9), "FILUS", Vector2(0.16, 0.36)], [Vector2(0.44, 0.52), 0.13, Color(0.45, 0.65, 0.35), "FLORESTA", Vector2(0.40, 0.66)],
	[Vector2(0.70, 0.72), 0.12, Color(0.55, 0.4, 0.65), "MASMOREUM", Vector2(0.70, 0.88)], [Vector2(0.74, 0.20), 0.14, Color(0.7, 0.72, 0.78), "ROCUETOS", Vector2(0.62, 0.36)],
	[Vector2(0.88, 0.12), 0.09, Color(0.95, 0.97, 1.0), "GELO", Vector2(0.88, 0.26)], [Vector2(0.84, 0.82), 0.12, Color(0.92, 0.78, 0.45), "DESERTO", Vector2(0.86, 0.68)],
	[Vector2(0.20, 0.70), 0.10, Color(0.5, 0.7, 0.9), "A COSTA", Vector2(0.24, 0.84)],
]
## ícones (arte dos packs): [prop, posição, escala]
const ICONS := {
	"casa": ["b_casa_creme", 0.32], "focus": ["b_casa_laranja", 0.36], "masmorra": ["h_torii", 0.3], "academia": ["b_salao_vermelho", 0.36],
	"porto": ["b_estalagem", 0.34], "pedralta": ["k_pedra_cinza_5", 0.38], "vila_neve": ["k_pedra_cinza_5", 0.3], "oasis": ["b_casa_empena", 0.32],
	"floresta": ["n_pinheiros_trio", 0.32],
}
const PEAKS := [[Vector2(0.60, 0.13), "n_pedra_cinza_alta"], [Vector2(0.65, 0.10), "n_pedra_cinza_alta"], [Vector2(0.70, 0.13), "n_pedra_cinza_alta"],
	[Vector2(0.78, 0.07), "n_pedra_cinza_alta"], [Vector2(0.92, 0.20), "n_pedra_cinza_alta"], [Vector2(0.66, 0.30), "n_pedra_cinza_alta"],
	[Vector2(0.75, 0.88), "n_pedra_marrom_alta"], [Vector2(0.92, 0.74), "n_pedra_marrom_alta"], [Vector2(0.56, 0.84), "n_pedra_marrom_alta"],
	[Vector2(0.18, 0.18), "n_pedra_cinza_alta"]]


## Mapa em pergaminho (referência do Victor): mar com ondas, litoral, regiões, rios, lagos, cordilheiras e florestas
## com as rochas e árvores do Ninja Adventure, cidades com prédios do Ninja/Kenney, estradas tracejadas e rosa dos ventos.
class Canvas extends Control:
	var here: String = ""
	var goal: String = ""
	var open: Dictionary = {}
	var _trees: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		var poly := PackedVector2Array(WorldMapWindow.COAST)
		for r in WorldMapWindow.REGIONS:
			if str(r[3]) in ["FLORESTA", "FILUS", "MASMOREUM"]:
				for i in (12 if str(r[3]) == "FLORESTA" else 7):
					var a := rng.randf() * TAU
					var d := sqrt(rng.randf()) * float(r[1]) * 0.85
					var p: Vector2 = (r[0] as Vector2) + Vector2(cos(a), sin(a) * 0.75) * d
					var near_place := false
					for pid in WorldMapWindow.PLACES:
						if p.distance_to(WorldMapWindow.PLACES[pid][1]) < 0.06:
							near_place = true
					if Geometry2D.is_point_in_polygon(p, poly) and not near_place:
						_trees.append([p, "n_arvore_pinheiro" if rng.randf() < 0.6 else ("n_arvore_seca" if str(r[3]) == "MASMOREUM" else "n_arvore_redonda")])
		_trees.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).y < (b[0] as Vector2).y)

	func _pt(v: Vector2) -> Vector2:
		var m := Vector2(10, 10)
		return m + v * (size - m * 2.0)

	func _icon(prop: String, at: Vector2, k: float, mod: Color = Color.WHITE) -> void:
		var tex := Interior.prop_tex(prop)
		if tex == null:
			return
		var sz := tex.get_size() * k
		draw_texture_rect(tex, Rect2(at - Vector2(sz.x / 2.0, sz.y - 2.0), sz), false, mod)

	func _draw() -> void:
		var f := Pix.font(1)
		var t := Time.get_ticks_msec() / 1000.0
		# pergaminho e mar
		draw_rect(Rect2(Vector2.ZERO, size), Color("d8c49a"))
		draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color("4f8a88"))
		for y in range(12, int(size.y) - 8, 14):
			for x in range(12 + (y / 14 % 2) * 9, int(size.x) - 12, 22):
				var w0 := Vector2(x, y)
				draw_arc(w0, 3.0, PI * 1.1, PI * 1.9, 5, Color(0.2, 0.35, 0.38, 0.5), 1.0)
				draw_arc(w0 + Vector2(5, 0), 3.0, PI * 1.1, PI * 1.9, 5, Color(0.2, 0.35, 0.38, 0.5), 1.0)
		# continente
		var land := PackedVector2Array()
		for v in WorldMapWindow.COAST:
			land.append(_pt(v))
		var shadow := PackedVector2Array()
		for v in land:
			shadow.append(v + Vector2(2, 3))
		draw_colored_polygon(shadow, Color(0.12, 0.2, 0.22, 0.5))
		draw_colored_polygon(land, Color("e2cf9c"))
		for r in WorldMapWindow.REGIONS:
			var c: Vector2 = _pt(r[0])
			var rad: float = float(r[1]) * size.x
			for k in 3:
				draw_circle(c, rad * (1.0 - k * 0.25), Color(r[2] as Color, 0.16))
		var closed := land.duplicate()
		closed.append(land[0])
		draw_polyline(closed, Color("5a3a1e"), 2.0)
		# rios e lagos
		for river in WorldMapWindow.RIVERS:
			var pl := PackedVector2Array()
			for v in river:
				pl.append(_pt(v))
			draw_polyline(pl, Color("4f8a98"), 2.0)
		for l in WorldMapWindow.LAKES:
			var c2: Vector2 = _pt(l[0])
			var rr: Vector2 = (l[1] as Vector2) * size
			var pts := PackedVector2Array()
			for i in 20:
				var a2 := TAU * i / 20.0
				pts.append(c2 + Vector2(cos(a2) * rr.x, sin(a2) * rr.y) * (1.0 + 0.12 * sin(a2 * 3.0)))
			draw_colored_polygon(pts, Color("4f8a98"))
			var pc := pts.duplicate()
			pc.append(pts[0])
			draw_polyline(pc, Color("2e5a60"), 1.0)
		# montanhas e florestas (Ninja Adventure)
		for pk in WorldMapWindow.PEAKS:
			_icon(str(pk[1]), _pt(pk[0]), 0.42)
		for tr in _trees:
			_icon(str(tr[1]), _pt(tr[0]), 0.36)
		# estradas tracejadas e perigo do caminho
		for r in WorldMapWindow.ROADS:
			var a: Vector2 = _pt(WorldMapWindow.PLACES[r[0]][1])
			var b: Vector2 = _pt(WorldMapWindow.PLACES[r[1]][1])
			var ok: bool = bool(open.get(r[0], false)) and bool(open.get(r[1], false))
			var col := Color("7a4a22") if ok else Color(0.45, 0.4, 0.35, 0.55)
			var n := int(a.distance_to(b) / 6.0)
			for i in n:
				if i % 2 == 0:
					draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 1.5)
			for dd in int(r[2]):
				draw_circle(a.lerp(b, 0.38 + 0.07 * dd) + Vector2(0, -4), 1.6, Color(0.75, 0.15, 0.12, 0.9 if ok else 0.3))
		# nomes dos reinos
		for rg in WorldMapWindow.REGIONS:
			var nm: String = rg[3]
			var wn := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(f, _pt(rg[4]) + Vector2(-wn / 2.0, 0), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 0.22, 0.12, 0.5))
		# lugares
		for id in WorldMapWindow.PLACES:
			var p2: Array = WorldMapWindow.PLACES[id]
			var c3: Vector2 = _pt(p2[1])
			var ok2: bool = bool(open.get(id, false))
			if id == goal:
				draw_circle(c3 + Vector2(0, -4), 12.0 + sin(t * 5.0) * 2.0, Color(UI.C_GOLD, 0.35))
			var ic: Array = WorldMapWindow.ICONS.get(id, ["", 0.3])
			if str(ic[0]) != "":
				_icon(str(ic[0]), c3 + Vector2(0, 4), float(ic[1]), Color.WHITE if ok2 else Color(0.55, 0.55, 0.55, 0.8))
			if id == here:
				draw_circle(c3 + Vector2(0, 6), 3.0 + sin(t * 8.0), Color(1, 1, 1))
				draw_arc(c3 + Vector2(0, 6), 5.0, 0, TAU, 16, Color("5a3a1e"), 1.0)
			var name: String = p2[0]
			var w := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var below: bool = p2.size() > 4 and bool(p2[4])
			var tp := c3 + Vector2(-w / 2.0, 18 if below else -14)
			tp.x = clampf(tp.x, 8.0, size.x - w - 8.0)
			draw_string_outline(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color("f1e2bb"))
			draw_string(f, tp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b8860b") if id == goal else (Color("3a2414") if ok2 else Color(0.45, 0.4, 0.35)))
		# rosa dos ventos
		var cr := Vector2(48, size.y - 40)
		for i in 8:
			var a3 := TAU * i / 8.0 - PI / 2.0
			var len := 18.0 if i % 2 == 0 else 10.0
			var tip := cr + Vector2(cos(a3), sin(a3)) * len
			var side := Vector2(cos(a3 + PI / 2.0), sin(a3 + PI / 2.0)) * 3.0
			draw_colored_polygon(PackedVector2Array([tip, cr + side, cr - side]), Color("5a3a1e") if i % 2 == 0 else Color("a07848"))
		draw_arc(cr, 8.0, 0, TAU, 20, Color("5a3a1e"), 1.0)
		for pair in [["N", Vector2(-3, -21)], ["S", Vector2(-3, 30)], ["L", Vector2(21, 4)], ["O", Vector2(-30, 4)]]:
			draw_string(f, cr + (pair[1] as Vector2), str(pair[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("3a2414"))
		draw_string(f, Vector2(14, 22), "VICERUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f1e2bb"))
		draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color("5a3a1e"), false, 2.0)


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
	var locked: Array = []
	for id in PLACES:
		if not bool(_canvas.open.get(id, false)):
			locked.append(id)
	if not locked.is_empty():
		side.add_child(UI.label("Trancados (em cinza)", UI.C_ORANGE_L))
		for i in mini(2, locked.size()):
			side.add_child(UI.wrap_label("%s: %s" % [PLACES[locked[i]][0], lock_reason(locked[i])], UI.C_DIM, 190))
		if locked.size() > 2:
			var rest: Array = []
			for i in range(2, locked.size()):
				rest.append(str(PLACES[locked[i]][0]))
			side.add_child(UI.wrap_label("Também: " + ", ".join(rest) + ".", UI.C_DIM, 190))
	side.add_child(UI.wrap_label("Pontinhos vermelhos nas estradas: monstros no caminho.", UI.C_DIM, 190))
	if get_tree().get_first_node_in_group("town") != null or get_tree().get_first_node_in_group("dungeon") != null:
		add_to_body(UI.button("< Mapa local", func() -> void: HUD.open_window("mapa"), 90), Vector2(410, 286))


func _process(_delta: float) -> void:
	if _canvas != null:
		_canvas.queue_redraw()
