class_name Enemy
extends Node2D
## Ennemi dessiné par le joueur. Le comportement est fixe (défini par son type) et pensé
## autour du dessin : flaques, traits d'encre, règle, compas, gomme, taches piégées...

const BOSS_DMG := 0.975     # (1,3 puis -25 % : un coup de boss fait ~3 de moins en moyenne)
const BOSS_SPEED := 1.12
const BOSS_EASE := 0.85        # PV et dégâts des boss (réglage global)
const BOSS_EASE_FIRST := 0.75  # le premier boss de la carte (vague 5)

var arena: Arena
var id := ""
var def: Dictionary
var hp := 1.0
var max_hp := 1.0
var dmg := 1.0
var speed := 50.0
var radius := 8.0
var element := 0
var color := 0              # couleur dans le cercle des faiblesses (Pal.color_of)
var weak_t := 0.0           # affichage « FAIBLE ! » / « RÉSISTE » (pas à chaque coup)
var ink_col := Color.BLACK
var loot := 1.0
var dead := false
var is_boss := false
var small := false
var elite := false
var power := ""             # Huile+ : pouvoir de l'élite (shield, fast, vampire, explosive, summoner)
var shield_up := false      # élite « bouclier » : ignore le premier coup
var summon_cd := 0.0        # élite « invocatrice »
var frenzy_on := false      # Chef-d'œuvre : boss en fureur sous 25 % de PV
var toile_phase := 1        # Toile Blanche / Encrier renversé : phase 1, 2 ou 3
var light_shots := false    # Encrier (phase 2+) : ses tirs sont des éclats de LUMIÈRE
var reflet: Enemy           # Encrier (phase 3) : son reflet de Rorschach
var reflet_of: Enemy        # ... et pour le reflet : l'Encrier qu'il copie
var blot_cd := 3.0          # Encrier : prochain buvard
var hit_at := Vector2.INF   # coup reçu par le reflet : le chiffre s'affiche sur lui
var boss_inv := 0.0         # boss intouchable (passage de phase)
var contact := true
var body: Node2D
var sprite: Sprite2D
var mat: ShaderMaterial
var base_scale := 1.0
var knock := Vector2.ZERO
var flash := 0.0
var squash := 0.0            # écrasement quand on le frappe (0 = forme normale)
var t := 0.0
var phase := 0.0
var hop_h := 0.0

# États de comportement
var state := "walk"
var st_t := 0.0
var cd := 0.0
var cd2 := 0.0
var cd3 := 0.0
var dash_dir := Vector2.ZERO
var tp_pos := Vector2.ZERO     # Raturé : où il va réapparaître (annoncé 1 s avant)
var tp_mark := {}
var spiral_a := 0.0
var last_atk := ""          # Raturé : dernière attaque (jamais deux fois de suite)
var atk_bag: Array = []     # Raturé : attaques restantes du cycle en cours
var hatch_a := 0.0          # Raturé : angle des hachures
var pattern := 0
var repeat := 0
var center := Vector2.ZERO
var orbit_r := 150.0
var orbit_a := 0.0
var mirror_mode := 0
var partner: Enemy           # Trombones : l'autre bout du fil
var crumple := 0             # Brouillon : nombre de fois froissé
var hit_ids := {}
# Effets des armes épiques / légendaires
var pin_t := 0.0             # Agrafeuse : épinglé au sol
var slip_t := 0.0            # La Banane : assommé après avoir glissé
var firefly := false         # aura de la Luciole : +15 % de dégâts subis
var slide := Vector2.ZERO    # La Banane : glissade (ralentit doucement)
var slide_hits := {}         # ennemis déjà percutés pendant cette glissade
var slip_chain := {}         # réaction en chaîne de la Banane (nombre d'ennemis à terre, STRIKE déjà fait)
var wet_t := 0.0             # Brumisateur : mouillé
var gust_t := 0.0            # Éventail : projeté (choc contre un bord)
var gust_dmg := 0.0
var staple: Enemy            # Agrafeuse : l'autre ennemi agrafé
var staple_t := 0.0
var staple_guard := false
var ink_t := 0.0             # Encre de Chine : marqué
var ink_dmg := 0.0
var ally := false            # Retouche : redessiné dans le camp du joueur
var ally_t := 0.0
var ally_cd := 0.0
var blind_t := 0.0           # Encre de seiche : aveuglé
var el_seen := {}            # Cercle chromatique : éléments différents subis
var shroom_cd := 0.0         # Champignon : délai entre deux nuages

# Statuts
var slow_t := 0.0
var chill := 0
var freeze_t := 0.0
var burn_ticks := 0
var burn_dmg := 0.0
var burn_acc := 0.0
var poison := 0
var poison_t := 0.0
var poison_acc := 0.0
var mark_t := 0.0
var last_tint := Color.WHITE


func setup(a: Arena, type_id: String, is_small := false, is_elite := false) -> void:
	arena = a
	id = type_id
	def = EnemyDB.get_def(id)
	small = is_small
	is_boss = def.has("boss")
	elite = is_elite and Run.elite_art.has(id)
	var art: Dictionary = Run.elite_art[id] if elite else Run.enemy_art[id]
	var mods: Dictionary = art.mods
	var w := Run.eff_wave()
	var d := Run.diff()
	var wave_hp := 1.0 if is_boss else 1.0 + 0.3 * (w - 1)
	var wave_dmg := 1.0 if is_boss else 1.0 + 0.1 * (w - 1)
	max_hp = def.hp * wave_hp * d.hp * mods.hp * (0.45 if small else 1.0) * (3.0 if elite else 1.0)
	hp = max_hp
	dmg = def.dmg * wave_dmg * d.dmg * (1.3 if elite else 1.0)
	speed = def.spd * randf_range(0.9, 1.1) * (1.1 if Run.difficulty >= 2 else 1.0)
	# Huile et plus : chaque élite a un pouvoir
	if elite and Run.difficulty >= 3:
		power = TRAITS.keys().pick_random()
		match power:
			"shield":
				shield_up = true
			"fast":
				speed *= 1.3
			"summoner":
				summon_cd = 3.0
	if is_boss:
		# Les boss bougent plus vite que leurs stats de base (et frappent un peu moins fort)
		dmg *= BOSS_DMG
		speed *= BOSS_SPEED
		# ... mais restent abordables : -15 % de PV et de dégâts, -25 % pour le 1er boss (vague 5)
		var ease := BOSS_EASE_FIRST if Run.wave <= 5 else BOSS_EASE
		max_hp *= ease
		hp = max_hp
		dmg *= ease
	radius = mods.radius * (0.6 if small else 1.0)
	element = mods.element
	color = Pal.color_of(art.a.frac) if art.has("a") else element
	ink_col = Pal.main_color(element) if element > 0 else Pal.SHADES[0][1]
	loot = def.loot * mods.loot * (0.5 if small else 1.0) * (3.0 if elite else 1.0)
	body = Node2D.new()
	add_child(body)
	mat = Gfx.material(art.effect, art.get("outline", false))
	sprite = Gfx.sprite(arena.enemy_tex(id, elite), mat)
	body.add_child(sprite)
	base_scale = 0.6 if small else 1.0
	body.scale = Vector2(base_scale, base_scale)
	phase = randf() * TAU
	cd = randf_range(0.6, 2.0)
	cd2 = randf_range(3.0, 6.0)
	st_t = 2.0
	mirror_mode = randi_range(1, 2) if small else 0


