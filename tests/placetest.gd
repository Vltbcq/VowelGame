extends Node
## Test : en posant une nouvelle amulette, on peut décaler celles déjà posées.
## Godot --path . res://tests/placetest.tscn [-- <capture.png>]

var fails := 0
var result = null


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _click(ps: PlaceScreen, c: Vector2i, button := MOUSE_BUTTON_LEFT) -> void:
	var pos := (Vector2(c) + Vector2(0.5, 0.5)) * ps.px
	var mv := InputEventMouseMotion.new()
	mv.position = pos
	ps._view_input(mv)
	var b := InputEventMouseButton.new()
	b.position = pos
	b.button_index = button
	b.pressed = true
	ps._view_input(b)


func _ready() -> void:
	Meta.no_save = true
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 24, 24), Pal.SHADES[1][1])
	Run.set_character(img, "")
	var a1 := Image.create_empty(6, 6, false, Image.FORMAT_RGBA8)
	a1.fill(Pal.SHADES[3][1])
	Run.set_amulet_art("plume", a1, "")
	Run.add_amulet("plume", a1, Vector2i(Run.PAD + 10, Run.PAD + 10))
	var a2 := Image.create_empty(6, 6, false, Image.FORMAT_RGBA8)
	a2.fill(Pal.SHADES[2][1])
	Run.set_amulet_art("oeil", a2, "")
	var ps := PlaceScreen.new("amulet", a2, AmuletDB.get_def("oeil"))
	add_child(ps)
	ps.done.connect(func(r): result = r)
	await get_tree().process_frame
	var old0: Vector2i = Run.amulets[0].pos
	# 1) on tient la nouvelle : cliquer SUR l'ancienne pose la nouvelle par-dessus (n'attrape pas l'ancienne)
	_click(ps, old0 + Vector2i(5, 5))   # (sur le coin de l'ancienne : la nouvelle la recouvre en partie)
	_check(ps.placed and ps.held == -1 and ps.olds[0].pos == old0, "la nouvelle se pose par-dessus l'ancienne (qui ne bouge pas)")
	# 2) une fois la nouvelle posée, on attrape l'ancienne (hors de la nouvelle) et on la décale
	_click(ps, old0)   # le coin de l'ancienne qui dépasse
	_check(ps.held == 0, "clic sur l'ancienne amulette : elle est attrapée")
	_click(ps, old0 + Vector2i(10, 0))
	_check(ps.held == -2 and ps.olds[0].pos == old0 + Vector2i(10, 0), "elle est reposée 10 px plus loin")
	_check(not ps.ok_btn.disabled, "la nouvelle amulette reste posée")
	if args.size() > 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[0])
	ps._validate()
	_check(result != null and result.moves.size() == 1, "VALIDER renvoie le déplacement de l'ancienne")
	Run.apply_amulet_moves(result.moves)
	Run.add_amulet("oeil", result.image, result.pos)
	_check(Run.amulets[0].pos == old0 + Vector2i(10, 0) and Run.amulets.size() == 2, "la Plume a bien bougé, l'Œil est ajouté")
	Run.active = false
	print("PLACE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
