class_name UnlockDB
extends RefCounted
## Déblocages permanents. Encre et Boutique : achetés avec les pigments ("cost").
## Couleurs, Outils et Effets : débloqués par un SUCCÈS (voir AchievementDB, "unlock").

const LIST := [
	{"id": "pack_primaires", "cat": "Couleurs", "name": "Pack primaire", "cost": [12],
		"desc": "Rouge (Feu), Bleu (Glace), Jaune (Foudre). Chaque couleur donne une résistance et un effet d'arme."},
	{"id": "pack_secondaires", "cat": "Couleurs", "name": "Pack secondaire", "cost": [55],
		"desc": "Vert (Poison), Violet (Arcane), Blanc (Lumière). Nécessite le pack primaire.", "req": "pack_primaires"},
	{"id": "ink", "cat": "Encre", "name": "Encrier", "cost": [20, 35, 55, 80, 110],
		"desc": "+25 encre pour ton perso, +10 pour tes armes."},
	{"id": "canvas", "cat": "Encre", "name": "Grande toile", "cost": [40, 90, 150],
		"desc": "+8 pixels de côté sur les toiles du perso et des armes."},
	{"id": "tool_big", "cat": "Outils", "name": "Gros pinceaux", "cost": [15],
		"desc": "Pinceaux de 2 et 3 pixels."},
	{"id": "tool_line", "cat": "Outils", "name": "Ligne", "cost": [15], "desc": "Trace des lignes droites."},
	{"id": "tool_rect", "cat": "Outils", "name": "Rectangle", "cost": [20], "desc": "Trace des rectangles."},
	{"id": "tool_ellipse", "cat": "Outils", "name": "Ellipse", "cost": [25], "desc": "Trace des cercles et ellipses."},
	{"id": "tool_mirror", "cat": "Outils", "name": "Symétrie", "cost": [35],
		"desc": "Dessine en miroir. Un perso symétrique esquive mieux !"},
	{"id": "gradient", "cat": "Effets", "name": "Dégradé", "cost": [50],
		"desc": "Le pinceau passe d'une couleur à l'autre. Les mélanges créent d'autres éléments."},
	{"id": "fx_pulse", "cat": "Effets", "name": "Encre pulsante", "cost": [40],
		"desc": "Effet animé : +10% vit. d'attaque (coûte 15% de l'encre)."},
	{"id": "fx_shimmer", "cat": "Effets", "name": "Encre scintillante", "cost": [60],
		"desc": "Effet animé : +critique et +esquive (coûte 15% de l'encre)."},
	{"id": "fx_rainbow", "cat": "Effets", "name": "Encre arc-en-ciel", "cost": [90],
		"desc": "Effet animé : compte un peu comme chaque élément (coûte 15% de l'encre)."},
	{"id": "shop_slot", "cat": "Boutique", "name": "Étal élargi", "cost": [60], "desc": "+1 offre dans la boutique."},
	{"id": "free_reroll", "cat": "Boutique", "name": "Relance offerte", "cost": [45], "desc": "Première relance gratuite à chaque boutique."},
	{"id": "start_gold", "cat": "Boutique", "name": "Bourse", "cost": [20, 40, 60], "desc": "+10 or au début de la partie."},
]


## Amélioration achetable avec des pigments (sinon : succès).
static func for_pigments(d: Dictionary) -> bool:
	return d.cat in ["Encre", "Boutique"]


## Le succès qui débloque cette amélioration ({} si elle s'achète).
static func achievement_for(id: String) -> Dictionary:
	for a in AchievementDB.LIST:
		if a.unlock == id:
			return a
	return {}


static func get_def(id: String) -> Dictionary:
	for d in LIST:
		if d.id == id:
			return d
	return {}
