extends Node
## Capture de l'écran « Ta première arme » (avec les dessins de base du Bestiaire).
## Godot --path . res://tests/weaponpickshot.tscn -- <capture.png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var scr := ChoiceScreens.weapon_kind()
	scr.size = Vector2(640, 360)
	add_child(scr)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