## La Banane : glisse sur une peau (assommé 2 s, part en patinant dans la direction où il allait).
## chain : la réaction en chaîne (partagée entre tous les ennemis qui glissent à cause de la même peau).
func slip(dir: Vector2, chain = null) -> void:
	if is_boss or dead:
		return
	if chain == null:
		chain = {"n": 0, "struck": false}   # nouvelle peau : nouvelle chaîne
	chain.n = int(chain.n) + 1
	slip_chain = chain
	if chain.n >= 3 and not chain.struck:
		chain.struck = true   # 3 ennemis à terre à cause d'une seule peau : STRIKE !
		arena.banana_strike(position)
	slip_t = 2.0
	slide = dir.normalized() * 260.0
	slide_hits = {}
	arena.float_text(position + Vector2(0, -14), "OUPS !", Color("f2d23a"))
	Sfx.play("swing")


## En glissant, il percute les autres ennemis : dégâts aux deux (une fois par ennemi).
func _slide_hits() -> void:
	if slide.length() < 60.0:
		return
	for o in arena.near(position, radius + 6.0):
		if o == self or o.dead or slide_hits.has(o.get_instance_id()):
			continue
		slide_hits[o.get_instance_id()] = true
		var d: float = (6.0 + Run.wave * 2.0) * (1.0 + Run.stats.dmg / 100.0)
		o.hurt(d, false, slide.normalized() * 120.0)
		hurt(d * 0.5, false, Vector2.ZERO)
		arena.burst(o.position, Color("f2d23a"), 6, 80.0)
		# Effet domino : il glisse à son tour (réaction en chaîne)
		if not o.dead and not o.is_boss and o.slip_t <= 0.0:
			o.slip(slide.normalized().rotated(randf_range(-0.5, 0.5)), slip_chain)


## Pouvoirs des élites (Huile et plus) : [nom affiché, couleur de l'aura]
const TRAITS := {
	"shield": ["BOUCLIER", Color("5aa8ff")],
	"fast": ["RAPIDE", Color("ffe066")],
	"vampire": ["VAMPIRE", Color("e03a3a")],
	"explosive": ["EXPLOSIVE", Color("ff8a2a")],
	"summoner": ["INVOCATRICE", Color("b06aff")],
}


func power_color() -> Color:
	return TRAITS[power][1] if power != "" else Pal.ACCENT


## Chef-d'œuvre : sous 25 % de PV, le boss entre en fureur (2e colère).
func _frenzy() -> bool:
	return is_boss and Run.difficulty >= 4 and hp < max_hp * 0.25


## Aquarelle et plus : les tireurs visent là où tu VAS (t = temps de vol du tir).
func _lead(t_fly: float) -> Vector2:
	var p := arena.target_pos()
	if Run.difficulty >= 2 and not is_boss:
		p += arena.player_vel() * t_fly
	return p


func _lead_dir(bullet_speed: float) -> Vector2:
	var d0 := arena.target_pos().distance_to(position)
	var d := (_lead(d0 / maxf(1.0, bullet_speed)) - position)
	return d.normalized() if d.length() > 0.01 else Vector2.RIGHT


func _draw() -> void:
	draw_set_transform(Vector2(0, radius * 0.9), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius + 2, Color(0, 0, 0, 0.15))
	if elite:
		# Aura des élites
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var pulse := 0.5 + 0.5 * sin(t * 6.0)
		draw_arc(Vector2.ZERO, radius + 5.0 + pulse * 2.0, 0.0, TAU, 28, Color(power_color(), 0.35 + pulse * 0.4), 2.0)
		if shield_up:
			draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 24, Color(0.6, 0.8, 1.0, 0.8), 2.0)
		draw_arc(Vector2.ZERO, radius + 9.0 + pulse * 3.0, 0.0, TAU, 28, Color(ink_col, 0.25), 1.0)
	if ink_t > 0.0:
		# Encre de Chine : taches noires sur l'ennemi marqué
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2(-radius * 0.4, -radius * 0.3), 2.5, Pal.INK)
		draw_circle(Vector2(radius * 0.35, radius * 0.1), 2.0, Pal.INK)
		draw_circle(Vector2(0, radius * 0.5), 1.5, Pal.INK)
	if ally:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 24, Color(Pal.GOOD, 0.8), 2.0)
	if def.get("beh", "") == "gum":
		# Zone où tes projectiles sont effacés
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_arc(Vector2.ZERO, GUM_R, 0.0, TAU, 32, Color(1, 1, 1, 0.25 + 0.1 * sin(t * 4.0)), 1.0)


# ------------------------------------------------------------------ Boucle

func tick(delta: float) -> void:
	if dead:
		return
	if reflet_of != null:
		_reflet_tick(delta)
		return
	weak_t -= delta
	if ally:
		_ally_tick(delta)
		return
	t += delta
	pin_t -= delta
	wet_t -= delta
	gust_t -= delta
	staple_t -= delta
	if ink_t > 0.0:
		ink_t -= delta
		queue_redraw()
	_status(delta)
	if dead:
		return
	var p := arena.player
	var to_p := arena.target_pos(position) - position   # le joueur, le leurre de la Lanterne ou Pavel
	var dist := maxf(0.01, to_p.length())
	var dirp := to_p / dist
	blind_t -= delta
	shroom_cd -= delta
	if not is_boss and (blind_t > 0.0 or p.invis_t > 0.0):
		# Aveuglé (Seiche) ou joueur invisible (Encre invisible) : il erre
		dirp = Vector2.from_angle(phase + t * 0.8)
		dist = 999.0
	var v := Vector2.ZERO
	var mult := 0.55 if slow_t > 0.0 else 1.0
	if arena.rush_t > 0.0 and not is_boss:
		mult *= 1.7   # Sonnerie : tout le monde se précipite
	if wet_t > 0.0:
		mult *= 0.7
	if pin_t > 0.0 and not is_boss:
		mult = 0.0
	if freeze_t > 0.0:
		mult = 0.0
	if slip_t > 0.0:
		slip_t -= delta
		mult = 0.0   # assommé par la peau de banane
	hop_h = 0.0

	# Chef-d'œuvre : boss en fureur = attaques plus rapprochées
	var bd := delta
	if _frenzy():
		bd = delta * 1.35
		if not frenzy_on:
			frenzy_on = true
			arena.float_text(position + Vector2(0, -44), "FUREUR !", Pal.BAD)
			arena.shake(8.0)
			Sfx.play("boss")
		flash = maxf(flash, 0.25 if int(t * 10.0) % 2 == 0 else 0.0)
	# Élite invocatrice : appelle des petits
	if power == "summoner":
		summon_cd -= delta
		if summon_cd <= 0.0:
			summon_cd = 5.0
			for k in 2:
				arena.spawn_enemy_now(id, position + Vector2.from_angle(randf() * TAU) * (radius + 12.0), true)
	match def.beh:
		"hop":
			v = _hop(delta * mult, dirp)
		"scribble":
			v = _scribble(delta * mult, dirp)
		"mortar":
			v = _mortar(delta * mult, dist)
		"ruler":
			v = _ruler(delta * mult, dirp, dist)
		"mirror":
			v = _mirror(delta * mult, p, dirp)
		"compass":
			v = _compass(delta * mult, p, dirp)
		"dvd":
			v = _colossus(delta * mult, dirp, dist)
		"mine":
			v = _mine(delta, dirp, dist)
			if dead:
				return
		"b_hatch":
			v = _boss_hatch(bd, dirp, dist)
		"b_critique":
			v = _boss_critique(bd, dirp)
		"b_orbit":
			v = _boss_orbit(bd, dirp, dist)
		"b_toile":
			v = _boss_toile(bd, dirp, dist)
		"pin":
			v = _pin(delta * mult, dirp, dist)
		"chalk":
			v = _chalk(delta * mult, dirp, dist)
		"clip":
			v = _clip(delta * mult, p, dirp)
		"stamp":
			v = _stamp(delta * mult, dirp, dist)
		"crumple":
			v = _crumple(dirp)
		"gum":
			v = _gum(dirp)
		"equation":
			v = _equation(delta * mult, dirp)
		"b_prof":
			v = _boss_prof(bd, dirp, dist)
		"b_copy":
			v = _boss_copy(bd, dirp, dist)
		"b_ink":
			v = _boss_ink(bd, dirp, dist)

	# Séparation entre ennemis
	if not is_boss and def.beh != "dvd":
		for o in arena.near(position, radius + 4.0):
			if o == self:
				continue
			var push: Vector2 = position - o.position
			var dd := push.length()
			if dd > 0.01 and dd < radius + o.radius:
				v += push / dd * 45.0

	position += (v * mult + knock + slide) * delta
	if slide.length() > 5.0:
		slide = slide.move_toward(Vector2.ZERO, 170.0 * delta)
		_slide_hits()
	knock = knock.move_toward(Vector2.ZERO, 700.0 * delta)
	var hit_wall := Vector2.ZERO
	if position.x <= radius or position.x >= Arena.W - radius:
		hit_wall.x = 1.0
	if position.y <= radius or position.y >= Arena.H - radius:
		hit_wall.y = 1.0
	position.x = clampf(position.x, radius, Arena.W - radius)
	position.y = clampf(position.y, radius, Arena.H - radius)
	if hit_wall != Vector2.ZERO:
		_on_wall(hit_wall)
		if gust_t > 0.0:
			# Éventail : écrasé contre le bord de la page
			gust_t = 0.0
			arena.burst(position, Color.WHITE, 10, 100.0)
			arena.shake(2.5)
			hurt(gust_dmg, true, Vector2.ZERO)

	if absf(v.x) > 1.0 and state != "arm":
		body.scale.x = base_scale * (-1.0 if v.x < 0.0 else 1.0)
	if def.beh == "hop":
		body.rotation = 0.0
		body.position.y = -hop_h
	else:
		body.rotation = sin(t * 9.0 + phase) * 0.08 * mult
		body.position.y = -absf(sin(t * 9.0 + phase)) * 1.5 * mult
	if slip_t > 0.0:
		body.rotation = t * (14.0 if slide.length() > 20.0 else 4.0)   # il tourne en glissant, puis titube

	if squash > 0.0:
		squash = maxf(0.0, squash - delta * 7.0)
		var sx := -1.0 if body.scale.x < 0.0 else 1.0
		body.scale = Vector2(sx * base_scale * (1.0 + 0.3 * squash), base_scale * (1.0 - 0.22 * squash))
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 7.0)
	mat.set_shader_parameter("flash", flash)
	_update_tint()
	if elite:
		queue_redraw()


