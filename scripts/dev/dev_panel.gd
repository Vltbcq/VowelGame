class_name DevPanel
extends Control
## OUTIL DE DEV (Ctrl+P en pleine vague) : modifier les stats du perso, faire apparaître
## n'importe quel ennemi / boss devant soi, donner des armes et des amulettes.
## À RETIRER AVANT DE PUBLIER LE JEU : mettre ENABLED à false (ou supprimer scripts/dev/).

const ENABLED := true

## Stats modifiables : [clé du bonus, libellé, pas]
const STATS := [
	["max_hp", "PV max", 5.0], ["regen", "Régénération", 1.0], ["armor", "Armure", 1.0],
	["dodge", "Esquive %", 5.0], ["speed", "Vitesse %", 10.0], ["dmg", "Dégâts %", 10.0],
	["atk_speed", "Vit. d'attaque %", 10.0], ["crit", "Critique %", 5.0], ["range", "Portée %", 10.0],
	["lifesteal", "Vol de vie %", 5.0], ["luck", "Chance", 10.0], ["harvest", "Pourboire", 5.0],
	["thorns", "Épines", 2.0], ["el_power", "Puissance élém. %", 10.0],
]

var arena: Arena
var unlock_armed := false   # « Tout débloquer » : 2 clics pour confirmer
var tab := "perso"
var jump_to := 0             # « Aller à la vague »
var elite := false
var rar := 0
var body: Control
var scroll_mem := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2.ZERO
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	UI.fill_bg(self, Color(0, 0, 0, 0.75))
	_build()


func _build() -> void:
	if body:
		body.queue_free()
	body = Control.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	var p := UI.panel(Color("1d2a24"), Pal.GOOD, 2)
	UI.put(body, p, Vector2(10, 8), Vector2(620, 344))
	UI.put(p, UI.label("OUTIL DE DEV", 20, Pal.GOOD), Vector2(10, 4))
	UI.put(p, UI.label("Ctrl+P ou Échap pour fermer · à retirer avant de publier", 10, Pal.DIM), Vector2(170, 12))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	UI.put(p, tabs, Vector2(10, 30), Vector2(600, 16))
	for t in [["perso", "Perso"], ["ennemis", "Ennemis"], ["armes", "Armes"], ["amulettes", "Amulettes"], ["familiers", "Familiers"]]:
		var tid: String = t[0]
		var b := UI.button(t[1], func():
			tab = tid
			_build())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if tid == tab:
			UI.selected(b)
		tabs.add_child(b)
	var area := Control.new()
	UI.put(p, area, Vector2(10, 52), Vector2(600, 284))
	match tab:
		"perso":
			_perso(area)
		"ennemis":
			_enemies(area)
		"armes":
			_weapons(area)
		"amulettes":
			_amulets(area)
		"familiers":
			_familiars(area)


# ------------------------------------------------------------------ Perso

