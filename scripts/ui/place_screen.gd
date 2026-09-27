class_name PlaceScreen
extends Control
## Pose une amulette ou une arme où tu veux sur ton perso.
## On peut tourner (R) et retourner en miroir (M) l'objet. Pour une amulette, la zone donne un bonus.
## Pour une arme, sa pointe (le côté droit du dessin après rotation) vise les ennemis.
## done({"pos": Vector2i, "image": Image, "rot": int, "flip": bool}) pour une amulette,
## done({"anchor": Vector2, "rot": int, "flip": bool}) pour une arme (position relative au centre du perso).

signal done(result)

var mode := "amulet"
var item: Image
var def: Dictionary
var base: Image
var px := 5
var view: Control
var cell := Vector2i(-100, -100)   # coin haut-gauche de l'objet dans l'image composite
var placed := false
var zone_label: Label
var ok_btn: Button
var base_tex: ImageTexture
var item_tex: ImageTexture
var weapon_ghosts: Array = []       # [texture, centre composite, taille]
var rot := 0                        # quarts de tour (appliqués après le miroir)
var margin := 0                     # zone en plus autour du perso (armes : bien plus large)
var outline := true                 # l'objet posé a-t-il un contour noir ?
const WEAPON_MARGIN := 34
var flip := false


func _init(m: String, img: Image, d: Dictionary, with_outline := true) -> void:
	mode = m
	item = Analyzer.trim(img)
	def = d
	outline = with_outline


## Texture d'affichage : avec le contour noir s'il est coché (image agrandie d'1px de chaque côté).
func _disp_tex(img: Image, with_outline: bool) -> ImageTexture:
	return ImageTexture.create_from_image(Gfx.baked_outline(img) if with_outline else img)


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	UI.fill_bg(self)
	base = Run.build_player_image()
	if mode == "weapon":
		margin = WEAPON_MARGIN
		var big := Image.create_empty(base.get_width() + margin * 2, base.get_height() + margin * 2, false, Image.FORMAT_RGBA8)
		big.blit_rect(base, Rect2i(Vector2i.ZERO, base.get_size()), Vector2i(margin, margin))
		base = big
	base_tex = _disp_tex(base, Run.char_outline)
	item_tex = _disp_tex(item, outline)
	var cc := Run.char_center() + Vector2(margin, margin)
	for w in Run.weapons:
		var wi := Run.weapon_image(w)
		var wo: bool = Run.art_of(w).get("outline", true)
		weapon_ghosts.append([_disp_tex(wi, wo), cc + w.anchor, Vector2(wi.get_size()), wo])

	var what: String = {"amulet": "ton amulette : %s", "weapon": "ton arme : %s", "mark": "ta marque : %s"}[mode] % def.name
	UI.put(self, UI.label("Pose " + what, 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 6), Vector2(640, 24))
	var hint := "Clique pour poser (clic droit pour reprendre).  R : tourner · M : miroir"
	UI.put(self, UI.label(hint, 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 32), Vector2(640, 14))

	var s := base.get_size()
	px = maxi(2, mini(290 / s.x, 280 / s.y))
	view = Control.new()
	view.mouse_default_cursor_shape = Control.CURSOR_CROSS
	view.clip_contents = true   # les armes posées loin ne débordent pas du cadre
	view.draw.connect(_draw_view)
	view.gui_input.connect(_view_input)
	var vs := Vector2(s * px)
	UI.put(self, view, Vector2(40 + (300 - vs.x) / 2.0, 56 + (280 - vs.y) / 2.0), vs)

	var y := 60.0
	if mode == "amulet":
		var info := ""
		for z in AmuletDB.ZONES:
			info += "%s : %s\n" % [z, AmuletDB.ZONES[z].desc]
		UI.put(self, UI.label("ZONES", 10, Pal.DIM), Vector2(370, y))
		UI.put(self, UI.label(info, 10, Pal.TEXT), Vector2(370, y + 16), Vector2(260, 70))
		UI.put(self, UI.label("EFFET", 10, Pal.DIM), Vector2(370, y + 94))
		var am_a: Dictionary = Run.amulet_art[def.id].a
		var eff := UI.label(AmuletDB.describe(def, Stats.amulet_mag(am_a, def)), 10, Pal.TEXT)
		eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.put(self, eff, Vector2(370, y + 108), Vector2(260, 40))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		UI.put(self, row, Vector2(370, y + 156), Vector2(260, 18))
		row.add_child(UI.button("Tourner (R)", _rotate))
		row.add_child(UI.button("Miroir (M)", _mirror))
		zone_label = UI.label("Zone : -", 20, Pal.ACCENT)
		UI.put(self, zone_label, Vector2(370, y + 190), Vector2(260, 24))
	elif mode == "mark":
		var info := UI.label(def.desc + "\n\nPose ta marque où tu veux : elle décore ton perso sans le rendre plus gros ni plus lent.", 10, Pal.TEXT)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.put(self, info, Vector2(370, y), Vector2(260, 80))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		UI.put(self, row, Vector2(370, y + 90), Vector2(260, 18))
		row.add_child(UI.button("Tourner (R)", _rotate))
		row.add_child(UI.button("Miroir (M)", _mirror))
	else:
		var info := UI.label(def.desc + "\n\nPlace-la sur une main, sur la tête, dans le dos... Elle attaque l'ennemi le plus proche depuis là où tu l'as posée.\n\nTourne-la pour choisir sa position au repos : c'est le côté droit du dessin qui vise.", 10, Pal.TEXT)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.put(self, info, Vector2(370, y), Vector2(260, 130))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		UI.put(self, row, Vector2(370, y + 140), Vector2(260, 18))
		row.add_child(UI.button("Tourner (R)", _rotate))
		row.add_child(UI.button("Miroir (M)", _mirror))
	if mode == "amulet":
		Tips.show(self, "amulet_zones")
	ok_btn = UI.hotkey(UI.button("VALIDER →", _validate), [KEY_ENTER, KEY_KP_ENTER])
	ok_btn.disabled = true
	UI.put(self, ok_btn, Vector2(496, 330), Vector2(136, 18))


