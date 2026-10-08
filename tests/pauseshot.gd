extends Node
## Capture : le menu pause (Échap en pleine vague).
## Godot --path . res://tests/pauseshot.tscn -- <png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(2, 1)
	Run.wave = 7
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(8, 6, 16, 20), Pal.SHADES[1][1])
	img.fill_rect(Rect2i(8, 18, 16, 3), Pal.SHADES[2][1])   # plusieurs couleurs = plusieurs résistances
	img.fill_rect(Rect2i(8, 21, 16, 2), Pal.SHADES[3][1])
	img.fill_rect(Rect2i(8, 23, 16, 3), Pal.SHADES[4][1])
	img.fill_rect(Rect2i(11, 10, 3, 3), Pal.INK)
	img.fill_rect(Rect2i(18, 10, 3, 3), Pal.INK)
	Run.set_character(img, "")
	var w := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	w.fill_rect(Rect2i(2, 10, 20, 4), Pal.SHADES[2][1])
	for t in [["epee", 0], ["epee", 1], ["arc", 2], ["dague", 0]]:
		Run.set_weapon_art(t[0], t[1], w, "", w if WeaponDB.get_def(t[0]).kind == "ranged" else null, "")
		Run.add_weapon(t[0], t[1], 10, Vector2(8, 0))
	var dot := Image.create_empty(10, 10, false, Image.FORMAT_RGBA8)
	dot.fill(Pal.SHADES[3][1])
	for id in ["sablier", "plume", "oeil", "sangsue", "polygunnus"]:
		Run.set_amulet_art(id, dot, "")
		Run.add_amulet(id, dot, Vector2i(4, 4))
	Run.set_familiar_art("moustique", dot, "")
	Run.add_familiar("moustique")
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	Run.recompute()
	var a := Arena.new()
	add_child(a)
	await get_tree().process_frame
	a.hud.toggle_pause()
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	get_tree().paused = false
	get_tree().quit()