func _on_wall(hit: Vector2) -> void:
	match def.beh:
		"dvd":
			# Colosse : s'écrase contre le bord, laisse une grosse trace de gomme et reprend son souffle
			if state == "dash":
				state = "rest"
				st_t = 1.2
				arena.add_hazard(position, radius + 6.0, 3.0, 0.5, 0.0, Pal.PAPER_DARK)
				arena.shake(3.0)
		"ruler":
			if state == "dash":
				state = "rest"
				st_t = 1.0
				arena.shake(3.0)


func _status(delta: float) -> void:
	slow_t -= delta
	freeze_t -= delta
	mark_t -= delta
	if burn_ticks > 0:
		burn_acc += delta
		if burn_acc >= 0.5:
			burn_acc = 0.0
			burn_ticks -= 1
			hurt(burn_dmg, false, Vector2.ZERO, Pal.FEU)
			# Synergie Feu : la brûlure se propage
			if not dead and arena.syn.has(Pal.FEU) and randf() < 0.4:
				for o in arena.near(position, 34.0):
					if o != self and o.burn_ticks == 0:
						o.burn(burn_dmg)
						break
	if poison > 0:
		poison_t -= delta
		poison_acc += delta
		if poison_acc >= 1.0:
			poison_acc = 0.0
			hurt(poison * (1.0 + Run.wave * 0.25), false, Vector2.ZERO, Pal.POISON)
		if poison_t <= 0.0:
			poison = 0


func _update_tint() -> void:
	var c := Color.WHITE
	if freeze_t > 0.0:
		c = Color(0.6, 0.85, 1.4)
	elif poison > 0:
		c = Color(0.8, 1.25, 0.8)
	elif burn_ticks > 0:
		c = Color(1.35, 0.85, 0.7)
	elif mark_t > 0.0:
		c = Color(1.15, 0.8, 1.35)
	if c != last_tint:
		last_tint = c
		mat.set_shader_parameter("tint", c)


# ------------------------------------------------------------------ Dégâts & statuts

func hurt(amount: float, crit := false, kb := Vector2.ZERO, el := 0) -> void:
	if dead or boss_inv > 0.0:
		return
	if reflet_of != null:
		# Reflet de Rorschach : les coups vont à l'Encrier (PV partagés)
		if is_instance_valid(reflet_of) and not reflet_of.dead:
			flash = 1.0
			reflet_of.hit_at = position
			reflet_of.hurt(amount, crit, Vector2.ZERO, el)
		return
	if shield_up:
		shield_up = false   # élite « bouclier » : le premier coup est bloqué
		flash = 1.0
		arena.float_text(position + Vector2(0, -16), "BLOQUÉ", Color("5aa8ff"))
		queue_redraw()
		return
	if mark_t > 0.0:
		amount *= (1.5 if arena.syn.has(Pal.ARCANE) else 1.25) + 0.15 * Run.amulet_count("grimoire")
	if firefly:
		arena.fam_credit("luciole", minf(hp, amount * 0.15))
		amount *= 1.15   # Luciole
	if state == "jam":
		amount *= 1.5   # Photocopieuse en bourrage papier : vulnérable
	if wet_t > 0.0 and (el == Pal.FOUDRE or el == Pal.GLACE):
		amount *= 1.25   # Brumisateur : mouillé
	# Agrafeuse : l'ennemi agrafé à celui-ci prend 50 % des dégâts
	if staple_t > 0.0 and is_instance_valid(staple) and not staple.dead and not staple_guard:
		staple.staple_guard = true
		staple.hurt(amount * 0.5, false, Vector2.ZERO, el)
		staple.staple_guard = false
	hp -= amount
	flash = 1.0
	squash = 1.0 if not is_boss else 0.4
	if def.beh != "dvd" and not is_boss:
		knock += kb * (0.25 if def.get("heavy", false) else 1.0)
	arena.damage_number(position if hit_at == Vector2.INF else hit_at, amount, crit, el)
	hit_at = Vector2.INF
	arena.hit_fx(self, crit, kb)
	if hp <= 0.0:
		arena.kill_enemy(self)


func burn(tick_dmg: float) -> void:
	burn_ticks = 4 * (1 + Run.amulet_count("allumette"))   # Allumette : dure plus longtemps
	burn_dmg = maxf(burn_dmg, tick_dmg)


func chill_hit() -> void:
	slow_t = 1.5
	chill += 1
	if chill >= (2 if Run.amulet_count("givre") > 0 else 3):   # Givre : gèle en 2 coups
		chill = 0
		freeze_t = 0.35 if is_boss else 1.0


func add_poison() -> void:
	poison += 1 + Run.amulet_count("fiole")   # Fiole : 2 cumuls
	poison_t = 4.0
	# Champignon : à 6 cumuls, éclate en nuage toxique qui contamine les voisins
	if poison >= 6 and shroom_cd <= 0.0 and Run.amulet_count("champignon") > 0 and not dead:
		shroom_cd = 2.0
		poison = 2
		arena.toxic_burst(self)


func mark() -> void:
	mark_t = 3.0 * (1 + Run.amulet_count("grimoire"))   # Grimoire : dure plus longtemps


# ------------------------------------------------------------------ Comportements

