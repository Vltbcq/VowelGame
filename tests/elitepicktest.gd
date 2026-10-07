extends Node
## Test : une élite qui a déjà un dessin dans le Codex propose d'abord le choix (comme les armes),
## sinon on passe directement au dessin. N'écrit rien dans la vraie sauvegarde.
## Godot --headless --path . res://tests/elitepicktest.tscn

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


## Lance la préparation de la vague 4 et renvoie le premier écran affiché.
func _first_screen(main: Node) -> String:
	var done_flag := [false]
	var run := func():
		await main._pre_wave(4)
		done_flag[0] = true
	run.call()
	var first := ""
	for i in 20:
		await get_tree().process_frame
		var cur: Node = main.current
		if done_flag[0]:
			break
		if cur is BestiaryPrompt:
			if first == "":
				first = "choix"
			cur.done.emit({"a": "keep", "image": cur.existing.image, "effect": "", "outline": false} if cur.get("existing") else {"a": "cancel"})
		elif cur is DrawScreen:
			if first == "":
				first = "dessin"
			cur.done.emit({"image": cur.img, "effect": "", "outline": false})
	return first


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.data = Meta.data.duplicate(true)
	var main: Node = load("res://scripts/main.gd").new()
	add_child(main)
	await get_tree().process_frame
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 16, 16), Pal.SHADES[1][1])
	# Sans dessin d'élite dans le Codex : directement le dessin
	Run.start(1, 1)
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	var b: Dictionary = Meta.data.get("bestiary", {})
	for id in EnemyDB.TYPES:
		b.erase(id + "_elite")
	Meta.data.bestiary = b
	var f1 := await _first_screen(main)
	_check(f1 == "dessin", "pas de dessin d'élite dans le Codex : on dessine directement (%s)" % f1)
	# Avec un dessin d'élite dans le Codex : d'abord le choix
	Run.start(1, 1)
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	var path := "user://__test_elite.png"
	img.save_png(path)
	b = Meta.data.get("bestiary", {})
	for id in EnemyDB.TYPES:
		b[id + "_elite"] = {"file": path, "effect": "", "outline": false}
	Meta.data.bestiary = b
	var f2 := await _first_screen(main)
	_check(f2 == "choix", "dessin d'élite dans le Codex : d'abord le choix, comme les armes (%s)" % f2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Run.active = false
	print("ELITE CODEX : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
