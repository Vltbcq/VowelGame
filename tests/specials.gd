extends Node
## Test des armes spéciales (épiques+ / légendaires) et des nouvelles amulettes.
## Godot --path . res://tests/specials.tscn [-- <dossier de captures>]


func _ready() -> void:
	Meta.no_save = true   # ne jamais toucher la vraie sauvegarde
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	# --- Choix de départ : jamais d'arme spéciale
	var start := WeaponDB.of_kind("melee") + WeaponDB.of_kind("ranged")
	var bad := start.filter(func(t): return int(WeaponDB.TYPES[t].get("min_rar", 0)) > 0)
	print("départ sans arme spéciale : %s (%d types)" % [bad.is_empty(), start.size()])
	print("types par rareté : ", [0, 1, 2, 3].map(func(r): return WeaponDB.allowed_for(r).size()))

	Run.start(0)
	Run.set_character(_blob(32, 180, Pal.SHADES[1][1]), "")
	# --- Boutique : les légendaires restent uniques
	Run.level = 60   # beaucoup de légendaires
	Run.wave = 15
	var dup := 0
	var special_bad := 0
	for i in 300:
		Run.roll_shop()
		var seen := {}
		for o in Run.shop_offers:
			if o.type == "amulet" and o.rar == 3:
				if seen.has(o.id):
					dup += 1
				seen[o.id] = true
			if o.type == "weapon" and int(WeaponDB.TYPES[o.wtype].get("min_rar", 0)) > o.rar:
				special_bad += 1
	print("boutique : légendaires en double=%d, armes spéciales sous leur rareté=%d" % [dup, special_bad])
	for d in AmuletDB.of_rarity(3):
		Run.set_amulet_art(d.id, _blob(16, 30, Pal.SHADES[5][1]), "")
		Run.add_amulet(d.id, Run.amulet_art[d.id].image, Vector2i(30, 30))
	var owned_offered := 0
	for i in 200:
		Run.roll_shop()
		for o in Run.shop_offers:
			if o.type == "amulet" and o.rar == 3:
				owned_offered += 1
	print("boutique : légendaires possédées reproposées=%d, emplacements d'armes=%d" % [owned_offered, Run.max_weapons()])

	# --- Toutes les armes spéciales + les nouvelles amulettes, en arène
	Run.start(0)
	Run.wave = 8
	Run.set_character(_blob(32, 180, Pal.SHADES[1][1]), "")
	var i := 0
	for t in WeaponDB.TYPES:
		var def: Dictionary = WeaponDB.TYPES[t]
		if not def.has("min_rar"):
			continue
		var r: int = def.min_rar
		var cols := [Pal.SHADES[1][1], Pal.SHADES[3][1], Pal.SHADES[2][1]] if t == "palette_vivante" else [Pal.INK]
		var bl: Image = _blob(def.get("bcanvas", 16), 20, Pal.SHADES[3][1]) if def.kind == "ranged" and not def.get("nobullet", false) else null
		Run.set_weapon_art(t, r, _multi(def.canvas, int(def.ink * 0.9), cols), "", bl, "")
		Run.add_weapon(t, r, 0, Vector2(-14 + i * 6, -6 + (i % 2) * 12))
		i += 1
	for id in ["calque", "estompe", "craquelure", "perspective", "tache", "collage", "croquis_rapide",
			"joconde", "double_expo", "trompe_oeil", "restauration", "renaissance", "cadre_dore", "mine_plomb"]:
		Run.set_amulet_art(id, _blob(AmuletDB.canvas(AmuletDB.get_def(id)), 20, Pal.SHADES[4][1]), "")
		Run.add_amulet(id, Run.amulet_art[id].image, Vector2i(randi_range(18, 40), randi_range(18, 40)))
	Run.gold = 120
	Run.recompute()
	print("stats : dégâts %+d%%, portée %+d%%, crit ×%.1f, vitesse %+d" % [Run.stats.dmg, Run.stats.range, Run.stats.crit_mult, Run.stats.speed])
	for w in Run.weapons:
		var st: Dictionary = w.st
		print("  %s (%s) : style %s, cd %.2f" % [w.type, Pal.RARITY_NAMES_F[w.rar], st.style, st.cooldown])
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3), Pal.SHADES[0][0]), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	var arena := Arena.new()
	add_child(arena)
	var zones := 0
	var clones := 0
	var shots := OS.get_cmdline_user_args()
	var hp_before := 0.0
	for f in 1500:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
		zones = maxi(zones, arena.clouds.size())
		for b in arena.bullets:
			if b.burst_r > 0.0:
				clones += 1
				break
		if f in [400, 700] and shots.size() > 0:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(shots[0] + "/specials_arena_%d.png" % f)
		elif f % 60 == 0:
			await get_tree().process_frame
		if arena.ended:
			break
	# Renaissance : on force un coup fatal
	arena.player.inv = 0.0
	arena.player.st = arena.player.st.duplicate()
	arena.player.st.dodge = 0.0
	arena.player.take_hit(99999.0, 0, null)
	print("arène : kills=%d, flaques de pinceau max=%d, frames avec clone=%d, renaissance=%s (PV %d), fin=%s" % [
		Run.kills, zones, clones, Run.revived, arena.player.hp, arena.ended])
	get_tree().quit()


func _blob(size: int, px: int, col: Color) -> Image:
	return _multi(size, px, [col])


## Disque rempli, découpé en bandes de couleurs.
func _multi(size: int, px: int, cols: Array) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, cols[mini(cols.size() - 1, x * cols.size() / size)])
	return img
