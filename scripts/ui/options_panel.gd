class_name OptionsPanel
extends Control
## Options : volume, plein écran, vitesse du jeu, zoom par défaut. Émet done(null) en fermant.

signal done(result)

const SPEEDS := [0.75, 1.0, 1.25, 1.5]
const ZOOMS := [1.0, 1.25, 1.5, 1.75, 2.0]

var groups := {}


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	UI.fill_bg(self)
	UI.put(self, UI.label("OPTIONS", 30, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 20), Vector2(640, 36))

	var y := 90.0
	UI.put(self, UI.label("Volume", 10, Pal.TEXT), Vector2(150, y + 2))
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = float(Meta.setting("volume"))
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(v): Meta.set_setting("volume", v))
	sl.drag_ended.connect(func(_c): Sfx.play("click"))
	UI.put(self, sl, Vector2(280, y), Vector2(200, 16))

	y += 40
	UI.put(self, UI.label("Plein écran", 10, Pal.TEXT), Vector2(150, y + 2))
	var fs := UI.button("", func(): pass)
	fs.pressed.connect(func():
		Meta.set_setting("fullscreen", not bool(Meta.setting("fullscreen")))
		fs.text = "Oui" if Meta.setting("fullscreen") else "Non")
	fs.text = "Oui" if Meta.setting("fullscreen") else "Non"
	UI.put(self, fs, Vector2(280, y), Vector2(80, 16))

	y += 40
	UI.put(self, UI.label("Vitesse du jeu", 10, Pal.TEXT), Vector2(150, y + 2))
	_choices("speed", SPEEDS, Vector2(280, y))

	y += 40
	UI.put(self, UI.label("Zoom par défaut", 10, Pal.TEXT), Vector2(150, y + 2))
	_choices("zoom", ZOOMS, Vector2(280, y))
	UI.put(self, UI.label("(en jeu : molette ou + / -)", 10, Pal.DIM), Vector2(280, y + 20))

	y += 44
	UI.put(self, UI.label("Conseils (tutoriel)", 10, Pal.TEXT), Vector2(150, y + 2))
	var tb := UI.button("", func(): pass)
	tb.pressed.connect(func():
		Meta.set_setting("tips", not bool(Meta.setting("tips")))
		tb.text = "Oui" if Meta.setting("tips") else "Non")
	tb.text = "Oui" if Meta.setting("tips") else "Non"
	UI.put(self, tb, Vector2(280, y), Vector2(80, 16))
	var rb := UI.button("Revoir les conseils", func():
		Tips.reset()
		Meta.set_setting("tips", true)
		tb.text = "Oui")
	rb.tooltip_text = "Tous les conseils réapparaîtront au bon moment"
	UI.put(self, rb, Vector2(366, y), Vector2(140, 16))

	# Crédits (licence Creative Commons : attribution obligatoire)
	var cr := UI.label("Musique (La Banane) : « Plastic and Flashing Lights » — Professor Kliq, licence CC BY-NC-SA", 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	UI.put(self, cr, Vector2(0, 296), Vector2(640, 12))
	UI.put(self, UI.hotkey(UI.button("Fermer", func(): done.emit(null), 20), [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]), Vector2(260, 316), Vector2(120, 26))


func _choices(key: String, values: Array, pos: Vector2) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	UI.put(self, row, pos, Vector2(300, 16))
	groups[key] = []
	for v in values:
		var val: float = v
		var b := UI.button("×%s" % str(val), func():
			Meta.set_setting(key, val)
			_refresh())
		b.set_meta("v", val)
		row.add_child(b)
		groups[key].append(b)
	_refresh()


func _refresh() -> void:
	for key in groups:
		for b: Button in groups[key]:
			var on := is_equal_approx(float(b.get_meta("v")), float(Meta.setting(key)))
			if on:
				b.add_theme_stylebox_override("normal", UI.sb(UI.SELECTED, Pal.ACCENT, 1))
				b.add_theme_color_override("font_color", Pal.ACCENT)
			else:
				b.remove_theme_stylebox_override("normal")
				b.remove_theme_color_override("font_color")
