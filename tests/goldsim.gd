extends Node
## Simulation de réglage (pas un test pass/fail) : combien d'or rapporte chaque vague, sans pourboire,
## sans rien dépenser, en ramassant toutes les pièces (aimant géant). Un perso correct pour sa vague,
## au centre, en Esquisse. Affiche l'or de chaque vague et le cumul.
## Godot --headless --path . res://tests/goldsim.tscn [-- <difficulté>]

const DT := 1.0 / 30.0


func _ready() -> void:
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	var diff := int(args[0]) if args.size() > 0 else 0
	seed(4321)
	var total := 0
	print("vague | or de la vague | cumul (sans l'or de départ)")
	for w in range(1, 13):
		var g := await _wave(w, diff)
		total += g
		print("%5d | %5d | %5d" % [w, g, total])
	get_tree().quit()


func _wave(w: int, diff: int) -> int:
	Run.start(diff, 1, 99)
	Run.wave = w
	Run.level = w
	Run.set_character(_blob(32, 220, Pal.SHADES[1][1]), "")
	var rar := 0 if w < 4 else (1 if w < 8 else 2)
	for k in mini(2 + w / 2, 6):
		var t: String = ["epee", "pistolet", "arc", "dague", "lance", "epee"][k]
		var def := WeaponDB.get_def(t)
		if not Run.has_art(t, rar):
			Run.set_weapon_art(t, rar, _blob(int(def.canvas), int(def.ink * 1.3), Pal.SHADES[2][1]), "",
				_blob(int(def.get("bcanvas", 16)), int(def.get("bink", 20) * 1.3), Pal.SHADES[2][1]) if def.kind == "ranged" else null, "")
		Run.add_weapon(t, rar, 10, Vector2(randf_range(-10, 10), randf_range(-10, 10)))
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3), Pal.SHADES[0][1]), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()
	Run.stats.pickup = 5000.0   # (ramasse tout)
	Run.hp = Run.stats.max_hp
	var arena := Arena.new()
	add_child(arena)
	await get_tree().process_frame
	var g0 := Run.run_gold
	var boss := arena.boss_id != ""
	var limit := 150.0 if boss else arena.time_left + 1.0
	var t := 0.0
	while t < limit and not arena.ended:
		arena.player.position = Vector2(Arena.W / 2.0, Arena.H / 2.0)
		arena.player.hp = arena.player.max_hp
		arena._process(DT)
		t += DT
	# les pièces encore au sol en fin de vague sont ramassées aussi
	for pk in arena.pickups.duplicate():
		if is_instance_valid(pk):
			arena.collect(pk)
	var got := Run.run_gold - g0
	arena.ended = true
	arena.queue_free()
	await get_tree().process_frame
	Engine.time_scale = 1.0
	Run.active = false
	return got


func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)
	return img
