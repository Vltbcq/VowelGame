extends Node
## Test + capture : vitrine pleine (doublons empilés ×N, défilement, rien ne déborde sur le portrait).
## Godot --path . res://tests/vitrineshot.tscn [-- <capture.png>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Run.start(0, 1)
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 24, 24), Pal.SHADES[Pal.FEU][1])
	Run.set_character(img, "")
	var dot := Image.create_empty(6, 6, false, Image.FORMAT_RGBA8)
	dot.fill(Pal.SHADES[Pal.FOUDRE][1])
	var ids := ["piece", "piece", "piece", "oeil", "oeil", "trefle", "coeur", "tampon", "gouache", "fusain", "lame",
		"gomme", "oursin", "rature", "echelle", "calice", "joconde", "horloge", "lanterne", "mecene", "metre_ruban"]
	for id in ids:
		Run.set_amulet_art(id, dot, "")
		Run.add_amulet(id, dot, Vector2i(2, 2))
	for fid in ["pie", "luciole", "corbeau", "pavel"]:
		if not FamiliarDB.get_def(fid).is_empty():
			Run.add_familiar(fid)
	Run.recompute()
	Run.shop_offers = []
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for f in 6:
		await get_tree().process_frame
	var vsc: ScrollContainer = null
	for sc in shop.find_children("*", "ScrollContainer", true, false):
		if sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
			vsc = sc
	_check(vsc != null, "la vitrine est une zone qui défile")
	if vsc:
		var shelf: Control = vsc.get_child(0)
		_check(shelf.custom_minimum_size.x > vsc.size.x, "vitrine pleine : elle déborde... dans sa zone qui défile (%d > %d)" % [shelf.custom_minimum_size.x, vsc.size.x])
		_check(vsc.get_global_rect().end.x <= 314.0, "rien ne passe sur le portrait")
		var stacks := shelf.find_children("*", "Label", true, false).filter(func(l): return l.text.begins_with("×"))
		_check(stacks.size() == 2, "doublons empilés : ×3 et ×2 (%d piles)" % stacks.size())
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0])
	Run.active = false
	print("VITRINE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
