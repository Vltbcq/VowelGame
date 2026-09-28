class_name BestiaryPrompt
extends Control
## Avant de dessiner QUOI QUE CE SOIT, on propose d'abord un dessin existant.
## À gauche : le dessin choisi (au départ, le dernier dessin utilisé pour cet objet).
## Cliquer un dessin de la galerie (à droite) le met dans le cadre de gauche :
## on peut alors l'utiliser tel quel ou le modifier. Bouton « Bord » pour le contour noir.
## done({"a": "keep"|"redraw", "image", "effect", "outline", "from_carnet"})
## | done({"a": "draw", "outline"}) | done({"a": "cancel"})

signal done(result)

var cfg: Dictionary
var existing          # {image, effect, outline} ou null
var reward := 0
var caption := "TON CARNET"

var sel_img: Image
var sel_effect := ""
var from_carnet := false
var outline := false

var frame_cap: Label
var pic: TextureRect
var pic_mat: ShaderMaterial
var keep_btn: Button
var mod_btn: Button
var why_label: Label
var bord_btn: Button
var gallery_btns := []


func _init(draw_cfg: Dictionary, current, pigments_reward := 0, featured_caption := "TON CARNET") -> void:
	cfg = draw_cfg
	existing = current
	reward = pigments_reward
	caption = featured_caption


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	UI.fill_bg(self)
	UI.put(self, UI.label(cfg.title, 20, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 8), Vector2(640, 24))
	var sub := UI.label(String(cfg.get("sub", "")), 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.put(self, sub, Vector2(20, 34), Vector2(600, 26))

	# --- Gauche : le dessin choisi
	frame_cap = UI.label(caption, 10, Pal.DIM)
	UI.put(self, frame_cap, Vector2(24, 64), Vector2(200, 12))
	var frame := UI.panel(Color("b07d1c"), Pal.ACCENT, 2)
	UI.put(self, frame, Vector2(24, 78), Vector2(200, 190))
	var inner := UI.panel(Pal.PAPER, Color("8c6a1a"), 1)
	UI.put(frame, inner, Vector2(8, 8), Vector2(184, 174))
	pic = TextureRect.new()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.put(inner, pic, Vector2(7, 7), Vector2(170, 160))

	keep_btn = UI.hotkey(UI.button("Utiliser ce dessin", _keep, 20), [KEY_ENTER, KEY_KP_ENTER])
	UI.put(self, keep_btn, Vector2(24, 274), Vector2(200, 24))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	UI.put(self, row, Vector2(24, 302), Vector2(200, 16))
	mod_btn = UI.hotkey(UI.button("Modifier", _redraw), [KEY_M])
	mod_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mod_btn)
	var nw := UI.hotkey(UI.button("Nouveau", func(): done.emit({"a": "draw", "outline": outline})), [KEY_N])
	nw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nw)
	bord_btn = UI.hotkey(UI.button("", _toggle_outline), [KEY_C])
	bord_btn.tooltip_text = "Contour noir autour du dessin en jeu"
	UI.put(self, bord_btn, Vector2(24, 322), Vector2(200, 16))
	why_label = UI.label("", 10, Pal.BAD, HORIZONTAL_ALIGNMENT_CENTER)
	UI.put(self, why_label, Vector2(24, 342), Vector2(200, 12))

	if existing != null:
		from_carnet = true
		outline = existing.outline
		_select(existing.image, existing.effect)
	else:
		_select(null, "")

	# --- Droite : dessins de la galerie qui conviennent
	var fits := _fitting()
	UI.put(self, UI.label("CLIQUE UN DESSIN DE TA GALERIE POUR LE PRENDRE", 10, Pal.DIM), Vector2(248, 64))
	var sc := ScrollContainer.new()
	UI.put(self, sc, Vector2(248, 78), Vector2(380, 252))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	for f in fits:
		var e: Dictionary = f[0]
		var gi: Image = f[1]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(58, 58)
		_style_thumb(b, false)
		var th := UI.thumb(gi, Vector2(50, 50))
		th.position = Vector2(4, 4)
		b.add_child(th)
		b.tooltip_text = "Encre : %d" % Analyzer.ink_cost(gi)
		b.pressed.connect(func():
			Sfx.play("click")
			from_carnet = false
			frame_cap.text = "DESSIN CHOISI DANS TA GALERIE"
			_select(gi, _effect_ok(e.get("effect", "")))
			for o in gallery_btns:
				_style_thumb(o, o == b))
		grid.add_child(b)
		gallery_btns.append(b)
	if fits.is_empty():
		UI.put(self, UI.label("Aucun dessin de ta galerie ne convient (taille ou encre).", 10, Pal.DIM), Vector2(248, 82))
	if existing != null:
		UI.put(self, UI.button("< Revenir à mon carnet", func():
			from_carnet = true
			frame_cap.text = caption
			outline = existing.outline
			_select(existing.image, existing.effect)
			for o in gallery_btns:
				_style_thumb(o, false)), Vector2(248, 338), Vector2(170, 18))
	if cfg.get("cancel", false):
		UI.put(self, UI.hotkey(UI.button(String(cfg.get("cancel_label", "Retour")), func(): done.emit({"a": "cancel"})), [KEY_ESCAPE]), Vector2(528, 338), Vector2(100, 18))
	Tips.show(self, "carnet")


