extends Node
## Captures du test de daltonisme (Lunettes de l'oculiste).
## Godot --path . res://tests/plateshot.tscn -- <png> [grille]
## - sans « grille » : 2 planches par type, chacune vue normalement puis telle que la voit le daltonien visé ;
## - avec « grille » : 4 planches par type (vue normale), une ligne par type ; les réponses sont
##   écrites dans <png>.txt (dans l'ordre, ligne par ligne).


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var grid := args.size() > 1 and args[1] == "grille"
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var S := OculistTest.SIZE
	var per := 6 if grid else 2
	var cw := S + 10 if grid else S * 2 + 20
	var sheet := Image.create_empty(10 + per * cw, S * 3 + 40, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3e1820"))
	var answers := []
	for row in 3:
		var k: String = OculistTest.TYPES[row]
		var line := []
		for col in per:
			var n := rng.randi_range(12, 98)
			if n % 10 == 0:
				n += 1
			var p := OculistTest.make_plate(k, n, rng)
			line.append("%d|%s%s" % [n, p.family, " inversé" if p.inverted else ""])
			var img: Image = p.image
			var x0 := 10 + col * cw
			var y0 := 10 + row * (S + 10)
			sheet.blit_rect(img, Rect2i(0, 0, S, S), Vector2i(x0, y0))
			if not grid:
				var sim := img.duplicate()
				for y in S:
					for x in S:
						var c := img.get_pixel(x, y)
						if c.a > 0.5:
							sim.set_pixel(x, y, OculistTest.simulate(c, k))
				sheet.blit_rect(sim, Rect2i(0, 0, S, S), Vector2i(x0 + S + 4, y0))
		answers.append("%s : %s" % [k, ";".join(line)])
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png(args[0])
	var f := FileAccess.open(args[0] + ".txt", FileAccess.WRITE)
	f.store_string("\n".join(answers))
	f.close()
	get_tree().quit()
