extends Node
## Test de l'outil Sélection de l'écran de dessin : sélectionner, déplacer, supprimer, défaire.
## Godot --path . res://tests/selecttest.tscn [-- <capture.png>]

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Meta.data = Meta.data.duplicate(true)
	Meta.unlock_all()   # tous les outils (copie de la sauvegarde, rien n'est écrit)
	await get_tree().process_frame
	var cfg := DrawCfg.character()
	var ds := DrawScreen.new(cfg)
	ds.size = Vector2(640, 360)
	add_child(ds)
	await get_tree().process_frame
	_check(ds.tool_btns.has("select"), "outil Sélection disponible")
	# un carré plein de 6×6 en (4,4)
	ds.img.fill_rect(Rect2i(4, 4, 6, 6), Pal.SHADES[1][1])
	ds._recount()
	ds._changed()
	var ink0 := ds.used
	ds._set_tool("select")
	# sélection autour du carré
	ds.begin_stroke(Vector2i(3, 3), false)
	ds.continue_stroke(Vector2i(10, 10))
	ds.end_stroke()
	_check(ds.sel_state == "floating" and ds.sel_img.get_size() == Vector2i(8, 8), "rectangle sélectionné (8×8)")
	# déplacement de +6,+2
	ds.begin_stroke(Vector2i(5, 5), false)
	ds.continue_stroke(Vector2i(11, 7))
	ds.end_stroke()
	_check(ds.img.get_pixel(12, 8).a > 0.5 and ds.img.get_pixel(5, 5).a < 0.5, "la zone a été déplacée")
	_check(ds.used == ink0, "déplacer ne coûte rien de plus (encre %d → %d)" % [ink0, ds.used])
	if OS.get_cmdline_user_args().size() > 0:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	# suppression
	ds._sel_delete()
	_check(ds.used == 0 and ds.sel_state == "", "Suppr : la zone disparaît, l'encre revient")
	# défaire : on retrouve le carré d'origine
	ds._undo()
	_check(ds.img.get_pixel(5, 5).a > 0.5 and ds.used == ink0, "Ctrl+Z : le carré revient à sa place")
	# changer d'outil pose la sélection
	ds._set_tool("select")
	ds.begin_stroke(Vector2i(3, 3), false)
	ds.continue_stroke(Vector2i(10, 10))
	ds.end_stroke()
	ds._set_tool("brush")
	_check(ds.sel_state == "" and ds.img.get_pixel(5, 5).a > 0.5, "changer d'outil pose la sélection")
	# sélection vide : rien
	ds._set_tool("select")
	ds.begin_stroke(Vector2i(20, 20), false)
	ds.continue_stroke(Vector2i(24, 24))
	ds.end_stroke()
	_check(ds.sel_state == "", "zone vide : pas de sélection")
	print("SELECT : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
