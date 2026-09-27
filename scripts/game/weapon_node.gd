class_name WeaponNode
extends Node2D
## Une arme dessinée, posée à un endroit choisi sur le perso, qui attaque toute seule
## l'ennemi le plus proche. Le type d'arme décide COMMENT elle attaque :
## mêlée  : thrust (estoc), sweep (arc), spin (tour complet), slam (onde de choc)
## distance : shot, spread (éventail), homing (tête chercheuse), lob (obus explosif)
## spéciales (épiques+) : trail (Pinceau), orbit (Compas), stamp (Tampon)
## légendaires : erase (Gomme sacrée), prism (Palette vivante), clone (Autoportrait)

var player: Player
var w: Dictionary
var st: Dictionary
var art: Dictionary
var cd := 0.0
var sprite: Sprite2D
var length := 16.0
var attacking := false
var atk_t := 0.0
var atk_dir := Vector2.RIGHT
var atk_angle := 0.0
var slam_point := Vector2.ZERO
var slam_done := false
var hit_ids := {}
var aim := 0.0
var recoil := 0.0
var bullet_tex: Array = []
var own_tex: Texture2D
var stamp_mask: Image       # Tampon : le dessin agrandi, sert de zone de dégâts
var stamp_ghost: Image      # ... et de trace au sol
var stamp_tex: Texture2D
var orbs: Array = []        # Palette vivante : un orbe par couleur {tex, wst, mult}
var clone_tex: Texture2D    # Autoportrait
var orbit_a := 0.0
var orbit_hits := {}
var paint_last := Vector2.INF
var trail: Line2D            # traînée du coup (coordonnées du monde)
var trail_pts: Array = []


func setup(p: Player, weapon: Dictionary) -> void:
	player = p
	w = weapon
	st = weapon.st
	art = Run.art_of(w)
	# En combat on utilise le dessin D'ORIGINE : son côté droit est la pointe / le canon, qui vise
	# l'ennemi. La rotation / le miroir choisis au rangement ne servent que pour la pose au repos.
	var trimmed := Analyzer.trim(art.image)
	length = trimmed.get_width()
	own_tex = Gfx.texture(trimmed)
	sprite = Gfx.sprite(own_tex, Gfx.material(art.effect, art.get("outline", true)))
	add_child(sprite)
	z_index = 1
	cd = randf() * st.cooldown
	if st.kind == "ranged":
		for b in st.bullets:
			bullet_tex.append(Gfx.texture(b.image))
	match st.style:
		"stamp":
			var sc: float = 2.0 * Stats.RAR_REACH[w.rar]
			stamp_mask = trimmed.duplicate()
			stamp_mask.resize(maxi(1, roundi(trimmed.get_width() * sc)), maxi(1, roundi(trimmed.get_height() * sc)), Image.INTERPOLATE_NEAREST)
			stamp_tex = Gfx.texture(stamp_mask)
			stamp_ghost = stamp_mask.duplicate()
			for y in stamp_ghost.get_height():
				for x in stamp_ghost.get_width():
					var c := stamp_ghost.get_pixel(x, y)
					if c.a > 0.0:
						stamp_ghost.set_pixel(x, y, Color(c, c.a * 0.4))
		"prism":
			var frac: Array = art.a.frac
			for el in Pal.COUNT:
				if frac[el] < 0.04:
					continue
				var f := []
				f.resize(Pal.COUNT)
				f.fill(0.0)
				var wst := st.duplicate()
				if el > 0:
					f[el] = 1.0   # effet élémentaire garanti
				wst.frac = f
				orbs.append({"tex": Gfx.texture(WeaponDB.orb(Pal.main_color(el) if el > 0 else Pal.INK)), "wst": wst,
					"mult": 1.0 if el > 0 else 1.3})
			if orbs.is_empty():
				orbs.append({"tex": bullet_tex[0], "wst": st, "mult": 1.3})
		"clone":
			clone_tex = Gfx.texture(Analyzer.trim(Run.build_player_image()))
		"orbit":
			orbit_a = randf() * TAU
	position = _home()
	if st.kind == "melee":
		trail = Line2D.new()
		trail.top_level = true
		trail.width = 4.0
		trail.z_index = 2
		var el := Run.weapon_element(w)
		var tc: Color = Pal.main_color(el) if el > 0 else Color.WHITE
		var g := Gradient.new()
		g.set_color(0, Color(tc, 0.0))
		g.set_color(1, Color(tc, 0.55))
		trail.gradient = g
		trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
		trail.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(trail)


