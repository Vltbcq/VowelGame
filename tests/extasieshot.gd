extends Node
## Capture : l'amulette Extasie (écran qui ondule, couleurs qui dérivent) + vérification des stats.
## Godot --path . res://tests/extasieshot.tscn -- <capture.png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Run.start(0, 1)
	Run.wave = 3
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	Run.set_weapon_art("epee", 0, img, "", null, "")
	Run.add_weapon("epee", 0, 0, Vector2(8, 0))
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
		if EnemyDB.TYPES[id].get("shoots", false):
			Run.auto_eproj(id)
	var before: float = Stats.player(Run).atk_speed
	Run.set_amulet_art("extasie", img, "")
	Run.add_amulet("extasie", img, Vector2i(20, 20))
	Run.recompute()
	print("EXTASIE vit. d'attaque %+.0f → %+.0f, limite %d, rareté %d" % [before, Run.stats.atk_speed, int(AmuletDB.get_def("extasie").limit), int(AmuletDB.get_def("extasie").rar)])
	var arena := Arena.new()
	add_child(arena)
	print("EXTASIE effet : ", arena.find_children("Extasie", "", true, false).size() == 1)
	for f in 90:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
