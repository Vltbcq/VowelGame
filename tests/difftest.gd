extends Node
## Test des règles de difficulté : tireurs qui anticipent (Aquarelle), élites à pouvoirs et flaques
## (Huile), fureur des boss (Chef-d'œuvre).
## Godot --path . res://tests/difftest.tscn [-- <dossier de captures>]

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
	await get_tree().process_frame

	# --- Aquarelle : les tireurs visent où tu vas
	for d in [0, 2]:
		var arena := _arena(d, 6)
		arena.player.vel = Vector2(100, 0)
		var e: Enemy = arena.spawn_enemy_now("crachoir", arena.player.position + Vector2(0, -150), false)
		var aim := e._lead(1.0)
		var off := aim - arena.player.position
		if d == 0:
			_check(off.length() < 0.1, "Esquisse : tir visé sur le joueur")
		else:
			_check(off.distance_to(Vector2(100, 0)) < 0.1, "Aquarelle : tir visé 1 s en avance (%s)" % off)
		arena.queue_free()
		await get_tree().process_frame

	# --- Huile : pouvoirs des élites, flaques
	var ar := _arena(3, 6)
	var seen := {}
	for k in 60:
		var el: Enemy = ar.spawn_enemy_now("tache", Vector2(40 + (k % 10) * 50, 60 + (k / 10) * 45), false, true)
		seen[el.power] = true
	_check(seen.size() == 5 and not seen.has(""), "Huile : chaque élite a un pouvoir (%s)" % [seen.keys()])
	if args.size() > 0:
		for f in 20:
			ar._process(1.0 / 60.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0] + "/elites_pouvoirs.png")
	for e in ar.enemies.duplicate():
		ar.kill_enemy(e)
	ar.queue_free()
	await get_tree().process_frame
	ar = _arena(3, 6)
	# bouclier
	var sh := _elite(ar, "shield")
	var hp0 := sh.hp
	sh.hurt(5.0)
	var hp1 := sh.hp
	sh.hurt(5.0)
	_check(hp1 == hp0 and sh.hp < hp0, "Bouclier : 1er coup bloqué, 2e passe")
	# vampire
	var va := _elite(ar, "vampire")
	va.hp = va.max_hp * 0.5
	var vh := va.hp
	va.position = ar.player.position
	ar.player.inv = 0.0
	ar.player.god = false
	ar._rebuild_grid()
	ar.player.tick(1.0 / 60.0)
	_check(va.hp > vh, "Vampire : se soigne en te touchant (%.0f → %.0f)" % [vh, va.hp])
	va.position = Vector2(30, 30)
	# invocatrice
	var su := _elite(ar, "summoner")
	su.position = Vector2(600, 350)
	var n0 := ar.enemies.size()
	for f in 60 * 4:
		ar.player.inv = 999.0
		su.hp = su.max_hp
		ar._process(1.0 / 60.0)
	_check(ar.enemies.filter(func(e): return e.small).size() >= 2, "Invocatrice : appelle des petits")
	# explosive
	var ex := _elite(ar, "explosive")
	ex.position = ar.player.position + Vector2(20, 0)
	ar.player.inv = 0.0
	ar.player.st = ar.player.st.duplicate()
	ar.player.st.dodge = 0.0   # pas d'esquive pour le test
	ar.player.hp = ar.player.max_hp
	var php := ar.player.hp
	ar.kill_enemy(ex)
	await get_tree().create_timer(0.7).timeout
	_check(ar.player.hp < php, "Explosive : explose après sa mort (PV %.0f → %.0f)" % [php, ar.player.hp])
	# flaques
	var hz0 := ar.hazards.size()
	var nor: Enemy = ar.spawn_enemy_now("tache", Vector2(500, 60), false)
	ar.kill_enemy(nor)
	_check(ar.hazards.size() > hz0, "Huile : l'ennemi tué laisse une flaque qui ralentit")
	ar.queue_free()
	await get_tree().process_frame
	ar = _arena(1, 6)
	var hz1 := ar.hazards.size()
	ar.kill_enemy(ar.spawn_enemy_now("tache", Vector2(500, 60), false))
	_check(ar.hazards.size() == hz1, "Croquis : pas de flaque")
	var elc: Enemy = ar.spawn_enemy_now("tache", Vector2(400, 60), false, true)
	_check(elc.elite and elc.power == "", "Croquis : élite sans pouvoir")
	ar.queue_free()
	await get_tree().process_frame

	# --- Chef-d'œuvre : fureur des boss
	for d in [3, 4]:
		ar = _arena(d, 5)
		var b: Enemy = ar.spawn_enemy_now("rature", Vector2(320, 100), false)
		b.hp = b.max_hp * 0.2
		var nb := ar.bullets.size()
		b._ring(12)
		var shot: int = ar.bullets.size() - nb
		if d == 3:
			_check(not b._frenzy() and shot == 12, "Huile : pas de fureur (%d tirs)" % shot)
		else:
			_check(b._frenzy() and shot == 16, "Chef-d'œuvre : FUREUR sous 25 %% (%d tirs au lieu de 12)" % shot)
		ar.queue_free()
		await get_tree().process_frame
	Run.active = false
	print("DIFF : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)


func _elite(ar: Arena, power: String) -> Enemy:
	var e: Enemy
	while true:
		e = ar.spawn_enemy_now("tache", Vector2(300, 300), false, true)
		if e.power == power:
			return e
		ar.kill_enemy(e)
	return e


func _arena(diff: int, wave: int) -> Arena:
	Run.start(diff, 1)
	Run.wave = wave
	Run.boss_plan = {5: "rature", 10: "critique", 15: "toile"}
	Run.set_character(_blob(32, 180), "")
	Run.set_weapon_art("epee", 1, _blob(32, 90), "", null, "")
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3)), "")
		Run.set_elite_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.4)), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	arena.player.inv = 999.0
	return arena


func _blob(size: int, px: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, Pal.SHADES[1][1])
	return img
