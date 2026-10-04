class_name DrawScreen
extends Control
## Écran de dessin générique : toile, encre limitée, outils débloquables, aperçu des stats.
## Émet done({image, effect, outline}) ou done(null) si annulé.
## L'encre ne se dépense que sur les CONTOURS : l'intérieur d'une forme est gratuit.

signal done(result)

const TOOLS := [
	["brush", "Pinceau", "", KEY_B],
	["eraser", "Gomme", "", KEY_E],
	["line", "Ligne", "tool_line", KEY_L],
	["rect", "Rectangle", "tool_rect", KEY_R],
	["ellipse", "Ellipse", "tool_ellipse", KEY_O],
	["fill", "Remplir", "", KEY_F],
	["select", "Sélection", "", KEY_S],
]

var cfg: Dictionary
var img: Image
var tex: ImageTexture
var shape_base: Image
var budget := 0
var used := 0
var tool := "brush"
var brush := 1
var col_a: Color = Pal.SHADES[0][0]
var col_b: Color = Pal.SHADES[0][2]
var gradient := false
var mirror := false
var effect := ""
var outline := false
var drawing := false
var rmb := false
var stroke_len := 0.0
var last_cell := Vector2i.ZERO
var start_cell := Vector2i.ZERO
# Sélection : "" | "making" (rectangle en cours) | "floating" (zone levée) | "drag" (on la déplace)
var sel_state := ""
var sel_a := Vector2i.ZERO
var sel_b := Vector2i.ZERO
var sel_img: Image          # les pixels sélectionnés
var sel_base: Image         # le dessin SANS ces pixels
var sel_pos := Vector2i.ZERO
var drag_from := Vector2i.ZERO
var drag_pos0 := Vector2i.ZERO
var undo_stack: Array[Image] = []
var redo_stack: Array[Image] = []

var view: CanvasView
var ink_bar: Control
var stats_label: Label
var color_label: Label
var warn_label: Label
var tool_btns := {}
var toggle_btns := {}
var size_btns := {}
var fx_btns := {}
var swatches: Array = []
var overlay: Control
var preview_rect: TextureRect
var preview_tex: ImageTexture
var preview_mat: ShaderMaterial
var outline_btn: Button
var body_view: Control        # aperçu de l'objet sur le perso, à la même échelle
var view_btn: Button


func _init(c: Dictionary) -> void:
	cfg = c


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var s: Vector2i = cfg.size
	img = Image.create_empty(s.x, s.y, false, Image.FORMAT_RGBA8)
	if cfg.get("base") != null:
		_blit_centered(cfg.base)
	tex = ImageTexture.create_from_image(img)
	budget = int(cfg.ink)
	var fx: String = cfg.get("effect", "")
	if fx in Meta.effects():
		effect = fx
	outline = cfg.get("outline", false)
	_build_ui()
	_recount()
	_changed()
	var tip: String = {"character": "draw_perso", "melee": "draw_weapon", "ranged": "draw_weapon",
		"bullet": "draw_bullet", "enemy": "draw_enemy", "boss": "draw_enemy", "amulet": "draw_amulet",
		}.get(cfg.kind, "")
	if tip != "":
		Tips.show(self, tip)
	if Meta.elements().size() > 1:
		Tips.show(self, "colors")


# ------------------------------------------------------------------ Interface

