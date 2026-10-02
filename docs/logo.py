"""Logo « Paint It Until You Make It » : on part de l'image d'origine (docs/logo_base.png) SANS toucher
à sa police, sa plaque noire ni ses contours, et on ajoute seulement :
- les grandes lettres (Paint, I, T) peintes aux couleurs des éléments (reflet en haut, ombre en bas) ;
- un crayon de couleur en train de peindre le dernier T (le bas du T est encore blanc).
Usage : python docs/logo.py   (écrit docs/logo.png et docs/logo_petit.png)"""
import math
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'logo_base.png')
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'logo.png')
P = 13.5   # taille d'un « pixel » des grandes lettres dans l'image d'origine

base = Image.open(src).convert('RGBA')
W, H = base.size
src_px = base.load()


def kind(x, y):
	r, g, b, a = src_px[x, y]
	if a < 128:
		return 0          # fond transparent
	return 1 if r < 128 else 2   # 1 plaque noire, 2 lettre blanche


INK = (0x1a, 0x14, 0x23)
WHITE = (255, 255, 255)
SH = {   # sombre, normale, claire (palette du jeu)
	'feu': [(0x8c, 0x1f, 0x2a), (0xd8, 0x43, 0x3b), (0xf0, 0x8a, 0x5d)],
	'glace': [(0x23, 0x40, 0x7a), (0x3f, 0x7f, 0xd9), (0x8c, 0xc4, 0xf2)],
	'foudre': [(0xb0, 0x7d, 0x1c), (0xf0, 0xc4, 0x3a), (0xfb, 0xe7, 0x9a)],
	'poison': [(0x2c, 0x6b, 0x3a), (0x4f, 0xaa, 0x4c), (0xa4, 0xd8, 0x6a)],
	'arcane': [(0x4d, 0x2a, 0x7a), (0x8c, 0x52, 0xc9), (0xc7, 0x9b, 0xea)],
}

# --- Les morceaux blancs (composantes 4-connexes), en pleine résolution
label = [[-1] * W for _ in range(H)]
comps = []   # [x0, y0, x1, y1, n]
for y in range(H):
	for x in range(W):
		if label[y][x] == -1 and kind(x, y) == 2:
			k = len(comps)
			stack = [(x, y)]
			label[y][x] = k
			b = [x, y, x, y, 0]
			while stack:
				cx, cy = stack.pop()
				b[0] = min(b[0], cx); b[1] = min(b[1], cy); b[2] = max(b[2], cx); b[3] = max(b[3], cy); b[4] += 1
				for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
					if 0 <= nx < W and 0 <= ny < H and label[ny][nx] == -1 and kind(nx, ny) == 2:
						label[ny][nx] = k
						stack.append((nx, ny))
			comps.append(b)

