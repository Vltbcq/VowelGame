extends Node
## État de la partie en cours : dessins, armes, amulettes, PV, or, niveau...
##
## Chaque type d'arme et chaque amulette se dessine UNE fois par partie (weapon_art /
## amulet_art) ; les exemplaires achetés ensuite réutilisent ce dessin.

const WAVES := 15          # une partie = 15 vagues, un boss toutes les 5 vagues
const XP_MULT := 0.7        # expérience gagnée (-30%)
const GOLD_MULT := 0.625    # or gagné : 62,5% de la valeur de chaque goutte (0.5 × 1.25)
const PAD := 22         # marge autour du perso pour poser amulettes et marques (zone "aura" large)
const MAX_WEAPONS := 6

## Bonus proposés en montant de niveau : [stat, valeur de base, texte]
const UPGRADES := [
	["max_hp", 3.0, "+{v} PV max"], ["regen", 1.5, "+{v} régénération"], ["armor", 1.0, "+{v} armure"],
	["dodge", 3.0, "+{v}% esquive"], ["speed", 5.0, "+{v}% vitesse"], ["dmg", 5.0, "+{v}% dégâts"],
	["atk_speed", 5.0, "+{v}% vit. d'attaque"], ["crit", 3.0, "+{v}% critique"], ["range", 8.0, "+{v}% portée"],
	["lifesteal", 2.0, "+{v}% vol de vie"], ["luck", 5.0, "+{v} chance"], ["harvest", 3.0, "+{v} récolte"],
	["el_power", 10.0, "+{v}% puissance élém."], ["pickup", 20.0, "+{v} ramassage"], ["thorns", 2.0, "+{v} épines"],
]
const UPGRADE_MULT := [1.0, 1.5, 2.2, 3.0]
const PACT_CHANCE := 0.3     # un choix sur 3 peut être un « pacte » : bonus doublé, mais un malus

## Synergies : 3 armes (ou plus) d'un même élément dominant.
const SYNERGY_NEED := 3
const SYNERGY_DESC := ["", "Brûlure contagieuse", "Éclats de glace à la mort des ennemis gelés",
	"Chaînes d'éclairs plus longues (4 cibles)", "Nuage toxique à la mort des empoisonnés",
	"Marque arcanique doublée (+50% dégâts subis)", "Les éclats de lumière te soignent"]

const HEALS := {
	"potion": {"name": "Fiole d'encre", "heal": 0.3, "price": 7, "desc": "Soigne 30% de tes PV max."},
	"grande_potion": {"name": "Grand flacon", "heal": 0.7, "price": 15, "desc": "Soigne 70% de tes PV max."},
}

var active := false
var map := 1                 # carte de la partie (MapDB)
var difficulty := 0
var wave := 0
var hp := 0.0               # les PV sont conservés d'une vague à l'autre
var character: Image
var char_effect := ""
var char_outline := true
var char_a := {}
var weapon_art := {}        # "type#rareté" -> {image, effect, a, bullet, beffect, ba} : un dessin par rareté
var boss_plan := {}         # vague -> boss de cette partie
var weapons: Array = []     # {type, rar, price, anchor, rot, flip, st}
var amulet_art := {}        # id -> {image, effect, a}
var amulets: Array = []     # {id, image, pos, zone, mag, a, outline}
var enemy_art := {}         # type -> {image, effect, a, mods}
var elite_art := {}         # type -> version élite redessinée (difficultés hautes)
var eproj_art := {}         # type -> {image, a, mods}
var gold := 0
var xp := 0
var xp_rest := 0.0          # fractions d'XP pas encore comptées
var level := 0
var kills := 0
var bosses := 0
var signature := 0
var bonus := {}             # bonus de stats choisis en montant de niveau
var marks: Array = []       # marques d'encre dessinées sur le perso {image, pos, a, outline}
var pending_levels := 0     # niveaux gagnés pendant la vague, à choisir après
var stats := {}
var shop_offers: Array = []
var rerolls := 0
var joconde := 0            # vagues parfaites avec La Joconde (+12% dégâts chacune)
var revived := false        # Renaissance déjà utilisée
var levelup_choices: Array = []   # les 3 bonus proposés au niveau en attente (sauvegardés)


