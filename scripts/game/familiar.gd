class_name Familiar
extends Node2D
## Un familier (dessiné par le joueur) qui vit sur la page avec son propre comportement.
## L'arène appelle tick(delta) à chaque image. Voir FamiliarDB pour la liste.

var arena: Arena
var id := ""
var def: Dictionary
var sprite: Sprite2D
var t := 0.0
var cd := 1.5           # prochaine action (s)
var cd2 := 0.0
var cd3 := 0.0
var state := "walk"
var st_t := 0.0
var goal := Vector2.ZERO
var vel := Vector2.ZERO
var ang := 0.0
var target: Enemy
var hit_cd := {}        # ennemi -> temps avant de pouvoir le retoucher
var hp := 0.0           # Pavel
var max_hp := 0.0
var ko_t := 0.0
var line_to := Vector2.ZERO   # langue de la grenouille / fléchette de Teemeo
var line_t := 0.0
var line_col := Color.WHITE
var shroom_n := 0       # Teemeo : champignons posés
var pie_count := 0      # Pie : gouttes ramassées
var life := -1.0        # oiseau de la Cage : durée de vie (s), -1 = permanent
var bird_dmg := 0.0


func setup(a: Arena, fid: String) -> void:
	arena = a
	id = fid
	def = FamiliarDB.get_def(id)
	var art: Dictionary = Run.familiar_art[id]
	sprite = Gfx.sprite(Gfx.texture(Analyzer.trim(art.image)), Gfx.material(art.effect, art.get("outline", false)))
	add_child(sprite)
	position = arena.player.position + Vector2.from_angle(randf() * TAU) * 30.0
	goal = position
	ang = randf() * TAU
	cd = randf_range(0.8, 2.0)
	if id == "pavel":
		max_hp = 60.0 + 18.0 * Run.wave
		hp = max_hp
	if id == "herisson_f":
		vel = Vector2.from_angle(randf() * TAU) * 110.0


## Oiseau de la Cage : vit 6 s, pique l'ennemi le plus proche.
func setup_bird(a: Arena, tex: Texture2D, effect: String, outline: bool, dmg: float) -> void:
	arena = a
	id = "oiseau"
	def = {}
	life = 6.0
	bird_dmg = dmg
	sprite = Gfx.sprite(tex, Gfx.material(effect, outline))
	add_child(sprite)
	position = arena.player.position + Vector2(0, -10)
	cd = 0.2


# ------------------------------------------------------------------ Outils communs

## Dégâts d'un familier : base + vague, × tes dégâts, × bonus des amulettes de familiers.
func fdmg(base: float, per_wave: float) -> float:
	var m := (1.0 + 0.2 * Run.amulet_count("niche")) * (1.0 + 0.25 * Run.amulet_count("dresseur") * Run.familiars.size())
	if arena.whip_t > 0.0:
		m *= 1.0 + 0.1 * arena.whip_stacks   # Fouet de dresseur
	return (base + per_wave * Run.wave) * (1.0 + Run.stats.dmg / 100.0) * m


## Délai entre deux actions (Croquettes : -15 % chacune).
func fcd(sec: float) -> float:
	return sec * pow(0.85, Run.amulet_count("croquettes"))


func _speed() -> float:
	return 1.2 if Run.amulet_count("laisse") > 0 else 1.0


func _leash() -> float:
	return 45.0 if Run.amulet_count("laisse") > 0 else 75.0


## Le familier touche un ennemi (Collier à grelot : soin ; Meute : élément de ton perso).
func hit(e: Enemy, dmg: float, kb := Vector2.ZERO) -> void:
	if e == null or e.dead:
		return
	e.hurt(dmg, false, kb)
	_action()
	var dom := int(Run.char_a.get("dominant", 0))
	if dom > 0 and Run.amulet_count("meute") > 0 and not e.dead:
		arena._apply_el(e, dom, dmg, false)


func _action() -> void:
	var g := Run.amulet_count("collier_grelot")
	if g > 0:
		arena.player.heal(1.0 * g)


