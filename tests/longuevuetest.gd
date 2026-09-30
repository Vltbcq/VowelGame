extends Node
## Test : Longue-vue (+60 % portée, zoom qui change tout seul, molette bloquée).
## Godot --headless --path . res://tests/longuevuetest.tscn

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Run.start(0, 1)
	Run.wave = 3
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	Run.set_weapon_art("epee", 0, img, "", null, "")
	Run.add_weapon("epee", 0, 0, Vector2(8, 0))
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
		if EnemyDB.TYPES[id].get("shoots", false):
			Run.auto_eproj(id)
	var r0: float = Stats.player(Run).range
	Run.set_amulet_art("longue_vue", img, "")
	Run.add_amulet("longue_vue", img, Vector2i(20, 20))
	Run.recompute()
	_check(is_equal_approx(Run.stats.range - r0, 60.0), "+60 %% de portée (%+.0f)" % (Run.stats.range - r0))
	var arena := Arena.new()
	add_child(arena)
	var zooms := {}
	for f in 60 * 20:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
		zooms[snappedf(arena.cam.zoom.x, 0.25)] = true
	_check(zooms.size() >= 4, "le zoom change tout seul (%d niveaux vus en 20 s)" % zooms.size())
	var z := arena.cam.zoom.x
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_WHEEL_UP
	ev.pressed = true
	arena._unhandled_input(ev)
	_check(arena.cam.zoom.x == z, "la molette ne marche plus")
	Run.active = false
	print("LONGUEVUE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