func start(d: int, map_id := 1) -> void:
	active = true
	map = map_id
	difficulty = d
	wave = 0
	hp = 0.0
	character = null
	char_effect = ""
	char_a = {}
	weapon_art = {}
	boss_plan = MapDB.boss_plan(map)
	weapons = []
	amulet_art = {}
	amulets = []
	enemy_art = {}
	elite_art = {}
	eproj_art = {}
	gold = 10 * Meta.level("start_gold")
	xp = 0
	xp_rest = 0.0
	level = 0
	kills = 0
	bosses = 0
	signature = 0
	bonus = {}
	marks = []
	pending_levels = 0
	stats = {}
	shop_offers = []
	joconde = 0
	revived = false
	levelup_choices = []


func diff() -> Dictionary:
	return Meta.DIFFICULTIES[difficulty]


func set_character(img: Image, effect: String, outline := true) -> void:
	character = img
	char_effect = effect
	char_outline = outline
	char_a = Analyzer.analyze(img)
	recompute()
	if hp <= 0.0:
		hp = stats.max_hp


## Recalcule les stats. Si les PV max montent, les PV actuels montent d'autant.
func recompute() -> void:
	var old_max: float = stats.get("max_hp", 0.0)
	stats = Stats.player(self)
	if old_max > 0.0 and stats.max_hp > old_max:
		hp += stats.max_hp - old_max
	hp = minf(hp, stats.max_hp)


func heal(amount: float) -> void:
	hp = minf(stats.max_hp, hp + amount)


## Emplacements d'armes (Musée ambulant : +1).
func max_weapons() -> int:
	return MAX_WEAPONS + amulet_count("musee")


func amulet_count(id: String) -> int:
	var n := 0
	for am in amulets:
		if am.id == id:
			n += 1
	return n


# ------------------------------------------------------------------ Armes

## Vague « effective » pour la difficulté : la vague 15 est aussi dure que l'ancienne vague 20.
func eff_wave() -> float:
	return 1.0 + (wave - 1) * 19.0 / (WAVES - 1)


static func art_key(type: String, rar: int) -> String:
	return "%s#%d" % [type, rar]


## Clé du Bestiaire pour le dessin d'une arme à une rareté. La rareté de base (commune, ou la
## rareté minimum des armes spéciales) garde la clé historique "arme_<type>".
static func weapon_key(type: String, rar: int) -> String:
	if rar <= int(WeaponDB.get_def(type).get("min_rar", 0)):
		return "arme_" + type
	return "arme_%s_r%d" % [type, rar]


func has_art(type: String, rar: int) -> bool:
	return weapon_art.has(art_key(type, rar))


func has_any_art(type: String) -> bool:
	return not closest_art(type, 0).is_empty()


## Dessin le plus proche pour ce type : même rareté, sinon en dessous, sinon au-dessus.
func closest_art(type: String, rar: int) -> Dictionary:
	for r in [rar, rar - 1, rar - 2, rar - 3, rar + 1, rar + 2, rar + 3]:
		if r >= 0 and r <= 3 and weapon_art.has(art_key(type, r)):
			return weapon_art[art_key(type, r)]
	return {}


func art_of(w: Dictionary) -> Dictionary:
	return weapon_art[art_key(w.type, w.rar)]


## Chaque rareté a son propre dessin : les exemplaires moins rares gardent le leur.
func set_weapon_art(type: String, rar: int, img: Image, effect: String, bullet: Image, beffect: String,
		outline := true, boutline := true) -> void:
	var art := {"image": img, "effect": effect, "a": Analyzer.analyze(img), "bullet": bullet, "beffect": beffect,
		"outline": outline, "boutline": boutline}
	if bullet:
		art.ba = Analyzer.analyze(bullet)
	weapon_art[art_key(type, rar)] = art
	for w in weapons:
		if w.type == type and w.rar == rar:
			rebuild_weapon(w)