func _build_ui() -> void:
	UI.fill_bg(self)
	UI.put(self, UI.label(cfg.title, 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 6), Vector2(640, 22))
	var sub := UI.label(cfg.get("sub", ""), 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.put(self, sub, Vector2(20, 30), Vector2(600, 26))

	# --- Outils (gauche)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	UI.put(self, left, Vector2(8, 62), Vector2(116, 290))
	left.add_child(UI.label("OUTILS", 10, Pal.DIM))
	# outils sur 2 colonnes (tout tient même quand tout est débloqué)
	var tgrid := GridContainer.new()
	tgrid.columns = 2
	tgrid.add_theme_constant_override("h_separation", 2)
	tgrid.add_theme_constant_override("v_separation", 2)
	left.add_child(tgrid)
	for t in TOOLS:
		if not Meta.has(t[2]):
			continue
		var id: String = t[0]
		var short: String = {"rect": "Rect.", "select": "Sélect."}.get(id, t[1])
		var b := UI.button(short, func(): _set_tool(id))
		b.clip_text = true
		b.custom_minimum_size.x = 56
		b.tooltip_text = "%s · raccourci : %s" % [t[1], OS.get_keycode_string(t[3])]
		if id == "select":
			b.tooltip_text = "Sélection (S) : trace un rectangle, glisse-le pour le déplacer,
Suppr pour l'effacer, clic à côté (ou clic droit) pour le poser"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tgrid.add_child(b)
		tool_btns[id] = b
	if Meta.has("tool_mirror"):
		toggle_btns.mirror = UI.button("Symétrie", func(): _toggle("mirror"))
		toggle_btns.mirror.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle_btns.mirror.clip_text = true
		toggle_btns.mirror.custom_minimum_size.x = 56
		tgrid.add_child(toggle_btns.mirror)
	if Meta.has("gradient"):
		toggle_btns.gradient = UI.button("Dégradé", func(): _toggle("gradient"))
		toggle_btns.gradient.tooltip_text = "Clic gauche : couleur A, clic droit : couleur B"
		toggle_btns.gradient.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle_btns.gradient.clip_text = true
		toggle_btns.gradient.custom_minimum_size.x = 56
		tgrid.add_child(toggle_btns.gradient)
	if Meta.has("tool_big"):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		for n in [1, 2, 3]:
			var sz: int = n
			var b := UI.button("%dpx" % n, func(): _set_brush(sz))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)
			size_btns[n] = b
		left.add_child(row)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 2)
	var bu := UI.button("< Défaire", _undo)
	bu.tooltip_text = "Revenir en arrière (Ctrl+Z)"
	bu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(bu)
	var br := UI.button("Refaire >", _redo)
	br.tooltip_text = "Ctrl+Y"
	br.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(br)
	left.add_child(row2)
	var bc := UI.button("Tout effacer", _clear)
	bc.tooltip_text = "Se défait avec Ctrl+Z"
	left.add_child(bc)
	var fxs := Meta.effects()
	if fxs.size() > 1:
		left.add_child(UI.label("EFFET (-15% encre)", 10, Pal.DIM))
		for f in fxs:
			var fid: String = f
			var b := UI.button(Stats.EFFECT_NAMES[f], func(): _set_effect(fid))
			left.add_child(b)
			fx_btns[f] = b

	# --- Toile (centre)
	var s: Vector2i = cfg.size
	var scale_px := maxi(2, mini(284 / s.x, 264 / s.y))
	view = CanvasView.new(self, scale_px)
	var vs := Vector2(s * scale_px)
	UI.put(self, view, Vector2(134 + (284 - vs.x) / 2.0, 62 + (264 - vs.y) / 2.0), vs)
	ink_bar = Control.new()
	ink_bar.draw.connect(_draw_ink_bar)
	UI.put(self, ink_bar, Vector2(134, 332), Vector2(284, 12))
	warn_label = UI.label("", 10, Pal.BAD, HORIZONTAL_ALIGNMENT_CENTER)
	UI.put(self, warn_label, Vector2(134, 346), Vector2(284, 12))

	# --- Couleurs + aperçu (droite)
	UI.put(self, UI.label("COULEURS", 10, Pal.DIM), Vector2(426, 62))
	var els := Meta.elements()
	for i in els.size():
		var e: int = els[i]
		for sh in 3:
			var sw := _Swatch.new(Pal.SHADES[e][sh], self)
			UI.put(self, sw, Vector2(426 + i * 18, 76 + sh * 16), Vector2(16, 14))
			swatches.append(sw)
	color_label = UI.label("", 10, Pal.TEXT)
	UI.put(self, color_label, Vector2(426, 126), Vector2(136, 12))

	# Aperçu en jeu avec ou sans contour noir
	var pv := UI.panel(Pal.PAPER, Pal.BORDER, 1)
	UI.put(self, pv, Vector2(558, 62), Vector2(74, 62))
	preview_tex = ImageTexture.create_from_image(Gfx.padded(img))
	preview_mat = Gfx.material(effect, outline)
	preview_rect = TextureRect.new()
	preview_rect.texture = preview_tex
	preview_rect.material = preview_mat
	preview_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.put(pv, preview_rect, Vector2(2, 2), Vector2(70, 58))
	outline_btn = UI.button("", _toggle_outline)
	outline_btn.tooltip_text = "Contour noir autour du dessin en jeu (touche C)"
	UI.put(self, outline_btn, Vector2(558, 126), Vector2(74, 14))
	UI.put(self, UI.label("APERÇU", 10, Pal.DIM), Vector2(426, 144))
	stats_label = UI.label("", 10, Pal.TEXT)
	stats_label.clip_text = false
	UI.put(self, stats_label, Vector2(426, 158), Vector2(206, 150))
	if Run.active and Run.character != null and cfg.kind in ["melee", "ranged", "bullet", "amulet", "mark"]:
		_build_body_preview()

	var bx := 426.0
	if cfg.get("gallery", "") != "":
		UI.put(self, UI.button("Galerie", _open_gallery), Vector2(bx, 318), Vector2(66, 16))
		bx += 70
	if cfg.get("random", false):
		UI.put(self, UI.button("Au hasard", _random_monster), Vector2(bx, 318), Vector2(66, 16))
	if cfg.kind in ["character", "melee", "ranged", "bullet"]:
		# petit cercle des couleurs : ouvre l'explication en grand
		var cb := UI.button("Couleurs", func(): UI.cercle_popup(self, UI.perso_color_line() if Run.active and cfg.kind != "character" else ""))
		cb.tooltip_text = "Cercle des faiblesses : quelle couleur bat laquelle"
		UI.put(self, cb, Vector2(566, 318), Vector2(66, 16))
	if cfg.get("cancel", false):
		UI.put(self, UI.hotkey(UI.button(cfg.get("cancel_label", "Retour"), func(): done.emit(null)), [KEY_ESCAPE]), Vector2(426, 338), Vector2(66, 16))
	UI.put(self, UI.hotkey(UI.button("VALIDER →", _validate), [KEY_ENTER, KEY_KP_ENTER]), Vector2(496, 338), Vector2(136, 16))
	_refresh_buttons()


