class_name Arena
extends Node2D
## Une vague : apparition des ennemis, collisions (grille spatiale), dégâts, butin, effets.
## Émet done("cleared" | "dead" | "quit").

signal done(result)

# Arène compacte : on en voit presque tout, même zoomé.
const W := 640
const H := 400
const ZOOM_MIN := 1.0
const ZOOM_MAX := 2.5
const ZOOM_STEP := 0.25
const CELL := 48
const MAX_ENEMIES := 170

var player: Player
var enemies: Array[Enemy] = []
var bullets: Array[Projectile] = []
var pickups: Array[Pickup] = []
var telegraphs: Array = []      # {pos, id, t}
var grid := {}
var world: Node2D
var bullet_layer: Node2D
var loot_layer: Node2D
var marks: _Marks
var numbers: _Numbers
var sparks: _Sparks
var hitstop_t := 0.0        # « arrêt sur image » : le monde se fige un instant sur les gros coups
var fx: Node2D
var cam: Camera2D
var hud: Hud
var floor_img: Image
var floor_tex: ImageTexture
var floor_dirty := false
var floor_timer := 0.0
var time_left := 0.0
var elapsed := 0.0
var boss_id := ""
var boss: Enemy
var boss_spawned := false
var spawn_acc := 0.0
var ended := false
var vacuum := false         # fin de vague : les gouttes restantes sont aspirées vers le joueur
var shake_amt := 0.0
var tex_cache := {}
var eproj_tex := {}
var dot_tex := {}
static var base_floors := {}
const BOARD := Color("2f4a3a")

# Effets au sol / en l'air créés par les ennemis
var hazards: Array = []   # flaques et traînées d'encre {pos, r, t, life, slow, dmg, col}
var lobs: Array = []      # tirs en cloche {from, to, t, dur, dmg, r, el, tex}
var rulers: Array = []    # lignes tracées à la règle {a, b, t, life}
var erasers: Array = []   # coups de gomme de la Toile Blanche {pos, r, t, dur, dmg}
var strokes: Array = []   # traits du Raturé annoncés à la règle, qui deviennent de l'encre {a, b, t, dmg, col, boom}
var clouds: Array = []    # nuages de poison (synergie) {pos, r, t, acc, dps}
var syn := {}             # synergies de couleur actives : élément -> nombre d'armes
# Le Tableau noir : événements et attaques spéciales
var rush_t := 0.0         # Sonnerie : les ennemis se précipitent
var ev_cd := 9.0          # prochain événement
var sponges: Array = []   # {horiz, c, t, tele, dur, hit}
var chalks: Array = []    # pluie de craies {pos, r, t, dmg}
var stars: Array = []     # bons points {pos, t}
var squares: Array = []   # Tampon encreur {pos, half, t, dur, dmg, col}
var quizzes: Array = []   # Professeur {cols, safe, answers, question, t, dur, dmg}
var scans: Array = []     # Photocopieuse {y, t, tele, dur, dmg, hit}
var dark_t := 0.0         # Nuit d'encre
var telegraphs_fx: Array = []   # repères visuels (copie de la Photocopieuse) {pos, t}
# Armes épiques / légendaires et Horloge
var allies: Array = []    # Retouche : ennemis redessinés dans ton camp
var wells: Array = []     # Point final {pos, t, dur, r, dmg, wst}
var staple_last: Enemy    # Agrafeuse : dernier ennemi agrafé
var stop_t := 0.0         # Horloge : temps arrêté
# Amulettes
var wave_len := 0.0       # durée de la vague (Cadran solaire)
var patron_mult := 1.0    # Mécène : ennemis en plus
var patron_elites: Array = []   # Mécène : moments (fraction de vague) où une élite arrive
var crowd := 0            # ennemis proches du joueur (Papier de verre)
var fly_n := 0            # Effet papillon : cumuls
var fly_t := 0.0
var squid_cd := 0.0       # Encre de seiche : recharge
var lure_cd := 15.0       # Lanterne magique
var lure_t := 0.0
var lure_pos := Vector2.ZERO
var kal_i := 0            # Kaléidoscope : couleur suivante
var star_kills := 0       # Nuit étoilée
var bat_log: Array = []   # Chauve-souris : [temps, PV soignés]
var bat_sum := 0.0
var chain_log: Array = [] # Dynamo : temps des chaînes d'éclairs
var clock_cd := 12.0
var air: _Marks


func _ready() -> void:
	_build_floor()
	loot_layer = Node2D.new()
	loot_layer.z_index = -1
	add_child(loot_layer)
	syn = Run.active_synergies()
	Engine.time_scale = float(Meta.setting("speed"))
	marks = _Marks.new()
	marks.arena = self
	marks.z_index = -1
	add_child(marks)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	bullet_layer = Node2D.new()
	bullet_layer.z_index = 5
	add_child(bullet_layer)
	fx = Node2D.new()
	fx.z_index = 10
	add_child(fx)
	numbers = _Numbers.new()
	numbers.z_index = 11
	add_child(numbers)
	sparks = _Sparks.new()
	sparks.z_index = 7
	add_child(sparks)
	air = _Marks.new()
	air.arena = self
	air.air = true
	air.z_index = 6
	add_child(air)

	player = Player.new()
	player.position = Vector2(W / 2.0, H / 2.0)
	world.add_child(player)
	player.setup(self)
	if Run.regen_boost > 0.0:
		player.sap_t = Run.regen_boost   # Élixir de sève (acheté à la boutique précédente)
		Run.regen_boost = 0.0
		_after(0.6, func(): float_text(player.position + Vector2(0, -24), "SÈVE : RÉGÉN ×4", Pal.GOOD))
	if Run.star_buff > 0.0:
		Run.wave_dmg = Run.star_buff   # Grattage (étoile) : pour cette vague
		Run.star_buff = 0.0
		Run.recompute()
		player.st = Run.stats
		_after(0.9, func(): float_text(player.position + Vector2(0, -34), "ÉTOILE : +%d%% DÉGÂTS" % roundi(Run.wave_dmg), Pal.ACCENT))
	match Run.patron:
		"more":
			patron_mult = Run.PATRON_MORE
		"elites":
			for k in Run.PATRON_ELITES:
				patron_elites.append((k + 1.0) / (Run.PATRON_ELITES + 1.0))   # réparties sur la vague
	if Run.patron != "":
		var txt := ("MÉCÈNE : +%d%% D'ENNEMIS" % roundi((Run.PATRON_MORE - 1.0) * 100.0)) if Run.patron == "more" else ("MÉCÈNE : %d ÉLITES EN PLUS" % Run.PATRON_ELITES)
		_after(1.2, func(): float_text(player.position + Vector2(0, -44), txt, Pal.BAD))
		Run.patron = ""

	cam = Camera2D.new()
	var z: float = Meta.setting("zoom")
	cam.zoom = Vector2(z, z)
	cam.limit_left = -8
	cam.limit_top = -16
	cam.limit_right = W + 8
	cam.limit_bottom = H + 8
	player.add_child(cam)
	cam.make_current()

	hud = Hud.new()
	hud.arena = self
	add_child(hud)

	boss_id = EnemyDB.boss_for(Run.wave)
	if boss_id != "":
		time_left = -1.0
		hud.announce("VAGUE %d — BOSS" % Run.wave, Pal.BAD)
		Sfx.play("boss")
	else:
		time_left = minf(20.0 + (Run.eff_wave() - 1) * 2.5, 60.0) * pow(1.25, Run.amulet_count("sablier_brise"))
		wave_len = time_left
		hud.announce("VAGUE %d" % Run.wave, Pal.ACCENT)
		Sfx.play("wave")


func _exit_tree() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0


## Molette ou +/- : zoom de la caméra (sauvegardé).
func _unhandled_input(ev: InputEvent) -> void:
	var dz := 0.0
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			dz = ZOOM_STEP
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dz = -ZOOM_STEP
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
			dz = ZOOM_STEP
		elif ev.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			dz = -ZOOM_STEP
	if dz == 0.0:
		return
	var z := clampf(cam.zoom.x + dz, ZOOM_MIN, ZOOM_MAX)
	cam.zoom = Vector2(z, z)
	Meta.set_setting("zoom", z)
	get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ Boucle

func _process(delta: float) -> void:
	elapsed += delta
	numbers.tick(delta)
	shake_amt = move_toward(shake_amt, 0.0, delta * 25.0)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
	if hitstop_t > 0.0:
		hitstop_t -= delta
		return
	sparks.tick(delta)
	floor_timer -= delta
	if floor_dirty and floor_timer <= 0.0:
		floor_tex.update(floor_img)
		floor_dirty = false
		floor_timer = 0.12
	if ended:
		if vacuum:
			_tick_vacuum(delta)
		return

	_rebuild_grid()
	stop_t -= delta
	_tick_amulets(delta)
	if Run.amulet_count("horloge") > 0:
		clock_cd -= delta
		if clock_cd <= 0.0:
			clock_cd = 12.0
			stop_t = 2.0
			hud.announce("TEMPS ARRÊTÉ", Color(0.7, 0.85, 1.0))
			Sfx.play("zap")
	var frozen := stop_t > 0.0
	if not frozen:
		_spawn(delta)
	for tg in telegraphs.duplicate():
		tg.t -= delta
		if tg.t <= 0.0:
			telegraphs.erase(tg)
			spawn_enemy_now(tg.id, tg.pos, false, tg.get("elite", false))
	marks.queue_redraw()

	player.tick(delta)
	for e in enemies.duplicate():
		if ended:
			break
		if not e.dead and not frozen:
			e.tick(delta)
	for a in allies.duplicate():
		a.tick(delta)
	if not frozen:
		_tick_effects(delta)
		_tick_board(delta)
	_tick_wells(delta)
	air.queue_redraw()

	var alive: Array[Projectile] = []
	for b in bullets:
		if frozen and b.hostile and not ended:
			alive.append(b)   # tirs ennemis figés par l'Horloge
			continue
		if not ended and b.tick(delta, self):
			alive.append(b)
		else:
			b.queue_free()
	bullets = alive

	var alive_p: Array[Pickup] = []
	for p in pickups:
		if p.tick(delta, self):
			alive_p.append(p)
		else:
			p.queue_free()
	pickups = alive_p

	if boss_id == "" and not ended:
		time_left -= delta
		if time_left <= 0.0:
			_end_wave()