## Se promène autour du joueur (Laisse : plus près, plus vite).
func _wander(delta: float, speed := 90.0) -> void:
	var p := arena.player.position
	if position.distance_to(goal) < 6.0 or goal.distance_to(p) > _leash() * 1.4:
		goal = p + Vector2.from_angle(randf() * TAU) * randf_range(16.0, _leash())
	position = position.move_toward(goal, speed * _speed() * delta)


func _sitflip(dir_x: float) -> void:
	if absf(dir_x) > 0.1:
		sprite.flip_h = dir_x < 0.0


## Sifflet : l'ennemi désigné, s'il est encore là.
func _called() -> Enemy:
	var w: Enemy = arena.whistle
	if w and is_instance_valid(w) and not w.dead:
		return w
	return null


func _strongest(r: float) -> Enemy:
	var best: Enemy = null
	var score := -1.0
	for e in arena.near(arena.player.position, r):
		if e.dead:
			continue
		var s: float = e.max_hp + (100000.0 if e.is_boss else (10000.0 if e.elite else 0.0))
		if s > score:
			score = s
			best = e
	return best


# ------------------------------------------------------------------ Boucle

func tick(delta: float) -> void:
	t += delta
	cd -= delta
	line_t -= delta
	for k in hit_cd.keys():
		hit_cd[k] -= delta
		if hit_cd[k] <= 0.0:
			hit_cd.erase(k)
	sprite.position.y = -absf(sin(t * 7.0)) * 1.5
	if life >= 0.0:
		life -= delta
		sprite.modulate.a = clampf(life / 0.5, 0.0, 1.0)
		if life <= 0.0:
			arena.familiars.erase(self)
			queue_free()
			return
	match id:
		"oiseau":
			_oiseau(delta)
		"mouche":
			_mouche(delta)
		"taupe":
			_taupe(delta)
		"pie":
			_wander(delta, 110.0)
		"herisson_f":
			_herisson(delta)
		"luciole":
			_luciole(delta)
		"escargot":
			_escargot(delta)
		"corbeau":
			_corbeau(delta)
		"grenouille":
			_grenouille(delta)
		"fantome":
			_fantome(delta)
		"yuki":
			_yuki(delta)
		"pavel":
			_pavel(delta)
		"teemeo":
			_teemeo(delta)
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.15))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if line_t > 0.0:
		draw_line(Vector2.ZERO, line_to - position, line_col, 2.0)
	if id == "pavel" and hp < max_hp:
		draw_rect(Rect2(-10, 12, 20, 3), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-10, 12, 20 * hp / max_hp, 3), Pal.GOOD)


# ------------------------------------------------------------------ Comportements

func _mouche(delta: float) -> void:
	ang += 3.2 * _speed() * delta
	var r := 30.0 if Run.amulet_count("laisse") > 0 else 38.0
	position = arena.player.position + Vector2.from_angle(ang) * r
	for e in arena.near(position, 8.0):
		var k: int = e.get_instance_id()
		if not hit_cd.has(k):
			hit_cd[k] = 0.5
			hit(e, fdmg(3.0, 1.0))


func _taupe(delta: float) -> void:
	match state:
		"dig":
			st_t -= delta
			sprite.modulate.a = clampf(st_t / 0.5, 0.0, 1.0)
			if st_t <= 0.0:
				if target and not target.dead:
					position = target.position
					hit(target, fdmg(8.0, 2.5), Vector2(0, -60))
					target.pin_t = maxf(target.pin_t, 1.0)
					arena.burst(position, Color("8a5a2b"), 10, 80.0)
					arena.float_text(position + Vector2(0, -16), "SURPRISE !", Color("c08040"))
				sprite.modulate.a = 1.0
				state = "walk"
			return
	_wander(delta)
	if cd <= 0.0:
		cd = fcd(4.0)
		var list := arena.near(arena.player.position, 300.0).filter(func(e): return not e.dead)
		if not list.is_empty():
			target = _called() if _called() else list.pick_random()
			state = "dig"
			st_t = 0.5


