class_name Pal
extends RefCounted
## Palette 16 bits, éléments liés aux couleurs et couleurs d'interface.

enum { NEUTRE, FEU, GLACE, FOUDRE, POISON, ARCANE, LUMIERE }
const COUNT := 7

const NAMES := ["Neutre", "Feu", "Glace", "Foudre", "Poison", "Arcane", "Lumière"]
const COLOR_NAMES := ["Noir", "Rouge", "Bleu", "Jaune", "Vert", "Violet", "Blanc"]
const UNLOCK := ["", "pack_primaires", "pack_primaires", "pack_primaires", "pack_secondaires", "pack_secondaires", "pack_secondaires"]

## Bonus donné au perso par la couleur, et effet donné aux armes.
const CHAR_BONUS := ["", "+Dégâts", "+Armure", "+Vit. d'attaque", "+Régénération", "+Vol de vie", "+Esquive"]
const WEAPON_EFFECT := ["", "Brûlure", "Gel", "Chaîne d'éclairs", "Poison cumulable", "Marque arcanique", "Éclat de lumière"]

## 3 nuances par élément : sombre, normale, claire.
const SHADES := [
	[Color("1a1423"), Color("3d3450"), Color("6e6784")],
	[Color("8c1f2a"), Color("d8433b"), Color("f08a5d")],
	[Color("23407a"), Color("3f7fd9"), Color("8cc4f2")],
	[Color("b07d1c"), Color("f0c43a"), Color("fbe79a")],
	[Color("2c6b3a"), Color("4faa4c"), Color("a4d86a")],
	[Color("4d2a7a"), Color("8c52c9"), Color("c79bea")],
	[Color("c8bfae"), Color("f4efe2"), Color("ffffff")],
]

# Interface
const INK := Color("1a1423")
const PAPER := Color("e9dcbc")
const PAPER_DARK := Color("d4c29a")
const BG := Color("3e1820")          # mur bordeaux de la galerie
const PANEL := Color("3a2418")       # boiserie
const PANEL_LIGHT := Color("4a2e1f")
const BORDER := Color("8c6414")      # laiton
const TEXT := Color("f4efe2")
const ACCENT := Color("f0c43a")
const DIM := Color("bfa27a")
const DISABLED := Color("6a5040")
const GOOD := Color("7fd66a")
const BAD := Color("f06a5d")
const RARITY := [Color("c9c3b6"), Color("3a86ff"), Color("c071f0"), Color("f0a030")]   # commun gris, rare BLEU
const RARITY_NAMES := ["Commun", "Rare", "Épique", "Légendaire"]
const RARITY_NAMES_F := ["Commune", "Rare", "Épique", "Légendaire"]

static var _cache := {}


static func main_color(el: int) -> Color:
	return SHADES[el][1]


## Élément d'une couleur : la nuance de palette la plus proche.
## Un mélange rouge→bleu donne donc du violet (Arcane) au milieu.
static func element_of(c: Color) -> int:
	var key := c.to_rgba32()
	if _cache.has(key):
		return _cache[key]
	var best := 0
	var best_d := 1e9
	for e in COUNT:
		for s: Color in SHADES[e]:
			var d := (c.r - s.r) * (c.r - s.r) + (c.g - s.g) * (c.g - s.g) + (c.b - s.b) * (c.b - s.b)
			if d < best_d:
				best_d = d
				best = e
	_cache[key] = best
	return best
