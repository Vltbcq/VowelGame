extends Node
## Amulettes v0.9 : Polygunnus (projectiles ×2), L'infini (un peu de tout), Stéroïdes (bonus de niveau +50 %).
## Godot --headless --path . res://tests/v09amutest.tscn

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame

	# --- Polygunnus
	_setup()
	var arena := Arena.new()
	add_child(arena)
	var b := {"damage": 5.0, "radius": 4.0, "pierce": 0}
	var p0 := arena.spawn_bullet(Vector2(100, 100), Vector2(200, 0), b, {}, null, "", 1.0)
	_give("polygunnus")
	var p1 := arena.spawn_bullet(Vector2(100, 100), Vector2(200, 0), b, {}, null, "", 1.0)
	_check(p0.radius == 4.0 and p1.radius == 8.0, "Polygunnus : zone de touche ×2 (%.0f → %.0f)" % [p0.radius, p1.radius])
	_check(p1.vel == p0.vel and p1.scale == Vector2(2, 2), "Polygunnus : même vitesse, dessin ×2")
	arena.queue_free()
	await get_tree().process_frame

	# --- L'infini
	_setup()
	var s0: Dictionary = Run.stats.duplicate(true)
	_give("infini")
	var s1: Dictionary = Run.stats
	var all_up := true
	for k in ["max_hp", "regen", "armor", "dodge", "dmg", "atk_speed", "crit", "range", "lifesteal", "luck", "harvest", "thorns"]:
		if float(s1[k]) <= float(s0[k]):
			all_up = false
			print("     %s : %.1f → %.1f" % [k, s0[k], s1[k]])
	_check(all_up, "L'infini : toutes les stats montent")

	# --- Stéroïdes : bonus de niveau +50 %
	_setup()
	Run.bonus["dmg"] = Run.bonus.get("dmg", 0.0) + 10.0
	Run.recompute()
	var d0: float = Run.stats.dmg
	_give("encrier")
	_check(absf(Run.stats.dmg - d0 - 5.0) < 0.01, "Stéroïdes : +10 %% de bonus de niveau → +15 %% (%.1f → %.1f)" % [d0, Run.stats.dmg])

	Run.active = false
	print("V09AMU : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)


func _setup() -> void:
	Run.start(0, 1)
	Run.wave = 3
	Run.set_character(_blob(32, 180), "")
	Run.set_weapon_art("epee", 1, _blob(32, 90), "", null, "")
	Run.recompute()


func _give(id: String) -> void:
	Run.set_amulet_art(id, _blob(16, 20), "")
	Run.add_amulet(id, Run.amulet_art[id].image, Vector2i(30, 30))
	Run.recompute()


func _blob(size: int, px: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, Pal.SHADES[1][1])
	return img