func _rebuild_grid() -> void:
	grid.clear()
	for e in enemies:
		if e.dead:
			continue
		var k := Vector2i(floori(e.position.x / CELL), floori(e.position.y / CELL))
		if grid.has(k):
			grid[k].append(e)
		else:
			grid[k] = [e]


## Ennemis dont le cercle touche le cercle (p, r).
func near(p: Vector2, r: float) -> Array:
	var out := []
	var reach := r + 32.0
	var x0 := floori((p.x - reach) / CELL)
	var x1 := floori((p.x + reach) / CELL)
	var y0 := floori((p.y - reach) / CELL)
	var y1 := floori((p.y + reach) / CELL)
	for gx in range(x0, x1 + 1):
		for gy in range(y0, y1 + 1):
			var arr = grid.get(Vector2i(gx, gy))
			if arr == null:
				continue
			for e: Enemy in arr:
				if e.dead:
					continue
				var rr := r + e.radius
				if e.position.distance_squared_to(p) <= rr * rr:
					out.append(e)
	return out


func nearest(p: Vector2, max_r: float) -> Enemy:
	var best: Enemy = null
	var bd := max_r * max_r
	for e in enemies:
		if e.dead:
			continue
		var d := e.position.distance_squared_to(p)
		if d < bd:
			bd = d
			best = e
	return best


# ------------------------------------------------------------------ Apparitions

func _spawn(delta: float) -> void:
	if boss_id != "" and not boss_spawned and elapsed > 1.5:
		boss_spawned = true
		telegraphs.append({"pos": _spawn_pos(160.0), "id": boss_id, "t": 1.5})
	var rate: float = (1.1 + 0.26 * Run.eff_wave()) * Run.diff().spawn * patron_mult
	# Mécène : élites promises
	if not patron_elites.is_empty() and elapsed >= float(patron_elites[0]) * (wave_len if wave_len > 0.0 else 40.0):
		patron_elites.pop_front()
		var eid := _pick_type()
		if eid != "":
			if not Run.elite_art.has(eid):
				var ea: Dictionary = Run.enemy_art[eid]
				Run.set_elite_art(eid, (ea.image as Image).duplicate(), ea.effect, ea.get("outline", false))
			telegraphs.append({"pos": _spawn_pos(120.0), "id": eid, "t": 0.8, "elite": true})
	if boss_id != "":
		rate *= 0.45
	spawn_acc += delta * rate
	while spawn_acc >= 1.0:
		spawn_acc -= 1.0
		if enemies.size() + telegraphs.size() >= MAX_ENEMIES:
			break
		var id := _pick_type()
		if id == "":
			return
		var group := 1
		if randf() < 0.3 and not EnemyDB.TYPES[id].get("heavy", false):
			group += randi() % 3
		var c := _spawn_pos(120.0)
		if EnemyDB.TYPES[id].beh == "clip":
			group = 2
		# Les taches piégées se posent en ligne
		if EnemyDB.TYPES[id].beh == "mine":
			group = randi_range(3, 5)
			var dir := Vector2.from_angle(randf() * TAU)
			for i in group:
				telegraphs.append({"pos": (c + dir * (i - group / 2.0) * 26.0).clamp(Vector2(16, 16), Vector2(W - 16, H - 16)), "id": id, "t": 0.8})
			continue
		for i in group:
			var el: bool = Run.difficulty >= 2 and Run.elite_art.has(id) and randf() < 0.05 + 0.02 * Run.difficulty   # (le Mécène amène les siennes)
			telegraphs.append({"pos": c + Vector2(randf_range(-16, 16), randf_range(-16, 16)), "id": id, "t": 0.8, "elite": el})


## Tanks (« heavy ») : jamais plus de MAX_HEAVY en même temps sur la page.
const MAX_HEAVY := 2


func _pick_type() -> String:
	var heavy := 0
	for e in enemies:
		if e.def.get("heavy", false):
			heavy += 1
	for tg in telegraphs:
		if EnemyDB.TYPES.get(tg.id, {}).get("heavy", false):
			heavy += 1
	var pool := EnemyDB.pool(Run.wave).filter(func(i): return Run.enemy_art.has(i) and (heavy < MAX_HEAVY or not EnemyDB.TYPES[i].get("heavy", false)))
	if pool.is_empty():
		return ""
	var total := 0
	for i in pool:
		total += int(EnemyDB.TYPES[i].weight)
	var r := randi() % total
	for i in pool:
		r -= int(EnemyDB.TYPES[i].weight)
		if r < 0:
			return i
	return pool[0]


func _spawn_pos(min_dist: float) -> Vector2:
	var p := Vector2.ZERO
	for i in 20:
		p = Vector2(randf_range(24, W - 24), randf_range(24, H - 24))
		if p.distance_to(player.position) > min_dist:
			break
	return p


func spawn_enemy_now(id: String, pos: Vector2, small: bool, elite := false) -> Enemy:
	if not Run.enemy_art.has(id):
		id = "tache"
		if not Run.enemy_art.has(id):
			return null
	var e := Enemy.new()
	e.position = pos
	world.add_child(e)
	e.setup(self, id, small, elite)
	e.queue_redraw()
	enemies.append(e)
	if e.is_boss:
		boss = e
		shake(6.0)
	return e


func enemy_tex(id: String, elite := false) -> Texture2D:
	var key := id + ("_elite" if elite else "")
	if not tex_cache.has(key):
		var art: Dictionary = Run.elite_art[id] if elite else Run.enemy_art[id]
		tex_cache[key] = Gfx.texture(Analyzer.trim(art.image))
	return tex_cache[key]


func _dot(el: int) -> Texture2D:
	if not dot_tex.has(el):
		var img := Image.create_empty(5, 5, false, Image.FORMAT_RGBA8)
		var c: Color = Pal.main_color(el) if el > 0 else Pal.SHADES[0][1]
		for y in 5:
			for x in 5:
				if (x - 2) * (x - 2) + (y - 2) * (y - 2) <= 4:
					img.set_pixel(x, y, c)
		dot_tex[el] = Gfx.texture(img)
	return dot_tex[el]


# ------------------------------------------------------------------ Projectiles

func spawn_bullet(pos: Vector2, vel: Vector2, b: Dictionary, wst: Dictionary, tex: Texture2D, effect: String, life: float, outline := false) -> Projectile:
	var p := Projectile.new()
	p.position = pos
	p.vel = vel
	p.radius = b.radius
	p.dmg = b.damage
	p.pierce = b.pierce + Run.amulet_count("calque")
	p.bounces = Run.amulet_count("elastique")
	p.homing_soft = Run.amulet_count("boussole") > 0 and wst.get("kind", "") == "ranged"
	p.tex = tex
	p.fx = effect
	p.outline_on = outline
	p.life = life
	p.wst = wst
	p.knock = 25.0
	bullet_layer.add_child(p)
	p.setup(tex, effect, outline)
	bullets.append(p)
	return p


func spawn_enemy_bullet(src: Enemy, pos: Vector2, vel: Vector2, hang := 0.0) -> void:
	var p := Projectile.new()
	p.hang = hang
	p.hostile = true
	p.position = pos
	p.dmg = src.dmg * (0.8 if src.is_boss else 1.0)
	p.life = 6.0
	var tex: Texture2D
	var effect := ""
	var outline := false
	if Run.eproj_art.has(src.id):
		var art: Dictionary = Run.eproj_art[src.id]
		vel *= art.mods.speed
		p.hang_speed *= art.mods.speed
		p.radius = art.mods.radius
		p.element = art.mods.element
		effect = art.effect
		outline = art.get("outline", false)
		if not eproj_tex.has(src.id):
			eproj_tex[src.id] = Gfx.texture(Analyzer.trim(art.image))
		tex = eproj_tex[src.id]
	else:
		p.radius = 3.0
		p.element = src.element
		tex = _dot(src.element)
	# Trompe-l'œil : certains tirs ennemis partent de travers
	if randf() < 0.3 * Run.amulet_count("trompe_oeil"):
		vel = vel.rotated(randf_range(0.9, 1.7) * (1.0 if randf() < 0.5 else -1.0))
	p.vel = vel
	p.spin = 5.0
	bullet_layer.add_child(p)
	p.setup(tex, effect, outline)
	bullets.append(p)


# ------------------------------------------------------------------ Dégâts