## Tache : avance par bonds et laisse une flaque qui ralentit à chaque atterrissage.
func _hop(delta: float, dirp: Vector2) -> Vector2:
	if state == "jump":
		st_t -= delta
		var k := clampf(1.0 - st_t / 0.4, 0.0, 1.0)
		hop_h = sin(k * PI) * 9.0
		if st_t <= 0.0:
			state = "rest"
			cd = randf_range(0.5, 1.0)
			arena.add_hazard(position, radius * 0.8 + 5.0, 3.0, 0.55, 0.0, ink_col)
			return Vector2.ZERO
		return dash_dir * speed * 3.4
	cd -= delta
	if cd <= 0.0:
		state = "jump"
		st_t = 0.4
		dash_dir = dirp.rotated(randf_range(-0.35, 0.35))
	return Vector2.ZERO


## Gribouille : traits en zigzag qui laissent de l'encre qui fait mal.
func _scribble(delta: float, dirp: Vector2) -> Vector2:
	st_t -= delta
	if st_t <= 0.0:
		st_t = randf_range(0.35, 0.7)
		dash_dir = dirp.rotated(randf_range(-1.2, 1.2))
	cd -= delta
	if cd <= 0.0:
		cd = 0.12
		arena.add_hazard(position, 4.0, 1.8, 1.0, dmg * 0.5, ink_col)
	return dash_dir * speed


## Crachoir : immobile, tire en cloche là où tu es, puis s'enfonce et ressort ailleurs.
func _mortar(delta: float, dist: float) -> Vector2:
	if state == "burrow":
		st_t -= delta
		mat.set_shader_parameter("alpha", clampf(st_t / 0.5, 0.1, 1.0) if st_t > 0.0 else 1.0)
		if st_t <= 0.0:
			var p := arena.player.position
			position = p + Vector2.from_angle(randf() * TAU) * randf_range(110.0, 200.0)
			position = position.clamp(Vector2(20, 20), Vector2(Arena.W - 20, Arena.H - 20))
			contact = true
			state = "idle"
			cd = 0.8
		return Vector2.ZERO
	cd -= delta
	if cd <= 0.0 and dist < 320.0:
		cd = 2.6
		arena.lob(self, _lead(1.1), 1.1)
	cd2 -= delta
	if cd2 <= 0.0:
		cd2 = randf_range(6.0, 8.0)
		state = "burrow"
		st_t = 0.5
		contact = false
	return Vector2.ZERO


## Bélier : trace une ligne à la règle, puis fonce dessus jusqu'au bord de la page.
func _ruler(delta: float, dirp: Vector2, dist: float) -> Vector2:
	match state:
		"aim":
			st_t -= delta
			flash = 0.5 if int(t * 14.0) % 2 == 0 else 0.0
			if st_t <= 0.0:
				state = "dash"
			return Vector2.ZERO
		"dash":
			return dash_dir * speed * 8.0
		"rest":
			st_t -= delta
			if st_t <= 0.0:
				state = "walk"
				cd = randf_range(1.0, 2.0)
			return Vector2.ZERO
		_:
			cd -= delta
			if cd <= 0.0 and dist < 280.0:
				state = "aim"
				st_t = 0.9
				dash_dir = dirp
				arena.add_ruler(position, _wall_point(position, dirp), 1.0)
			return dirp * speed * 0.6


func _wall_point(from: Vector2, dir: Vector2) -> Vector2:
	var tmax := 99999.0
	if dir.x > 0.001:
		tmax = minf(tmax, (Arena.W - radius - from.x) / dir.x)
	elif dir.x < -0.001:
		tmax = minf(tmax, (radius - from.x) / dir.x)
	if dir.y > 0.001:
		tmax = minf(tmax, (Arena.H - radius - from.y) / dir.y)
	elif dir.y < -0.001:
		tmax = minf(tmax, (radius - from.y) / dir.y)
	return from + dir * tmax


## Scinde : se place en miroir de toi par rapport au centre de la page et tire des reflets.
func _mirror(delta: float, p: Player, dirp: Vector2) -> Vector2:
	var target: Vector2
	match mirror_mode:
		1:
			target = Vector2(Arena.W - p.position.x, p.position.y)   # miroir gauche/droite
		2:
			target = Vector2(p.position.x, Arena.H - p.position.y)   # miroir haut/bas
		_:
			target = Vector2(Arena.W - p.position.x, Arena.H - p.position.y)
	cd -= delta
	if cd <= 0.0:
		cd = randf_range(2.5, 3.5)
		_shoot(_lead_dir(140.0 * 0.8), 0.8)
		Sfx.play("enemy_shot")
	var to := target - position
	if to.length() < 4.0:
		return Vector2.ZERO
	return to.normalized() * speed * 1.4


## Éclaboussure : cercles au compas de plus en plus serrés autour de toi.
func _compass(delta: float, p: Player, dirp: Vector2) -> Vector2:
	cd2 -= delta
	if state != "orbit" or cd2 <= 0.0 or orbit_r <= 42.0:
		state = "orbit"
		center = p.position
		orbit_r = 150.0
		orbit_a = (position - center).angle()
		cd2 = 6.0
	orbit_r = maxf(40.0, orbit_r - 20.0 * delta)
	orbit_a += (speed / orbit_r) * delta * (1.0 if sin(phase) > 0.0 else -1.0)
	var target := center + Vector2.from_angle(orbit_a) * orbit_r
	cd -= delta
	if cd <= 0.0:
		cd = 2.5
		var aim := _lead_dir(140.0)
		for k in [-1, 0, 1]:
			_shoot(aim.rotated(k * 0.3), 1.0)
		Sfx.play("enemy_shot")
	return ((target - position) * 4.0).limit_length(speed * 1.6)


## Colosse : avance lourdement vers toi, s'arrête pour viser (il clignote)... puis FONCE en ligne
## droite là où tu étais. S'arrête au bord de la page ou au bout de sa course.
func _colossus(delta: float, dirp: Vector2, dist: float) -> Vector2:
	st_t -= delta
	match state:
		"aim":
			flash = 0.6 if int(t * 14.0) % 2 == 0 else 0.0
			dash_dir = dirp   # suit le joueur des yeux jusqu'au dernier moment
			if st_t <= 0.0:
				state = "dash"
				st_t = 1.3
				Sfx.play("swing")
			return Vector2.ZERO
		"dash":
			if st_t <= 0.0:
				state = "rest"
				st_t = 1.2
			return dash_dir * speed * 7.0
		"rest":
			if st_t <= 0.0:
				state = "walk"
				st_t = randf_range(0.8, 1.6)
			return dirp * speed * 0.3
	# marche vers toi, puis se prépare à charger
	if st_t <= 0.0 and dist < 320.0:
		state = "aim"
		st_t = 0.7
	return dirp * speed


## Pâté : tache piégée qui fonce sur toi, gonfle quand elle arrive au contact et explose.
func _mine(delta: float, dirp: Vector2, dist: float) -> Vector2:
	if state == "arm":
		st_t -= delta
		flash = 0.7 if int(t * 18.0) % 2 == 0 else 0.0
		var s := base_scale * (1.0 + (0.9 - st_t) * 0.6)
		body.scale = Vector2(s, s)
		if st_t <= 0.0:
			_explode()
		return Vector2.ZERO
	contact = false
	if dist < 52.0:
		state = "arm"
		st_t = 0.9
		Sfx.play("zap")
		return Vector2.ZERO
	if t < 0.5:
		return Vector2.ZERO   # petite pause à l'apparition
	return dirp * speed * minf(1.4, 0.8 + t * 0.15)   # fonce, de plus en plus vite


# ------------------------------------------------------------------ Allié (Retouche)