## Position choisie par le joueur sur son perso (suit le perso quand il se retourne).
func _home() -> Vector2:
	var a: Vector2 = w.anchor
	return Vector2(a.x * player.body.scale.x, a.y) + player.body.position


## Pose au repos (aucun ennemi à portée) : celle choisie au rangement, en miroir quand le perso
## regarde à gauche.
func _rest_pose() -> void:
	var left := player.body.scale.x < 0.0
	var rest := float(w.get("rot", 0)) * PI / 2.0
	var target_rot := PI - rest if left else rest
	var fl: bool = w.get("flip", false)
	rotation = lerp_angle(rotation, target_rot, 0.25)
	aim = rotation
	# Miroir gauche/droite de la pose = pivoter de 180° (PI - rest) et retourner verticalement.
	sprite.flip_h = fl
	sprite.flip_v = left


func _atk_mult() -> float:
	var m: float = 1.0 + player.st.atk_speed / 100.0
	if player.arena.elapsed < 10.0:
		m += 0.6 * Run.amulet_count("croquis_rapide")
	return maxf(0.2, m)


func _range_mult() -> float:
	return 1.0 + player.st.range / 100.0


func tick(delta: float) -> void:
	var arena := player.arena
	cd -= delta * _atk_mult()
	_update_trail()
	if st.style == "orbit":
		_orbit_step()
		return
	var home := _home()
	var rng: float
	if st.kind == "melee":
		rng = st.reach * _range_mult() + 10.0
		if st.style == "spin":
			rng = st.reach * _range_mult() * 0.9
	else:
		rng = st.range * _range_mult()
	var origin := player.position + home
	var target: Enemy = arena.nearest(origin, rng)

	if attacking:
		_melee_step(delta)
		return

	position = position.lerp(home, 0.5)
	if target:
		var want := (target.position - origin).angle()
		if Run.amulet_count("pinceau_fou") > 0:
			want = randf() * TAU
		aim = lerp_angle(aim, want, 0.3)
		rotation = aim
		sprite.flip_h = false
		sprite.flip_v = cos(aim) < 0.0   # visée à gauche : miroir pour garder l'arme à l'endroit
	else:
		_rest_pose()
	recoil = lerpf(recoil, 0.0, 0.25)
	sprite.position.x = -recoil

	if cd <= 0.0 and target:
		cd = st.cooldown
		# Double exposition : l'attaque se relance aussitôt
		if Run.amulet_count("double_expo") > 0 and randf() < 0.25:
			cd = 0.06
		if st.kind == "melee":
			_start_melee(target)
		else:
			_fire(target)


# ------------------------------------------------------------------ Mêlée

func _start_melee(target: Enemy) -> void:
	attacking = true
	atk_t = 0.0
	slam_done = false
	hit_ids.clear()
	var origin := player.position + _home()
	atk_dir = (target.position - origin).normalized()
	atk_angle = atk_dir.angle()
	var reach: float = st.reach * _range_mult()
	slam_point = origin + atk_dir * minf(origin.distance_to(target.position), reach)
	paint_last = Vector2.INF
	sprite.flip_h = false
	Sfx.play("swing")
	if st.style == "erase":
		_erase_line(origin)
	var dt := Run.amulet_count("double_trait")
	for i in dt:
		var a := atk_angle + (i - (dt - 1) / 2.0) * 0.25
		var p := player.arena.spawn_bullet(origin, Vector2.from_angle(a) * 260.0,
			{"damage": st.damage * 0.6, "radius": st.hit_r, "pierce": 2}, st, own_tex, art.effect, 1.2, art.get("outline", true))
		p.spin = 12.0


