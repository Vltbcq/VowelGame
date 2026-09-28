class_name ShopScreen
extends Control
## Boutique entre les vagues, mise en scène comme une GALERIE D'ART : les offres sont des tableaux
## accrochés au mur (cadre selon la rareté), avec un cartel et une étiquette de prix ;
## une pastille rouge = vendu. En bas : ta collection (armes, vitrine d'amulettes) et ton portrait.
## Les achats qui demandent un dessin sont renvoyés au Main :
## done({"a": "buy", "i": index}) / done({"a": "fuse", ...}) / done({"a": "arrange"}) / done({"a": "next"})

signal done(result)

const WALL := Color("5a2330")
const WALL_STRIPE := Color("50202b")
const GOLD := Color("d6ab4f")
const GOLD_DARK := Color("8c6414")
const WOOD := Color("3a2418")
const WOOD_PANEL := Color("4a2e1f")
const FLOOR := Color("6b4a2a")
const CARTEL := Color("efe6cf")
const CARTEL_DIM := Color("7a6a55")
const STICKER := Color("b8322a")
## Cadres selon la rareté : bois, laque bleue, laque violette, or
const FRAME := [[Color("8a5a2b"), Color("5a3818")], [Color("2f6fe0"), Color("173a7a")],
	[Color("7a3fa6"), Color("3e1d5a")], [Color("e0a830"), Color("8c6414")]]
const FRAME_HEAL := [Color("5d9a6a"), Color("2e5a38")]
const FRAME_ROULETTE := [Color("b8322a"), Color("1d1a1a")]
const WHEEL_RED := Color("c8322a")
const WHEEL_BLACK := Color("221e1e")
const WHEEL_GREEN := Color("2f9a4a")
const WALL_BOTTOM := 212.0

var spots: Array = []      # rectangles des tableaux éclairés


