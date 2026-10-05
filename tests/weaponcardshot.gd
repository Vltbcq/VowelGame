extends Node
## Capture : fiches des armes en vente (dessinée, à ratio, pas encore dessinée, éventail).
## Godot --path . res://tests/weaponcardshot.tscn -- <capture.png> [etroit]
## « etroit » : 7 offres (fiches étroites), descriptions défilées jusqu'en bas.


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.data = Meta.data.duplicate(true)
	Run.start(0, 1)
	Run.wave = 4
	Run.gold = 120
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 12, 22, 6), Pal.SHADES[Pal.FOUDRE][1])
	Run.set_character(img, "")
	Run.set_weapon_art("pistolet", 0, img, "", WeaponDB.orb(Pal.SHADES[Pal.FEU][1]), "")
	Run.add_weapon("pistolet", 0, 10, Vector2.ZERO)
	Run.add_weapon("pistolet", 0, 10, Vector2(4, 0))   # 2 armes : boutons « revendre »
	Run.recompute()
	Run.shop_offers = [
		{"type": "weapon", "wtype": "pistolet", "rar": 1, "price": 30, "sold": false},
		{"type": "weapon", "wtype": "rouleau", "rar": 0, "price": 19, "sold": false},
		{"type": "weapon", "wtype": "tromblon", "rar": 2, "price": 50, "sold": false},
		{"type": "weapon", "wtype": "baguette", "rar": 0, "price": 14, "sold": false},
		{"type": "weapon", "wtype": "agrafeuse", "rar": 2, "price": 50, "sold": false},
	]
	var narrow := OS.get_cmdline_user_args().size() > 1
	if narrow:
		Run.shop_offers = [
			{"type": "weapon", "wtype": "pipette", "rar": 0, "price": 14, "sold": false},
			{"type": "weapon", "wtype": "pinceau_dore", "rar": 0, "price": 14, "sold": false},
			{"type": "familiar", "id": "pie", "rar": 1, "price": 30, "sold": false},
			{"type": "amulet", "id": "lanterne", "rar": 2, "price": 40, "sold": false},
			{"type": "weapon", "wtype": "agrafeuse", "rar": 2, "price": 50, "sold": false},
			{"type": "heal", "id": "grande_potion", "rar": 0, "price": 15, "sold": false},
			{"type": "weapon", "wtype": "cutter", "rar": 1, "price": 28, "sold": false},
		]
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for f in 10:
		await get_tree().process_frame
	if narrow and OS.get_cmdline_user_args().size() < 3:   # 3e argument : on reste en haut
		for sc in shop.find_children("*", "ScrollContainer", true, false):
			sc.scroll_vertical = 1000
		for f in 3:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	Run.active = false
	get_tree().quit()