func _melee_step(delta: float) -> void:
	var dur := 0.3
	match st.style:
		"spin":
			dur = 0.45
		"slam", "stamp":
			dur = 0.5
		"erase":
			dur = 0.35
	dur *= clampf(st.cooldown / 0.6, 0.35, 1.0)   # petites armes rapides = coups plus vifs
	atk_t += delta / (dur / sqrt(_atk_mult()))
	var t := clampf(atk_t, 0.0, 1.0)
	var reach: float = st.reach * _range_mult()
	var home := _home()
	var hit_on := false
	match st.style:
		"thrust", "erase":
			var ext := sin(t * PI)
			position = home * (1.0 - ext) + (home + atk_dir * reach) * ext
			rotation = atk_angle
			hit_on = ext > 0.35 and st.style == "thrust"
		"sweep", "trail":
			var a := atk_angle - 1.2 + 2.4 * t
			var ext := sin(t * PI)
			position = home * (1.0 - ext) + (home + Vector2.from_angle(a) * reach * 0.75) * ext
			rotation = a
			hit_on = ext > 0.25
		"spin":
			var a := atk_angle + TAU * t
			var ext := minf(1.0, sin(t * PI) * 2.0)
			position = home * (1.0 - ext) + Vector2.from_angle(a) * reach * 0.8 * ext
			rotation = a
			hit_on = ext > 0.4
		"slam", "stamp":
			# Monte, fonce sur le point d'impact, puis revient
			var local_target := slam_point - player.position
			if t < 0.6:
				var k := t / 0.6
				position = home.lerp(local_target, k * k) + Vector2(0, -sin(k * PI) * 18.0)
				rotation = atk_angle - 1.4 * (1.0 - k)
			else:
				if not slam_done:
					slam_done = true
					if st.style == "stamp":
						_stamp_impact()
					else:
						_slam_impact()
				position = local_target.lerp(home, (t - 0.6) / 0.4)
				rotation = atk_angle
	sprite.flip_v = cos(rotation) < 0.0
	if hit_on:
		var tip := player.position + position + Vector2.from_angle(rotation) * length * 0.3
		for e in player.arena.near(tip, st.hit_r):
			var id: int = e.get_instance_id()
			if hit_ids.has(id):
				continue
			hit_ids[id] = true
			player.arena.hit_enemy(e, st.damage, st, Vector2.from_angle(rotation), st.knock)
		if st.style == "trail":
			_paint(tip)
	if atk_t >= 1.0:
		attacking = false
		aim = rotation


func _slam_impact() -> void:
	var arena := player.arena
	var r: float = st.aoe * _range_mult()
	arena.explosion(slam_point, r, Color(Pal.INK, 0.7))
	arena.shake(4.0)
	for e in arena.near(slam_point, r):
		arena.hit_enemy(e, st.damage, st, (e.position - slam_point).normalized(), st.knock * 1.5)


## Traînée : la pointe laisse un sillage pendant les coups (et le Compas en permanence).
func _update_trail() -> void:
	if trail == null:
		return
	var active: bool = attacking or st.style == "orbit"
	if active:
		trail_pts.append(global_position + Vector2.from_angle(global_rotation) * length * 0.45)
		while trail_pts.size() > (10 if st.style == "orbit" else 7):
			trail_pts.pop_front()
	elif not trail_pts.is_empty():
		trail_pts.pop_front()
	trail.points = PackedVector2Array(trail_pts)


## Pinceau : dépose des flaques d'encre amies le long du coup.
func _paint(tip: Vector2) -> void:
	if tip.distance_to(paint_last) < st.hit_r * 0.8:
		return
	paint_last = tip
	player.arena.add_zone(tip, st.hit_r * 0.9, 2.5, st.damage * 0.7, Run.weapon_element(w))


## Compas : tourne en permanence autour du perso et coupe tout ce qu'il croise.
func _orbit_step() -> void:
	var arena := player.arena
	var period := 0.9 * clampf(st.cooldown / 0.85, 0.5, 1.4) / _atk_mult()
	orbit_a = wrapf(orbit_a + TAU * get_process_delta_time() / period, 0.0, TAU)
	var r: float = st.reach * _range_mult() * 0.75
	position = _home() + Vector2.from_angle(orbit_a) * r
	rotation = orbit_a + PI / 2.0
	sprite.flip_v = false
	sprite.flip_h = false
	var now := arena.elapsed
	var tip := player.position + position
	for e in arena.near(tip, st.hit_r + length * 0.3):
		var id: int = e.get_instance_id()
		if now - float(orbit_hits.get(id, -99.0)) < period * 0.5:
			continue
		orbit_hits[id] = now
		arena.hit_enemy(e, st.damage, st, Vector2.from_angle(orbit_a), st.knock * 0.5)
	if orbit_hits.size() > 300:
		orbit_hits.clear()


## Tampon : le dessin (agrandi) s'imprime au sol. Seuls les ennemis SOUS l'encre prennent le coup.
func _stamp_impact() -> void:
	var arena := player.arena
	var sz := Vector2(stamp_mask.get_size())
	var top := slam_point - sz / 2.0
	arena.stamp_floor(stamp_ghost, top)
	arena.flash_image(stamp_tex, slam_point)
	arena.shake(5.0)
	Sfx.play("explode")
	for e in arena.near(slam_point, sz.length() / 2.0 + 16.0):
		if _under_ink(e.position - top, e.radius):
			arena.hit_enemy(e, st.damage * 1.5, st, (e.position - slam_point).normalized(), st.knock * 1.5)


