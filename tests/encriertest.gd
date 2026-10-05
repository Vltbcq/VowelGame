extends Node
## Test : l'Encrier renversé en 3 phases (taches, buvards, éclats de lumière, reflet de Rorschach).
## Godot --path . res://tests/encriertest.tscn [-- <capture.png>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _step(arena: Arena, b: Enemy, n: int) -> void:
	for f in n:
		arena.player.inv = 999.0
		arena.player.hp = 999.0
		arena._process(1.0 / 60.0)


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(0, 2)
	Run.wave = 14
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 16, 16), Pal.SHADES[Pal.FEU][1])   # perso tout rouge : Feu
	Run.set_character(img, "")
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	arena.boss_spawned = true
	await get_tree().process_frame
	var p := arena.player
	p.position = Vector2(320, 300)
	var b: Enemy = arena.spawn_enemy_now("encrier", Vector2(200, 120), false)
	b.cd = 99.0
	b.cd2 = 99.0
	# --- Phase 1 : taches
	_check(p.main_color() == Pal.FEU, "perso rouge : Feu au départ")
	for k in 5:
		p.inv = 0.0
		p.st.dodge = 0.0
		p.take_hit(1.0, 0, b)
	_check(p.stains == 5 and p.main_color() == Pal.NOIR, "5 taches : le perso passe à l'Ombre (%d taches, %s)" % [p.stains, Pal.color_name(p.main_color())])
	_check(Pal.weakness(Pal.LUMIERE, p.main_color()) == Pal.WEAK_MULT, "la Lumière fait ×1,5 sur un perso taché")
	# --- Buvard
	b.blot_cd = 0.0
	_step(arena, b, 30)   # (passé l'arrêt sur image des coups)
	_check(arena.blotters.size() == 1, "un buvard apparaît quand on est taché")
	if not arena.blotters.is_empty():
		p.position = arena.blotters[0].pos
		_step(arena, b, 5)
	_check(p.stains == 0 and p.main_color() == Pal.FEU and arena.blotters.is_empty(), "le buvard nettoie : de nouveau Feu")
	# --- Phase 2 : éclats de lumière
	p.position = Vector2(320, 300)
	b.hp = b.max_hp * 0.6
	_step(arena, b, 20)
	_check(b.toile_phase == 2 and b.boss_inv > 0.0, "à 60 % de PV : phase 2, intouchable un instant")
	_step(arena, b, 100)
	b.cd = 0.0
	b.pattern = 0   # prochaine attaque : spirale
	_step(arena, b, 30)
	var lights := arena.bullets.filter(func(x): return x.hostile and x.light and x.element == Pal.LUMIERE)
	_check(not lights.is_empty(), "phase 2 : ses tirs sont des éclats de Lumière (%d)" % lights.size())
	# --- Phase 3 : Rorschach
	b.hp = b.max_hp * 0.3
	_step(arena, b, 2)
	var tw: Enemy = b.reflet
	_check(b.toile_phase == 3 and is_instance_valid(tw), "à 30 % de PV : phase 3, il se dédouble")
	if is_instance_valid(tw):
		_step(arena, b, 140)
		_check(tw.position.distance_to(Vector2(Arena.W - b.position.x, b.position.y)) < 1.0, "le reflet est en miroir")
		_check(arena.boss == b, "la barre de boss reste celle de l'Encrier")
		var h0 := b.hp
		tw.hurt(100.0)
		_check(is_equal_approx(b.hp, h0 - 100.0) and not tw.dead, "taper le reflet enlève des PV à l'Encrier")
		var n0 := arena.bullets.size()
		b._shoot(Vector2.RIGHT, 1.0)
		_check(arena.bullets.size() == n0 + 2, "chaque tir est copié par le reflet")
		if args.size() > 0:
			b.cd = 0.0
			b.pattern = 2   # projecteur
			_step(arena, b, 40)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(args[0])
		b.hurt(b.hp + 10.0)
		_step(arena, b, 30)
		_check(not is_instance_valid(tw) or tw.dead, "l'Encrier vaincu : le reflet disparaît")
	arena.queue_free()
	Run.active = false
	print("ENCRIER : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
