extends Node
## Capture : les styles d'affichage des bords (ce qui coûte de l'encre) sur le même dessin.
## Godot --path . res://tests/edgeshot.tscn -- <png>


func _ready() -> void:
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.data.unlocks["pack_primaires"] = 1
	var d := DrawScreen.new(DrawCfg.character())
	add_child(d)
	await get_tree().process_frame
	# un perso simple : un corps rouge plein, une tête jaune, un trou, un trait noir
	var img: Image = d.img
	img.fill_rect(Rect2i(9, 12, 14, 14), Pal.SHADES[1][1])
	img.fill_rect(Rect2i(12, 4, 8, 8), Pal.SHADES[3][1])
	img.fill_rect(Rect2i(14, 16, 4, 4), Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(5, 27, 22, 1), Pal.INK)
	d._recount()
	d._changed()
	var shots := []
	for st in ["dots", "line", "line_gold", "line_tint"]:
		d.view.edge_style = st
		d.view.queue_redraw()
		for k in 2:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var full := get_viewport().get_texture().get_image()
		var sc := float(full.get_width()) / 640.0
		var r := Rect2i(Vector2i(d.view.global_position * sc), Vector2i(d.view.size * sc))
		shots.append(full.get_region(r))
	var w: int = shots[0].get_width()
	var sheet := Image.create_empty(w * 4 + 50, shots[0].get_height() + 20, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3e1820"))
	for k in 4:
		sheet.blit_rect(shots[k], Rect2i(Vector2i.ZERO, shots[k].get_size()), Vector2i(10 + k * (w + 10), 10))
	sheet.save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
