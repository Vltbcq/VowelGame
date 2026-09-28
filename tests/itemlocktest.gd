extends Node
## Test des objets verrouillés par succès : boutique filtrée, déblocage en fin de partie, récap.
## Godot --path . res://tests/itemlocktest.tscn [-- <capture.png>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		print("FAIL " + what)
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.data = Meta.data.duplicate(true)
	Meta.data.item_unlocks = {}
	Meta.data.pending_unlocks = []
	await get_tree().process_frame
	var nw := 0
	var na := 0
	for k in ItemUnlockDB.CONDS:
		if k.begins_with("w:"):
			nw += 1
			_check(WeaponDB.TYPES.has(k.substr(2)), "arme existe : " + k)
		else:
			na += 1
			_check(not AmuletDB.get_def(k.substr(2)).is_empty(), "amulette existe : " + k)
		_check(ItemUnlockDB.text(ItemUnlockDB.CONDS[k]) != "?", "condition lisible : " + k)
	print("verrouillés : %d armes / %d amulettes" % [nw, na])

	# Boutique : jamais d'objet verrouillé
	Run.start(0, 1)
	var bad := 0
	for n in 400:
		Run.wave = 1 + n % 20
		Run.roll_shop()
		for o in Run.shop_offers:
			var key := ""
			if o.type == "weapon":
				key = ItemUnlockDB.key_weapon(o.wtype)
			elif o.type == "amulet":
				key = ItemUnlockDB.key_amulet(o.id)
			if key != "" and not Meta.item_open(key):
				bad += 1
	_check(bad == 0, "boutique sans objet verrouillé (%d fautifs)" % bad)

	# Pendant la partie : en attente, pas encore dispo
	Run.gold = 200
	Run.stats.lifesteal = 30.0
	Meta.check_achievements(Run.achievement_ctx(3))
	var pend: Array = Meta.data.pending_unlocks
	_check("w:pinceau_dore" in pend and "a:calice" in pend, "succès obtenus en partie -> en attente")
	_check(not Meta.item_open("w:pinceau_dore"), "pas dispo avant la fin de la partie")
	var got := Meta.apply_pending_unlocks()
	_check(Meta.item_open("w:pinceau_dore") and Meta.item_open("a:calice"), "dispo après la fin de la partie")
	_check(Meta.item_open("w:epee"), "arme classique toujours dispo")

	# Récap : liste qui défile quand il y a beaucoup de lignes
	var many := got.duplicate()
	for k in ItemUnlockDB.CONDS.keys().slice(0, 20):
		many.append(k)
	var scr := ChoiceScreens.end_run(false, 42, many)
	scr.size = Vector2(640, 360)
	add_child(scr)
	for f in 3:
		await get_tree().process_frame
	var scs := scr.find_children("*", "ScrollContainer", true, false)
	_check(scs.size() == 1, "récap avec défilement")
	if scs.size() == 1:
		var sc: ScrollContainer = scs[0]
		_check(sc.get_v_scroll_bar().max_value > sc.size.y, "la liste dépasse et défile")
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0])
	scr.queue_free()

	# « ! » : jamais vu -> nouveau une seule fois
	Meta.data.seen_items = {}
	Run.wave = 3
	Run.roll_shop()
	var first_new := true
	for o in Run.shop_offers:
		if o.type != "heal":
			first_new = first_new and o.get("new", false)
	_check(first_new, "première boutique : tout est nouveau")
	var again := 0
	var seen_before := (Meta.data.seen_items as Dictionary).duplicate()
	for n in 30:
		Run.roll_shop()
		var here := {}
		for o in Run.shop_offers:
			if o.type == "heal":
				continue
			var key := ItemUnlockDB.key_weapon(o.wtype) if o.type == "weapon" else ItemUnlockDB.key_amulet(o.id)
			if o.new and seen_before.has(key):
				again += 1
			here[key] = true
		seen_before.merge(here)
	_check(again == 0, "un objet déjà vu n'a plus de « ! » (%d fautifs)" % again)
	Meta.data.seen_items = {}
	Run.roll_shop()
	Run.set_character(Image.create(32, 32, false, Image.FORMAT_RGBA8), "")
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for f in 3:
		await get_tree().process_frame
	if args.size() > 1:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[1])
	shop.queue_free()
	var cx := CodexScreen.new("armes", "retouche")
	cx.size = Vector2(640, 360)
	add_child(cx)
	for f in 3:
		await get_tree().process_frame
	if args.size() > 2:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[2])
	Run.active = false
	print("ITEMLOCK : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
