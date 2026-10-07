class_name DrawCfg
extends RefCounted
## Configurations de l'écran de dessin pour chaque type de dessin.


static func character() -> Dictionary:
	var s := 32 + Meta.canvas_bonus()
	return {"kind": "character", "gallery": "character", "size": Vector2i(s, s), "ink": Meta.base_ink(),
		"title": "Dessine ton personnage",
		"sub": "Seuls les contours coûtent de l'encre : remplir l'intérieur est gratuit.",
		"cancel": true, "min": 12}


static func weapon(type: String, rar := 0, cancel := true) -> Dictionary:
	var def := WeaponDB.get_def(type)
	var s: int = def.canvas + Meta.canvas_bonus()
	var kind: String = def.kind
	var sub := "Manche à GAUCHE, pointe à DROITE → (c'est elle qui frappe).  %s" % def.desc
	if kind == "ranged":
		sub = "Crosse à GAUCHE, canon à DROITE → (les tirs partent de là).  %s" % def.desc
	return {"kind": kind, "wtype": type, "gallery": kind, "size": Vector2i(s, s),
		"ink": roundi(def.ink * WeaponDB.RAR_INK[rar]) + Meta.weapon_ink_bonus(), "rar": rar,
		"title": "Dessine ton arme : %s" % def.name, "sub": sub + "  (Ce dessin servira pour toute la partie.)",
		"cancel": cancel, "min": 6}


static func bullet(type: String, weapon_a: Dictionary, weapon_effect: String, rar := 0) -> Dictionary:
	var def := WeaponDB.get_def(type)
	@warning_ignore("integer_division")
	var s: int = def.bcanvas + Meta.canvas_bonus() / 2
	return {"kind": "bullet", "wtype": type, "gallery": "bullet", "size": Vector2i(s, s), "ink": roundi(def.bink * WeaponDB.RAR_INK[rar]) + Meta.bullet_ink_bonus(),
		"weapon_a": weapon_a, "weapon_effect": weapon_effect,
		"title": "Dessine les projectiles : %s" % def.name,
		"sub": "Chaque morceau séparé = un projectile en plus !",
		"cancel": false, "min": 1}


static func enemy(id: String) -> Dictionary:
	var def := EnemyDB.get_def(id)
	var boss := def.has("boss")
	var title := "Nouvel ennemi : %s" % def.name
	if boss:
		title = ("BOSS : %s" if def.boss == 2 else "MINI-BOSS : %s") % def.name
	var sub := "%s  Sa couleur = son élément." % def.desc
	var min_ink := 0
	if boss:
		# Un boss doit être un vrai chef-d'œuvre : au moins 95% de l'encre.
		min_ink = ceili(def.ink * 0.95)
		sub = "Un boss doit utiliser au moins 95%% de l'encre (%d) ! Sa couleur = son élément.  %s" % [min_ink, def.desc]
	return {"kind": "boss" if boss else "enemy", "gallery": "boss" if boss else "enemy",
		"size": Vector2i(def.canvas, def.canvas), "ink": def.ink, "title": title, "sub": sub,
		"cancel": false, "min": 6, "min_ink": min_ink, "random": true}


## Version élite : on repart du dessin de l'ennemi, sur une toile un peu plus grande, et on AJOUTE.
## base : le dessin de départ (par défaut celui de l'ennemi dans la partie ; le Codex donne le sien).
static func elite(id: String, base: Image = null, base_effect := "", base_outline := false) -> Dictionary:
	var def := EnemyDB.get_def(id)
	var in_run := base == null
	if in_run:
		base = Run.enemy_art[id].image
	var base_cost := Analyzer.ink_cost(base)
	var ink := maxi(roundi(def.ink * 1.4), base_cost + 30)
	var s: int = def.canvas + 8
	return {"kind": "enemy", "gallery": "enemy", "size": Vector2i(s, s), "ink": ink, "base": base,
		"effect": Run.enemy_art[id].effect if in_run else base_effect,
		"outline": Run.enemy_art[id].get("outline", false) if in_run else base_outline,
		"title": "ÉLITE : %s" % def.name,
		"sub": "Complète ton dessin : c'est sa version élite (aura, PV ×3, butin ×3). Ajoute au moins 15 d'encre.",
		"cancel": false, "min": 6, "min_ink": base_cost + 15, "random": false}


static func eproj(id: String) -> Dictionary:
	var def := EnemyDB.get_def(id)
	return {"kind": "eproj", "gallery": "eproj", "size": Vector2i(12, 12), "ink": 40,
		"title": "Dessine les projectiles de : %s" % def.name,
		"sub": "Sa couleur = son élément.",
		"cancel": false, "min": 1, "random": true}


static func familiar(def: Dictionary) -> Dictionary:
	var s := FamiliarDB.canvas(def)
	return {"kind": "familiar", "gallery": "familiar", "size": Vector2i(s, s), "ink": FamiliarDB.ink(def),
		"def": def, "title": "Dessine ton familier : %s" % def.name,
		"sub": String(def.desc),
		"cancel": true, "min": 4}


static func amulet(def: Dictionary) -> Dictionary:
	@warning_ignore("integer_division")
	var s := AmuletDB.canvas(def) + Meta.canvas_bonus() / 2   # Grande toile : +4 px par niveau
	return {"kind": "amulet", "gallery": "amulet", "size": Vector2i(s, s), "ink": AmuletDB.ink(def) + Meta.amulet_ink_bonus(),
		"def": def, "title": "Dessine l'amulette : %s" % def.name,
		"sub": AmuletDB.describe(def) + "  Ce dessin servira pour toute la partie.",
		"cancel": true, "min": 3}


## Marque d'encre dessinée en montant de niveau (petite, ne compte pas dans la taille).
## Plus le bonus est rare, plus la marque peut être grande.
const MARK_INK := [10, 16, 24, 34]
const MARK_SIZE := [14, 16, 20, 24]


static func mark(u: Dictionary) -> Dictionary:
	var s: int = MARK_SIZE[u.rar]
	return {"kind": "mark", "gallery": "mark", "size": Vector2i(s, s), "ink": MARK_INK[u.rar], "upgrade": u,
		"title": "Dessine ta marque : %s" % u.text,
		"sub": "Tatouage, cicatrice, peinture de guerre... Elle s'ajoute sur ton perso sans compter dans sa taille.",
		"cancel": true, "cancel_label": "Passer", "min": 1, "random": true}