func hit_enemy(e: Enemy, base: float, wst: Dictionary, dir: Vector2, knock: float) -> void:
	if e.dead:
		return
	var s := Run.stats
	var scale: String = wst.get("scale", "")
	if scale != "":
		base = Stats.scaled_damage(base, scale)
	# Pierre à aiguiser : +1 dégât par rang de rareté de l'arme
	base += float(wst.get("rar", 0)) * Run.amulet_count("pierre_aiguiser")
	var dmg: float = base * (1.0 + s.dmg / 100.0)
	if stop_t > 0.0:
		dmg *= 2.0   # Horloge : pendant l'arrêt du temps
	dmg *= _amulet_dmg_mult(e, wst)
	match String(wst.get("style", "")):
		"staple":
			e.pin_t = 1.0
			_staple(e)
		"mist":
			e.wet_t = 4.0
		"gust":
			e.gust_t = 0.8
			e.gust_dmg = base * 2.5 * (1.0 + s.dmg / 100.0)
		"inkmark":
			e.ink_t = 4.0
			e.ink_dmg = base * 0.8 * (1.0 + s.dmg / 100.0)
			e.queue_redraw()
	var vernis := Run.amulet_count("vernis")
	if vernis > 0:
		dmg *= pow(1.35, vernis) if (e.is_boss or e.elite) else pow(0.85, vernis)
	if Run.amulet_count("perspective") > 0:
		var dist := e.position.distance_to(player.position)
		if dist > 110.0:
			dmg *= 1.25
		elif dist < 45.0:
			dmg *= 0.75
	var crit_chance: float = s.crit + float(wst.get("crit", 0.0))
	var crit: bool = randf() * 100.0 < crit_chance
	if crit and Run.amulet_count("papillon") > 0:
		fly_n = mini(10, fly_n + 1)
		fly_t = 3.0
	if Run.amulet_count("autographe") > 0:
		if e.is_boss and crit:
			dmg *= 2.0
		elif not e.is_boss:
			dmg *= 0.92
	if crit:
		# Cutter : ses critiques grandissent avec le taux de critique
		dmg *= maxf(s.crit_mult, 2.0 + crit_chance / 35.0) if scale == "crit" else s.crit_mult
	dmg = maxf(1.0, dmg)
	if Run.amulet_count("estompe") > 0:
		e.slow_t = maxf(e.slow_t, 0.8)
	e.hurt(dmg, crit, dir * knock)
	# Ciseaux : exécution sous 25 % des PV (pas les boss)
	if wst.get("style", "") == "scissors" and not e.dead and not e.is_boss and e.hp < e.max_hp * 0.25:
		_slash(e.position)
		float_text(e.position + Vector2(0, -12), "TRANCHÉ !", Pal.TEXT)
		e.hurt(e.hp + 1.0, true, Vector2.ZERO)
	var craq := Run.amulet_count("craquelure")
	if crit and craq > 0:
		explosion(e.position, boom(26.0), Color(Pal.ACCENT, 0.6), true)
		for o in near(e.position, boom(26.0)):
			if o != e:
				o.hurt(boom_dmg(dmg * 0.4 * craq), false, (o.position - e.position).normalized() * 40.0)
	Sfx.play("hit")
	# Vol de vie (Pipette : ×3 + 5 %) ; au-delà de 100 %, plusieurs PV par coup
	var ls := Stats.lifesteal_of(scale) / 100.0
	var heal := floorf(ls) + (1.0 if randf() < ls - floorf(ls) else 0.0)
	if heal > 0.0:
		var cal := Run.amulet_count("calice")
		if cal > 0:
			heal *= maxf(1.0, dmg * 0.02 * cal)   # Calice : 2 % des dégâts du coup
		player.heal(heal, true, true)
	_procs(e, dmg, wst)


func _procs(e: Enemy, dmg: float, wst: Dictionary) -> void:
	# Crayon de couleur (élément de ton perso) et Kaléidoscope (couleur suivante du cycle)
	var dom := int(Run.char_a.get("dominant", 0))
	if dom > 0 and randf() < 0.1 * Run.amulet_count("crayon_couleur"):
		_apply_el(e, dom, dmg)
	if Run.amulet_count("kaleidoscope") > 0:
		kal_i += 1
		if randf() < 0.2:
			_apply_el(e, 1 + kal_i % (Pal.COUNT - 1), dmg)
	var frac: Array = wst.get("frac", [])
	if frac.is_empty():
		return
	var power: float = 1.0 + Run.stats.el_power / 100.0
	var bonus := 0.15 * Run.amulet_count("arc_en_ciel")
	if wst.get("scale", "") == "luck":
		bonus += maxf(0.0, Run.stats.luck) * 0.004   # Compte-gouttes : la chance donne des effets
	for el in range(1, Pal.COUNT):
		var chance: float = frac[el] * power + bonus
		if chance <= 0.0:
			continue
		if el == e.element:
			chance *= 0.3   # un ennemi résiste à son propre élément
		if randf() >= chance:
			continue
		_apply_el(e, el, dmg)


## Effet élémentaire sur un ennemi (brûlure, gel, chaîne, poison, marque, éclat).
func _apply_el(e: Enemy, el: int, dmg: float, spread := true) -> void:
	if e.dead:
		return
	e.el_seen[el] = true   # Cercle chromatique
	# Alchimie : l'effet se propage à l'ennemi le plus proche (50 %)
	if spread and Run.amulet_count("alchimie") > 0 and randf() < 0.5:
		var best: Enemy = null
		var bd := 100.0
		for o in near(e.position, 100.0):
			if o != e and not o.dead and o.position.distance_to(e.position) < bd:
				bd = o.position.distance_to(e.position)
				best = o
		if best:
			_apply_el(best, el, dmg, false)
	if true:
		match el:
			Pal.FEU:
				e.burn(maxf(1.0, dmg * 0.25))
			Pal.GLACE:
				e.chill_hit()
			Pal.FOUDRE:
				_chain(e, dmg * 0.5)
			Pal.POISON:
				e.add_poison()
			Pal.ARCANE:
				e.mark()
				if randf() < 0.3:
					player.heal(1.0)
			Pal.LUMIERE:
				var lr := boom(34.0 * (1.0 + 0.5 * Run.amulet_count("vitrail")))   # Vitrail : +50 % de rayon
				var au := Run.amulet_count("aureole")
				explosion(e.position, lr, Color(1, 1, 0.9, 0.9))
				if au > 0:
					player.heal(1.0 * au)   # Auréole
				for o in near(e.position, lr):
					if au > 0:
						o.blind_t = maxf(o.blind_t, 1.0)
					if o != e:
						o.hurt(boom_dmg(dmg * 0.4), false, (o.position - e.position).normalized() * 60.0, Pal.LUMIERE)


func _chain(from: Enemy, dmg: float) -> void:
	var boosted := syn.has(Pal.FOUDRE)   # synergie Foudre : chaînes plus longues
	var cands := near(from.position, 130.0 if boosted else 90.0).filter(func(o): return o != from)
	cands.sort_custom(func(a, b): return a.position.distance_squared_to(from.position) < b.position.distance_squared_to(from.position))
	var prev := from.position
	for i in mini((4 if boosted else 2) + 2 * Run.amulet_count("paratonnerre"), cands.size()):
		var o: Enemy = cands[i]
		_bolt(prev, o.position)
		prev = o.position
		o.hurt(dmg, false, Vector2.ZERO, Pal.FOUDRE)
	if cands.size() > 0:
		Sfx.play("zap")
		if Run.amulet_count("dynamo") > 0:
			chain_log.append(elapsed)


func kill_enemy(e: Enemy) -> void:
	if e.dead:
		return
	e.dead = true
	Run.kills += 1
	if e.elite:
		Run.elite_kills += 1
	if e.is_boss:
		Run.boss_ids[e.id] = true
	Sfx.play("kill")
	var col: Color = Pal.main_color(e.element) if e.element > 0 else Pal.SHADES[0][1]
	_splat(e.position, e.radius, col)
	# Éclaboussure d'encre (plus grosse pour les élites et les boss)
	var big := e.is_boss or e.elite
	burst(e.position, col, 40 if e.is_boss else (18 if e.elite else 8), 150.0 if big else 90.0)
	burst(e.position, Pal.INK, 12 if big else 3, 70.0)
	if big:
		hitstop(0.25 if e.is_boss else 0.07)
	# Butin
	# L'XP suit le butin de l'ennemi ; l'or en est une fraction (Run.GOLD_MULT).
	var total := roundi(e.loot * randf_range(0.8, 1.25))
	if total == 0 and randf() < e.loot:
		total = 1
	while total > 0:
		var v := mini(total, 5 if e.is_boss else randi_range(1, 2))
		total -= v
		var pk := Pickup.new()
		pk.xp = v
		# Arrondi au hasard : 0.6 or = 60% de chances d'avoir 1 pièce (jamais bloqué à 0)
		var g: float = v * Run.GOLD_MULT * pow(0.85, Run.amulet_count("restauration"))
		g *= 1.0 + 0.15 * Run.amulet_count("aimant_pepites")
		if e.elite:
			g *= 1.0 + Run.amulet_count("cachet_cire")
		pk.value = floori(g) + (1 if randf() < g - floorf(g) else 0)
		pk.color = Pal.ACCENT
		pk.position = e.position + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		pk.vel = Vector2.from_angle(randf() * TAU) * randf_range(20, 90 if e.is_boss else 50)
		loot_layer.add_child(pk)
		pickups.append(pk)
	# Synergie Glace : un ennemi gelé (ou ralenti) éclate en éclats de glace
	if syn.has(Pal.GLACE) and (e.freeze_t > 0.0 or e.slow_t > 0.0):
		for k in 6:
			var shard := spawn_bullet(e.position, Vector2.from_angle(TAU * k / 6.0 + randf() * 0.3) * 230.0,
				{"damage": 4.0 + Run.wave * 1.5, "radius": 3.0, "pierce": 1}, {"frac": []}, _dot(Pal.GLACE), "", 0.45)
			shard.spin = 10.0
	# Synergie Poison : un ennemi empoisonné laisse un nuage toxique
	if syn.has(Pal.POISON) and e.poison > 0:
		clouds.append({"pos": e.position, "r": 30.0, "t": 2.5, "acc": 0.0, "dps": 3.0 + Run.wave})
	# Encre de Chine : un marqué qui meurt éclabousse ses voisins (qui sont marqués à leur tour)
	if e.ink_t > 0.0:
		var n := 0
		burst(e.position, Pal.INK, 12, 110.0)
		for o in near(e.position, 52.0):
			if o == e or o.dead or n >= 12:
				continue
			n += 1
			o.ink_t = 4.0
			o.ink_dmg = e.ink_dmg
			o.queue_redraw()
			o.hurt(e.ink_dmg, false, (o.position - e.position).normalized() * 50.0)
	# Retouche : 15 % de chances de redessiner l'ennemi tué dans ton camp
	if Run.weapon_count("retouche") > 0 and not e.is_boss and not e.small and randf() < 0.15:
		var aid: String = e.id
		var apos: Vector2 = e.position
		var ael: bool = e.elite
		_after(0.05, func(): spawn_ally(aid, apos, ael))   # (l'ennemi mort est déjà effacé)
	# Braise : un ennemi qui meurt en brûlant explose et enflamme ses voisins
	if e.burn_ticks > 0 and Run.amulet_count("braise") > 0:
		explosion(e.position, boom(40.0), Color(Pal.main_color(Pal.FEU), 0.8), true)
		burst(e.position, Pal.main_color(Pal.FEU), 12, 110.0)
		for o in near(e.position, boom(40.0)):
			if o != e and not o.dead:
				o.burn(e.burn_dmg)
				o.hurt(e.burn_dmg * 2.0 * Run.amulet_count("braise"), false, (o.position - e.position).normalized() * 50.0, Pal.FEU)
	# Pentacle : tuer un marqué soigne et transfère la marque
	if e.mark_t > 0.0 and Run.amulet_count("pentacle") > 0:
		player.heal(2.0 * Run.amulet_count("pentacle"))
		var nb: Enemy = null
		var nd := 150.0
		for o in near(e.position, 150.0):
			if o != e and not o.dead and o.position.distance_to(e.position) < nd:
				nd = o.position.distance_to(e.position)
				nb = o
		if nb:
			nb.mark()
			_bolt(e.position, nb.position)
	# Pinceau de Midas : +1 or par ennemi tué
	Run.gold += Run.amulet_count("midas")
	# Bulle de soin : goutte qui soigne
	if randf() < 0.08 * Run.amulet_count("bulle_soin"):
		var hp := Pickup.new()
		hp.heal = 3.0
		hp.xp = 0
		hp.value = 0
		hp.color = Pal.GOOD
		hp.position = e.position
		hp.vel = Vector2.from_angle(randf() * TAU) * 40.0
		loot_layer.add_child(hp)
		pickups.append(hp)
	# Nuit étoilée : un ennemi tué sur 10 fait tomber une étoile
	if Run.amulet_count("nuit_etoilee") > 0:
		star_kills += 1
		if star_kills % 10 == 0:
			var spos: Vector2 = e.position
			_after(0.35, func(): _star(spos))
	# Sanguine : soin sur élimination
	if randf() < 0.12 * Run.amulet_count("sanguine"):
		player.heal(1.0)
	# Scinde : se divise
	if e.def.beh == "mirror" and not e.small:
		for k in 2:
			spawn_enemy_now(e.id, e.position + Vector2(k * 12 - 6, randf_range(-4, 4)), true)
	# Amulette Rature : explosion
	var rat := Run.amulet_count("rature")
	if rat > 0 and not e.is_boss and randf() < 0.08 * rat:
		explosion(e.position, boom(42.0), Color(Pal.INK, 0.8))
		for o in near(e.position, boom(42.0)):
			if o != e:
				o.hurt(boom_dmg(8.0 + Run.wave * 3.0), false, (o.position - e.position).normalized() * 80.0)
	enemies.erase(e)
	e.queue_free()
	if e.is_boss:
		Run.bosses += 1
		boss = null
		shake(10.0)
		explosion(e.position, 80.0, Color(Pal.ACCENT, 0.9))
		if e.id == boss_id:
			_end_wave()


