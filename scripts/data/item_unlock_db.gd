class_name ItemUnlockDB
extends RefCounted
## Succès qui DÉBLOQUENT des armes et des amulettes (la moitié du jeu). Un objet verrouillé
## n'apparaît pas en boutique. Les conditions ne sont affichées que dans le Codex.
## Obtenu pendant une partie : l'objet n'est disponible qu'à la fin de la partie.
## Clés : "w:<type d'arme>", "a:<id d'amulette>" ou "f:<id de familier>".
##
## kind : "stat" (stat du perso >= v), "gold" (or en poche >= v), "colors" (couleurs du perso),
## "pixels" (pixels du perso), "solo" (vague v finie avec une seule arme), "wave" (vague finie),
## "wave2" (vague finie sur Le Tableau noir), "win" (partie gagnée, difficulté >= v),
## "win2" (partie gagnée sur Le Tableau noir), "kills" / "elites" (ennemis / élites tués, toutes
## parties), "level", "boss" (boss vaincu), "runs" (parties jouées), "syn" (synergie de
## l'élément el active à la vague v ou plus), "syn2" (v synergies actives en même temps),
## "legend" (arme légendaire), "clean" (vague >= v finie sans perdre de PV), "gallery".
## v0.8 : "mono6" (vague finie avec 6 armes de la même couleur), "boss_clean" (boss vaincu sans
## perdre de PV), "boss_total" (boss vaincus, toutes parties), "damage" (dégâts infligés, toutes
## parties), "boss_crit" (boss achevé d'un critique), "mono_color" (vague v finie avec un perso
## d'une seule couleur), "spent" (or dépensé, toutes parties), "roulette" (parties gagnées à la
## roulette), "wave_kills" (ennemis tués en une vague), "maps" (vague finie sur les 2 cartes),
## "fast_win" (partie gagnée en moins de v minutes), "legend_buys" (légendaires achetées dans une partie).
## v0.9 : "earned" (or ramassé, toutes parties), "win_pet" (partie gagnée avec un familier),
## "pets" (v familiers en même temps), "pets_wave" (vague v finie avec n familiers).

