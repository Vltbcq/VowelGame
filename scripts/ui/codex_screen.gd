class_name CodexScreen
extends Control
## Bestiaire : toutes les armes, amulettes et ennemis, avec leurs stats et leur DESSIN PAR DÉFAUT.
## Le dessin par défaut est proposé en premier quand on achète / rencontre l'objet en partie
## (on peut toujours le redessiner à ce moment-là). Les armes ont un dessin PAR RARETÉ.
## done(null) pour revenir au titre, done({"a": "draw", "key", "cfg", "tab", "sel"}) pour dessiner.

signal done(result)

const TABS := [["armes", "Armes"], ["amulettes", "Amulettes"], ["ennemis", "Ennemis"]]

var tab := "armes"
var sel := ""
var picker: Control


func _init(start_tab := "armes", start_sel := "") -> void:
	tab = start_tab
	sel = start_sel


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build()


# ------------------------------------------------------------------ Données

func _items() -> Array:
	var out := []
	match tab:
		"armes":
			for id in WeaponDB.TYPES:
				out.append(id)
		"amulettes":
			for d in AmuletDB.LIST:
				out.append(d.id)
		"ennemis":
			for id in EnemyDB.TYPES:
				out.append(id)
	return out


## Ennemi / boss d'une carte pas encore débloquée : on ne sait pas ce que c'est.
func _locked(id: String) -> bool:
	return tab == "ennemis" and not Meta.map_unlocked(int(EnemyDB.get_def(id).get("map", 1)))


func _name(id: String) -> String:
	if _locked(id):
		return "???"
	match tab:
		"armes":
			return WeaponDB.get_def(id).name
		"amulettes":
			return AmuletDB.get_def(id).name
	return EnemyDB.get_def(id).name


## Emplacements de dessin d'un objet : [clé du carnet, libellé, config de dessin]
func _slots(id: String) -> Array:
	match tab:
		"armes":
			var def := WeaponDB.get_def(id)
			var out := []
			for r in range(int(def.get("min_rar", 0)), 4):
				out.append([Run.weapon_key(id, r), Pal.RARITY_NAMES_F[r], DrawCfg.weapon(id, r, true), Pal.RARITY[r]])
			if def.kind == "ranged" and not def.get("nobullet", false):
				var wa := Analyzer.analyze(_default_or_blank("arme_" + id, Vector2i(def.canvas, def.canvas)))
				out.append(["balle_" + id, "Balles", DrawCfg.bullet(id, wa, "", 0)])
			return out
		"amulettes":
			return [["amulette_" + id, "Amulette", DrawCfg.amulet(AmuletDB.get_def(id))]]
	return [[id, "Ennemi", DrawCfg.enemy(id)]]


func _default_or_blank(key: String, size: Vector2i) -> Image:
	var b = Meta.bestiary_get(key)
	if b != null:
		return b.image
	return Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)


# ------------------------------------------------------------------ Interface