class _Swatch extends Control:
	var color: Color
	var ds: DrawScreen

	func _init(c: Color, s: DrawScreen) -> void:
		color = c
		ds = s
		tooltip_text = "Clic gauche : couleur A · Clic droit : couleur B (dégradé)"

	func _gui_input(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			if ev.button_index == MOUSE_BUTTON_LEFT:
				ds.col_a = color
			elif ev.button_index == MOUSE_BUTTON_RIGHT:
				ds.col_b = color
			if ds.tool == "eraser":
				ds._set_tool("brush")
			Sfx.play("click")
			ds._refresh_buttons()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), color)
		if ds.col_a == color:
			draw_rect(Rect2(Vector2.ZERO, size), Pal.ACCENT, false, 2.0)
		elif ds.gradient and ds.col_b == color:
			draw_rect(Rect2(Vector2.ZERO, size), Pal.TEXT, false, 1.0)


func _draw_ink_bar() -> void:
	var w := ink_bar.size.x
	var eb := eff_budget()
	ink_bar.draw_rect(Rect2(0, 0, w, 12), Pal.INK)
	var t := clampf(float(used) / maxf(1.0, budget), 0.0, 1.0)
	var col := Pal.ACCENT if used < eb else Pal.BAD
	ink_bar.draw_rect(Rect2(1, 1, (w - 2) * t, 10), col.darkened(0.2))
	if eb < budget:
		var x := (w - 2) * float(eb) / budget
		ink_bar.draw_rect(Rect2(1 + x, 1, w - 2 - x, 10), Color(Pal.BORDER, 0.7))
	var mi := int(cfg.get("min_ink", 0))
	if mi > 0:
		var mx := 1 + (w - 2) * float(mi) / budget
		ink_bar.draw_rect(Rect2(mx, 0, 2, 12), Pal.GOOD if used >= mi else Pal.BAD)
	var txt := "ENCRE  %d / %d   (seuls les traits coûtent)" % [used, eb]
	if mi > 0:
		txt = "ENCRE  %d / %d   (minimum %d)" % [used, eb, mi]
	ink_bar.draw_string(UI.font, Vector2(0, 10), txt, HORIZONTAL_ALIGNMENT_CENTER, w, UI.fs(10), Pal.TEXT)


func _refresh_buttons() -> void:
	for id in tool_btns:
		_mark(tool_btns[id], id == tool)
	if toggle_btns.has("mirror"):
		_mark(toggle_btns.mirror, mirror)
	if toggle_btns.has("gradient"):
		_mark(toggle_btns.gradient, gradient)
	for n in size_btns:
		_mark(size_btns[n], n == brush)
	for f in fx_btns:
		_mark(fx_btns[f], f == effect)
	if outline_btn:
		outline_btn.text = "Bord : %s" % ("oui" if outline else "non")
		_mark(outline_btn, outline)
	for sw in swatches:
		sw.queue_redraw()
	var ea := Pal.element_of(col_a)
	var txt := "A : %s (%s)" % [Pal.COLOR_NAMES[ea], Pal.NAMES[ea]]
	if gradient:
		var eb := Pal.element_of(col_b)
		txt += "  B : %s" % Pal.COLOR_NAMES[eb]
	color_label.text = txt
	if view:
		view.queue_redraw()