## Première arme (même type, même rareté < légendaire) qu'un achat pourrait fusionner.
func fusion_match(type: String, rar: int) -> int:
	if rar >= 3:
		return -1
	for i in weapons.size():
		if weapons[i].type == type and weapons[i].rar == rar:
			return i
	return -1


func add_weapon(type: String, rar: int, price: int, anchor: Vector2, rot := 0, flip := false) -> void:
	var w := {"type": type, "rar": rar, "price": price, "anchor": anchor, "rot": rot, "flip": flip}
	rebuild_weapon(w)
	weapons.append(w)


## Applique les déplacements faits dans l'écran de rangement (un par arme existante).
func apply_weapon_moves(moves: Array) -> void:
	for i in mini(moves.size(), weapons.size()):
		var m: Dictionary = moves[i]
		weapons[i].anchor = m.anchor
		weapons[i].rot = m.rot
		weapons[i].flip = m.flip


func rebuild_weapon(w: Dictionary) -> void:
	var art: Dictionary = art_of(w)
	w.st = Stats.weapon({"type": w.type, "rar": w.rar, "a": art.a, "effect": art.effect,
		"bullet": art.bullet, "ba": art.get("ba", {}), "beffect": art.beffect})


## Image de cet exemplaire d'arme (tourné / retourné au moment de la pose).
func weapon_image(w: Dictionary) -> Image:
	return Gfx.transformed(Analyzer.trim(art_of(w).image), w.get("rot", 0), w.get("flip", false))


func weapon_count(type: String) -> int:
	var n := 0
	for w in weapons:
		if w.type == type:
			n += 1
	return n


# ------------------------------------------------------------------ Amulettes

func set_amulet_art(id: String, img: Image, effect: String, outline := true) -> void:
	amulet_art[id] = {"image": Analyzer.trim(img), "effect": effect, "a": Analyzer.analyze(img), "outline": outline}


## img = dessin de l'amulette déjà tourné / retourné par le joueur.
func add_amulet(id: String, img: Image, pos: Vector2i) -> void:
	var def := AmuletDB.get_def(id)
	var a: Dictionary = amulet_art[id].a
	var am := {"id": id, "image": img, "pos": pos, "a": a, "mag": Stats.amulet_mag(a, def),
		"outline": amulet_art[id].get("outline", true)}
	am.zone = zone_at(pos, img.get_size())
	amulets.append(am)
	recompute()


## Zone du perso où tombe le centre de l'amulette.
func zone_at(pos: Vector2i, size: Vector2i) -> String:
	var r: Rect2i = char_a.rect
	r.position += Vector2i(PAD, PAD)
	var c := Vector2(pos) + Vector2(size) / 2.0
	var rf := Rect2(r).grow(1)
	if not rf.has_point(c):
		return "Aura"
	var ty := (c.y - r.position.y) / float(r.size.y)
	var tx := (c.x - r.position.x) / float(r.size.x)
	if ty < 0.33:
		return "Tête"
	if ty > 0.7:
		return "Pieds"
	if tx < 0.22 or tx > 0.78:
		return "Mains"
	return "Cœur"


## Centre du dessin du perso dans l'image composite (origine du joueur en jeu).
func char_center() -> Vector2:
	var r: Rect2i = char_a.rect
	return Vector2(r.position) + Vector2(r.size) / 2.0 + Vector2(PAD, PAD)


