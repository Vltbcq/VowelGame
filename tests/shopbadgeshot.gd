extends Node
## Capture de la boutique avec les pastilles « ! » (objet débloqué vs objet simplement jamais vu).
## Godot --path . res://tests/shopbadgeshot.tscn -- <capture.png> [<capture2.png>]


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.data = Meta.data.duplicate(true)
	Meta.data.item_unlocks = {}
	for k in ItemUnlockDB.CONDS:
		Meta.data.item_unlocks[k] = true
	Run.start(0, 1)
	Run.wave = 4
	Run.gold = 120
	Run.set_character(Image.create(32, 32, false, Image.FORMAT_RGBA8), "")
	Run.shop_offers = [
		{"type": "weapon", "wtype": "pinceau_dore", "rar": 1, "price": 30, "sold": false, "new": true},
		{"type": "amulet", "id": "calice", "rar": 3, "price": 90, "sold": false, "new": true},
		{"type": "weapon", "wtype": "lance", "rar": 0, "price": 19, "sold": false, "new": true},
		{"type": "amulet", "id": "gouache", "rar": 0, "price": 14, "sold": false, "new": false},
		{"type": "heal", "id": "potion", "rar": 0, "price": 9, "sold": false},
	]
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		for f in (20 if i == 0 else 21):   # deux instants de l'animation
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[i])
	Run.active = false
	get_tree().quit()