## Redessiné dans le camp du joueur : fonce sur l'ennemi le plus proche et le frappe au contact.
func _ally_tick(delta: float) -> void:
	t += delta
	ally_t -= delta
	ally_cd -= delta
	if ally_t <= 0.0:
		arena.remove_ally(self)
		return
	var tg: Enemy = arena.nearest(position, 400.0)
	var v := Vector2.ZERO
	if tg:
		var to := tg.position - position
		v = to.normalized() * speed * 1.3
		if to.length() < radius + tg.radius + 2.0 and ally_cd <= 0.0:
			ally_cd = 0.5
			tg.hurt(maxf(4.0, dmg * 2.5), false, to.normalized() * 60.0)
	position += v * delta
	position.x = clampf(position.x, radius, Arena.W - radius)
	position.y = clampf(position.y, radius, Arena.H - radius)
	if absf(v.x) > 1.0:
		body.scale.x = base_scale * (-1.0 if v.x < 0.0 else 1.0)
	body.position.y = -absf(sin(t * 9.0)) * 1.5
	mat.set_shader_parameter("flash", 0.25 + 0.15 * sin(t * 8.0))
	queue_redraw()


# ------------------------------------------------------------------ Le Tableau noir

const GUM_R := 44.0


## Punaise : vise, fonce sur toi, puis reste plantée (piquante) un instant.
func _pin(delta: float, dirp: Vector2, dist: float) -> Vector2:
	match state:
		"aim":
			st_t -= delta
			flash = 0.4 if int(t * 16.0) % 2 == 0 else 0.0
			if st_t <= 0.0:
				state = "dash"
				st_t = 0.45
			return Vector2.ZERO
		"dash":
			st_t -= delta
			if st_t <= 0.0:
				state = "planted"
				st_t = 1.3
			return dash_dir * speed * 3.2
		"planted":
			st_t -= delta
			body.rotation = 0.0
			if st_t <= 0.0:
				state = "walk"
				cd = randf_range(0.6, 1.2)
			return Vector2.ZERO
	cd -= delta
	if cd <= 0.0 and dist < 210.0:
		state = "aim"
		st_t = 0.35
		dash_dir = dirp
	return dirp * speed * 0.45


## Craie : écrit une ligne de projectiles qui restent suspendus, puis partent tous vers toi.
func _chalk(delta: float, dirp: Vector2, dist: float) -> Vector2:
	cd -= delta
	if cd <= 0.0 and dist < 300.0:
		cd = 3.4
		var side := dirp.orthogonal()
		for k in 5:
			arena.spawn_enemy_bullet(self, position + dirp * 14.0 + side * (k - 2) * 10.0, Vector2.ZERO, 0.6 + k * 0.15)
		Sfx.play("enemy_shot")
	var want := 1.0 if dist > 170.0 else -0.8
	return (dirp * want + dirp.orthogonal() * 0.5).normalized() * speed


## Trombones : deux par deux, reliés par un fil qui coupe ; ils tournent autour d'un point
## (ta position d'il y a un instant) pour te trancher avec le fil.
func _clip(delta: float, p: Player, dirp: Vector2) -> Vector2:
	if partner == null:
		for o in arena.near(position, 90.0):
			if o != self and o.def.beh == "clip" and o.partner == null and not o.dead:
				partner = o
				o.partner = self
				o.orbit_a = orbit_a + PI
				break
	if partner != null and (not is_instance_valid(partner) or partner.dead):
		partner = null
	cd2 -= delta
	if state != "orbit" or cd2 <= 0.0:
		state = "orbit"
		center = p.position
		orbit_r = 110.0
		cd2 = 4.0
		if partner != null and get_instance_id() < partner.get_instance_id():
			orbit_a = (position - center).angle()
			partner.center = center
			partner.orbit_r = orbit_r
			partner.orbit_a = orbit_a + PI
			partner.cd2 = cd2
			partner.state = "orbit"
	orbit_r = maxf(50.0, orbit_r - 12.0 * delta)
	orbit_a += (speed / orbit_r) * delta
	# Le fil blesse le joueur (vérifié par un seul des deux)
	if partner != null and get_instance_id() < partner.get_instance_id():
		var q := Geometry2D.get_closest_point_to_segment(p.position, position, partner.position)
		if q.distance_to(p.position) < p.radius + 2.0:
			p.take_hit(dmg, element, null)
	var target := center + Vector2.from_angle(orbit_a) * orbit_r
	if partner == null:
		return dirp * speed
	return ((target - position) * 3.0).limit_length(speed * 1.8)


## Tampon encreur : saute très haut vers toi et s'écrase sur un carré annoncé au sol.
func _stamp(delta: float, dirp: Vector2, dist: float) -> Vector2:
	match state:
		"air":
			st_t -= delta
			var k := clampf(1.0 - st_t / 0.8, 0.0, 1.0)
			hop_h = sin(k * PI) * 28.0
			contact = false
			if st_t <= 0.0:
				state = "land"
				st_t = 0.6
				contact = true
				return Vector2.ZERO
			return (center - position) / maxf(st_t, 0.05)
		"land":
			st_t -= delta
			if st_t <= 0.0:
				state = "walk"
				cd = randf_range(1.2, 2.2)
			return Vector2.ZERO
	cd -= delta
	if cd <= 0.0 and dist < 230.0:
		state = "air"
		st_t = 0.8
		center = arena.player.position
		arena.add_square(center, 24.0, 0.8, dmg, ink_col)
	return dirp * speed * 0.5


## Brouillon (tank) : se froisse à 66 % et 33 % de ses PV : plus petit, plus rapide, et crache.
func _crumple(dirp: Vector2) -> Vector2:
	var stage := 0 if hp > max_hp * 0.66 else (1 if hp > max_hp * 0.33 else 2)
	if stage > crumple:
		crumple = stage
		base_scale *= 0.8
		body.scale = Vector2(base_scale, base_scale)
		radius *= 0.85
		_ring(8, randf() * TAU, 0.8)
		arena.float_text(position + Vector2(0, -16), "FROISSÉ !", Pal.TEXT)
		arena.burst(position, Color.WHITE, 10, 90.0)
	return dirp * speed * (1.0 + 0.5 * crumple)


## Gomme mie de pain (tank) : efface les projectiles du joueur autour d'elle.
func _gum(dirp: Vector2) -> Vector2:
	for b in arena.bullets:
		if b.hostile or b.lob_r > 0.0 or b.burst_r > 0.0 or b.life <= 0.0:
			continue
		if b.position.distance_squared_to(position) < GUM_R * GUM_R:
			b.life = -1.0
			arena.burst(b.position, Color(1, 1, 1, 0.8), 2, 30.0)
	return dirp * speed


## Équation (tank) : avance lentement et « calcule » : chaque résultat est une punaise.
func _equation(delta: float, dirp: Vector2) -> Vector2:
	cd -= delta
	if cd <= 0.0:
		cd = 5.0
		if Run.enemy_art.has("punaise") and arena.enemies.size() < Arena.MAX_ENEMIES - 10:
			_summon("punaise", 2)
			arena.float_text(position + Vector2(0, -22), "= ?", Pal.TEXT)
	return dirp * speed


## Le Professeur : interros surprises (colonnes, une seule bonne réponse), salves de craie, punaises.
func _boss_prof(delta: float, dirp: Vector2, dist: float) -> Vector2:
	cd -= delta
	cd2 -= delta
	cd3 -= delta
	if cd2 <= 0.0:
		cd2 = 7.0 if _enraged() else 9.5
		arena.quiz(4 if _enraged() else 3, dmg * 1.3)
	if cd <= 0.0:
		cd = 1.6 if _enraged() else 2.3
		for k in range(-3, 4):
			_shoot(dirp.rotated(k * 0.16), 1.0)
		Sfx.play("enemy_shot")
	if cd3 <= 0.0:
		cd3 = 11.0
		if Run.enemy_art.has("punaise"):
			_summon("punaise", 3)
	return dirp * speed * (1.0 if dist > 150.0 else -0.6)


