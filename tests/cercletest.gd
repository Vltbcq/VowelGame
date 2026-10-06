extends Node
## Test : cercle des faiblesses (Pal.weakness), tes coups et ceux que tu prends, + captures.
## Godot --path . res://tests/cercletest.tscn [-- <pause.png> <popup.png>]

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
	_check(Pal.weakness(Pal.FEU, Pal.FOUDRE) == 1.5 and Pal.weakness(Pal.ARCANE, Pal.FEU) == 1.5, "Feu bat Foudre, Arcane bat Feu")
	_check(Pal.weakness(Pal.FOUDRE, Pal.FEU) == 0.75 and Pal.weakness(Pal.FEU, Pal.POISON) == 1.0, "dans l'autre sens ×0,75, sinon ×1")
	_check(Pal.weakness(Pal.LUMIERE, Pal.NOIR) == 1.5 and Pal.weakness(Pal.NOIR, Pal.LUMIERE) == 1.5, "Lumière et Noir se battent l'un l'autre")
	var red := [0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	_check(Pal.color_of(red) == Pal.FEU and Pal.color_of([0.9, 0.1, 0, 0, 0, 0, 0]) == Pal.NOIR and Pal.color_of([0.3, 0.2, 0.2, 0.3, 0, 0, 0]) == Pal.FOUDRE, "couleur principale d'un dessin")

	Run.start(0, 1)
	Run.wave = 3
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.main_color(Pal.FEU))   # perso rouge
	Run.set_character(img, "")
	Run.set_weapon_art("epee", 0, img, "", null, "")
	Run.add_weapon("epee", 0, 0, Vector2(8, 0))
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
	Run.stats.crit = -1000.0   # pas de critique pendant les mesures
	var wst := {"type": "epee", "frac": red, "crit": 0.0}
	var a: Enemy = arena.spawn_enemy_now("colosse", Vector2(100, 100), false)
	var b: Enemy = arena.spawn_enemy_now("colosse", Vector2(200, 100), false)
	a.color = Pal.FOUDRE
	b.color = Pal.POISON
	var ha := a.hp
	var hb := b.hp
	a.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(a, 10.0, wst, Vector2.RIGHT, 0.0)
	b.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(b, 10.0, wst, Vector2.RIGHT, 0.0)
	var ra := (ha - a.hp) / maxf(0.01, hb - b.hp)
	_check(absf(ra - 1.5) < 0.05, "arme rouge : ×1,5 sur un ennemi jaune (%.2f)" % ra)
	# Les coups que tu prends : perso rouge, attaqué par un ennemi violet (Arcane bat Feu)
	var p := arena.player
	var src: Enemy = arena.spawn_enemy_now("colosse", Vector2(300, 100), false)
	src.color = Pal.ARCANE
	p.st.dodge = -1000.0
	p.hp = 100.0
	p.inv = 0.0
	p.take_hit(10.0, 0, src)
	var lost_weak := 100.0 - p.hp
	p.hp = 100.0
	p.inv = 0.0
	src.color = Pal.POISON
	p.take_hit(10.0, 0, src)
	var lost_norm := 100.0 - p.hp
	_check(lost_norm > 0.0 and absf(lost_weak / lost_norm - 1.5) < 0.1, "perso rouge : ×1,5 d'un ennemi violet (%.1f contre %.1f)" % [lost_weak, lost_norm])
	# Bouton « Amulettes : oui / non » : cache les amulettes du perso, et revient
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.show_amulets = true
	var am := Image.create_empty(6, 6, false, Image.FORMAT_RGBA8)
	am.fill(Pal.main_color(Pal.GLACE))
	Run.set_amulet_art("oeil", am, "")
	Run.add_amulet("oeil", am, Vector2i(Run.PAD + 8, Run.PAD + 8))
	p.refresh_image()
	var with_am: PackedByteArray = p.pimg.get_data()
	arena.hud._toggle_amulets()
	var without: PackedByteArray = p.pimg.get_data()
	_check(with_am != without and not bool(Meta.setting("show_amulets")) and arena.hud._amulet_btn.text.ends_with("non"), "bouton : les amulettes disparaissent du perso")
	arena.hud._toggle_amulets()
	_check(p.pimg.get_data() == with_am, "bouton : elles reviennent")
	# Captures : menu pause, puis la fenêtre du cercle
	p.hp = p.max_hp
	arena.hud.toggle_pause()
	await get_tree().process_frame
	await get_tree().process_frame
	if args.size() > 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0])
	arena.hud.toggle_pause()
	var pop := UI.cercle_popup(self)
	await get_tree().process_frame
	await get_tree().process_frame
	if args.size() > 1:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[1])
	pop.queue_free()
	get_tree().paused = false
	Run.active = false
	print("CERCLE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
