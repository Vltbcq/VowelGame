extends Node
## Capture : descriptions de la boutique avec les icônes de stats -- <capture.png> <1|2|3>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	Run.wave = 8
	Run.gold = 300
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 22, 22), Pal.SHADES[Pal.FEU][1])
	Run.set_character(img, "")
	Run.recompute()
	if args.size() > 1 and args[1] == "3":
		# armes à ratio : la stat dont elles dépendent, en icône
		Run.shop_offers = [
			{"type": "weapon", "wtype": "rouleau", "rar": 0, "price": 14, "sold": false},
			{"type": "weapon", "wtype": "chevalet_bouclier", "rar": 0, "price": 14, "sold": false},
			{"type": "weapon", "wtype": "aerographe", "rar": 0, "price": 14, "sold": false},
			{"type": "weapon", "wtype": "compte_gouttes", "rar": 0, "price": 14, "sold": false},
			{"type": "weapon", "wtype": "regle", "rar": 0, "price": 14, "sold": false},
			{"type": "weapon", "wtype": "pipette", "rar": 0, "price": 14, "sold": false},
		]
	elif args.size() > 1 and args[1] == "2":
		Run.shop_offers = [
			{"type": "amulet", "id": "pacte_sang", "rar": 3, "price": 70, "sold": false},
			{"type": "amulet", "id": "calice", "rar": 2, "price": 40, "sold": false},
			{"type": "amulet", "id": "taille_douce", "rar": 1, "price": 22, "sold": false},
			{"type": "amulet", "id": "papillon", "rar": 2, "price": 40, "sold": false},
			{"type": "heal", "id": "grande_potion", "rar": 0, "price": 15, "sold": false},
		]
	else:
		Run.shop_offers = [
			{"type": "amulet", "id": "oursin", "rar": 1, "price": 22, "sold": false},
			{"type": "amulet", "id": "carapace", "rar": 1, "price": 22, "sold": false},
			{"type": "amulet", "id": "herisson", "rar": 3, "price": 70, "sold": false},
			{"type": "amulet", "id": "echelle", "rar": 2, "price": 40, "sold": false},
			{"type": "weapon", "wtype": "compte_gouttes", "rar": 0, "price": 14, "sold": false},
		]
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for f in 8:
		await get_tree().process_frame
	# la fiche de l'arme : on fait défiler jusqu'à sa description
	for sc in shop.find_children("*", "ScrollContainer", true, false):
		if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and sc.get_global_rect().position.x > 500 and not (args.size() > 1 and args[1] == "3"):
			sc.scroll_vertical = 1000
	for f in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	Run.active = false
	get_tree().quit()
