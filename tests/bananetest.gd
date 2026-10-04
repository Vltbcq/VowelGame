extends Node
## Test : La Banane (peau toutes les 8 éliminations, lancer, glissade, domino, STRIKE).
## Godot --path . res://tests/bananetest.tscn [-- <capture.png>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	Run.wave = 4
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	Run.set_weapon_art("epee", 0, img, "", null, "")
	Run.add_weapon("epee", 0, 0, Vector2(8, 0))
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
		if EnemyDB.TYPES[id].get("shoots", false):
			Run.auto_eproj(id)
	Run.set_amulet_art("banane", img, "")
	Run.add_amulet("banane", img, Vector2i(20, 20))
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	await get_tree().process_frame
	# 8 éliminations → 1 peau
	arena.banana_kills = 0
	var n0 := arena.peels.size()
	for k in 8:
		arena.kill_enemy(arena.spawn_enemy_now("tache", Vector2(100 + k * 10, 60), false))
	_check(arena.peels.size() == n0 + 1, "8 éliminations → 1 peau de banane (%d)" % (arena.peels.size() - n0))
	# un ennemi marche dessus : il glisse, assommé, et percute un voisin
	var peel := {"pos": arena.player.position + Vector2(-120, 0), "t": 20.0, "a": 0.0}
	arena.peels = [peel]
	arena.banana_throw_t = 999.0
	var a: Enemy = arena.spawn_enemy_now("tache", arena.player.position + Vector2(-120, 0), false)
	var b: Enemy = arena.spawn_enemy_now("colosse", arena.player.position + Vector2(-80, 0), false)
	var hb := b.hp
	for f in 40:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
		if f == 12 and args.size() > 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(args[0])
	_check(not peel in arena.peels, "la peau a servi")
	_check(a.slip_t > 0.0, "l'ennemi est assommé (%.1f s)" % a.slip_t)
	_check(b.hp < hb, "il a percuté un autre ennemi (%.0f → %.0f PV)" % [hb, b.hp])
	# Domino : un ennemi qui glisse fait glisser ceux qu'il percute ; 3 d'un coup = STRIKE
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.mash.clear()
	var row := []
	for k in 4:
		var o: Enemy = arena.spawn_enemy_now("colosse", arena.player.position + Vector2(-60 + k * 14, 60), false)
		o.max_hp = 1e5
		o.hp = 1e5
		row.append(o)
	arena.player.inv = 999.0
	arena._process(1.0 / 60.0)
	row[0].slip(Vector2.RIGHT)
	for f in 40:
		arena.player.inv = 999.0
		for k in row.size():
			if row[k].slide.length() < 5.0 and row[k].slip_t <= 0.0:
				row[k].position.y = arena.player.position.y + 60
		arena._process(1.0 / 60.0)
	var slipped := row.filter(func(o): return o.slip_t > 0.0).size()
	_check(slipped >= 3, "effet domino : %d ennemis ont glissé" % slipped)
	_check(not arena.mash.is_empty(), "STRIKE : flaque de purée qui ralentit")
	# Lancer : toutes les 6 s, une peau devant l'ennemi le plus proche
	arena.peels.clear()
	arena.banana_throw_t = 0.0
	arena._process(1.0 / 60.0)
	_check(arena.peels.size() == 1 and arena.peels[0].has("ft"), "une peau est lancée")
	# les boss ne glissent pas
	var bs: Enemy = arena.spawn_enemy_now("rature", Vector2(500, 300), false)
	bs.slip(Vector2.RIGHT)
	_check(bs.slip_t == 0.0, "les boss ne glissent pas")
	arena.queue_free()
	Run.amulets = []
	Run.active = false
	print("BANANE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
