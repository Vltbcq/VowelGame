extends Node
## Test : la couleur d'une arme à distance compte l'arme et ses balles au nombre de pixels
## (une balle minuscule ne change pas la couleur) + capture de la boutique avec les balles.
## Godot --path . res://tests/bulletcolortest.tscn [-- <capture.png>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _blob(n: int, col: Color) -> Image:
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(2, 2, n, n), col)
	return img


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Run.start(0, 1)
	Run.set_character(_blob(12, Pal.SHADES[1][1]), "")
	var blue := Pal.SHADES[Pal.GLACE][1]
	var red := Pal.SHADES[Pal.FEU][1]
	# flingue tout bleu (glace), balle d'1 pixel rouge (feu)
	Run.set_weapon_art("pistolet", 0, _blob(10, blue), "", _blob(1, red), "")
	Run.add_weapon("pistolet", 0, 10, Vector2.ZERO)
	Run.recompute()
	var st: Dictionary = Run.weapons[0].st
	_check(Pal.color_of(st.frac, 0.3) == Pal.GLACE, "balle minuscule rouge : le flingue bleu reste Glace (%s)" % Pal.color_name(Pal.color_of(st.frac, 0.3)))
	# grosse balle rouge : elle l'emporte
	Run.set_weapon_art("pistolet", 0, _blob(6, blue), "", _blob(10, red), "")
	Run.recompute()
	st = Run.weapons[0].st
	_check(Pal.color_of(st.frac, 0.3) == Pal.FEU, "grosse balle rouge : l'arme devient Feu (%s)" % Pal.color_name(Pal.color_of(st.frac, 0.3)))
	# Boutique : un pistolet en vente (déjà dessiné) + celui qu'on a
	Run.gold = 100
	Run.shop_offers = [{"type": "weapon", "wtype": "pistolet", "rar": 0, "price": 12, "sold": false}]
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	for f in 10:
		await get_tree().process_frame
	var badges := shop.find_children("*", "Panel", true, false).filter(func(c): return c.tooltip_text == "Ses balles")
	_check(badges.size() == 2, "boutique : les balles sont montrées sur l'offre et sur l'arme possédée (%d)" % badges.size())
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0])
	Run.active = false
	print("BALLES : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
