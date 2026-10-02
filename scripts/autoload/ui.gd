extends Node
## Thème pixel art global + petites fonctions pour construire l'interface en code.

## DA « galerie d'art » (la même que la boutique) : mur bordeaux rayé, boiseries, laiton, cartels.
const WALL := Color("5a2330")
const WALL_STRIPE := Color("50202b")
const GOLD := Color("d6ab4f")
const GOLD_DARK := Color("8c6414")
const WOOD := Color("3a2418")
const WOOD_PANEL := Color("4a2e1f")
const FLOOR := Color("6b4a2a")
const CARTEL := Color("efe6cf")
const SELECTED := Color("7a5214")   # onglet / choix sélectionné

var font: FontFile
var font_menu: FontFile   # Yoster Island (codeman38, libre dans un jeu) : menu de l'écran titre
var theme: Theme

## Yoster Island : ses pixels font 85/1024 de la taille, donc 12 ≈ 1 pixel de jeu (net), 24 = 2.
const MENU_FONT_PATH := "res://assets/fonts/YosterIsland.ttf"
const MENU_SIZE := 12
const MENU_BIG := 24
const MENU_TITLE := 36   # 3 pixels de jeu par pixel de police
const MENU_MARGIN := 2   # marge verticale dans les boutons du menu


func _ready() -> void:
	font = PixelFont.build()
	font_menu = (load(MENU_FONT_PATH) as FontFile).duplicate()
	font_menu.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font_menu.hinting = TextServer.HINTING_NONE
	font_menu.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font_menu.generate_mipmaps = false
	font_menu.allow_system_fallback = false
	font_menu.fallbacks = [font]   # au cas où un caractère manquerait (voir docs/yoster_glyphs.py)
	theme = _build_theme()
	# Appliqué au thème par défaut : l'héritage de thème est coupé par les Node/CanvasLayer.
	var dt := ThemeDB.get_default_theme()
	dt.merge_with(theme)
	dt.default_font = font
	dt.default_font_size = PixelFont.SIZE
	ThemeDB.fallback_font = font
	ThemeDB.fallback_font_size = PixelFont.SIZE
	get_tree().root.theme = theme


