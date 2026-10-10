extends Node
## Capture : la boutique avec Case opening (les 4 caisses : bois, argent, or, diamant).
## Godot --path . res://tests/caseshot.tscn -- <png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	Run.wave = 2
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	for e in Pal.COUNT:
		img.fill_rect(Rect2i(6, 4 + e * 3, 20, 3), Pal.SHADES[e][1])
	Run.set_character(img, "")
	var w := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	w.fill_rect(Rect2i(2, 10, 20, 4), Pal.SHADES[2][1])
	Run.set_weapon_art("epee", 0, w, "", null, "")
	Run.add_weapon("epee", 0, 10, Vector2(8, 0))
	Run.recompute()
	Run.gold = 250
	Run.set_amulet_art("case_opening", w, "")
	Run.add_amulet("case_opening", w, Vector2i(30, 30))
	Run.new_shop()
	# une caisse de chaque rang, armes et amulettes en alternance
	var n := 0
	for i in Run.shop_offers.size():
		if Run.shop_offers[i].type == "case" and n < 4:
			Run.shop_offers[i] = Run.make_case(n, "weapon" if n % 2 == 0 else "amulet")
			n += 1
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for k in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	Run.active = false
	get_tree().quit()