func collect(p: Pickup) -> void:
	if p.heal > 0.0:
		player.heal(p.heal)
	Run.gold += p.value
	Sfx.play("pickup", 0.2)
	if p.value > 0:
		burst(p.position, Pal.ACCENT, 2, 40.0)
	Run.hp = player.hp
	var lv := Run.add_xp(p.xp)
	if lv > 0 and Run.amulet_count("pansement") > 0:
		player.heal(5.0 * lv * Run.amulet_count("pansement"))
	if lv > 0:
		player.st = Run.stats
		player.hp = Run.hp
		player.refresh_max_hp()
		Sfx.play("level")
		numbers.add(player.position + Vector2(0, -24), "NIVEAU %d !" % Run.level, Pal.GOOD, 1.6)
		explosion(player.position, 46.0, Color(Pal.GOOD, 0.9), true)
		burst(player.position, Pal.GOOD, 20, 120.0)
		burst(player.position, Pal.ACCENT, 12, 90.0)


func player_died() -> void:
	if ended:
		return
	ended = true
	Sfx.play("lose")
	hud.announce("TU AS ÉTÉ EFFACÉ...", Pal.BAD)
	shake(8.0)
	_after(2.2, func(): done.emit("dead"))


func _end_wave() -> void:
	if ended:
		return
	ended = true
	if Run.wave_dmg > 0.0:
		Run.wave_dmg = 0.0   # l'étoile du grattage ne dure qu'une vague
		Run.recompute()
	# Les gouttes restantes s'envolent vers le joueur (voir _tick_vacuum)
	vacuum = not pickups.is_empty()
	var far := 1.0
	for p in pickups:
		far = maxf(far, p.position.distance_to(player.position))
	for p in pickups:
		p.vac = 0.0
		# les plus proches partent d'abord : une vague qui converge vers le perso
		p.vac_delay = 0.12 + 0.3 * p.position.distance_to(player.position) / far + randf() * 0.08
	for e in enemies:
		e.dead = true
		_splat(e.position, e.radius, Pal.SHADES[0][2])
		e.queue_free()
	enemies.clear()
	for b in bullets:
		b.queue_free()
	bullets.clear()
	telegraphs.clear()
	hazards.clear()
	lobs.clear()
	rulers.clear()
	erasers.clear()
	clouds.clear()
	wells.clear()
	stop_t = 0.0
	for a in allies:
		a.queue_free()
	allies.clear()
	Run.hp = player.hp
	# La Joconde : une vague sans une égratignure = +12% dégâts pour la partie
	if Run.amulet_count("joconde") > 0:
		Run.joconde += Run.amulet_count("joconde")
		numbers.add(player.position + Vector2(0, -34), "LA JOCONDE SOURIT : +12% DÉGÂTS", Pal.ACCENT, 2.0)
	Run.end_wave()
	Meta.check_achievements(Run.achievement_ctx(Run.wave, not player.was_hurt, Run.wave == Run.WAVES))
	hud.announce("VAGUE %d TERMINÉE !" % Run.wave, Pal.GOOD)
	Sfx.play("win" if Run.wave == Run.WAVES else "wave")
	_after(1.8, func():
		_flush_pickups()
		done.emit("cleared"))


# ------------------------------------------------------------------ Encre au sol, cloches, règles, gommes

func _tick_vacuum(delta: float) -> void:
	var keep: Array[Pickup] = []
	for p in pickups:
		if p.vacuum(delta, self):
			keep.append(p)
		else:
			p.queue_free()
	pickups = keep
	sparks.tick(delta)
	if pickups.is_empty():
		vacuum = false


## Sécurité : tout ce qui n'est pas encore arrivé est compté avant de quitter la vague.
func _flush_pickups() -> void:
	for p in pickups:
		collect(p)
		p.queue_free()
	pickups.clear()
	vacuum = false


func add_hazard(pos: Vector2, r: float, life: float, slow: float, dmg: float, col: Color) -> void:
	if hazards.size() > 600:
		hazards.pop_front()
	hazards.append({"pos": pos, "r": r, "t": life, "life": life, "slow": slow, "dmg": dmg, "col": col})


## Effet des flaques sur un cercle : [multiplicateur de vitesse, dégâts, élément]
func hazard_effect(pos: Vector2, r: float) -> Array:
	var slow := 1.0
	var dmg := 0.0
	for h in hazards:
		var rr: float = h.r + r * 0.5
		if pos.distance_squared_to(h.pos) <= rr * rr:
			slow = minf(slow, h.slow)
			dmg = maxf(dmg, h.dmg)
	return [slow, dmg]


## Tir en cloche : un pâté d'encre part de src et retombe sur `to` après `dur` secondes.
func lob(src: Enemy, to: Vector2, dur: float, r := 22.0) -> void:
	var tex: Texture2D = _dot(src.element)
	if Run.eproj_art.has(src.id):
		if not eproj_tex.has(src.id):
			eproj_tex[src.id] = Gfx.texture(Analyzer.trim(Run.eproj_art[src.id].image))
		tex = eproj_tex[src.id]
	lobs.append({"from": src.position, "to": to, "t": 0.0, "dur": dur, "dmg": src.dmg, "r": r,
		"el": src.element, "tex": tex, "col": src.ink_col})
	Sfx.play("enemy_shot")


func add_ruler(a: Vector2, b: Vector2, life: float) -> void:
	rulers.append({"a": a, "b": b, "t": life, "life": life})


## Raturé : une ligne annoncée à la règle pendant « delay », puis un trait d'encre qui brûle
## (boom > 0 : explosion au point a, pour le centre d'une croix).
func add_stroke(a: Vector2, b: Vector2, delay: float, dmg: float, col: Color, boom_r := 0.0) -> void:
	add_ruler(a, b, delay)
	strokes.append({"a": a, "b": b, "t": delay, "dmg": dmg, "col": col, "boom": boom_r})


func add_eraser(pos: Vector2, r: float, dur: float, dmg: float) -> void:
	erasers.append({"pos": pos, "r": r, "t": 0.0, "dur": dur, "dmg": dmg})


