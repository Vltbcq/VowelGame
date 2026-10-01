extends Node
## Capture : champignons de Teemeo visibles + outil de dev (aller à une vague).
## Godot --path . res://tests/devjumpshot.tscn -- <champis.png> <dev.png>


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
	var fi := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	fi.fill_rect(Rect2i(3, 3, 10, 10), Pal.SHADES[2][1])
	Run.set_familiar_art("teemeo", fi, "")
	Run.add_familiar("teemeo")
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	await get_tree().process_frame
	for k in 10:
		arena.shrooms.append({"pos": arena.player.position + Vector2.from_angle(k * 0.63) * (40.0 + k * 7.0), "dmg": 5.0})
	for f in 30:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
	await RenderingServer.frame_post_draw
	if args.size() > 0:
		get_viewport().get_texture().get_image().save_png(args[0])
	arena.hud.toggle_dev()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if args.size() > 1:
		get_viewport().get_texture().get_image().save_png(args[1])
	get_tree().paused = false
	Run.active = false
	get_tree().quit()
