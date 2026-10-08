extends Node
## Capture : la toile avec un trait en dégradé (début rouge → fin bleue), un triangle en dégradé,
## et les deux symétries (lignes rouges). Godot --path . res://tests/gradshot.tscn -- <png> [zoom <png>]


func _ready() -> void:
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	for u in ["gradient", "tool_mirror", "tool_mirror_h", "tool_triangle", "pack_primaires"]:
		Meta.data.unlocks[u] = 1
	var args := OS.get_cmdline_user_args()
	var d := DrawScreen.new(DrawCfg.character())
	add_child(d)
	await get_tree().process_frame
	d.col_a = Pal.SHADES[1][1]
	d.col_b = Pal.SHADES[2][1]
	d._toggle("gradient")
	d.grad_end = 1
	d._toggle("mirror")
	d._toggle("mirror_h")
	d.begin_stroke(Vector2i(3, 3), false)
	for x in range(4, 14):
		d.continue_stroke(Vector2i(x, 3 + x / 3))
	d.end_stroke()
	d._toggle("mirror")
	d._toggle("mirror_h")
	d._set_tool("triangle")
	d.begin_stroke(Vector2i(8, 18), false)
	d.continue_stroke(Vector2i(24, 30))
	d.end_stroke()
	d._toggle("mirror")
	d._toggle("mirror_h")
	d._refresh_buttons()
	# une sélection levée puis tournée (boutons Tourner / Miroir sur la toile)
	d._set_tool("select")
	d.begin_stroke(Vector2i(2, 2), false)
	d.continue_stroke(Vector2i(14, 9))
	d.end_stroke()
	d._sel_transform("rot")
	if args.size() > 1:
		d.view.zoom_step(1, Vector2(40, 40))   # 2e capture : zoomée (×1,5) vers le coin haut-gauche
		d.view.zoom_step(1, Vector2(40, 40))
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[args.size() - 1])
	get_tree().quit()
