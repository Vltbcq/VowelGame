class_name Projectile
extends Node2D
## Projectile du joueur (dessiné) ou d'un ennemi (dessiné aussi !).

var vel := Vector2.ZERO
var radius := 3.0
var dmg := 1.0
var pierce := 0
var life := 1.0
var hostile := false
var element := 0
var wst: Dictionary = {}
var knock := 20.0
var hit_ids := {}
var spin := 0.0
var homing := false      # tourne vers l'ennemi le plus proche
var lob_r := 0.0         # obus : ne touche rien en vol, explose en zone à l'arrivée
var burst_r := 0.0       # Autoportrait : explose au premier contact (ou en fin de course)
var upright := false     # reste droit (le clone ne tourne pas sur lui-même)
var hang := 0.0          # Craie : reste suspendu au tableau, puis part vers le joueur
var hang_speed := 140.0


func setup(tex: Texture2D, effect: String, outline := true) -> void:
	var s := Gfx.sprite(tex, Gfx.material(effect, outline))
	add_child(s)
	rotation = vel.angle()


## Retourne false quand le projectile doit disparaître.
func tick(delta: float, arena: Arena) -> bool:
	if hang > 0.0:
		hang -= delta
		rotation += 6.0 * delta
		if hang <= 0.0:
			vel = (arena.player.position - position).normalized() * hang_speed
		elif hostile and position.distance_to(arena.player.position) < radius + arena.player.radius:
			arena.player.take_hit(dmg, element, null)
			return false
		if hang > 0.0:
			return true
	if homing:
		var tg := arena.nearest(position, 220.0)
		if tg:
			var want := (tg.position - position).angle()
			var ang := rotate_toward(vel.angle(), want, 5.0 * delta)
			vel = Vector2.from_angle(ang) * vel.length()
			rotation = 0.0 if upright else ang
	position += vel * delta
	life -= delta
	if spin != 0.0:
		rotation += spin * delta
	if lob_r > 0.0:
		rotation += 8.0 * delta
		if life <= 0.0:
			arena.explosion(position, lob_r, Color(Pal.main_color(Pal.FEU), 0.7))
			for e in arena.near(position, lob_r):
				arena.hit_enemy(e, dmg, wst, (e.position - position).normalized(), knock * 2.0)
			return false
		return true
	if burst_r > 0.0:
		rotation = 0.0
		if life <= 0.0 or not arena.near(position, radius).is_empty():
			arena.explosion(position, burst_r, Color(Pal.ACCENT, 0.85))
			for e in arena.near(position, burst_r):
				arena.hit_enemy(e, dmg, wst, (e.position - position).normalized(), knock * 3.0)
			return false
	if life <= 0.0 or position.x < -30 or position.y < -30 or position.x > Arena.W + 30 or position.y > Arena.H + 30:
		return false
	if hostile:
		var p := arena.player
		if position.distance_to(p.position) < radius + p.radius:
			p.take_hit(dmg, element, null)
			return false
		return true
	for e in arena.near(position, radius):
		var id: int = e.get_instance_id()
		if hit_ids.has(id):
			continue
		hit_ids[id] = true
		arena.hit_enemy(e, dmg, wst, vel.normalized(), knock)
		pierce -= 1
		if pierce < 0:
			return false
	return true
