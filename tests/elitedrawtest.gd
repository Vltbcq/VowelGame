extends "res://scripts/main.gd"
## Test : sans dessin d'élite dans le Codex, une élite se dessine DIRECTEMENT par-dessus le dessin de l'ennemi.

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:   # (pas le menu du vrai jeu)
	Meta.no_save = true
	# Copie de la sauvegarde sans dessins d'élite (sinon on aurait d'abord l'écran de choix, voir elitepicktest)
	Meta.data = Meta.data.duplicate(true)
	var bst: Dictionary = Meta.data.get("bestiary", {})
	for id in EnemyDB.TYPES:
		bst.erase(id + "_elite")
	Meta.data.bestiary = bst
	Run.start(1, 1)
	Run.wave = 4
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	_pre_wave(4)
	await get_tree().process_frame
	_check(current is DrawScreen, "l'élite ouvre directement l'écran de dessin (%s)" % current.get_class())
	var cfg: Dictionary = current.cfg if current is DrawScreen else {}
	_check(String(cfg.get("title", "")).begins_with("ÉLITE") and cfg.get("base") != null, "avec le dessin de l'ennemi déjà posé")
	var done_img := img.duplicate()
	done_img.fill_rect(Rect2i(2, 2, 4, 4), Pal.SHADES[3][1])
	current.done.emit({"image": done_img, "effect": "", "outline": false})
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not Run.elite_art.is_empty(), "le dessin d'élite est enregistré pour la partie")
	Run.active = false
	print("ELITE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
