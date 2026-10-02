"""Logo « Paint It Until You Make It » : on garde EXACTEMENT le logo d'origine (police, plaque noire,
contours) et on ajoute seulement : les lettres peintes aux couleurs des éléments, et un crayon de
couleur en train de peindre le dernier T (le bas du T est encore blanc).
Usage : python docs/logo.py   (lit docs/logo_base.txt, écrit docs/logo.png et docs/logo_petit.png)"""
import math
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
grid_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'logo_base.txt')
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'logo.png')
grid = open(grid_path, encoding='utf-8').read().split('\n')
GW = max(len(r) for r in grid)
grid = [r.ljust(GW) for r in grid]
GH = len(grid)

INK = (0x1a, 0x14, 0x23)
WHITE = (255, 255, 255)
SH = {   # sombre, normale, claire (palette du jeu)
	'feu': [(0x8c, 0x1f, 0x2a), (0xd8, 0x43, 0x3b), (0xf0, 0x8a, 0x5d)],
	'glace': [(0x23, 0x40, 0x7a), (0x3f, 0x7f, 0xd9), (0x8c, 0xc4, 0xf2)],
	'foudre': [(0xb0, 0x7d, 0x1c), (0xf0, 0xc4, 0x3a), (0xfb, 0xe7, 0x9a)],
	'poison': [(0x2c, 0x6b, 0x3a), (0x4f, 0xaa, 0x4c), (0xa4, 0xd8, 0x6a)],
	'arcane': [(0x4d, 0x2a, 0x7a), (0x8c, 0x52, 0xc9), (0xc7, 0x9b, 0xea)],
}

# --- Morceaux blancs (les lettres) : composantes 4-connexes
seen = set()
comps = []
for y in range(GH):
	for x in range(GW):
		if grid[y][x] == 'o' and (x, y) not in seen:
			stack = [(x, y)]
			seen.add((x, y))
			cells = []
			while stack:
				cx, cy = stack.pop()
				cells.append((cx, cy))
				for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
					nx, ny = cx + dx, cy + dy
					if 0 <= nx < GW and 0 <= ny < GH and grid[ny][nx] == 'o' and (nx, ny) not in seen:
						seen.add((nx, ny))
						stack.append((nx, ny))
			comps.append(cells)


def bbox(cells):
	xs = [c[0] for c in cells]
	ys = [c[1] for c in cells]
	return min(xs), min(ys), max(xs), max(ys)


# Les grosses lettres : « Paint » en haut (le point du i rejoint son i), puis I et T à droite.
# Les petites lettres (« until you make ») restent blanches, comme sur le logo d'origine.
top = min(bbox(c)[1] for c in comps)
big = [c for c in comps if bbox(c)[1] < top + 10]   # tout ce qui commence en haut (les petites lettres sont en bas)
big.sort(key=lambda c: bbox(c)[0])
letters = []   # [cells]
for c in big:
	x0, y0, x1, y1 = bbox(c)
	# le point du i : chevauche en x la lettre précédente ou suivante
	host = None
	for k, l in enumerate(letters):
		lx0, ly0, lx1, ly1 = bbox(l)
		if x0 <= lx1 and x1 >= lx0 and (y1 < ly0 or y0 > ly1):
			host = k
	if host is not None:
		letters[host] = letters[host] + c
		continue
	letters.append(c)
# un point du i placé AVANT son i dans le tri : on le rattache à la lettre qui le chevauche
merged = []
for l in letters:
	x0, y0, x1, y1 = bbox(l)
	if merged:
		mx0, my0, mx1, my1 = bbox(merged[-1])
		if x0 <= mx1 and (y1 < my0 or y0 > my1 or (y1 - y0) < 6 or (my1 - my0) < 6):
			merged[-1] = merged[-1] + l
			continue
	merged.append(l)
letters = merged
order = ['feu', 'glace', 'foudre', 'poison', 'arcane', 'feu', 'glace']   # P a i n t  I T
color = {}
for k, cells in enumerate(letters):
	sh = SH[order[k % len(order)]]
	x0, y0, x1, y1 = bbox(cells)
	h = y1 - y0 + 1
	for (x, y) in cells:
		ly = y - y0
		c = sh[1]
		if ly < max(1, round(h * 0.2)):
			c = sh[2]
		elif ly >= h - max(1, round(h * 0.15)):
			c = sh[0]
		color[(x, y)] = c