## Image du perso avec ses amulettes, avec une marge PAD tout autour.
func build_player_image() -> Image:
	var s := character.get_size()
	var img := Image.create_empty(s.x + PAD * 2, s.y + PAD * 2, false, Image.FORMAT_RGBA8)
	img.blit_rect(character, Rect2i(Vector2i.ZERO, s), Vector2i(PAD, PAD))
	for m in marks:
		var mi: Image = m.image
		var mp: Vector2i = m.pos
		if m.get("outline", true):
			mi = Gfx.baked_outline(mi)
			mp -= Vector2i.ONE
		img.blend_rect(mi, Rect2i(Vector2i.ZERO, mi.get_size()), mp)
	for am in amulets:
		var ai: Image = am.image
		var pos: Vector2i = am.pos
		if am.id == "tache":
			_ink_blob(img, pos + ai.get_size() / 2)
		if am.get("outline", true):
			ai = Gfx.baked_outline(ai)
			pos -= Vector2i.ONE
		img.blend_rect(ai, Rect2i(Vector2i.ZERO, ai.get_size()), pos)
	return img


## Tache indélébile : une grosse tache d'encre irrégulière sur le perso.
func _ink_blob(img: Image, c: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = c.x * 131 + c.y
	var blobs := [[Vector2(c), 6.5]]
	for i in 5:
		blobs.append([Vector2(c) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, 8.0), rng.randf_range(1.5, 3.5)])
	for bl in blobs:
		var p: Vector2 = bl[0]
		var r: float = bl[1]
		for y in range(int(p.y - r), int(p.y + r) + 1):
			for x in range(int(p.x - r), int(p.x + r) + 1):
				if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and Vector2(x, y).distance_to(p) <= r:
					img.set_pixel(x, y, Pal.INK)


# ------------------------------------------------------------------ Ennemis

func set_enemy_art(id: String, img: Image, effect: String, outline := true) -> void:
	var def := EnemyDB.get_def(id)
	var a := Analyzer.analyze(img)
	enemy_art[id] = {"image": img, "effect": effect, "a": a, "mods": Stats.enemy_art(a, def.ink), "outline": outline}


## Version élite : le dessin de base + des ajouts du joueur (plus d'encre).
func set_elite_art(id: String, img: Image, effect: String, outline := true) -> void:
	var def := EnemyDB.get_def(id)
	var a := Analyzer.analyze(img)
	elite_art[id] = {"image": img, "effect": effect, "a": a, "mods": Stats.enemy_art(a, roundi(def.ink * 1.4)), "outline": outline}


## Élément dominant d'une arme (arme + balles), ou 0 si aucun ne domine.
func weapon_element(w: Dictionary) -> int:
	var frac: Array = w.st.frac
	var best := 0
	var best_v := 0.3
	for e in range(1, Pal.COUNT):
		if frac[e] >= best_v:
			best_v = frac[e]
			best = e
	return best


func synergy_counts() -> Dictionary:
	var c := {}
	for w in weapons:
		var e := weapon_element(w)
		if e > 0:
			c[e] = int(c.get(e, 0)) + 1
	return c


func active_synergies() -> Dictionary:
	var out := {}
	var c := synergy_counts()
	for e in c:
		if c[e] >= SYNERGY_NEED:
			out[e] = c[e]
	return out


## Projectile ennemi automatique : une goutte d'encre de la couleur de l'ennemi.
func auto_eproj(id: String) -> void:
	var def := EnemyDB.get_def(id)
	var el: int = enemy_art[id].mods.element
	var col: Color = Pal.main_color(el) if el > 0 else Pal.SHADES[0][1]
	var n := 9 if def.has("boss") else 7
	var img := Image.create_empty(n, n + 2, false, Image.FORMAT_RGBA8)
	var c := Vector2((n - 1) / 2.0, n / 2.0 + 1.0)
	for y in n + 2:
		for x in n:
			var d := Vector2(x, y) - c
			# Rond + pointe vers le haut = goutte
			var inside := d.length() <= n / 2.0 - 0.3 or (y < c.y and absf(d.x) <= (y - 0.5) * 0.45)
			if inside:
				img.set_pixel(x, y, col)
	img.set_pixel(int(c.x) - 1, int(c.y) - 1, col.lightened(0.6))
	set_eproj_art(id, img, "", true)
	eproj_art[id].mods.speed = 1.0


