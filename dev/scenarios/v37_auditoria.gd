extends Node

## v3.7 (pedido do Victor): auditoria de entradas e pontos de missão.
##  1) toda construção com nome em Focus Town, floresta e cidades tem porta que abre (ou oferta, no caso da casa à venda);
##  2) cada interior novo (moradores, castelo da Academia, sala do trono, cabana) abre sem erro e tem saída;
##  3) cada alvo de objetivo da história existe como ponto em algum mapa, e se for prédio, a porta abre.
var fails := 0
var dev: Node
var landmarks := {}      # id -> [cena, porta_ok]


func check(cond: bool, what: String) -> void:
	if cond:
		print("[aud] ok    ", what)
	else:
		fails += 1
		printerr("[aud] FALHA ", what)


func _collect(scene_name: String) -> void:
	var sc := get_tree().current_scene
	var bmap: Dictionary = sc.get("buildings") if sc.get("buildings") != null else {}
	for l in sc.map_landmarks():
		var id := str(l[0])
		var door_ok := true
		if bmap.has(id) and bmap[id] is Building:
			var b: Building = bmap[id]
			door_ok = b.door.enabled or id == "casa" or id == "castelo"
		landmarks[id] = [scene_name, door_ok]


func _check_buildings(scene_name: String) -> Array:
	var sc := get_tree().current_scene
	var interiors: Array = []
	var bmap: Dictionary = sc.get("buildings") if sc.get("buildings") != null else {}
	for id in bmap:
		var b = bmap[id]
		if not (b is Building):
			continue
		var bb: Building = b
		var opens := bb.door.enabled
		if not opens:
			# portas com oferta/entrada própria (casa à venda, portão do castelo da Academia)
			for n in sc.world.get_children():
				if n is Interior.Spot and n.global_position.distance_to(bb.global_position) < 40.0:
					opens = true
		check(opens, "%s: \"%s\" tem entrada" % [scene_name, bb.display_name])
		if bb.interior_id != "":
			interiors.append(bb.interior_id)
	return interiors


func _enter_all(ids: Array, from: String) -> void:
	for iid in ids:
		Game.enter_interior(str(iid), from)
		await dev.wait(1.6)
		var sc := get_tree().current_scene
		var has_exit := false
		for n in sc.world.get_children():
			if n is Interior.Spot and n.text == "Sair":
				has_exit = true
		check(sc.is_in_group("interior") and has_exit, "interior %s abre e tem saída" % iid)
		HUD.close_window()


func run(d: Node) -> void:
	dev = d
	GameState.debug_reset()
	Story.dev_start()
	GameState.choose_class("guerreiro")
	for k in Looks.SPEAKER_LOOK:
		Story.set_flag("intro_" + str(k))
	Game.go_to_town("start")
	await dev.wait(2.5)
	_collect("Focus Town")
	_check_buildings("Focus Town")
	Game.go_to_forest("town")
	await dev.wait(3.0)
	_collect("Floresta")
	var fi := _check_buildings("Floresta")
	await _enter_all(fi.filter(func(x): return x == "cabana_pietro"), "forest")
	for cid in CityData.CITIES:
		if cid == "estrada":
			continue
		Game.go_to_city(cid)
		await dev.wait(3.0)
		_collect(str(cid))
		var ints := _check_buildings(str(cid))
		var new_ints := ints.filter(func(x): return str(x).begins_with("morador_") or str(x) == "castelo_rocuetos")
		await _enter_all(new_ints, "city")
	Game.go_to_castle("start")
	await dev.wait(2.5)
	_collect("Castelo")
	var cas := get_tree().current_scene
	var acad: Array = []
	for dd in cas.DOORS:
		acad.append(str(dd[0]))
	await _enter_all(acad, "castle")
	# alvos da história
	var targets := {}
	for s in StoryData.OBJECTIVE_TARGET:
		targets[str(StoryData.OBJECTIVE_TARGET[s])] = s
	for s2 in StoryV4.TARGETS:
		targets[str(StoryV4.TARGETS[s2])] = s2
	for t in targets:
		var info: Variant = landmarks.get(t, null)
		check(info != null, "alvo '%s' (passo %s) existe num mapa%s" % [t, targets[t], "" if info == null else " (%s)" % info[0]])
		if info != null:
			check(bool(info[1]), "alvo '%s': a porta abre" % t)
	print("[aud] falhas: ", fails)
