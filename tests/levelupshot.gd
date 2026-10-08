extends Node
## Capture : écran de montée de niveau (3 bonus + les stats du perso à droite).
## Godot --path . res://tests/levelupshot.tscn -- <capture.png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Run.start(0, 1)
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 16, 16), Pal.SHADES[Pal.FEU][1])
	Run.set_character(img, "")
	Run.recompute()
	Run.level = 2
	Run.pending_levels = 1
	# (la vitesse d'attaque, au texte long, doit s'afficher en grand comme les autres)
	Run.levelup_choices = [{"stat": "luck", "v": 5.0, "rar": 0, "text": "+5 chance"},
		{"stat": "atk_speed", "v": 5.0, "rar": 0, "text": "+5% vit. d'attaque"},
		{"stat": "harvest", "v": 3.0, "rar": 0, "text": "+3 pourboire"}]
	var s := LevelUpScreen.new()
	s.size = Vector2(640, 360)
	add_child(s)
	for f in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	Run.active = false
	get_tree().quit()
