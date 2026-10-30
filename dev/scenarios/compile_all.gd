extends Node

## Carrega todos os scripts do projeto para revelar erros de sintaxe/tipos.

func run(_dev: Node) -> void:
	var count := 0
	var bad := 0
	for dir in ["res://scripts", "res://dev"]:
		for path in _scripts_in(dir):
			var s: Script = load(path)
			count += 1
			if s == null:
				bad += 1
				printerr("[compile] FALHOU: ", path)
	print("[compile] %d scripts, %d com erro" % [count, bad])


func _scripts_in(dir_path: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		var full := dir_path + "/" + f
		if d.current_is_dir():
			if not f.begins_with("."):
				out.append_array(_scripts_in(full))
		elif f.ends_with(".gd"):
			out.append(full)
		f = d.get_next()
	return out
