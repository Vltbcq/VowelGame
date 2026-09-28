class_name WeaponDB
extends RefCounted
## Types d'armes. Chaque type se dessine UNE fois par partie : toutes les copies achetées
## ensuite réutilisent ce dessin. Le type donne le comportement, le dessin donne les stats.
##
## ink / bink : encre pour l'arme / pour ses balles. dmg, cd, reach, speed : multiplicateurs.
## scale : arme à RATIO, ses dégâts grandissent avec une stat (voir Stats.scaled_damage).

const TYPES := {
	# --- Mêlée
	"dague": {"name": "Dague", "kind": "melee", "style": "thrust", "ink": 45, "canvas": 24,
		"dmg": 0.55, "cd": 0.45, "reach": 0.75, "crit": 15.0,
		"desc": "Petits coups très rapides. +15% critique."},
	"epee": {"name": "Épée", "kind": "melee", "style": "sweep", "ink": 102, "canvas": 32,
		"dmg": 1.0, "cd": 1.0, "reach": 1.0,
		"desc": "Balaie un arc devant toi."},
	"lance": {"name": "Lance", "kind": "melee", "style": "thrust", "ink": 90, "canvas": 40,
		"dmg": 0.9, "cd": 1.05, "reach": 1.5,
		"desc": "Estoc très long qui transperce la ligne."},
	"faux": {"name": "Faux", "kind": "melee", "style": "spin", "ink": 102, "canvas": 32,
		"dmg": 0.75, "cd": 1.5, "reach": 0.9,
		"desc": "Fait un tour complet autour de toi."},
	"marteau": {"name": "Marteau", "kind": "melee", "style": "slam", "ink": 102, "canvas": 32,
		"dmg": 1.7, "cd": 1.9, "reach": 1.0,
		"desc": "Lent. Écrase le sol : onde de choc en zone."},
	# --- Distance
	"pistolet": {"name": "Pistolet", "kind": "ranged", "style": "shot", "ink": 65, "bink": 25, "canvas": 32, "bcanvas": 16,
		"dmg": 1.0, "cd": 1.0, "speed": 1.0,
		"desc": "Tir simple et fiable."},
	"tromblon": {"name": "Tromblon", "kind": "ranged", "style": "spread", "ink": 102, "bink": 14, "canvas": 32, "bcanvas": 12,
		"dmg": 0.55, "cd": 1.5, "speed": 0.9, "pellets": 3,
		"desc": "Tire ses balles en éventail (×3), courte portée."},
	"arc": {"name": "Arc", "kind": "ranged", "style": "shot", "ink": 80, "bink": 30, "canvas": 32, "bcanvas": 20,
		"dmg": 1.25, "cd": 1.35, "speed": 1.6, "pierce": 2,
		"desc": "Flèches rapides qui transpercent (+2)."},
	"baguette": {"name": "Baguette", "kind": "ranged", "style": "homing", "ink": 50, "bink": 25, "canvas": 24, "bcanvas": 16,
		"dmg": 0.8, "cd": 0.9, "speed": 0.8,
		"desc": "Projectiles à tête chercheuse."},
	"mortier": {"name": "Mortier", "kind": "ranged", "style": "lob", "ink": 102, "bink": 40, "canvas": 32, "bcanvas": 20,
		"dmg": 1.5, "cd": 1.8, "speed": 0.8,
		"desc": "Obus qui explosent en zone à l'arrivée."},
	# --- Armes à RATIO : leurs dégâts suivent une stat (toutes raretés, pas au choix de départ)
	"plume": {"name": "Plume solitaire", "kind": "ranged", "style": "shot", "ink": 60, "bink": 25, "canvas": 32, "bcanvas": 16,
		"dmg": 0.8, "cd": 1.0, "speed": 1.2, "scale": "free_slots",
		"desc": "+60% de dégâts par emplacement d'arme LIBRE. Seule, elle est redoutable."},
	"rouleau": {"name": "Rouleau à peinture", "kind": "melee", "style": "sweep", "ink": 102, "canvas": 32,
		"dmg": 0.7, "cd": 1.3, "reach": 1.2, "scale": "max_hp",
		"desc": "Balayage large. + 15% de tes PV max en dégâts."},
	"chevalet_bouclier": {"name": "Chevalet-bouclier", "kind": "melee", "style": "slam", "ink": 102, "canvas": 32,
		"dmg": 0.7, "cd": 1.5, "reach": 1.0, "scale": "armor",
		"desc": "Onde de choc. +1,5 dégât par point d'armure."},
	"aerographe": {"name": "Aérographe", "kind": "ranged", "style": "spread", "ink": 80, "bink": 14, "canvas": 32, "bcanvas": 12,
		"dmg": 0.5, "cd": 1.4, "speed": 1.0, "pellets": 3, "scale": "speed",
		"desc": "Éventail (×3). +1% de dégâts par % de vitesse de déplacement."},
	"cutter": {"name": "Cutter", "kind": "melee", "style": "thrust", "ink": 45, "canvas": 24,
		"dmg": 0.6, "cd": 0.6, "reach": 0.85, "crit": 10.0, "scale": "crit",
		"desc": "Estoc rapide. Ses critiques font ×(2 + critique ÷ 35) au lieu de ×2."},
	"compte_gouttes": {"name": "Compte-gouttes", "kind": "ranged", "style": "homing", "ink": 50, "bink": 14, "canvas": 24, "bcanvas": 12,
		"dmg": 0.6, "cd": 0.9, "speed": 0.8, "scale": "luck",
		"desc": "Gouttes chercheuses. +0,25 dégât par point de chance, et plus d'effets élémentaires."},
	"pinceau_dore": {"name": "Pinceau doré", "kind": "melee", "style": "thrust", "ink": 80, "canvas": 32,
		"dmg": 0.7, "cd": 1.0, "reach": 1.1, "scale": "gold",
		"desc": "+1 dégât par tranche de 12 or dans ta bourse. Dépenser ou garder ?"},
	"regle": {"name": "Règle graduée", "kind": "melee", "style": "thrust", "ink": 90, "canvas": 40,
		"dmg": 0.8, "cd": 1.2, "reach": 1.6, "scale": "range",
		"desc": "Estoc très long. +1,5% de dégâts par % de portée."},
	"nuancier": {"name": "Nuancier", "kind": "ranged", "style": "shot", "ink": 70, "bink": 25, "canvas": 32, "bcanvas": 16,
		"dmg": 0.6, "cd": 0.9, "speed": 1.0, "scale": "colors",
		"desc": "+35% de dégâts par COULEUR différente sur ton perso."},
	"silhouette": {"name": "Silhouette", "kind": "melee", "style": "spin", "ink": 102, "canvas": 32,
		"dmg": 0.6, "cd": 1.4, "reach": 0.95, "scale": "pixels",
		"desc": "Tour complet. Dégâts selon la TAILLE de ton perso (pixels dessinés)."},
	# --- Épiques ou plus (min_rar = 2) : très liées au dessin
	"pinceau": {"name": "Pinceau", "kind": "melee", "style": "trail", "ink": 102, "canvas": 32, "min_rar": 2,
		"dmg": 0.75, "cd": 1.0, "reach": 1.1,
		"desc": "Épique+. Balaie et laisse une traînée d'encre qui brûle les ennemis qui marchent dessus."},
	"compas": {"name": "Compas", "kind": "melee", "style": "orbit", "ink": 90, "canvas": 32, "min_rar": 2,
		"dmg": 0.45, "cd": 1.0, "reach": 1.0,
		"desc": "Épique+. Tourne sans arrêt autour de toi et découpe tout ce qu'il touche."},
	"tampon": {"name": "Tampon", "kind": "melee", "style": "stamp", "ink": 102, "canvas": 32, "min_rar": 2,
		"dmg": 1.6, "cd": 1.7, "reach": 1.0,
		"desc": "Épique+. Imprime TON DESSIN au sol (×2) : seuls les ennemis sous l'encre sont touchés, mais fort."},
	# --- Légendaires uniquement (min_rar = 3) : vraiment à part
	"gomme_sacree": {"name": "Gomme sacrée", "kind": "melee", "style": "erase", "ink": 102, "canvas": 32, "min_rar": 3,
		"dmg": 1.2, "cd": 2.2, "reach": 1.4,
		"desc": "Légendaire. Un trait de gomme en ligne droite : 30% de chances d'EFFACER net un ennemi (hors boss), sinon 25% de ses PV."},
	"palette_vivante": {"name": "Palette vivante", "kind": "ranged", "style": "prism", "ink": 102, "bink": 30, "canvas": 32, "bcanvas": 16,
		"min_rar": 3, "nobullet": true, "dmg": 0.8, "cd": 1.2, "speed": 0.9,
		"desc": "Légendaire. Tire un orbe par COULEUR de son dessin, chacun avec son effet élémentaire garanti. Pas de balles à dessiner."},
	"autoportrait": {"name": "Autoportrait", "kind": "ranged", "style": "clone", "ink": 102, "bink": 30, "canvas": 32, "bcanvas": 16,
		"min_rar": 3, "nobullet": true, "dmg": 2.4, "cd": 3.0, "speed": 0.5,
		"desc": "Légendaire. Envoie un clone de TON PERSO qui court vers l'ennemi le plus proche et explose."},
}

