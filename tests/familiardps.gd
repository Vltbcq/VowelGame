extends Node
## Mesure : dégâts par seconde de chaque familier, seul, en vague 6 (moyenne sur plusieurs graines).
## Sans arme pour les familiers qui frappent eux-mêmes ; Luciole et Perroquet ont besoin d'une arme :
## pour eux, contribution = (Épée + familier) − (Épée seule).
## Godot --headless --path . res://tests/familiardps.tscn

const SECS := 40.0
const SEEDS := [11, 22, 33, 44]
const WITH_SWORD := ["luciole", "perroquet"]


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var base := await _avg("", true)
	print("Référence (Épée seule) : %.1f dégâts/s" % base)
	var rows := []
	for d in FamiliarDB.LIST:
		var sw: bool = d.id in WITH_SWORD
		var dps: float = await _avg(d.id, sw) - (base if sw else 0.0)
		rows.append([d.id, d.name, int(d.rar), dps])
	rows.sort_custom(func(a, b): return a[3] > b[3])
	print("CLASSEMENT DPS (vague 6, contribution par seconde)")
	for i in rows.size():
		print("%2d. %-20s %-11s %7.1f" % [i + 1, rows[i][1], Pal.RARITY_NAMES[rows[i][2]], rows[i][3]])
	get_tree().quit()


func _avg(fid: String, sword: bool) -> float:
	var sum := 0.0
	for sd in SEEDS:
		sum += await _run(fid, sword, sd)
	return sum / SEEDS.size()


func _run(fid: String, sword: bool, sd: int) -> float:
	seed(sd)
	Run.start(0, 1)
	Run.wave = 6
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	if sword:
		Run.set_weapon_art("epee", 0, img, "", null, "")
		Run.add_weapon("epee", 0, 0, Vector2(8, 0))
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
		if EnemyDB.TYPES[id].get("shoots", false):
			Run.auto_eproj(id)
	if fid != "":
		var fi := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
		fi.fill_rect(Rect2i(3, 3, 10, 10), Pal.SHADES[2][1])
		Run.set_familiar_art(fid, fi, "")
		Run.add_familiar(fid)
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	arena.time_left = 999.0
	await get_tree().process_frame
	var total := 0.0
	var prev := {}
	for f in int(SECS * 60):
		arena.player.inv = 999.0
		arena.player.hp = arena.player.max_hp
		for e in arena.enemies:
			if not prev.has(e):
				prev[e] = e.hp
		arena._process(1.0 / 60.0)
		for e in prev.keys():
			var now: float = 0.0 if (not is_instance_valid(e) or e.dead) else e.hp
			total += maxf(0.0, prev[e] - now)
			if now <= 0.0:
				prev.erase(e)
			else:
				prev[e] = now
	arena.free()
	Run.active = false
	return total / SECS