func _style_thumb(b: Button, on: bool) -> void:
	b.add_theme_stylebox_override("normal", UI.sb(Pal.PAPER, Pal.ACCENT if on else Pal.BORDER, 3 if on else 1))
	b.add_theme_stylebox_override("hover", UI.sb(Pal.PAPER, Pal.ACCENT, 2))
	b.add_theme_stylebox_override("pressed", UI.sb(Pal.PAPER, Pal.ACCENT, 3))


## Met un dessin dans le grand cadre (ou un « ? » si aucun).
func _select(img: Image, effect: String) -> void:
	sel_img = _fit_canvas(img) if img else null
	sel_effect = effect
	var shown: Image = Analyzer.trim(sel_img) if sel_img else Gfx.icon(Gfx.ICON_UNKNOWN)
	pic.texture = ImageTexture.create_from_image(Gfx.padded(shown))
	pic_mat = Gfx.material(sel_effect, outline and sel_img != null)
	pic.material = pic_mat
	var why := _usable(sel_img) if sel_img else "Rien pour l'instant : dessine-le !"
	keep_btn.disabled = why != ""
	mod_btn.disabled = sel_img == null
	mod_btn.text = "Modifier" + ("  (+%d ◆)" % reward if reward > 0 and from_carnet else "")
	why_label.text = why if sel_img else ""
	keep_btn.text = "Utiliser ce dessin" if sel_img else "Dessiner"
	if sel_img == null:
		keep_btn.disabled = false
	bord_btn.text = "Bord : %s" % ("oui" if outline else "non")


func _toggle_outline() -> void:
	outline = not outline
	pic_mat.set_shader_parameter("outline", outline and sel_img != null)
	bord_btn.text = "Bord : %s" % ("oui" if outline else "non")


func _keep() -> void:
	if sel_img == null:
		done.emit({"a": "draw", "outline": outline})
		return
	Sfx.play("buy")
	done.emit({"a": "keep", "image": sel_img, "effect": sel_effect, "outline": outline, "from_carnet": from_carnet})


func _redraw() -> void:
	if sel_img == null:
		return
	done.emit({"a": "redraw", "image": sel_img, "effect": sel_effect, "outline": outline, "from_carnet": from_carnet})


## "" si le dessin est utilisable tel quel, sinon la raison.
func _usable(img: Image) -> String:
	if img == null:
		return "Rien"
	var s: Vector2i = cfg.size
	var r := img.get_used_rect()
	if r.size.x > s.x or r.size.y > s.y:
		return "Trop grand pour cette toile"
	var cost := Analyzer.ink_cost(img)
	if cost > int(cfg.ink):
		return "Trop d'encre (%d / %d)" % [cost, int(cfg.ink)]
	if cost < int(cfg.get("min_ink", 0)):
		return "Pas assez d'encre (%d / %d min)" % [cost, int(cfg.min_ink)]
	return ""


## Dessins de la galerie compatibles (taille). L'encre est vérifiée sur le dessin choisi :
## un dessin trop gourmand peut quand même être pris puis modifié.
func _fitting() -> Array:
	var out := []
	var s: Vector2i = cfg.size
	for e in Meta.gallery(cfg.gallery):
		var gi := Meta.gallery_image(e)
		if gi == null:
			continue
		var r := gi.get_used_rect()
		if r.size.x > s.x or r.size.y > s.y:
			continue
		out.append([e, gi])
		if out.size() >= 48:
			break
	return out


func _effect_ok(fx: String) -> String:
	return fx if fx in Meta.effects() else ""


## Recentre le dessin sur une toile de la taille attendue.
func _fit_canvas(src: Image) -> Image:
	var s: Vector2i = cfg.size
	var t := Analyzer.trim(src)
	var out := Image.create_empty(s.x, s.y, false, Image.FORMAT_RGBA8)
	var ss := t.get_size()
	@warning_ignore("integer_division")
	out.blit_rect(t, Rect2i(Vector2i.ZERO, Vector2i(mini(ss.x, s.x), mini(ss.y, s.y))), Vector2i(maxi(0, (s.x - ss.x) / 2), maxi(0, (s.y - ss.y) / 2)))
	return out