func _herisson(delta: float) -> void:
	position += vel * _speed() * delta
	if position.x < 8.0 or position.x > Arena.W - 8.0:
		vel.x = -vel.x
	if position.y < 8.0 or position.y > Arena.H - 8.0:
		vel.y = -vel.y
	position = position.clamp(Vector2(8, 8), Vector2(Arena.W - 8, Arena.H - 8))
	sprite.rotation += 8.0 * delta
	if randf() < 0.01:
		vel = vel.rotated(randf_range(-1.0, 1.0))
	for e in arena.near(position, 10.0):
		var k: int = e.get_instance_id()
		if not hit_cd.has(k):
			hit_cd[k] = 0.6
			hit(e, maxf(3.0, Run.stats.thorns * 2.0) * (1.0 + 0.1 * Run.wave), vel.normalized() * 60.0)


func _luciole(delta: float) -> void:
	var w := _called()
	if w and w != target:
		if target and is_instance_valid(target):
			target.firefly = false
		target = w
		target.firefly = true
	if target == null or not is_instance_valid(target) or target.dead:
		if target and is_instance_valid(target):
			target.firefly = false
		target = arena.nearest(arena.player.position, 400.0)
		if target:
			target.firefly = true
			_action()
	if target:
		position = position.move_toward(target.position + Vector2(sin(t * 5.0) * 6.0, -14.0 + cos(t * 4.0) * 3.0), 220.0 * _speed() * delta)
		sprite.modulate = Color(1, 1, 0.6, 0.6 + 0.4 * sin(t * 10.0))
	else:
		_wander(delta)


func _escargot(delta: float) -> void:
	_wander(delta, 30.0)
	cd2 -= delta
	if cd2 <= 0.0:
		cd2 = 0.25
		arena.add_slime(position)


func _corbeau(delta: float) -> void:
	match state:
		"dive":
			if target == null or not is_instance_valid(target) or target.dead:
				state = "back"
				return
			position = position.move_toward(target.position, 420.0 * _speed() * delta)
			_sitflip(target.position.x - position.x)
			if position.distance_to(target.position) < 8.0:
				hit(target, fdmg(20.0, 5.0), (target.position - arena.player.position).normalized() * 80.0)
				arena.burst(position, Pal.INK, 10, 90.0)
				state = "back"
			return
		"back":
			var home := arena.player.position + Vector2(0, -30)
			position = position.move_toward(home, 300.0 * delta)
			if position.distance_to(home) < 6.0:
				state = "walk"
			return
	position = arena.player.position + Vector2(sin(t * 1.5) * 18.0, -30.0 + sin(t * 3.0) * 3.0)
	if cd <= 0.0:
		target = _called() if _called() else _strongest(350.0)
		cd = fcd(3.0)
		if target:
			state = "dive"


func _grenouille(delta: float) -> void:
	# petits sauts
	cd2 -= delta
	if cd2 <= 0.0:
		cd2 = 1.2
		goal = arena.player.position + Vector2.from_angle(randf() * TAU) * randf_range(20.0, _leash())
	position = position.move_toward(goal, 140.0 * _speed() * delta)
	if position.distance_to(goal) > 2.0:
		sprite.position.y = -absf(sin(t * 12.0)) * 6.0
	if cd <= 0.0:
		cd = fcd(6.0)
		var best: Enemy = null
		var bd := 150.0
		for e in arena.near(position, 150.0):
			if not e.dead and not e.elite and not e.is_boss and position.distance_to(e.position) < bd:
				bd = position.distance_to(e.position)
				best = e
		if best:
			line_to = best.position
			line_t = 0.25
			line_col = Color("e85a8a")
			_action()
			arena.float_text(best.position + Vector2(0, -14), "GLOUP !", Color("6ac04a"))
			arena.kill_enemy(best)


func _fantome(delta: float) -> void:
	match state:
		"cross":
			position += vel * delta
			for e in arena.near(position, 14.0):
				var k: int = e.get_instance_id()
				if not hit_cd.has(k):
					hit_cd[k] = 3.0
					e.blind_t = maxf(e.blind_t, 2.0)
					hit(e, fdmg(4.0, 1.0))
			if position.x < -30.0 or position.x > Arena.W + 30.0 or position.y < -30.0 or position.y > Arena.H + 30.0:
				state = "walk"
				position = arena.player.position + Vector2(0, -20)
			return
	sprite.modulate.a = 0.6
	_wander(delta, 70.0)
	if cd <= 0.0:
		cd = fcd(5.0)
		var p := arena.player.position
		if randf() < 0.5:
			var left := randf() < 0.5
			position = Vector2(-20.0 if left else Arena.W + 20.0, p.y)
			vel = Vector2(400.0 if left else -400.0, 0.0)
		else:
			var top := randf() < 0.5
			position = Vector2(p.x, -20.0 if top else Arena.H + 20.0)
			vel = Vector2(0.0, 400.0 if top else -400.0)
		_sitflip(vel.x)
		sprite.modulate.a = 0.9
		state = "cross"