func _tick_effects(delta: float) -> void:
	for h in hazards:
		h.t -= delta
	hazards = hazards.filter(func(h): return h.t > 0.0)
	for rl in rulers:
		rl.t -= delta
	rulers = rulers.filter(func(rl): return rl.t > 0.0)
	var sk := []
	for sk_i in strokes:
		sk_i.t -= delta
		if sk_i.t > 0.0:
			sk.append(sk_i)
			continue
		var len_s: float = sk_i.a.distance_to(sk_i.b)
		var n := maxi(1, int(len_s / 9.0))
		for k in n + 1:
			add_hazard(sk_i.a.lerp(sk_i.b, float(k) / n), 7.0, 1.4, 1.0, sk_i.dmg, sk_i.col)
		if sk_i.boom > 0.0:
			explosion(sk_i.a, sk_i.boom, Color(sk_i.col, 0.8))
			if sk_i.a.distance_to(player.position) < sk_i.boom + player.radius:
				player.take_hit(sk_i.dmg * 2.5, 0, null)
	strokes = sk
	var keep := []
	for lb in lobs:
		lb.t += delta
		if lb.t < lb.dur:
			keep.append(lb)
			continue
		# Atterrissage
		explosion(lb.to, lb.r, Color(lb.col, 0.7))
		if lb.to.distance_to(player.position) < lb.r + player.radius:
			player.take_hit(lb.dmg, lb.el, null)
		add_hazard(lb.to, lb.r * 0.7, 3.0, 0.5, 0.0, lb.col)
	lobs = keep
	keep = []
	for er in erasers:
		er.t += delta
		if er.t < er.dur:
			keep.append(er)
			continue
		explosion(er.pos, er.r, Color(1, 1, 1, 0.9))
		if er.pos.distance_to(player.position) < er.r + player.radius:
			player.take_hit(er.dmg, 0, null)
			player.erase_at(player.position + (er.pos - player.position) * 0.5)
	erasers = keep
	keep = []
	for g in telegraphs_fx:
		g.t -= delta
	telegraphs_fx = telegraphs_fx.filter(func(g): return g.t > 0.0)
	for cl in clouds:
		cl.t -= delta
		cl.acc += delta
		if cl.acc >= 0.5:
			cl.acc = 0.0
			for e in near(cl.pos, cl.r):
				e.hurt(cl.dps * 0.5, false, Vector2.ZERO, int(cl.get("el", Pal.POISON)))
		if cl.t > 0.0:
			keep.append(cl)
	clouds = keep


# ------------------------------------------------------------------ Effets

# ------------------------------------------------------------------ Le Tableau noir : événements et attaques

func _tick_board(delta: float) -> void:
	rush_t -= delta
	dark_t -= delta
	# Événements (vagues normales du Tableau noir)
	if MapDB.get_def(Run.map).get("events", false) and boss_id == "" and not ended:
		ev_cd -= delta
		if ev_cd <= 0.0:
			ev_cd = randf_range(11.0, 15.0)
			_board_event()
	var p := player
	# Éponge : annoncée, puis balaie toute une bande
	var keep := []
	for sp in sponges:
		sp.t += delta
		if sp.t > sp.tele:
			var k: float = (sp.t - sp.tele) / sp.dur
			var along: float = lerpf(-40.0, (W if sp.horiz else H) + 40.0, k)
			var pos := Vector2(along, sp.c) if sp.horiz else Vector2(sp.c, along)
			sp.pos = pos
			var rect := Rect2(pos - Vector2(30, 36), Vector2(60, 72)) if sp.horiz else Rect2(pos - Vector2(36, 30), Vector2(72, 60))
			if rect.has_point(p.position) and not sp.hit.has(-1):
				sp.hit[-1] = true
				p.take_hit(4.0 + Run.wave * 0.6, 0, null)
			for e in near(pos, 50.0):
				if rect.has_point(e.position) and not sp.hit.has(e.get_instance_id()):
					sp.hit[e.get_instance_id()] = true
					if not e.is_boss:
						e.hurt(e.max_hp * 0.3, false, Vector2.ZERO)
			hazards = hazards.filter(func(h): return not rect.grow(8).has_point(h.pos))
		if sp.t < sp.tele + sp.dur:
			keep.append(sp)
	sponges = keep
	# Pluie de craies
	keep = []
	for ch in chalks:
		ch.t -= delta
		if ch.t > 0.0:
			keep.append(ch)
			continue
		explosion(ch.pos, ch.r, Color(1, 1, 1, 0.8), true)
		burst(ch.pos, Color.WHITE, 8, 90.0)
		if ch.pos.distance_to(p.position) < ch.r + p.radius:
			p.take_hit(ch.dmg, 0, null)
		for e in near(ch.pos, ch.r):
			e.hurt(10.0 + Run.wave * 2.0, false, (e.position - ch.pos).normalized() * 60.0)
		add_hazard(ch.pos, ch.r * 0.8, 3.0, 0.6, 0.0, Color(0.9, 0.92, 0.9))
	chalks = keep
	# Bons points
	keep = []
	for st in stars:
		st.t -= delta
		if st.pos.distance_to(p.position) < 12.0 + p.radius:
			var g := 5 + Run.wave * 2
			Run.gold += g
			p.heal(3.0)
			burst(st.pos, Pal.ACCENT, 20, 110.0)
			float_text(st.pos + Vector2(0, -12), "BON POINT ! +%d or" % g, Pal.ACCENT)
			Sfx.play("level")
			continue
		if st.t > 0.0:
			keep.append(st)
	stars = keep
	# Tampon encreur : le carré s'imprime
	keep = []
	for sq in squares:
		sq.t += delta
		if sq.t < sq.dur:
			keep.append(sq)
			continue
		var r := Rect2(sq.pos - Vector2(sq.half, sq.half), Vector2(sq.half, sq.half) * 2.0)
		if r.grow(p.radius).has_point(p.position):
			p.take_hit(sq.dmg, 0, null)
		shake(3.0)
		burst(sq.pos, sq.col, 14, 100.0)
		_splat(sq.pos, sq.half * 0.7, sq.col)
	squares = keep
	# Interro du Professeur : les mauvaises colonnes explosent
	keep = []
	for qz in quizzes:
		qz.t += delta
		if qz.t < qz.dur:
			keep.append(qz)
			continue
		var n: int = qz.cols
		var cw := float(W) / n
		for i in n:
			if i == qz.safe:
				float_text(Vector2(cw * (i + 0.5), 40), "BONNE RÉPONSE : %d" % qz.answers[i], Pal.GOOD)
				continue
			for k in 4:
				explosion(Vector2(cw * (i + 0.5), H * (k + 0.5) / 4.0), cw * 0.45, Color(Pal.BAD, 0.6), k > 0)
			if p.position.x >= cw * i and p.position.x < cw * (i + 1):
				p.take_hit(qz.dmg, 0, null)
		shake(6.0)
	quizzes = keep
	# Scanner de la Photocopieuse : une ligne qui descend
	keep = []
	for sc in scans:
		sc.t += delta
		if sc.t > sc.tele:
			sc.y = lerpf(0.0, float(H), (sc.t - sc.tele) / sc.dur)
			if absf(p.position.y - sc.y) < p.radius + 3.0 and not sc.hit:
				sc.hit = true
				p.take_hit(sc.dmg, 0, null)
		if sc.t < sc.tele + sc.dur:
			keep.append(sc)
	scans = keep


func _board_event() -> void:
	var p := player
	match ["sponge", "chalk"].pick_random():
		"sponge":
			var horiz := randf() < 0.5
			var c := (p.position.y if horiz else p.position.x) + randf_range(-40.0, 40.0)
			sponges.append({"horiz": horiz, "c": clampf(c, 40.0, (H if horiz else W) - 40.0), "t": 0.0, "tele": 1.6, "dur": 1.3, "hit": {}, "pos": Vector2.ZERO})
			hud.announce("COUP D'ÉPONGE !", Pal.TEXT)
		"chalk":
			for i in 7:
				var pos := p.position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 50.0) if i < 2 else _spawn_pos(0.0)
				chalks.append({"pos": pos, "r": 20.0, "t": 1.2 + i * 0.15, "dmg": 3.0 + Run.wave * 0.5})
			hud.announce("PLUIE DE CRAIES !", Pal.TEXT)
		"bell":
			rush_t = 5.0
			shake(4.0)
			hud.announce("DRIIIIING !", Pal.BAD)
			Sfx.play("boss")
		"star":
			stars.append({"pos": _spawn_pos(100.0), "t": 7.0})
			hud.announce("UN BON POINT À GAGNER !", Pal.ACCENT)


# ------------------------------------------------------------------ Armes épiques / légendaires

# ------------------------------------------------------------------ Amulettes

## Minuteries des amulettes (Papillon, Seiche, Lanterne) et foule autour du joueur.
func _tick_amulets(delta: float) -> void:
	# Chauve-souris : PV soignés ces 5 dernières secondes ; Dynamo : chaînes ces 5 dernières secondes
	if not bat_log.is_empty():
		bat_log = bat_log.filter(func(b): return elapsed - b[0] < 5.0)
		bat_sum = 0.0
		for b in bat_log:
			bat_sum += b[1]
	else:
		bat_sum = 0.0
	if not chain_log.is_empty():
		chain_log = chain_log.filter(func(t): return elapsed - t < 5.0)
	fly_t -= delta
	if fly_t <= 0.0:
		fly_n = 0
	squid_cd -= delta
	lure_t -= delta
	if Run.amulet_count("papier_verre") > 0:
		crowd = near(player.position, 70.0).size()
	if Run.amulet_count("lanterne") > 0:
		lure_cd -= delta
		if lure_cd <= 0.0:
			lure_cd = 15.0
			lure_t = 3.0
			lure_pos = player.position
			var s := Sprite2D.new()
			s.texture = player.ptex
			s.position = player.position + player.sprite.position + player.sprite.texture.get_size() / 2.0
			s.modulate = Color(1, 1, 1, 0.55)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			fx.add_child(s)
			var tw := s.create_tween()
			tw.tween_interval(2.6)
			tw.tween_property(s, "modulate:a", 0.0, 0.4)
			tw.tween_callback(s.queue_free)
			float_text(player.position + Vector2(0, -26), "LEURRE !", Pal.ACCENT)


## Chauve-souris : note un soin reçu.
func bat_heal(amount: float) -> void:
	if Run.amulet_count("chauve_souris") > 0 and amount > 0.0:
		bat_log.append([elapsed, amount])


## Dynamo : bonus de vitesse d'attaque (0 à 0,4).
func dynamo_bonus() -> float:
	return minf(0.4, 0.02 * chain_log.size()) * Run.amulet_count("dynamo")


## Oursin : 6 épines d'encre autour du joueur.
func urchin(pos: Vector2, dmg: float) -> void:
	for k in 6:
		var p := spawn_bullet(pos, Vector2.from_angle(TAU * k / 6.0) * 260.0, {"damage": dmg, "radius": 3.0, "pierce": 1},
			{"frac": []}, _dot(0), "", 0.45)
		p.spin = 12.0


