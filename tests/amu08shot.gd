extends Node
## Captures : la vague avec Reflet + Salle thématique + commande, puis la boutique avec la commande.
## Godot --path . res://tests/amu08shot.tscn -- <vague.png> <boutique.png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	Run.wave = 4
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 16, 16), Pal.SHADES[Pal.FEU][1])
	Run.set_character(img, "")
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	var wimg := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	wimg.fill_rect(Rect2i(2, 8, 20, 6), Pal.SHADES[Pal.GLACE][1])
	Run.set_weapon_art("epee", 0, wimg, "", null, "")
	Run.add_weapon("epee", 0, 10, Vector2.ZERO)
	var dot := Image.create_empty(6, 6, false, Image.FORMAT_RGBA8)
	dot.fill(Pal.INK)
	for id in ["reflet", "salle_thematique", "carnet_commandes"]:
		Run.set_amulet_art(id, dot, "")
		Run.add_amulet(id, dot, Vector2i(2, 2))
	Run.recompute()
	Run.order = {"kind": "kills", "n": 30, "progress": 12.0, "reward": 35, "done": false, "text": "Tue 30 ennemis"}
	var a := Arena.new()
	add_child(a)
	await get_tree().process_frame
	a.player.position = Vector2(285, 200)   # près du centre : le double se voit aussi
	for f in 120:
		a.player.hp = 999.0
		a._process(1.0 / 60.0)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	a.queue_free()
	await get_tree().process_frame
	Run.wave = 4
	Run.new_shop()
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for f in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[1])
	Run.active = false
	get_tree().quit()
