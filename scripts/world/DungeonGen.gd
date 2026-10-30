class_name DungeonGen
extends RefCounted

## Gerador de andares: salas retangulares ligadas por corredores largos (2 tiles).
## Andares de chefe têm uma sala inicial pequena e uma arena grande com pilares.

const WALL := 0
const FLOOR := 1


static func generate(floor_n: int, rng: RandomNumberGenerator, boss_floor: bool) -> Dictionary:
	if boss_floor:
		return _generate_boss(floor_n, rng)
	var w := 60
	var h := 42
	var cells := PackedByteArray()
	cells.resize(w * h)
	cells.fill(WALL)
	var room_of := PackedInt32Array()
	room_of.resize(w * h)
	room_of.fill(0)
	var rooms: Array[Rect2i] = []
	var target := mini(9 + floor_n / 5, 12)
	var attempts := 0
	while rooms.size() < target and attempts < 400:
		attempts += 1
		var rw := rng.randi_range(7, 13)
		var rh := rng.randi_range(6, 10)
		var rx := rng.randi_range(2, w - rw - 3)
		var ry := rng.randi_range(2, h - rh - 3)
		var r := Rect2i(rx, ry, rw, rh)
		var ok := true
		for o in rooms:
			if r.grow(3).intersects(o):
				ok = false
				break
		if ok:
			rooms.append(r)
	# carve
	for i in rooms.size():
		_carve_rect(cells, w, rooms[i])
		_mark_rect(room_of, w, rooms[i], i + 1)
	# MST (Prim) + ligações extras
	var edges: Array = []
	var connected := [0]
	var remaining: Array = range(1, rooms.size())
	while not remaining.is_empty():
		var best_d := INF
		var best_a := -1
		var best_b := -1
		for a in connected:
			for b in remaining:
				var d := _center(rooms[a]).distance_to(_center(rooms[b]))
				if d < best_d:
					best_d = d
					best_a = a
					best_b = b
		edges.append([best_a, best_b])
		connected.append(best_b)
		remaining.erase(best_b)
	for k in 2:
		var a := rng.randi() % rooms.size()
		var b := rng.randi() % rooms.size()
		if a != b and not _has_edge(edges, a, b):
			edges.append([a, b])
	for e in edges:
		_carve_corridor(cells, w, h, _center(rooms[e[0]]), _center(rooms[e[1]]), rng)
	# sala inicial = primeira; escada = a mais distante no grafo
	var dist := _graph_distances(rooms.size(), edges, 0)
	var stairs_room := 0
	for i in rooms.size():
		if dist[i] > dist[stairs_room]:
			stairs_room = i
	var treasure_room := -1
	var shrine_room := -1
	var candidates: Array = []
	for i in rooms.size():
		if i != 0 and i != stairs_room:
			candidates.append(i)
	candidates.shuffle()
	if candidates.size() > 0:
		treasure_room = candidates[0]
	if candidates.size() > 1 and floor_n >= 2 and rng.randf() < 0.6:
		shrine_room = candidates[1]
	return {
		"w": w, "h": h, "cells": cells, "room_of": room_of, "rooms": rooms,
		"start_room": 0, "stairs_room": stairs_room, "treasure_room": treasure_room, "shrine_room": shrine_room,
		"boss_room": -1, "pillars": [],
	}


static func _generate_boss(floor_n: int, rng: RandomNumberGenerator) -> Dictionary:
	var w := 52
	var h := 34
	var cells := PackedByteArray()
	cells.resize(w * h)
	cells.fill(WALL)
	var room_of := PackedInt32Array()
	room_of.resize(w * h)
	room_of.fill(0)
	var start := Rect2i(4, 13, 9, 8)
	var arena := Rect2i(20, 6, 28, 22)
	var rooms: Array[Rect2i] = [start, arena]
	_carve_rect(cells, w, start)
	_carve_rect(cells, w, arena)
	_mark_rect(room_of, w, start, 1)
	_mark_rect(room_of, w, arena, 2)
	# corredor curto
	for x in range(start.end.x - 1, arena.position.x + 1):
		for y in range(16, 18):
			cells[y * w + x] = FLOOR
	# pilares na arena (blocos 2x2 de parede)
	var pillars: Array = []
	for p in [Vector2i(26, 11), Vector2i(41, 11), Vector2i(26, 21), Vector2i(41, 21)]:
		for dx in 2:
			for dy in 2:
				cells[(p.y + dy) * w + p.x + dx] = WALL
		pillars.append(p)
	return {
		"w": w, "h": h, "cells": cells, "room_of": room_of, "rooms": rooms,
		"start_room": 0, "stairs_room": 1, "treasure_room": -1, "shrine_room": -1,
		"boss_room": 1, "pillars": pillars,
	}


static func _center(r: Rect2i) -> Vector2i:
	return Vector2i(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)


static func _carve_rect(cells: PackedByteArray, w: int, r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			cells[y * w + x] = FLOOR


static func _mark_rect(arr: PackedInt32Array, w: int, r: Rect2i, id: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			arr[y * w + x] = id


static func _carve_corridor(cells: PackedByteArray, w: int, h: int, a: Vector2i, b: Vector2i, rng: RandomNumberGenerator) -> void:
	var horizontal_first := rng.randf() < 0.5
	var corner := Vector2i(b.x, a.y) if horizontal_first else Vector2i(a.x, b.y)
	_carve_line(cells, w, h, a, corner)
	_carve_line(cells, w, h, corner, b)


static func _carve_line(cells: PackedByteArray, w: int, h: int, a: Vector2i, b: Vector2i) -> void:
	var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var p := a
	while true:
		for dx in 2:
			for dy in 2:
				var x := p.x + dx
				var y := p.y + dy
				if x > 0 and y > 0 and x < w - 1 and y < h - 1:
					cells[y * w + x] = FLOOR
		if p == b:
			break
		p += step
		if step == Vector2i.ZERO:
			break


static func _has_edge(edges: Array, a: int, b: int) -> bool:
	for e in edges:
		if (e[0] == a and e[1] == b) or (e[0] == b and e[1] == a):
			return true
	return false


static func _graph_distances(n: int, edges: Array, start: int) -> Array:
	var dist: Array = []
	dist.resize(n)
	dist.fill(-1)
	dist[start] = 0
	var queue := [start]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for e in edges:
			var other := -1
			if e[0] == cur:
				other = e[1]
			elif e[1] == cur:
				other = e[0]
			if other >= 0 and dist[other] < 0:
				dist[other] = dist[cur] + 1
				queue.append(other)
	return dist
