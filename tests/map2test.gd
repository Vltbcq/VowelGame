extends Node
## Test de la carte 2 (Le Tableau noir) : ennemis, boss, événements. Joueur invincible.
## Godot --path . res://tests/map2test.tscn [-- <dossier de captures>]


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	var shots := Array(OS.get_cmdline_user_args()).filter(func(a): return a != "boss")
	Run.start(0, 1)
	var p1 := EnemyDB.pool(15)
	Run.start(0, 2)
	var p2 := EnemyDB.pool(15)
	print("POOLS : carte 1=%s | carte 2=%s | boss carte 2=%s" % [p1, p2, Run.boss_plan])
	var mins := []
	for id in EnemyDB.TYPES:
		var cfg := DrawCfg.enemy(id)
		mins.append("%s %d/%d" % [id, cfg.min_ink, cfg.ink])
	print("ENCRE MIN : ", ", ".join(mins))
	Run.set_character(_blob(32, 180, Pal.SHADES[1][1]), "")
	var types := ["epee", "pistolet", "lance", "arc", "marteau", "baguette"]
	for i in types.size():
		var t: String = types[i]
		var def: Dictionary = WeaponDB.TYPES[t]
		Run.set_weapon_art(t, 2, _blob(def.canvas, int(def.ink * 1.3), Pal.INK), "",
			_blob(def.get("bcanvas", 16), int(def.get("bink", 30)), Pal.SHADES[1][1]) if def.kind == "ranged" else null, "")
		Run.add_weapon(t, 2, 0, Vector2(i * 5 - 12, 0))
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3), Pal.SHADES[[1, 3, 4, 5][randi() % 4]][1]), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.level = 12
	Run.bonus = {"dmg": 60.0}
	Run.recompute()
	for w in ([5, 10, 15] if OS.get_cmdline_user_args().has("boss") else [1, 3, 5, 6, 8, 10, 11, 13, 15]):
		Run.wave = w
		var arena := Arena.new()
		add_child(arena)
		var seen := {}
		var counts := {"éponge": 0, "craies": 0, "sonnerie": 0, "bon point": 0, "interro": 0, "scanner": 0, "tampon": 0, "nuit": 0, "fil": 0}
		var last := {}
		var frames := 0
		var t0 := Time.get_ticks_msec()
		while not arena.ended and frames < 60 * 150:
			arena.player.max_hp = 2e6
			arena.player.hp = 1e6
			# Joueur « courageux » en vague de boss : il colle le boss comme un vrai joueur
			var bs = arena.boss
			if bs != null and is_instance_valid(bs):
				var to: Vector2 = bs.position - arena.player.position
				if to.length() > 45.0:
					arena.player.position += to.normalized() * float(Run.stats.move) / 60.0
			arena._process(1.0 / 60.0)
			frames += 1
			var hv := 0
			for e in arena.enemies:
				seen[e.id] = true
				if e.def.get("heavy", false) and not e.small:
					hv += 1
			counts["tanks max"] = maxi(int(counts.get("tanks max", 0)), hv)
			for k in [["éponge", arena.sponges.size()], ["craies", arena.chalks.size()], ["bon point", arena.stars.size()],
					["interro", arena.quizzes.size()], ["scanner", arena.scans.size()], ["tampon", arena.squares.size()]]:
				if k[1] > int(last.get(k[0], 0)):
					counts[k[0]] += 1
				last[k[0]] = k[1]
			if arena.rush_t > 4.98:
				counts["sonnerie"] += 1
			if arena.dark_t > 5.98:
				counts["nuit"] += 1
			for e in arena.enemies:
				if e.partner != null:
					counts["fil"] = 1
			if shots.size() > 0 and ((w == 6 and frames == 900) or (w == 5 and arena.quizzes.size() > 0 and not last.has("shot5")) or (w == 15 and arena.dark_t > 1.0 and arena.dark_t < 4.5 and not last.has("shot15"))):
				last["shot%d" % w] = true
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(shots[0] + "/map2_w%d.png" % w)
			if frames % 120 == 0:
				await get_tree().process_frame
		var ms := float(Time.get_ticks_msec() - t0) / frames
		print("VAGUE %d : %ds, fin=%s, ennemis vus=%s, %s, %.1f ms/frame" % [w, frames / 60, arena.ended, seen.keys(), counts, ms])
		arena.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)
	return img