## Champignon : nuage toxique qui contamine les voisins.
func toxic_burst(e: Enemy) -> void:
	clouds.append({"pos": e.position, "r": 36.0, "t": 3.0, "acc": 0.0, "dps": 3.0 + Run.wave})
	burst(e.position, Pal.main_color(Pal.POISON), 14, 90.0)
	for o in near(e.position, 50.0):
		if o != e and not o.dead:
			o.poison += 2
			o.poison_t = 4.0


## Où les ennemis visent : le joueur, ou le leurre de la Lanterne magique.
func target_pos() -> Vector2:
	return lure_pos if lure_t > 0.0 else player.position


## Multiplicateur de dégâts des amulettes conditionnelles.
func _amulet_dmg_mult(e: Enemy, wst: Dictionary) -> float:
	var m := 1.0
	var kind: String = wst.get("kind", "")
	var sp := Run.amulet_count("spatule")
	var vi := Run.amulet_count("viseur")
	if kind == "melee":
		m *= (1.0 + 0.12 * sp) * pow(0.92, vi)
	elif kind == "ranged":
		m *= (1.0 + 0.12 * vi) * pow(0.92, sp)
	var ca := Run.amulet_count("cadran_solaire")
	if ca > 0:
		var late := elapsed > (wave_len * 0.5 if wave_len > 0.0 else 30.0)
		m *= (1.0 + 0.2 * ca) if late else pow(0.95, ca)
	if e.freeze_t > 0.0:
		m *= 1.0 + 0.5 * Run.amulet_count("stalactite")   # Stalactite : gelés ×1,5
	var cs := Run.amulet_count("chauve_souris")
	if cs > 0:
		m *= 1.0 + minf(0.3, 0.01 * bat_sum) * cs
	var cc := Run.amulet_count("cercle_chromatique")
	if cc > 0:
		m *= 1.0 + 0.15 * e.el_seen.size() * cc
	var pv := Run.amulet_count("papier_verre")
	if pv > 0:
		m *= 1.0 + minf(0.3, 0.03 * crowd) * pv
	if Run.amulet_count("derniere_touche") > 0 and player.hp < player.max_hp * 0.25:
		m *= 2.0
	if player.shadow_ready:
		player.shadow_ready = false
		m *= 2.0   # Ombre portée
	return m


## Nuit étoilée : une étoile tombe et explose.
func _star(pos: Vector2) -> void:
	if ended:
		return
	var sr := boom(60.0)
	explosion(pos, sr, Color(Pal.ACCENT, 0.9))
	burst(pos, Pal.ACCENT, 16, 120.0)
	var d: float = boom_dmg((12.0 + Run.wave * 4.0) * (1.0 + Run.stats.dmg / 100.0))
	for o in near(pos, sr):
		o.hurt(d, false, (o.position - pos).normalized() * 80.0)


## Mise en abyme : le projectile qui touche se divise en 2 petits projectiles.
func split_bullet(p: Projectile) -> void:
	if bullets.size() > 400:
		return
	for k in [-0.6, 0.6]:
		var c := spawn_bullet(p.position, p.vel.rotated(k) * 0.9, {"damage": p.dmg * 0.4, "radius": maxf(2.0, p.radius * 0.6), "pierce": 0},
			p.wst, p.tex, p.fx, 0.5, p.outline_on)
		c.child = true
		c.bounces = 0
		c.hit_ids = p.hit_ids.duplicate()
		c.scale = Vector2(0.6, 0.6)


## Encre de seiche : nuage qui aveugle les ennemis proches.
func squid_cloud(pos: Vector2) -> void:
	if squid_cd > 0.0 or Run.amulet_count("encre_seiche") == 0:
		return
	squid_cd = 15.0
	explosion(pos, 90.0, Color(Pal.INK, 0.8))
	burst(pos, Pal.INK, 30, 120.0)
	for o in near(pos, 90.0):
		o.blind_t = 2.0
	float_text(pos + Vector2(0, -26), "ENCRE DE SEICHE !", Pal.TEXT)


## Agrafeuse : relie cet ennemi au précédent agrafé (s'il est encore là et pas trop loin).
func _staple(e: Enemy) -> void:
	if is_instance_valid(staple_last) and staple_last != e and not staple_last.dead and staple_last.position.distance_to(e.position) < 160.0:
		e.staple = staple_last
		e.staple_t = 4.0
		staple_last.staple = e
		staple_last.staple_t = 4.0
	staple_last = e


## Ciseaux : un X blanc sur l'ennemi tranché.
func _slash(pos: Vector2) -> void:
	for k in [-1.0, 1.0]:
		var l := Line2D.new()
		l.width = 2.0
		l.default_color = Color(1, 1, 1, 0.95)
		l.add_point(pos + Vector2(-10, -10 * k))
		l.add_point(pos + Vector2(10, 10 * k))
		fx.add_child(l)
		var tw := l.create_tween()
		tw.tween_property(l, "modulate:a", 0.0, 0.25)
		tw.tween_callback(l.queue_free)


## Retouche : un ennemi redessiné dans ton camp pendant 10 s.
func spawn_ally(id: String, pos: Vector2, elite := false) -> void:
	if ended or not Run.enemy_art.has(id) or allies.size() >= 8:
		return
	var a := Enemy.new()
	a.position = pos
	world.add_child(a)
	a.setup(self, id, false, elite)
	a.ally = true
	a.ally_t = 10.0
	a.contact = false
	allies.append(a)
	burst(pos, Pal.GOOD, 14, 90.0)
	float_text(pos + Vector2(0, -16), "REDESSINÉ !", Pal.GOOD)


func remove_ally(a: Enemy) -> void:
	allies.erase(a)
	burst(a.position, Pal.GOOD, 8, 60.0)
	a.queue_free()


## Point final : un point noir qui aspire puis implose.
func add_well(pos: Vector2, r: float, dmg: float, wst: Dictionary) -> void:
	wells.append({"pos": pos, "t": 0.0, "dur": 1.2, "r": r, "dmg": dmg, "wst": wst})


func _tick_wells(delta: float) -> void:
	var keep := []
	for w in wells:
		w.t += delta
		for e in near(w.pos, w.r):
			if e.is_boss:
				continue
			var to: Vector2 = w.pos - e.position
			var pull := 90.0 * (0.3 if e.def.get("heavy", false) else 1.0)
			e.position += to.normalized() * minf(to.length(), pull * delta)
		if w.t < w.dur:
			keep.append(w)
			continue
		explosion(w.pos, boom(w.r * 0.8), Color(Pal.INK, 0.9))
		burst(w.pos, Pal.INK, 24, 140.0)
		for e in near(w.pos, boom(w.r * 0.8)):
			hit_enemy(e, boom_dmg(w.dmg), w.wst, (e.position - w.pos).normalized(), 120.0)
	wells = keep


## Grande Signature : un trait cursif géant qui traverse l'écran.
func signature(y: float, dmg: float, wst: Dictionary) -> void:
	var pts := PackedVector2Array()
	var phase := randf() * TAU
	var x := -10.0
	while x <= W + 10:
		var loop := sin(x * 0.045 + phase) * 14.0 + sin(x * 0.11 + phase * 2.0) * 5.0
		pts.append(Vector2(x, clampf(y + loop, 10.0, H - 10.0)))
		x += 14.0
	var l := Line2D.new()
	l.points = pts
	l.width = 7.0
	l.default_color = Color(Pal.INK, 0.9)
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
	shake(4.0)
	Sfx.play("swing")
	for e in enemies.duplicate():
		if e.dead:
			continue
		for i in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(e.position, pts[i], pts[i + 1]).distance_to(e.position) < e.radius + 14.0:
				hit_enemy(e, dmg, wst, Vector2.UP, 40.0)
				break


func add_square(pos: Vector2, half: float, dur: float, dmg: float, col: Color) -> void:
	squares.append({"pos": pos, "half": half, "t": 0.0, "dur": dur, "dmg": dmg, "col": col})


## Interro : une question (calcul) en haut de l'écran, le tableau découpé en n colonnes qui
## portent chacune une réponse. Seule la colonne de la BONNE réponse n'explose pas :
## rien n'est laissé au hasard, il suffit de calculer vite et d'y aller.
func quiz(n: int, dmg: float) -> void:
	var hard := n >= 4
	var q := ""
	var good := 0
	match randi() % (3 if hard else 2):
		0:
			var a := randi_range(3, 12 if hard else 9)
			var b := randi_range(2, 12 if hard else 9)
			q = "%d + %d" % [a, b]
			good = a + b
		1:
			var a := randi_range(8, 20 if hard else 15)
			var b := randi_range(2, a - 1)
			q = "%d - %d" % [a, b]
			good = a - b
		_:
			var a := randi_range(2, 9)
			var b := randi_range(2, 9)
			q = "%d × %d" % [a, b]
			good = a * b
	# Mauvaises réponses proches de la bonne (il faut vraiment calculer)
	var answers := [good]
	var offsets := [-3, -2, -1, 1, 2, 3]
	offsets.shuffle()
	for o in offsets:
		if answers.size() >= n:
			break
		if good + o > 0:
			answers.append(good + o)
	answers.shuffle()
	quizzes.append({"cols": n, "safe": answers.find(good), "answers": answers, "question": q + " = ?",
		"t": 0.0, "dur": 2.8 if hard else 3.2, "dmg": dmg})
	hud.announce("INTERRO SURPRISE !", Pal.ACCENT)
	Sfx.play("zap")


## Scanner : une ligne annoncée en haut, puis qui descend tout l'écran.
func scan(dmg: float) -> void:
	scans.append({"y": 0.0, "t": 0.0, "tele": 1.0, "dur": 2.4, "dmg": dmg, "hit": false})


