"""Logo « Paint It Until You Make It » : le logo d'origine en noir et blanc (docs/logo_base.txt,
relevé case par case : `#` plaque noire, `o` lettres blanches), où le I de « IT » est remplacé par
un crayon debout, mine en haut, gomme en bas.
Usage : python docs/logo.py   (écrit docs/logo.png et docs/logo_petit.png)"""
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
grid_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, 'logo_base.txt')
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'logo.png')
grid = open(grid_path, encoding='utf-8').read().split('\n')
GW = max(len(r) for r in grid)
grid = [list(r.ljust(GW)) for r in grid]
GH = len(grid)

# --- Trouver le I de « IT » : l'avant-dernier grand morceau blanc qui part du haut
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
				for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
					if 0 <= nx < GW and 0 <= ny < GH and grid[ny][nx] == 'o' and (nx, ny) not in seen:
						seen.add((nx, ny))
						stack.append((nx, ny))
			comps.append(cells)
tall = sorted([c for c in comps if max(y for _, y in c) - min(y for _, y in c) > 20], key=lambda c: min(x for x, _ in c))
i_cells = tall[-2]   # [..., I, T]
ix0 = min(x for x, _ in i_cells); ix1 = max(x for x, _ in i_cells)
iy0 = min(y for _, y in i_cells); iy1 = max(y for _, y in i_cells)
# le pied du I (sa partie la plus étroite) donne le centre du crayon
mid = (iy0 + iy1) // 2
stem = [x for x, y in i_cells if y == mid]
cx = (min(stem) + max(stem)) / 2.0
for (x, y) in i_cells:
	grid[y][x] = '#'   # on efface le I : la plaque noire reprend sa place

# --- Le crayon, debout : mine en haut, gomme en bas
HALF = 6                      # demi-largeur (13 cases)
x0 = round(cx - HALF); x1 = round(cx + HALF)
H = iy1 - iy0 + 1
GRAPH = (0x3d, 0x34, 0x50)
WOOD = [(0xc0, 0x90, 0x5a), (0xe8, 0xc0, 0x8a), (0xf6, 0xdc, 0xb0)]
YEL = [(0xb0, 0x7d, 0x1c), (0xf0, 0xc4, 0x3a), (0xfb, 0xe7, 0x9a)]
METAL = [(0x78, 0x78, 0x88), (0xb8, 0xb8, 0xc8), (0xe8, 0xe8, 0xf0)]
PINK = [(0xc8, 0x50, 0x70), (0xf0, 0x8a, 0xa4), (0xf8, 0xc0, 0xcc)]
paint = {}
tip_h, cone_h, metal_h, eraser_h = 2, 6, 3, 4
for y in range(iy0, iy1 + 1):
	r = y - iy0                  # rangée depuis le haut
	if r < tip_h:
		half = r                  # mine : 1 puis 3 cases
		shades = [GRAPH, GRAPH, (0x6e, 0x67, 0x84)]
	elif r < tip_h + cone_h:
		half = min(HALF, 1 + (r - tip_h + 1) * HALF // cone_h)   # bois taillé qui s'élargit
		shades = WOOD
	elif r < H - metal_h - eraser_h:
		half = HALF
		shades = YEL
	elif r < H - eraser_h:
		half = HALF
		shades = METAL
	else:
		half = HALF - (1 if r == H - 1 else 0)   # gomme aux coins arrondis
		shades = PINK
	for x in range(round(cx - half), round(cx + half) + 1):
		d = x - cx
		if shades is YEL:
			# trois pans du crayon : clair à gauche, normal au milieu, foncé à droite (avec arêtes)
			c = shades[2] if d < -HALF / 3 else (shades[1] if d <= HALF / 3 else shades[0])
			if abs(abs(d) - HALF / 3) < 0.6:
				c = shades[0] if d > 0 else shades[1]
		else:
			c = shades[2] if d < -half / 2 else (shades[1] if d <= half / 2 else shades[0])
		if shades is METAL and (r - (H - metal_h - eraser_h)) == 1:
			c = shades[0]          # rainure de la bague
		paint[(x, y)] = c

# --- Rendu : 1 case = 8 px (comme le logo d'origine), fond transparent
img = Image.new('RGBA', (GW, GH), (0, 0, 0, 0))
pix = img.load()
for y in range(GH):
	for x in range(GW):
		if grid[y][x] == '#':
			pix[x, y] = (0, 0, 0, 255)
		elif grid[y][x] == 'o':
			pix[x, y] = (255, 255, 255, 255)
for (x, y), c in paint.items():
	pix[x, y] = c + (255,)
img = img.crop(img.getbbox())
for scale, suffix in [(8, ''), (3, '_petit')]:
	img.resize((img.width * scale, img.height * scale), Image.NEAREST).save(out.replace('.png', suffix + '.png'))
print(img.size, 'I remplacé par un crayon :', (ix0, iy0, ix1, iy1))
