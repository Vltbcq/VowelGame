"""Icônes des stats du perso (PV, armure, esquive...), même DA que les outils (docs/tool_icons.py) :
pixel art 16 × 16, palette du jeu, contour d'encre d'1 pixel.

Usage : python docs/stat_icons.py [planche.png]
  - écrit les icônes dans assets/ui/stats/<stat>.png
  - avec un chemin : une planche d'aperçu (icônes agrandies + nom)
"""
import math
import os
import sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tool_icons import Icon, C, N, INK, ROOT  # noqa: E402

PAL = {
	'r': C['red'], 'R': C['red_d'], 'p': C['pink_l'], 'w': C['white'], 'c': C['cream'],
	'g': C['green'], 'G': (0x2c, 0x6b, 0x3a), 'l': (0xa4, 0xd8, 0x6a),
	'y': C['gold'], 'Y': C['gold_l'], 'd': C['gold_d'],
	's': C['grey'], 'S': C['grey_d'], 'W': (0xe8, 0xe8, 0xf0),
	'b': C['blue'], 'B': C['blue_l'], 'n': C['wood'], 'N': C['wood_d'],
	'v': C['violet'], 'V': (0x4d, 0x2a, 0x7a), 'o': (0xe8, 0x7a, 0x3a),
}


def grid(rows):
	"""Dessin pixel par pixel ; le contour d'encre est ajouté automatiquement."""
	i = Icon()
	for y, row in enumerate(rows):
		for x, ch in enumerate(row):
			if ch in PAL:
				i.set(x, y, PAL[ch])
	return i


def disc(i, cx, cy, r, col, hole=-1.0):
	for y in range(N):
		for x in range(N):
			d = math.hypot(x - cx, y - cy)
			if hole < d <= r:
				i.set(x, y, col)


def max_hp():
	return grid([
		"................",
		"................",
		"...rrr....rrr...",
		"..rpprr..rrrrr..",
		"..rprrrrrrrrrr..",
		"..rrrrrrrrrrrr..",
		"..rrrrrrrrrrRr..",
		"...rrrrrrrrRr...",
		"....rrrrrrRr....",
		".....rrrrRr.....",
		"......rrRr......",
		".......rr.......",
	])


def regen():
	return grid([
		"................",
		"......gggg......",
		"......gllg......",
		"......glgg......",
		"..gggggggggggg..",
		"..glllgggggggg..",
		"..gggggggggggG..",
		"..ggggggggggGG..",
		"......gggG......",
		"......gggG......",
		"......ggGG......",
		"...........l....",
		"..........lll...",
		"...........l....",
	])


def armor():
	return grid([
		"................",
		"..yyyyyyyyyyyy..",
		"..yWWsssssssSy..",
		"..yWssssssssSy..",
		"..ysssssssssSy..",
		"..ysssssssssSy..",
		"..ysssssssssSy..",
		"...ysssssssSy...",
		"...ysssssssSy...",
		"....ysssssSy....",
		".....yssSSy.....",
		"......ysSy......",
		".......yy.......",
	])


def dodge():
	# une silhouette qui file en laissant des traînées
	return grid([
		"................",
		"..........ccc...",
		".........cwccc..",
		".........ccccc..",
		"..BBBB....ccc...",
		"........cccccc..",
		".BBBBBB.cccccccc",
		"........cccccc..",
		"..BBBB...cc.cc..",
		"........cc...cc.",
		".......cc.....c.",
	])


def speed():
	return grid([
		"................",
		"................",
		"..bb.....bb.....",
		"..Bbb....Bbb....",
		"...Bbb....Bbb...",
		"....Bbb....Bbb..",
		".....bbb....bbb.",
		"....bbb....bbb..",
		"...bbb....bbb...",
		"..bbb....bbb....",
		"..bb.....bb.....",
	])


def dmg():
	return grid([
		"..............Ws",
		".............WsS",
		"............WsS.",
		"...........WsS..",
		"..........WsS...",
		".........WsS....",
		"........WsS.....",
		"..d....WsS......",
		"..dd..WsS.......",
		"...dyWsS........",
		"....yyS.........",
		"...nyydd........",
		"..nN..dd........",
		".nN.............",
		"nN..............",
	])


def atk_speed():
	return grid([
		"...dddddddddd...",
		"....yWYYYYYy....",
		"....yYYYYYYy....",
		".....yYYYYy.....",
		"......yYYy......",
		".......yy.......",
		"......y..y......",
		".....y.YY.y.....",
		"....y.YYYY.y....",
		"....yYYYYYYy....",
		"...dddddddddd...",
	])


def crit():
	i = Icon()
	disc(i, 7.5, 7.5, 6.6, PAL['r'])
	disc(i, 7.5, 7.5, 4.8, PAL['w'])
	disc(i, 7.5, 7.5, 3.0, PAL['r'])
	disc(i, 7.5, 7.5, 1.3, PAL['w'])
	return i


def range_():
	return grid([
		"................",
		"................",
		"................",
		"...........S....",
		"r.r........sS...",
		"rr.r.nnnnnnnsss.",
		".rr.rNNNNNNNsS..",
		"r.r........S....",
		"................",
		"..s....s....s...",
		"................",
	])


def lifesteal():
	return grid([
		"................",
		".......r........",
		"......rr........",
		"......rrr.......",
		".....rrrr.......",
		"....rprrrr......",
		"....rprrrrr.....",
		"...rpprrrrr.....",
		"...rprrrrrR.....",
		"...rrrrrrrR.....",
		"....rrrrrR......",
		".....RRRR.......",
	])