const CONDS := {
	# --- Armes à ratio : leur stat
	"w:plume": {"kind": "solo", "v": 5},
	"w:rouleau": {"kind": "stat", "stat": "max_hp", "v": 80},
	"w:chevalet_bouclier": {"kind": "stat", "stat": "armor", "v": 15},
	"w:aerographe": {"kind": "stat", "stat": "speed", "v": 40},
	"w:cutter": {"kind": "stat", "stat": "crit", "v": 40},
	"w:compte_gouttes": {"kind": "stat", "stat": "luck", "v": 40},
	"w:pinceau_dore": {"kind": "gold", "v": 150},
	"w:regle": {"kind": "stat", "stat": "range", "v": 50},
	"w:nuancier": {"kind": "colors", "v": 4},
	"w:silhouette": {"kind": "pixels", "v": 450},
	"w:pipette": {"kind": "stat", "stat": "lifesteal", "v": 20},
	# --- Épiques / légendaires
	"w:ciseaux": {"kind": "elites", "v": 30},
	"w:loupe": {"kind": "boss", "boss": "critique"},
	"w:avion": {"kind": "wave", "v": 10},
	"w:eventail": {"kind": "kills", "v": 3000},
	"w:crayon_hb": {"kind": "level", "v": 12},
	"w:retouche": {"kind": "win", "v": 0},
	"w:miroir_deformant": {"kind": "boss", "boss": "muse"},
	"w:grande_signature": {"kind": "kills", "v": 10000},
	"w:point_final": {"kind": "boss", "boss": "toile"},
	# --- Amulettes : vol de vie, épines, éléments
	"a:encre_rouge": {"kind": "stat", "stat": "lifesteal", "v": 8},
	"a:encre_carmin": {"kind": "stat", "stat": "lifesteal", "v": 15},
	"a:calice": {"kind": "stat", "stat": "lifesteal", "v": 25},
	"a:chauve_souris": {"kind": "kills", "v": 2000},
	"a:pacte_sang": {"kind": "win2"},
	"a:carapace": {"kind": "stat", "stat": "armor", "v": 10},
	"a:oursin": {"kind": "stat", "stat": "thorns", "v": 5},
	"a:cactus": {"kind": "stat", "stat": "max_hp", "v": 70},
	"a:ronces": {"kind": "stat", "stat": "thorns", "v": 10},
	"a:herisson": {"kind": "stat", "stat": "thorns", "v": 20},
	"a:allumette": {"kind": "syn", "el": 1, "v": 1},
	"a:braise": {"kind": "syn", "el": 1, "v": 8},
	"a:givre": {"kind": "syn", "el": 2, "v": 1},
	"a:stalactite": {"kind": "syn", "el": 2, "v": 8},
	"a:paratonnerre": {"kind": "syn", "el": 3, "v": 1},
	"a:dynamo": {"kind": "syn", "el": 3, "v": 8},
	"a:fiole": {"kind": "syn", "el": 4, "v": 1},
	"a:champignon": {"kind": "syn", "el": 4, "v": 8},
	"a:grimoire": {"kind": "syn", "el": 5, "v": 1},
	"a:pentacle": {"kind": "syn", "el": 5, "v": 8},
	"a:vitrail": {"kind": "syn", "el": 6, "v": 1},
	"a:aureole": {"kind": "syn", "el": 6, "v": 8},
	"a:cercle_chromatique": {"kind": "colors", "v": 6},
	"a:alchimie": {"kind": "syn2", "v": 2},
	# --- Amulettes : le reste
	"a:spatule": {"kind": "wave", "v": 4},
	"a:viseur": {"kind": "wave", "v": 4},
	"a:chiffon": {"kind": "runs", "v": 3},
	"a:encre_sympathique": {"kind": "stat", "stat": "luck", "v": 15},
	"a:godet": {"kind": "stat", "stat": "el_power", "v": 20},
	"a:etiquette_prix": {"kind": "gold", "v": 100},
	"a:timbre": {"kind": "stat", "stat": "thorns", "v": 3},
	"a:gommette": {"kind": "level", "v": 6},
	"a:aimant_pepites": {"kind": "gold", "v": 120},
	"a:crayon_couleur": {"kind": "colors", "v": 3},
	"a:ombre_portee": {"kind": "stat", "stat": "dodge", "v": 30},
	"a:pansement": {"kind": "level", "v": 10},
	"a:cadran_solaire": {"kind": "wave", "v": 8},
	"a:taille_douce": {"kind": "stat", "stat": "armor", "v": 12},
	"a:encre_invisible": {"kind": "elites", "v": 15},
	"a:papier_verre": {"kind": "kills", "v": 1500},
	"a:bulle_soin": {"kind": "runs", "v": 5},
	"a:elastique": {"kind": "wave", "v": 9},
	"a:correcteur": {"kind": "wave2", "v": 3},
	"a:cachet_cire": {"kind": "elites", "v": 40},
	"a:kaleidoscope": {"kind": "colors", "v": 5},
	"a:lanterne": {"kind": "boss", "boss": "rature"},
	"a:ressort": {"kind": "stat", "stat": "range", "v": 40},
	"a:metronome": {"kind": "stat", "stat": "atk_speed", "v": 50},
	"a:pierre_aiguiser": {"kind": "legend"},
	"a:boussole": {"kind": "wave", "v": 11},
	"a:papillon": {"kind": "stat", "stat": "crit", "v": 50},
	"a:encre_seiche": {"kind": "wave2", "v": 8},
	"a:echelle": {"kind": "level", "v": 15},
	"a:accordeon": {"kind": "stat", "stat": "speed", "v": 50},
	"a:bouclier_papier": {"kind": "clean", "v": 10},
	"a:mise_abyme": {"kind": "win", "v": 1},
	"a:midas": {"kind": "gold", "v": 300},
	"a:palimpseste": {"kind": "level", "v": 20},
	"a:fresque": {"kind": "gallery", "v": 100},
	"a:autographe": {"kind": "boss", "boss": "professeur"},
	"a:nuit_etoilee": {"kind": "kills", "v": 20000},
	"a:derniere_touche": {"kind": "win", "v": 2},
	# --- v0.8
	"a:accord_parfait": {"kind": "mono6"},
	"a:bache": {"kind": "boss_clean"},
	"a:colle_forte": {"kind": "boss_total", "v": 10},
	"a:grattoir": {"kind": "damage", "v": 100000},
	"a:monocle": {"kind": "boss_crit"},
	"a:pigment_pur": {"kind": "mono_color", "v": 10},
	"a:toile_tendue": {"kind": "boss", "boss": "photocopieuse"},
	"a:carnet_commandes": {"kind": "spent", "v": 1000},
	"a:de_pipe": {"kind": "roulette", "v": 3},
	"a:performance": {"kind": "wave_kills", "v": 150},
	"a:reflet": {"kind": "boss", "boss": "encrier"},
	"a:salle_thematique": {"kind": "maps"},
	"a:speed_painting": {"kind": "fast_win", "v": 25},
	"a:vernissage": {"kind": "legend_buys", "v": 3},
	# --- Familiers : la moitié à débloquer
	"f:pie": {"kind": "earned", "v": 3000},
	"f:perroquet": {"kind": "win_pet"},
	"f:fantome": {"kind": "win", "v": 1},
	"f:paon": {"kind": "pets_wave", "v": 10, "n": 3},
	"f:pavel": {"kind": "wave", "v": 15},
	"f:teemeo": {"kind": "win", "v": 2},
	"f:chimere": {"kind": "pets", "v": 5},
}

