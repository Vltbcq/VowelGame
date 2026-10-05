extends Node
## Test : la boutique ne repropose jamais une amulette à achat unique déjà achetée,
## même quand il n'y a plus de légendaire disponible (repli sur les épiques).
## Godot --headless --path . res://tests/shoplimittest.tscn

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.data = Meta.data.duplicate(true)
	Meta.data.item_unlocks = {}
	for k in ItemUnlockDB.CONDS:
		Meta.data.item_unlocks[k] = true   # tout débloqué
	Run.start(0, 1)
	Run.wave = 14
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 16, 16), Pal.SHADES[1][1])
	Run.set_character(img, "")
	var dot := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	dot.fill(Pal.INK)
	# Toutes les légendaires déjà achetées + les épiques uniques
	var owned := []
	for d in AmuletDB.LIST:
		var lim := int(d.get("limit", 1 if int(d.rar) == 3 else 0))
		if lim == 1 and int(d.rar) >= 2 and d.id != "case_opening":   # (Case opening : que des caisses)
			Run.set_amulet_art(d.id, dot, "")
			Run.add_amulet(d.id, dot, Vector2i(2, 2))
			owned.append(d.id)
	Run.stats.luck = 400.0   # beaucoup de légendaires tirées : on passe souvent par le repli
	var again := {}
	for k in 300:
		Run.roll_shop()
		for o in Run.shop_offers:
			if o.type == "amulet" and o.id in owned:
				again[o.id] = true
	_check(again.is_empty(), "aucune unique déjà achetée n'est reproposée (%s)" % [again.keys()])
	Run.active = false
	print("LIMITES : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