var default_cache := {}


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build()
	(func(): Tips.show(self, "shop")).call_deferred()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	spots = []
	var wall := _Wall.new()
	wall.shop = self
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wall)

	# --- En-tête : plaques en laiton
	_plaque(Vector2(210, 4), Vector2(220, 26), "GALERIE · SALLE %d / %d" % [Run.wave + 1, Run.WAVES], 10)
	var hp_col := Color("f06a5d") if Run.hp < Run.stats.max_hp * 0.35 else CARTEL
	_plaque(Vector2(10, 4), Vector2(150, 26), "♥ %d / %d  ·  NIV %d" % [ceili(Run.hp), int(Run.stats.max_hp), Run.level], 10, hp_col)
	_plaque(Vector2(480, 4), Vector2(150, 26), "BOURSE  ● %d" % Run.gold, 10, Pal.ACCENT)

	# --- Les tableaux accrochés
	var n := Run.shop_offers.size()
	var fw := minf(92.0, (616.0 - (n - 1) * 10.0) / n)
	var total := n * fw + (n - 1) * 10.0
	var x0 := (640.0 - total) / 2.0
	for i in n:
		_artwork(i, Vector2(x0 + i * (fw + 10.0), 44), fw)

	# --- Ta collection (sur le lambris)
	UI.put(self, UI.label("TA COLLECTION  %d/%d" % [Run.weapons.size(), Run.max_weapons()], 10, GOLD), Vector2(12, 216))
	var syn_txt := ""
	var counts := Run.synergy_counts()
	for e in counts:
		syn_txt += "%s %d/%d%s  " % [Pal.NAMES[e], counts[e], Run.SYNERGY_NEED, " ✓" if counts[e] >= Run.SYNERGY_NEED else ""]
	if syn_txt != "":
		var sl := UI.label(syn_txt, 10, Pal.ACCENT)
		sl.mouse_filter = Control.MOUSE_FILTER_STOP
		var tip := "Synergies : 3 armes d'un même élément dominant\n"
		for e in range(1, Pal.COUNT):
			tip += "%s : %s\n" % [Pal.NAMES[e], Run.SYNERGY_DESC[e]]
		sl.tooltip_text = tip
		UI.put(self, sl, Vector2(130, 216), Vector2(240, 12))
	for i in Run.weapons.size():
		var w: Dictionary = Run.weapons[i]
		# 7 armes (Musée ambulant) : on resserre pour ne pas mordre sur l'autoportrait
		var x := 12 + i * mini(50, 300 / maxi(1, Run.weapons.size()))
		var f := _frame_panel(FRAME[w.rar], 3)
		UI.put(self, f, Vector2(x, 230), Vector2(46, 40))
		UI.put(f, UI.thumb(Run.weapon_image(w), Vector2(36, 30)), Vector2(5, 5), Vector2(36, 30))
		f.tooltip_text = _weapon_tip(w)
		if Run.weapons.size() > 1:
			var refund := _refund(w)
			var idx := i
			var sb := UI.button("+%d" % refund, func(): _sell(idx))
			_style_tag(sb)
			sb.tooltip_text = "Revendre cette œuvre"
			UI.put(self, sb, Vector2(x + 6, 272), Vector2(34, 13))
	var pair := _fusion_pair()
	if not pair.is_empty():
		var def := WeaponDB.get_def(pair[0])
		var fb := UI.button("Fusion : 2× %s → %s" % [def.name, Pal.RARITY_NAMES_F[pair[1] + 1].to_lower()],
			func(): done.emit({"a": "fuse", "type": pair[0], "rar": pair[1]}))
		_style_museum(fb)
		UI.put(self, fb, Vector2(12, 289), Vector2(300, 14))
	# Vitrine des amulettes
	var vit := UI.panel(Color(0.75, 0.85, 1.0, 0.12), Color(0.8, 0.9, 1.0, 0.5), 1)
	UI.put(self, vit, Vector2(12, 307), Vector2(300, 22))
	if Run.amulets.is_empty():
		UI.put(vit, UI.label("vitrine des amulettes (vide)", 10, CARTEL_DIM), Vector2(6, 5))
	var ax := 4
	for am in Run.amulets:
		var th := UI.thumb(am.image, Vector2(16, 16))
		var def := AmuletDB.get_def(am.id)
		th.mouse_filter = Control.MOUSE_FILTER_STOP
		th.tooltip_text = "%s (%s)\n%s" % [def.name, am.zone, AmuletDB.describe(def, am.mag)]
		UI.put(vit, th, Vector2(ax, 3), Vector2(16, 16))
		ax += 18

	# --- Ton portrait + cartel de stats
	var pf := _frame_panel(FRAME[3], 5)
	UI.put(self, pf, Vector2(322, 218), Vector2(64, 76))
	UI.put(pf, UI.thumb(Run.build_player_image(), Vector2(52, 64)), Vector2(6, 6), Vector2(52, 64))
	# Sous l'autoportrait : taille du perso (pixels dessinés) et couleurs, utiles pour Silhouette / Nuancier
	var npx := int(Run.char_a.get("pixels", 0))
	var ncol := int(Run.char_a.get("elements", 0))
	var px := UI.label("%d px\n%d couleur%s" % [npx, ncol, "s" if ncol > 1 else ""], 10, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	px.mouse_filter = Control.MOUSE_FILTER_STOP
	px.tooltip_text = "Autoportrait\nTaille de ton perso : %d pixels dessinés\nCouleurs (éléments) sur ton perso : %d" % [npx, ncol]
	UI.put(self, px, Vector2(312, 296), Vector2(84, 26))
	var ct := UI.panel(CARTEL, Color("b9a883"), 1)
	UI.put(self, ct, Vector2(392, 216), Vector2(238, 112))
	var lines := Stats.describe_player(Run.stats).split("\n")
	var half := ceili(lines.size() / 2.0)
	UI.put(ct, UI.label("\n".join(lines.slice(0, half)), 10, Pal.INK), Vector2(5, 2), Vector2(116, 108))
	UI.put(ct, UI.label("\n".join(lines.slice(half)), 10, Pal.INK), Vector2(121, 2), Vector2(116, 108))

	# --- Actions (plaques de musée)
	var rp := Run.reroll_price()
	var rb := UI.hotkey(UI.button("Nouvel accrochage (%s)" % ("gratuit" if rp == 0 else "● %d" % rp), _reroll), [KEY_R])
	_style_museum(rb)
	rb.disabled = Run.gold < rp
	var odds := Run.rarity_odds()
	rb.tooltip_text = "Relancer : de nouvelles œuvres (de plus en plus cher)
Chances par œuvre : rare %d%% · épique %d%% · légendaire %d%%" % [roundi(odds[0]), roundi(odds[1]), roundi(odds[2])]
	UI.put(self, rb, Vector2(12, 336), Vector2(170, 18))
	var ab := UI.hotkey(UI.button("Ranger mes armes", func(): done.emit({"a": "arrange"})), [KEY_A])
	_style_museum(ab)
	ab.tooltip_text = "Déplace, tourne ou retourne tes armes sur ton perso"
	UI.put(self, ab, Vector2(188, 336), Vector2(124, 18))
	var sq := UI.button("Sauvegarder et quitter", func(): done.emit({"a": "suspend"}))
	_style_museum(sq)
	sq.tooltip_text = "Retour au menu : tu reprendras ici, dans cette boutique."
	UI.put(self, sq, Vector2(318, 336), Vector2(160, 18))
	var nb := UI.hotkey(UI.button("Salle suivante →", func(): done.emit({"a": "next"})), [KEY_ENTER, KEY_KP_ENTER])
	_style_museum(nb)
	UI.put(self, nb, Vector2(488, 334), Vector2(142, 22))


# ------------------------------------------------------------------ Tableaux

func _artwork(i: int, pos: Vector2, fw: float) -> void:
	var o: Dictionary = Run.shop_offers[i]
	var oname := ""
	var kind := ""
	var desc := ""
	var full := false
	var icon: Image = Gfx.icon(Gfx.ICON_UNKNOWN)   # pas encore dessiné : un point d'interrogation
	var frame_cols: Array = FRAME[o.rar]
	match o.type:
		"weapon":
			var def := WeaponDB.get_def(o.wtype)
			var near := Run.closest_art(o.wtype, o.rar)
			var dflt: Image = _default_img(Run.weapon_key(o.wtype, o.rar))
			if Run.has_art(o.wtype, o.rar):
				icon = Analyzer.trim(near.image)
			elif dflt:
				icon = dflt
			elif not near.is_empty():
				icon = Analyzer.trim(near.image)
			oname = def.name
			kind = "%s · %s" % ["Mêlée" if def.kind == "melee" else "Distance", Pal.RARITY_NAMES_F[o.rar].to_lower()]
			desc = def.desc
			if Run.has_art(o.wtype, o.rar):
				desc += "\n✓ Dessinée"
			elif dflt:
				desc += "\nDessin du Bestiaire"
			elif Run.has_any_art(o.wtype):
				desc += "\nÀ redessiner"
			else:
				var mult: float = WeaponDB.RAR_INK[o.rar]
				desc += "\nEncre %d" % roundi(def.ink * mult) + ("+%d" % roundi(def.bink * mult) if def.kind == "ranged" else "")
			if o.rar > 0:
				desc += " · ×%s" % ["", "1,8", "3,2", "6"][o.rar]
			if def.has("scale"):
				# Arme à ratio : la valeur ACTUELLE d'abord (le cartel est petit)
				desc = Stats.scale_text(def.scale).replace("Ratio : ", "") + "\n" + desc
			full = Run.weapons.size() >= Run.max_weapons() and Run.fusion_match(o.wtype, o.rar) < 0
			if Run.weapons.size() >= Run.max_weapons() and not full:
				desc += "\n→ fusionne !"
		"amulet":
			var def := AmuletDB.get_def(o.id)
			oname = def.name
			kind = Pal.RARITY_NAMES_F[o.rar]
			desc = AmuletDB.describe(def)
			if Run.amulet_art.has(o.id):
				icon = Run.amulet_art[o.id].image
			elif _default_img("amulette_" + o.id):
				icon = _default_img("amulette_" + o.id)
		"heal":
			var h: Dictionary = Run.HEALS[o.id]
			oname = h.name
			kind = "Consommable"
			desc = h.desc
			frame_cols = FRAME_HEAL
			full = Run.hp >= Run.stats.max_hp and h.heal > 0.0
			if o.id == "seve":
				full = Run.regen_boost > 0.0
			var liquid: Color = {"grande_potion": Pal.SHADES[1][1], "seve": Pal.main_color(Pal.POISON)}.get(o.id, Pal.SHADES[4][1])
			icon = Gfx.icon(Gfx.ICON_POTION, liquid)
		"roulette":
			oname = "Roulette"
			kind = "Jeu de hasard"
			desc = "Mise ton or : Rouge ou Noir ×2, Vert ×15."
			frame_cols = FRAME_ROULETTE
			icon = _wheel_icon()

	# Le tableau : cadre + toile
	var frame := _frame_panel(frame_cols, 5)
	UI.put(self, frame, pos, Vector2(fw, 64))
	spots.append(Rect2(pos, Vector2(fw, 64)))
	var pic := UI.thumb(icon, Vector2(fw - 16, 48))
	UI.put(frame, pic, Vector2(8, 8), Vector2(fw - 16, 48))
	frame.tooltip_text = Pal.RARITY_NAMES_F[o.rar] if not o.type in ["heal", "roulette"] else kind
	if o.get("new", false) and not o.sold:
		var ukey := ItemUnlockDB.key_weapon(o.wtype) if o.type == "weapon" else ItemUnlockDB.key_amulet(o.id)
		if ItemUnlockDB.CONDS.has(ukey):
			_unlock_badge(frame, pos, fw)
		else:
			# Jamais vue : petite pastille « ! » dans le coin du cadre
			var nb := UI.panel(Pal.ACCENT, GOLD_DARK, 1)
			nb.tooltip_text = "Nouveau : jamais vu en boutique"
			UI.put(self, nb, pos + Vector2(fw - 10, -4), Vector2(14, 14))
			UI.put(nb, UI.label("!", 10, Pal.INK, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 1), Vector2(14, 12))
	if o.type == "weapon" and o.rar > 0:
		frame.tooltip_text += "\nDégâts ×%s · vitesse d'attaque +%d%% · critique +%d%%\nAllonge +%d%% (mêlée) · perforation +%d (distance) · effets élémentaires +%d%%" % [
			str(Stats.RAR_DMG[o.rar]), Stats.RAR_ATK[o.rar], Stats.RAR_CRIT[o.rar],
			roundi((Stats.RAR_REACH[o.rar] - 1.0) * 100.0), Stats.RAR_PIERCE[o.rar], roundi(Stats.RAR_PROC[o.rar] * 100.0)]

	# Le cartel
	var ct := UI.panel(CARTEL, Color("b9a883"), 1)
	UI.put(self, ct, pos + Vector2(-2, 70), Vector2(fw + 4, 94))
	ct.tooltip_text = "%s — %s
%s" % [oname, kind, desc]   # texte complet au survol
	var nl := UI.label(oname, 10, Pal.INK)
	nl.clip_text = true
	UI.put(ct, nl, Vector2(4, 2), Vector2(fw - 4, 12))
	var kl := UI.label(kind, 10, CARTEL_DIM)
	kl.clip_text = true
	UI.put(ct, kl, Vector2(4, 14), Vector2(fw - 4, 12))
	var dl := UI.label(desc, 10, Pal.INK)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.clip_text = true
	UI.put(ct, dl, Vector2(4, 27), Vector2(fw - 4, 50))
	if o.sold:
		# Pastille rouge des galeries : œuvre vendue
		var dot := _Dot.new()
		UI.put(ct, dot, Vector2(fw - 14, 77), Vector2(14, 14))
		UI.put(ct, UI.label("JOUÉ" if o.type == "roulette" else "VENDU", 10, STICKER), Vector2(4, 79), Vector2(fw - 20, 12))
		frame.modulate = Color(1, 1, 1, 0.55)
		return
	var b := UI.button("Miser" if o.type == "roulette" else "● %d" % o.price, func(): _buy(i))
	if i < 9:
		UI.hotkey(b, [KEY_1 + i])
	_style_price(b)
	b.disabled = Run.gold < o.price or full or (o.type == "roulette" and Run.gold < 1)
	if full and o.get("id", "") == "seve":
		b.tooltip_text = "Tu as déjà un Élixir de sève pour la vague suivante."
	elif full and o.type == "weapon":
		b.tooltip_text = "Tu as déjà %d armes : revends-en une." % Run.max_weapons()
	elif full:
		b.tooltip_text = "Tes PV sont déjà au max."
	UI.put(ct, b, Vector2(fw - 50, 77), Vector2(52, 15))


## Objet débloqué par un succès, vu pour la première fois : gros « ! » qui pulse,
## halo doré qui clignote autour du cadre et ruban « DÉBLOQUÉ ».
func _unlock_badge(frame: Control, pos: Vector2, fw: float) -> void:
	var halo := UI.panel(Color(1, 0.85, 0.3, 0.0), Color("ffe066"), 3)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.put(self, halo, pos - Vector2(4, 4), Vector2(fw + 8, 72))
	move_child(halo, frame.get_index())   # derrière le tableau
	var ribbon := UI.panel(Color("e8356b"), Color("ffe066"), 1)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.put(self, ribbon, pos + Vector2(6, 52), Vector2(fw - 12, 14))
	UI.put(ribbon, UI.label("DÉBLOQUÉ", 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 1), Vector2(fw - 12, 12))
	var nb := UI.panel(Color("e8356b"), Color("ffe066"), 2)
	nb.tooltip_text = "Nouveau ! Débloqué grâce à un succès, jamais vu en boutique"
	UI.put(self, nb, pos + Vector2(fw - 16, -9), Vector2(24, 24))
	UI.put(nb, UI.label("!", 20, Color("ffe066"), HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 0), Vector2(24, 24))
	nb.pivot_offset = Vector2(12, 12)
	nb.rotation = 0.2
	var tw := nb.create_tween().set_loops()
	tw.tween_property(nb, "scale", Vector2(1.25, 1.25), 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(nb, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
	var th := halo.create_tween().set_loops()
	th.tween_property(halo, "modulate:a", 0.25, 0.5)
	th.tween_property(halo, "modulate:a", 1.0, 0.5)


# ------------------------------------------------------------------ Styles « musée »

## Dessin par défaut du Bestiaire (montré en vitrine tant que l'objet n'est pas acheté).
func _default_img(key: String) -> Image:
	if not default_cache.has(key):
		var d = Meta.bestiary_get(key)
		default_cache[key] = Analyzer.trim(d.image) if d != null else null
	return default_cache[key]


func _frame_panel(cols: Array, bw: int) -> Panel:
	var s := UI.sb(Pal.PAPER, cols[0], bw, 0, 0)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 3
	s.shadow_offset = Vector2(2, 3)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", s)
	var inner := Panel.new()
	inner.add_theme_stylebox_override("panel", UI.sb(Color(0, 0, 0, 0), cols[1], 1, 0, 0))
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = bw - 1
	inner.offset_top = bw - 1
	inner.offset_right = -bw + 1
	inner.offset_bottom = -bw + 1
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(inner)
	return p


func _plaque(pos: Vector2, size: Vector2, text: String, fs: int, col := Pal.INK) -> void:
	var p := UI.panel(WOOD, GOLD, 2)
	UI.put(self, p, pos, size)
	UI.put(p, UI.label(text, fs, col if col != Pal.INK else GOLD, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, (size.y - 12) / 2.0), Vector2(size.x, 12))


func _style_museum(b: Button) -> void:
	b.add_theme_stylebox_override("normal", UI.sb(WOOD, GOLD_DARK, 1))
	b.add_theme_stylebox_override("hover", UI.sb(WOOD_PANEL, GOLD, 1))
	b.add_theme_stylebox_override("pressed", UI.sb(GOLD, GOLD, 1))
	b.add_theme_stylebox_override("disabled", UI.sb(Color("2a1a12"), Color("4a3524"), 1))
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Pal.ACCENT)


func _style_price(b: Button) -> void:
	b.add_theme_stylebox_override("normal", UI.sb(Pal.INK, Pal.INK, 1, 2, 1))
	b.add_theme_stylebox_override("hover", UI.sb(Color("3d3450"), Pal.ACCENT, 1, 2, 1))
	b.add_theme_stylebox_override("pressed", UI.sb(Pal.ACCENT, Pal.ACCENT, 1, 2, 1))
	b.add_theme_stylebox_override("disabled", UI.sb(Color("cfc3a6"), Color("b9a883"), 1, 2, 1))
	b.add_theme_color_override("font_color", Pal.ACCENT)
	b.add_theme_color_override("font_disabled_color", CARTEL_DIM)


func _style_tag(b: Button) -> void:
	b.add_theme_stylebox_override("normal", UI.sb(CARTEL, Color("b9a883"), 1, 1, 0))
	b.add_theme_stylebox_override("hover", UI.sb(Color.WHITE, Pal.ACCENT, 1, 1, 0))
	b.add_theme_color_override("font_color", Pal.INK)
	b.add_theme_color_override("font_hover_color", Pal.INK)


class _Dot extends Control:
	func _draw() -> void:
		draw_circle(size / 2.0, size.x / 2.0, ShopScreen.STICKER)
		draw_circle(size / 2.0 - Vector2(2, 2), 1.5, Color(1, 1, 1, 0.6))


## Mur tapissé, cimaise dorée, spots au-dessus des tableaux, lambris et parquet.
class _Wall extends Control:
	var shop: ShopScreen

	func _draw() -> void:
		var W := 640.0
		var wb := ShopScreen.WALL_BOTTOM
		draw_rect(Rect2(0, 0, W, wb), ShopScreen.WALL)
		for x in range(0, 640, 12):
			draw_rect(Rect2(x, 0, 5, wb), ShopScreen.WALL_STRIPE)
		# cimaise (rail d'accrochage)
		draw_rect(Rect2(0, 36, W, 2), ShopScreen.GOLD_DARK)
		# spots : lampe en laiton + cône de lumière
		for r: Rect2 in shop.spots:
			var cx := r.position.x + r.size.x / 2.0
			var pts := PackedVector2Array([Vector2(cx - 5, 38), Vector2(cx + 5, 38),
				Vector2(r.end.x + 10, r.end.y + 6), Vector2(r.position.x - 10, r.end.y + 6)])
			draw_colored_polygon(pts, Color(1.0, 0.93, 0.7, 0.09))
			draw_rect(Rect2(cx - 6, 34, 12, 4), ShopScreen.GOLD)
			draw_line(Vector2(r.position.x + 6, 38), Vector2(cx, 30), Color(ShopScreen.GOLD_DARK, 0.6), 1.0)
			draw_line(Vector2(r.end.x - 6, 38), Vector2(cx, 30), Color(ShopScreen.GOLD_DARK, 0.6), 1.0)
		# lambris
		draw_rect(Rect2(0, wb, W, 332 - wb), ShopScreen.WOOD)
		draw_rect(Rect2(0, wb, W, 2), ShopScreen.GOLD_DARK)
		for x in range(8, 640, 106):
			draw_rect(Rect2(x, wb + 10, 96, 106), ShopScreen.WOOD_PANEL, false, 1.0)
		# parquet
		draw_rect(Rect2(0, 332, W, 28), ShopScreen.FLOOR)
		for x in range(0, 640, 40):
			draw_line(Vector2(x, 332), Vector2(x, 360), Color(0, 0, 0, 0.2), 1.0)
		draw_rect(Rect2(0, 332, W, 1), Color(0, 0, 0, 0.35))


# ------------------------------------------------------------------ Logique (inchangée)

func _fusion_pair() -> Array:
	for i in Run.weapons.size():
		var a: Dictionary = Run.weapons[i]
		if a.rar >= 3:
			continue
		for j in range(i + 1, Run.weapons.size()):
			var b: Dictionary = Run.weapons[j]
			if b.type == a.type and b.rar == a.rar:
				return [a.type, a.rar]
	return []


func _buy(i: int) -> void:
	var o: Dictionary = Run.shop_offers[i]
	if o.type == "roulette":
		_open_roulette(i)
		return
	if o.type != "heal":
		done.emit({"a": "buy", "i": i})
		return
	if Run.gold < o.price:
		return
	Run.gold -= o.price
	if Run.HEALS[o.id].has("regen"):
		Run.regen_boost = float(Run.HEALS[o.id].regen)   # Élixir de sève : vague suivante
	else:
		Run.heal(Run.stats.max_hp * Run.HEALS[o.id].heal)
	o.sold = true
	Sfx.play("level")
	_build()


func _weapon_tip(w: Dictionary) -> String:
	var st: Dictionary = w.st
	var nm: String = WeaponDB.get_def(w.type).name
	var ratio := ("\n" + Stats.scale_text(st.scale)) if String(st.get("scale", "")) != "" else ""
	if st.kind == "melee":
		return "%s %s\nDégâts %.1f · Recharge %.2fs\nAllonge %d%s" % [nm, Pal.RARITY_NAMES_F[w.rar].to_lower(), st.damage, st.cooldown, roundi(st.reach), ratio]
	var tot := 0.0
	for b in st.bullets:
		tot += b.damage
	return "%s %s\n%d projectile(s) · %.1f dégâts/tir\nRecharge %.2fs · Portée %d%s" % [nm, Pal.RARITY_NAMES_F[w.rar].to_lower(), st.bullets.size() * st.pellets, tot * st.pellets, st.cooldown, roundi(st.range), ratio]


func _refund(w: Dictionary) -> int:
	return maxi(3, roundi(w.price * 0.4))


func _sell(i: int) -> void:
	Run.gold += _refund(Run.weapons[i])
	Run.weapons.remove_at(i)
	Sfx.play("buy")
	_build()


func _reroll() -> void:
	var p := Run.reroll_price()
	if Run.gold < p:
		return
	Run.gold -= p
	Run.rerolls += 1
	Run.roll_shop()
	_build()


# ------------------------------------------------------------------ Roulette

## Case de la roue -> couleur ("vert" pour 0, puis rouge / noir en alternance).
static func wheel_color(slot: int) -> String:
	if slot == 0:
		return "vert"
	return "rouge" if slot % 2 == 1 else "noir"


func _wheel_icon() -> Image:
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var v := Vector2(x + 0.5, y + 0.5) - c
			var d := v.length()
			if d > 15.0:
				continue
			var col := GOLD_DARK
			if d < 13.5 and d > 5.0:
				var slot := int(fposmod(v.angle() + PI / 2.0, TAU) / TAU * 37.0)
				col = {"vert": WHEEL_GREEN, "rouge": WHEEL_RED, "noir": WHEEL_BLACK}[wheel_color(slot)]
			elif d <= 5.0:
				col = GOLD if d > 2.0 else GOLD_DARK
			img.set_pixel(x, y, col)
	return img


var roul: Control
var roul_bet := 10
var roul_offer := -1


func _open_roulette(i: int) -> void:
	if roul or Run.gold < 1:
		return
	roul_offer = i
	roul_bet = clampi(roul_bet, 1, Run.gold)
	roul = Control.new()
	roul.set_anchors_preset(PRESET_FULL_RECT)
	roul.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(roul)
	UI.fill_bg(roul, Color(0, 0, 0, 0.65))
	var p := _frame_panel(FRAME_ROULETTE, 5)
	UI.put(roul, p, Vector2(120, 24), Vector2(400, 312))
	var inner := UI.panel(WOOD_PANEL, GOLD_DARK, 1)
	UI.put(p, inner, Vector2(6, 6), Vector2(388, 300))
	UI.put(inner, UI.label("ROULETTE", 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 6), Vector2(388, 24))
	var wheel := _Wheel.new()
	UI.put(inner, wheel, Vector2(114, 34), Vector2(160, 160))
	var info := UI.label("Choisis ta mise, puis une couleur.", 10, CARTEL, HORIZONTAL_ALIGNMENT_CENTER)
	UI.put(inner, info, Vector2(0, 198), Vector2(388, 12))
	# Mise
	var bet_l := UI.label("", 10, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	UI.put(inner, bet_l, Vector2(0, 216), Vector2(388, 12))
	var sl := HSlider.new()
	sl.min_value = 1
	sl.max_value = maxi(1, Run.gold)
	sl.step = 1
	sl.value = roul_bet
	sl.focus_mode = Control.FOCUS_NONE
	UI.put(inner, sl, Vector2(60, 232), Vector2(268, 14))
	var upd := func():
		roul_bet = int(sl.value)
		bet_l.text = "MISE : ● %d   (bourse ● %d)" % [roul_bet, Run.gold]
	sl.value_changed.connect(func(_v): upd.call())
	upd.call()
	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 4)
	UI.put(inner, quick, Vector2(94, 250), Vector2(200, 14))
	for q in [["10%", 0.1], ["25%", 0.25], ["50%", 0.5], ["Tout", 1.0]]:
		var f: float = q[1]
		var qb := UI.button(q[0], func(): sl.value = maxi(1, roundi(Run.gold * f)))
		_style_tag(qb)
		qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quick.add_child(qb)
	# Couleurs
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	UI.put(inner, row, Vector2(24, 272), Vector2(340, 20))
	var btns := []
	for c in [["rouge", "ROUGE ×2", WHEEL_RED], ["noir", "NOIR ×2", WHEEL_BLACK], ["vert", "VERT ×15", WHEEL_GREEN]]:
		var cid: String = c[0]
		var cb := UI.button(c[1], func(): _spin(cid, wheel, info, btns, sl))
		cb.add_theme_stylebox_override("normal", UI.sb(c[2], GOLD, 1))
		cb.add_theme_stylebox_override("hover", UI.sb(Color(c[2]).lightened(0.2), GOLD, 2))
		cb.add_theme_color_override("font_color", Color.WHITE)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cb)
		btns.append(cb)
	var close := UI.hotkey(UI.button("×", func(): _close_roulette()), [KEY_ESCAPE])
	_style_tag(close)
	UI.put(inner, close, Vector2(366, 6), Vector2(16, 14))
	btns.append(close)


func _spin(color: String, wheel: _Wheel, info: Label, btns: Array, sl: HSlider) -> void:
	var bet := mini(roul_bet, Run.gold)
	if bet < 1 or wheel.spinning:
		return
	for b in btns:
		b.disabled = true
	sl.editable = false
	Run.gold -= bet
	Run.shop_offers[roul_offer].sold = true
	var slot := randi() % 37
	var res := wheel_color(slot)
	info.text = "Ça tourne..."
	Sfx.play("click")
	await wheel.spin_to(slot)
	var win := res == color
	var gain: int = bet * int(Run.ROULETTE_PAY[color]) if win else 0
	Run.gold += gain
	info.add_theme_color_override("font_color", Pal.GOOD if win else Color("f06a5d"))
	info.text = ("%s ! Gagné : ● %d" % [res.to_upper(), gain]) if win else ("%s... Perdu ● %d" % [res.to_upper(), bet])
	Sfx.play("level" if win else "hurt")
	btns[btns.size() - 1].disabled = false   # fermer
	await get_tree().create_timer(1.6).timeout
	_close_roulette()


func _close_roulette() -> void:
	if roul:
		roul.queue_free()
		roul = null
	_build()


class _Wheel extends Control:
	var angle := 0.0
	var spinning := false

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 4.0
		draw_circle(c, r + 4.0, ShopScreen.GOLD_DARK)
		for k in 37:
			var a0 := angle + TAU * k / 37.0 - PI / 2.0
			var a1 := a0 + TAU / 37.0
			var col: Color = {"vert": ShopScreen.WHEEL_GREEN, "rouge": ShopScreen.WHEEL_RED, "noir": ShopScreen.WHEEL_BLACK}[ShopScreen.wheel_color(k)]
			draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a0) * r, c + Vector2.from_angle((a0 + a1) / 2.0) * r, c + Vector2.from_angle(a1) * r]), col)
		draw_circle(c, r * 0.35, ShopScreen.WOOD)
		draw_circle(c, r * 0.12, ShopScreen.GOLD)
		# pointeur en haut
		draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -r - 6), c + Vector2(7, -r - 6), c + Vector2(0, -r + 10)]), Color.WHITE)

	## Tourne quelques tours et s'arrête avec la case « slot » sous le pointeur.
	func spin_to(slot: int) -> void:
		spinning = true
		var target := -TAU * (slot + 0.5) / 37.0
		var end := angle - fposmod(angle, TAU) + TAU * 5.0 + fposmod(target, TAU)
		var tw := create_tween()
		tw.tween_method(func(v: float):
			angle = v
			queue_redraw(), angle, end, 3.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tw.finished
		angle = fposmod(angle, TAU)
		spinning = false