const STAT_NAMES := {"max_hp": "PV max", "armor": "d'armure", "speed": "% de vitesse", "crit": "% de critique",
	"luck": "de chance", "range": "% de portée", "lifesteal": "% de vol de vie", "thorns": "d'épines",
	"el_power": "% de puissance élémentaire", "dodge": "% d'esquive", "atk_speed": "% de vitesse d'attaque"}


static func key_weapon(type: String) -> String:
	return "w:" + type


static func key_amulet(id: String) -> String:
	return "a:" + id


static func key_familiar(id: String) -> String:
	return "f:" + id


## Nom lisible d'une clé ("Arme : Plume solitaire").
static func label(key: String) -> String:
	if key.begins_with("w:"):
		return "Arme : " + String(WeaponDB.get_def(key.substr(2)).name)
	if key.begins_with("f:"):
		return "Familier : " + String(FamiliarDB.get_def(key.substr(2)).name)
	return "Amulette : " + String(AmuletDB.get_def(key.substr(2)).name)


## Condition en clair (affichée dans le Codex).
static func text(c: Dictionary) -> String:
	match String(c.kind):
		"stat":
			return "Atteins %d %s dans une partie." % [int(c.v), STAT_NAMES.get(c.stat, c.stat)]
		"gold":
			return "Aie %d or en poche." % int(c.v)
		"colors":
			return "Joue un perso avec %d couleurs différentes." % int(c.v)
		"pixels":
			return "Joue un perso de %d pixels ou plus." % int(c.v)
		"solo":
			return "Termine la vague %d avec une seule arme." % int(c.v)
		"wave":
			return "Termine la vague %d." % int(c.v)
		"wave2":
			return "Termine la vague %d sur Le Tableau noir." % int(c.v)
		"win":
			return "Gagne une partie" + (" en %s ou plus dur." % Meta.DIFFICULTIES[int(c.v)].name if int(c.v) > 0 else ".")
		"win2":
			return "Gagne une partie sur Le Tableau noir."
		"kills":
			return "Efface %d ennemis (toutes parties)." % int(c.v)
		"elites":
			return "Efface %d élites (toutes parties)." % int(c.v)
		"level":
			return "Atteins le niveau %d dans une partie." % int(c.v)
		"boss":
			return "Vaincs %s." % String(EnemyDB.get_def(c.boss).name)
		"runs":
			return "Joue %d parties." % int(c.v)
		"syn":
			var el: String = Pal.NAMES[int(c.el)]
			return ("Active la synergie %s (3 armes %s)." % [el, el]) if int(c.v) <= 1 else ("Aie la synergie %s active à la vague %d." % [el, int(c.v)])
		"syn2":
			return "Aie %d synergies d'éléments actives en même temps." % int(c.v)
		"legend":
			return "Possède une arme légendaire."
		"clean":
			return "Termine une vague %d ou plus sans perdre de PV." % int(c.v)
		"gallery":
			return "Aie %d dessins dans ta galerie." % int(c.v)
		"mono6":
			return "Termine une vague avec 6 armes de la même couleur."
		"boss_clean":
			return "Vaincs un boss sans perdre de PV pendant sa vague."
		"boss_total":
			return "Vaincs %d boss (toutes parties)." % int(c.v)
		"damage":
			return "Inflige %d dégâts (toutes parties)." % int(c.v)
		"boss_crit":
			return "Achève un boss d'un coup critique."
		"mono_color":
			return "Termine la vague %d avec un perso d'une seule couleur." % int(c.v)
		"spent":
			return "Dépense %d or (toutes parties)." % int(c.v)
		"roulette":
			return "Gagne %d fois à la roulette (toutes parties)." % int(c.v)
		"wave_kills":
			return "Efface %d ennemis en une seule vague." % int(c.v)
		"maps":
			return "Termine une vague sur chacune des deux cartes."
		"fast_win":
			return "Gagne une partie en moins de %d minutes." % int(c.v)
		"legend_buys":
			return "Achète %d objets légendaires dans une même partie." % int(c.v)
		"earned":
			return "Ramasse %d or (toutes parties)." % int(c.v)
		"win_pet":
			return "Gagne une partie avec au moins un familier."
		"pets":
			return "Aie %d familiers en même temps." % int(c.v)
		"pets_wave":
			return "Termine la vague %d avec %d familiers." % [int(c.v), int(c.n)]
	return "?"


