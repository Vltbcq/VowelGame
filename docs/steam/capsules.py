"""Images de la page Steam : capsule d'entête 920 × 430 (logo du jeu dans un cadre de galerie,
entouré de gribouillis du jeu : héros, armes, taches d'encre, crayon).

Usage : python docs/steam/capsules.py   (pip install pillow)
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'docs', 'steam')

WALL, WALL_LINE = (0x3e, 0x18, 0x20), (0x47, 0x1c, 0x25)
GOLD_D, GOLD, GOLD_L = (0x8c, 0x64, 0x14), (0xf0, 0xc4, 0x3a), (0xfb, 0xe7, 0x9a)
PAPER, PAPER_LINE, INK = (0xe9, 0xdc, 0xbc), (0xdb, 0xcb, 0xa6), (0x1a, 0x14, 0x23)

# Gribouillis (1 caractère = 1 pixel du jeu)
PAL = {
	'k': INK, 'w': (0xff, 0xff, 0xff), 'r': (0xd8, 0x43, 0x3b), 'R': (0x8c, 0x1f, 0x2a),
	'b': (0x3f, 0x7f, 0xd9), 'B': (0x8c, 0xc4, 0xf2), 'y': (0xf0, 0xc4, 0x3a), 'Y': (0xfb, 0xe7, 0x9a),
	'g': (0x4f, 0xaa, 0x4c), 'G': (0x2c, 0x6b, 0x3a), 'v': (0x8c, 0x52, 0xc9), 'V': (0x4d, 0x2a, 0x7a),
	'n': (0xc0, 0x90, 0x5a), 'p': (0xf0, 0x8a, 0xa4), 'm': (0x78, 0x78, 0x88), 's': (0x3d, 0x34, 0x50),
}
HERO = [
	"....rrrrr.....",
	"...rrrrrrr....",
	"..rrwkrrwkr...",
	"..rrwkrrwkr...",
	"..rrrrrrrrr...",
	"..rrRkkkkRr...",
	"...rrrrrrr....",
	"....rrrrr.....",
	"...rr...rr....",
	"..rR.....Rr...",
]
SWORD = [
	"..............BB",
	"nn.kbbbbbbbbbbbbB",
	"nnkkbbbbbbbbbbbb.",
	"nn.kbbbbbbbbbbB..",
]
BLOB_V = [
	"...vvvv...",
	".vvvvvvvv.",
	"vvwkvvwkvv",
	"vvwkvvwkvv",
	"vvvvvvvvvv",
	".vVvvvvVv.",
	"v.v.vv.v.v",
]
BLOB_G = [
	"..gggggg..",
	".gggggggg.",
	"ggwwgggwwg",
	"ggkwgggkwg",
	"gggggggggg",
	"gGggGGggGg",
	".g..gg..g.",
]
BLOB_K = [
	"..ssss..",
	".ssssss.",
	"sswkswks",
	"sswkswks",
	"ssssssss",
	"s.ss.s.s",
]
PENCIL = [
	"pp............",
	"ppmyyyyyyyyynk",
	"ppmyyyYYYYYYnnk",
	"ppmyyyyyyyyynk",
	"pp............",
]


def sprite(img, rows, x, y, px, flip=False):
	d = ImageDraw.Draw(img)
	for j, row in enumerate(rows):
		if flip:
			row = row[::-1]
		for i, ch in enumerate(row):
			if ch in PAL:
				d.rectangle([x + i * px, y + j * px, x + (i + 1) * px - 1, y + (j + 1) * px - 1], fill=PAL[ch])


def splat(img, x, y, px, col):
	"""Petite éclaboussure d'encre."""
	sprite(img, ["..k.k..", ".kkkkk.", "kkkkkkk", ".kkkkk.", "..k..k."], x, y, px)


def header():
	W, H = 920, 430
	img = Image.new('RGB', (W, H), WALL)
	d = ImageDraw.Draw(img)
	for x in range(0, W, 16):   # mur de la galerie (rayures)
		d.rectangle([x, 0, x + 5, H], fill=WALL_LINE)
	# Cadre doré
	m = 14
	d.rectangle([m, m, W - m - 1, H - m - 1], fill=GOLD_D)
	d.rectangle([m + 4, m + 4, W - m - 5, H - m - 5], fill=GOLD)
	d.rectangle([m + 4, m + 4, W - m - 5, m + 8], fill=GOLD_L)
	d.rectangle([m + 4, m + 4, m + 8, H - m - 5], fill=GOLD_L)
	d.rectangle([m + 18, m + 18, W - m - 19, H - m - 19], fill=GOLD_D)
	# Papier quadrillé
	x0, y0, x1, y1 = m + 22, m + 22, W - m - 23, H - m - 23
	d.rectangle([x0, y0, x1, y1], fill=PAPER)
	for x in range(x0 + 20, x1, 20):
		d.line([x, y0, x, y1], fill=PAPER_LINE, width=2)
	for y in range(y0 + 20, y1, 20):
		d.line([x0, y, x1, y], fill=PAPER_LINE, width=2)
	# Logo (agrandi au pixel près, centré en haut)
	logo = Image.open(os.path.join(ROOT, 'docs', 'logo_jeu_source.png')).convert('RGBA')
	lw = 660
	lh = round(logo.height * lw / logo.width)
	logo = logo.resize((lw, lh), Image.NEAREST)
	img.paste(logo, ((W - lw) // 2, 62), logo)
	# Gribouillis du jeu sous le logo
	px = 6
	gy = 62 + lh + 34
	sprite(img, HERO, 150, gy - 8, px)
	sprite(img, SWORD, 150 + 9 * px, gy + 4 * px, px)
	sprite(img, BLOB_V, 560, gy - 4, px)
	sprite(img, BLOB_G, 650, gy + 6, px, flip=True)
	sprite(img, BLOB_K, 742, gy - 10, px)
	sprite(img, PENCIL, 52, gy + 64, 5)
	# trait de crayon en pointillés jusqu'au héros
	for k in range(6):
		d.rectangle([128 + k * 16, gy + 74, 128 + k * 16 + 8, gy + 78], fill=INK)
	splat(img, 470, gy + 40, 4, INK)
	splat(img, 845, gy + 50, 3, INK)
	splat(img, 92, 70, 3, INK)
	img.save(os.path.join(OUT, 'capsule_entete_920x430.png'))
	print('capsule_entete_920x430.png', img.size)


if __name__ == '__main__':
	header()