func _under_ink(p: Vector2, r: float) -> bool:
	for o in [Vector2.ZERO, Vector2(r * 0.7, 0), Vector2(-r * 0.7, 0), Vector2(0, r * 0.7), Vector2(0, -r * 0.7)]:
		var q := Vector2i(p + o)
		if q.x >= 0 and q.y >= 0 and q.x < stamp_mask.get_width() and q.y < stamp_mask.get_height() and stamp_mask.get_pixelv(q).a > 0.5:
			return true
	return false


## Gomme sacrée : un long trait de gomme. Les ennemis touchés peuvent être EFFACÉS d'un coup.
func _erase_line(origin: Vector2) -> void:
	var arena := player.arena
	var a := origin
	var b: Vector2 = origin + atk_dir * st.reach * _range_mult() * 1.7
	var width: float = st.hit_r * 0.55
	arena.erase_stroke(a, b, width)
	for e in arena.near((a + b) / 2.0, a.distance_to(b) / 2.0 + 24.0):
		if e.dead:
			continue
		if Geometry2D.get_closest_point_to_segment(e.position, a, b).distance_to(e.position) > width + e.radius:
			continue
		if e.is_boss:
			e.hurt(e.max_hp * 0.03, false, Vector2.ZERO)
			arena.hit_enemy(e, st.damage * 1.5, st, atk_dir, 0.0)
		elif randf() < (0.15 if e.elite else 0.3):
			arena.float_text(e.position + Vector2(0, -12), "EFFACÉ", Pal.TEXT)
			e.hurt(e.hp + 1.0, true, Vector2.ZERO)
		else:
			e.hurt(e.max_hp * 0.25, false, Vector2.ZERO)
			arena.hit_enemy(e, st.damage, st, atk_dir, st.knock)


# ------------------------------------------------------------------ Distance

func _fire(target: Enemy) -> void:
	var arena := player.arena
	if st.style == "prism":
		_fire_prism()
		return
	if st.style == "clone":
		_fire_clone()
		return
	var copies := 1 + Run.amulet_count("miroir")
	var muzzle := player.position + position + Vector2.from_angle(aim) * length * 0.5
	var base := aim + deg_to_rad(randf_range(-st.spread, st.spread))
	var life_range: float = st.range * _range_mult()
	var pellets: int = st.pellets
	for c in copies:
		for k in pellets:
			var a := base + (c - (copies - 1) / 2.0) * 0.2 + (k - (pellets - 1) / 2.0) * 0.28
			for i in st.bullets.size():
				var b: Dictionary = st.bullets[i]
				var off: Vector2 = b.center.rotated(a)
				var life: float = life_range / b.speed
				if st.style == "lob":
					life = clampf(muzzle.distance_to(target.position) / b.speed, 0.15, life)
				var p := arena.spawn_bullet(muzzle + off, Vector2.from_angle(a) * b.speed, b, st, bullet_tex[i],
					art.beffect, life, art.get("boutline", true))
				if st.style == "homing":
					p.homing = true
				elif st.style == "lob":
					p.lob_r = 16.0 + b.radius * 2.5
	recoil = 4.0
	arena.burst(muzzle, Color(1, 0.95, 0.8), 3, 70.0, Vector2.from_angle(aim), 0.5)   # éclat au canon
	Sfx.play("shoot")


## Palette vivante : un orbe chercheur par couleur du dessin, avec son effet garanti.
func _fire_prism() -> void:
	var arena := player.arena
	var b: Dictionary = st.bullets[0]
	var muzzle := player.position + position + Vector2.from_angle(aim) * length * 0.5
	var n := orbs.size()
	for i in n:
		var o: Dictionary = orbs[i]
		var a := aim + (i - (n - 1) / 2.0) * 0.4
		var bb := {"damage": b.damage * o.mult, "radius": b.radius, "pierce": b.pierce}
		var p := arena.spawn_bullet(muzzle, Vector2.from_angle(a) * b.speed, bb, o.wst, o.tex, "", st.range * _range_mult() / b.speed)
		p.homing = true
	recoil = 3.0
	Sfx.play("shoot")


## Autoportrait : un clone du perso court vers l'ennemi et explose.
func _fire_clone() -> void:
	var arena := player.arena
	var b: Dictionary = st.bullets[0]
	var bb := {"damage": b.damage, "radius": maxf(6.0, player.radius), "pierce": 0}
	var p := arena.spawn_bullet(player.position + position, Vector2.from_angle(aim) * maxf(90.0, b.speed), bb, st, clone_tex,
		Run.char_effect, 4.0, Run.char_outline)
	p.homing = true
	p.upright = true
	p.burst_r = 34.0 + player.radius * 2.0
	Sfx.play("shoot")
