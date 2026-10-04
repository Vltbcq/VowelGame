extends Node
## Capture : écran de dessin (perso par défaut, ou arme) -- <capture.png> [perso|arme]


func _ready() -> void:
	Meta.no_save = true
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	var cfg := DrawCfg.weapon("epee", 0) if args.size() > 1 and args[1] == "arme" else DrawCfg.character()
	if args.size() > 1 and args[1] == "arme":
		cfg.base = img
	elif true:
		cfg.base = img
	var ds := DrawScreen.new(cfg)
	add_child(ds)
	for k in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	get_tree().quit()