func _mark(b: Button, on: bool) -> void:
	if on:
		b.add_theme_stylebox_override("normal", UI.sb(UI.SELECTED, Pal.ACCENT, 1))
		b.add_theme_color_override("font_color", Pal.ACCENT)
	else:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_color_override("font_color")


func _set_tool(t: String) -> void:
	if t != "select":
		_sel_commit()
	tool = t
	_refresh_buttons()


func _set_brush(n: int) -> void:
	brush = n
	_refresh_buttons()


## Montre l'objet en cours de dessin sur le perso (avec ses amulettes et armes déjà posées),
## à la même échelle qu'en jeu, pour se rendre compte de la taille.
func _build_body_preview() -> void:
	body_view = UI.panel(Pal.PAPER, Pal.BORDER, 1)
	body_view.clip_contents = true
	UI.put(self, body_view, Vector2(426, 158), Vector2(206, 154))
	view_btn = UI.button("", _toggle_body_view)
	view_btn.tooltip_text = "Touche V"
	UI.put(self, view_btn, Vector2(502, 142), Vector2(130, 14))

	var comp := Run.build_player_image()
	var cc := Run.char_center()
	var cr: Rect2i = Run.char_a.rect
	var isz := Vector2(img.get_size())
	var item_c := cc
	match cfg.kind:
		"melee", "ranged":
			item_c = cc + Vector2(cr.size.x / 2.0 + isz.x * 0.3, 2.0)
		"bullet":
			item_c = cc + Vector2(cr.size.x / 2.0 + 10.0 + isz.x / 2.0, 0.0)
	# Rectangles (en pixels du dessin) de tout ce qu'on affiche
	var parts := []   # [texture, material, rect]
	parts.append([ImageTexture.create_from_image(Gfx.padded(comp)),
		Gfx.material(Run.char_effect, Run.char_outline), Rect2(Vector2(-1, -1), Vector2(comp.get_size()) + Vector2(2, 2))])
	for w in Run.weapons:
		var wi := Run.weapon_image(w)
		var ws := Vector2(wi.get_size())
		var art: Dictionary = Run.art_of(w)
		parts.append([Gfx.texture(wi), Gfx.material(art.effect, art.get("outline", false)),
			Rect2(cc + w.anchor - ws / 2.0 - Vector2.ONE, ws + Vector2(2, 2))])
	parts.append([preview_tex, preview_mat, Rect2(item_c - isz / 2.0 - Vector2.ONE, isz + Vector2(2, 2))])
	var bounds: Rect2 = parts[0][2]
	for pt in parts:
		bounds = bounds.merge(pt[2])
	var avail := body_view.size - Vector2(8, 8)
	var sc := minf(avail.x / bounds.size.x, avail.y / bounds.size.y)
	if sc >= 1.0:
		sc = floorf(sc)
	var off := (body_view.size - bounds.size * sc) / 2.0 - bounds.position * sc
	for pt in parts:
		var tr := TextureRect.new()
		tr.texture = pt[0]
		tr.material = pt[1]
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r: Rect2 = pt[2]
		UI.put(body_view, tr, off + r.position * sc, r.size * sc)
	_set_body_view(false)   # de base : les stats (V ou le bouton pour voir sur le perso)


func _toggle_body_view() -> void:
	_set_body_view(not body_view.visible)


func _set_body_view(on: bool) -> void:
	body_view.visible = on
	stats_label.visible = not on
	view_btn.text = "Voir : les stats" if on else "Voir : sur le perso"


func _toggle_outline() -> void:
	outline = not outline
	preview_mat.set_shader_parameter("outline", outline)
	_refresh_buttons()


func _toggle(what: String) -> void:
	if what == "mirror":
		mirror = not mirror
	else:
		gradient = not gradient
	_refresh_buttons()


func _set_effect(f: String) -> void:
	var old := effect
	effect = f
	if used > eff_budget():
		effect = old
		_warn("Trop d'encre utilisée pour cet effet !")
	_refresh_buttons()
	_changed()