def luck():
	"""Trèfle à quatre feuilles (chaque feuille en forme de cœur)."""
	return grid([
		"................",
		"..gg.gg..gg.gg..",
		".glgggg..gglggg.",
		".gggggg..gggggg.",
		"..ggggg..ggggg..",
		"...gggggggggg...",
		".....gGGGGg.....",
		".....gGGGGg.....",
		"...gggggggggg...",
		"..ggggg..ggggg..",
		".gggggg..gggggg.",
		".gggggg..gggggg.",
		"..gg.gg..gg.gg..",
		"............GG..",
		".............GG.",
	])


def coin_stack(i, x, bottom, n):
	"""Pile de n pièces (7 px de large, contour compris), posée sur la ligne `bottom`.
	Dessinée par-dessus ce qui est derrière : les piles se séparent par leur contour."""
	rows = [".kkkkk.", "kYwYYyk", "kyYYYyk", "kdyyydk"]
	for c in range(n - 1):
		rows += ["kyYYyyk", "kdddddk"]
	rows += [".kkkkk."]
	pal = {'k': INK, 'y': PAL['y'], 'Y': PAL['Y'], 'd': PAL['d'], 'w': C['white']}
	top = bottom - len(rows) + 1
	for j, row in enumerate(rows):
		for k, ch in enumerate(row):
			if ch in pal:
				i.set(x + k, top + j, pal[ch])


def harvest():
	"""Des piles de pièces d'or de hauteurs différentes, serrées les unes contre les autres."""
	i = Icon()
	i.outline = False
	coin_stack(i, 5, 10, 4)    # la plus haute, au fond
	coin_stack(i, 0, 12, 3)    # à gauche
	coin_stack(i, 9, 13, 3)    # à droite
	coin_stack(i, 4, 15, 1)    # une pièce seule devant
	return i


def thorns():
	return grid([
		"................",
		".......l........",
		"......lgg.......",
		"..l..lgggl......",
		"..gg.ggggg..l...",
		"..gg.ggGgg.gg...",
		"..ggggggGggggl..",
		"...gggggGggggg..",
		"......ggGgg.....",
		"......ggGgg.....",
		"......ggGgg.....",
		"....nnnnnnnnN...",
		".....nnnnnnN....",
		".....NNNNNNN....",
	])


def el_power():
	# fiole ronde aux couleurs des éléments
	i = Icon()
	disc(i, 7.5, 9.5, 5.6, PAL['W'])
	for y in range(N):
		for x in range(N):
			if math.hypot(x - 7.5, y - 9.5) <= 4.6 and y >= 8:
				i.set(x, y, [PAL['r'], PAL['y'], PAL['g'], PAL['b'], PAL['v']][min(4, max(0, (x - 3) * 5 // 10))])
	i.rect(6, 1, 9, 4, PAL['W'])
	i.rect(5, 0, 10, 0, PAL['n'])
	i.set(5, 8, PAL['w'])
	i.set(4, 9, PAL['w'])
	return i


STATS = [
	("max_hp", "PV max", max_hp), ("regen", "Régénération", regen), ("armor", "Armure", armor),
	("dodge", "Esquive", dodge), ("move", "Vitesse", speed), ("dmg", "Dégâts", dmg),
	("atk_speed", "Vit. d'attaque", atk_speed), ("crit", "Critique", crit), ("range", "Portée", range_),
	("lifesteal", "Vol de vie", lifesteal), ("luck", "Chance", luck), ("harvest", "Pourboire", harvest),
	("thorns", "Épines", thorns), ("el_power", "Puissance élém.", el_power),
]


def main():
	icons = {key: fn().image() for key, label, fn in STATS}
	if len(sys.argv) > 1:
		sheet(icons, sys.argv[1])
		return
	out_dir = os.path.join(ROOT, 'assets', 'ui', 'stats')
	os.makedirs(out_dir, exist_ok=True)
	for key, img in icons.items():
		img.save(os.path.join(out_dir, key + '.png'))
	print('ok', len(icons), 'icônes dans', out_dir)


def sheet(icons, path):
	"""Planche : chaque icône ×4, puis la ligne de stat comme dans le jeu (icône ×2 + texte)."""
	cols = 5
	cw, ch = 220, 130
	rows = (len(STATS) + cols - 1) // cols
	img = Image.new('RGB', (cols * cw, rows * ch), (0x3e, 0x18, 0x20))
	d = ImageDraw.Draw(img)
	font = ImageFont.truetype(os.path.join(ROOT, 'assets', 'fonts', 'YosterIsland.ttf'), 24)
	for k, (key, label, fn) in enumerate(STATS):
		x0, y0 = (k % cols) * cw, (k // cols) * ch
		big = icons[key].resize((N * 4, N * 4), Image.NEAREST)
		img.paste(big, (x0 + (cw - N * 4) // 2, y0 + 6), big)
		# ligne de stat sur le cartel crème
		d.rectangle([x0 + 10, y0 + 78, x0 + cw - 10, y0 + 118], fill=(0xef, 0xe6, 0xcf))
		ic = icons[key].resize((N * 2, N * 2), Image.NEAREST)
		img.paste(ic, (x0 + 16, y0 + 82), ic)
		d.text((x0 + 54, y0 + 86), label, font=font, fill=(0x1a, 0x14, 0x23))
	img.save(path)
	print('planche', path, img.size)


if __name__ == '__main__':
	main()
