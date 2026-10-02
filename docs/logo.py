"""Usage : python docs/logo.py  (régénère docs/logo.png et docs/logo_petit.png)
Logo « Paint It Until You Make It » en pixel art : lettres peintes aux couleurs des éléments,
coulures d'encre, crayon en train de finir le dernier IT. Sortie : PNG transparent."""
import random
import sys
from PIL import Image

random.seed(7)

INK = (0x1a, 0x14, 0x23)
PAPER = (0xf4, 0xef, 0xe2)
WHITE = (255, 255, 255)
SH = {
	'feu': [(0x8c, 0x1f, 0x2a), (0xd8, 0x43, 0x3b), (0xf0, 0x8a, 0x5d)],
	'glace': [(0x23, 0x40, 0x7a), (0x3f, 0x7f, 0xd9), (0x8c, 0xc4, 0xf2)],
	'foudre': [(0xb0, 0x7d, 0x1c), (0xf0, 0xc4, 0x3a), (0xfb, 0xe7, 0x9a)],
	'poison': [(0x2c, 0x6b, 0x3a), (0x4f, 0xaa, 0x4c), (0xa4, 0xd8, 0x6a)],
	'arcane': [(0x4d, 0x2a, 0x7a), (0x8c, 0x52, 0xc9), (0xc7, 0x9b, 0xea)],
	'papier': [(0xc8, 0xbf, 0xae), (0xf4, 0xef, 0xe2), (0xff, 0xff, 0xff)],
}

