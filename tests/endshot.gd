extends Node
## Capture : l'écran de fin de partie (défaite). Godot --path . res://tests/endshot.tscn -- <png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(1, 1)
	Run.wave = 9
	Run.kills = 321
	Run.level = 8
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(8, 6, 16, 20), Pal.SHADES[1][1])
	Run.set_character(img, "")
	add_child(ChoiceScreens.end_run(false, 57))
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	get_tree().quit()
