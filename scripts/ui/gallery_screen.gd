class_name GalleryScreen
extends Control
## Tous tes dessins sauvegardés, réutilisables en partie. Clique un dessin pour le sélectionner,
## puis « Supprimer » pour le retirer de ta galerie (avec confirmation).

signal done(result)

const KINDS := [
	["character", "Persos"], ["melee", "Mêlée"], ["ranged", "Distance"], ["bullet", "Balles"],
	["amulet", "Amulettes"], ["enemy", "Ennemis"], ["boss", "Boss"],
]

var scroll_mem := {}         # position de défilement de la grille, par onglet
var kind := "character"
var selected := {}          # entrée de galerie sélectionnée
var confirm: Control


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	confirm = null
	UI.fill_bg(self)
	UI.put(self, UI.label("GALERIE", 20, Pal.ACCENT), Vector2(12, 8))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	UI.put(self, tabs, Vector2(12, 34), Vector2(616, 16))
	for k in KINDS:
		var kid: String = k[0]
		var b := UI.button(k[1], func():
			kind = kid
			selected = {}
			_build())
		b.tooltip_text = "%d dessin(s)" % Meta.gallery(kid).size()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if kid == kind:
			b.add_theme_stylebox_override("normal", UI.sb(UI.SELECTED, Pal.ACCENT, 1))
		tabs.add_child(b)
	var sc := ScrollContainer.new()
	UI.put(self, sc, Vector2(12, 58), Vector2(616, 268))
	UI.keep_scroll(sc, scroll_mem, str(kind))
	var grid := GridContainer.new()
	grid.columns = 11
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	var entries := Meta.gallery(kind)
	for e in entries:
		var img := Meta.gallery_image(e)
		if img == null:
			continue
		var is_sel: bool = not selected.is_empty() and selected.file == e.file
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(52, 52)
		b.tooltip_text = "Encre : %d" % Analyzer.ink_cost(img)
		b.add_theme_stylebox_override("normal", UI.sb(Pal.PAPER, Pal.ACCENT if is_sel else Pal.BORDER, 3 if is_sel else 1))
		b.add_theme_stylebox_override("hover", UI.sb(Pal.PAPER, Pal.ACCENT, 2))
		b.add_theme_stylebox_override("pressed", UI.sb(Pal.PAPER, Pal.ACCENT, 3))
		var th := UI.thumb(img, Vector2(44, 44))
		th.position = Vector2(4, 4)
		b.add_child(th)
		var entry: Dictionary = e
		b.pressed.connect(func():
			Sfx.play("click")
			selected = {} if is_sel else entry
			_build())
		grid.add_child(b)
	if entries.is_empty():
		UI.put(self, UI.label("Aucun dessin ici pour l'instant.", 10, Pal.DIM), Vector2(12, 64))
	UI.put(self, UI.hotkey(UI.button("Retour", func(): done.emit(null)), [KEY_ESCAPE]), Vector2(12, 334), Vector2(80, 18))
	var del := UI.hotkey(UI.button("Supprimer le dessin", _ask_delete), [KEY_DELETE])
	del.disabled = selected.is_empty()
	del.tooltip_text = "Clique d'abord sur un dessin"
	UI.put(self, del, Vector2(468, 334), Vector2(160, 18))
	if not selected.is_empty():
		UI.put(self, UI.label("1 dessin sélectionné", 10, Pal.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(260, 337), Vector2(200, 14))


func _ask_delete() -> void:
	if selected.is_empty() or confirm:
		return
	confirm = Control.new()
	confirm.set_anchors_preset(PRESET_FULL_RECT)
	confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(confirm)
	UI.fill_bg(confirm, Color(0, 0, 0, 0.6))
	var p := UI.panel(Pal.BG, Pal.BAD, 2)
	UI.put(confirm, p, Vector2(170, 110), Vector2(300, 140))
	UI.put(p, UI.label("Supprimer ce dessin ?", 20, Pal.BAD, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 10), Vector2(300, 24))
	var img := Meta.gallery_image(selected)
	if img:
		var bg := UI.panel(Pal.PAPER, Pal.BORDER, 1)
		UI.put(p, bg, Vector2(126, 40), Vector2(48, 48))
		UI.put(bg, UI.thumb(img, Vector2(44, 44)), Vector2(2, 2), Vector2(44, 44))
	UI.put(p, UI.label("Il disparaîtra définitivement de ta galerie.", 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 94), Vector2(300, 12))
	UI.put(p, UI.hotkey(UI.button("Garder", func():
		confirm.queue_free()
		confirm = null), [KEY_ESCAPE]), Vector2(40, 112), Vector2(100, 18))
	UI.put(p, UI.button("Supprimer", func():
		Meta.remove_from_gallery(selected)
		Sfx.play("explode")
		selected = {}
		_build()), Vector2(160, 112), Vector2(100, 18))
