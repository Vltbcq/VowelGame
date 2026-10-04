"""Visuel du cercle des faiblesses (pixel art, couleurs du jeu).
Chaque couleur bat la suivante (sens des flèches) : Feu → Foudre → Poison → Glace → Arcane → Feu ;
Lumière et Ombre se battent l'un l'autre.
Écrit assets/ui/cercle.png (avec les noms), assets/ui/cercle_mini.png (sans les noms, petit)
et docs/cercle_elements_x4.png (aperçu agrandi). Usage : python docs/cercle_elements.py"""
import math
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, '..')
INK = (0x1a, 0x14, 0x23)
GOLD = (0xd6, 0xab, 0x4f)
GOLD_DARK = (0x8c, 0x64, 0x14)
SH = {   # sombre, normale, claire
	'feu': [(0x8c, 0x1f, 0x2a), (0xd8, 0x43, 0x3b), (0xf0, 0x8a, 0x5d)],
	'foudre': [(0xb0, 0x7d, 0x1c), (0xf0, 0xc4, 0x3a), (0xfb, 0xe7, 0x9a)],
	'poison': [(0x2c, 0x6b, 0x3a), (0x4f, 0xaa, 0x4c), (0xa4, 0xd8, 0x6a)],
	'glace': [(0x23, 0x40, 0x7a), (0x3f, 0x7f, 0xd9), (0x8c, 0xc4, 0xf2)],
	'arcane': [(0x4d, 0x2a, 0x7a), (0x8c, 0x52, 0xc9), (0xc7, 0x9b, 0xea)],
	'lumiere': [(0xc8, 0xbf, 0xae), (0xf4, 0xef, 0xe2), (0xff, 0xff, 0xff)],
	'noir': [(0x1a, 0x14, 0x23), (0x3d, 0x34, 0x50), (0x6e, 0x67, 0x84)],
}
ICON = {   # 7×7 : '#' = blanc (ou encre sur fond clair), 'o' = teinte claire
	'feu': ["...#...", "..##...", "..###..", ".#####.", ".##o##.", "##ooo##", ".#####."],
	'foudre': ["...###.", "..###..", ".###...", "#######", "...###.", "..###..", ".##...."],
	'poison': ["...#...", "..###..", ".#####.", ".#####.", "#######", "#######", ".#####."],
	'glace': ["#..#..#", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "#..#..#"],
	'arcane': ["...#...", "...#...", ".#####.", "#######", ".#####.", "...#...", "...#..."],
	'lumiere': ["#..#..#", ".#...#.", "...#...", "#.###.#", "...#...", ".#...#.", "#..#..#"],
	'noir': [".#####.", "##...##", "#.....#", "#..#..#", "#.....#", "##...##", ".#####."],
}
NAMES = {'feu': 'Feu', 'foudre': 'Foudre', 'poison': 'Poison', 'glace': 'Glace', 'arcane': 'Arcane',
	'lumiere': 'Lumière', 'noir': 'Ombre'}
CYCLE = ['feu', 'foudre', 'poison', 'glace', 'arcane']