func _yuki(delta: float) -> void:
	var p := arena.player
	position = p.position + Vector2(-9.0, -16.0 + sin(t * 3.0) * 1.0)
	cd2 -= delta
	cd3 -= delta
	if cd <= 0.0:
		cd = fcd(8.0)
		p.heal(p.max_hp * 0.05)
		arena.burst(p.position, Pal.GOOD, 8, 60.0)
		_action()
	if cd2 <= 0.0 and p.paper <= 0:
		cd2 = fcd(12.0)
		p.paper += 1
		arena.float_text(p.position + Vector2(0, -26), "YUKI TE PROTÈGE", Color("9ad0ff"))
	if cd3 <= 0.0 and p.hp < p.max_hp * 0.25:
		cd3 = 10.0
		p.yuki_t = 3.0
		arena.float_text(p.position + Vector2(0, -26), "VITE !", Color("9ad0ff"))


func _pavel(delta: float) -> void:
	if ko_t > 0.0:
		ko_t -= delta
		visible = false
		if ko_t <= 0.0:
			visible = true
			hp = max_hp
			position = arena.player.position + Vector2(16, 0)
			arena.float_text(position + Vector2(0, -18), "PAVEL REVIENT !", Pal.GOOD)
		return
	# se place entre toi et l'ennemi le plus proche
	var p := arena.player.position
	var e := arena.nearest(p, 200.0)
	goal = p + ((e.position - p).normalized() * 26.0 if e else Vector2(18, 4))
	position = position.move_toward(goal, 120.0 * _speed() * delta)
	_sitflip(goal.x - position.x)
	# il encaisse les coups des ennemis collés à lui
	for o in arena.near(position, 14.0):
		if o.contact and not o.dead:
			hp -= o.dmg * 1.5 * delta
	if hp <= 0.0:
		ko_t = 10.0
		arena.burst(position, Pal.BAD, 14, 90.0)
		arena.float_text(position + Vector2(0, -18), "PAVEL K.O.", Pal.BAD)


## Pavel est-il là pour attirer les ennemis ?
func pavel_up() -> bool:
	return id == "pavel" and ko_t <= 0.0


func _teemeo(delta: float) -> void:
	_wander(delta, 80.0)
	cd2 -= delta
	if cd2 <= 0.0:
		cd2 = fcd(2.5)
		if arena.shrooms.size() < 8:
			var sp := (arena.player.position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 160.0)).clamp(Vector2(10, 10), Vector2(Arena.W - 10, Arena.H - 10))
			arena.shrooms.append({"pos": sp, "dmg": fdmg(4.0, 1.5)})
	if cd <= 0.0:
		cd = fcd(5.0)
		var e: Enemy = _called() if _called() else arena.nearest(position, 260.0)
		if e:
			e.blind_t = maxf(e.blind_t, 2.0)
			line_to = e.position
			line_t = 0.15
			line_col = Color("c8e070")
			hit(e, fdmg(5.0, 1.0))
			arena.float_text(e.position + Vector2(0, -14), "AVEUGLÉ", Color("c8e070"))


func _oiseau(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.dead:
		target = _called() if _called() else arena.nearest(position, 300.0)
		if target == null:
			_wander(delta, 120.0)
			return
	position = position.move_toward(target.position, 260.0 * _speed() * delta)
	_sitflip(target.position.x - position.x)
	if cd <= 0.0 and position.distance_to(target.position) < 10.0:
		cd = fcd(0.6)
		hit(target, fdmg(bird_dmg, 0.0), (target.position - position).normalized() * 40.0)
		arena.burst(position, Pal.INK, 5, 60.0)
		target = null
