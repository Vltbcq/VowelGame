extends Node
## Armes à ratio : DPS comparé à l'Épée (même rareté, même remplissage), en milieu de partie
## puis avec un build spécialisé dans la stat de l'arme. Godot --headless --path . res://tests/scaletest.tscn

const SCALED := ["plume", "rouleau", "chevalet_bouclier", "aerographe", "cutter", "compte_gouttes", "pinceau_dore", "regle", "nuancier", "silhouette"]


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	Run.start(0)
	Run.set_character(_blob(32, 250, Pal.SHADES[1][1]), "")
	# Chaque arme à ratio est comparée à l'arme classique du même style (sans ratio)
	var ref := {"plume": "pistolet", "rouleau": "epee", "chevalet_bouclier": "marteau", "aerographe": "tromblon", "cutter": "dague",
		"compte_gouttes": "baguette", "pinceau_dore": "epee", "regle": "lance", "nuancier": "pistolet", "silhouette": "faux"}
	print("arme              | vs arme classique | milieu de partie | build spécialisé")
	for t in SCALED:
		var base := _dps(ref[t])
		var mid := _dps(t, _mid(t, false))
		var top := _dps(t, _mid(t, true))
		print("%-17s | %-17s | ×%.2f            | ×%.2f" % [t, ref[t], mid / base, top / base])
	Run.weapons = []
	# Vague en arène avec les 10 armes (erreurs ?)
	for t in SCALED:
		var def: Dictionary = WeaponDB.TYPES[t]
		Run.set_weapon_art(t, 1, _blob(def.canvas, int(def.ink * 1.2), Pal.INK), "", _blob(def.get("bcanvas", 16), 20, Pal.SHADES[1][1]) if def.kind == "ranged" else null, "")
		Run.add_weapon(t, 1, 0, Vector2.ZERO)
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, _blob(EnemyDB.TYPES[id].canvas, 120, Pal.SHADES[0][0]), "")
		if EnemyDB.TYPES[id].get("shoots", false):
			Run.auto_eproj(id)
	Run.wave = 4
	Run.gold = 80
	Run.recompute()
	var arena := Arena.new()
	add_child(arena)
	var f := 0
	while not arena.ended and f < 2400:
		arena.player.hp = 1e5
		arena._process(1.0 / 60.0)
		f += 1
		if f % 300 == 0:
			await get_tree().process_frame
	print("ARÈNE 10 armes à ratio : %ds, kills %d, fin=%s" % [f / 60, Run.kills, arena.ended])
	get_tree().quit()


## Stats simulées : milieu de partie, ou build centré sur la stat de l'arme.
func _mid(t: String, spec: bool) -> Dictionary:
	var sc: String = WeaponDB.TYPES[t].get("scale", "")
	var s := {"max_hp": 40.0, "armor": 5.0, "speed": 10.0, "crit": 20.0, "crit_mult": 2.0, "luck": 20.0, "range": 20.0, "gold": 60, "colors": 2, "px": 250, "weapons": 3}
	if spec:
		match sc:
			"free_slots": s.weapons = 1
			"max_hp": s.max_hp = 120.0
			"armor": s.armor = 20.0
			"speed": s.speed = 60.0
			"crit": s.crit = 60.0
			"luck": s.luck = 80.0
			"gold": s.gold = 250
			"range": s.range = 80.0
			"colors": s.colors = 5
			"pixels": s.px = 600
	return s


func _dps(t: String, s := {}) -> float:
	var def: Dictionary = WeaponDB.TYPES[t]
	var img := _blob(def.canvas, int(def.ink * 1.3), Pal.INK)
	var w := {"type": t, "rar": 1, "a": Analyzer.analyze(img), "effect": "", "beffect": ""}
	if def.kind == "ranged":
		var b := _blob(def.get("bcanvas", 16), int(def.get("bink", 20) * 1.3), Pal.INK)
		w.bullet = b
		w.ba = Analyzer.analyze(b)
	var st := Stats.weapon(w)
	var hit: float = st.get("damage", 0.0)
	if st.kind == "ranged":
		hit = 0.0
		for bl in st.bullets:
			hit += bl.damage
	var pellets: int = st.get("pellets", 1)
	if not s.is_empty():
		Run.stats = {"max_hp": s.max_hp, "armor": s.armor, "speed": s.speed, "crit": s.crit, "crit_mult": 2.0, "luck": s.luck, "range": s.range}
		Run.gold = s.gold
		Run.char_a = Run.char_a.duplicate()
		Run.char_a.elements = s.colors
		Run.char_a.pixels = s.px
		Run.weapons = []
		for i in s.weapons:
			Run.weapons.append({})
		hit = Stats.scaled_damage(hit, st.scale) if st.scale != "" else hit
		Run.weapons = []
	var crit: float = (s.get("crit", 0.0) + st.crit) / 100.0 if not s.is_empty() else st.crit / 100.0
	var cmult := 2.0
	if st.get("scale", "") == "crit":
		cmult = maxf(2.0, 2.0 + (s.get("crit", 0.0) + st.crit) / 35.0)
	crit = minf(crit, 1.0)
	return hit * pellets * (1.0 + crit * (cmult - 1.0)) / st.cooldown


func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)
	return img