## La Photocopieuse : chaque salve a sa COPIE qui arrive du côté opposé ; scanner qui balaie
## l'écran ; en rage, bourrage papier (immobile et vulnérable) puis anneau de feuilles.
func _boss_copy(delta: float, dirp: Vector2, dist: float) -> Vector2:
	if state == "jam":
		st_t -= delta
		flash = 0.35 if int(t * 10.0) % 2 == 0 else 0.0
		if st_t <= 0.0:
			state = "walk"
			_ring(24, randf() * TAU, 0.8)
		return Vector2.ZERO
	cd -= delta
	cd2 -= delta
	cd3 -= delta
	if cd <= 0.0:
		cd = 2.2 if _enraged() else 3.0
		for k in range(-4, 5):
			_shoot(dirp.rotated(k * 0.14), 0.9)
		var mp := Vector2(Arena.W - position.x, Arena.H - position.y)
		arena.ghost_volley(self, mp, 9, 0.14, 0.8)
		Sfx.play("enemy_shot")
	if cd2 <= 0.0:
		cd2 = 8.0 if _enraged() else 11.0
		arena.scan(dmg, 1 if _enraged() else 2)
	if cd3 <= 0.0 and _enraged():
		cd3 = 12.0
		state = "jam"
		st_t = 2.2
		arena.float_text(position + Vector2(0, -34), "BOURRAGE PAPIER !", Pal.ACCENT)
	return dirp.orthogonal() * speed * 0.8 + dirp * speed * (0.4 if dist > 160.0 else -0.4)


## L'Encrier renversé, boss final du Tableau noir, en 3 PHASES (66 % et 33 % de PV) :
## 1. L'encre se renverse : inondation (grosses gouttes), spirale, charge qui laisse une traînée d'encre.
##    Ses gouttes et ses coups TACHENT ton perso (ta couleur tire vers l'Ombre) ; des BUVARDS
##    apparaissent pour te nettoyer.
## 2. Éclats de lumière : ses tirs deviennent de la LUMIÈRE (×1,5 sur un perso Ombre), projecteur
##    (double anneau) et NUIT D'ENCRE, où seuls ses éclats de lumière brillent.
## 3. Taches de Rorschach : il se dédouble en MIROIR ; le reflet copie chaque attaque (PV partagés).
func _boss_ink(delta: float, dirp: Vector2, dist: float) -> Vector2:
	var want := 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
	if want > toile_phase:
		toile_phase = want
		_ink_transition()
	if boss_inv > 0.0:
		boss_inv -= delta
		flash = 0.6 if int(t * 12.0) % 2 == 0 else 0.1
		return Vector2.ZERO
	light_shots = toile_phase >= 2
	var fast: float = [1.0, 1.0, 1.15, 1.3][toile_phase]
	var twin := is_instance_valid(reflet) and not reflet.dead
	# Buvards : de quoi se nettoyer quand on est taché
	blot_cd -= delta
	if blot_cd <= 0.0:
		blot_cd = 7.0
		if arena.player.stains > 0 and arena.blotters.size() < (2 if toile_phase >= 3 else 1):
			arena.spawn_blotter(position)
	if state == "dash":
		st_t -= delta
		cd3 -= delta
		if cd3 <= 0.0:
			cd3 = 0.05
			arena.add_hazard(position, 8.0, 3.0, 0.8, dmg * 0.35, ink_col)
			if twin:
				arena.add_hazard(reflet.position, 8.0, 3.0, 0.8, dmg * 0.35, ink_col)
		if st_t <= 0.0:
			state = "walk"
			_ring(18, randf() * TAU, 0.9)
		return dash_dir * speed * 4.5
	if state == "spiral":
		st_t -= delta
		cd3 -= delta
		if cd3 <= 0.0:
			cd3 = 0.08
			spiral_a += 0.31
			for k in 3:
				_shoot(Vector2.from_angle(spiral_a + TAU * k / 3.0), 0.85)
			Sfx.play("enemy_shot")
		if st_t <= 0.0:
			state = "walk"
		return dirp * speed * 0.3
	if state == "aim":
		st_t -= delta
		flash = 0.5 if int(t * 14.0) % 2 == 0 else 0.0
		if st_t <= 0.0:
			state = "dash"
			st_t = 0.55
		return Vector2.ZERO
	cd -= delta * fast
	cd2 -= delta
	if cd <= 0.0:
		cd = 3.0
		pattern = (pattern + 1) % (3 if toile_phase == 1 else 4)
		match pattern:
			0:
				# Inondation : grosses gouttes en cloche qui TACHENT et laissent de larges flaques
				for k in 5:
					arena.lob(self, arena.player.position + Vector2.from_angle(randf() * TAU) * randf_range(0.0, 90.0), 1.2, 34.0)
				if twin:
					for k in 3:
						arena.lob(self, arena.player.position + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 90.0), 1.3, 34.0, reflet.position)
			1:
				state = "spiral"
				st_t = 2.4
			2:
				state = "aim"
				st_t = 0.6
				dash_dir = dirp
				arena.add_ruler(position, _wall_point(position, dirp), 0.6)
				if twin:
					var md := Vector2(-dirp.x, dirp.y)
					arena.add_ruler(reflet.position, _wall_point(reflet.position, md), 0.6)
			3:
				# Projecteur : deux anneaux de lumière, le 2e décalé (on se glisse entre les éclats)
				var a0 := randf() * TAU
				_ring(16, a0, 0.75)
				var me := self
				arena._after(0.45, func():
					if is_instance_valid(me) and not me.dead and not arena.ended:
						me._ring(16, a0 + PI / 16.0, 0.95))
				arena.float_text(position + Vector2(0, -40), "PROJECTEUR !", Pal.ACCENT)
	if toile_phase >= 2 and cd2 <= 0.0:
		cd2 = 14.0
		arena.darkness(6.0)
		arena.float_text(position + Vector2(0, -40), "NUIT D'ENCRE !", Pal.BAD)
	return dirp * speed * (1.0 if dist > 120.0 else 0.3)


## Passage de phase de l'Encrier : intouchable 1,5 s, onde qui repousse ; en phase 3, il se dédouble.
func _ink_transition() -> void:
	boss_inv = 1.5
	state = "walk"
	cd = 1.8
	cd2 = 4.0
	arena.hud.announce("ÉCLATS DE LUMIÈRE !" if toile_phase == 2 else "TACHES DE RORSCHACH !", Pal.BAD)
	arena.shake(12.0)
	arena.hitstop(0.2)
	Sfx.play("boss")
	arena.explosion(position, 140.0, Color(ink_col, 0.9))
	var p := arena.player
	var away := (p.position - position).normalized()
	p.position = (p.position + away * 70.0).clamp(Vector2(12, 12), Vector2(Arena.W - 12, Arena.H - 12))
	if toile_phase == 3:
		_split()


## Taches de Rorschach : un reflet de l'Encrier apparaît en miroir (axe vertical au centre de la page).
## Il copie chaque mouvement et chaque tir ; les coups qu'il prend vont à l'Encrier (PV partagés).
func _split() -> void:
	if absf(position.x - Arena.W / 2.0) < 90.0:
		position.x = Arena.W * (0.28 if position.x < Arena.W / 2.0 else 0.72)
	var tw := arena._spawn_enemy_raw(id, Vector2(Arena.W - position.x, position.y), false)
	arena.boss = self
	if tw == null:
		return
	tw.reflet_of = self
	tw.is_boss = false
	tw.max_hp = 1e9
	tw.hp = 1e9
	tw.loot = 0.0
	tw.dmg = dmg
	tw.boss_inv = boss_inv
	reflet = tw
	arena.burst(tw.position, ink_col, 30, 140.0)
	arena.burst(position, ink_col, 30, 140.0)