func set_eproj_art(id: String, img: Image, effect: String, outline := true) -> void:
	var a := Analyzer.analyze(img)
	eproj_art[id] = {"image": img, "effect": effect, "a": a, "mods": Stats.eproj_art(a), "outline": outline}


## Contexte pour les succès (vagues finies, niveau, arme légendaire...).
func achievement_ctx(cleared := -1, clean := false, win := false) -> Dictionary:
	var legend := false
	for w in weapons:
		legend = legend or w.rar == 3
	return {"cleared": wave - 1 if cleared < 0 else cleared, "kills": kills, "level": level,
		"legend": legend, "clean": clean, "win": win, "diff": difficulty}


# ------------------------------------------------------------------ Sauvegarde de la partie en cours

## Photo de la partie à un point d'étape (stage = "wave" : la vague `wave` va commencer ;
## "after" : la vague `wave` est finie, reste les niveaux et la boutique).
## Les dessins sont stockés en PNG ; tout ce qui se recalcule (stats, analyses) ne l'est pas.
func to_save(stage: String) -> Dictionary:
	var d := {"version": 1, "stage": stage, "map": map, "difficulty": difficulty, "wave": wave, "hp": hp,
		"character": _png(character), "char_effect": char_effect, "char_outline": char_outline,
		"boss_plan": boss_plan.duplicate(), "gold": gold, "xp": xp, "xp_rest": xp_rest, "level": level,
		"kills": kills, "bosses": bosses, "signature": signature, "bonus": bonus.duplicate(),
		"pending_levels": pending_levels, "shop_offers": shop_offers.duplicate(true), "rerolls": rerolls,
		"joconde": joconde, "revived": revived, "levelup_choices": levelup_choices.duplicate(true)}
	var wa := {}
	for k in weapon_art:
		var e: Dictionary = weapon_art[k]
		wa[k] = {"image": _png(e.image), "effect": e.effect, "bullet": _png(e.bullet), "beffect": e.beffect,
			"outline": e.get("outline", true), "boutline": e.get("boutline", true)}
	d.weapon_art = wa
	d.weapons = weapons.map(func(w): return {"type": w.type, "rar": w.rar, "price": w.price, "anchor": w.anchor,
		"rot": w.get("rot", 0), "flip": w.get("flip", false)})
	var aa := {}
	for k in amulet_art:
		aa[k] = {"image": _png(amulet_art[k].image), "effect": amulet_art[k].effect, "outline": amulet_art[k].get("outline", true)}
	d.amulet_art = aa
	d.amulets = amulets.map(func(am): return {"id": am.id, "image": _png(am.image), "pos": am.pos})
	d.marks = marks.map(func(m): return {"image": _png(m.image), "pos": m.pos, "outline": m.get("outline", true)})
	for field in ["enemy_art", "elite_art", "eproj_art"]:
		var src: Dictionary = get(field)
		var out := {}
		for k in src:
			out[k] = {"image": _png(src[k].image), "effect": src[k].effect, "outline": src[k].get("outline", true)}
		d[field] = out
	return d