func _warn(t: String) -> void:
	warn_label.text = t
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_callback(func(): warn_label.text = "")


func _unhandled_input(ev: InputEvent) -> void:
	if overlay:
		return
	# Défaire / refaire (maintenir la touche répète)
	if ev is InputEventKey and ev.pressed and ev.ctrl_pressed:
		if ev.keycode == KEY_Z and not ev.shift_pressed:
			_sel_commit()
			_undo()
			return
		if ev.keycode == KEY_Y or (ev.keycode == KEY_Z and ev.shift_pressed):
			_redo()
			return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.keycode
		if (k == KEY_DELETE or k == KEY_BACKSPACE) and sel_state == "floating":
			_sel_delete()
			return
		for t in TOOLS:
			if k == t[3] and tool_btns.has(t[0]):
				_set_tool(t[0])
				return
		if k == KEY_M and toggle_btns.has("mirror"):
			_toggle("mirror")
		elif k == KEY_G and toggle_btns.has("gradient"):
			_toggle("gradient")
		elif k == KEY_C:
			_toggle_outline()
		elif k == KEY_V and body_view:
			_toggle_body_view()


# ------------------------------------------------------------------ Dessin

func eff_budget() -> int:
	if effect == "":
		return budget
	return budget - ceili(budget * Stats.EFFECT_COST)