## Le reflet de Rorschach : il suit l'Encrier en miroir, ne pense pas tout seul.
func _reflet_tick(delta: float) -> void:
	var m := reflet_of
	if not is_instance_valid(m) or m.dead:
		dead = true
		arena.burst(position, ink_col, 24, 120.0)
		arena.enemies.erase(self)
		queue_free()
		return
	t += delta
	position = Vector2(Arena.W - m.position.x, m.position.y)
	contact = m.contact
	boss_inv = m.boss_inv
	flash = maxf(m.flash, maxf(0.0, flash - delta * 7.0))
	body.scale = Vector2(-m.body.scale.x, m.body.scale.y)
	body.rotation = -m.body.rotation
	body.position = m.body.position
	mat.set_shader_parameter("flash", flash)


# ------------------------------------------------------------------ Attaques

func _shoot(dir: Vector2, speed_mult: float) -> void:
	arena.spawn_enemy_bullet(self, position, dir * 140.0 * speed_mult, 0.0, light_shots)
	if is_instance_valid(reflet) and not reflet.dead:
		# Rorschach : le reflet tire la même chose, en miroir
		arena.spawn_enemy_bullet(self, reflet.position, Vector2(-dir.x, dir.y) * 140.0 * speed_mult, 0.0, light_shots)


func _ring(n: int, offset := 0.0, speed_mult := 1.0) -> void:
	if _frenzy():
		n += ceili(n / 3.0)   # fureur : un tiers de projectiles en plus
	for i in n:
		_shoot(Vector2.from_angle(offset + TAU * i / n), speed_mult)
	Sfx.play("enemy_shot")


func _explode() -> void:
	arena.explosion(position, 48.0, Color(ink_col, 0.8))
	if position.distance_to(arena.player.position) < 48.0 + arena.player.radius:
		arena.player.take_hit(dmg, element, self)
	arena.add_hazard(position, 22.0, 3.0, 0.55, 0.0, ink_col)
	contact = false
	arena.kill_enemy(self)


func _summon(type_id: String, n: int) -> void:
	for i in n:
		arena.spawn_enemy_now(type_id, position + Vector2.from_angle(randf() * TAU) * (radius + 16.0), false)


func _enraged() -> bool:
	return hp < max_hp * 0.5


## Hachures (La Muse, vague 10) : elle RATURE la page. Enchaîne ses 4 attaques dans un ordre mélangé (toutes avant de recommencer) :
## - Zigzag : 3 petites charges (5 enragé), chacune annoncée à la règle, qui laissent un trait d'encre.
## - Hachures : des lignes parallèles barrent la page (on se glisse ENTRE elles) ; enragé : en croisillon.
## - Croix : il barre ta position d'un X (3 de suite), le centre explose.
## - Gribouillage : il griffonne sur place, crachant de l'encre au hasard, et libère des Gribouillis.
func _boss_hatch(delta: float, dirp: Vector2, dist: float) -> Vector2:
	var rage := _enraged()
	st_t -= delta
	match state:
		"walk":
			if st_t <= 0.0:
				# Sac mélangé : les 4 attaques passent avant qu'une revienne (jamais 2 fois de suite)
				if atk_bag.is_empty():
					atk_bag = ["zigzag", "hatch", "cross", "scribble"]
					atk_bag.shuffle()
					if atk_bag[0] == last_atk:
						atk_bag.reverse()
				last_atk = atk_bag.pop_front()
				flash = 0.8
				match last_atk:
					"zigzag":
						state = "zz_aim"
						cd2 = 5 if rage else 3
						_zz_aim(dirp)
					"hatch":
						state = "hatch"
						st_t = 2.2
						_hatch(randf() * PI, 0.0)
						if rage:
							cd3 = 0.9   # 2e passe perpendiculaire
					"cross":
						state = "cross"
						cd2 = 3
						cd3 = 0.0
						st_t = 2.0
					"scribble":
						state = "scribble"
						st_t = 2.2
						cd3 = 0.0
						arena.float_text(position + Vector2(0, -40), "GRIBOUILLAGE !", Pal.BAD)
				return Vector2.ZERO
			return dirp * speed * (1.0 if dist > 90.0 else 0.4)
		"zz_aim":
			flash = 0.5 if int(t * 16.0) % 2 == 0 else 0.0
			if st_t <= 0.0:
				state = "zz_dash"
				st_t = 0.32
				Sfx.play("swing")
			return Vector2.ZERO
		"zz_dash":
			cd -= delta
			if cd <= 0.0:
				cd = 0.04
				arena.add_hazard(position, 7.0, 2.2, 1.0, dmg * 0.4, ink_col)
			if st_t <= 0.0:
				cd2 -= 1
				if cd2 > 0:
					state = "zz_aim"
					_zz_aim(dirp)
				else:
					_rest(rage)
			return dash_dir * speed * 5.0
		"hatch":
			if cd3 > 0.0:
				cd3 -= delta
				if cd3 <= 0.0:
					_hatch(hatch_a + PI / 2.0, 24.0)   # croisillon, décalé d'une demi-maille
			if st_t <= 0.0:
				_rest(rage)
			return dirp * speed * 0.2
		"cross":
			cd3 -= delta
			if cd3 <= 0.0 and cd2 > 0:
				cd2 -= 1
				cd3 = 0.45 if rage else 0.6
				var c := arena.player.position + arena.player_vel() * 0.25
				var r := 46.0
				var a0 := randf() * PI
				for k in 2:
					var d := Vector2.from_angle(a0 + k * PI / 2.0)
					arena.add_stroke(c + d * r, c - d * r, 0.85, dmg * 0.4, ink_col)
				arena.add_stroke(c, c, 0.85, dmg * 0.4, ink_col, 26.0)
				Sfx.play("zap")
			if st_t <= 0.0:
				_rest(rage)
			return Vector2.ZERO
		"scribble":
			cd3 -= delta
			if cd3 <= 0.0:
				cd3 = 0.06 if rage else 0.09
				body.rotation = randf_range(-0.4, 0.4)
				_shoot(Vector2.from_angle(randf() * TAU), randf_range(0.7, 1.3))
			if st_t <= 0.0:
				_summon("gribouille", 3 if rage else 2)
				_rest(rage)
			# tremble sur place en griffonnant
			return Vector2.from_angle(t * 40.0) * 30.0
	_rest(rage)
	return Vector2.ZERO


func _rest(rage: bool) -> void:
	state = "walk"
	st_t = 1.0 if rage else 1.7
	flash = 0.0


## Zigzag : vise le joueur (en anticipant un peu) et l'annonce à la règle.
func _zz_aim(dirp: Vector2) -> void:
	var aim := (arena.player.position + arena.player_vel() * 0.3 - position).normalized()
	dash_dir = aim if aim != Vector2.ZERO else dirp
	st_t = 0.4
	var reach := speed * 5.0 * 0.32
	arena.add_ruler(position, position + dash_dir * reach, 0.4)


## Hachures : lignes parallèles sur toute la page, espacées de 48 px (on passe entre).
func _hatch(angle: float, shift: float) -> void:
	hatch_a = angle
	var dir := Vector2.from_angle(angle)
	var nrm := dir.orthogonal()
	var c := arena.player.position
	for k in range(-6, 7):
		var o := c + nrm * (k * 48.0 + shift)
		if o.x < 0.0 or o.y < 0.0 or o.x > Arena.W or o.y > Arena.H:
			continue
		arena.add_stroke(_wall_point(o, dir), _wall_point(o, -dir), 1.0, dmg * 0.4, ink_col)
	Sfx.play("zap")