func _perso(area: Control) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 2)
	UI.put(area, grid, Vector2.ZERO, Vector2(380, 280))
	for s in STATS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var key: String = s[0]
		var step: float = s[2]
		var val := float(Run.bonus.get(key, 0.0))
		var vs := ("+" if val > 0.0 else "") + (str(int(val)) if is_equal_approx(val, roundf(val)) else str(val))
		var l := UI.label("%s  %s" % [s[1], vs], 10, Pal.TEXT if val == 0.0 else Pal.ACCENT)
		l.custom_minimum_size = Vector2(118, 14)
		row.add_child(l)
		row.add_child(UI.button("-", func(): _bonus(key, -step)))
		row.add_child(UI.button("+", func(): _bonus(key, step)))
		grid.add_child(row)
	var st := Run.stats
	var info := "PV %d/%d · dégâts %+d%% · vit. att. %+d%% · crit %d%% · vitesse %d · esquive %d%% · armure %d" % [
		ceili(arena.player.hp), roundi(arena.player.max_hp), st.dmg, st.atk_speed, st.crit, roundi(st.move), st.dodge, st.armor]
	var il := UI.label(info, 10, Pal.DIM)
	il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.put(area, il, Vector2(0, 250), Vector2(390, 30))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	UI.put(area, col, Vector2(410, 0), Vector2(180, 280))
	col.add_child(UI.button("Invincible : %s" % ("OUI" if arena.player.god else "non"), func():
		arena.player.god = not arena.player.god
		_build()))
	col.add_child(UI.button("Soigner à fond", func():
		arena.player.hp = arena.player.max_hp
		_build()))
	col.add_child(UI.button("+100 or", func():
		Run.gold += 100
		_build()))
	col.add_child(UI.button("+1 niveau (choix après la vague)", func():
		Run.add_xp(Run.xp_needed() - Run.xp)
		_build()))
	col.add_child(UI.button("Remettre les stats à zéro", func():
		Run.bonus = {}
		_refresh_stats()
		_build()))
	col.add_child(UI.button("Tuer tous les ennemis", func():
		for e in arena.enemies.duplicate():
			if not e.dead:
				arena.kill_enemy(e)
		_build()))
	var ua := UI.button("TOUT DÉBLOQUER (sauvegarde)" if not unlock_armed else "Sûr ? Clique encore pour confirmer", func():
		if not unlock_armed:
			unlock_armed = true
		else:
			unlock_armed = false
			Meta.unlock_all()
			UI.toast("OUTIL DE DEV\nTout est débloqué")
		_build())
	ua.tooltip_text = "Objets à succès, succès, améliorations de l'Atelier au max, cartes et difficultés.\nModifie la sauvegarde en cours (irréversible)."
	col.add_child(ua)
	var tb := UI.button("+30 s à la vague", func():
		if arena.time_left > 0.0:
			arena.time_left += 30.0
			arena.wave_len += 30.0
			UI.toast("OUTIL DE DEV\n+30 s (reste %d s)" % ceili(arena.time_left))
		else:
			UI.toast("OUTIL DE DEV\nVague de boss : pas de chrono"))
	tb.tooltip_text = "Ajoute 30 secondes au chrono de la vague en cours"
	tb.disabled = arena.time_left <= 0.0
	col.add_child(tb)
	col.add_child(UI.button("Finir la vague", func():
		_close()
		arena._end_wave()))
	# Aller directement à une vague (sans boutique) : -/+ puis « Y aller »
	if jump_to <= 0:
		jump_to = mini(Run.WAVES, Run.wave + 1)
	var jr := HBoxContainer.new()
	jr.add_theme_constant_override("separation", 2)
	jr.add_child(UI.button("-", func():
		jump_to = maxi(1, jump_to - 1)
		_build()))
	var jl := UI.label("Vague %d" % jump_to, 10, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	jl.custom_minimum_size = Vector2(56, 14)
	jr.add_child(jl)
	jr.add_child(UI.button("+", func():
		jump_to = mini(Run.WAVES, jump_to + 1)
		_build()))
	var go := UI.button("Y aller", func():
		Run.dev_jump = jump_to
		jump_to = 0
		_close()
		arena._end_wave())
	go.tooltip_text = "Termine la vague en cours et lance directement la vague choisie (sans boutique)"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jr.add_child(go)
	col.add_child(jr)


func _bonus(key: String, v: float) -> void:
	Run.bonus[key] = float(Run.bonus.get(key, 0.0)) + v
	_refresh_stats()
	_build()


func _refresh_stats() -> void:
	Run.recompute()
	var p := arena.player
	p.st = Run.stats
	p.radius = Run.stats.radius
	p.refresh_max_hp()


# ------------------------------------------------------------------ Ennemis

func _enemies(area: Control) -> void:
	var eb := UI.button("Élite : %s" % ("OUI" if elite else "non"), func():
		elite = not elite
		_build())
	UI.put(area, eb, Vector2(0, 0), Vector2(110, 16))
	UI.put(area, UI.label("[F] La Feuille · [T] Le Tableau noir · boss en rouge (ils ne finissent pas la vague)", 10, Pal.DIM), Vector2(120, 3))
	var sc := ScrollContainer.new()
	UI.put(area, sc, Vector2(0, 22), Vector2(600, 262))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.keep_scroll(sc, scroll_mem, "ennemis")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	for id in EnemyDB.TYPES:
		var def: Dictionary = EnemyDB.TYPES[id]
		var eid: String = id
		var map := "F" if int(def.get("map", 1)) == 1 else "T"
		var b := UI.button("[%s] %s" % [map, def.name], func(): _spawn(eid))
		b.custom_minimum_size = Vector2(194, 18)
		b.clip_text = true
		b.tooltip_text = "%s%s — %s" % [def.name, " (BOSS)" if def.has("boss") else "", "La Feuille" if map == "F" else "Le Tableau noir"]
		if def.has("boss"):
			b.add_theme_color_override("font_color", Pal.BAD)
		grid.add_child(b)


func _spawn(id: String) -> void:
	_ensure_enemy_art(id)
	var p := arena.player
	var dir := Vector2(-1.0 if p.body.scale.x < 0.0 else 1.0, 0.0)
	var pos := (p.position + dir * 90.0).clamp(Vector2(20, 20), Vector2(Arena.W - 20, Arena.H - 20))
	var e := arena.spawn_enemy_now(id, pos, false, elite)
	if e:
		arena.float_text(pos + Vector2(0, -20), "DEV : " + String(e.def.name), Pal.GOOD)


## Dessin d'un ennemi : celui de la partie, sinon celui du Codex, sinon un rond provisoire.
func _ensure_enemy_art(id: String) -> void:
	var def: Dictionary = EnemyDB.TYPES[id]
	if not Run.enemy_art.has(id):
		var d = Meta.bestiary_get(id)
		var img: Image = d.image if d != null else _blob(def.canvas, int(def.ink * 0.9), Pal.SHADES[0][1])
		Run.set_enemy_art(id, img, d.effect if d != null else "", d.outline if d != null else true)
		if def.get("shoots", false):
			Run.auto_eproj(id)
		arena.tex_cache.erase(id)
	if elite and not Run.elite_art.has(id):
		var base: Image = Run.enemy_art[id].image
		Run.set_elite_art(id, base.duplicate(), Run.enemy_art[id].effect, Run.enemy_art[id].get("outline", false))


# ------------------------------------------------------------------ Armes

func _weapons(area: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	UI.put(area, row, Vector2(0, 0), Vector2(600, 16))
	for r in 4:
		var rr := r
		var b := UI.button(Pal.RARITY_NAMES_F[r], func():
			rar = rr
			_build())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_color_override("font_color", Pal.RARITY[r])
		if r == rar:
			UI.selected(b)
		row.add_child(b)
	row.add_child(UI.button("Retirer toutes les armes", func():
		Run.weapons.clear()
		arena.player.rebuild_weapons()
		_build()))
	UI.put(area, UI.label("Armes : %d (pas de limite en dev). Clique pour ajouter à la rareté choisie." % Run.weapons.size(), 10, Pal.DIM), Vector2(0, 22))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	UI.put(area, grid, Vector2(0, 40), Vector2(600, 240))
	for t in WeaponDB.TYPES:
		var def: Dictionary = WeaponDB.TYPES[t]
		var tid: String = t
		var r: int = maxi(rar, int(def.get("min_rar", 0)))
		var b := UI.button(def.name + ("" if r == rar else " (%s)" % ["com.", "rare", "ép.", "lég."][r]), func(): _give_weapon(tid, r))
		b.custom_minimum_size = Vector2(144, 18)
		b.clip_text = true
		grid.add_child(b)


func _give_weapon(type: String, r: int) -> void:
	var def := WeaponDB.get_def(type)
	if not Run.has_art(type, r):
		var d = Meta.bestiary_get(Run.weapon_key(type, r))
		if d == null:
			d = Meta.bestiary_get(Run.weapon_key(type, int(def.get("min_rar", 0))))
		var img: Image = d.image if d != null else _stick(def.canvas)
		var bullet: Image = null
		if def.kind == "ranged" and not def.get("nobullet", false):
			var bd = Meta.bestiary_get("balle_" + type)
			bullet = bd.image if bd != null else WeaponDB.orb(Pal.SHADES[1][1])
		Run.set_weapon_art(type, r, img, d.effect if d != null else "", bullet, "")
	var n := Run.weapons.size()
	Run.add_weapon(type, r, 0, Vector2(-14 + (n % 6) * 6, -6 + (n / 6) * 8))
	arena.player.rebuild_weapons()
	_refresh_stats()
	arena.float_text(arena.player.position + Vector2(0, -26), "DEV : %s %s" % [def.name, Pal.RARITY_NAMES_F[r].to_lower()], Pal.GOOD)
	_build()


# ------------------------------------------------------------------ Amulettes

func _amulets(area: Control) -> void:
	UI.put(area, UI.button("Retirer toutes les amulettes", func():
		Run.amulets.clear()
		_refresh_stats()
		arena.player.refresh_image()
		_build()), Vector2(0, 0), Vector2(180, 16))
	UI.put(area, UI.label("Amulettes : %d. Clique pour en ajouter une (posée au hasard sur le perso)." % Run.amulets.size(), 10, Pal.DIM), Vector2(190, 3))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.put(area, sc, Vector2(0, 22), Vector2(600, 262))
	UI.keep_scroll(sc, scroll_mem, "amulettes")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sc.add_child(grid)
	for d in AmuletDB.LIST:
		var aid: String = d.id
		var b := UI.button(d.name, func(): _give_amulet(aid))
		b.custom_minimum_size = Vector2(144, 18)
		b.clip_text = true
		b.add_theme_color_override("font_color", Pal.RARITY[d.rar])
		b.tooltip_text = AmuletDB.describe(d)
		grid.add_child(b)


func _give_amulet(id: String) -> void:
	var def := AmuletDB.get_def(id)
	if not Run.amulet_art.has(id):
		var d = Meta.bestiary_get("amulette_" + id)
		var s := AmuletDB.canvas(def)
		Run.set_amulet_art(id, d.image if d != null else _blob(s, int(AmuletDB.ink(def)), Pal.SHADES[2][1]), d.effect if d != null else "")
	var img: Image = Run.amulet_art[id].image
	var r: Rect2i = Run.char_a.rect
	var pos := Vector2i(r.position) + Vector2i(Run.PAD, Run.PAD) + Vector2i(randi_range(0, r.size.x), randi_range(0, r.size.y)) - img.get_size() / 2
	Run.add_amulet(id, img, pos)
	_refresh_stats()
	arena.player.refresh_image()
	arena.float_text(arena.player.position + Vector2(0, -26), "DEV : " + String(def.name), Pal.GOOD)
	_build()


# ------------------------------------------------------------------ Familiers

func _familiars(area: Control) -> void:
	UI.put(area, UI.button("Retirer tous les familiers", func():
		Run.familiars.clear()
		for fm in arena.familiars:
			fm.queue_free()
		arena.familiars.clear()
		_build()), Vector2(0, 0), Vector2(180, 16))
	UI.put(area, UI.label("Familiers : %d. Clique pour en ajouter un (ou le retirer s'il est déjà là)." % Run.familiars.size(), 10, Pal.DIM), Vector2(190, 3))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	UI.put(area, grid, Vector2(0, 22), Vector2(600, 262))
	for d in FamiliarDB.LIST:
		var fid: String = d.id
		var owned: bool = fid in Run.familiars
		var b := UI.button(("✓ " if owned else "") + String(d.name), func(): _toggle_familiar(fid))
		b.custom_minimum_size = Vector2(144, 18)
		b.clip_text = true
		b.add_theme_color_override("font_color", Pal.RARITY[int(d.rar)])
		b.tooltip_text = d.desc
		if owned:
			UI.selected(b)
		grid.add_child(b)


func _toggle_familiar(id: String) -> void:
	var def := FamiliarDB.get_def(id)
	if id in Run.familiars:
		Run.familiars.erase(id)
		for fm in arena.familiars.duplicate():
			if fm.id == id:
				arena.familiars.erase(fm)
				fm.queue_free()
		_build()
		return
	if not Run.familiar_art.has(id):
		var d = Meta.bestiary_get("familier_" + id)
		var s := FamiliarDB.canvas(def)
		Run.set_familiar_art(id, d.image if d != null else _blob(s, int(FamiliarDB.ink(def)), Pal.SHADES[3][1]), d.effect if d != null else "")
	Run.add_familiar(id)
	var fm := Familiar.new()
	arena.world.add_child(fm)
	fm.setup(arena, id)
	arena.familiars.append(fm)
	arena.float_text(arena.player.position + Vector2(0, -26), "DEV : " + String(def.name), Pal.GOOD)
	_build()


# ------------------------------------------------------------------ Divers

func _close() -> void:
	arena.hud.toggle_dev()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()


static func _blob(size: int, px: int, col: Color) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size / 2.0, size / 2.0)
	var r := minf(sqrt(px / PI), size / 2.0 - 1.0)
	for y in size:
		for x in size:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				img.set_pixel(x, y, col)
	return img


## Arme provisoire : un trait horizontal (pointe à droite).
static func _stick(size: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(2, size / 2 - 2, size - 4, 4), Pal.INK)
	img.fill_rect(Rect2i(size - 8, size / 2 - 4, 6, 8), Pal.SHADES[1][1])
	return img