func _in(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height()


func _cur_tool() -> String:
	return "eraser" if rmb else tool


func begin_stroke(cell: Vector2i, right: bool) -> void:
	if tool == "select":
		if right:
			_sel_commit()   # clic droit : poser la sélection
		else:
			_sel_press(cell)
		return
	_push_undo()
	drawing = true
	rmb = right
	stroke_len = 0.0
	last_cell = cell
	start_cell = cell
	match _cur_tool():
		"brush", "eraser":
			_stamp(cell)
		"fill":
			_flood(cell)
			drawing = false
		_:
			shape_base = img.duplicate()
			_shape(cell)
	_changed()


func continue_stroke(cell: Vector2i) -> void:
	if not drawing or cell == last_cell:
		return
	if tool == "select":
		_sel_move(cell)
		last_cell = cell
		return
	match _cur_tool():
		"brush", "eraser":
			var pts := _line_cells(last_cell, cell)
			for i in range(1, pts.size()):
				stroke_len += 1.0
				_stamp(pts[i])
		_:
			_shape(cell)
	last_cell = cell
	_changed()


func end_stroke() -> void:
	if not drawing:
		return
	if tool == "select":
		_sel_release()
		return
	drawing = false
	shape_base = null
	Sfx.play("paint")
	_changed()


func _paint_color() -> Color:
	if not gradient:
		return col_a
	var t := pingpong(stroke_len / 10.0, 1.0)
	return col_a.lerp(col_b, roundf(t * 4.0) / 4.0)


func _stamp(c: Vector2i) -> void:
	@warning_ignore("integer_division")
	var off := -(brush - 1) / 2
	for dy in brush:
		for dx in brush:
			var p := Vector2i(c.x + off + dx, c.y + off + dy)
			_plot(p)
			if mirror:
				_plot(Vector2i(img.get_width() - 1 - p.x, p.y))


## Coût local : nombre de pixels de contour parmi p et ses 4 voisins.
func _local_cost(p: Vector2i) -> int:
	var n := 0
	for q in [p, p + Vector2i.LEFT, p + Vector2i.RIGHT, p + Vector2i.UP, p + Vector2i.DOWN]:
		if Analyzer.is_edge(img, q):
			n += 1
	return n


func _plot(p: Vector2i) -> void:
	if not _in(p):
		return
	var cur := img.get_pixelv(p)
	if _cur_tool() == "eraser":
		if cur.a > 0.5:
			var before := _local_cost(p)
			img.set_pixelv(p, Color(0, 0, 0, 0))
			used += _local_cost(p) - before
		return
	var col := _paint_color()
	if cur.a > 0.5:
		img.set_pixelv(p, col)   # recolorier est gratuit
		return
	var before := _local_cost(p)
	img.set_pixelv(p, col)
	var delta := _local_cost(p) - before
	if used + delta > eff_budget():
		img.set_pixelv(p, Color(0, 0, 0, 0))
	else:
		used += delta


func _shape(end: Vector2i) -> void:
	if shape_base == null:
		return
	img.copy_from(shape_base)
	_recount()
	var cells: Array[Vector2i] = []
	match tool:
		"line":
			cells = _line_cells(start_cell, end)
		"rect":
			var x0 := mini(start_cell.x, end.x)
			var x1 := maxi(start_cell.x, end.x)
			var y0 := mini(start_cell.y, end.y)
			var y1 := maxi(start_cell.y, end.y)
			for x in range(x0, x1 + 1):
				cells.append(Vector2i(x, y0))
				cells.append(Vector2i(x, y1))
			for y in range(y0 + 1, y1):
				cells.append(Vector2i(x0, y))
				cells.append(Vector2i(x1, y))
		"ellipse":
			cells = _ellipse_cells(start_cell, end)
	for i in cells.size():
		stroke_len = float(i)
		_stamp(cells[i])


func _line_cells(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var p := a
	while true:
		out.append(p)
		if p == b:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			p.x += sx
		if e2 <= dx:
			err += dx
			p.y += sy
	return out


func _ellipse_cells(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var c := (Vector2(a) + Vector2(b)) / 2.0
	var rx := absf(b.x - a.x) / 2.0
	var ry := absf(b.y - a.y) / 2.0
	var n := int((rx + ry) * 4.0) + 8
	var seen := {}
	for i in n:
		var ang := TAU * i / n
		var p := Vector2i(roundi(c.x + cos(ang) * rx), roundi(c.y + sin(ang) * ry))
		if not seen.has(p):
			seen[p] = true
			out.append(p)
	return out


func _flood(start: Vector2i) -> void:
	if not _in(start):
		return
	var target := img.get_pixelv(start)
	var col := col_a
	var target_empty := target.a < 0.5
	if not target_empty and target.is_equal_approx(col):
		return
	var backup := img.duplicate()
	var queue: Array[Vector2i] = [start]
	var seen := {start: true}
	var i := 0
	while i < queue.size():
		var p := queue[i]
		i += 1
		img.set_pixelv(p, col)
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q: Vector2i = p + d
			if not _in(q) or seen.has(q):
				continue
			var qc := img.get_pixelv(q)
			var same := (qc.a < 0.5) if target_empty else (qc.a > 0.5 and qc.is_equal_approx(target))
			if same:
				seen[q] = true
				queue.append(q)
	# Remplir l'intérieur est gratuit, mais une zone ouverte crée de nouveaux contours
	var cost := Analyzer.ink_cost(img)
	if cost > eff_budget():
		img.copy_from(backup)
		_warn("Pas assez d'encre : la zone n'est pas fermée ?")
	else:
		used = cost


func _recount() -> void:
	used = Analyzer.ink_cost(img)


func _push_undo() -> void:
	undo_stack.append(img.duplicate())
	if undo_stack.size() > 100:
		undo_stack.pop_front()
	redo_stack.clear()


func _undo() -> void:
	_sel_commit()
	if undo_stack.is_empty():
		_warn("Rien à défaire")
		return
	redo_stack.append(img.duplicate())
	img.copy_from(undo_stack.pop_back())
	_recount()
	_changed()


func _redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(img.duplicate())
	img.copy_from(redo_stack.pop_back())
	_recount()
	_changed()


func _clear() -> void:
	_sel_commit()
	_push_undo()
	img.fill(Color(0, 0, 0, 0))
	used = 0
	_changed()


func _blit_centered(src: Image) -> void:
	img.fill(Color(0, 0, 0, 0))
	var ss := src.get_size()
	var ds := img.get_size()
	@warning_ignore("integer_division")
	var off := Vector2i((ds.x - ss.x) / 2, (ds.y - ss.y) / 2)
	img.blit_rect(src, Rect2i(Vector2i.ZERO, ss), off)


func _changed() -> void:
	tex.update(img)
	if preview_tex:
		preview_tex.update(Gfx.padded(img))
		preview_mat.set_shader_parameter("effect", Gfx.FX_ID.get(effect, 0))
	view.queue_redraw()
	ink_bar.queue_redraw()
	stats_label.text = Stats.preview(cfg, img, effect)


# ------------------------------------------------------------------ Sélection (rectangle)

func _sel_rect() -> Rect2i:
	if sel_state == "making":
		return Rect2i(Vector2i(mini(sel_a.x, sel_b.x), mini(sel_a.y, sel_b.y)), (sel_a - sel_b).abs() + Vector2i.ONE)
	if sel_img == null:
		return Rect2i()
	return Rect2i(sel_pos, sel_img.get_size())


func _sel_press(cell: Vector2i) -> void:
	drawing = true
	last_cell = cell
	if sel_state == "floating" and _sel_rect().has_point(cell):
		sel_state = "drag"   # on attrape la zone pour la déplacer
		drag_from = cell
		drag_pos0 = sel_pos
		return
	_sel_commit()
	sel_state = "making"
	sel_a = cell.clamp(Vector2i.ZERO, img.get_size() - Vector2i.ONE)
	sel_b = sel_a
	view.queue_redraw()


func _sel_move(cell: Vector2i) -> void:
	match sel_state:
		"making":
			sel_b = cell.clamp(Vector2i.ZERO, img.get_size() - Vector2i.ONE)
			view.queue_redraw()
		"drag":
			sel_pos = drag_pos0 + (cell - drag_from)
			_sel_compose()


## Le dessin = le fond + la zone sélectionnée à sa position (ce qui sort de la toile est coupé).
func _sel_compose() -> void:
	img.copy_from(sel_base)
	img.blit_rect_mask(sel_img, sel_img, Rect2i(Vector2i.ZERO, sel_img.get_size()), sel_pos)
	_recount()
	_changed()


func _sel_release() -> void:
	drawing = false
	match sel_state:
		"making":
			var r := _sel_rect().intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			var region := img.get_region(r) if r.has_area() else null
			if region == null or region.is_invisible():
				sel_state = ""   # rien dedans : pas de sélection
				view.queue_redraw()
				return
			_push_undo()
			sel_img = region
			sel_base = img.duplicate()
			sel_base.fill_rect(r, Color(0, 0, 0, 0))
			sel_pos = r.position
			sel_state = "floating"
			_warn("Glisse : déplacer · Suppr : effacer · clic à côté : poser")
		"drag":
			sel_state = "floating"
			if used > eff_budget():
				sel_pos = drag_pos0   # pas assez d'encre à cet endroit : on revient
				_sel_compose()
				_warn("Pas assez d'encre pour la poser là")
			else:
				Sfx.play("paint")
	view.queue_redraw()


## Pose la sélection (elle fait déjà partie du dessin) et arrête de la déplacer.
func _sel_commit() -> void:
	if sel_state == "":
		return
	sel_state = ""
	sel_img = null
	sel_base = null
	drawing = false
	if view:
		view.queue_redraw()


## Suppr : la zone sélectionnée disparaît (son encre revient).
func _sel_delete() -> void:
	img.copy_from(sel_base)
	_sel_commit()
	_recount()
	_changed()
	Sfx.play("paint")


func _validate() -> void:
	_sel_commit()
	if Analyzer.count_pixels(img) < int(cfg.get("min", 1)):
		_warn("Dessine un peu plus !")
		return
	if used > eff_budget():
		_warn("Trop d'encre !")
		return
	if used < int(cfg.get("min_ink", 0)):
		_warn("Encore %d d'encre à utiliser (95%% minimum) !" % (int(cfg.min_ink) - used))
		return
	Meta.add_to_gallery(cfg.get("gallery", cfg.kind), img, effect)
	Sfx.play("buy")
	done.emit({"image": img, "effect": effect, "outline": outline})


# ------------------------------------------------------------------ Galerie & hasard

func _open_gallery() -> void:
	var entries := Meta.gallery(cfg.gallery)
	overlay = UI.panel(Color(Pal.BG, 0.97), Pal.ACCENT)
	UI.put(self, overlay, Vector2(20, 20), Vector2(600, 320))
	UI.put(overlay, UI.label("GALERIE — réutilise un ancien dessin", 10, Pal.ACCENT), Vector2(10, 8))
	UI.put(overlay, UI.hotkey(UI.button("Fermer", _close_gallery), [KEY_ESCAPE]), Vector2(530, 6), Vector2(60, 16))
	var sc := ScrollContainer.new()
	UI.put(overlay, sc, Vector2(10, 30), Vector2(580, 280))
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	var s: Vector2i = cfg.size
	var shown := 0
	for e in entries:
		var ok: bool = int(e.w) <= s.x and int(e.h) <= s.y
		var gi := Meta.gallery_image(e)
		if gi == null:
			continue
		var cost := Analyzer.ink_cost(gi)
		var fits: bool = cost <= (budget if e.get("effect", "") == "" else budget - ceili(budget * Stats.EFFECT_COST))
		var b := Button.new()
		b.custom_minimum_size = Vector2(52, 52)
		b.focus_mode = Control.FOCUS_NONE
		var th := UI.thumb(gi, Vector2(44, 44))
		th.position = Vector2(4, 4)
		b.add_child(th)
		if not ok or not fits:
			b.disabled = true
			b.tooltip_text = "Trop grand ou trop d'encre (%d)" % cost
			th.modulate = Color(1, 1, 1, 0.3)
		else:
			b.tooltip_text = "Encre : %d" % cost
			var entry: Dictionary = e
			b.pressed.connect(func(): _load_gallery(entry, gi))
		grid.add_child(b)
		shown += 1
	if shown == 0:
		UI.put(overlay, UI.label("Rien pour l'instant : tes dessins validés arriveront ici.", 10, Pal.DIM), Vector2(10, 40))


func _load_gallery(entry: Dictionary, gi: Image) -> void:
	_push_undo()
	_blit_centered(gi)
	var fx: String = entry.get("effect", "")
	effect = fx if fx in Meta.effects() else ""
	outline = entry.get("outline", false)
	preview_mat.set_shader_parameter("outline", outline)
	_recount()
	_close_gallery()
	_refresh_buttons()
	_changed()


func _close_gallery() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null


## Génère un petit monstre symétrique au hasard (pour aller vite sur les ennemis).
func _random_monster() -> void:
	_push_undo()
	var k := 1.0
	for attempt in 6:
		_generate_monster(k)
		_recount()
		if used <= eff_budget():
			break
		k *= 0.8
	_scribble_to(int(cfg.get("min_ink", 0)))
	_changed()


## Ajoute des gribouillis symétriques jusqu'à atteindre `target` d'encre (boss).
func _scribble_to(target: int) -> void:
	if used >= target:
		return
	var saved := [tool, mirror, gradient, rmb, col_a]
	tool = "brush"
	mirror = true
	gradient = false
	rmb = false
	var w := img.get_width()
	var h := img.get_height()
	var els := Meta.elements()
	for walk in 600:
		if used >= target:
			break
		col_a = Pal.SHADES[els.pick_random()][randi() % 2]
		var p := Vector2i(randi_range(1, w / 2), randi_range(1, h - 2))
		var dir := Vector2i([-1, 0, 1].pick_random(), [-1, 0, 1].pick_random())
		for step in randi_range(4, 14):
			if used >= target:
				break
			_stamp(p)
			if randf() < 0.3:
				dir = Vector2i([-1, 0, 1].pick_random(), [-1, 0, 1].pick_random())
			p = (p + dir).clamp(Vector2i.ZERO, Vector2i(w - 1, h - 1))
	tool = saved[0]
	mirror = saved[1]
	gradient = saved[2]
	rmb = saved[3]
	col_a = saved[4]


func _generate_monster(k: float) -> void:
	img.fill(Color(0, 0, 0, 0))
	var w := img.get_width()
	var h := img.get_height()
	var els := Meta.elements()
	var e: int = els.pick_random()
	var dark: Color = Pal.SHADES[e][0]
	var mid: Color = Pal.SHADES[e][1]
	var cx := w / 2.0
	var cy := h / 2.0 + randf_range(-1, 2)
	var rx := w * randf_range(0.22, 0.4) * k
	var ry := h * randf_range(0.2, 0.36) * k
	for y in h:
		for x in int(ceil(cx)):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0 + randf_range(-0.25, 0.25):
				img.set_pixel(x, y, mid)
				img.set_pixel(w - 1 - x, y, mid)
	# Pattes / cornes
	for i in randi_range(1, 3):
		var x := randi_range(1, maxi(1, int(cx) - 1))
		var y0 := int(cy + ry * (1 if randf() < 0.6 else -1))
		var dir := 1 if y0 > cy else -1
		for j in randi_range(2, int(h * 0.2 * k) + 2):
			for q in [Vector2i(x, y0 + j * dir), Vector2i(w - 1 - x, y0 + j * dir)]:
				if _in(q):
					img.set_pixelv(q, dark)
	# Contour sombre
	var copy := img.duplicate()
	for y in h:
		for x in w:
			if Analyzer.is_edge(copy, Vector2i(x, y)):
				img.set_pixel(x, y, dark)
	# Yeux (des trous dans l'encre)
	var ey := int(cy - ry * 0.25)
	var ex := int(cx - rx * randf_range(0.3, 0.55))
	for q in [Vector2i(ex, ey), Vector2i(w - 1 - ex, ey)]:
		if _in(q) and img.get_pixelv(q).a > 0.5:
			img.set_pixelv(q, Color(0, 0, 0, 0))
