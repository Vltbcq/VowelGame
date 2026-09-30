extends Node
## Test de la Toile Blanche en 3 phases : paliers, invulnérabilité, bords effacés qui font mal.
## Godot --path . res://tests/toiletest.tscn [-- <dossier de captures>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.settings.zoom = 1.0   # capture : toute la page
	var args := OS.get_cmdline_user_args()
	await get_tree().process_frame
	Run.start(0, 1)
	Run.wave = 15
	Run.boss_plan = {5: "rature", 10: "critique", 15: "toile"}
	Run.set_character(_blob(32, 180), "")
	Run.set_weapon_art("epee", 1, _blob(32, 90), "", null, "")
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3)), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	var b: Enemy = arena.spawn_enemy_now("toile", Vector2(320, 120), false)
	arena.boss = b
	for f in 60:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
	_check(b.toile_phase == 1 and arena.void_target == 0.0, "phase 1 au début")
	b.hp = b.max_hp * 0.6
	arena.player.inv = 999.0
	arena._process(1.0 / 60.0)
	_check(b.toile_phase == 2 and b.boss_inv > 1.0, "66 % : phase 2, intouchable")
	var h := b.hp
	b.hurt(500.0)
	_check(b.hp == h, "intouchable pendant la transition")
	_check(is_equal_approx(arena.void_target, 0.06), "phase 2 : les bords commencent à s'effacer")
	for f in 60 * 4:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
	_check(arena.void_f > 0.05, "bords effacés (%.3f)" % arena.void_f)
	# le vide fait mal
	arena.player.position = Vector2(8, 8)
	arena.player.inv = 0.0
	arena.player.god = false
	arena.player.st = arena.player.st.duplicate()
	arena.player.st.dodge = 0.0
	arena.player.hp = 999.0
	arena.player.max_hp = 999.0
	for f in 40:
		arena._process(1.0 / 60.0)
		arena.player.position = Vector2(8, 8)
		arena.player.inv = 0.0
	_check(arena.player.hp < 999.0, "le vide fait mal (PV 999 → %.0f)" % arena.player.hp)
	arena.player.position = Vector2(320, 250)
	b.hp = b.max_hp * 0.3
	arena.player.inv = 999.0
	arena._process(1.0 / 60.0)
	_check(b.toile_phase == 3 and is_equal_approx(arena.void_target, 0.113), "33 % : phase 3, la page rétrécit encore")
	for f in 60 * 6:
		arena.player.inv = 999.0
		arena.player.hp = 999.0
		b.hp = maxf(b.hp, b.max_hp * 0.25)
		arena._process(1.0 / 60.0)
		if f == 60 * 5 and args.size() > 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(args[0] + "/toile_phase3.png")
		elif f % 60 == 0:
			await get_tree().process_frame
	var area := arena.void_rect().get_area() / (Arena.W * Arena.H)
	_check(area < 0.65 and area > 0.55, "zone de jeu ≈ 60 %% (%.0f %%)" % (area * 100.0))
	Run.active = false
	print("TOILE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)


func _blob(size: int, px: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, Pal.SHADES[1][1])
	return img
