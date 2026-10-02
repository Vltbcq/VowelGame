class_name TitleScreen
extends Control
## Écran titre façon « galerie d'exposition » : les dessins du joueur sont accrochés dans des
## cadres qui changent régulièrement, et ses persos / ennemis / boss défilent en bas.
## done("play" | "atelier" | "gallery" | "options" | "quit")

signal done(result)

const FRAME_KINDS := ["character", "boss", "enemy", "melee", "ranged", "amulet"]
const KIND_NAMES := {"character": "Personnage", "boss": "Boss", "enemy": "Ennemi", "melee": "Arme",
	"ranged": "Arme", "amulet": "Amulette", "mark": "Marque", "bullet": "Projectile"}
const WALKER_KINDS := ["character", "enemy", "enemy", "boss"]
const FRAME_SPOTS := [Vector2(16, 64), Vector2(16, 186), Vector2(524, 64), Vector2(524, 186)]
const FRAME_SIZE := Vector2(100, 100)
const FLOOR_Y := 338.0

var t := 0.0
var entries := []           # entrées de galerie utilisables
var tex_cache := {}
var frames: Array = []      # {panel, pic, label}
var swap_t := 4.0
var swap_i := 0
var walkers: Array = []     # {tex, x, speed, scale, phase}
var walk_t := 0.5
var parade: Control
var hero: TextureRect


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	UI.fill_bg(self)
	for k in FRAME_KINDS + ["bullet"]:
		entries += Meta.gallery(k)
	# Version du jeu (en bas à droite) : écrite par la pipeline de Release à partir du tag
	var ver := UI.label("v" + String(ProjectSettings.get_setting("application/config/version", "?")), 10, Pal.DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	ver.z_index = 10
	UI.put(self, ver, Vector2(480, 346), Vector2(154, 12))

	# Mur de l'expo (papier) derrière les cadres et le défilé
	var rail := ColorRect.new()
	rail.color = UI.GOLD_DARK
	UI.put(self, rail, Vector2(0, 58), Vector2(640, 2))
	var floor_band := ColorRect.new()
	floor_band.color = UI.WOOD
	UI.put(self, floor_band, Vector2(0, 310), Vector2(640, 50))
	var floor_line := ColorRect.new()
	floor_line.color = UI.GOLD_DARK
	UI.put(self, floor_line, Vector2(0, 310), Vector2(640, 2))

	# Défilé en bas (derrière le menu)
	parade = Control.new()
	parade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parade.draw.connect(_draw_parade)
	UI.put(self, parade, Vector2.ZERO, Vector2(640, 360))

	# Titre
	UI.logo(self, 320.0, 3.0)

	# Cadres
	for i in FRAME_SPOTS.size():
		frames.append(_make_frame(FRAME_SPOTS[i]))
	for i in frames.size():
		_fill_frame(i, false)

	# Menu au centre, dans un panneau
	var mp := UI.panel(Color(Pal.BG, 0.92), Pal.BORDER, 2)
	UI.put(self, mp, Vector2(208, 86), Vector2(224, 222))
	var sb := UI.hotkey(UI.button("Sauvegarde %d  ·  changer" % Meta.slot, func(): done.emit("slots")), [KEY_S])
	UI.put(mp, sb, Vector2(22, 6), Vector2(180, 16))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	UI.put(mp, vb, Vector2(22, 28), Vector2(180, 150))
	var run := Meta.read_run() if Meta.has_run() else {}
	if not run.is_empty():
		var rb := UI.button("Reprendre", func(): done.emit("resume"), 20)
		rb.tooltip_text = "Vague %d · %s" % [int(run.wave), Meta.DIFFICULTIES[int(run.difficulty)].name]
		vb.add_child(UI.hotkey(rb, [KEY_ENTER, KEY_KP_ENTER, KEY_C]))
		vb.add_child(UI.hotkey(UI.button("Nouvelle partie", func(): done.emit("play")), [KEY_N]))
	else:
		vb.add_child(UI.hotkey(UI.button("Nouvelle partie", func(): done.emit("play"), 20), [KEY_ENTER, KEY_KP_ENTER, KEY_N]))
	vb.add_child(UI.hotkey(UI.button("Atelier  ◆ %d" % Meta.pigments(), func(): done.emit("atelier")), [KEY_A]))
	vb.add_child(UI.hotkey(UI.button("Galerie (%d dessins)" % entries.size(), func(): done.emit("gallery")), [KEY_G]))
	vb.add_child(UI.hotkey(UI.button("Bestiaire", func(): done.emit("codex")), [KEY_B]))
	vb.add_child(UI.hotkey(UI.button("Options", func(): done.emit("options")), [KEY_O]))
	vb.add_child(UI.button("Quitter", func(): done.emit("quit")))
	var d := Meta.data
	var info := "Record : vague %d\nParties : %d  ·  Victoires : %d" % [int(d.best_wave), int(d.runs), int(d.wins)]
	UI.put(mp, UI.label(info, 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 190), Vector2(224, 30))
	UI.use_font2(mp)   # essai de la police m6x11plus sur le menu

	for i in 3:
		_spawn_walker(randf_range(40.0, 600.0))
	Tips.show(self, "welcome")
	if entries.is_empty():
		UI.put(self, UI.label("Tes dessins seront exposés ici !", 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 318), Vector2(640, 14))


# ------------------------------------------------------------------ Cadres

func _make_frame(pos: Vector2) -> Dictionary:
	# Cadre doré + passe-partout papier
	var outer := UI.panel(Color("b07d1c"), Pal.ACCENT, 2)
	UI.put(self, outer, pos, FRAME_SIZE)
	var inner := UI.panel(Pal.PAPER, Color("8c6a1a"), 1)
	UI.put(outer, inner, Vector2(6, 6), FRAME_SIZE - Vector2(12, 12))
	var pic := TextureRect.new()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.put(inner, pic, Vector2(4, 4), FRAME_SIZE - Vector2(20, 20))
	# Petit cartel sous le cadre
	var plate := UI.panel(Pal.INK, Color("8c6a1a"), 1)
	UI.put(self, plate, pos + Vector2(12, FRAME_SIZE.y + 2), Vector2(FRAME_SIZE.x - 24, 14))
	var label := UI.label("", 10, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	UI.put(plate, label, Vector2(0, 1), Vector2(FRAME_SIZE.x - 24, 12))
	return {"panel": outer, "pic": pic, "label": label, "inner": inner}


func _texture(e: Dictionary) -> Texture2D:
	var key: String = e.file
	if not tex_cache.has(key):
		var img := Meta.gallery_image(e)
		if img == null:
			return null
		img = Analyzer.trim(img)
		tex_cache[key] = ImageTexture.create_from_image(img)   # sans bord (comme les dessins par défaut)
	return tex_cache[key]


## Met un dessin au hasard dans le cadre i (en évitant ceux déjà affichés).
func _fill_frame(i: int, animate: bool) -> void:
	var f: Dictionary = frames[i]
	var tex: Texture2D = null
	var kind := ""
	if not entries.is_empty():
		var shown := []
		for o in frames:
			shown.append(o.get("file", ""))
		for attempt in 12:
			var e: Dictionary = entries.pick_random()
			if e.file in shown and entries.size() > frames.size():
				continue
			tex = _texture(e)
			if tex:
				kind = e.kind
				f.file = e.file
				break
	if tex == null:
		tex = ImageTexture.create_from_image(Gfx.icon(Gfx.ICON_UNKNOWN))
		kind = ""
	var pic: TextureRect = f.pic
	var label: Label = f.label
	if animate:
		var tw := create_tween()
		tw.tween_property(pic, "modulate:a", 0.0, 0.35)
		tw.tween_callback(func():
			pic.texture = tex
			label.text = KIND_NAMES.get(kind, "À dessiner !"))
		tw.tween_property(pic, "modulate:a", 1.0, 0.35)
	else:
		pic.texture = tex
		label.text = KIND_NAMES.get(kind, "À dessiner !")


# ------------------------------------------------------------------ Défilé

func _spawn_walker(x := -60.0) -> void:
	var pool := entries.filter(func(e): return e.kind in WALKER_KINDS)
	if pool.is_empty():
		return
	var e: Dictionary = pool.pick_random()
	var tex := _texture(e)
	if tex == null:
		return
	var big := maxf(tex.get_width(), tex.get_height())
	var sc := minf(3.0, 56.0 / big)   # gros et bien visible
	if sc >= 1.0:
		sc = floorf(sc)                # échelle entière = pixels nets
	walkers.append({"tex": tex, "x": x, "speed": randf_range(22.0, 38.0) * (0.7 if e.kind == "boss" else 1.0),
		"scale": sc, "phase": randf() * TAU})


func _process(delta: float) -> void:
	t += delta
	# Les cadres flottent un peu
	for i in frames.size():
		var f: Dictionary = frames[i]
		f.panel.position.y = FRAME_SPOTS[i].y + sin(t * 1.3 + i * 1.7) * 2.0
	swap_t -= delta
	if swap_t <= 0.0 and entries.size() > 0:
		swap_t = 3.0
		swap_i = (swap_i + 1) % frames.size()
		_fill_frame(swap_i, true)
	walk_t -= delta
	if walk_t <= 0.0:
		walk_t = randf_range(2.0, 3.5)
		_spawn_walker()
	for w in walkers:
		w.x += w.speed * delta
	walkers = walkers.filter(func(w): return w.x < 720.0)
	parade.queue_redraw()


func _draw_parade() -> void:
	for w in walkers:
		var tex: Texture2D = w.tex
		var sz: Vector2 = tex.get_size() * w.scale
		var bob := absf(sin(t * 7.0 + w.phase)) * 3.0
		var pos := Vector2(w.x - sz.x / 2.0, FLOOR_Y - sz.y - bob)
		parade.draw_set_transform(Vector2(pos.x + sz.x / 2.0, FLOOR_Y), 0.0, Vector2(1.0, 0.35))
		parade.draw_circle(Vector2.ZERO, sz.x * 0.4, Color(0, 0, 0, 0.3))
		parade.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		parade.draw_texture_rect(tex, Rect2(pos, sz), false)