const PRICE := [14, 28, 50, 85]
## Plus l'offre est rare, plus on a d'encre pour dessiner l'arme (et ses balles).
## Encre selon la rareté. Avec l'encre de base plafonnée à 10 % de la toile, ça donne au plus
## 10 % / 12 % / 15 % / 20 % de la surface de la toile (commune / rare / épique / légendaire).
const RAR_INK := [1.0, 1.2, 1.5, 2.0]


static func get_def(id: String) -> Dictionary:
	return TYPES.get(id, {})


## Balle par défaut des armes sans balles à dessiner (Palette vivante, Autoportrait).
static func orb(col: Color = Pal.INK) -> Image:
	var img := Image.create_empty(7, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 7:
			var d := Vector2(x - 3, y - 3).length()
			if d <= 3.2:
				img.set_pixel(x, y, col.lightened(0.4) if d < 1.3 else col)
	return img


## Types qu'une offre de cette rareté peut proposer.
static func allowed_for(rar: int) -> Array:
	var out := []
	for id in TYPES:
		if int(TYPES[id].get("min_rar", 0)) <= rar:
			out.append(id)
	return out


## Types d'une famille (mêlée / distance). Les armes spéciales (épiques+, légendaires)
## et les armes à ratio ne sont pas proposées au choix de départ.
static func of_kind(kind: String, include_special := false) -> Array:
	var out := []
	for id in TYPES:
		var special: bool = int(TYPES[id].get("min_rar", 0)) > 0 or TYPES[id].has("scale")
		if TYPES[id].kind == kind and (include_special or not special):
			out.append(id)
	return out