## Copie d'une salve, tirée un peu plus tard depuis `pos` (côté opposé de la page).
func ghost_volley(src: Enemy, pos: Vector2, n: int, step: float, delay: float) -> void:
	telegraphs_fx.append({"pos": pos, "t": delay})
	_after(delay, func():
		if ended or not is_instance_valid(src) or src.dead:
			return
		var d := (player.position - pos).normalized()
		for k in n:
			spawn_enemy_bullet(src, pos, d.rotated((k - (n - 1) / 2.0) * step) * 126.0)
		burst(pos, Color.WHITE, 10, 80.0))


func player_vel() -> Vector2:
	return player.vel if player else Vector2.ZERO


func darkness(sec: float) -> void:
	dark_t = sec


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)


## Fige le jeu un court instant (impact).
func hitstop(sec: float) -> void:
	hitstop_t = maxf(hitstop_t, sec)


## Gerbe de particules (pixels d'encre).
func burst(pos: Vector2, col: Color, n: int, speed := 80.0, dir := Vector2.ZERO, spread := PI) -> void:
	sparks.emit(pos, col, n, speed, dir, spread)


## Retour visuel d'un coup sur un ennemi.
func hit_fx(e: Enemy, crit: bool, kb: Vector2) -> void:
	var col: Color = e.ink_col if e.element > 0 else Pal.SHADES[0][1]
	var dir := kb.normalized() if kb.length() > 0.1 else Vector2.ZERO
	burst(e.position, col, 5 if crit else 2, 90.0 if crit else 60.0, dir, 0.9)
	if crit:
		burst(e.position, Color.WHITE, 3, 110.0, dir, 0.6)


## Retour visuel quand le joueur est touché.
func player_hurt_fx(pos: Vector2) -> void:
	burst(pos, Pal.BAD, 10, 90.0)
	hud.hurt_flash = 1.0
	hitstop(0.05)


func float_text(pos: Vector2, text: String, color: Color) -> void:
	numbers.add(pos, text, color, 0.8)


func damage_number(pos: Vector2, amount: float, crit: bool, el := 0) -> void:
	var c := Pal.TEXT
	if el > 0:
		c = Pal.main_color(el)
	if crit:
		c = Pal.ACCENT
	numbers.add(pos + Vector2(randf_range(-4, 4), -10), str(roundi(amount)) + ("!" if crit else ""), c, 0.7 if crit else 0.6, crit)


## Rayon d'une explosion du joueur : synergie Lumière = +33 %.
func boom(r: float) -> float:
	return r * (1.33 if syn.has(Pal.LUMIERE) else 1.0)


## Dégâts d'une explosion du joueur : Pétard = +25 % chacun.
func boom_dmg(d: float) -> float:
	return d * (1.0 + 0.25 * Run.amulet_count("petard"))


func explosion(pos: Vector2, r: float, color: Color, quiet := false) -> void:
	var ring := _Ring.new()
	ring.position = pos
	ring.max_r = r
	ring.color = color
	fx.add_child(ring)
	if quiet:
		return
	shake(2.5)
	Sfx.play("explode")


## Zone d'encre AMIE (Pinceau) : brûle les ennemis qui marchent dedans.
func add_zone(pos: Vector2, r: float, life: float, dps: float, el: int) -> void:
	if clouds.size() > 160:
		clouds.pop_front()
	var col: Color = Pal.main_color(el) if el > 0 else Pal.INK
	clouds.append({"pos": pos, "r": r, "t": life, "acc": randf() * 0.5, "dps": dps, "el": el, "col": col})
	_splat(pos, r * 0.35, col)


## Tampon : imprime une image sur le sol de l'arène.
func stamp_floor(img: Image, top_left: Vector2) -> void:
	floor_img.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(top_left))
	floor_dirty = true


## Image qui apparaît puis s'efface (flash du tampon).
func flash_image(tex: Texture2D, pos: Vector2, dur := 0.35) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, dur)
	tw.tween_callback(s.queue_free)


## Gomme sacrée : un grand trait blanc qui efface aussi l'encre ennemie au sol.
func erase_stroke(a: Vector2, b: Vector2, width: float) -> void:
	var l := Line2D.new()
	l.width = width * 1.6
	l.default_color = Color(1, 1, 1, 0.9)
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.add_point(a)
	l.add_point(b)
	fx.add_child(l)
	var edge := Line2D.new()
	edge.width = 1.0
	edge.default_color = Color(Pal.INK, 0.6)
	var n := (b - a).orthogonal().normalized() * width * 0.8
	edge.add_point(a + n)
	edge.add_point(b + n)
	l.add_child(edge)
	var edge2 := edge.duplicate() as Line2D
	edge2.set_point_position(0, a - n)
	edge2.set_point_position(1, b - n)
	l.add_child(edge2)
	# Miettes de gomme
	for i in 6:
		var q := a.lerp(b, randf()) + n * randf_range(-1.0, 1.0)
		numbers.add(q, "·", Pal.DIM, 0.4)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)
	hazards = hazards.filter(func(h): return Geometry2D.get_closest_point_to_segment(h.pos, a, b).distance_to(h.pos) > width + h.r)
	Sfx.play("swing")


func _bolt(a: Vector2, b: Vector2) -> void:
	var l := Line2D.new()
	l.width = 2.0
	l.default_color = Pal.SHADES[3][2]
	var n := 5
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if i > 0 and i < n:
			p += (b - a).orthogonal().normalized() * randf_range(-5, 5)
		l.add_point(p)
	fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.18)
	tw.tween_callback(l.queue_free)


func _after(sec: float, cb: Callable) -> void:
	var tm := Timer.new()
	tm.one_shot = true
	tm.wait_time = sec
	tm.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(tm)
	tm.timeout.connect(cb)
	tm.start()


func _build_floor() -> void:
	var kind: String = MapDB.get_def(Run.map).floor
	if not base_floors.has(kind):
		var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
		var board := kind == "board"
		var bg: Color = BOARD if board else Pal.PAPER
		img.fill(bg)
		var line: Color = bg.lightened(0.07) if board else Pal.PAPER.darkened(0.06)
		var border: Color = Color("6b4428") if board else Pal.PAPER_DARK.darkened(0.2)
		for y in H:
			for x in W:
				if x < 3 or y < 3 or x >= W - 3 or y >= H - 3:
					img.set_pixel(x, y, border)
				elif (x % 32 == 0 or y % 32 == 0) if board else (x % 16 == 0 or y % 16 == 0):
					img.set_pixel(x, y, line)
				elif randf() < 0.03:
					img.set_pixel(x, y, bg.lightened(randf_range(0.02, 0.08)) if board else Pal.PAPER.darkened(randf_range(0.02, 0.05)))
		if board:
			# Traces de craie mal effacées
			for i in 14:
				var c := Vector2i(randi_range(20, W - 20), randi_range(20, H - 20))
				for k in 60:
					var q := c + Vector2i(randi_range(-26, 26), randi_range(-3, 3))
					if q.x > 3 and q.y > 3 and q.x < W - 3 and q.y < H - 3:
						img.set_pixel(q.x, q.y, img.get_pixel(q.x, q.y).lerp(Color.WHITE, 0.08))
		base_floors[kind] = img
	floor_img = (base_floors[kind] as Image).duplicate()
	floor_tex = ImageTexture.create_from_image(floor_img)
	var s := Sprite2D.new()
	s.texture = floor_tex
	s.centered = false
	s.z_index = -10
	add_child(s)


## Tache d'encre qui reste au sol : l'arène se remplit de dessins au fil de la vague.
func _splat(pos: Vector2, r: float, col: Color) -> void:
	var ink := col.lerp(Pal.PAPER, 0.35)
	var blobs := [[pos, r * 0.8 + 2.0]]
	for i in randi_range(3, 6):
		blobs.append([pos + Vector2.from_angle(randf() * TAU) * randf_range(r, r * 2.2 + 4.0), randf_range(1.0, 2.5)])
	for bl in blobs:
		var c: Vector2 = bl[0]
		var rr: float = bl[1]
		var ir := ceili(rr)
		for y in range(-ir, ir + 1):
			for x in range(-ir, ir + 1):
				if x * x + y * y > rr * rr * randf_range(0.7, 1.0):
					continue
				var px := int(c.x) + x
				var py := int(c.y) + y
				if px < 3 or py < 3 or px >= W - 3 or py >= H - 3:
					continue
				floor_img.set_pixel(px, py, floor_img.get_pixel(px, py).lerp(ink, 0.45))
	floor_dirty = true


# ------------------------------------------------------------------ Petits noeuds d'effets

