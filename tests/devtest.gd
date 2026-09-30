extends Node
## Test de l'outil de dev (Ctrl+P) : ennemis, armes, amulettes, stats. Joueur de test.
## Godot --path . res://tests/devtest.tscn [-- <dossier de captures>]


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var shots := OS.get_cmdline_user_args()
	Run.start(0)
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(10, 6, 12, 20), Pal.SHADES[1][1])
	Run.set_character(img, "")
	Run.wave = 3
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	await get_tree().process_frame
	# Ctrl+P
	for pressed in [true, false]:
		var k := InputEventKey.new()
		k.keycode = KEY_P
		k.ctrl_pressed = true
		k.pressed = pressed
		Input.parse_input_event(k)
		await get_tree().process_frame
	var dp: DevPanel = arena.hud.dev_panel
	print("DEV ouvert=%s, jeu en pause=%s" % [dp != null, get_tree().paused])
	var t0: float = arena.time_left
	var tb: Array = dp.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("+30 s"))
	if tb.size() == 1:
		tb[0].pressed.emit()
	print("DEV +30 s à la vague : bouton=%s, chrono %.1f → %.1f" % [tb.size() == 1, t0, arena.time_left])
	if dp == null:
		get_tree().quit()
		return
	for t in ["perso", "ennemis", "armes", "amulettes"]:
		dp.tab = t
		dp._build()
		await get_tree().process_frame
		if shots.size() > 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(shots[0] + "/dev_%s.png" % t)
	# Stats
	dp._bonus("dmg", 50.0)
	dp._bonus("max_hp", 20.0)
	arena.player.god = true
	print("DEV stats : dégâts %+d%%, PV max %d, invincible=%s" % [Run.stats.dmg, arena.player.max_hp, arena.player.god])
	# Tous les ennemis et boss, normaux puis élites
	var n0 := arena.enemies.size()
	for el in [false, true]:
		dp.elite = el
		for id in EnemyDB.TYPES:
			dp._spawn(id)
	print("DEV ennemis apparus : %d (attendu %d)" % [arena.enemies.size() - n0, EnemyDB.TYPES.size() * 2])
	# Toutes les armes, toutes les amulettes
	for t in WeaponDB.TYPES:
		dp._give_weapon(t, maxi(1, int(WeaponDB.TYPES[t].get("min_rar", 0))))
	for d in AmuletDB.LIST:
		dp._give_amulet(d.id)
	print("DEV armes : %d (nœuds %d), amulettes : %d" % [Run.weapons.size(), arena.player.weapons.size(), Run.amulets.size()])
	# Fermer et laisser tourner la vague
	arena.hud.toggle_dev()
	print("DEV fermé=%s, pause=%s" % [arena.hud.dev_panel == null, get_tree().paused])
	for f in 900:
		arena._process(1.0 / 60.0)
		if f % 120 == 0:
			await get_tree().process_frame
	print("DEV après 15 s : ennemis vivants %d, PV %d/%d (invincible), fin=%s" % [arena.enemies.size(), arena.player.hp, arena.player.max_hp, arena.ended])
	get_tree().quit()
