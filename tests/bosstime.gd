extends Node
## Mesure (dev) : temps pour tuer chaque boss et dégâts qu'il inflige, avec un build typique du moment.
## Godot --headless --path . res://tests/bosstime.tscn


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	# [vague, boss, armes (rareté), niveau]
	var cases := [[5, "rature", [1, 1, 0, 0], 5], [10, "critique", [2, 1, 1, 1, 1], 11], [10, "muse", [2, 1, 1, 1, 1], 11],
		[15, "toile", [3, 2, 2, 2, 1, 1], 17]]
	print("boss | vague | temps pour le tuer | dégâts reçus (PV max du perso)")
	for c in cases:
		var times := []
		var taken := []
		var maxhp := 0.0
		for rep in 3:
			Run.start(0)
			Run.boss_plan = {5: "rature", 10: c[1] if c[0] == 10 else "critique", 15: "toile"}
			Run.set_character(_blob(32, 180, Pal.SHADES[1][1]), "")
			var types := ["epee", "pistolet", "lance", "arc", "marteau", "baguette"]
			for i in c[2].size():
				var t: String = types[i]
				var def: Dictionary = WeaponDB.TYPES[t]
				Run.set_weapon_art(t, c[2][i], _blob(def.canvas, int(def.ink * 1.1 * WeaponDB.RAR_INK[c[2][i]]), Pal.INK), "",
					_blob(def.get("bcanvas", 16), int(def.get("bink", 30) * 0.9), Pal.SHADES[1][1]) if def.kind == "ranged" else null, "")
				Run.add_weapon(t, c[2][i], 0, Vector2(i * 5 - 12, 0))
			Run.level = c[3]
			Run.bonus = {"max_hp": float(c[3]) * 2.0, "dmg": float(c[3]) * 2.0}
			for id in EnemyDB.TYPES:
				var d: Dictionary = EnemyDB.TYPES[id]
				Run.set_enemy_art(id, _blob(d.canvas, int(d.ink * 1.6 * 0.6), Pal.SHADES[0][0]), "")
				if d.get("shoots", false):
					Run.auto_eproj(id)
			Run.wave = c[0]
			Run.recompute()
			maxhp = Run.stats.max_hp
			var arena := Arena.new()
			add_child(arena)
			var got := 0.0
			var f := 0
			while not arena.ended and f < 60 * 240:
				# PV géants remis à chaque image : on additionne ce que le boss enlève
				arena.player.max_hp = 2e6
				arena.player.hp = 1e6
				# Joueur « courageux » : il colle le boss (à ~45 px) comme un vrai joueur
				var bs = arena.boss
				if bs != null and is_instance_valid(bs):
					var to: Vector2 = bs.position - arena.player.position
					if to.length() > 45.0:
						arena.player.position += to.normalized() * float(Run.stats.move) / 60.0
				arena._process(1.0 / 60.0)
				if arena.player.max_hp > 1e5:
					got += 1e6 - arena.player.hp
				f += 1
				if f % 300 == 0:
					await get_tree().process_frame
			times.append(f / 60.0)
			taken.append(got)
			arena.queue_free()
			await get_tree().process_frame
		times.sort()
		taken.sort()
		print("%s | %d | %.0fs (médiane) | %.0f (PV max %d)" % [c[1], c[0], times[1], taken[1], maxhp])
	get_tree().quit()


func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var ctr := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(ctr) <= r:
				img.set_pixel(x, y, col)
	return img
