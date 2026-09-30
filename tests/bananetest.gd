extends Node
## Test : La Banane (peaux toutes les 15 éliminations, glissade, collisions, musique).
## Godot --path . res://tests/bananetest.tscn [-- <capture.png>]

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
	Run.set_weapon_art("epee", 0, img, "", null, "")
	Run.add_weapon("epee", 0, 0, Vector2(8, 0))
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
		if EnemyDB.TYPES[id].get("shoots", false):
			Run.auto_eproj(id)
	Run.set_amulet_art("banane", img, "")
	Run.add_amulet("banane", img, Vector2i(20, 20))
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	await get_tree().process_frame
	_check(Sfx.music_player != null and Sfx.music_player.playing, "musique de La Banane lancée pendant la vague")
	# 15 éliminations → 1 peau
	var n0 := arena.peels.size()
	for k in 15:
		arena.kill_enemy(arena.spawn_enemy_now("tache", Vector2(100 + k * 10, 60), false))
	_check(arena.peels.size() == n0 + 1, "15 éliminations → 1 peau de banane (%d)" % (arena.peels.size() - n0))
	# un ennemi marche dessus : il glisse, assommé, et percute un voisin
	arena.peels = [{"pos": arena.player.position + Vector2(-120, 0), "t": 20.0, "a": 0.0}]
	var a: Enemy = arena.spawn_enemy_now("tache", arena.player.position + Vector2(-120, 0), false)
	var b: Enemy = arena.spawn_enemy_now("colosse", arena.player.position + Vector2(-80, 0), false)
	var hb := b.hp
	for f in 40:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
		if f == 12 and args.size() > 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(args[0])
	_check(arena.peels.is_empty(), "la peau a servi")
	_check(a.slip_t > 0.0, "l'ennemi est assommé (%.1f s)" % a.slip_t)
	_check(b.hp < hb, "il a percuté un autre ennemi (%.0f → %.0f PV)" % [hb, b.hp])
	# les boss ne glissent pas
	var bs: Enemy = arena.spawn_enemy_now("rature", Vector2(500, 300), false)
	bs.slip(Vector2.RIGHT)
	_check(bs.slip_t == 0.0, "les boss ne glissent pas")
	arena.queue_free()
	Run.amulets = []
	Sfx.update_music()
	_check(not Sfx.music_player.playing, "sans La Banane : pas de musique")
	Run.active = false
	print("BANANE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
