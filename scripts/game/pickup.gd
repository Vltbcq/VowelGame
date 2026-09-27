class_name Pickup
extends Node2D
## Goutte d'encre lâchée par les ennemis : donne de l'or et de l'expérience.

var value := 1       # or
var xp := 1          # expérience
var color := Pal.INK
var vel := Vector2.ZERO
var t := 0.0
var magnet := false


func _draw() -> void:
	var r := 2.0 + minf(3.0, xp * 0.5)
	var bob := sin(t * 5.0) * 1.0
	draw_circle(Vector2(0, bob), r + 1.0, Pal.INK)
	draw_circle(Vector2(0, bob), r, color)
	draw_rect(Rect2(-1, bob - r + 1, 1, 1), Color(1, 1, 1, 0.8))


## Retourne false quand ramassée.
func tick(delta: float, arena: Arena) -> bool:
	t += delta
	var p := arena.player
	var to_p := p.position - position
	var d := to_p.length()
	if magnet or d < p.st.pickup:
		magnet = true
		vel = vel.lerp(to_p.normalized() * 320.0, 0.15)
	else:
		vel = vel.move_toward(Vector2.ZERO, 300.0 * delta)
	position += vel * delta
	if d < p.radius + 6.0:
		arena.collect(self)
		return false
	queue_redraw()
	return true
