extends Node
## Banc d'essai : chaque arme COMMUNE seule en arène (même dessin rempli à ~90 %), perso immobile
## et invincible. Mesure les dégâts réellement infligés et les kills sur plusieurs vagues / essais.
## Godot --headless --path . res://tests/weaponbench.tscn

const WAVES := [3, 8, 13]
const SEEDS := 3
const FRAMES := 1800   # 30 s par essai


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	var types: Array = []
	for t in WeaponDB.TYPES:
		var def: Dictionary = WeaponDB.TYPES[t]
		if int(def.get("min_rar", 0)) == 0 and not def.has("scale"):
			types.append(t)
	var rows := []
	for t in types:
		var dmg := 0.0
		var kills := 0
		var per_wave := []
		for w in WAVES:
			var wd := 0.0
			for s in SEEDS:
				seed(1000 * w + s)
				var r := await _trial(t, w)
				wd += r[0]
				kills += r[1]
			per_wave.append(wd / SEEDS)
			dmg += wd
		rows.append([t, dmg / (WAVES.size() * SEEDS) / 30.0, kills / float(WAVES.size() * SEEDS), per_wave])
	rows.sort_custom(func(a, b): return a[1] < b[1])
	print("BENCH (du plus faible au plus fort) : arme | dégâts/s moyens | kills/30 s | dégâts/s par vague ", WAVES)
	for r in rows:
		print("BENCH %-10s | %6.1f | %5.1f | %s" % [r[0], r[1], r[2], ", ".join(r[3].map(func(x): return "%.0f" % (x / 30.0)))])
	get_tree().quit()


func _trial(t: String, wave: int) -> Array:
	Run.start(0, 1)
	Run.wave = wave
	Run.set_character(_blob(32, 180), "")
	var def: Dictionary = WeaponDB.TYPES[t]
	var bl: Image = _blob(def.get("bcanvas", 16), int(def.get("bink", 25) * 0.9)) if def.kind == "ranged" else null
	Run.set_weapon_art(t, 0, _blob(def.canvas, int(def.ink * 0.9)), "", bl, "")
	Run.add_weapon(t, 0, 0, Vector2(8, 0))
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3)), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	var last := {}
	var dealt := 0.0
	var k0 := Run.kills
	for f in FRAMES:
		arena.player.inv = 999.0
		arena.player.hp = arena.player.st.max_hp if "st" in arena.player else arena.player.hp
		arena._process(1.0 / 60.0)
		var now := {}
		for e in arena.enemies:
			if is_instance_valid(e):
				var id := e.get_instance_id()
				now[id] = e.hp
				if last.has(id):
					dealt += maxf(0.0, last[id] - e.hp)
		for id in last:
			if not now.has(id):
				dealt += maxf(0.0, last[id])   # tué : le reste de ses PV
		last = now
		if f % 300 == 0:
			await get_tree().process_frame
		if arena.ended:
			break
	var kills := Run.kills - k0
	arena.queue_free()
	await get_tree().process_frame
	return [dealt, kills]


func _blob(size: int, px: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, Pal.INK)
	return img