def build(with_names: bool):
	R, r = (44, 10) if with_names else (31, 7)
	W, H = (236, 168) if with_names else (84, 98)
	cx, cy = W // 2, (72 if with_names else 40)
	img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
	px = img.load()
	d = ImageDraw.Draw(img)
	font = ImageFont.truetype(os.path.join(ROOT, 'assets', 'fonts', 'YosterIsland.ttf'), 12)

	def put(x, y, c):
		if 0 <= x < W and 0 <= y < H:
			px[x, y] = c + (255,)

	def disc(x0, y0, rr, sh):
		for y in range(-rr - 1, rr + 2):
			for x in range(-rr - 1, rr + 2):
				dd = math.hypot(x, y)
				if dd <= rr + 1.0:
					put(x0 + x, y0 + y, INK)
				if dd <= rr - 0.2:
					c = sh[1]
					if x + y < -rr * 0.6:
						c = sh[2]
					elif x + y > rr * 0.7:
						c = sh[0]
					put(x0 + x, y0 + y, c)

	def icon(x0, y0, el):
		light = el in ('lumiere', 'foudre')
		for j, row in enumerate(ICON[el]):
			for i, ch in enumerate(row):
				if ch == '#':
					put(x0 - 3 + i, y0 - 3 + j, INK if light else (255, 255, 255))
				elif ch == 'o':
					put(x0 - 3 + i, y0 - 3 + j, SH[el][2])

	def head(tx, ty, ang, size):
		"""Pointe de flèche pleine (triangle), sans anticrénelage."""
		pts = [(tx, ty)]
		for s in (-1, 1):
			pts.append((tx - size * math.cos(ang + s * 0.62), ty - size * math.sin(ang + s * 0.62)))
		d.polygon([(round(x), round(y)) for x, y in pts], fill=GOLD, outline=GOLD_DARK)

	def arc(a0, a1, rad):
		"""Arc de cercle épais de 2 pixels, d'un angle à l'autre (sens horaire), pointe au bout."""
		steps = int(abs(a1 - a0) * rad * 3) + 2
		pts = set()
		for k in range(steps + 1):
			a = a0 + (a1 - a0) * k / steps
			x, y = cx + rad * math.cos(a), cy + rad * math.sin(a)
			for ox, oy in ((0, 0), (1, 0), (0, 1), (1, 1)):
				pts.add((math.floor(x - 0.5) + ox, math.floor(y - 0.5) + oy))
		for p in pts:   # ombre
			put(p[0] + 1, p[1] + 1, GOLD_DARK)
		for p in pts:
			put(p[0], p[1], GOLD)
		tang = a1 + math.pi / 2
		ex, ey = cx + rad * math.cos(a1), cy + rad * math.sin(a1)
		head(ex + math.cos(tang) * (3 if with_names else 2), ey + math.sin(tang) * (3 if with_names else 2), tang, 6 if with_names else 4)

	# angles des 5 couleurs (Feu en haut, sens horaire)
	angs = [-math.pi / 2 + k * 2 * math.pi / 5 for k in range(5)]
	gap = (r + (6 if with_names else 4)) / R   # on laisse de la place autour des pastilles
	for k in range(5):
		arc(angs[k] + gap, angs[k] + 2 * math.pi / 5 - gap - 3.5 / R, R)
	for k, el in enumerate(CYCLE):
		x, y = round(cx + R * math.cos(angs[k])), round(cy + R * math.sin(angs[k]))
		disc(x, y, r, SH[el])
		icon(x, y, el)
		if with_names:
			tw = d.textlength(NAMES[el], font=font)
			c, s = math.cos(angs[k]), math.sin(angs[k])
			if s > 0.5:            # en bas : sous la pastille
				tx, ty = x - tw / 2, y + r + 3
			elif c > 0.3:          # à droite
				tx, ty = x + r + 5, y - 7
			elif c < -0.3:         # à gauche
				tx, ty = x - r - 5 - tw, y - 7
			else:                  # en haut
				tx, ty = x - tw / 2, y - r - 15
			d.text((round(tx) + 1, ty + 1), NAMES[el], font=font, fill=INK)
			d.text((round(tx), ty), NAMES[el], font=font, fill=SH[el][2])

	# Lumière ⇄ Noir, en bas : deux flèches droites
	y = H - (16 if with_names else 10)
	rr = 8 if with_names else 6
	lx, nx = cx - (26 if with_names else 17), cx + (26 if with_names else 17)
	for (x0, x1, yy) in ((lx + rr + 3, nx - rr - 4, y - 2), (nx - rr - 3, lx + rr + 4, y + 2)):
		step = 1 if x1 > x0 else -1
		for x in range(x0, x1, step):
			put(x + 1, yy + 1, GOLD_DARK)
			put(x, yy, GOLD)
		head(x1, yy, 0 if step > 0 else math.pi, 4 if with_names else 3)
	disc(lx, y, rr, SH['lumiere']); icon(lx, y, 'lumiere')
	disc(nx, y, rr, SH['noir']); icon(nx, y, 'noir')
	if with_names:
		for text, x, col, right in (("Lumière", lx - rr - 5, SH['lumiere'][1], True), ("Ombre", nx + rr + 5, SH['noir'][2], False)):
			tw = d.textlength(text, font=font)
			tx = x - tw if right else x
			d.text((round(tx) + 1, y - 6), text, font=font, fill=INK)
			d.text((round(tx), y - 7), text, font=font, fill=col)
	return img


os.makedirs(os.path.join(ROOT, 'assets', 'ui'), exist_ok=True)
full = build(True)
full.save(os.path.join(ROOT, 'assets', 'ui', 'cercle.png'))
build(False).save(os.path.join(ROOT, 'assets', 'ui', 'cercle_mini.png'))
bg = Image.new('RGBA', full.size, (0x2a, 0x10, 0x15, 255))
bg.alpha_composite(full)
bg.resize((full.width * 4, full.height * 4), Image.NEAREST).save(os.path.join(HERE, 'cercle_elements_x4.png'))
print('ok')
