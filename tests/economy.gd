extends Node
## Mesure de l'économie (dev) : or gagné par vague vs prix de la boutique.
## Godot --headless --path . res://tests/economy.tscn


func _ready() -> void:
	Meta.no_save = true   # ne jamais toucher la vraie sauvegarde
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	Run.start(0)
	Run.set_character(_blob(32, 180), "")
	var sword := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(4, 28):
		for y in range(12, 18):
			sword.set_pixel(x, y, Pal.SHADES[0][0])
	Run.set_weapon_art("epee", 2, sword, "", null, "")
	for k in 4:
		Run.add_weapon("epee", 2, 0, Vector2(k * 8 - 12, 0))
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		# Ennemis dessinés « normalement » : environ la moitié de l'encre en contour, rempli
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.35)), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()
	var total := 0
	print("vague | ennemis tués | or gagné | cumul | prix arme commune | prix amulette commune | prix potion")
	for w in range(1, Run.WAVES + 1):
		Run.wave = w
		var gold_before := Run.gold
		var kills_before := Run.kills
		var arena := Arena.new()
		add_child(arena)
		var frames := 0
		while not arena.ended and frames < 4000:
			arena.player.hp = 1e6
			arena._process(1.0 / 60.0)
			frames += 1
			if frames % 120 == 0:
				await get_tree().process_frame
		arena._flush_pickups()   # les gouttes aspirées en fin de vague
		var g := Run.gold - gold_before
		total += g
		print("%5d | %12d | %8d | %5d | %17d | %21d | %11d" % [w, Run.kills - kills_before, g, total,
			roundi(WeaponDB.PRICE[0] * Run.price_mult()), roundi(AmuletDB.PRICE[0] * Run.price_mult()),
			roundi(Run.HEALS.potion.price * Run.price_mult())])
		arena.queue_free()
		await get_tree().process_frame
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
