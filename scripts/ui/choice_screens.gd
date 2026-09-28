class_name ChoiceScreens
extends RefCounted
## Petits écrans de choix : sauvegardes, confirmation, difficulté, type d'arme, fin de partie.


## Choix de la carte. done(id) ou done(null).
static func map_choice() -> Control:
	var s := _Screen.new()
	s.build = func(root: _Screen):
		UI.put(root, UI.label("Choisis ta salle d'exposition", 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 24), Vector2(640, 24))
		var i := 0
		for id in MapDB.MAPS:
			var d: Dictionary = MapDB.MAPS[id]
			var open := Meta.map_unlocked(id)
			var p := UI.panel(Color("2f4a3a") if d.floor == "board" else Pal.PAPER.darkened(0.55), Pal.ACCENT if open else Pal.BORDER, 2)
			UI.put(root, p, Vector2(70 + i * 260, 64), Vector2(240, 230))
			UI.put(p, UI.label(d.name, 20, Pal.ACCENT if open else Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 12), Vector2(240, 24))
			var txt: String = d.desc if open else "VERROUILLÉE\n\n" + String(d.get("unlock", ""))
			var l := UI.label(txt, 10, Pal.TEXT if open else Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			UI.put(p, l, Vector2(14, 48), Vector2(212, 130))
			var mid: int = id
			var b := UI.hotkey(UI.button("Jouer ici (%d)" % (i + 1), func(): root.done.emit(mid)), [KEY_1 + i])
			b.disabled = not open
			UI.put(p, b, Vector2(50, 192), Vector2(140, 22))
			i += 1
		UI.put(root, UI.hotkey(UI.button("Retour", func(): root.done.emit(null)), [KEY_ESCAPE]), Vector2(20, 330), Vector2(80, 18))
	return s


## Choix parmi les 3 sauvegardes. done({"a": "play"|"delete", "n"}) ou {"a": "quit"}.
static func slots() -> Control:
	var s := _Screen.new()
	s.build = func(root: _Screen):
		UI.put(root, UI.label("VOWEL", 40, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 14), Vector2(640, 44))
		UI.put(root, UI.label("Choisis ta sauvegarde", 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 62), Vector2(640, 14))
		for i in Meta.SLOTS:
			var n := i + 1
			var sm := Meta.slot_summary(n)
			var p := UI.panel(Pal.PANEL, Pal.ACCENT if n == Meta.slot else Pal.BORDER, 2)
			UI.put(root, p, Vector2(40 + i * 192, 90), Vector2(176, 200))
			UI.put(p, UI.label("Sauvegarde %d" % n, 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 10), Vector2(176, 24))
			var txt := "Vide : une toile blanche."
			if not sm.is_empty():
				txt = "◆ %d pigments\nParties : %d · Victoires : %d\nRecord : vague %d\nGalerie : %d dessins" % [
					sm.pigments, sm.runs, sm.wins, sm.best_wave, sm.drawings]
				txt += "\n\nPartie en cours :\n" + String(sm.get("run", "aucune"))
			var l := UI.label(txt, 10, Pal.TEXT if not sm.is_empty() else Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			UI.put(p, l, Vector2(8, 44), Vector2(160, 100))
			UI.put(p, UI.hotkey(UI.button(("Jouer (%d)" if not sm.is_empty() else "Commencer (%d)") % n,
				func(): root.done.emit({"a": "play", "n": n})), [KEY_1 + i]), Vector2(28, 148), Vector2(120, 20))
			if not sm.is_empty():
				UI.put(p, UI.button("Supprimer", func(): root.done.emit({"a": "delete", "n": n})), Vector2(48, 174), Vector2(80, 16))
		UI.put(root, UI.button("Quitter le jeu", func(): root.done.emit({"a": "quit"})), Vector2(20, 330), Vector2(110, 18))
	return s


## Confirmation : done(true) / done(false). Échap = non ; Entrée = oui, sauf si c'est dangereux
## (suppression) : il faut alors cliquer.
static func confirm(title: String, text: String, yes: String, no: String, danger := false) -> Control:
	var s := _Screen.new()
	s.build = func(root: _Screen):
		var p := UI.panel(Pal.PANEL, Pal.BAD, 2)
		UI.put(root, p, Vector2(150, 110), Vector2(340, 140))
		UI.put(p, UI.label(title, 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 12), Vector2(340, 24))
		var l := UI.label(text, 10, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.put(p, l, Vector2(16, 44), Vector2(308, 50))
		UI.put(p, UI.hotkey(UI.button(no, func(): root.done.emit(false)), [KEY_ESCAPE]), Vector2(40, 104), Vector2(120, 20))
		var yb := UI.button(yes, func(): root.done.emit(true))
		if not danger:
			UI.hotkey(yb, [KEY_ENTER, KEY_KP_ENTER])
		UI.put(p, yb, Vector2(180, 104), Vector2(120, 20))
	return s


## Difficultés de cette carte : chaque carte a ses propres difficultés débloquées.
static func difficulty(map_id := 1) -> Control:
	var s := _Screen.new()
	s.build = func(root: _Screen):
		UI.put(root, UI.label("Choisis la difficulté", 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 22), Vector2(640, 24))
		UI.put(root, UI.label(MapDB.get_def(map_id).name, 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 50), Vector2(640, 14))
		var maxd := Meta.max_diff(map_id)
		for i in Meta.DIFFICULTIES.size():
			var d: Dictionary = Meta.DIFFICULTIES[i]
			var idx := i
			var y := 80 + i * 44
			var b := UI.hotkey(UI.button(d.name, func(): root.done.emit(idx), 20), [KEY_1 + i])
			UI.put(root, b, Vector2(150, y), Vector2(160, 30))
			var txt: String = d.desc + "\nRécompense : ×%.2f pigments" % d.reward
			if i > maxd:
				b.disabled = true
				txt = "Gagne une partie en %s sur cette carte pour débloquer." % Meta.DIFFICULTIES[i - 1].name
			UI.put(root, UI.label(txt, 10, Pal.DIM if i > maxd else Pal.TEXT), Vector2(322, y + 4), Vector2(300, 30))
		UI.put(root, UI.hotkey(UI.button("Retour", func(): root.done.emit(null)), [KEY_ESCAPE]), Vector2(20, 330), Vector2(80, 18))
	return s


## Choix de la première arme : 3 armes tirées au hasard (au moins une de mêlée et une à distance).
static func weapon_kind() -> Control:
	var s := _Screen.new()
	var melee := WeaponDB.of_kind("melee")
	var ranged := WeaponDB.of_kind("ranged")
	melee.shuffle()
	ranged.shuffle()
	var picks: Array = [melee[0], ranged[0]]
	var rest: Array = melee.slice(1) + ranged.slice(1)
	picks.append(rest.pick_random())
	picks.shuffle()
	s.build = func(root: _Screen):
		UI.put(root, UI.label("Ta première arme", 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 20), Vector2(640, 24))
		UI.put(root, UI.label("3 armes tirées au hasard. Tu la dessineras une fois : ce dessin servira pour toute la partie.", 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 48), Vector2(640, 14))
		for i in picks.size():
			var id: String = picks[i]
			var def := WeaponDB.get_def(id)
			var p := UI.panel()
			UI.put(root, p, Vector2(40 + i * 192, 80), Vector2(176, 220))
			UI.put(p, UI.label(def.name, 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 10), Vector2(176, 24))
			UI.put(p, UI.label("Corps à corps" if def.kind == "melee" else "À distance", 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 38), Vector2(176, 12))
			var ink := "Encre %d" % def.ink
			if def.kind == "ranged":
				ink += " + balles %d" % def.bink
			var l := UI.label(def.desc + "\n\n" + ink, 10, Pal.TEXT)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			UI.put(p, l, Vector2(12, 62), Vector2(152, 110))
			UI.put(p, UI.hotkey(UI.button("Choisir (%d)" % (i + 1), func(): root.done.emit(id)), [KEY_1 + i]), Vector2(38, 186), Vector2(100, 20))
	return s


static func end_run(win: bool, earned: int, unlocked: Array = []) -> Control:
	var s := _Screen.new()
	s.build = func(root: _Screen):
		var title := "VICTOIRE !" if win else "EFFACÉ..."
		UI.put(root, UI.label(title, 40, Pal.GOOD if win else Pal.BAD, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 30), Vector2(640, 50))
		var lines := [
			"Difficulté : %s" % Meta.DIFFICULTIES[Run.difficulty].name,
			"Vague atteinte : %d / %d" % [Run.wave, Run.WAVES],
			"Ennemis effacés : %d" % Run.kills,
			"Boss vaincus : %d" % Run.bosses,
			"Niveau : %d" % Run.level,
			"",
			"Pigments gagnés : ◆ %d" % earned,
		]
		# Sans déblocage : colonne centrée ; sinon, stats à gauche et récapitulatif à droite
		var cx := 0.0 if unlocked.is_empty() else -150.0
		UI.put(root, UI.label("\n".join(lines), 10, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(cx, 96), Vector2(640, 120))
		if Run.character:
			var th := UI.thumb(Run.build_player_image(), Vector2(72, 72))
			UI.put(root, th, Vector2(284 + cx, 214), Vector2(72, 72))
		if not unlocked.is_empty():
			_recap_panel(root, unlocked, Vector2(330, 96))
		UI.put(root, UI.hotkey(UI.button("Continuer", func(): root.done.emit(true), 20), [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]), Vector2(250, 310), Vector2(140, 26))
		Tips.show(root, "end")
	return s


## Récapitulatif seul (partie en cours remplacée par une nouvelle).
static func unlock_recap(unlocked: Array) -> Control:
	var s := _Screen.new()
	s.build = func(root: _Screen):
		UI.put(root, UI.label("Partie précédente terminée", 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 40), Vector2(640, 24))
		_recap_panel(root, unlocked, Vector2(170, 90))
		UI.put(root, UI.hotkey(UI.button("Continuer", func(): root.done.emit(true), 20), [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]), Vector2(250, 310), Vector2(140, 26))
	return s


## Panneau « Nouveautés débloquées » : un succès par ligne et ce qu'il débloque.
static func _recap_panel(root: Control, unlocked: Array, pos: Vector2) -> void:
	# Épuré : une ligne par nouveauté (catégorie + nom). Au-delà de 9 lignes, la liste défile.
	var rows := unlocked.size()
	var list_h := minf(rows * 18.0, 162.0)
	var p := UI.panel(Pal.PANEL, Pal.ACCENT, 2)
	UI.put(root, p, pos, Vector2(300, 36.0 + list_h))
	UI.put(p, UI.label("DÉBLOQUÉ (%d)" % rows if rows > 9 else "DÉBLOQUÉ", 10, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 8), Vector2(300, 12))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.put(p, sc, Vector2(14, 26), Vector2(282, list_h + 4))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.custom_minimum_size = Vector2(262, 0)
	sc.add_child(vb)
	for i in rows:
		var id := String(unlocked[i])
		var txt := ""
		var col := Pal.GOOD
		if id.begins_with("map:"):
			txt = "Salle : " + String(MapDB.get_def(int(id.substr(4))).name)
			col = Pal.ACCENT
		elif id.begins_with("w:") or id.begins_with("a:"):
			txt = ItemUnlockDB.label(id)
		else:
			var a := AchievementDB.get_def(id)
			txt = "Atelier : " + String(UnlockDB.get_def(a.unlock).name)
		var l := UI.label("★ " + txt, 10, col)
		l.custom_minimum_size = Vector2(262, 12)
		vb.add_child(l)


class _Screen extends Control:
	signal done(result)
	var build: Callable

	func _ready() -> void:
		set_anchors_preset(PRESET_FULL_RECT)
		UI.fill_bg(self)
		build.call(self)
