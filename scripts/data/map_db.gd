class_name MapDB
extends RefCounted
## Cartes (lieux d'une partie). Chaque carte a ses propres ennemis, ses boss et son décor.
## La 2e se débloque en gagnant une partie sur la 1re (Esquisse ou plus dur).

const MAPS := {
	1: {"name": "La Feuille", "floor": "paper",
		"desc": "La page blanche du début : taches, gribouillis, ratures... et la Toile Blanche au bout.",
		"bosses": {5: ["rature"], 10: ["critique", "muse"], 15: ["toile"]}},
	2: {"name": "Le Tableau noir", "floor": "board", "events": true,
		"desc": "Une salle de classe hantée. Punaises, trombones, gommes... et des ÉVÉNEMENTS en pleine vague : éponge, pluie de craies, sonnerie, bon point.",
		"unlock": "Gagne une partie sur La Feuille (Esquisse ou plus dur).",
		"bosses": {5: ["professeur"], 10: ["photocopieuse"], 15: ["encrier"]}},
}


static func get_def(id: int) -> Dictionary:
	return MAPS.get(id, MAPS[1])


## Boss de chaque vague pour une nouvelle partie sur cette carte (tirés au sort s'il y a le choix).
static func boss_plan(id: int) -> Dictionary:
	var out := {}
	var b: Dictionary = get_def(id).bosses
	for w in b:
		out[w] = (b[w] as Array).pick_random()
	return out
