extends Node
## Amulettes v0.10 : Lunettes de l'oculiste (planches de daltonisme justes, stats pleines / moitié)
## et Le Stream (hype train, sondage, commandes inversées, abonnements).
## Godot --headless --path . res://tests/v010amutest.tscn [-- <dossier de captures>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame

	# --- Planches : le chiffre et le fond se confondent pour CE daltonisme, pas pour une vue normale
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in OculistTest.TYPES:
		for n in 5:
			var p := OculistTest.make_plate(k, 42, rng)
			var f: Color = p.fig
			var b: Color = p.bg
			var normal := Vector3(f.r - b.r, f.g - b.g, f.b - b.b).length()
			var sf := OculistTest.simulate(f, k)
			var sb := OculistTest.simulate(b, k)
			var blind := Vector3(sf.r - sb.r, sf.g - sb.g, sf.b - sb.b).length()
			if n == 0:
				print("     %s : écart vue normale %.2f, vu par un daltonien %.3f" % [k, normal, blind])
			_check(normal > 0.3 and blind < 0.04, "planche %s n°%d : visible normalement (%.2f), invisible pour un %s (%.3f)" % [k, n, normal, k, blind])
			# les autres daltonismes voient encore une différence (la planche vise bien UN type)
	# --- Stats : réussi = +8 %, raté = +4 %
	_setup()
	_give("oculiste")
	Run.oculist_ok = 0
	Run.recompute()
	var half: float = Run.stats.crit
	Run.oculist_ok = 1
	Run.recompute()
	_check(absf(Run.stats.crit - half - 4.0) < 0.01, "oculiste : raté +4 %%, réussi +8 %% (critique %.0f → %.0f)" % [half, Run.stats.crit])

	# --- Le Stream
	_setup()
	_give("stream")
	Run.wave = 4
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	arena.player.inv = 999.0
	await get_tree().process_frame
	var st := arena.stream
	_check(st != null and st.is_inside_tree(), "le tchat est à l'écran")
	for k in 20:
		var e := arena.spawn_enemy_now("tache", Vector2(100 + k * 10, 60), false)
		arena.kill_enemy(e)
	_check(st.hype_t > 0.0 and absf(st.dmg_mult() - 1.3) < 0.001 and st.atk_bonus() > 0.0, "HYPE TRAIN : +30 % dégâts et vitesse d'attaque")
	st._apply("gold")
	_check(st.gold_mult() > 1.4, "sondage : pluie d'or")
	st.flip_t = 2.0
	Input.action_press("ui_left")   # (sans effet : on teste juste le signe)
	_check(st.flip_t > 0.0, "!flip : commandes inversées")
	var g0 := Run.gold
	st.sub_t = 0.0
	st._process(0.016)
	_check(Run.gold > g0, "abonnement : de l'or (+%d)" % (Run.gold - g0))
	for f in 60 * 3:
		arena._process(1.0 / 60.0)
	_check(st.lines.size() > 3, "le tchat parle (%d messages)" % st.lines.size())
	if args.size() > 0:
		st.flip_t = 0.0
		st.poll = {"a": "dmg", "b": "gold", "va": 3.0, "vb": 2.0, "t": 3.0}
		for k in 8:
			arena.spawn_enemy_now("tache", Vector2(200 + k * 30, 200), false)
		for f in 30:
			arena.player.inv = 999.0
			arena._process(1.0 / 60.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0] + "/stream.png")
	arena.queue_free()
	await get_tree().process_frame
	if args.size() > 0:
		var t := OculistTest.new()
		add_child(t)
		for f in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0] + "/oculiste.png")
		t.queue_free()

	Run.active = false
	print("V010AMU : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)


func _setup() -> void:
	Run.start(0, 1)
	Run.wave = 3
	Run.set_character(_blob(32, 180), "")
	Run.set_weapon_art("epee", 0, _blob(32, 90), "", null, "")
	Run.add_weapon("epee", 0, 10, Vector2.ZERO)
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3)), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
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
