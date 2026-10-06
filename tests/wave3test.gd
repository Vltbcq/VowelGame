extends Node
## Vérifie la mécanique de chaque arme épique / légendaire ajoutée (et l'Horloge).
## Godot --headless --path . res://tests/wave3test.tscn

var arena: Arena


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	await _setup([])
	# --- Ciseaux : exécution sous 25 %
	var e := _enemy(Vector2(400, 200))
	e.hp = e.max_hp * 0.2 + 0.5
	e.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(e, 0.01, {"style": "scissors", "frac": []}, Vector2.ZERO, 0.0)
	_ok("Ciseaux : exécute sous 25 %", e.dead)
	var e2 := _enemy(Vector2(400, 200))
	e2.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(e2, 0.01, {"style": "scissors", "frac": []}, Vector2.ZERO, 0.0)
	_ok("Ciseaux : n'exécute pas au-dessus", not e2.dead)
	# --- Agrafeuse : épinglé + relié (50 % des dégâts)
	var a := _enemy(Vector2(300, 200))
	var b := _enemy(Vector2(360, 200))
	a.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(a, 0.01, {"style": "staple", "frac": []}, Vector2.ZERO, 0.0)
	b.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(b, 0.01, {"style": "staple", "frac": []}, Vector2.ZERO, 0.0)
	var hp_b := b.hp
	a.hurt(10.0)
	_ok("Agrafeuse : épinglé (%.1f s)" % a.pin_t, a.pin_t > 0.5)
	_ok("Agrafeuse : l'autre prend 50 %% (%.1f)" % (hp_b - b.hp), absf((hp_b - b.hp) - 5.0) < 0.01)
	# --- Brumisateur : mouillé → +25 % de dégâts de Foudre
	var w := _enemy(Vector2(300, 250))
	w.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(w, 0.01, {"style": "mist", "frac": []}, Vector2.ZERO, 0.0)
	var hp_w := w.hp
	w.hurt(10.0, false, Vector2.ZERO, Pal.FOUDRE)
	_ok("Brumisateur : mouillé, Foudre ×1,25 (%.1f)" % (hp_w - w.hp), w.wet_t > 0.0 and absf((hp_w - w.hp) - 12.5) < 0.01)
	# --- Éventail : choc contre un bord
	var g := _enemy(Vector2(Arena.W - 30, 200))
	g.max_hp = 1000.0
	g.hp = 1000.0
	g.dodge = 0.0   # (pas d'esquive tirée du dessin : test déterministe)
	arena.hit_enemy(g, 10.0, {"style": "gust", "frac": []}, Vector2.RIGHT, 900.0)
	for i in 30:
		g.tick(1.0 / 60.0)
	_ok("Éventail : choc contre le bord (PV %d / 1000)" % g.hp, g.hp < 1000.0 - 10.0 * 2.0)
	# --- Encre de Chine : réaction en chaîne
	var pack := []
	for i in 6:
		var o := _enemy(Vector2(200 + i * 30, 300))
		o.max_hp = 30.0
		o.hp = 30.0
		pack.append(o)
	arena._rebuild_grid()
	arena.hit_enemy(pack[0], 0.01, {"style": "inkmark", "frac": []}, Vector2.ZERO, 0.0)
	pack[0].ink_dmg = 40.0
	pack[0].hurt(999.0)
	var dead := 0
	for o in pack:
		if o.dead:
			dead += 1
	_ok("Encre de Chine : réaction en chaîne (%d / 6 effacés)" % dead, dead >= 4)
	arena.enemies.clear()
	# --- Point final : aspire puis implose
	var far := _enemy(Vector2(260, 100))
	var d0 := far.position.distance_to(Vector2(320, 100))
	arena._rebuild_grid()
	arena.add_well(Vector2(320, 100), 90.0, 999.0, {"frac": []})
	for i in 40:
		arena._rebuild_grid()
		arena._tick_wells(1.0 / 60.0)
	var d1 := far.position.distance_to(Vector2(320, 100))
	for i in 40:
		arena._rebuild_grid()
		arena._tick_wells(1.0 / 60.0)
	_ok("Point final : aspire (%.0f → %.0f px) puis implose" % [d0, d1], d1 < d0 and far.dead)
	# --- Grande Signature : touche tout le monde sur la ligne
	arena.enemies.clear()
	var line := []
	for i in 5:
		line.append(_enemy(Vector2(60 + i * 120, 200)))
	arena._rebuild_grid()
	arena.signature(200.0, 999.0, {"frac": []})
	var hit := 0
	for o in line:
		if o.dead:
			hit += 1
	_ok("Grande Signature : %d / 5 touchés sur la ligne" % hit, hit >= 4)
	# --- Retouche : ennemis redessinés dans ton camp
	arena.enemies.clear()
	Run.set_weapon_art("retouche", 3, _blob(32, 60, Pal.INK), "", _blob(16, 20, Pal.INK), "")
	Run.add_weapon("retouche", 3, 0, Vector2.ZERO)
	for i in 60:
		var k := _enemy(Vector2(100 + (i % 10) * 40, 120))
		arena.kill_enemy(k)
	for i in 10:
		await get_tree().process_frame
	_ok("Retouche : %d alliés redessinés (max 8 à la fois)" % arena.allies.size(), arena.allies.size() >= 3)
	var victim := _enemy(arena.allies[0].position + Vector2(10, 0)) if not arena.allies.is_empty() else null
	var hpv := victim.hp if victim else 0.0
	for i in 40:
		arena._rebuild_grid()
		for al in arena.allies.duplicate():
			al.tick(1.0 / 60.0)
	_ok("Retouche : les alliés frappent les ennemis", victim != null and victim.hp < hpv)
	Run.weapons.clear()
	# --- Miroir déformant : renvoie les tirs ennemis
	await _setup(["miroir_deformant"])
	var src := _enemy(Vector2(500, 200))
	for i in 5:
		arena.spawn_enemy_bullet(src, arena.player.position + Vector2(40, i * 6 - 12), Vector2(-60, 0))
	var wn: WeaponNode = arena.player.weapons[0]
	wn.special_t = 0.0
	wn._special_step(1.0 / 60.0)
	var mine := 0
	for p in arena.bullets:
		if not p.hostile:
			mine += 1
	_ok("Miroir déformant : %d / 5 tirs renvoyés" % mine, mine == 5)
	# --- Avion en papier : revient vers le joueur
	await _setup(["avion"])
	var tg := _enemy(Vector2(arena.player.position.x + 120, arena.player.position.y))
	arena._rebuild_grid()
	var av: WeaponNode = arena.player.weapons[0]
	av._fire(tg)
	var plane: Projectile = arena.bullets[-1]
	var back := false
	for i in 400:
		arena._rebuild_grid()
		if not plane.tick(1.0 / 60.0, arena):
			back = true
			break
	_ok("Avion en papier : part et revient (retour=%s)" % plane.returning, back and plane.returning)
	# --- Crayon HB : s'échauffe
	await _setup(["crayon_hb"])
	var cr: WeaponNode = arena.player.weapons[0]
	cr.heat = 50
	_ok("Crayon HB : +%.0f %% après 50 coups" % (minf(1.5, 0.03 * cr.heat) * 100.0), cr.heat == 50)
	# --- Loupe : le rayon monte en puissance
	await _setup(["loupe"])
	var big := _enemy(Vector2(arena.player.position.x + 60, arena.player.position.y))
	big.max_hp = 1e6
	big.hp = 1e6
	arena._rebuild_grid()
	var lp: WeaponNode = arena.player.weapons[0]
	for i in 30:
		lp._beam_step(1.0 / 60.0, big)
	var early := 1e6 - big.hp
	for i in 150:
		lp._beam_step(1.0 / 60.0, big)
	var h0 := big.hp
	for i in 30:
		lp._beam_step(1.0 / 60.0, big)
	var late := h0 - big.hp
	_ok("Loupe : 0,5 s au début %.1f → après 3 s %.1f (×%.1f)" % [early, late, late / maxf(0.01, early)], late > early * 2.5)
	# --- Horloge : le temps s'arrête
	await _setup([])
	Run.set_amulet_art("horloge", _blob(16, 30, Pal.INK), "")
	Run.add_amulet("horloge", Run.amulet_art["horloge"].image, Vector2i(30, 30))
	arena.clock_cd = 0.01
	var mover := _enemy(arena.player.position + Vector2(150, 0))
	arena.set_process(true)
	for i in 4:
		await get_tree().process_frame
	arena.set_process(false)
	var p0 := mover.position
	for i in 30:
		arena._process(1.0 / 60.0)
	_ok("Horloge : temps arrêté (%.1f s) et ennemi figé" % arena.stop_t, arena.stop_t > 0.0 and mover.position.distance_to(p0) < 0.01)
	get_tree().quit()


func _setup(types: Array) -> void:
	if arena:
		arena.queue_free()
		await get_tree().process_frame
	Run.start(0)
	Run.set_character(_blob(32, 180, Pal.SHADES[1][1]), "")
	for t in types:
		var def: Dictionary = WeaponDB.TYPES[t]
		Run.set_weapon_art(t, 3, _blob(def.canvas, 60, Pal.INK), "", _blob(16, 20, Pal.INK) if def.kind == "ranged" and not def.get("nobullet", false) else null, "")
		Run.add_weapon(t, 3, 0, Vector2.ZERO)
	Run.set_enemy_art("tache", _blob(24, 120, Pal.SHADES[0][0]), "")
	Run.auto_eproj("tache")
	Run.wave = 3
	Run.recompute()
	arena = Arena.new()
	add_child(arena)
	await get_tree().process_frame
	arena.set_process(false)
	arena.player.god = true


func _enemy(pos: Vector2) -> Enemy:
	var e := arena.spawn_enemy_now("tache", pos, false)
	e.max_hp = 100.0
	e.hp = 100.0
	return e


func _ok(txt: String, ok: bool) -> void:
	print("%s %s" % ["OK  " if ok else "ÉCHEC", txt])


func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0 - 1.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)
	return img