## La condition est-elle remplie ? ctx : voir Run.achievement_ctx() + Meta.check_achievements().
static func met(c: Dictionary, ctx: Dictionary) -> bool:
	match String(c.kind):
		"stat":
			return float((ctx.get("stats", {}) as Dictionary).get(c.stat, 0.0)) >= float(c.v)
		"gold":
			return int(ctx.get("gold", 0)) >= int(c.v)
		"colors":
			return int(ctx.get("colors", 0)) >= int(c.v)
		"pixels":
			return int(ctx.get("pixels", 0)) >= int(c.v)
		"solo":
			return int(ctx.get("cleared", 0)) >= int(c.v) and int(ctx.get("weapons", 99)) <= 1
		"wave":
			return int(ctx.get("cleared", 0)) >= int(c.v)
		"wave2":
			return int(ctx.get("map", 1)) == 2 and int(ctx.get("cleared", 0)) >= int(c.v)
		"win":
			return bool(ctx.get("win", false)) and int(ctx.get("diff", 0)) >= int(c.v)
		"win2":
			return bool(ctx.get("win", false)) and int(ctx.get("map", 1)) == 2
		"kills":
			return int(ctx.get("total_kills", 0)) >= int(c.v)
		"elites":
			return int(ctx.get("total_elites", 0)) >= int(c.v)
		"level":
			return int(ctx.get("level", 0)) >= int(c.v)
		"boss":
			return (ctx.get("bosses", {}) as Dictionary).has(c.boss)
		"runs":
			return int(ctx.get("runs", 0)) >= int(c.v)
		"syn":
			return (ctx.get("syn", {}) as Dictionary).has(int(c.el)) and int(ctx.get("cleared", 0)) >= int(c.v) - 1
		"syn2":
			return (ctx.get("syn", {}) as Dictionary).size() >= int(c.v)
		"legend":
			return bool(ctx.get("legend", false))
		"clean":
			return bool(ctx.get("clean", false)) and int(ctx.get("cleared", 0)) >= int(c.v)
		"gallery":
			return int(ctx.get("gallery", 0)) >= int(c.v)
		"mono6":
			return bool(ctx.get("mono6", false))
		"boss_clean":
			return bool(ctx.get("boss_clean", false))
		"boss_total":
			return int((ctx.get("counters", {}) as Dictionary).get("bosses", 0)) >= int(c.v)
		"damage":
			return float((ctx.get("counters", {}) as Dictionary).get("damage", 0.0)) >= float(c.v)
		"boss_crit":
			return bool(ctx.get("boss_crit", false))
		"mono_color":
			return int(ctx.get("colors", 99)) <= 1 and int(ctx.get("cleared", 0)) >= int(c.v)
		"spent":
			return int((ctx.get("counters", {}) as Dictionary).get("gold_spent", 0)) >= int(c.v)
		"roulette":
			return int((ctx.get("counters", {}) as Dictionary).get("roulette_wins", 0)) >= int(c.v)
		"wave_kills":
			return int(ctx.get("wave_kills", 0)) >= int(c.v)
		"maps":
			return int(ctx.get("maps", 0)) >= 2
		"fast_win":
			return bool(ctx.get("win", false)) and float(ctx.get("play_time", 1e9)) < float(c.v) * 60.0
		"legend_buys":
			return int(ctx.get("legend_buys", 0)) >= int(c.v)
		"earned":
			return int((ctx.get("counters", {}) as Dictionary).get("gold_earned", 0)) >= int(c.v)
		"win_pet":
			return bool(ctx.get("win", false)) and int(ctx.get("pets", 0)) >= 1
		"pets":
			return int(ctx.get("pets", 0)) >= int(c.v)
		"pets_wave":
			return int(ctx.get("pets", 0)) >= int(c.n) and int(ctx.get("cleared", 0)) >= int(c.v)
	return false