func _boss_critique(delta: float, dirp: Vector2) -> Vector2:
	cd -= delta
	if state == "spiral":
		st_t -= delta
		cd3 -= delta
		if cd3 <= 0.0:
			cd3 = 0.09
			spiral_a += 0.38
			var arms := 3 if _enraged() else 2
			for k in arms:
				_shoot(Vector2.from_angle(spiral_a + TAU * k / arms), 0.9)
			Sfx.play("enemy_shot")
		if st_t <= 0.0:
			state = "walk"
			cd = 1.6 if _enraged() else 2.4
	elif cd <= 0.0:
		state = "spiral"
		st_t = 2.6
	cd2 -= delta
	if cd2 <= 0.0:
		cd2 = 7.0 if _enraged() else 9.0
		_summon("tache", 4)
		# Le Critique « note » ta position : pâtés d'encre en cloche
		for k in 3:
			arena.lob(self, arena.player.position + Vector2.from_angle(TAU * k / 3.0) * 30.0, 1.2)
	return dirp * speed * (0.4 if state == "spiral" else 1.0)


func _boss_orbit(delta: float, dirp: Vector2, dist: float) -> Vector2:
	if state == "fade":
		st_t -= delta
		mat.set_shader_parameter("alpha", clampf(st_t / 0.5, 0.15, 1.0))
		if st_t <= 0.0:
			position = tp_pos
			tp_mark.t = 0.0   # la cible s'efface quand il arrive
			mat.set_shader_parameter("alpha", 1.0)
			contact = true
			state = "walk"
			_ring(16 if _enraged() else 12, randf() * TAU, 0.9)
		return Vector2.ZERO
	cd -= delta
	cd2 -= delta
	if cd2 <= 0.0:
		cd2 = 1.6 if _enraged() else 2.3   # (le 1er boss tire moins souvent)
		for k in range(-2, 3):
			_shoot(dirp.rotated(k * 0.2), 1.1)
		Sfx.play("enemy_shot")
	if cd <= 0.0:
		cd = 4.5 if _enraged() else 5.5
		state = "fade"
		st_t = 1.0   # le point d'arrivée est annoncé 1 s avant
		contact = false
		var p := arena.player.position
		tp_pos = p + Vector2.from_angle(randf() * TAU) * randf_range(70.0, 120.0)
		tp_pos.x = clampf(tp_pos.x, 30.0, Arena.W - 30.0)
		tp_pos.y = clampf(tp_pos.y, 30.0, Arena.H - 30.0)
		tp_mark = {"pos": tp_pos, "t": 2.0, "boss": true}
		arena.telegraphs_fx.append(tp_mark)
	var tang := dirp.orthogonal()
	return (tang + dirp * clampf((dist - 95.0) / 50.0, -1.0, 1.0)).normalized() * speed


## La Toile Blanche : spirales, anneaux, charges, renforts... et elle GOMME des bouts de ton perso.
## La Toile Blanche, boss final de La Feuille, en 3 PHASES (66 % et 33 % de PV) :
## 1. spirale, anneaux, charge, renforts, coups de gomme ;
## 2. tout va 30 % plus vite, pluie de gommes, et la page commence à s'effacer par les bords ;
## 3. presque sans pause (70 % plus vite), gommes pendant la spirale, la page rétrécit encore.
## À chaque palier : elle est intouchable 1,5 s, une onde te repousse, « LA TOILE S'EFFACE... ».
func _boss_toile(delta: float, dirp: Vector2, dist: float) -> Vector2:
	var want := 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
	if want > toile_phase:
		toile_phase = want
		_toile_transition()
	if boss_inv > 0.0:
		boss_inv -= delta
		flash = 0.6 if int(t * 12.0) % 2 == 0 else 0.1
		return Vector2.ZERO
	var fast: float = [1.0, 1.0, 1.3, 1.7][toile_phase]
	cd -= delta * fast
	if state == "dash":
		st_t -= delta
		if st_t <= 0.0:
			state = "walk"
		return dash_dir * speed * 5.0
	if state == "aim":
		st_t -= delta
		flash = 0.5 if int(t * 14.0) % 2 == 0 else 0.0
		if st_t <= 0.0:
			state = "dash"
			st_t = 0.5
			dash_dir = dirp
		return Vector2.ZERO
	if state == "rings":
		cd3 -= delta * fast
		if cd3 <= 0.0:
			cd3 = 0.5
			_ring(18 + 4 * (toile_phase - 1), repeat * 0.17, 0.9)
			repeat -= 1
			if repeat <= 0:
				state = "walk"
		return dirp * speed * 0.5
	if state == "spiral":
		st_t -= delta
		cd3 -= delta
		cd2 -= delta
		if cd3 <= 0.0:
			cd3 = 0.08 / fast
			spiral_a += 0.33
			for k in 4:
				_shoot(Vector2.from_angle(spiral_a * (1 if k % 2 == 0 else -1) + TAU * k / 4), 0.85)
			Sfx.play("enemy_shot")
		if toile_phase >= 3 and cd2 <= 0.0:
			cd2 = 1.0   # phase 3 : des gommes tombent pendant la spirale
			arena.add_eraser(arena.player.position, 30.0, 1.2, dmg)
		if st_t <= 0.0:
			state = "walk"
		return dirp * speed * 0.3
	if cd <= 0.0:
		cd = 1.4 if toile_phase >= 3 else 3.2
		pattern = (pattern + 1) % (5 if toile_phase == 1 else 6)
		match pattern:
			0:
				state = "spiral"
				st_t = 3.0
				cd2 = 0.5
			1:
				state = "rings"
				repeat = 3 + (toile_phase - 1)
				cd3 = 0.0
			2:
				state = "aim"
				st_t = 0.6 / fast
			3:
				var pool := EnemyDB.pool(Run.wave)
				_summon(pool.pick_random(), 2 + (toile_phase - 1))
				_summon("tache", 2)
			4:
				# Coups de gomme : là où ils tombent, ton dessin s'efface
				var p := arena.player.position
				arena.add_eraser(p, 34.0, 1.1, dmg)
				if toile_phase >= 2:
					for k in 2:
						arena.add_eraser(p + Vector2.from_angle(randf() * TAU) * 60.0, 30.0, 1.4, dmg)
			5:
				# Phase 2+ : pluie de gommes autour de toi
				var c := arena.player.position
				arena.add_eraser(c, 28.0, 1.3, dmg)
				for k in 4 + 2 * (toile_phase - 2):
					arena.add_eraser(c + Vector2.from_angle(TAU * k / (4.0 + 2 * (toile_phase - 2)) + randf() * 0.4) * randf_range(45.0, 80.0), 26.0, 1.5 + k * 0.12, dmg)
				arena.float_text(position + Vector2(0, -50), "PLUIE DE GOMMES", Pal.BAD)
	return dirp * speed * (0.6 if dist < 80.0 else 1.0)


## Passage de phase : intouchable 1,5 s, onde qui repousse, la page s'efface par les bords.
func _toile_transition() -> void:
	boss_inv = 1.5
	state = "walk"
	cd = 1.8
	arena.hud.announce("LA TOILE S'EFFACE..." if toile_phase == 2 else "TOUT DOIT DISPARAÎTRE !", Pal.BAD)
	arena.shake(12.0)
	arena.hitstop(0.2)
	Sfx.play("boss")
	arena.explosion(position, 140.0, Color(1, 1, 1, 0.9))
	var p := arena.player
	var away := (p.position - position).normalized()
	p.position = (p.position + away * 70.0).clamp(Vector2(12, 12), Vector2(Arena.W - 12, Arena.H - 12))
	arena.void_target = 0.06 if toile_phase == 2 else 0.113   # zone de jeu : 77 % puis 60 %
	arena.void_dmg = dmg * 0.35