## Recrée la partie depuis une photo (to_save). Retourne false si elle est illisible.
func from_save(d: Dictionary) -> bool:
	if d.is_empty() or not d.has("character"):
		return false
	start(int(d.difficulty), int(d.get("map", 1)))
	boss_plan = d.boss_plan
	set_character(_img(d.character), d.char_effect, d.char_outline)
	for k in d.weapon_art:
		var e: Dictionary = d.weapon_art[k]
		var parts: PackedStringArray = String(k).split("#")
		set_weapon_art(parts[0], int(parts[1]), _img(e.image), e.effect, _img(e.bullet), e.beffect, e.outline, e.boutline)
	for w in d.weapons:
		add_weapon(w.type, int(w.rar), int(w.price), w.anchor, int(w.rot), bool(w.flip))
	for k in d.amulet_art:
		var e: Dictionary = d.amulet_art[k]
		set_amulet_art(k, _img(e.image), e.effect, e.outline)
	for am in d.amulets:
		add_amulet(am.id, _img(am.image), am.pos)
	for m in d.marks:
		add_mark(_img(m.image), m.pos, m.outline)
	for k in d.enemy_art:
		set_enemy_art(k, _img(d.enemy_art[k].image), d.enemy_art[k].effect, d.enemy_art[k].outline)
	for k in d.elite_art:
		set_elite_art(k, _img(d.elite_art[k].image), d.elite_art[k].effect, d.elite_art[k].outline)
	for k in d.eproj_art:
		set_eproj_art(k, _img(d.eproj_art[k].image), d.eproj_art[k].effect, d.eproj_art[k].outline)
	wave = int(d.wave)
	gold = int(d.gold)
	xp = int(d.xp)
	xp_rest = float(d.xp_rest)
	level = int(d.level)
	kills = int(d.kills)
	bosses = int(d.bosses)
	signature = int(d.signature)
	bonus = d.bonus
	pending_levels = int(d.pending_levels)
	shop_offers = d.shop_offers
	rerolls = int(d.rerolls)
	joconde = int(d.get("joconde", 0))
	revived = bool(d.get("revived", false))
	levelup_choices = d.get("levelup_choices", [])
	recompute()
	hp = clampf(float(d.hp), 1.0, stats.max_hp)
	return true


static func _png(img: Image):
	return img.save_png_to_buffer() if img else null


static func _img(buf) -> Image:
	if buf == null:
		return null
	var img := Image.new()
	img.load_png_from_buffer(buf)
	img.convert(Image.FORMAT_RGBA8)
	return img


# ------------------------------------------------------------------ Progression

func xp_needed() -> int:
	return (level + 3) * (level + 3)


## Retourne le nombre de niveaux gagnés. Chaque niveau : +1 PV max et un peu d'encre.
func add_xp(n: int) -> int:
	xp_rest += n * XP_MULT * (1.0 + 0.25 * amulet_count("carnet"))
	var whole := floori(xp_rest)
	xp_rest -= whole
	xp += whole
	var gained := 0
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		gained += 1
		pending_levels += 1
	if gained > 0:
		recompute()
	return gained


## 3 bonus différents, de rareté tirée comme en boutique.
func roll_upgrades() -> Array:
	var pool := UPGRADES.duplicate()
	pool.shuffle()
	var out := []
	var n := mini(pool.size() - 1, 3 + amulet_count("encrier"))
	for i in n:
		var u: Array = pool[i]
		var rar := roll_rarity()
		var pact := randf() < PACT_CHANCE
		var v := snappedf(u[1] * UPGRADE_MULT[rar] * (2.0 if pact else 1.0), 0.5)
		var up := {"stat": u[0], "v": v, "rar": rar, "text": String(u[2]).replace("{v}", _num(v))}
		if pact:
			# Pacte : un autre attribut baisse
			var m: Array = pool[(i + 1 + randi() % (pool.size() - 1)) % pool.size()]
			if m[0] == u[0]:
				m = pool[pool.size() - 1 - i]
			var mv := -snappedf(m[1] * 1.5, 0.5)
			up.malus = [m[0], mv]
			up.pact = true
			up.text += "\n" + String(m[2]).replace("+{v}", _num(mv))
		out.append(up)
	return out


func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else str(v)


func apply_upgrade(u: Dictionary) -> void:
	bonus[u.stat] = float(bonus.get(u.stat, 0.0)) + u.v
	if u.has("malus"):
		bonus[u.malus[0]] = float(bonus.get(u.malus[0], 0.0)) + u.malus[1]
	recompute()


func add_mark(img: Image, pos: Vector2i, outline := true) -> void:
	marks.append({"image": img, "pos": pos, "a": Analyzer.analyze(img), "outline": outline})
	recompute()


func end_wave() -> void:
	signature += amulet_count("signature")
	gold += roundi(stats.harvest)
	recompute()


