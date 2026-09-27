extends Node
## Dégâts par seconde selon la rareté (même dessin), et intérêt de la fusion.


func _ready() -> void:
	Meta.no_save = true
	for t in ["epee", "dague", "pistolet"]:
		var def := WeaponDB.get_def(t)
		var img := _blob(def.canvas, int(def.ink * Stats.FILL_REF * 0.6))
		var a := Analyzer.analyze(img)
		var bimg := _blob(def.get("bcanvas", 16), int(def.get("bink", 30) * Stats.FILL_REF * 0.5))
		var base := 0.0
		var line := "%-8s" % t
		for r in 4:
			var w := {"type": t, "a": a, "rar": r, "effect": "", "bullet": bimg, "ba": Analyzer.analyze(bimg), "beffect": ""}
			var st := Stats.weapon(w)
			var hit: float = st.damage if st.kind == "melee" else 0.0
			if st.kind == "ranged":
				for b in st.bullets:
					hit += b.damage
			var dps: float = hit / st.cooldown * (1.0 + minf(st.crit, 100.0) / 100.0)
			if r == 0:
				base = dps
			line += " | %s : %.1f dps (x%.2f)" % [Pal.RARITY_NAMES[r], dps, dps / base]
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