func sb(bg: Color, border: Color = Color.TRANSPARENT, bw := 0, mx := 6, my := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	s.anti_aliasing = false
	return s


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = PixelFont.SIZE

	t.set_stylebox("normal", "Button", _shadowed(sb(WOOD, GOLD_DARK, 1)))
	t.set_stylebox("hover", "Button", _shadowed(sb(WOOD_PANEL, GOLD, 1)))
	t.set_stylebox("pressed", "Button", sb(GOLD, GOLD, 1))
	t.set_stylebox("hover_pressed", "Button", sb(GOLD, GOLD, 1))
	t.set_stylebox("disabled", "Button", sb(Color("2a1a12"), Color("4a3524"), 1))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", GOLD)
	t.set_color("font_hover_color", "Button", Pal.ACCENT)
	t.set_color("font_pressed_color", "Button", Pal.INK)
	t.set_color("font_hover_pressed_color", "Button", Pal.INK)
	t.set_color("font_focus_color", "Button", Pal.TEXT)
	t.set_color("font_disabled_color", "Button", Pal.DISABLED)

	t.set_color("font_color", "Label", Pal.TEXT)
	t.set_constant("line_spacing", "Label", 1)

	t.set_stylebox("panel", "Panel", _shadowed(sb(Pal.PANEL, Pal.BORDER, 2)))
	t.set_stylebox("panel", "PanelContainer", _shadowed(sb(Pal.PANEL, Pal.BORDER, 2, 6, 6)))

	t.set_stylebox("background", "ProgressBar", sb(Pal.INK, Pal.BORDER, 1, 0, 0))
	t.set_stylebox("fill", "ProgressBar", sb(Pal.ACCENT, Color.TRANSPARENT, 0, 0, 0))

	t.set_stylebox("panel", "TooltipPanel", sb(WOOD, GOLD, 1, 4, 3))
	t.set_color("font_color", "TooltipLabel", Pal.TEXT)

	t.set_stylebox("slider", "HSlider", sb(WOOD, GOLD_DARK, 1, 0, 3))
	t.set_stylebox("grabber_area", "HSlider", sb(GOLD_DARK, GOLD_DARK, 1, 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", sb(GOLD, GOLD, 1, 0, 3))
	for bar in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, sb(Color(0, 0, 0, 0.3), Color.TRANSPARENT, 0, 2, 2))
		t.set_stylebox("grabber", bar, sb(GOLD_DARK))
		t.set_stylebox("grabber_highlight", bar, sb(Pal.ACCENT))
		t.set_stylebox("grabber_pressed", bar, sb(Pal.ACCENT))
	return t


## Petite ombre portée, comme les cadres accrochés au mur.
func _shadowed(s: StyleBoxFlat) -> StyleBoxFlat:
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 1
	s.shadow_offset = Vector2(1, 2)
	return s


# ------------------------------------------------------------------ Notification (succès...)

var _toasts: CanvasLayer


## Petit bandeau en haut de l'écran, par-dessus tout, qui disparaît tout seul.
func toast(text: String) -> void:
	if _toasts == null:
		_toasts = CanvasLayer.new()
		_toasts.layer = 50
		_toasts.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_toasts)
	var p := panel(WOOD, GOLD, 2)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := _toasts.get_child_count()
	p.position = Vector2(170, 6 + n * 40)
	p.size = Vector2(300, 34)
	var l := label(text, 10, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, 4)
	l.size = Vector2(300, 28)
	p.add_child(l)
	_toasts.add_child(p)
	var tw := p.create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


# ------------------------------------------------------------------ Helpers

func label(text: String, size := 10, color := Pal.TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func button(text: String, cb: Callable, size := 10) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(func():
		Sfx.play("click")
		cb.call())
	return b


## Raccourci clavier sur un bouton (rappelé dans l'infobulle). Les chiffres utilisent la
## touche physique (1 à 9 marchent en AZERTY sans Maj) et le pavé numérique.
func hotkey(b: Button, keys: Array) -> Button:
	var evs := []
	for k in keys:
		var ev := InputEventKey.new()
		if k >= KEY_0 and k <= KEY_9:
			ev.physical_keycode = k
			var kp := InputEventKey.new()
			kp.keycode = KEY_KP_0 + (k - KEY_0)
			evs.append(kp)
		else:
			ev.keycode = k
		evs.append(ev)
	var sc := Shortcut.new()
	sc.events = evs
	b.shortcut = sc
	b.shortcut_in_tooltip = true
	return b


func panel(color := Pal.PANEL, border := Pal.BORDER, bw := 2) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _shadowed(sb(color, border, bw)) if color.a >= 1.0 else sb(color, border, bw))
	return p


## Garde la position de défilement d'une liste qu'on reconstruit (clic sur un élément...) :
## elle est mémorisée dans store[key] et remise en place une fois la liste affichée.
func keep_scroll(sc: ScrollContainer, store: Dictionary, key: String) -> void:
	var v := int(store.get(key, 0))
	_restore_scroll(sc, v, store, key)


func _restore_scroll(sc: ScrollContainer, v: int, store: Dictionary, key: String) -> void:
	# Attendre que la liste ait sa taille (sinon le défilement est ramené à 0)
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(sc):
		return
	sc.scroll_vertical = v
	sc.get_v_scroll_bar().value_changed.connect(func(x: float): store[key] = int(x))


## Cartel de musée (papier crème, texte encre) : pour les textes posés sur le mur.
func cartel() -> Panel:
	return panel(CARTEL, Color("b9a883"), 1)


## Style « sélectionné » (onglets, choix actifs).
func selected(b: Button) -> void:
	b.add_theme_stylebox_override("normal", sb(SELECTED, Pal.ACCENT, 1))
	b.add_theme_color_override("font_color", Pal.ACCENT)


## Place un contrôle à une position/taille fixe dans un parent (layout 640x360).
func put(parent: Node, c: Control, pos: Vector2, size := Vector2.ZERO) -> Control:
	parent.add_child(c)
	c.position = pos
	if size != Vector2.ZERO:
		c.size = size
	return c


## Fond d'écran. Sans couleur : le mur de la galerie (papier peint rayé, cimaise, parquet).
## Avec une couleur : un voile uni (menus par-dessus le jeu, confirmations...).
func fill_bg(parent: Control, color := Color(0, 0, 0, 0)) -> Control:
	var r: Control
	if color.a == 0.0:
		r = _Wall.new()
	else:
		r = _Veil.new()
		(r as _Veil).color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


## Voile uni : couvre son parent, ou tout l'écran si le parent n'a pas de taille.
class _Veil extends Control:
	var color := Color.BLACK

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var s := size if size.x > 0.0 and size.y > 0.0 else get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, s), color)


