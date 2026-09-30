extends Node
## Capture : tirs ennemis (losange « ! ») à côté de tirs du joueur, zoomée.
## Godot --path . res://tests/eprojshot.tscn -- <capture.png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.settings.zoom = 2.5
	Run.start(0, 1)
	Run.wave = 3
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	var b := Image.create_empty(12, 12, false, Image.FORMAT_RGBA8)
	b.fill_rect(Rect2i(3, 3, 6, 6), Pal.SHADES[2][1])
	Run.set_weapon_art("pistolet", 0, img, "", b, "")
	Run.add_weapon("pistolet", 0, 0, Vector2(8, 0))
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
	var src: Enemy = arena.spawn_enemy_now("crachoir", arena.player.position + Vector2(200, 0), false)
	for k in 6:
		arena.spawn_enemy_bullet(src, arena.player.position + Vector2(-50 + k * 20, -30), Vector2(20, 5))
	for f in 40:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