# Grandes lettres = celles qui commencent tout en haut (Paint, I, T) ; le point du i rejoint son i.
top = min(c[1] for c in comps if c[4] > 50)
starts_top = [k for k, c in enumerate(comps) if c[4] > 50 and c[1] < top + 3 * P]
# bas de la ligne « Paint » = le bas le plus fréquent parmi les lettres du haut (le I et le T descendent plus bas)
bottoms = sorted(comps[k][3] for k in starts_top)
paint_bottom = bottoms[len(bottoms) // 2]
# + les morceaux qui finissent sur cette ligne (le pied du i, sous son point)
big = sorted(set(starts_top) | {k for k, c in enumerate(comps) if c[4] > 50 and abs(c[3] - paint_bottom) < P * 1.5},
	key=lambda k: comps[k][0])
groups = []   # [[indices], x0, y0, x1, y1]
for k in big:
	x0, y0, x1, y1, n = comps[k]
	for g in groups:
		if x0 <= g[3] and x1 >= g[1]:   # chevauche en x : même lettre (le i et son point)
			g[0].append(k); g[1] = min(g[1], x0); g[2] = min(g[2], y0); g[3] = max(g[3], x1); g[4] = max(g[4], y1)
			break
	else:
		groups.append([[k], x0, y0, x1, y1])
groups.sort(key=lambda g: g[1])
order = ['feu', 'glace', 'foudre', 'poison', 'arcane', 'feu', 'glace']   # P a i n t  I T
comp_letter = {}
for gi, g in enumerate(groups):
	for k in g[0]:
		comp_letter[k] = gi

# Dernier T : peint jusqu'à 60 % de sa hauteur (bord un peu irrégulier, case par case)
tg = groups[-1]
t_rows = round((tg[4] - tg[2] + 1) / P)
paint_row = round(t_rows * 0.6)

img = base.copy()
px = img.load()
for y in range(H):
	for x in range(W):
		k = label[y][x]
		if k < 0 or k not in comp_letter:
			continue
		gi = comp_letter[k]
		g = groups[gi]
		row = int((y - g[2]) / P)                       # rangée de « pixel » dans la lettre
		rows = max(1, round((g[4] - g[2] + 1) / P))
		if gi == len(groups) - 1:
			col = int((x - g[1]) / P)
			if row > paint_row - (1 if col % 3 == 1 else 0):
				continue                                 # pas encore peint : reste blanc
		sh = SH[order[gi % len(order)]]
		c = sh[1]
		if row < max(1, round(rows * 0.2)):
			c = sh[2]
		elif row >= rows - max(1, round(rows * 0.15)):
			c = sh[0]
		px[x, y] = c + (255,)

# --- Crayon de couleur (mine bleue, celle du T), dessiné en « gros pixels » alignés sur le T.
# La mine touche le bord droit du pied du T, à la limite de la peinture ; il part vers le haut à droite.
ox, oy = tg[1], tg[2]                     # origine de la grille du T
paint_y = oy + (paint_row + 1) * P
stem_right = max(x for x in range(tg[1], tg[3] + 1) if label[int(paint_y - P / 2)][x] >= 0 and comp_letter.get(label[int(paint_y - P / 2)][x]) == len(groups) - 1)
C = P * 0.6   # taille d'une case du crayon
tip = ((stem_right - ox) / C - 0.5, (paint_y - oy) / C - 0.5)   # en cases
ANG = math.radians(17)
DX, DY = math.cos(ANG), -math.sin(ANG)
NX, NY = -DY, DX
L, R = 30.0, 3.4
BLUE = SH['glace']


def pencil_at(cx, cy):
	a = (cx - tip[0]) * DX + (cy - tip[1]) * DY
	b = (cx - tip[0]) * NX + (cy - tip[1]) * NY
	if a < 0 or a > L:
		return None
	half = min(R, 0.4 + a * 0.5) if a < 7 else R
	if abs(b) > half:
		return None
	if a < 2.2:
		return BLUE[1] if b < 0.3 else BLUE[0]
	if a < 7:
		return (0xe8, 0xc0, 0x8a) if b < half - 1.0 else (0xc0, 0x90, 0x5a)
	if a < L - 7:
		return BLUE[2] if b < -1.2 else (BLUE[1] if b < 1.4 else BLUE[0])
	if a < L - 4:
		return (0xd8, 0xd8, 0xe4) if b < 0 else (0x98, 0x98, 0xa8)
	return (0xf8, 0xb0, 0xc0) if b < 0 else (0xe0, 0x70, 0x90)


# cases du crayon, puis contour noir (1 case) et liseré blanc (1 case) hors de la plaque
cells = {}
for cy in range(-80, 80):
	for cx in range(-20, 120):
		c = pencil_at(cx + 0.5, cy + 0.5)
		if c:
			cells[(cx, cy)] = c
outline = set()
for (cx, cy) in cells:
	for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		if (cx + dx, cy + dy) not in cells:
			outline.add((cx + dx, cy + dy))
rim = set()
for (cx, cy) in outline:
	for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
		q = (cx + dx, cy + dy)
		if q not in cells and q not in outline:
			rim.add(q)
# agrandit l'image si le crayon dépasse à droite / en haut
xs = [ox + (c[0] + 1) * C for c in rim]
ys = [oy + c[1] * C for c in rim]
pad_r = max(0, int(max(xs)) + 4 - W)
pad_t = max(0, -int(min(ys)) + 4)
if pad_r or pad_t:
	big_img = Image.new('RGBA', (W + pad_r, H + pad_t), (0, 0, 0, 0))
	big_img.paste(img, (0, pad_t))
	img = big_img
	oy += pad_t
	px = img.load()


def fill_cell(c, col, only_transparent=False):
	x0 = int(round(ox + c[0] * C)); x1 = int(round(ox + (c[0] + 1) * C))
	y0 = int(round(oy + c[1] * C)); y1 = int(round(oy + (c[1] + 1) * C))
	for y in range(max(0, y0), min(img.height, y1)):
		for x in range(max(0, x0), min(img.width, x1)):
			if only_transparent and px[x, y][3] > 0:
				continue
			px[x, y] = col + (255,)


for c in rim:
	fill_cell(c, WHITE, only_transparent=True)
for c in outline:
	fill_cell(c, INK)
for c, col in cells.items():
	fill_cell(c, col)

img = img.crop(img.getbbox())
img.save(out)
img.resize((img.width * 2 // 5, img.height * 2 // 5), Image.NEAREST).save(out.replace('.png', '_petit.png'))
print(img.size, len(groups), 'lettres colorées')