class _Marks extends Node2D:
	var arena: Arena
	var air := false

	func _draw() -> void:
		if air:
			_draw_air()
			return
		for h in arena.hazards:
			var a: float = clampf(h.t / minf(h.life, 0.6), 0.0, 1.0)
			var c: Color = h.col
			draw_circle(h.pos, h.r, Color(c.darkened(0.2), 0.45 * a))
			if h.dmg > 0.0:
				draw_circle(h.pos, h.r * 0.5, Color(c, 0.7 * a))
		for cl in arena.clouds:
			if cl.has("col"):
				var cc: Color = cl.col
				draw_circle(cl.pos, cl.r, Color(cc, 0.3 * clampf(cl.t, 0.0, 1.0)))
				draw_arc(cl.pos, cl.r, 0.0, TAU, 20, Color(cc.darkened(0.3), 0.5 * clampf(cl.t, 0.0, 1.0)), 1.0)
				continue
			draw_circle(cl.pos, cl.r, Color(Pal.SHADES[4][1], 0.25 * clampf(cl.t, 0.0, 1.0)))
			draw_arc(cl.pos, cl.r, 0.0, TAU, 24, Color(Pal.SHADES[4][2], 0.5), 1.0)
		for rl in arena.rulers:
			var blink := 0.35 + 0.35 * sin(arena.elapsed * 30.0)
			draw_line(rl.a, rl.b, Color(Pal.BAD, blink), 3.0)
			var n := int(rl.a.distance_to(rl.b) / 8.0)
			var dir: Vector2 = (rl.b - rl.a).normalized()
			for i in n:
				var q: Vector2 = rl.a + dir * i * 8.0
				draw_line(q, q + dir.orthogonal() * (4.0 if i % 4 == 0 else 2.0), Color(Pal.INK, 0.6), 1.0)
		for lb in arena.lobs:
			var k: float = lb.t / lb.dur
			draw_arc(lb.to, lb.r, 0.0, TAU, 24, Color(Pal.BAD, 0.4 + 0.4 * k), 1.0)
			draw_circle(lb.to, lb.r * k, Color(Pal.BAD, 0.15))
		for er in arena.erasers:
			var k: float = er.t / er.dur
			draw_circle(er.pos, er.r, Color(1, 1, 1, 0.25 + 0.3 * k))
			draw_arc(er.pos, er.r * (1.0 - k) + 2.0, 0.0, TAU, 28, Color(Pal.INK, 0.8), 2.0)
			draw_arc(er.pos, er.r, 0.0, TAU, 28, Color(1, 1, 1, 0.9), 2.0)
		# --- Tableau noir
		for sp in arena.sponges:
			var band := Rect2(0, sp.c - 36, W, 72) if sp.horiz else Rect2(sp.c - 36, 0, 72, H)
			if sp.t < sp.tele:
				var blink := 0.12 + 0.1 * sin(arena.elapsed * 20.0)
				draw_rect(band, Color(0.5, 0.8, 1.0, blink))
			else:
				draw_rect(band, Color(0.5, 0.8, 1.0, 0.08))
				var r := Rect2(sp.pos - Vector2(30, 36), Vector2(60, 72)) if sp.horiz else Rect2(sp.pos - Vector2(36, 30), Vector2(72, 60))
				draw_rect(r, Color("e8c547"))
				draw_rect(r.grow(-6), Color("d4a93a"))
				draw_rect(Rect2(r.position, Vector2(r.size.x, 10)) if sp.horiz else Rect2(r.position, Vector2(10, r.size.y)), Color("4caf50"))
		for ch in arena.chalks:
			var k: float = clampf(ch.t / 1.2, 0.0, 1.0)
			draw_arc(ch.pos, ch.r, 0.0, TAU, 20, Color(1, 1, 1, 0.8), 1.0)
			draw_circle(ch.pos, ch.r * (1.0 - k), Color(1, 1, 1, 0.25))
		for st in arena.stars:
			var s: float = 7.0 + sin(arena.elapsed * 6.0) * 1.5
			var pts := PackedVector2Array()
			for i in 10:
				pts.append(st.pos + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * (s if i % 2 == 0 else s * 0.45))
			draw_colored_polygon(pts, Pal.ACCENT)
		for sq in arena.squares:
			var k: float = sq.t / sq.dur
			var r := Rect2(sq.pos - Vector2(sq.half, sq.half), Vector2(sq.half, sq.half) * 2.0)
			draw_rect(r, Color(sq.col, 0.15 + 0.25 * k))
			draw_rect(r, Color(Pal.BAD, 0.5 + 0.4 * k), false, 2.0)
		for qz in arena.quizzes:
			var n: int = qz.cols
			var cw := float(W) / n
			for i in n:
				var col := Color(1, 1, 1, 0.07 if i % 2 == 0 else 0.03)
				draw_rect(Rect2(cw * i, 0, cw, H), col)
				draw_line(Vector2(cw * i, 0), Vector2(cw * i, H), Color(1, 1, 1, 0.5), 2.0)
				# La réponse de la colonne, répétée sur toute la hauteur (visible même zoomé)
				for k in 4:
					draw_string(UI.font, Vector2(cw * i, H * (k + 0.5) / 4.0 + 14.0), str(qz.answers[i]), HORIZONTAL_ALIGNMENT_CENTER, cw, 40, Color(1, 1, 1, 0.55))
		for sc in arena.scans:
			if sc.t < sc.tele:
				draw_line(Vector2(0, 4), Vector2(W, 4), Color(0.6, 1.0, 0.7, 0.4 + 0.4 * sin(arena.elapsed * 25.0)), 3.0)
			else:
				draw_rect(Rect2(0, sc.y - 6, W, 12), Color(0.6, 1.0, 0.7, 0.18))
				draw_line(Vector2(0, sc.y), Vector2(W, sc.y), Color(0.75, 1.0, 0.8, 0.95), 2.0)
		for g in arena.telegraphs_fx:
			draw_arc(g.pos, 10.0, 0.0, TAU, 16, Color(1, 1, 1, 0.8), 2.0)
			draw_string(UI.font, g.pos + Vector2(-20, -14), "COPIE", HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color(1, 1, 1, 0.8))
		# Agrafes (Agrafeuse)
		for e in arena.enemies:
			if e.staple_t > 0.0 and is_instance_valid(e.staple) and not e.staple.dead and e.get_instance_id() < e.staple.get_instance_id():
				draw_line(e.position, e.staple.position, Color(0.75, 0.78, 0.85, 0.9), 1.0)
		# Points finaux
		for w in arena.wells:
			var k: float = clampf(w.t / w.dur, 0.0, 1.0)
			draw_circle(w.pos, 4.0 + w.r * 0.22 * k, Pal.INK)
			for i in 3:
				var a: float = arena.elapsed * 6.0 + i * TAU / 3.0
				draw_arc(w.pos, w.r * (1.0 - k * 0.5), a, a + 1.2, 10, Color(Pal.INK, 0.35), 2.0)
		# Fil des trombones
		for e in arena.enemies:
			if e.partner != null and is_instance_valid(e.partner) and not e.partner.dead and e.get_instance_id() < e.partner.get_instance_id():
				draw_line(e.position, e.partner.position, Color(0.8, 0.82, 0.88, 0.9), 2.0)
				draw_line(e.position, e.partner.position, Color(1, 1, 1, 0.5), 1.0)
		for tg in arena.telegraphs:
			var p: Vector2 = tg.pos
			var s: float = 4.0 + (1.0 - tg.t) * 2.0
			var c := Color(Pal.BAD, 0.5 + 0.5 * sin(arena.elapsed * 20.0))
			draw_line(p + Vector2(-s, -s), p + Vector2(s, s), c, 2.0)
			draw_line(p + Vector2(-s, s), p + Vector2(s, -s), c, 2.0)

	## Pâtés en cloche : le projectile dessiné suit un arc au-dessus de son ombre.
	func _draw_air() -> void:
		for lb in arena.lobs:
			var k: float = lb.t / lb.dur
			var ground: Vector2 = lb.from.lerp(lb.to, k)
			draw_circle(ground, 3.0, Color(0, 0, 0, 0.2))
			var pos := ground + Vector2(0, -sin(k * PI) * 46.0)
			var tex: Texture2D = lb.tex
			draw_texture(tex, pos - tex.get_size() / 2.0)


class _Numbers extends Node2D:
	var items: Array = []

	func add(pos: Vector2, text: String, color: Color, life: float, big := false) -> void:
		if items.size() > 90:
			items.pop_front()
		items.append({"pos": pos, "text": text, "color": color, "t": 0.0, "life": life, "big": big,
			"vx": randf_range(-14.0, 14.0)})

	func tick(delta: float) -> void:
		var keep := []
		for it in items:
			it.t += delta
			# Saute puis retombe un peu, en dérivant sur le côté
			var vy: float = -60.0 + it.t * 140.0
			it.pos = it.pos + Vector2(it.vx * delta, minf(vy, 10.0) * delta)
			if it.t < it.life:
				keep.append(it)
		items = keep
		queue_redraw()

	func _draw() -> void:
		for it in items:
			var a := 1.0 - maxf(0.0, (it.t - it.life * 0.6) / (it.life * 0.4))
			var w := 120.0
			# « Pop » : grossit d'un coup puis revient à sa taille
			var s: float = 1.0 + (0.8 if it.big else 0.35) * maxf(0.0, 1.0 - it.t / 0.12)
			if it.big:
				s *= 1.4
			draw_set_transform(it.pos, 0.0, Vector2(s, s))
			var p := Vector2(-w / 2.0, 0)
			draw_string(UI.font, p + Vector2(1, 1), it.text, HORIZONTAL_ALIGNMENT_CENTER, w, 10, Color(Pal.INK, a))
			draw_string(UI.font, p, it.text, HORIZONTAL_ALIGNMENT_CENTER, w, 10, Color(it.color, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Particules d'encre : de petits carrés de pixels qui partent, freinent et tombent.
class _Sparks extends Node2D:
	var items: Array = []

	func emit(pos: Vector2, col: Color, n: int, speed: float, dir: Vector2, spread: float) -> void:
		if items.size() > 500:
			n = mini(n, 2)
		for i in n:
			var a := (dir.angle() + randf_range(-spread, spread)) if dir != Vector2.ZERO else randf() * TAU
			items.append({"pos": pos, "vel": Vector2.from_angle(a) * speed * randf_range(0.4, 1.2),
				"t": 0.0, "life": randf_range(0.25, 0.55), "col": col, "s": 1.0 + float(randi() % 2)})
		while items.size() > 700:
			items.pop_front()

	func tick(delta: float) -> void:
		var keep := []
		for it in items:
			it.t += delta
			it.vel = it.vel * (1.0 - 4.0 * delta) + Vector2(0, 120.0 * delta)
			it.pos = it.pos + it.vel * delta
			if it.t < it.life:
				keep.append(it)
		items = keep
		queue_redraw()

	func _draw() -> void:
		for it in items:
			var k: float = 1.0 - it.t / it.life
			var s: float = it.s * (0.5 + 0.5 * k)
			draw_rect(Rect2(it.pos.round() - Vector2(s, s) / 2.0, Vector2(s, s)), Color(it.col, clampf(k * 1.5, 0.0, 1.0)))


class _Ring extends Node2D:
	var max_r := 30.0
	var color := Color.WHITE
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta / 0.25
		if t >= 1.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var r := max_r * minf(1.0, t)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(color, 1.0 - t), 3.0)
		draw_circle(Vector2.ZERO, r * 0.6, Color(color, (1.0 - t) * 0.35))
