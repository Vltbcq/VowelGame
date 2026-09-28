extends Node
## Test des retouches : Raturé (4 attaques), Colosse (charge), Pâté (fonce), synergie Lumière,
## Joconde, Tache indélébile, Élixir de sève, roulette, galerie (Tout + vue en grand), complétion.
## Godot --path . res://tests/reworktest.tscn [-- <dossier de captures>]

var fails := 0
var shots := ""


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots + "/" + name + ".png")


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	shots = args[0] if args.size() > 0 else ""
	await get_tree().process_frame

	# --- Raturé : les 4 attaques tournent, jamais deux fois de suite
	_setup(5)
	Run.boss_plan = {5: "rature", 10: "critique", 15: "toile"}
	var arena := Arena.new()
	add_child(arena)
	var seen := {}
	var repeats := 0
	var prev := ""
	var strokes_max := 0
	var shot_done := false
	for f in 60 * 40:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
		var bs = arena.boss
		if bs != null and is_instance_valid(bs):
			bs.hp = bs.max_hp * (1.0 if f < 60 * 20 else 0.4)   # 2e moitié : enragé
			if bs.last_atk != prev and bs.last_atk != "":
				if prev != "" and bs.last_atk == prev:
					repeats += 1
				seen[bs.last_atk] = true
				prev = bs.last_atk
		strokes_max = maxi(strokes_max, arena.strokes.size())
		if not shot_done and arena.strokes.size() >= 8:
			shot_done = true
			await _shot("rature_hachures")
		if f % 120 == 0:
			await get_tree().process_frame
	_check(seen.size() == 4, "Raturé : les 4 attaques utilisées %s" % [seen.keys()])
	_check(repeats == 0, "Raturé : jamais deux fois la même attaque de suite")
	_check(strokes_max >= 8, "Raturé : hachures tracées (%d traits en même temps)" % strokes_max)
	arena.queue_free()
	await get_tree().process_frame

	# --- Colosse : vise, puis fonce vers le joueur ; Pâté : fonce vers le joueur
	_setup(11)
	arena = Arena.new()
	add_child(arena)
	for e in arena.enemies.duplicate():
		arena.kill_enemy(e)
	arena.time_left = 999.0
	var col: Enemy = arena.spawn_enemy_now("colosse", arena.player.position + Vector2(200, 0), false)
	var pate: Enemy = arena.spawn_enemy_now("pate", arena.player.position + Vector2(-200, 60), false)
	var d_pate0 := pate.position.distance_to(arena.player.position)
	var dashed := false
	var toward := false
	var pate_close := false
	for f in 60 * 8:
		arena.player.inv = 999.0
		var before := col.position.distance_to(arena.player.position) if is_instance_valid(col) else 0.0
		arena._process(1.0 / 60.0)
		if is_instance_valid(col) and col.state == "dash":
			dashed = true
			if col.position.distance_to(arena.player.position) < before - 1.0:
				toward = true
		if is_instance_valid(pate) and pate.position.distance_to(arena.player.position) < d_pate0 - 80.0:
			pate_close = true
	_check(dashed and toward, "Colosse : charge vers le joueur")
	_check(pate_close or not is_instance_valid(pate), "Pâté : fonce vers le joueur")
	arena.queue_free()
	await get_tree().process_frame

	# --- Lumière : explosions +33 % ; Joconde : +15 % par vague ; Tache ; régénération
	_setup(3)
	arena = Arena.new()
	add_child(arena)
	var r0 := arena.boom(40.0)
	arena.syn = {Pal.LUMIERE: 3}
	_check(is_equal_approx(arena.boom(40.0), 40.0 * 1.33) and is_equal_approx(r0, 40.0), "Lumière : explosions ×1,33 (%.1f → %.1f)" % [r0, arena.boom(40.0)])
	Run.set_amulet_art("petard", _blob(16, 20), "")
	Run.add_amulet("petard", Run.amulet_art["petard"].image, Vector2i(30, 30))
	_check(is_equal_approx(arena.boom_dmg(100.0), 125.0), "Pétard : dégâts d'explosion +25 %% (%.0f)" % arena.boom_dmg(100.0))
	Run.amulets = []
	arena.queue_free()
	_check(int(WeaponDB.TYPES.faux.get("min_rar", 0)) == 2 and not "faux" in WeaponDB.allowed_for(1) and not "faux" in WeaponDB.of_kind("melee"), "Faux : épique ou plus seulement")
	# Tout débloquer (outil de dev), sur une copie de la sauvegarde
	var keep: Dictionary = Meta.data
	Meta.data = Meta.data.duplicate(true)
	Meta.data.item_unlocks = {}
	Meta.unlock_all()
	var all_items := ItemUnlockDB.CONDS.keys().all(func(k): return Meta.item_open(k))
	_check(all_items and Meta.map_unlocked(2) and Meta.max_diff(2) == Meta.DIFFICULTIES.size() - 1 and Meta.level("ink") == 5, "Tout débloquer : objets, cartes, difficultés, Atelier")
	Meta.data = keep
	var base := Stats.player(Run)
	Run.joconde = 2
	Run.recompute()
	_check(is_equal_approx(Run.stats.dmg - base.dmg, 30.0), "Joconde : 2 vagues = +30%% dégâts (%s)" % str(roundi(Run.stats.dmg - base.dmg)))
	Run.joconde = 0
	Run.set_amulet_art("tache", _blob(16, 30), "")
	Run.add_amulet("tache", Run.amulet_art["tache"].image, Vector2i(30, 30))
	Run.recompute()
	var dt := {"dmg": Run.stats.dmg - base.dmg, "armor": Run.stats.armor - base.armor, "hp": Run.stats.max_hp - base.max_hp, "spd": Run.stats.speed - base.speed}
	print("     Tache : ", dt)
	_check(dt.armor >= 2.0 and dt.hp >= 5.0 and dt.dmg >= 20.0 and dt.spd <= -20.0, "Tache indélébile : +20 % dégâts, +2 armure, +5 PV, -20 % vitesse")
	var st_names := Stats.STAT_LABELS.map(func(r): return r[0])
	_check(not "pickup" in st_names and AmuletDB.get_def("aimant").is_empty() and AmuletDB.get_def("buvard").is_empty(), "Ramassage retiré (stat, Aimant, Buvard)")

	# Élixir de sève : régénération boostée 10 s
	_setup(3)
	Run.regen_boost = 10.0
	arena = Arena.new()
	add_child(arena)
	_check(arena.player.sap_t > 9.0 and Run.regen_boost == 0.0, "Élixir de sève : actif au début de la vague")
	arena.player.hp = 1.0
	for f in 60:
		arena.player.inv = 999.0
		arena._process(1.0 / 60.0)
	_check(arena.player.hp > 1.5, "Élixir de sève : régénère sans régénération de base (PV %.1f)" % arena.player.hp)
	arena.queue_free()
	await get_tree().process_frame

	# --- Roulette
	_setup(4)
	Run.gold = 100
	Run.shop_offers = [{"type": "roulette", "id": "roulette", "rar": 0, "price": 0, "sold": false},
		{"type": "heal", "id": "seve", "rar": 0, "price": 10, "sold": false}]
	var shop := ShopScreen.new()
	shop.size = Vector2(640, 360)
	add_child(shop)
	await get_tree().process_frame
	await _shot("boutique_roulette")
	shop._open_roulette(0)
	await get_tree().process_frame
	var wheel: Control = shop.roul.find_children("*", "", true, false).filter(func(n): return n.get_script() != null and n.has_method("spin_to"))[0]
	var gold0 := Run.gold
	shop.roul_bet = 20
	seed(7)
	shop._spin.call("rouge", wheel, Label.new(), [Button.new(), Button.new()], HSlider.new())   # sans attendre
	for f in 60:
		await get_tree().process_frame
	await _shot("roulette_tourne")
	while wheel.spinning:
		await get_tree().process_frame
	var g := Run.gold
	_check(g == gold0 - 20 or g == gold0 + 20, "Roulette : mise 20 sur rouge → bourse %d → %d" % [gold0, g])
	_check(Run.shop_offers[0].sold, "Roulette : jouée une fois")
	var cnt := {"rouge": 0, "noir": 0, "vert": 0}
	for k in 37:
		cnt[ShopScreen.wheel_color(k)] += 1
	_check(cnt.rouge == 18 and cnt.noir == 18 and cnt.vert == 1, "Roulette : 18 rouges, 18 noires, 1 verte")
	shop.queue_free()
	await get_tree().process_frame

	# --- Galerie : onglet Tout + vue en grand ; Bestiaire : complétion
	var gal := GalleryScreen.new()
	gal.size = Vector2(640, 360)
	add_child(gal)
	await get_tree().process_frame
	_check(gal.kind == "all", "Galerie : s'ouvre sur « Tout »")
	var all_n := Meta.gallery("all").size()
	var sum := 0
	for k in GalleryScreen.KINDS:
		if k[0] != "all":
			sum += Meta.gallery(k[0]).size()
	_check(all_n == sum, "Galerie : Tout = somme des catégories (%d)" % all_n)
	if all_n > 0:
		gal._view(Meta.gallery("all")[0])
		await get_tree().process_frame
		_check(gal.viewer != null, "Galerie : vue en grand")
		await _shot("galerie_grand")
	gal.queue_free()
	var cx := CodexScreen.new("armes")
	cx.size = Vector2(640, 360)
	add_child(cx)
	await get_tree().process_frame
	var comp: Array = cx._completion()
	_check(comp[0] >= 0.0 and comp[0] <= 100.0 and comp[1] > 0.0 and comp[1] <= 100.0, "Bestiaire : complétion %d%% dessiné · %d%% débloqué" % [roundi(comp[0]), roundi(comp[1])])
	await _shot("bestiaire_completion")
	Run.active = false
	print("REWORK : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)


func _setup(wave: int) -> void:
	Run.start(0, 1)
	Run.wave = wave
	Run.set_character(_blob(32, 180), "")
	Run.set_weapon_art("epee", 1, _blob(32, 90), "", null, "")
	Run.add_weapon("epee", 1, 0, Vector2(8, 0))
	for id in EnemyDB.TYPES:
		var d: Dictionary = EnemyDB.TYPES[id]
		Run.set_enemy_art(id, _blob(d.canvas, int(d.canvas * d.canvas * 0.3)), "")
		if d.get("shoots", false):
			Run.auto_eproj(id)
	Run.recompute()


func _blob(size: int, px: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, Pal.SHADES[1][1])
	return img
