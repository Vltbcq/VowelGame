extends Node
## Capture : l'Atelier (établi qui défile, Mécénat) -- <capture.png> [bas]


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.data = Meta.data.duplicate(true)
	Meta.data.pigments = 400
	var args := OS.get_cmdline_user_args()
	var s := AtelierScreen.new()
	s.size = Vector2(640, 360)
	add_child(s)
	for f in 6:
		await get_tree().process_frame
	if "bas" in args:
		for sc in s.find_children("*", "ScrollContainer", true, false):
			sc.scroll_vertical = 1000
		for f in 3:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	get_tree().quit()