# --- Le dernier T est en train d'être peint : sous la « ligne de peinture », il reste blanc
t_cells = letters[-1]
tx0, ty0, tx1, ty1 = bbox(t_cells)
paint_y = ty0 + round((ty1 - ty0) * 0.62)
front = {}
for (x, y) in t_cells:
	# bord de peinture un peu irrégulier, comme un coup de crayon
	limit = paint_y + (1 if (x // 2) % 2 == 0 else 0)
	if y > limit:
		color.pop((x, y), None)
	front[x] = max(front.get(x, -1), min(y, limit))

# --- Image native (1 case = 1 px), avec une marge pour le crayon
PAD_R, PAD_B = 22, 4
img = Image.new('RGBA', (GW + PAD_R, GH + PAD_B), (0, 0, 0, 0))
pix = img.load()
for y in range(GH):
	for x in range(GW):
		ch = grid[y][x]
		if ch == '#':
			pix[x, y] = (0, 0, 0, 255)
		elif ch == 'o':
			pix[x, y] = color.get((x, y), WHITE) + (255,)

# --- Crayon de couleur (mine bleue, celle du T), qui part vers le haut à droite (sur la plaque noire),
# la mine posée sur le bord de la peinture, côté droit du pied du T
stem = [x for (x, y) in t_cells if y == paint_y]
tip = (max(stem) - 1, paint_y)
ANG = math.radians(17)
DX, DY = math.cos(ANG), -math.sin(ANG)   # le long du crayon
NX, NY = -DY, DX                         # en travers
L, R = 30.0, 3.4
BLUE = SH['glace']
YEL = SH['foudre']
pencil = {}
for y in range(img.height):
	for x in range(img.width):
		a = (x - tip[0]) * DX + (y - tip[1]) * DY
		b = (x - tip[0]) * NX + (y - tip[1]) * NY
		if a < 0 or a > L:
			continue
		half = min(R, 0.4 + a * 0.5) if a < 7 else R
		if abs(b) > half:
			continue
		if a < 2.2:
			c = BLUE[1] if b < 0.3 else BLUE[0]                              # mine de couleur
		elif a < 7:
			c = (0xe8, 0xc0, 0x8a) if b < half - 1.0 else (0xc0, 0x90, 0x5a)  # bois taillé
		elif a < L - 7:
			c = BLUE[2] if b < -1.2 else (BLUE[1] if b < 1.4 else BLUE[0])   # corps du crayon, bleu
		elif a < L - 4:
			c = (0xd8, 0xd8, 0xe4) if b < 0 else (0x98, 0x98, 0xa8)          # bague en métal
		else:
			c = (0xf8, 0xb0, 0xc0) if b < 0 else (0xe0, 0x70, 0x90)          # gomme
		pencil[(x, y)] = c
for (x, y), c in pencil.items():
	pix[x, y] = c + (255,)
for (x, y) in list(pencil):
	for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		p = (x + dx, y + dy)
		if p not in pencil and 0 <= p[0] < img.width and 0 <= p[1] < img.height:
			pix[p] = INK + (255,)
# petit liseré blanc autour du crayon quand il sort sur le fond transparent
for (x, y) in list(pencil):
	for dx in (-2, -1, 0, 1, 2):
		for dy in (-2, -1, 0, 1, 2):
			p = (x + dx, y + dy)
			if p not in pencil and 0 <= p[0] < img.width and 0 <= p[1] < img.height and pix[p][3] == 0 and abs(dx) + abs(dy) <= 2:
				pix[p] = WHITE + (255,)

bb = img.getbbox()
img = img.crop(bb)
for scale, suffix in [(8, ''), (3, '_petit')]:
	img.resize((img.width * scale, img.height * scale), Image.NEAREST).save(out.replace('.png', suffix + '.png'))
print(img.size, len(letters), 'lettres colorées')
