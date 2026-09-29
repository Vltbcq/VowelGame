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
	{"id": "piece", "ink": 14, "name": "Pièce", "rar": 0, "stat": "harvest", "v": 5.0, "desc": "+{v} pourboire (or à chaque fin de vague) · {m} chance", "malus": ["luck", -4.0]},
	{"id": "tampon", "ink": 40, "name": "Tampon", "rar": 0, "stat": "armor", "v": 4.0, "desc": "+{v} armure · {m}% vitesse", "malus": ["speed", -8.0]},
	{"id": "taille_crayon", "ink": 18, "name": "Taille-crayon", "rar": 0, "stat": "crit", "v": 7.0, "desc": "+{v}% critique · {m}% portée", "malus": ["range", -8.0]},
	{"id": "gouache", "ink": 40, "name": "Gouache", "rar": 0, "stat": "max_hp", "v": 7.0, "desc": "+{v} PV max · {m}% esquive", "malus": ["dodge", -4.0]},
	{"id": "fixatif", "ink": 28, "name": "Fixatif", "rar": 0, "stat": "regen", "v": 2.0, "desc": "+{v} régénération · {m}% dégâts", "malus": ["dmg", -4.0]},
	{"id": "chevalet", "ink": 44, "name": "Chevalet", "rar": 0, "stat": "dmg", "v": 9.0, "desc": "+{v}% dégâts · {m}% vitesse", "malus": ["speed", -7.0]},
	{"id": "pastel", "ink": 20, "name": "Pastel", "rar": 0, "stat": "dodge", "v": 6.0, "desc": "+{v}% esquive · {m} armure", "malus": ["armor", -1.0]},
	{"id": "craie_grasse", "ink": 18, "name": "Craie grasse", "rar": 0, "stat": "regen", "v": 2.0, "desc": "+{v} régénération · {m} chance", "malus": ["luck", -4.0]},
	{"id": "papier_kraft", "ink": 24, "name": "Papier kraft", "rar": 0, "stat": "armor", "v": 2.0, "desc": "+{v} armure · {m}% critique", "malus": ["crit", -4.0]},
	{"id": "colle", "ink": 20, "name": "Colle", "rar": 0, "stat": "lifesteal", "v": 3.0, "desc": "+{v}% vol de vie · {m}% vitesse", "malus": ["speed", -5.0]},
	{"id": "spatule", "ink": 24, "name": "Spatule", "rar": 0, "flag": true, "desc": "+12% dégâts de MÊLÉE · -8% dégâts à distance"},
	{"id": "viseur", "ink": 24, "name": "Viseur", "rar": 0, "flag": true, "desc": "+12% dégâts À DISTANCE · -8% dégâts de mêlée"},
	{"id": "tube_peinture", "ink": 30, "name": "Tube de peinture", "rar": 0, "stat": "max_hp", "v": 6.0, "desc": "+{v} PV max · {m}% critique", "malus": ["crit", -3.0]},
	{"id": "chiffon", "ink": 22, "name": "Chiffon", "rar": 0, "stat": "dodge", "v": 5.0, "desc": "+{v}% esquive · {m}% dégâts", "malus": ["dmg", -3.0]},
	{"id": "metre_ruban", "ink": 22, "name": "Mètre ruban", "rar": 0, "stat": "range", "v": 12.0, "desc": "+{v}% portée · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "encre_sympathique", "ink": 20, "name": "Encre sympathique", "rar": 0, "stat": "luck", "v": 8.0, "desc": "+{v} chance · {m} armure", "malus": ["armor", -1.0]},
	{"id": "godet", "ink": 24, "name": "Godet", "rar": 0, "stat": "el_power", "v": 15.0, "desc": "+{v}% puissance élémentaire · {m}% vit. d'attaque", "malus": ["atk_speed", -5.0]},
	{"id": "etiquette_prix", "ink": 16, "name": "Étiquette de prix", "rar": 0, "flag": true, "limit": 5, "desc": "Les œuvres de la boutique coûtent 8% moins cher (5 max) · {m}% dégâts", "malus": ["dmg", -3.0]},
	{"id": "timbre", "ink": 16, "name": "Timbre", "rar": 0, "stat": "thorns", "v": 2.0, "desc": "+{v} épines · {m}% vitesse", "malus": ["speed", -4.0]},
	{"id": "gommette", "ink": 14, "name": "Gommette", "rar": 0, "flag": true, "desc": "+10% d'expérience · {m} armure", "malus": ["armor", -2.0]},
	{"id": "porte_mine", "ink": 18, "name": "Porte-mine", "rar": 0, "stat": "crit", "v": 5.0, "desc": "+{v}% critique · {m} régénération", "malus": ["regen", -1.0]},
	{"id": "encre_rouge", "ink": 18, "name": "Encre rouge", "rar": 0, "stat": "lifesteal", "v": 2.0, "desc": "+{v}% vol de vie · {m} armure", "malus": ["armor", -1.0]},
	{"id": "petard", "ink": 20, "name": "Pétard", "rar": 0, "flag": true, "desc": "+25% dégâts des explosions (Marteau, Mortier, éclats de Lumière, Rature...) · {m}% vit. d'attaque", "malus": ["atk_speed", -4.0]},
	{"id": "capital", "ink": 36, "name": "Le Capital", "rar": 2, "flag": true, "limit": 1, "desc": "Toutes les armes et amulettes de la boutique coûtent le PRIX MOYEN de la vague (il coûte lui-même ce prix) · achat unique"},
	{"id": "case_opening", "ink": 34, "name": "Case opening", "rar": 2, "flag": true, "limit": 1, "desc": "La boutique ne vend plus que des CAISSES (Bois, Argent, Or ; armes ou amulettes), 20% moins chères que leur contenu · achat unique"},
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
	{"id": "aimant_pepites", "ink": 30, "name": "Aimant à pépites", "rar": 1, "flag": true, "desc": "+15% d'or ramassé · {m} PV max", "malus": ["max_hp", -4.0]},
	{"id": "crayon_couleur", "ink": 28, "name": "Crayon de couleur", "rar": 1, "flag": true, "desc": "10% de chances par coup d'appliquer l'élément de ton perso · {m}% dégâts", "malus": ["dmg", -4.0]},
	{"id": "ombre_portee", "ink": 34, "name": "Ombre portée", "rar": 1, "flag": true, "desc": "Après une esquive, ton prochain coup fait ×2 · {m} armure", "malus": ["armor", -1.0]},
	{"id": "pansement", "ink": 26, "name": "Pansement", "rar": 1, "flag": true, "desc": "Soigne 5 PV à chaque montée de niveau · {m}% vitesse", "malus": ["speed", -3.0]},
	{"id": "cadran_solaire", "ink": 36, "name": "Cadran solaire", "rar": 1, "flag": true, "desc": "+20% dégâts pendant la 2e moitié de chaque vague, -5% la 1re moitié"},
	{"id": "taille_douce", "ink": 34, "name": "Taille-douce", "rar": 1, "flag": true, "desc": "+1% critique par tranche de 3 armure · {m}% vitesse", "malus": ["speed", -5.0]},
	{"id": "encre_invisible", "ink": 30, "name": "Encre invisible", "rar": 1, "flag": true, "desc": "Après un coup reçu, les ennemis te perdent de vue 1 s · {m}% dégâts", "malus": ["dmg", -4.0]},
	{"id": "papier_verre", "ink": 32, "name": "Papier de verre", "rar": 1, "flag": true, "desc": "+3% dégâts par ennemi proche (max +30%) · {m} armure", "malus": ["armor", -1.0]},
	{"id": "bulle_soin", "ink": 30, "name": "Bulle de soin", "rar": 1, "flag": true, "desc": "Les ennemis tués ont 8% de chances de lâcher une goutte de soin · {m}% dégâts", "malus": ["dmg", -5.0]},
	{"id": "elastique", "ink": 26, "name": "Élastique", "rar": 1, "flag": true, "desc": "Tes projectiles rebondissent 1 fois sur les bords · {m}% dégâts", "malus": ["dmg", -5.0]},
	{"id": "correcteur", "ink": 28, "name": "Correcteur", "rar": 1, "flag": true, "desc": "Insensible aux flaques d'encre ennemies · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "cachet_cire", "ink": 32, "name": "Cachet de cire", "rar": 1, "flag": true, "desc": "Les élites lâchent ×2 d'or · {m} chance", "malus": ["luck", -4.0]},
	{"id": "encre_carmin", "ink": 32, "name": "Encre carmin", "rar": 1, "flag": true, "desc": "Le soin du vol de vie EN TROP devient un bouclier d'encre (jusqu'à 20% PV max) · {m}% dégâts", "malus": ["dmg", -3.0]},
	{"id": "carapace", "ink": 36, "name": "Carapace", "rar": 1, "flag": true, "desc": "Épines +25% de ton armure · {m}% vitesse", "malus": ["speed", -4.0]},
	{"id": "oursin", "ink": 30, "name": "Oursin", "rar": 1, "flag": true, "desc": "Touché : tu lances 6 épines d'encre tout autour (dégâts = épines ×2, min 4) · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "allumette", "ink": 18, "name": "Allumette", "rar": 1, "flag": true, "desc": "FEU : les brûlures durent 2× plus longtemps · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "givre", "ink": 26, "name": "Givre", "rar": 1, "flag": true, "desc": "GLACE : 2 coups de Glace suffisent pour geler (au lieu de 3) · {m}% vitesse", "malus": ["speed", -5.0]},
	{"id": "paratonnerre", "ink": 28, "name": "Paratonnerre", "rar": 1, "flag": true, "desc": "FOUDRE : +2 cibles par chaîne d'éclairs · {m}% dégâts", "malus": ["dmg", -4.0]},
	{"id": "fiole", "ink": 24, "name": "Fiole", "rar": 1, "flag": true, "desc": "POISON : chaque effet Poison met 2 cumuls au lieu d'1 · {m}% dégâts", "malus": ["dmg", -3.0]},
	{"id": "grimoire", "ink": 34, "name": "Grimoire", "rar": 1, "flag": true, "desc": "ARCANE : les marques durent 2× plus longtemps et font +15% de plus · {m}% vitesse", "malus": ["speed", -4.0]},
	{"id": "vitrail", "ink": 34, "name": "Vitrail", "rar": 1, "flag": true, "desc": "LUMIÈRE : les éclats ont +50% de rayon · {m}% dégâts", "malus": ["dmg", -4.0]},
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
	{"id": "tache", "ink": 30, "name": "Tache indélébile", "rar": 2, "stat": "dmg", "v": 20.0, "flag": true, "desc": "+{v}% dégâts, +2 armure, +5 PV max · -20% vitesse (une grosse tache noire s'ajoute à ton perso)"},
	{"id": "perspective", "ink": 48, "name": "Perspective", "rar": 2, "flag": true, "desc": "+30% portée. Ennemis loin de toi : +25% dégâts, proches : -25%"},
	{"id": "kaleidoscope", "ink": 50, "name": "Kaléidoscope", "rar": 2, "flag": true, "desc": "Tes coups font défiler les couleurs : 20% de chances d'appliquer l'élément suivant du cycle · {m}% dégâts", "malus": ["dmg", -5.0]},
	{"id": "lanterne", "ink": 54, "name": "Lanterne magique", "rar": 2, "flag": true, "desc": "Toutes les 15 s, un LEURRE de ton perso attire les ennemis 3 s · {m} PV max", "malus": ["max_hp", -4.0]},
	{"id": "ressort", "ink": 40, "name": "Ressort", "rar": 2, "flag": true, "desc": "Armes de mêlée : +30% portée et recul ×2 · {m}% vit. d'attaque", "malus": ["atk_speed", -8.0]},
	{"id": "metronome", "ink": 46, "name": "Métronome", "rar": 2, "flag": true, "desc": "Une attaque sur 5 de chaque arme fait ×2,5 · {m}% vit. d'attaque", "malus": ["atk_speed", -8.0]},
	{"id": "pierre_aiguiser", "ink": 44, "name": "Pierre à aiguiser", "rar": 2, "flag": true, "desc": "+1 dégât par coup par rang de rareté de l'arme (légendaire +3) · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "boussole", "ink": 40, "name": "Boussole", "rar": 2, "flag": true, "desc": "Tous tes projectiles deviennent un peu chercheurs · {m}% portée", "malus": ["range", -10.0]},
	{"id": "papillon", "ink": 42, "name": "Effet papillon", "rar": 2, "flag": true, "desc": "Chaque critique : +3% vit. d'attaque pendant 3 s (jusqu'à ×10) · {m}% critique", "malus": ["crit", -4.0]},
	{"id": "encre_seiche", "ink": 48, "name": "Encre de seiche", "rar": 2, "flag": true, "desc": "Touché : un nuage d'encre aveugle les ennemis proches 2 s (recharge 15 s) · {m} armure", "malus": ["armor", -1.0]},
	{"id": "echelle", "ink": 44, "name": "Échelle", "rar": 2, "flag": true, "desc": "+2% dégâts par niveau atteint · {m} PV max", "malus": ["max_hp", -4.0]},
	{"id": "accordeon", "ink": 46, "name": "Accordéon", "rar": 2, "flag": true, "desc": "+0,5% vit. d'attaque par % de vitesse de déplacement · {m} armure", "malus": ["armor", -3.0]},
	{"id": "bouclier_papier", "ink": 40, "name": "Bouclier de papier", "rar": 2, "flag": true, "desc": "Le 1er coup reçu de chaque vague est ignoré · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "calice", "ink": 50, "name": "Calice", "rar": 2, "flag": true, "desc": "Le vol de vie soigne 2% des dégâts du coup au lieu d'1 PV (au moins 1) · {m} PV max", "malus": ["max_hp", -5.0]},
	{"id": "chauve_souris", "ink": 44, "name": "Chauve-souris", "rar": 2, "flag": true, "desc": "+1% dégâts par PV soigné ces 5 dernières secondes (max +30%) · {m}% vitesse", "malus": ["speed", -4.0]},
	{"id": "cactus", "ink": 46, "name": "Cactus", "rar": 2, "flag": true, "desc": "+1 épine par tranche de 10 PV max · {m}% vitesse", "malus": ["speed", -8.0]},
	{"id": "ronces", "ink": 50, "name": "Ronces", "rar": 2, "flag": true, "desc": "Un ennemi qui te frappe est repoussé et prend un cumul de poison · {m}% dégâts", "malus": ["dmg", -5.0]},
	{"id": "braise", "ink": 40, "name": "Braise", "rar": 2, "flag": true, "desc": "FEU : un ennemi qui meurt en brûlant explose et enflamme ses voisins · {m} armure", "malus": ["armor", -1.0]},
	{"id": "stalactite", "ink": 44, "name": "Stalactite", "rar": 2, "flag": true, "desc": "GLACE : les ennemis gelés prennent ×1,5 dégâts · {m}% vit. d'attaque", "malus": ["atk_speed", -5.0]},
	{"id": "dynamo", "ink": 42, "name": "Dynamo", "rar": 2, "flag": true, "desc": "FOUDRE : +2% vit. d'attaque par chaîne d'éclairs ces 5 dernières secondes (max +40%) · {m} PV max", "malus": ["max_hp", -3.0]},
	{"id": "champignon", "ink": 48, "name": "Champignon", "rar": 2, "flag": true, "desc": "POISON : un ennemi à 6 cumuls éclate en nuage toxique qui contamine ses voisins · {m} PV max", "malus": ["max_hp", -4.0]},
	{"id": "pentacle", "ink": 46, "name": "Pentacle", "rar": 2, "flag": true, "desc": "ARCANE : tuer un ennemi marqué te soigne 2 PV et transfère la marque à son voisin · {m} armure", "malus": ["armor", -1.0]},
	{"id": "aureole", "ink": 44, "name": "Auréole", "rar": 2, "flag": true, "desc": "LUMIÈRE : tes éclats font +10% de dégâts et aveuglent 1 s les ennemis touchés · {m}% vit. d'attaque", "malus": ["atk_speed", -5.0]},
	{"id": "sceau", "ink": 58, "name": "Sceau d'encre", "rar": 2, "stat": "dmg", "v": 25.0, "desc": "+{v}% dégâts · {m} régénération", "malus": ["regen", -3.0]},
	# Légendaires
	{"id": "chef_oeuvre", "ink": 100, "name": "Chef-d'œuvre", "rar": 3, "flag": true, "desc": "Les stats du dessin de ton perso ×1.5 · {m}% vitesse", "malus": ["speed", -10.0]},
	{"id": "double_trait", "ink": 64, "name": "Double trait", "rar": 3, "flag": true, "desc": "Tes armes de mêlée lancent aussi leur dessin · {m} armure", "malus": ["armor", -3.0]},
	{"id": "arc_en_ciel", "ink": 72, "name": "Prisme", "rar": 3, "flag": true, "desc": "+15% de chaque effet élémentaire sur tes armes · {m}% critique", "malus": ["crit", -8.0]},
	{"id": "encrier", "ink": 56, "name": "Encrier sans fond", "rar": 3, "flag": true, "desc": "+1 choix de bonus à chaque niveau, mais -15% PV max"},
	{"id": "joconde", "ink": 90, "name": "La Joconde", "rar": 3, "flag": true, "desc": "Chaque vague finie : +15% dégâts pour la partie · {m} PV max", "malus": ["max_hp", -5.0]},
	{"id": "double_expo", "ink": 70, "name": "Double exposition", "rar": 3, "flag": true, "desc": "Chaque attaque a 25% de chances de se relancer aussitôt · {m}% critique", "malus": ["crit", -6.0]},
	{"id": "musee", "ink": 80, "name": "Musée ambulant", "rar": 3, "flag": true, "desc": "+1 emplacement d'arme (7 au lieu de 6) · {m}% dégâts", "malus": ["dmg", -8.0]},
	{"id": "trompe_oeil", "ink": 66, "name": "Trompe-l'œil", "rar": 3, "flag": true, "desc": "30% des tirs ennemis sont déviés · {m} armure", "malus": ["armor", -4.0]},
	{"id": "restauration", "ink": 76, "name": "Restauration", "rar": 3, "flag": true, "desc": "Soigne 30% de tes PV au début de chaque vague, mais -15% d'or ramassé"},
	{"id": "renaissance", "ink": 84, "name": "Renaissance", "rar": 3, "flag": true, "desc": "Une fois par partie, à 0 PV tu reviens avec 50% de tes PV · {m}% vitesse", "malus": ["speed", -10.0]},
	{"id": "mise_abyme", "ink": 80, "name": "Mise en abyme", "rar": 3, "flag": true, "desc": "Tes projectiles qui touchent se DIVISENT en 2 petits projectiles · {m}% critique", "malus": ["crit", -6.0]},
	{"id": "midas", "ink": 74, "name": "Pinceau de Midas", "rar": 3, "flag": true, "desc": "Chaque ennemi tué donne +1 or, mais -20% PV max"},
	{"id": "palimpseste", "ink": 70, "name": "Palimpseste", "rar": 3, "flag": true, "desc": "Les bonus de niveau que tu choisis comptent DOUBLE, mais un choix de moins à chaque niveau"},
	{"id": "fresque", "ink": 90, "name": "Fresque", "rar": 3, "flag": true, "desc": "+0,5% dégâts par dessin dans ta galerie (max +60%) · {m}% vitesse", "malus": ["speed", -5.0]},
	{"id": "autographe", "ink": 66, "name": "Autographe", "rar": 3, "flag": true, "desc": "Tes critiques font ×2 sur les boss, mais -8% dégâts contre les autres"},
	{"id": "nuit_etoilee", "ink": 84, "name": "Nuit étoilée", "rar": 3, "flag": true, "desc": "Un ennemi tué sur 10 fait tomber une étoile qui explose en zone · {m} PV max", "malus": ["max_hp", -5.0]},
	{"id": "derniere_touche", "ink": 72, "name": "Dernière touche", "rar": 3, "flag": true, "desc": "Sous 25% de PV : tes armes font ×2 et tu vas 20% plus vite, mais -10% PV max"},
	{"id": "pacte_sang", "ink": 70, "name": "Pacte de sang", "rar": 3, "flag": true, "desc": "Ton vol de vie est DOUBLÉ, mais ta régénération et les potions ne marchent plus"},
	{"id": "herisson", "ink": 74, "name": "Hérisson", "rar": 3, "flag": true, "desc": "Tes épines frappent EN CONTINU les ennemis collés à toi (toutes les 0,5 s) · {m}% dégâts", "malus": ["dmg", -6.0]},
	{"id": "cercle_chromatique", "ink": 86, "name": "Cercle chromatique", "rar": 3, "flag": true, "desc": "Chaque élément DIFFÉRENT appliqué à un ennemi lui fait +15% de dégâts (jusqu'à +90%) · {m}% critique", "malus": ["crit", -6.0]},
	{"id": "alchimie", "ink": 80, "name": "Alchimie", "rar": 3, "flag": true, "desc": "Tes effets élémentaires ont 50% de chances de se propager à l'ennemi le plus proche · {m} PV max", "malus": ["max_hp", -5.0]},
	{"id": "horloge", "ink": 76, "name": "Horloge", "rar": 3, "flag": true, "desc": "Toutes les 12 s, le TEMPS S'ARRÊTE 2 s : ennemis et tirs figés, tes armes font ×2 · {m} PV max", "malus": ["max_hp", -6.0]},
	{"id": "sablier_brise", "ink": 70, "name": "Sablier brisé", "rar": 3, "stat": "atk_speed", "v": 45.0, "flag": true, "desc": "+{v}% vit. d'attaque, mais les vagues durent 25% plus longtemps"},
]

## Bonus selon l'endroit où l'amulette est posée sur le perso.
const ZONES := {
	"Tête": {"stat": "crit", "v": 3.0, "desc": "+3% critique"},
	"Cœur": {"stat": "max_hp", "v": 3.0, "desc": "+3 PV max"},
	"Mains": {"stat": "atk_speed", "v": 5.0, "desc": "+5% vit. d'attaque"},
	"Pieds": {"stat": "speed", "v": 5.0, "desc": "+5% vitesse"},
	"Aura": {"stat": "harvest", "v": 2.0, "desc": "+2 pourboire, flotte autour de toi"},
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
	# Valeur ACTUELLE des amulettes dont l'effet varie (pendant une partie)
	if Run.active:
		var live := Stats.amulet_live(String(def.id))
		if live != "":
			s = "Actuellement : %s
%s" % [live, s]
	return s
