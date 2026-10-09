extends Node
## Simulation de réglage (pas un test pass/fail) : un perso « bien équipé » typique joue les vagues
## 8 à 15 en Croquis, SANS puis AVEC la difficulté de fin de partie (Run.late_on).
## Il reste au centre sans bouger (pire cas) ; ses PV sont remis au max à chaque image, on compte
## les dégâts reçus. Vagues normales : ennemis tués et encore en vie à la fin ; boss : temps pour le tuer.
## Godot --headless --path . res://tests/latesim.tscn [-- boss]

const DT := 1.0 / 30.0
## Équipement typique par vague : [arme, rareté]
const KITS := {
	8: [["epee", 1], ["epee", 2], ["pistolet", 2], ["arc", 1], ["dague", 2]],
	9: [["epee", 2], ["epee", 2], ["pistolet", 2], ["arc", 2], ["dague", 2]],
	10: [["epee", 2], ["epee", 2], ["pistolet", 2], ["arc", 2], ["dague", 2], ["lance", 3]],
	11: [["epee", 2], ["epee", 3], ["pistolet", 2], ["arc", 2], ["dague", 2], ["lance", 3]],
	12: [["epee", 3], ["epee", 3], ["pistolet", 2], ["arc", 3], ["dague", 2], ["lance", 3]],
	13: [["epee", 3], ["epee", 3], ["pistolet", 3], ["arc", 3], ["dague", 2], ["lance", 3]],
	14: [["epee", 3], ["epee", 3], ["pistolet", 3], ["arc", 3], ["dague", 3], ["lance", 3]],
	15: [["epee", 3], ["epee", 3], ["pistolet", 3], ["arc", 3], ["dague", 3], ["lance", 3]],
}


func _ready() -> void:
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	seed(1234)
	var only_boss := "boss" in OS.get_cmdline_user_args()   # -- boss : seulement les vagues 10 et 15
	var rows := []
	for late in [false, true]:
		for w in range(8, 16):
			if only_boss and not w in [10, 15]:
				rows.append({"kills": 0, "alive": 0, "taken": 0, "boss": false, "boss_t": -1.0})
				continue
			rows.append(await _wave(w, late))
	print("")
	print("vague | sans : tués / restants / dégâts reçus (boss : s pour le tuer) | avec : idem")
	for w in range(8, 16):
		var a: Dictionary = rows[w - 8]
		var b: Dictionary = rows[w - 8 + 8]
		print("%5d | %s | %s" % [w, _fmt(a), _fmt(b)])
	get_tree().quit()


func _fmt(r: Dictionary) -> String:
	if r.boss:
		return "boss %s, %4d dégâts reçus" % [("%5.1f s" % r.boss_t) if r.boss_t > 0.0 else "  >120 s", r.taken]
	return "%4d tués / %3d restants / %4d dégâts" % [r.kills, r.alive, r.taken]


func _wave(w: int, late: bool) -> Dictionary:
	Run.start(1, 1, 777)
	Run.late_on = late
	Run.wave = w
	Run.level = 2 * w
	var body := _blob(32, 260, Pal.SHADES[1][1])
	Run.set_character(body, "")
	for k in KITS[w]:
		if not Run.has_art(k[0], k[1]):
			var def := WeaponDB.get_def(k[0])
			Run.set_weapon_art(k[0], k[1], _blob(int(def.canvas), int(def.ink * 1.3), Pal.SHADES[2][1]), "",
				_blob(int(def.get("bcanvas", 16)), int(def.get("bink", 20) * 1.3), Pal.SHADES[2][1]) if def.kind == "ranged" else null, "")
		Run.add_weapon(k[0], k[1], 10, Vector2(randf_range(-10, 10), randf_range(-10, 10)))
	# Bonus de niveau : à chaque niveau, le 1er choix (avec la décroissance si elle est active)
	var lv := Run.level
	for l in range(1, lv + 1):
		Run.level = l
		Run.apply_upgrade(Run.roll_upgrades()[0])
	Run.level = lv
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3), Pal.SHADES[0][1]), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()
	Run.hp = Run.stats.max_hp
	var arena := Arena.new()
	add_child(arena)
	await get_tree().process_frame
	var k0 := Run.kills
	var taken := 0.0
	var boss := arena.boss_id != ""
	var t := 0.0
	var boss_t := -1.0
	var seen_boss := false   # (le boss n'apparaît pas à la 1re image)
	var limit := 120.0 if boss else maxf(5.0, arena.time_left - 0.5)
	while t < limit and not arena.ended:
		var hp0: float = arena.player.hp
		arena.player.position = Vector2(Arena.W / 2.0, Arena.H / 2.0)
		arena._process(DT)
		if arena.player.hp < hp0:
			taken += hp0 - arena.player.hp
		arena.player.hp = arena.player.max_hp
		t += DT
		var alive_boss := arena.enemies.filter(func(e): return e.is_boss and not e.dead).size()
		if alive_boss > 0:
			seen_boss = true
		elif boss and seen_boss:
			boss_t = t
			break
	var r := {"kills": Run.kills - k0, "alive": arena.enemies.size(), "taken": roundi(taken), "boss": boss,
		"boss_t": boss_t}
	print("vague %d %s : %s" % [w, "avec" if late else "sans", r])
	arena.ended = true
	arena.queue_free()
	await get_tree().process_frame
	Engine.time_scale = 1.0
	Run.active = false
	return r


func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)
	return img
