extends Node
## Test : le scanner de la Photocopieuse laisse des bandes non scannées où l'on est à l'abri.
## Godot --path . res://tests/scantest.tscn [-- <capture.png>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _sweep(arena: Arena, x: float, n_gaps: int) -> float:
	if n_gaps > 0:
		arena.scans.clear()
		arena.scan(10.0, n_gaps)
	var sc: Dictionary = arena.scans[0]
	arena.player.position = Vector2(x if x >= 0.0 else sc.gaps[0] + Arena.SCAN_GAP / 2.0, 200.0)
	arena.player.st.dodge = 0.0
	var hp0 := arena.player.hp
	for f in 240:
		arena.player.inv = 0.0
		arena._process(1.0 / 60.0)
		arena.player.position.x = x if x >= 0.0 else sc.gaps[0] + Arena.SCAN_GAP / 2.0
	return hp0 - arena.player.hp


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	await get_tree().process_frame
	for n in [1, 2]:
		for k in 20:
			arena.scans.clear()
			arena.scan(10.0, n)
			var g: Array = arena.scans[0].gaps
			if g.size() != n:
				_check(false, "%d bande(s) demandée(s), %d obtenue(s)" % [n, g.size()])
				break
	_check(true, "le nombre de bandes est respecté")
	_check(_sweep(arena, -1.0, 2) == 0.0, "dans une bande non scannée : aucun dégât")
	var x_out := 0.0
	arena.scans.clear()
	arena.scan(10.0, 1)
	var g0: float = arena.scans[0].gaps[0]
	x_out = 30.0 if g0 > 120.0 else 600.0
	_check(_sweep(arena, x_out, 0) > 0.0, "hors des bandes : le scanner touche")
	if args.size() > 0:
		arena.scans.clear()
		arena.scan(10.0, 2)
		arena.scans[0].t = 2.2
		arena._process(1.0 / 60.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0])
	arena.queue_free()
	Run.active = false
	print("SCAN : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