func _validate() -> void:
	if not placed:
		return
	Sfx.play("buy")
	if mode != "weapon":
		done.emit({"pos": cell, "image": item, "rot": rot, "flip": flip})
	else:
		var center := Vector2(cell) + Vector2(item.get_size()) / 2.0
		done.emit({"anchor": center - Run.char_center() - Vector2(margin, margin), "rot": rot, "flip": flip})


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_R:
			_rotate()
		elif ev.keycode == KEY_M:
			_mirror()


func _rotate() -> void:
	var center := Vector2(cell) + Vector2(item.get_size()) / 2.0
	item.rotate_90(CLOCKWISE)
	rot = (rot + 1) % 4
	_after_transform(center)


func _mirror() -> void:
	var center := Vector2(cell) + Vector2(item.get_size()) / 2.0
	item.flip_x()
	# miroir après rotation = rotation inverse après miroir
	flip = not flip
	rot = (4 - rot) % 4
	_after_transform(center)


func _after_transform(center: Vector2) -> void:
	item_tex = _disp_tex(item, outline)
	if cell.x > -50:
		cell = _clamp(Vector2i((center - Vector2(item.get_size()) / 2.0).round()))
	Sfx.play("click")
	_update()


func _cell_at(p: Vector2) -> Vector2i:
	var c := Vector2i(floori(p.x / px), floori(p.y / px))
	@warning_ignore("integer_division")
	return c - Vector2i(item.get_width() / 2, item.get_height() / 2)


func _clamp(p: Vector2i) -> Vector2i:
	var s := base.get_size()
	return Vector2i(clampi(p.x, 0, maxi(0, s.x - item.get_width())), clampi(p.y, 0, maxi(0, s.y - item.get_height())))


func _view_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and not placed:
		cell = _clamp(_cell_at(ev.position))
		_update()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		cell = _clamp(_cell_at(ev.position))
		placed = true
		ok_btn.disabled = false
		Sfx.play("paint")
		_update()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
		placed = false
		ok_btn.disabled = true
		_update()


func _update() -> void:
	if zone_label:
		zone_label.text = "Zone : %s" % Run.zone_at(cell, item.get_size())
	view.queue_redraw()


func _draw_view() -> void:
	var sz := view.size
	view.draw_rect(Rect2(Vector2(-2, -2), sz + Vector2(4, 4)), Pal.ACCENT)
	view.draw_rect(Rect2(Vector2.ZERO, sz), Pal.PAPER)
	if mode == "amulet":
		var r: Rect2i = Run.char_a.rect
		var rr := Rect2(Vector2(r.position + Vector2i(Run.PAD, Run.PAD)) * px, Vector2(r.size) * px)
		view.draw_rect(rr, Color(Pal.BORDER, 0.12))
		view.draw_rect(rr, Color(Pal.BORDER, 0.5), false, 1.0)
		for t in [0.33, 0.7]:
			var yy: float = rr.position.y + rr.size.y * t
			view.draw_line(Vector2(rr.position.x, yy), Vector2(rr.end.x, yy), Color(Pal.BORDER, 0.4))
	var bo := 1.0 if Run.char_outline else 0.0
	view.draw_texture_rect(base_tex, Rect2(Vector2(-bo, -bo) * px, sz + Vector2(bo, bo) * 2.0 * px), false)
	for g in weapon_ghosts:
		var go := 1.0 if g[3] else 0.0
		var gs: Vector2 = (g[2] + Vector2(go, go) * 2.0) * px
		view.draw_texture_rect(g[0], Rect2(g[1] * px - gs / 2.0, gs), false, Color(1, 1, 1, 0.85))
	if cell.x > -50:
		var a := 1.0 if placed else 0.75
		var io := 1.0 if outline else 0.0
		var rect := Rect2(Vector2(cell) * px, Vector2(item.get_size()) * px)
		view.draw_texture_rect(item_tex, rect.grow(io * px), false, Color(1, 1, 1, a))
		view.draw_rect(rect.grow(io * px + 1.0), Color(Pal.ACCENT, a), false, 1.0)