func _build() -> void:
	for c in get_children():
		c.queue_free()
	picker = null
	UI.fill_bg(self)
	UI.put(self, UI.label("BESTIAIRE", 20, Pal.ACCENT), Vector2(12, 8))
	UI.put(self, UI.label("Choisis le dessin par défaut de chaque objet : il sera proposé en premier en partie.", 10, Pal.DIM), Vector2(130, 14))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	UI.put(self, tabs, Vector2(12, 34), Vector2(250, 16))
	for t in TABS:
		var tid: String = t[0]
		var b := UI.button(t[1], func():
			tab = tid
			sel = ""
			_build())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if tid == tab:
			b.add_theme_stylebox_override("normal", UI.sb(UI.SELECTED, Pal.ACCENT, 1))
		tabs.add_child(b)

	var items := _items()
	if sel == "" or not sel in items:
		sel = items[0]

	# --- Liste
	var sc := ScrollContainer.new()
	UI.put(self, sc, Vector2(12, 56), Vector2(250, 272))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	vb.custom_minimum_size = Vector2(238, 0)
	sc.add_child(vb)
	for id in items:
		var iid: String = id
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(236, 24)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var locked := _locked(iid)
		var has_default: bool = not locked and Meta.bestiary_get(_slots(iid)[0][0]) != null
		b.text = "      " + _name(iid) + ("  ✓" if has_default else "")
		if iid == sel:
			b.add_theme_stylebox_override("normal", UI.sb(UI.SELECTED, Pal.ACCENT, 1))
		if tab == "amulettes":
			b.add_theme_color_override("font_color", Pal.RARITY[AmuletDB.get_def(iid).rar])
		var d = null if locked else Meta.bestiary_get(_slots(iid)[0][0])
		if locked:
			b.add_theme_color_override("font_color", Pal.DISABLED)
		var th := UI.thumb(Analyzer.trim(d.image) if d != null else Gfx.icon(Gfx.ICON_UNKNOWN), Vector2(18, 18))
		th.position = Vector2(4, 3)
		b.add_child(th)
		b.pressed.connect(func():
			Sfx.play("click")
			sel = iid
			_build())
		vb.add_child(b)

	# --- Détail
	var p := UI.panel()
	UI.put(self, p, Vector2(270, 56), Vector2(358, 272))
	UI.put(p, UI.label(_name(sel), 20, Pal.ACCENT), Vector2(10, 6), Vector2(338, 24))
	if _locked(sel):
		var fr := UI.panel(Pal.PAPER, Pal.BORDER, 2)
		UI.put(p, fr, Vector2(10, 36), Vector2(76, 76))
		UI.put(fr, UI.thumb(Gfx.icon(Gfx.ICON_UNKNOWN), Vector2(68, 68)), Vector2(4, 4), Vector2(68, 68))
		var lk := UI.label("VERROUILLÉ

Cette créature vit dans une salle que tu n'as pas encore ouverte.

%s" % String(MapDB.get_def(int(EnemyDB.get_def(sel).get("map", 1))).get("unlock", "")), 10, Pal.DIM)
		lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.put(p, lk, Vector2(96, 36), Vector2(250, 120))
		UI.put(self, UI.hotkey(UI.button("Retour", func(): done.emit(null)), [KEY_ESCAPE]), Vector2(12, 334), Vector2(80, 18))
		return
	var slots := _slots(sel)
	var compact := slots.size() > 2
	for i in slots.size():
		if compact:
			_slot_small(p, slots[i], Vector2(10 + i * 68, 32))
		else:
			_slot_ui(p, slots[i], Vector2(10 + i * 172, 34))
	var info := UI.label(_stats_text(sel), 10, Pal.TEXT)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.put(p, info, Vector2(10, 146 if compact else 128), Vector2(338, 120))
	UI.put(self, UI.hotkey(UI.button("Retour", func(): done.emit(null)), [KEY_ESCAPE]), Vector2(12, 334), Vector2(80, 18))


## Version compacte (armes : une case par rareté + balles).
func _slot_small(parent: Control, slot: Array, pos: Vector2) -> void:
	var key: String = slot[0]
	var cfg: Dictionary = slot[2]
	var d = Meta.bestiary_get(key)
	var col: Color = slot[3] if slot.size() > 3 else Pal.DIM
	UI.put(parent, UI.label(String(slot[1]).to_upper(), 10, col, HORIZONTAL_ALIGNMENT_CENTER), pos, Vector2(64, 12))
	var frame := UI.panel(Pal.PAPER, col if d != null else Pal.BORDER, 2)
	UI.put(parent, frame, pos + Vector2(4, 12), Vector2(56, 56))
	var img: Image = Gfx.baked_outline(Analyzer.trim(d.image)) if d != null else Gfx.icon(Gfx.ICON_UNKNOWN)
	UI.put(frame, UI.thumb(img, Vector2(48, 48)), Vector2(4, 4), Vector2(48, 48))
	var g := UI.button("Galerie", func(): _open_picker(key, cfg))
	UI.put(parent, g, pos + Vector2(0, 72), Vector2(64, 16))
	var m := UI.button("Modifier" if d != null else "Dessiner", func():
		done.emit({"a": "draw", "key": key, "cfg": cfg, "tab": tab, "sel": sel}))
	UI.put(parent, m, pos + Vector2(0, 90), Vector2(64, 16))
	if d != null:
		var x := UI.button("×", func():
			Meta.bestiary_remove(key)
			Sfx.play("click")
			_build())
		x.tooltip_text = "Retirer ce dessin par défaut"
		UI.put(parent, x, pos + Vector2(50, 12), Vector2(14, 14))


func _slot_ui(parent: Control, slot: Array, pos: Vector2) -> void:
	var key: String = slot[0]
	var cfg: Dictionary = slot[2]
	var d = Meta.bestiary_get(key)
	UI.put(parent, UI.label(String(slot[1]).to_upper(), 10, Pal.DIM), pos)
	var frame := UI.panel(Pal.PAPER, Pal.ACCENT if d != null else Pal.BORDER, 2)
	UI.put(parent, frame, pos + Vector2(0, 12), Vector2(76, 76))
	var img: Image = Gfx.baked_outline(Analyzer.trim(d.image)) if d != null else Gfx.icon(Gfx.ICON_UNKNOWN)
	UI.put(frame, UI.thumb(img, Vector2(68, 68)), Vector2(4, 4), Vector2(68, 68))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	UI.put(parent, col, pos + Vector2(82, 12), Vector2(76, 76))
	col.add_child(UI.button("Galerie", func(): _open_picker(key, cfg)))
	col.add_child(UI.button("Modifier" if d != null else "Dessiner", func():
		done.emit({"a": "draw", "key": key, "cfg": cfg, "tab": tab, "sel": sel})))
	if d != null:
		col.add_child(UI.button("Retirer", func():
			Meta.bestiary_remove(key)
			Sfx.play("click")
			_build()))


func _stats_text(id: String) -> String:
	var L := []
	match tab:
		"armes":
			var def := WeaponDB.get_def(id)
			L.append("%s — %s" % ["Corps à corps" if def.kind == "melee" else "À distance", def.desc])
			var ink := "Encre %d" % def.ink
			if def.kind == "ranged" and not def.get("nobullet", false):
				ink += " + balles %d" % def.bink
			L.append(ink + "  ·  Rareté : puissance ×1,8 / ×3,2 / ×6")
			var d = Meta.bestiary_get("arme_" + id)
			if d != null:
				var mr := int(def.get("min_rar", 0))
				var w := {"type": id, "rar": mr, "a": Analyzer.analyze(d.image), "effect": d.effect, "beffect": ""}
				if def.kind == "ranged":
					var b := _default_or_blank("balle_" + id, Vector2i(def.bcanvas, def.bcanvas))
					if Analyzer.count_pixels(b) == 0:
						b.set_pixel(1, 1, Pal.INK)
					w.bullet = b
					w.ba = Analyzer.analyze(b)
					w.beffect = ""
				var st := Stats.weapon(w)
				var hit: float = st.get("damage", 0.0)
				if st.kind == "ranged":
					hit = 0.0
					for bl in st.bullets:
						hit += bl.damage
					hit *= st.pellets
				L.append("Avec ton dessin (" + Pal.RARITY_NAMES_F[mr].to_lower() + ") : %.1f dégâts / %.2fs = %.1f dégâts/s, critique %d%%" % [hit, st.cooldown, hit / st.cooldown, roundi(st.crit)])
		"amulettes":
			var def := AmuletDB.get_def(id)
			L.append("%s — encre %d" % [Pal.RARITY_NAMES_F[def.rar], AmuletDB.ink(def)])
			L.append(AmuletDB.describe(def))
			L.append("La taille du dessin ne change pas l'effet ; ses couleurs donnent un peu de résistance élémentaire.")
		"ennemis":
			var def := EnemyDB.get_def(id)
			var kind := "Boss" if def.get("boss", 0) == 2 else ("Mini-boss" if def.has("boss") else "Ennemi")
			L.append("%s — %s, vague %d. %s" % [kind, MapDB.get_def(int(def.get("map", 1))).name, def.wave, def.desc])
			L.append("PV %d · dégâts %s · vitesse %d · encre %d%s" % [roundi(def.hp * (Stats.BOSS_HP if def.has("boss") else Stats.ENEMY_HP)), str(def.dmg), roundi(def.spd), def.ink,
				" (95 %% minimum)" if def.has("boss") else " (90 %% minimum)"])
			var d = Meta.bestiary_get(id)
			if d != null:
				var m := Stats.enemy_art(Analyzer.analyze(d.image), def.ink)
				L.append("Avec ton dessin : élément %s (ses PV ne dépendent pas du dessin)" % Pal.NAMES[m.element])
	return "\n".join(L)


# ------------------------------------------------------------------ Choix dans la galerie

func _open_picker(key: String, cfg: Dictionary) -> void:
	picker = UI.panel(Color(Pal.BG, 0.97), Pal.ACCENT)
	UI.put(self, picker, Vector2(20, 20), Vector2(600, 320))
	UI.put(picker, UI.label("Choisis le dessin par défaut", 10, Pal.ACCENT), Vector2(10, 8))
	UI.put(picker, UI.hotkey(UI.button("Fermer", func():
		picker.queue_free()
		picker = null), [KEY_ESCAPE]), Vector2(530, 6), Vector2(60, 16))
	var sc := ScrollContainer.new()
	UI.put(picker, sc, Vector2(10, 30), Vector2(580, 280))
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	var s: Vector2i = cfg.size
	var shown := 0
	for e in Meta.gallery(cfg.gallery):
		var gi := Meta.gallery_image(e)
		if gi == null:
			continue
		var r := gi.get_used_rect()
		if r.size.x > s.x or r.size.y > s.y:
			continue
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(52, 52)
		b.add_theme_stylebox_override("normal", UI.sb(Pal.PAPER, Pal.BORDER, 1))
		b.add_theme_stylebox_override("hover", UI.sb(Pal.PAPER, Pal.ACCENT, 2))
		var th := UI.thumb(gi, Vector2(44, 44))
		th.position = Vector2(4, 4)
		b.add_child(th)
		b.tooltip_text = "Encre : %d / %d" % [Analyzer.ink_cost(gi), int(cfg.ink)]
		var fx: String = e.get("effect", "")
		b.pressed.connect(func():
			var out := Image.create_empty(s.x, s.y, false, Image.FORMAT_RGBA8)
			var t := Analyzer.trim(gi)
			@warning_ignore("integer_division")
			out.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i((s.x - t.get_width()) / 2, (s.y - t.get_height()) / 2))
			Meta.bestiary_set(key, out, fx, true)
			Sfx.play("buy")
			_build())
		grid.add_child(b)
		shown += 1
	if shown == 0:
		UI.put(picker, UI.label("Aucun dessin de ta galerie n'a la bonne taille.", 10, Pal.DIM), Vector2(10, 40))
