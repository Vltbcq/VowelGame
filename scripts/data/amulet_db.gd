class_name AmuletDB
extends RefCounted
## Catalogue des amulettes (passifs). La valeur "v" est multipliée par la taille du dessin
## (magnitude de 0.5 à 1.5 selon l'encre utilisée). Les amulettes "flag" ont des effets spéciaux.
## Chaque amulette a sa propre quantité d'encre, et se dessine une seule fois par partie.

## Toutes les amulettes ont un malus intégré : aucune n'est un bonus gratuit.
## Les LÉGENDAIRES sont uniques : une seule par partie (plus proposées une fois achetées).
## "malus" = [stat, valeur] (fixe, ne dépend pas du dessin).
const LIST := [
	# Communes
	{"id": "plume", "ink": 20, "name": "Plume", "rar": 0, "stat": "speed", "v": 8.0, "desc": "+{v}% vitesse · {m} armure", "malus": ["armor", -1.0]},
	{"id": "coeur", "ink": 45, "name": "Cœur d'encre", "rar": 0, "stat": "max_hp", "v": 5.0, "desc": "+{v} PV max · {m}% vitesse", "malus": ["speed", -4.0]},
	{"id": "bouclier", "ink": 50, "name": "Écu", "rar": 0, "stat": "armor", "v": 2.0, "desc": "+{v} armure · {m}% vit. d'attaque", "malus": ["atk_speed", -5.0]},
	{"id": "sablier", "ink": 30, "name": "Sablier", "rar": 0, "stat": "atk_speed", "v": 8.0, "desc": "+{v}% vit. d'attaque · {m}% dégâts", "malus": ["dmg", -4.0]},
	{"id": "oeil", "ink": 16, "name": "Œil", "rar": 0, "stat": "crit", "v": 4.0, "desc": "+{v}% critique · {m} PV max", "malus": ["max_hp", -2.0]},
	{"id": "crochet", "ink": 25, "name": "Crochet", "rar": 0, "stat": "range", "v": 12.0, "desc": "+{v}% portée · {m}% vit. d'attaque", "malus": ["atk_speed", -4.0]},
	{"id": "aimant", "ink": 35, "name": "Aimant", "rar": 0, "stat": "pickup", "v": 40.0, "desc": "+{v} ramassage · {m}% dégâts", "malus": ["dmg", -3.0]},
	{"id": "piece", "ink": 14, "name": "Pièce", "rar": 0, "stat": "harvest", "v": 5.0, "desc": "+{v} pourboire (or à chaque fin de vague) · {m} chance", "malus": ["luck", -4.0]},
	{"id": "tampon", "ink": 40, "name": "Tampon", "rar": 0, "stat": "armor", "v": 4.0, "desc": "+{v} armure · {m}% vitesse", "malus": ["speed", -8.0]},
	{"id": "taille_crayon", "ink": 18, "name": "Taille-crayon", "rar": 0, "stat": "crit", "v": 7.0, "desc": "+{v}% critique · {m}% portée", "malus": ["range", -8.0]},
	{"id": "buvard", "ink": 30, "name": "Buvard", "rar": 0, "stat": "pickup", "v": 60.0, "desc": "+{v} ramassage · {m} armure", "malus": ["armor", -1.0]},
	{"id": "gouache", "ink": 40, "name": "Gouache", "rar": 0, "stat": "max_hp", "v": 7.0, "desc": "+{v} PV max · {m}% esquive", "malus": ["dodge", -4.0]},
	{"id": "fixatif", "ink": 28, "name": "Fixatif", "rar": 0, "stat": "regen", "v": 2.0, "desc": "+{v} régénération · {m}% dégâts", "malus": ["dmg", -4.0]},
	{"id": "chevalet", "ink": 44, "name": "Chevalet", "rar": 0, "stat": "dmg", "v": 9.0, "desc": "+{v}% dégâts · {m}% vitesse", "malus": ["speed", -7.0]},
	{"id": "fusain", "ink": 22, "name": "Fusain", "rar": 0, "stat": "atk_speed", "v": 12.0, "desc": "+{v}% vit. d'attaque · {m} PV max", "malus": ["max_hp", -3.0]},
	# Rares
	{"id": "sangsue", "ink": 30, "name": "Sangsue", "rar": 1, "stat": "lifesteal", "v": 4.0, "desc": "+{v}% vol de vie · {m} régénération", "malus": ["regen", -1.0]},
	{"id": "trefle", "ink": 24, "name": "Trèfle", "rar": 1, "stat": "luck", "v": 12.0, "desc": "+{v} chance · {m}% dégâts", "malus": ["dmg", -3.0]},
	{"id": "epine", "ink": 42, "name": "Épine", "rar": 1, "stat": "thorns", "v": 5.0, "desc": "Renvoie {v} dégâts au contact · {m}% esquive", "malus": ["dodge", -3.0]},
	{"id": "rune", "ink": 36, "name": "Rune", "rar": 1, "stat": "el_power", "v": 25.0, "desc": "+{v}% effets élémentaires · {m}% critique", "malus": ["crit", -2.0]},
	{"id": "lame", "ink": 34, "name": "Lame", "rar": 1, "stat": "dmg", "v": 12.0, "desc": "+{v}% dégâts · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "mousse", "ink": 52, "name": "Mousse", "rar": 1, "stat": "regen", "v": 3.0, "desc": "+{v} régénération · {m}% vitesse", "malus": ["speed", -5.0]},
	{"id": "gomme", "ink": 30, "name": "Gomme", "rar": 1, "stat": "dodge", "v": 8.0, "desc": "+{v}% esquive · {m} PV max", "malus": ["max_hp", -5.0]},
	{"id": "loupe", "ink": 38, "name": "Loupe", "rar": 1, "stat": "range", "v": 25.0, "desc": "+{v}% portée · {m}% dégâts", "malus": ["dmg", -6.0]},
	{"id": "calque", "ink": 30, "name": "Calque", "rar": 1, "flag": true, "desc": "Tes projectiles transpercent +1 ennemi · {m}% dégâts", "malus": ["dmg", -6.0]},
	{"id": "estompe", "ink": 34, "name": "Estompe", "rar": 1, "flag": true, "desc": "Chaque coup ralentit l'ennemi · {m}% vit. d'attaque", "malus": ["atk_speed", -6.0]},
	{"id": "mine_plomb", "ink": 26, "name": "Mine de plomb", "rar": 1, "stat": "crit_mult", "v": 0.4, "desc": "Critiques +{v} (×2 → ×2,4) · {m} chance", "malus": ["luck", -5.0]},
	{"id": "sanguine", "ink": 36, "name": "Sanguine", "rar": 1, "flag": true, "desc": "12% de chances qu'un ennemi tué te soigne 1 PV · {m} PV max", "malus": ["max_hp", -4.0]},
	{"id": "craquelure", "ink": 40, "name": "Craquelure", "rar": 1, "flag": true, "desc": "Tes coups critiques explosent autour de l'ennemi · {m}% critique", "malus": ["crit", -4.0]},
	{"id": "mecene", "ink": 32, "name": "Mécène", "rar": 1, "stat": "harvest", "v": 9.0, "desc": "+{v} pourboire (or à chaque fin de vague) · {m}% dégâts", "malus": ["dmg", -5.0]},
	{"id": "carnet", "ink": 44, "name": "Carnet de croquis", "rar": 1, "flag": true, "desc": "+25% d'expérience · {m} armure", "malus": ["armor", -3.0]},
	# Épiques (cassables)
	{"id": "palette", "ink": 60, "name": "Palette", "rar": 2, "flag": true, "desc": "+8% dégâts par couleur de ton perso · {m} armure", "malus": ["armor", -4.0]},
	{"id": "esquisse", "ink": 18, "name": "Esquisse", "rar": 2, "flag": true, "desc": "Perso < 120 pixels : +40% dégâts, +20% vitesse · {m} PV max", "malus": ["max_hp", -4.0]},
	{"id": "poids", "ink": 80, "name": "Poids", "rar": 2, "flag": true, "desc": "+1 armure par 60 pixels de ton perso · {m}% vitesse", "malus": ["speed", -10.0]},
	{"id": "miroir", "ink": 44, "name": "Miroir", "rar": 2, "flag": true, "desc": "Tes armes à distance tirent une rafale de plus · {m}% dégâts", "malus": ["dmg", -12.0]},
	{"id": "rature", "ink": 36, "name": "Rature", "rar": 2, "flag": true, "desc": "8% de chances qu'un ennemi tué explose · {m} PV max", "malus": ["max_hp", -4.0]},
	{"id": "signature", "ink": 28, "name": "Signature", "rar": 2, "flag": true, "desc": "+3% dégâts par vague survécue après l'achat · {m}% vit. d'attaque", "malus": ["atk_speed", -10.0]},
	{"id": "pinceau_fou", "ink": 40, "name": "Pinceau fou", "rar": 2, "flag": true, "desc": "+40% vit. d'attaque, mais tes armes visent au hasard"},
	{"id": "vernis", "ink": 50, "name": "Vernis", "rar": 2, "flag": true, "desc": "+35% dégâts contre boss et élites, mais -15% contre les autres"},
	{"id": "cadre_dore", "ink": 60, "name": "Cadre doré", "rar": 2, "flag": true, "desc": "+1% dégâts par tranche de 5 or dans ta bourse (max +40%) · {m}% vitesse", "malus": ["speed", -8.0]},
	{"id": "collage", "ink": 52, "name": "Collage", "rar": 2, "flag": true, "desc": "+8% dégâts par TYPE d'arme différent · {m} armure", "malus": ["armor", -3.0]},
	{"id": "croquis_rapide", "ink": 40, "name": "Croquis rapide", "rar": 2, "flag": true, "desc": "+60% vit. d'attaque pendant les 10 premières secondes de chaque vague · {m}% dégâts", "malus": ["dmg", -5.0]},
	{"id": "tache", "ink": 30, "name": "Tache indélébile", "rar": 2, "stat": "dmg", "v": 40.0, "flag": true, "desc": "+{v}% dégâts, mais une grosse tache noire s'ajoute à ton perso (plus gros, plus lent)"},
	{"id": "perspective", "ink": 48, "name": "Perspective", "rar": 2, "flag": true, "desc": "+30% portée. Ennemis loin de toi : +25% dégâts, proches : -25%"},
	{"id": "sceau", "ink": 58, "name": "Sceau d'encre", "rar": 2, "stat": "dmg", "v": 25.0, "desc": "+{v}% dégâts · {m} régénération", "malus": ["regen", -3.0]},
	# Légendaires
	{"id": "chef_oeuvre", "ink": 100, "name": "Chef-d'œuvre", "rar": 3, "flag": true, "desc": "Les stats du dessin de ton perso ×1.5 · {m}% vitesse", "malus": ["speed", -10.0]},
	{"id": "double_trait", "ink": 64, "name": "Double trait", "rar": 3, "flag": true, "desc": "Tes armes de mêlée lancent aussi leur dessin · {m} armure", "malus": ["armor", -3.0]},
	{"id": "arc_en_ciel", "ink": 72, "name": "Prisme", "rar": 3, "flag": true, "desc": "+15% de chaque effet élémentaire sur tes armes · {m}% critique", "malus": ["crit", -8.0]},
	{"id": "encrier", "ink": 56, "name": "Encrier sans fond", "rar": 3, "flag": true, "desc": "+1 choix de bonus à chaque niveau, mais -15% PV max"},
	{"id": "joconde", "ink": 90, "name": "La Joconde", "rar": 3, "flag": true, "desc": "Chaque vague finie sans perdre de PV : +12% dégâts pour la partie · {m} PV max", "malus": ["max_hp", -5.0]},
	{"id": "double_expo", "ink": 70, "name": "Double exposition", "rar": 3, "flag": true, "desc": "Chaque attaque a 25% de chances de se relancer aussitôt · {m}% critique", "malus": ["crit", -6.0]},
	{"id": "musee", "ink": 80, "name": "Musée ambulant", "rar": 3, "flag": true, "desc": "+1 emplacement d'arme (7 au lieu de 6) · {m}% dégâts", "malus": ["dmg", -8.0]},
	{"id": "trompe_oeil", "ink": 66, "name": "Trompe-l'œil", "rar": 3, "flag": true, "desc": "30% des tirs ennemis sont déviés · {m} armure", "malus": ["armor", -4.0]},
	{"id": "restauration", "ink": 76, "name": "Restauration", "rar": 3, "flag": true, "desc": "Soigne 30% de tes PV au début de chaque vague, mais -15% d'or ramassé"},
	{"id": "renaissance", "ink": 84, "name": "Renaissance", "rar": 3, "flag": true, "desc": "Une fois par partie, à 0 PV tu reviens avec 50% de tes PV · {m}% vitesse", "malus": ["speed", -10.0]},
	{"id": "horloge", "ink": 76, "name": "Horloge", "rar": 3, "flag": true, "desc": "Toutes les 12 s, le TEMPS S'ARRÊTE 2 s : ennemis et tirs figés, tes armes font ×2 · {m} PV max", "malus": ["max_hp", -6.0]},
	{"id": "sablier_brise", "ink": 70, "name": "Sablier brisé", "rar": 3, "stat": "atk_speed", "v": 45.0, "flag": true, "desc": "+{v}% vit. d'attaque, mais les vagues durent 25% plus longtemps"},
]

## Bonus selon l'endroit où l'amulette est posée sur le perso.
const ZONES := {
	"Tête": {"stat": "crit", "v": 3.0, "desc": "+3% critique"},
	"Cœur": {"stat": "max_hp", "v": 3.0, "desc": "+3 PV max"},
	"Mains": {"stat": "atk_speed", "v": 5.0, "desc": "+5% vit. d'attaque"},
	"Pieds": {"stat": "speed", "v": 5.0, "desc": "+5% vitesse"},
	"Aura": {"stat": "pickup", "v": 30.0, "desc": "+30 ramassage, flotte autour de toi"},
}

const PRICE := [10, 22, 40, 70]


## Plus l'amulette est rare, plus on a d'encre pour la dessiner.
const RAR_INK := [1.0, 1.3, 1.6, 2.0]


static func ink(def: Dictionary) -> int:
	return roundi(def.ink * RAR_INK[def.rar])


## Taille de toile selon l'encre de l'amulette.
static func canvas(def: Dictionary) -> int:
	var i := ink(def)
	if i <= 30:
		return 16
	if i <= 50:
		return 20
	if i <= 80:
		return 24
	if i <= 120:
		return 28
	return 32


static func get_def(id: String) -> Dictionary:
	for d in LIST:
		if d.id == id:
			return d
	return {}


static func of_rarity(rar: int) -> Array:
	return LIST.filter(func(d): return d.rar == rar)


static func describe(def: Dictionary, mag := 1.0) -> String:
	var s: String = def.desc
	if def.has("malus"):
		var mv: float = def.malus[1]
		s = s.replace("{m}", str(int(mv)) if is_equal_approx(mv, roundf(mv)) else str(mv))
	if def.has("v"):
		var v := snappedf(def.v * mag, 0.1)
		s = s.replace("{v}", str(int(v)) if is_equal_approx(v, roundf(v)) else str(v))
	if int(def.rar) == 3:
		s += " · UNIQUE"
	return s
