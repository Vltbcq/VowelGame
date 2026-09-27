extends Node
## Vérifie que TOUS les scripts du projet se compilent (avec les autoloads chargés).
## Godot --headless --path . res://tests/checkall.tscn


func _ready() -> void:
	var bad := 0
	var n := 0
	for path in _scripts("res://scripts"):
		n += 1
		var s = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if s == null or not (s as Script).can_instantiate():
			bad += 1
			print("ÉCHEC : ", path)
	print("CHECKALL : %d scripts, %d en erreur" % [n, bad])
	get_tree().quit(1 if bad > 0 else 0)


func _scripts(dir: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out += _scripts(dir + "/" + d)
	return out
