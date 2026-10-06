extends Node
## Test : perforation selon la TAILLE des balles, effets par coup proportionnels à la force du coup.

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _bullet(px: int) -> Image:
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var side := int(ceil(sqrt(float(px))))
	var n := 0
	for y in side:
		for x in side:
			if n < px:
				img.set_pixel(x, y, Pal.main_color(Pal.POISON))
				n += 1
	return img


func _ready() -> void:
	Meta.no_save = true
	Run.start(0, 1)
	var gun := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	gun.fill_rect(Rect2i(4, 12, 24, 8), Pal.SHADES[0][1])
	var def := WeaponDB.get_def("pistolet")
	var ga := Analyzer.analyze(gun)
	var small := Stats.ranged({"type": "pistolet", "a": ga, "ba": Analyzer.analyze(_bullet(2)), "bullet": _bullet(2), "rar": 0, "effect": "", "beffect": ""}, def)
	var big_img := _bullet(int(def.bink * Stats.FILL_REF))
	var big := Stats.ranged({"type": "pistolet", "a": ga, "ba": Analyzer.analyze(big_img), "bullet": big_img, "rar": 0, "effect": "", "beffect": ""}, def)
	_check(small.bullets[0].pierce == 0, "petite balle : ne traverse pas (%d)" % small.bullets[0].pierce)
	_check(big.bullets[0].pierce >= 2, "grosse balle : traverse %d ennemis" % big.bullets[0].pierce)
	var thin := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	thin.fill_rect(Rect2i(0, 7, 3, 1), Pal.SHADES[0][1])   # balle fine et allongée mais petite
	var tst := Stats.ranged({"type": "pistolet", "a": ga, "ba": Analyzer.analyze(thin), "bullet": thin, "rar": 3, "effect": "", "beffect": ""}, def)
	_check(tst.bullets[0].pierce == 0, "balle fine mais petite : ne traverse pas, même légendaire")
	# Effets par coup : un coup à 30 % du coup de référence empoisonne ~3 fois moins souvent
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[0][1])
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
	var wst := {"type": "pistolet", "frac": [0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0], "ref_hit": 10.0}
	var counts := []
	for base in [10.0, 3.0]:
		var n := 0
		for k in 400:
			var e: Enemy = arena.spawn_enemy_now("colosse", Vector2(100, 100), false)
			e.max_hp = 1e6
			e.hp = 1e6
			e.element = 0
			e.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
			arena.hit_enemy(e, base, wst, Vector2.RIGHT, 0.0)
			if e.poison > 0:
				n += 1
			e.dead = true
			e.queue_free()
			arena.enemies.erase(e)
		counts.append(n)
	var ratio := float(counts[1]) / maxf(1.0, float(counts[0]))
	_check(ratio > 0.18 and ratio < 0.45, "coup à 30 %% : %d empoisonnements contre %d (×%.2f)" % [counts[1], counts[0], ratio])
	Run.active = false
	print("BALLES : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
