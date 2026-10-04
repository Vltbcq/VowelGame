"""Visuel du cercle des faiblesses (pixel art, couleurs du jeu) : docs/cercle_elements.png.
Chaque couleur bat la suivante (sens des flèches) : Feu → Foudre → Poison → Glace → Arcane → Feu ;
Lumière et noir s'opposent. Usage : python docs/cercle_elements.py"""
import math
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
INK = (0x1a, 0x14, 0x23)
BG = (0x2a, 0x10, 0x15)
GOLD = (0xd6, 0xab, 0x4f)
CREAM = (0xe9, 0xdc, 0xbc)
SH = {   # sombre, normale, claire
	'feu': [(0x8c, 0x1f, 0x2a), (0xd8, 0x43, 0x3b), (0xf0, 0x8a, 0x5d)],
	'foudre': [(0xb0, 0x7d, 0x1c), (0xf0, 0xc4, 0x3a), (0xfb, 0xe7, 0x9a)],
	'poison': [(0x2c, 0x6b, 0x3a), (0x4f, 0xaa, 0x4c), (0xa4, 0xd8, 0x6a)],
	'glace': [(0x23, 0x40, 0x7a), (0x3f, 0x7f, 0xd9), (0x8c, 0xc4, 0xf2)],
	'arcane': [(0x4d, 0x2a, 0x7a), (0x8c, 0x52, 0xc9), (0xc7, 0x9b, 0xea)],
	'lumiere': [(0xc8, 0xbf, 0xae), (0xf4, 0xef, 0xe2), (0xff, 0xff, 0xff)],
	'noir': [(0x1a, 0x14, 0x23), (0x3d, 0x34, 0x50), (0x6e, 0x67, 0x84)],
}
# Petits symboles 7×7 (blanc = '#', sombre = 'o')
ICON = {
	'feu': ["...#...", "..##...", "..###..", ".#####.", ".##o##.", "##ooo##", ".#####."],
	'foudre': ["...###.", "..###..", ".###...", "#######", "...###.", "..###..", ".##...."],
	'poison': ["...#...", "..###..", ".#####.", ".#####.", "#######", "#######", ".#####."],
	'glace': ["#..#..#", ".#.#.#.", "..###..", "#######", "..###..", ".#.#.#.", "#..#..#"],
	'arcane': ["...#...", "...#...", ".#####.", "#######", ".#####.", "...#...", "...#..."],
	'lumiere': ["#..#..#", ".#...#.", "...#...", "#.###.#", "...#...", ".#...#.", "#..#..#"],
	'noir': [".#####.", "##...##", "#.....#", "#..#..#", "#.....#", "##...##", ".#####."],
}
NAMES = {'feu': 'Feu', 'foudre': 'Foudre', 'poison': 'Poison', 'glace': 'Glace', 'arcane': 'Arcane',
	'lumiere': 'Lumière', 'noir': 'Noir'}
CYCLE = ['feu', 'foudre', 'poison', 'glace', 'arcane']

W, H = 236, 164
img = Image.new('RGBA', (W, H), BG + (255,))
d = ImageDraw.Draw(img)
font = ImageFont.truetype(os.path.join(HERE, '..', 'assets', 'fonts', 'YosterIsland.ttf'), 12)


def disc(cx, cy, r, sh):
	for y in range(-r - 1, r + 2):
		for x in range(-r - 1, r + 2):
			dd = math.hypot(x, y)
			if dd <= r + 1.0:
				img.putpixel((cx + x, cy + y), INK + (255,))
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			dd = math.hypot(x, y)
			if dd <= r - 0.2:
				c = sh[1]
				if x + y < -r * 0.6:
					c = sh[2]
				elif x + y > r * 0.7:
					c = sh[0]
				img.putpixel((cx + x, cy + y), c + (255,))


def icon(cx, cy, el):
	light = el in ('lumiere', 'foudre')
	for j, row in enumerate(ICON[el]):
		for i, ch in enumerate(row):
			if ch == '#':
				img.putpixel((cx - 3 + i, cy - 3 + j), (INK if light else (255, 255, 255)) + (255,))
			elif ch == 'o':
				img.putpixel((cx - 3 + i, cy - 3 + j), SH[el][2] + (255,))


def arrow(x0, y0, x1, y1, col):
	d.line([(x0, y0), (x1, y1)], fill=col, width=2)
	a = math.atan2(y1 - y0, x1 - x0)
	for s in (-1, 1):
		ax = x1 - 6 * math.cos(a + s * 0.55)
		ay = y1 - 6 * math.sin(a + s * 0.55)
		d.line([(x1, y1), (round(ax), round(ay))], fill=col, width=2)


def label(cx, y, text, col):
	w = d.textlength(text, font=font)
	d.text((round(cx - w / 2) + 1, y + 1), text, font=font, fill=INK)
	d.text((round(cx - w / 2), y), text, font=font, fill=col)


# Le cercle : 5 couleurs, chacune bat la suivante (sens des aiguilles d'une montre)
cx, cy, R, r = 118, 70, 44, 10
pos = []
for k, el in enumerate(CYCLE):
	a = -math.pi / 2 + k * 2 * math.pi / 5
	pos.append((round(cx + R * math.cos(a)), round(cy + R * math.sin(a))))
for k in range(5):
	(x0, y0), (x1, y1) = pos[k], pos[(k + 1) % 5]
	dx, dy = x1 - x0, y1 - y0
	L = math.hypot(dx, dy)
	ux, uy = dx / L, dy / L
	arrow(round(x0 + ux * (r + 4)), round(y0 + uy * (r + 4)), round(x1 - ux * (r + 4)), round(y1 - uy * (r + 4)), GOLD)
for k, el in enumerate(CYCLE):
	disc(pos[k][0], pos[k][1], r, SH[el])
	icon(pos[k][0], pos[k][1], el)
# noms des couleurs, à l'extérieur du cercle (à droite, à gauche ou au-dessus selon la place)
for k, el in enumerate(CYCLE):
	a = -math.pi / 2 + k * 2 * math.pi / 5
	nx, ny = pos[k]
	text = NAMES[el]
	tw = d.textlength(text, font=font)
	if math.cos(a) > 0.3:
		tx, ty = nx + r + 5, ny - 7
	elif math.cos(a) < -0.3:
		tx, ty = nx - r - 5 - tw, ny - 7
	else:
		tx, ty = nx - tw / 2, ny - r - 15
	if math.sin(a) > 0.5:
		ty = ny + r + 3
		tx = nx - tw / 2
	d.text((round(tx) + 1, ty + 1), text, font=font, fill=INK)
	d.text((round(tx), ty), text, font=font, fill=SH[el][2])
# Lumière ⇄ Noir, en bas : ils se battent l'un l'autre
y = 148
disc(98, y, 8, SH['lumiere']); icon(98, y, 'lumiere')
disc(138, y, 8, SH['noir']); icon(138, y, 'noir')
arrow(109, y - 3, 127, y - 3, GOLD)
arrow(127, y + 3, 109, y + 3, GOLD)
for text, x, col, right in (("Lumière", 86, SH['lumiere'][1], True), ("Noir", 150, SH['noir'][2], False)):
	tw = d.textlength(text, font=font)
	tx = x - tw if right else x
	d.text((round(tx) + 1, y - 6), text, font=font, fill=INK)
	d.text((round(tx), y - 7), text, font=font, fill=col)
img.save(os.path.join(HERE, 'cercle_elements.png'))
img.resize((W * 4, H * 4), Image.NEAREST).save(os.path.join(HERE, 'cercle_elements_x4.png'))
print('ok')
