extends Node
## Capture : fiches des armes en vente (dessinée, à ratio, pas encore dessinée, éventail).
## Godot --path . res://tests/weaponcardshot.tscn -- <capture.png>


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
	Run.recompute()
	Run.shop_offers = [
		{"type": "weapon", "wtype": "pistolet", "rar": 1, "price": 30, "sold": false},
		{"type": "weapon", "wtype": "rouleau", "rar": 0, "price": 19, "sold": false},
		{"type": "weapon", "wtype": "tromblon", "rar": 2, "price": 50, "sold": false},
		{"type": "weapon", "wtype": "cutter", "rar": 0, "price": 14, "sold": false},
		{"type": "amulet", "id": "gouache", "rar": 0, "price": 14, "sold": false},
	]
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for f in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	Run.active = false
	get_tree().quit()
