class_name Pickup
extends Node2D
## Goutte d'encre lâchée par les ennemis : donne de l'or et de l'expérience.

var value := 1       # or
var xp := 1          # expérience
var color := Pal.INK
var vel := Vector2.ZERO
var t := 0.0
var magnet := false
var heal := 0.0      # Bulle de soin : goutte qui soigne
var vac := -1.0      # fin de vague : aspirée vers le joueur (< 0 = non ; sinon temps écoulé)
var vac_delay := 0.0


func _draw() -> void:
	var r := 2.0 + minf(3.0, xp * 0.5)
	var bob := sin(t * 5.0) * 1.0
	if vac > vac_delay and vel.length() > 60.0:
		# traînée pendant l'aspiration
		draw_line(Vector2.ZERO, -vel * 0.035, Color(color, 0.45), r * 1.4)
	draw_circle(Vector2(0, bob), r + 1.0, Pal.INK)
	draw_circle(Vector2(0, bob), r, color)
	draw_rect(Rect2(-1, bob - r + 1, 1, 1), Color(1, 1, 1, 0.8))


## Fin de vague : petit bond sur place, puis la goutte file vers le joueur en accélérant.
func vacuum(delta: float, arena: Arena) -> bool:
	t += delta
	vac += delta
	var p := arena.player
	var to_p := p.position - position
	if vac < vac_delay:
		position += Vector2(0, -30.0 * delta)   # elle décolle un peu
		queue_redraw()
		return true
	var k := vac - vac_delay
	vel = to_p.normalized() * (180.0 + 1400.0 * k * k)
	position += vel * delta
	if to_p.length() < p.radius + 6.0 or vel.length() * delta > to_p.length():
		arena.collect(self)
		return false
	queue_redraw()
	return true


## Retourne false quand ramassée.
func tick(delta: float, arena: Arena) -> bool:
	t += delta
	var p := arena.player
	var to_p := p.position - position
	var d := to_p.length()
	# Le butin jaillit de l'ennemi, puis file tout de suite vers toi (où que tu sois)
	if magnet or d < p.st.pickup or t > 0.25:
		magnet = true
		vel = vel.lerp(to_p.normalized() * (300.0 + 500.0 * t), 0.18)
	else:
		vel = vel.move_toward(Vector2.ZERO, 300.0 * delta)
	if d < p.radius + 6.0 or (magnet and vel.length() * delta >= d):   # (rapide : ne pas le dépasser)
		arena.collect(self)
		return false
	position += vel * delta
	queue_redraw()
	return true
