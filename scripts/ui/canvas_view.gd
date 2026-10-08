class_name CanvasView
extends Control
## La toile agrandie sur laquelle on dessine. Transmet la souris au DrawScreen.

var screen: DrawScreen
var px := 8
var hover := Vector2i(-1, -1)
var edges := PackedVector2Array()
var edge_light := PackedByteArray()   # 1 = pixel clair (blanc, jaune pâle...) : point foncé   # pixels de contour (ceux qui coûtent de l'encre)
var pulse_t := 0.0


func _init(s: DrawScreen, scale_px: int) -> void:
	screen = s
	px = scale_px
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	mouse_exited.connect(func():
		hover = Vector2i(-1, -1)
		queue_redraw())


## Recalcule les pixels de contour (appelé à chaque modification du dessin).
func refresh_edges() -> void:
	edges.clear()
	edge_light.clear()
	var img := screen.img
	for y in img.get_height():
		for x in img.get_width():
			if Analyzer.is_edge(img, Vector2i(x, y)):
				edges.append(Vector2(x, y))
				edge_light.append(1 if img.get_pixel(x, y).get_luminance() > 0.6 else 0)
	queue_redraw()


func _process(delta: float) -> void:
	# les points des contours pulsent doucement (on redessine ~20 fois par seconde)
	pulse_t += delta
	if not edges.is_empty() and int(pulse_t * 20.0) != int((pulse_t - delta) * 20.0):
		queue_redraw()


func cell_at(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / px), floori(p.y / px))


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				screen.begin_stroke(cell_at(mb.position), mb.button_index == MOUSE_BUTTON_RIGHT)
			else:
				screen.end_stroke()
			accept_event()
	elif ev is InputEventMouseMotion:
		var c := cell_at((ev as InputEventMouseMotion).position)
		if c != hover:
			hover = c
			if screen.drawing:
				screen.continue_stroke(c)
			queue_redraw()


func _draw() -> void:
	var s := screen.img.get_size()
	draw_rect(Rect2(Vector2(-3, -3), size + Vector2(6, 6)), Pal.ACCENT)
	draw_rect(Rect2(Vector2(-1, -1), size + Vector2(2, 2)), Pal.INK)
	# Papier en damier très léger
	for y in s.y:
		for x in s.x:
			var c := Pal.PAPER if (x + y) % 2 == 0 else Pal.PAPER.darkened(0.04)
			draw_rect(Rect2(x * px, y * px, px, px), c)
	if screen.cfg.get("kind", "") in ["melee", "ranged"]:
		_weapon_guide()
	draw_texture_rect(screen.tex, Rect2(Vector2.ZERO, size), false)
	_draw_edges()
	if screen.mirror:
		var mx := s.x * px / 2.0
		draw_line(Vector2(mx, 0), Vector2(mx, size.y), Color(Pal.BAD, 0.6), 1.0)
	if screen.mirror_h:
		var my := s.y * px / 2.0
		draw_line(Vector2(0, my), Vector2(size.x, my), Color(Pal.BAD, 0.6), 1.0)
	# Sélection : rectangle en pointillés
	if screen.sel_state != "":
		var r := screen._sel_rect()
		var rr := Rect2(Vector2(r.position * px), Vector2(r.size * px))
		_dashed(rr)
		return
	if screen.tool == "select":
		return
	if hover.x >= 0 and hover.y >= 0 and hover.x < s.x and hover.y < s.y:
		var b := screen.brush
		@warning_ignore("integer_division")
		var off := -(b - 1) / 2
		var r := Rect2((hover.x + off) * px, (hover.y + off) * px, b * px, b * px)
		draw_rect(r, Color(Pal.INK, 0.8), false, 1.0)
		draw_rect(r.grow(-1), Color(1, 1, 1, 0.6), false, 1.0)


## Contours qui coûtent de l'encre : un petit point clair qui pulse au centre de chaque pixel.
func _draw_edges() -> void:
	var a := 0.45 + 0.35 * sin(pulse_t * 4.0)
	var d := maxf(1.0 if px < 4 else 2.0, roundf(px * 0.34))
	var o := (px - d) / 2.0
	for i in edges.size():
		var e := edges[i]
		var r := Rect2(e.x * px + o, e.y * px + o, d, d)
		# point blanc sur les couleurs foncées, point d'encre sur les couleurs claires
		var light := edge_light[i] == 1
		if px >= 6:
			draw_rect(r.grow(1.0), Color(Color.WHITE if light else Pal.INK, a * 0.6))
		draw_rect(r, Color(Pal.INK if light else Color.WHITE, a + (0.2 if light else 0.0)))


func _dashed(r: Rect2) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b) / 4.0)
		for k in n:
			var p0: Vector2 = a.lerp(b, float(k) / n)
			var p1: Vector2 = a.lerp(b, float(k + 1) / n)
			draw_line(p0, p1, Pal.INK if k % 2 == 0 else Color.WHITE, 2.0)


## Repère des armes (sous le dessin) : le manche à gauche, la pointe / le canon à droite.
## C'est le côté droit qui vise l'ennemi et d'où partent les tirs.
func _weapon_guide() -> void:
	var y := size.y / 2.0
	var col := Color(Pal.INK, 0.13)
	var x0 := size.x * 0.12
	var x1 := size.x * 0.88
	draw_line(Vector2(x0, y), Vector2(x1, y), col, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x1 + 10, y), Vector2(x1 - 8, y - 10), Vector2(x1 - 8, y + 10)]), col)
	var tip := "CANON" if screen.cfg.kind == "ranged" else "POINTE"
	draw_string(UI.font, Vector2(6, y - 8), "CROSSE" if screen.cfg.kind == "ranged" else "MANCHE", HORIZONTAL_ALIGNMENT_LEFT, -1, UI.fs(10), Color(Pal.INK, 0.3))
	draw_string(UI.font, Vector2(0, y - 8), tip + " →", HORIZONTAL_ALIGNMENT_RIGHT, size.x - 6, UI.fs(10), Color(Pal.INK, 0.3))