# Police pixel 5×7 (comme les lettres arrondies du logo d'origine)
G = {
	'P': ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	'A': [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	'I': ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
	'N': ["#...#", "##..#", "#.#.#", "#.#.#", "#..##", "#...#", "#...#"],
	'T': ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	'U': ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	'L': ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	'Y': ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	'O': [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	'M': ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	'K': ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	'E': ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	' ': [".....", ".....", ".....", ".....", ".....", ".....", "....."],
}

W, H = 340, 130
col = {}   # (x, y) -> couleur de la peinture (avant contour)


def put(x, y, c):
	if 0 <= x < W and 0 <= y < H:
		col[(x, y)] = c


def letter(ch, ox, oy, s, shades, wet=True):
	"""Lettre à l'échelle s, remplie comme un coup de pinceau : reflet en haut, ombre en bas,
	quelques poils de pinceau plus clairs."""
	g = G[ch]
	h = 7 * s
	bristles = {random.randrange(5 * s) for _ in range(max(1, s // 2))}
	for gy, row in enumerate(g):
		for gx, v in enumerate(row):
			if v != '#':
				continue
			for dy in range(s):
				for dx in range(s):
					x, y = ox + gx * s + dx, oy + gy * s + dy
					ly = gy * s + dy
					c = shades[1]
					if ly < h * 0.22:
						c = shades[2]
					elif ly > h * 0.82:
						c = shades[0]
					elif (gx * s + dx) in bristles and wet:
						c = shades[2]
					put(x, y, c)
	return 5 * s


def drip(x, y0, length, shades, w=2):
	for y in range(y0, y0 + length):
		for dx in range(w):
			put(x + dx, y, shades[1] if dx < w - 1 else shades[0])
	# goutte au bout
	for dy in range(-1, 3):
		for dx in range(-1, w + 1):
			if (dx + 0.5 - w / 2) ** 2 + (dy - 0.5) ** 2 <= 3.2:
				put(x + dx, y0 + length + dy, shades[1])
	put(x, y0 + length, shades[2])


def splat(cx, cy, r, c):
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + 0.5:
				put(x, y, c)


# --- Mise en page : PAINT en haut, « UNTIL YOU MAKE » dessous, gros IT à droite
s1, s2, s3 = 5, 2, 9
x0, y0 = 12, 8
gap1 = s1 + 1
paint = [('P', 'feu'), ('A', 'glace'), ('I', 'foudre'), ('N', 'poison'), ('T', 'arcane')]
x = x0
bottoms = []
for ch, el in paint:
	w = letter(ch, x, y0, s1, SH[el])
	bottoms.append((x, w, el))
	x += w + gap1
paint_end = x - gap1
yl2 = y0 + 7 * s1 + 7
x = x0 + 2
for ch in "UNTIL YOU MAKE":
	if ch == ' ':
		x += 3 * s2
		continue
	w = letter(ch, x, yl2, s2, SH['papier'], wet=False)
	x += w + s2
line2_end = x - s2
it_x = max(paint_end, line2_end) + 10
it_h = 7 * s3
it_y = y0 + (yl2 + 7 * s2 - y0 - it_h) // 2
w = letter('I', it_x, it_y, s3, SH['feu'])
t_x = it_x + w + s3
# le T : « en train d'être dessiné » : le bas du pied n'est pas encore peint
letter('T', t_x, it_y, s3, SH['glace'])
stem_x0 = t_x + 2 * s3
unfinished = it_y + 7 * s3 - int(1.6 * s3)
for yy in range(unfinished, it_y + 7 * s3):
	for xx in range(stem_x0, stem_x0 + s3):
		col.pop((xx, yy), None)

# --- Coulures sous PAINT et sous le I
for (lx, lw, el) in bottoms:
	for k in range(random.choice([1, 2])):
		dx = random.randrange(0, lw - 2)
		ybot = y0 + 7 * s1
		# la coulure part d'un pixel peint du bas de la lettre
		if (lx + dx, ybot - 1) in col:
			drip(lx + dx, ybot, random.randint(2, 4), SH[el])
drip(it_x + 4 * s3 - 3, it_y + 7 * s3, 12, SH['feu'], 3)
drip(it_x + s3, it_y + 7 * s3, 6, SH['feu'])

# --- Éclaboussures
for cx, cy, r, el in [(6, 14, 2, 'feu'), (3, 22, 1, 'feu'), (paint_end + 4, 10, 2, 'arcane'), (paint_end + 6, 4, 1, 'arcane'),
		(x0 + 40, yl2 + 18, 1, 'glace'), (it_x - 5, it_y + 3, 1, 'foudre')]:
	splat(cx, cy, r, SH[el][1])

# --- Contour : encre noire épaisse (2 px) puis liseré blanc (1 px), façon autocollant
img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
filled = set(col)
ink = set()
for (x, y) in filled:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if abs(dx) + abs(dy) <= 3 and (x + dx, y + dy) not in filled:
				ink.add((x + dx, y + dy))
rim = set()
for (x, y) in ink:
	for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		p = (x + dx, y + dy)
		if p not in filled and p not in ink:
			rim.add(p)
for (x, y) in rim:
	if 0 <= x < W and 0 <= y < H:
		img.putpixel((x, y), WHITE + (255,))
for (x, y) in ink:
	if 0 <= x < W and 0 <= y < H:
		img.putpixel((x, y), INK + (255,))
for (x, y), c in col.items():
	img.putpixel((x, y), c + (255,))

# --- Le crayon, en diagonale, sa mine au bout du pied du T (là où ça reste à peindre)
tip = (stem_x0 + s3 + 1, unfinished + 1)
# trait de graphite frais : le pied du T esquissé au crayon
for yy in range(unfinished, it_y + 7 * s3):
	img.putpixel((stem_x0, yy), INK + (255,))
	img.putpixel((stem_x0 + s3 - 1, yy), INK + (255,))
for xx in range(stem_x0, stem_x0 + s3):
	img.putpixel((xx, it_y + 7 * s3 - 1), INK + (255,))
for yy in range(unfinished, it_y + 7 * s3 - 1):
	for xx in range(stem_x0 + 1, stem_x0 + s3 - 1):
		img.putpixel((xx, yy), (0x8c, 0xc4, 0xf2, 70))   # « pas encore peint » : bleu très léger

L = 40.0   # longueur du crayon (le long de la diagonale, en px)
R = 4.2    # demi-épaisseur
YEL = SH['foudre']
import math
pix = img.load()
pencil = {}
for y in range(H):
	for x in range(W):
		a = ((x - tip[0]) + (y - tip[1])) / math.sqrt(2)   # le long du crayon (0 = mine)
		b = ((x - tip[0]) - (y - tip[1])) / math.sqrt(2)   # en travers
		if a < 0 or a > L:
			continue
		half = min(R, a * 0.55) if a < 8 else R          # bout taillé en cône
		if abs(b) > half:
			continue
		if a < 2.5:
			c = INK                                         # mine
		elif a < 8:
			c = (0xe8, 0xc0, 0x8a) if b < half - 1.2 else (0xc0, 0x90, 0x5a)   # bois taillé
		elif a < L - 8:
			c = YEL[2] if b < -1.6 else (YEL[1] if b < 1.6 else YEL[0])        # corps jaune, reflet / ombre
		elif a < L - 5:
			c = (0xd8, 0xd8, 0xe4) if b < 0 else (0x98, 0x98, 0xa8)             # bague en métal
		else:
			c = (0xf8, 0xb0, 0xc0) if b < 0 else (0xe0, 0x70, 0x90)             # gomme
		pencil[(x, y)] = c
for (x, y), c in pencil.items():
	pix[x, y] = c + (255,)
for (x, y) in list(pencil):
	for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		p = (x + dx, y + dy)
		if p not in pencil and 0 <= p[0] < W and 0 <= p[1] < H:
			pix[p] = INK + (255,)
# l'épaisseur des pans coupés entre bois et corps
# recadrage + agrandissement net
bbox = img.getbbox()
img = img.crop((bbox[0] - 2, bbox[1] - 2, bbox[2] + 2, bbox[3] + 2))
out = sys.argv[1] if len(sys.argv) > 1 else "docs/logo.png"
for scale, suffix in [(6, ''), (2, '_petit')]:
	img.resize((img.width * scale, img.height * scale), Image.NEAREST).save(out.replace('.png', suffix + '.png'))
print(img.size)
