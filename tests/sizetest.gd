extends Node
## Dégâts par seconde selon la taille du dessin (critique compris, ×2).


func _ready() -> void:
	Meta.no_save = true   # ne jamais toucher la vraie sauvegarde
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	for t in ["dague", "epee", "marteau"]:
		var def := WeaponDB.get_def(t)
		var line := "%-8s" % t
		for f in [0.05, 0.25, 0.5, 1.0, 1.5]:
			var a := Analyzer.analyze(_blob(def.canvas, int(def.ink * Stats.FILL_REF * f)))
			var st := Stats.melee({"type": t, "a": a, "rar": 0, "effect": ""}, def)
			var crit: float = minf(st.crit, 100.0) / 100.0
			line += " | f=%.2f dps %.1f (crit %d%%, allonge %d)" % [f, st.damage / st.cooldown * (1.0 + crit), roundi(st.crit), roundi(st.reach)]
		print(line)
	for t in ["pistolet", "arc"]:
		var def := WeaponDB.get_def(t)
		for bf in [0.1, 0.5, 1.0]:
			var line := "%-8s balles %.1f" % [t, bf]
			for f in [0.05, 0.5, 1.0]:
				var a := Analyzer.analyze(_blob(def.canvas, int(def.ink * Stats.FILL_REF * f)))
				var bimg := _blob(def.bcanvas, maxi(1, int(def.bink * Stats.FILL_REF * bf)))
				var st := Stats.ranged({"type": t, "a": a, "ba": Analyzer.analyze(bimg), "bullet": bimg, "rar": 0, "effect": "", "beffect": ""}, def)
				var tot := 0.0
				for b in st.bullets:
					tot += b.damage
				var crit: float = minf(st.crit, 100.0) / 100.0
				line += " | arme %.2f : dps %.1f (%.2fs, crit %d%%)" % [f, tot / st.cooldown * (1.0 + crit), st.cooldown, roundi(st.crit)]
			print(line)
	get_tree().quit()


func _blob(size: int, px: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := sqrt(px / PI)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, Pal.SHADES[0][0])
	return img