func pigments_earned(win: bool) -> int:
	var p := 0.0
	var cleared := wave if win else wave - 1
	for w in range(1, cleared + 1):
		p += (2.0 + (1.0 + (w - 1) * 19.0 / (WAVES - 1)) * 0.5) * 20.0 / WAVES
	p += bosses * 10.0
	if win:
		p += 30.0
	return maxi(Meta.MIN_PIGMENTS, roundi(p * diff().reward))


# ------------------------------------------------------------------ Boutique

## Tout devient plus cher au fil de la partie (×1 en vague 1, ×4.7 en vague 20).
func price_mult() -> float:
	var w := eff_wave() - 1.0
	return 1.0 + 0.12 * w + 0.004 * w * w


## Chances (en %) de [rare, épique, légendaire] pour une offre ou un bonus, selon la vague qui
## arrive. Épique : à partir de la vague 6. Légendaire : seulement sur les 5 dernières vagues
## (11 à 15). La chance avance ces paliers (2 vagues au plus) et augmente un peu les chances.
func rarity_odds() -> Array:
	var luck: float = stats.get("luck", 0.0)
	var w := float(mini(wave + 1, WAVES)) + clampf(luck / 20.0, 0.0, 2.0)
	var leg := 0.0 if w < 11.0 else 3.0 + (w - 11.0) * 2.0 + maxf(0.0, luck) * 0.05
	var epi := 0.0 if w < 6.0 else 6.0 + (w - 6.0) * 2.0 + maxf(0.0, luck) * 0.1
	var rar := maxf(2.0, 10.0 + (w - 1.0) * 2.2 + luck * 0.15)
	return [rar, epi, leg]


func roll_rarity() -> int:
	var o := rarity_odds()
	var r := randf() * 100.0
	if r < o[2]:
		return 3
	if r < o[2] + o[1]:
		return 2
	if r < o[2] + o[1] + o[0]:
		return 1
	return 0


func new_shop() -> void:
	rerolls = 0
	roll_shop()


func roll_shop() -> void:
	shop_offers = []
	var n := 4 + Meta.level("shop_slot")
	var offered := {}
	for i in n:
		var rar := roll_rarity()
		if randf() < 0.4:
			# Les armes spéciales n'apparaissent qu'à partir de leur rareté minimum.
			var type: String = WeaponDB.allowed_for(rar).pick_random()
			shop_offers.append({"type": "weapon", "wtype": type, "rar": rar,
				"price": roundi(WeaponDB.PRICE[rar] * price_mult()), "sold": false})
		else:
			# Légendaires = uniques : jamais une déjà possédée, ni deux fois la même en vitrine.
			var pool := AmuletDB.of_rarity(rar).filter(func(d): return rar < 3 or (amulet_count(d.id) == 0 and not offered.has(d.id)))
			if pool.is_empty():
				rar = 2
				pool = AmuletDB.of_rarity(2)
			var def: Dictionary = pool.pick_random()
			offered[def.id] = true
			shop_offers.append({"type": "amulet", "id": def.id, "rar": rar,
				"price": roundi(AmuletDB.PRICE[rar] * price_mult()), "sold": false})
	# Soin : pas à chaque fois !
	if randf() < 0.5:
		var hid := "grande_potion" if randf() < 0.3 else "potion"
		shop_offers.append({"type": "heal", "id": hid, "rar": 0,
			"price": roundi(HEALS[hid].price * price_mult()), "sold": false})


## Le prix de base monte avec les vagues, et chaque relance coûte plus cher
## que la précédente (remis à zéro à chaque nouvelle boutique).
func reroll_price() -> int:
	if rerolls == 0 and Meta.has("free_reroll"):
		return 0
	var base := ceili(2.0 + eff_wave() * 0.6)
	var step := ceili(1.0 + eff_wave() * 0.3)
	var n := rerolls - (1 if Meta.has("free_reroll") else 0)
	return base + maxi(0, n) * step
