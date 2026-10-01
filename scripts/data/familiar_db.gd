class_name FamiliarDB
extends RefCounted
## Familiers : des compagnons que tu DESSINES, qui se baladent sur la page avec chacun son
## comportement (attaquer, soigner, gêner, encaisser...). Tous uniques, nombre illimité.
## « Pavel » : en hommage au chien de Theorus. « Yuki » et « Teemeo » : clins d'œil à League of Legends.

const LIST := [
	# Communs
	{"id": "moustique", "name": "Moustique", "rar": 0, "ink": 40,
		"desc": "Vole piquer l'ennemi le plus proche toutes les 1,5 s : dégâts, et te rend 1 PV."},
	{"id": "taupe", "name": "Taupe", "rar": 0, "ink": 50,
		"desc": "Creuse, puis surgit sous un ennemi : dégâts et étourdi 1 s (toutes les 4 s)."},
	{"id": "pie", "name": "Pie voleuse", "rar": 0, "ink": 45,
		"desc": "Chaque goutte d'or ramassée : 15% de chances de te rapporter 1 ou 2 or en plus."},
	# Rares
	{"id": "herisson_f", "name": "Hérisson-pelote", "rar": 1, "ink": 55,
		"desc": "Roule au hasard sur la page : les ennemis touchés prennent tes épines (au moins 3)."},
	{"id": "luciole", "name": "Luciole", "rar": 1, "ink": 40,
		"desc": "Se pose sur un ennemi : il prend +25% de dégâts. Passe au suivant quand il meurt."},
	{"id": "escargot", "name": "Escargot", "rar": 1, "ink": 50,
		"desc": "Laisse une traînée de bave qui ralentit les ennemis de 50%."},
	# Épiques
	{"id": "corbeau", "name": "Corbeau", "rar": 2, "ink": 60,
		"desc": "Plane au-dessus de toi et plonge sur l'ennemi le plus fort (élites et boss en priorité), toutes les 3 s."},
	{"id": "grenouille", "name": "Grenouille", "rar": 2, "ink": 60,
		"desc": "Saute partout et avale d'un coup de langue un petit ennemi (pas les élites ni les boss), toutes les 6 s."},
	{"id": "fantome", "name": "Fantôme de papier", "rar": 2, "ink": 55,
		"desc": "Traverse la page en ligne droite toutes les 5 s : les ennemis traversés sont aveuglés 2 s."},
	# Légendaires
	{"id": "yuki", "name": "Yuki", "rar": 3, "ink": 70,
		"desc": "Petit chat magique collé à toi : te soigne de 5% de tes PV toutes les 8 s, bloque un coup toutes les 12 s, et sous 25% de PV te donne +30% de vitesse 3 s."},
	{"id": "pavel", "name": "Pavel", "rar": 3, "ink": 80,
		"desc": "Gros chien qui encaisse : les ennemis proches de lui l'attaquent lui plutôt que toi. K.O., il revient 10 s plus tard."},
	{"id": "teemeo", "name": "Teemeo", "rar": 3, "ink": 70,
		"desc": "Plante des champignons invisibles (8 au plus) qui explosent en nuage de poison, et lance une fléchette aveuglante toutes les 5 s."},
]

const PRICE := [16, 30, 52, 88]
const RAR_INK := [1.0, 1.3, 1.6, 2.0]


static func get_def(id: String) -> Dictionary:
	for d in LIST:
		if d.id == id:
			return d
	return {}


static func of_rarity(rar: int) -> Array:
	return LIST.filter(func(d): return int(d.rar) == rar)


static func ink(def: Dictionary) -> int:
	return roundi(def.ink * RAR_INK[int(def.rar)])


static func canvas(def: Dictionary) -> int:
	return [24, 24, 28, 32][int(def.rar)]