class _Wall extends Control:
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		# Taille de l'écran (les écrans posés sous un Node n'ont pas de taille propre)
		var s := get_viewport_rect().size
		draw_rect(Rect2(Vector2.ZERO, s), UI.WALL)
		for x in range(0, int(s.x), 12):
			draw_rect(Rect2(x, 0, 5, s.y - 14), UI.WALL_STRIPE)
		# cimaise en haut, plinthe et parquet en bas
		draw_rect(Rect2(0, 2, s.x, 1), UI.GOLD_DARK)
		draw_rect(Rect2(0, s.y - 14, s.x, 14), UI.FLOOR)
		for x in range(0, int(s.x), 40):
			draw_line(Vector2(x, s.y - 14), Vector2(x, s.y), Color(0, 0, 0, 0.2), 1.0)
		draw_rect(Rect2(0, s.y - 16, s.x, 2), UI.WOOD)
		draw_rect(Rect2(0, s.y - 16, s.x, 1), UI.GOLD_DARK)
		# léger vignettage
		draw_rect(Rect2(0, 0, s.x, 6), Color(0, 0, 0, 0.15))


## Vignette d'un dessin (TextureRect pixel-perfect).
func thumb(img: Image, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = size
	tr.size = size
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


## Police du menu (Yoster Island) sur tous les textes d'un bloc : normal → MENU_SIZE,
## gros (≥ 20) → MENU_BIG, très gros titre (≥ 40) → MENU_TITLE. Marges verticales des boutons : MENU_MARGIN.
func fs_title() -> int:
	return 40


func use_menu_font(root: Node) -> void:
	for c in root.get_children():
		if c is Button or c is Label:
			var cur := (c as Control).get_theme_font_size("font_size")
			var n := MENU_TITLE if cur >= fs_title() else (MENU_BIG if cur >= 20 else MENU_SIZE)
			(c as Control).add_theme_font_override("font", font_menu)
			(c as Control).add_theme_font_size_override("font_size", n)
			if c is Button:
				for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
					var sbx := (c as Button).get_theme_stylebox(st).duplicate() as StyleBox
					sbx.content_margin_top = MENU_MARGIN
					sbx.content_margin_bottom = MENU_MARGIN
					(c as Button).add_theme_stylebox_override(st, sbx)
		use_menu_font(c)


## Le logo du jeu (assets/logo.png), centré, avec une ombre portée. Largeur en pixels de jeu.
func logo(parent: Node, center_x: float, y: float, w := 230.0) -> TextureRect:
	var tex: Texture2D = load("res://assets/logo.png")
	var h := w * tex.get_height() / tex.get_width()
	var sh := TextureRect.new()
	sh.texture = tex
	sh.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sh.stretch_mode = TextureRect.STRETCH_SCALE
	sh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sh.modulate = Color(0, 0, 0, 0.35)
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(parent, sh, Vector2(center_x - w / 2.0 + 2, y + 3), Vector2(w, h))
	var tr := sh.duplicate() as TextureRect
	tr.modulate = Color.WHITE
	put(parent, tr, Vector2(center_x - w / 2.0, y), Vector2(w, h))
	return tr
