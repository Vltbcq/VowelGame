extends Node
## Vérifie les mécaniques des nouvelles amulettes. Godot --headless --path . res://tests/amulettest.tscn

var arena: Arena


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	# --- Étiquette de prix : -8 % par exemplaire, 5 au plus en boutique
	await _setup({})
	var p0 := Run.price_mult()
	for i in 5:
		_give("etiquette_prix")
	var p5 := Run.price_mult()
	var offered := 0
	for i in 400:
		Run.roll_shop()
		for o in Run.shop_offers:
			if o.type == "amulet" and o.id == "etiquette_prix":
				offered += 1
	_ok("Étiquette : prix ×%.2f après 5, plus proposée ensuite (%d fois)" % [p5 / p0, offered], absf(p5 / p0 - pow(0.92, 5)) < 0.001 and offered == 0)
	_ok("Étiquette : valeur affichée « %s »" % Stats.amulet_live("etiquette_prix"), Stats.amulet_live("etiquette_prix").contains("5/5"))
	# --- Fresque : +0,5 % par dessin (max 60 %) et valeur affichée
	await _setup({})
	var g := (Meta.data.get("gallery", []) as Array).size()
	var d0: float = Run.stats.dmg
	_give("fresque")
	_ok("Fresque : %d dessins → +%.1f %% (« %s »)" % [g, Run.stats.dmg - d0, Stats.amulet_live("fresque")], absf((Run.stats.dmg - d0) - minf(60.0, 0.5 * g)) < 0.01)
	# --- Bouclier de papier : 1er coup de la vague ignoré
	await _setup({"bouclier_papier": 1})
	arena.player.st = arena.player.st.duplicate()
	arena.player.st.dodge = 0.0
	var hp := arena.player.hp
	arena.player.take_hit(5.0, 0, null)
	var hp1 := arena.player.hp
	arena.player.inv = 0.0
	arena.player.take_hit(5.0, 0, null)
	_ok("Bouclier de papier : 1er coup ignoré, 2e encaissé (%d → %d → %d)" % [hp, hp1, arena.player.hp], hp1 == hp and arena.player.hp < hp1)
	# --- Encre de seiche : aveugle, recharge 15 s
	await _setup({"encre_seiche": 1})
	var e := _enemy(arena.player.position + Vector2(40, 0))
	arena._rebuild_grid()
	arena.squid_cloud(arena.player.position)
	var first := e.blind_t
	e.blind_t = 0.0
	arena.squid_cloud(arena.player.position)
	_ok("Encre de seiche : aveugle (%.1f s), pas relancée avant 15 s (%.1f s)" % [first, e.blind_t], first > 1.5 and e.blind_t <= 0.0)
	# --- Spatule / Viseur
	await _setup({"spatule": 1})
	var mm: float = arena._amulet_dmg_mult(_enemy(Vector2(100, 100)), {"kind": "melee"})
	var mr: float = arena._amulet_dmg_mult(_enemy(Vector2(100, 100)), {"kind": "ranged"})
	_ok("Spatule : mêlée ×%.2f, distance ×%.2f" % [mm, mr], absf(mm - 1.12) < 0.001 and absf(mr - 0.92) < 0.001)
	# --- Dernière touche : ×2 sous 25 % de PV
	await _setup({"derniere_touche": 1})
	arena.player.hp = arena.player.max_hp * 0.2
	var dt: float = arena._amulet_dmg_mult(_enemy(Vector2(100, 100)), {"kind": "melee"})
	_ok("Dernière touche : ×%.1f sous 25 %% de PV" % dt, absf(dt - 2.0) < 0.001)
	# --- Ombre portée : après une esquive, prochain coup ×2
	await _setup({"ombre_portee": 1})
	arena.player.st = arena.player.st.duplicate()
	arena.player.st.dodge = 100.0
	arena.player.take_hit(5.0, 0, null)
	var om: float = arena._amulet_dmg_mult(_enemy(Vector2(100, 100)), {})
	var om2: float = arena._amulet_dmg_mult(_enemy(Vector2(100, 100)), {})
	_ok("Ombre portée : ×%.0f après esquive, puis ×%.0f" % [om, om2], om == 2.0 and om2 == 1.0)
	# --- Élastique : le projectile rebondit sur le bord
	await _setup({"elastique": 1})
	var pr := arena.spawn_bullet(Vector2(Arena.W - 5, 200), Vector2(300, 0), {"damage": 1.0, "radius": 3.0, "pierce": 0}, {"frac": []}, arena._dot(0), "", 2.0)
	for i in 10:
		pr.tick(1.0 / 60.0, arena)
	_ok("Élastique : rebond (vitesse x = %d)" % pr.vel.x, pr.vel.x < 0.0)
	# --- Mise en abyme : division en 2
	await _setup({"mise_abyme": 1})
	var tgt := _enemy(Vector2(300, 200))
	tgt.max_hp = 1e6
	tgt.hp = 1e6
	arena._rebuild_grid()
	var n0 := arena.bullets.size()
	var pm := arena.spawn_bullet(Vector2(296, 200), Vector2(200, 0), {"damage": 5.0, "radius": 4.0, "pierce": 3}, {"frac": []}, arena._dot(0), "", 2.0)
	pm.tick(1.0 / 60.0, arena)
	_ok("Mise en abyme : %d nouveaux projectiles" % (arena.bullets.size() - n0 - 1), arena.bullets.size() - n0 - 1 == 2)
	# --- Pinceau de Midas : +1 or par ennemi tué
	await _setup({"midas": 1})
	var gold := Run.gold
	arena.kill_enemy(_enemy(Vector2(200, 200)))
	_ok("Pinceau de Midas : +%d or à la mort (hors gouttes)" % (Run.gold - gold), Run.gold - gold == 1)
	# --- Palimpseste : bonus doublés, un choix de moins
	await _setup({})
	Run.bonus = {"dmg": 10.0}
	Run.recompute()
	var dmg1: float = Run.stats.dmg
	_give("palimpseste")
	var dmg2: float = Run.stats.dmg
	_ok("Palimpseste : bonus de niveau +10 %% → +%.0f %%, %d choix au lieu de 3" % [dmg2 - dmg1 + 10.0, Run.roll_upgrades().size()], absf((dmg2 - dmg1) - 10.0) < 0.01 and Run.roll_upgrades().size() == 2)
	# --- Lanterne magique : les ennemis visent le leurre
	await _setup({"lanterne": 1})
	arena.lure_cd = 0.0
	arena._tick_amulets(1.0 / 60.0)
	arena.player.position += Vector2(150, 0)
	_ok("Lanterne magique : les ennemis visent le leurre (%.0f px du joueur)" % arena.target_pos().distance_to(arena.player.position), arena.target_pos().distance_to(arena.player.position) > 100.0)
	# --- Correcteur : pas ralenti par les flaques
	await _setup({"correcteur": 1})
	arena.add_hazard(arena.player.position, 40.0, 5.0, 0.3, 5.0, Pal.INK)
	var hp2 := arena.player.hp
	arena.player.inv = 0.0
	arena.player.tick(1.0 / 60.0)
	_ok("Correcteur : pas blessé par la flaque (%d → %d)" % [hp2, arena.player.hp], arena.player.hp >= hp2)
	# --- Échelle / Accordéon / Taille-douce : valeurs affichées
	await _setup({})
	Run.level = 8
	_give("echelle")
	_ok("Échelle : « %s »" % Stats.amulet_live("echelle"), Stats.amulet_live("echelle") == "+16% dégâts")
	# --- Pierre à aiguiser : +3 par coup pour une arme légendaire
	await _setup({"pierre_aiguiser": 1})
	var tp := _enemy(Vector2(200, 200))
	var hb := tp.hp
	var s0: Dictionary = Run.stats
	Run.stats = s0.duplicate()
	Run.stats.crit = -1000.0
	arena.hit_enemy(tp, 1.0, {"frac": [], "rar": 3}, Vector2.ZERO, 0.0)
	Run.stats = s0
	_ok("Pierre à aiguiser : coup de 1 sur une légendaire → %.1f dégâts" % (hb - tp.hp), hb - tp.hp >= 4.0 * (1.0 + s0.dmg / 100.0) - 0.01)
	# --- Métronome : une attaque sur 5
	await _setup({"metronome": 1})
	Run.set_weapon_art("epee", 0, _blob(32, 60, Pal.INK), "", null, "")
	Run.add_weapon("epee", 0, 0, Vector2.ZERO)
	arena.player.rebuild_weapons()
	var wn: WeaponNode = arena.player.weapons[0]
	_enemy(arena.player.position + Vector2(20, 0))
	arena._rebuild_grid()
	var big := 0
	for i in 10:
		wn.cd = 0.0
		wn.attacking = false
		wn.tick(1.0 / 60.0)
		if wn.metro > 1.0:
			big += 1
	_ok("Métronome : %d attaques ×2,5 sur 10" % big, big == 2)
	get_tree().quit()


func _setup(amulets: Dictionary) -> void:
	if arena:
		arena.queue_free()
		await get_tree().process_frame
	Run.start(0)
	Run.set_character(_blob(32, 180, Pal.SHADES[1][1]), "")
	Run.set_enemy_art("tache", _blob(24, 120, Pal.SHADES[0][0]), "")
	Run.wave = 5
	for id in amulets:
		for i in amulets[id]:
			_give(id)
	Run.recompute()
	arena = Arena.new()
	add_child(arena)
	await get_tree().process_frame
	arena.set_process(false)


func _give(id: String) -> void:
	Run.set_amulet_art(id, _blob(16, 20, Pal.INK), "")
	Run.add_amulet(id, Run.amulet_art[id].image, Vector2i(30, 30))


func _enemy(pos: Vector2) -> Enemy:
	var e := arena.spawn_enemy_now("tache", pos, false)
	e.max_hp = 100.0
	e.hp = 100.0
	return e


func _ok(txt: String, ok: bool) -> void:
	print("%s %s" % ["OK  " if ok else "ÉCHEC", txt])


func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0 - 1.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)
	return img
