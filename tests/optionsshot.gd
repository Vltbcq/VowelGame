extends Node
## Capture : le panneau des Options. Godot --path . res://tests/optionsshot.tscn -- <png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	var o := OptionsPanel.new()
	add_child(o)
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
