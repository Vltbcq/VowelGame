extends Node
## Capture : un dessin de la galerie vu en grand, avec « Dessin de base de : ... ».
## Godot --path . res://tests/galuseshot.tscn -- <capture.png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var gal := GalleryScreen.new()
	gal.size = Vector2(640, 360)
	add_child(gal)
	await get_tree().process_frame
	# le premier dessin de la galerie qui sert de dessin de base, sinon le premier tout court
	var pick = null
	for e in Meta.gallery("all"):
		var img := Meta.gallery_image(e)
		if img and not Meta.gallery_uses(img).is_empty():
			pick = e
			break
	if pick == null and not Meta.gallery("all").is_empty():
		pick = Meta.gallery("all")[0]
	if pick != null:
		print("USES ", Meta.gallery_uses(Meta.gallery_image(pick)))
		gal._view(pick)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
