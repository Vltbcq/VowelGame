class_name Hud
extends CanvasLayer
## Interface pendant une vague : PV, XP, or, chrono, barre du boss, annonces, pause.

var arena: Arena
var draw_layer: Control
var announce_label: Label
var pause_menu: Control
var hint_label: Label
var hint_t := 0.0
var hurt_flash := 0.0
var dev_panel: DevPanel     # OUTIL DE DEV (Ctrl+P) — à retirer avant de publier


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	draw_layer = Control.new()
	draw_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw_layer.draw.connect(_draw_hud)
	add_child(draw_layer)
	announce_label = UI.label("", 30, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	announce_label.position = Vector2(0, 130)
	announce_label.size = Vector2(640, 40)
	add_child(announce_label)
	hint_label = UI.label("", 10, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	hint_label.position = Vector2(60, 300)
	hint_label.size = Vector2(520, 14)
	hint_label.add_theme_stylebox_override("normal", UI.sb(Color(Pal.BG, 0.85), Pal.ACCENT, 1, 8, 3))
	hint_label.visible = false
	add_child(hint_label)
	if Run.wave == 1:
		var holder := Control.new()
		holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(holder)
		(func(): Tips.show(holder, "controls", true)).call_deferred()


func _process(delta: float) -> void:
	hurt_flash = maxf(0.0, hurt_flash - delta * 3.0)
	draw_layer.queue_redraw()
	if hint_t > 0.0:
		hint_t -= delta
		if hint_t <= 0.0:
			hint_label.visible = false
	_check_hints()


## Petit bandeau de conseil en bas de l'écran (une seule fois, sans mettre en pause).
func hint(id: String) -> void:
	if not Tips.enabled() or Tips.seen(id) or hint_t > 0.0:
		return
	Tips.mark(id)
	hint_label.text = Tips.TEXT[id][1]
	hint_label.visible = true
	hint_t = 6.0


func _check_hints() -> void:
	if arena == null or arena.player == null or arena.ended:
		return
	var p := arena.player
	if arena.hazard_effect(p.position, p.radius)[0] < 1.0:
		hint("hint_hazard")
	if arena.boss and is_instance_valid(arena.boss):
		hint("hint_boss")
	if p.hp < p.max_hp * 0.3:
		hint("hint_lowhp")
	for e in arena.enemies:
		if e.elite:
			hint("hint_elite")
			break


func announce(text: String, color: Color) -> void:
	announce_label.text = text
	announce_label.add_theme_color_override("font_color", color)
	announce_label.modulate.a = 1.0
	announce_label.pivot_offset = announce_label.size / 2.0
	announce_label.scale = Vector2(1.8, 1.8)
	var tw := announce_label.create_tween()
	tw.tween_property(announce_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_property(announce_label, "modulate:a", 0.0, 0.5)


func _bar(pos: Vector2, size: Vector2, t: float, col: Color, text := "") -> void:
	var d := draw_layer
	d.draw_rect(Rect2(pos - Vector2(1, 1), size + Vector2(2, 2)), Pal.INK)
	d.draw_rect(Rect2(pos, size), Pal.PANEL)
	d.draw_rect(Rect2(pos, Vector2(size.x * clampf(t, 0.0, 1.0), size.y)), col)
	d.draw_rect(Rect2(pos, Vector2(size.x * clampf(t, 0.0, 1.0), 1)), col.lightened(0.35))
	if text != "":
		_text(pos + Vector2(0, size.y - 1), text, Pal.TEXT, 10, size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _text(pos: Vector2, text: String, col: Color, fs := 10, w := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_layer.draw_string(UI.font, pos + Vector2(1, 1), text, align, w, fs, Pal.INK)
	draw_layer.draw_string(UI.font, pos, text, align, w, fs, col)


func _draw_hud() -> void:
	# Horloge : le temps est arrêté
	if arena.stop_t > 0.0:
		draw_layer.draw_rect(Rect2(0, 0, 640, 360), Color(0.6, 0.75, 1.0, 0.13))
		_text(Vector2(0, 322), "TEMPS ARRÊTÉ  %.1f" % arena.stop_t, Color(0.8, 0.9, 1.0), 10, 640, HORIZONTAL_ALIGNMENT_CENTER)
	# Interro du Professeur : la question, en grand, toujours visible
	for qz in arena.quizzes:
		var k: float = clampf(1.0 - qz.t / qz.dur, 0.0, 1.0)
		draw_layer.draw_rect(Rect2(200, 44, 240, 44), Color(Pal.BG, 0.9))
		draw_layer.draw_rect(Rect2(200, 44, 240, 44), Pal.ACCENT, false, 2.0)
		_text(Vector2(200, 70), String(qz.question), Pal.TEXT, 20, 240, HORIZONTAL_ALIGNMENT_CENTER)
		draw_layer.draw_rect(Rect2(206, 80, 228 * k, 4), Pal.ACCENT if k > 0.35 else Pal.BAD)
		# Les colonnes du tableau, de gauche à droite (toutes visibles, même zoomé) ; la tienne est encadrée
		var n: int = qz.cols
		var cw := 240.0 / n
		var mine := clampi(int(arena.player.position.x / (float(Arena.W) / n)), 0, n - 1)
		for i in n:
			var r := Rect2(200 + i * cw + 2, 90, cw - 4, 18)
			draw_layer.draw_rect(r, Color(Pal.BG, 0.9))
			draw_layer.draw_rect(r, Pal.ACCENT if i == mine else Pal.BORDER, false, 2.0 if i == mine else 1.0)
			_text(Vector2(r.position.x, 104), str(qz.answers[i]), Pal.TEXT, 10, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_text(Vector2(160, 122), "Va dans la colonne de la bonne réponse !", Pal.ACCENT, 10, 320, HORIZONTAL_ALIGNMENT_CENTER)
	# Nuit d'encre (Encrier renversé) : noir partout sauf autour du joueur
	if arena.dark_t > 0.0:
		var a := clampf(arena.dark_t, 0.0, 1.0) * clampf((6.0 - arena.dark_t) * 2.0, 0.0, 1.0)
		var sp: Vector2 = arena.get_viewport().get_canvas_transform() * arena.player.global_position
		var r := 44.0 * arena.cam.zoom.x
		var ink := Color(0.05, 0.04, 0.08, 0.95 * a)
		# Bord doux du cercle de lumière
		for k in 8:
			draw_layer.draw_arc(sp, r + k * 4.0, 0.0, TAU, 48, Color(ink, ink.a * float(k + 1) / 9.0), 4.5)
		# Anneau plein jusqu'aux coins du carré, puis le reste de l'écran
		# Entre le cercle et un carré autour : des quadrilatères (une seule couche, pas de coutures)
		var inner := r + 30.0
		var half := inner * 1.6
		var n := 64
		for i in n:
			var d0 := Vector2.from_angle(TAU * i / n)
			var d1 := Vector2.from_angle(TAU * (i + 1) / n)
			var q0 := d0 * (half / maxf(absf(d0.x), absf(d0.y)))
			var q1 := d1 * (half / maxf(absf(d1.x), absf(d1.y)))
			draw_layer.draw_colored_polygon(PackedVector2Array([sp + d0 * inner, sp + d1 * inner, sp + q1, sp + q0]), ink)
		# Le reste de l'écran
		draw_layer.draw_rect(Rect2(0, 0, 640, maxf(0.0, sp.y - half)), ink)
		draw_layer.draw_rect(Rect2(0, sp.y + half, 640, maxf(0.0, 360 - sp.y - half)), ink)
		draw_layer.draw_rect(Rect2(0, sp.y - half, maxf(0.0, sp.x - half), half * 2.0), ink)
		draw_layer.draw_rect(Rect2(sp.x + half, sp.y - half, maxf(0.0, 640 - sp.x - half), half * 2.0), ink)
	# Voile rouge sur les bords quand on prend un coup
	if hurt_flash > 0.0:
		var c := Color(Pal.BAD, 0.45 * hurt_flash)
		for i in 6:
			var inset := float(i) * 4.0
			var ci := Color(c, c.a * (1.0 - i / 6.0))
			draw_layer.draw_rect(Rect2(inset, inset, 640 - inset * 2.0, 360 - inset * 2.0), ci, false, 4.0)
	if arena == null or arena.player == null:
		return
	var p := arena.player
	_draw_arrows()
	var hp_txt := "♥ %d / %d" % [ceili(maxf(0.0, p.hp)), int(p.max_hp)]
	if p.erase_mult < 1.0:
		hp_txt += " (gommé)"
	_bar(Vector2(8, 8), Vector2(140, 12), p.hp / p.max_hp, Color("d8433b"), hp_txt)
	_bar(Vector2(8, 24), Vector2(140, 4), float(Run.xp) / Run.xp_needed(), Pal.GOOD)
	_text(Vector2(152, 30), "NIV %d" % Run.level, Pal.GOOD)
	_text(Vector2(8, 42), "● %d" % Run.gold, Pal.ACCENT)

	_text(Vector2(0, 22), "VAGUE %d" % Run.wave, Pal.TEXT, 20, 640, HORIZONTAL_ALIGNMENT_CENTER)
	if arena.boss_id == "":
		var tl := maxf(0.0, arena.time_left)
		var col := Pal.BAD if tl < 5.0 else Pal.TEXT
		_text(Vector2(0, 36), "%d" % ceili(tl), col, 10, 640, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Vector2(0, 12), Meta.DIFFICULTIES[Run.difficulty].name, Pal.DIM, 10, 632, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(Vector2(0, 24), "Échap : pause", Pal.DIM, 10, 632, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(Vector2(0, 36), "Molette / + - : zoom", Pal.DIM, 10, 632, HORIZONTAL_ALIGNMENT_RIGHT)

	var b := arena.boss
	if b and is_instance_valid(b) and not b.dead:
		_text(Vector2(0, 334), b.def.name, Pal.BAD, 10, 640, HORIZONTAL_ALIGNMENT_CENTER)
		_bar(Vector2(170, 340), Vector2(300, 8), b.hp / b.max_hp, Pal.BAD)


## Flèches au bord de l'écran vers les ennemis hors champ.
## Boss : toujours (grosse flèche rouge). Tireurs : orange. Les autres : seulement s'ils sont proches.
func _draw_arrows() -> void:
	var cam := arena.cam
	var z := cam.zoom.x
	var center := cam.get_screen_center_position()
	var half := Vector2(320.0, 180.0) / z
	var view := Rect2(center - half, half * 2.0)
	var shown := 0
	var list := arena.enemies.duplicate()
	list.sort_custom(func(a, b): return a.position.distance_squared_to(center) < b.position.distance_squared_to(center))
	for e: Enemy in list:
		if e.dead or view.grow(-4.0).has_point(e.position):
			continue
		var col := Pal.DIM
		var size := 4.0
		var shooter: bool = EnemyDB.TYPES[e.id].get("shoots", false)
		if e.is_boss:
			col = Pal.BAD
			size = 8.0
		elif e.elite:
			col = Pal.ACCENT
			size = 6.0
		elif shooter:
			col = Color("f0a030")
			size = 5.0
		elif e.position.distance_to(arena.player.position) > 240.0:
			continue
		var dir := (e.position - center).normalized()
		# Point sur le bord de l'écran (repère de l'écran 640x360)
		var sc := Vector2(320, 180)
		var k := minf((320.0 - 14.0) / maxf(absf(dir.x), 0.001), (180.0 - 14.0) / maxf(absf(dir.y), 0.001))
		var tip := sc + dir * k
		var back := tip - dir * size * 2.0
		var side := dir.orthogonal() * size
		var pts := PackedVector2Array([tip, back + side, back - side])
		draw_layer.draw_colored_polygon(pts, Color(Pal.INK, 0.8))
		var inner := PackedVector2Array([tip - dir * 2.0, back + side * 0.6 + dir, back - side * 0.6 + dir])
		draw_layer.draw_colored_polygon(inner, col)
		shown += 1
		if shown >= 16:
			break


func _unhandled_input(ev: InputEvent) -> void:
	if DevPanel.ENABLED and ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_P and ev.ctrl_pressed:
		toggle_dev()
		get_viewport().set_input_as_handled()
		return
	if dev_panel:
		return   # l'outil de dev gère ses propres touches
	if ev is InputEventKey and ev.pressed and not ev.echo and (ev.keycode == KEY_ESCAPE or ev.keycode == KEY_P):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_START:
		toggle_pause()


## OUTIL DE DEV : ouvre / ferme le panneau (le jeu est en pause pendant qu'il est ouvert).
func toggle_dev() -> void:
	if dev_panel:
		dev_panel.queue_free()
		dev_panel = null
		get_tree().paused = pause_menu != null
		return
	if arena.ended or pause_menu:
		return
	get_tree().paused = true
	dev_panel = DevPanel.new()
	dev_panel.arena = arena
	add_child(dev_panel)


func toggle_pause() -> void:
	if pause_menu == null and get_tree().paused:
		return   # un conseil est affiché (le jeu est déjà en pause)
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
		get_tree().paused = false
		return
	if arena.ended:
		return
	get_tree().paused = true
	pause_menu = Control.new()
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pause_menu)
	UI.fill_bg(pause_menu, Color(Pal.BG, 0.88))
	UI.put(pause_menu, UI.label("PAUSE", 30, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 16), Vector2(640, 36))
	var stats := UI.label(Stats.describe_player(Run.stats), 10, Pal.TEXT)
	UI.put(pause_menu, stats, Vector2(40, 64), Vector2(200, 280))
	var ws := ""
	for i in Run.weapons.size():
		var w: Dictionary = Run.weapons[i]
		var st: Dictionary = w.st
		var wn: String = WeaponDB.get_def(w.type).name
		if st.kind == "melee":
			ws += "%d. %s %s : %.1f dégâts / %.2fs\n" % [i + 1, wn, Pal.RARITY_NAMES[w.rar], st.damage, st.cooldown]
		else:
			var tot := 0.0
			for bl in st.bullets:
				tot += bl.damage
			ws += "%d. %s %s : %d×, %.1f dégâts / %.2fs\n" % [i + 1, wn, Pal.RARITY_NAMES[w.rar], st.bullets.size() * st.pellets, tot * st.pellets, st.cooldown]
	var am := ""
	for a in Run.amulets:
		am += "%s (%s)\n" % [AmuletDB.get_def(a.id).name, a.zone]
	var syn := ""
	var counts := Run.synergy_counts()
	for e in counts:
		syn += "%s %d/%d%s\n" % [Pal.NAMES[e], counts[e], Run.SYNERGY_NEED, (" ✓ " + Run.SYNERGY_DESC[e]) if counts[e] >= Run.SYNERGY_NEED else ""]
	UI.put(pause_menu, UI.label("ARMES\n" + ws + "\nAMULETTES\n" + (am if am != "" else "aucune") + "\n\nSYNERGIES\n" + (syn if syn != "" else "aucune"), 10, Pal.TEXT), Vector2(260, 64), Vector2(370, 220))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	UI.put(pause_menu, vb, Vector2(40, 270), Vector2(160, 80))
	vb.add_child(UI.hotkey(UI.button("Reprendre", toggle_pause), [KEY_ENTER, KEY_KP_ENTER]))
	vb.add_child(UI.hotkey(UI.button("Options", func():
		var op := OptionsPanel.new()
		pause_menu.add_child(op)
		op.done.connect(func(_r):
			op.queue_free()
			Engine.time_scale = float(Meta.setting("speed")))), [KEY_O]))
	var sq := UI.button("Sauvegarder et quitter", func():
		get_tree().paused = false
		arena.ended = true
		arena.done.emit("suspend"))
	sq.tooltip_text = "Retour au menu. Tu pourras reprendre plus tard :\ncette vague recommencera depuis son début."
	vb.add_child(sq)
	vb.add_child(UI.button("Abandonner la partie", func():
		get_tree().paused = false
		arena.ended = true
		arena.done.emit("quit")))
