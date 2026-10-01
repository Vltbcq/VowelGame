extends Node
## Test : le Raturé annonce son point de réapparition 1 s avant (cible rouge).
## Godot --path . res://tests/raturetest.tscn [-- <capture.png>]

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
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
		if EnemyDB.TYPES[id].get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	await get_tree().process_frame
	var b: Enemy = arena.spawn_enemy_now("rature", arena.player.position + Vector2(150, 0), false)
	b.cd = 0.0
	b.cd2 = 99.0
	arena.player.inv = 999.0
	arena._process(1.0 / 60.0)
	var marks: Array = arena.telegraphs_fx.filter(func(g): return g.get("boss", false))
	_check(b.state == "fade" and marks.size() == 1, "le Raturé disparaît et sa cible d'arrivée est affichée")
	var start := b.position
	var dest := b.tp_pos
	for f in 30:
		arena.player.inv = 999.0
		b.cd2 = 99.0
		arena._process(1.0 / 60.0)
	if args.size() > 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0])
	_check(b.position.distance_to(dest) > 20.0, "après 0,5 s il n'est pas encore arrivé")
	var n := 30
	while b.state == "fade" and n < 120:
		arena.player.inv = 999.0
		b.cd2 = 99.0
		arena._process(1.0 / 60.0)
		n += 1
	_check(b.position.distance_to(dest) < 4.0 and n / 60.0 > 0.8 and n / 60.0 < 1.05, "il apparaît sur la cible au bout de %.2f s" % (n / 60.0))
	arena._process(1.0 / 60.0)
	_check(arena.telegraphs_fx.filter(func(g): return g.get("boss", false)).is_empty(), "la cible disparaît à son arrivée")
	arena.queue_free()
	Run.active = false
	print("RATURE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
