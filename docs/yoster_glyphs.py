"""Ajoute à Yoster Island les caractères du jeu qui lui manquent, dessinés dans son style

(pixels de 85 unités, traits de 2 pixels) : ( ) / % · ◆ ● → × — ’ « » ✓ ♥ ★ ⌛ − ≥ ° ≈ ← ÷ ↔ _ œ Œ ë Ë.

Usage : python docs/yoster_glyphs.py docs/YosterIsland_original.ttf assets/fonts/YosterIsland.ttf

(pip install fonttools)"""

import sys

from fontTools.ttLib import TTFont

from fontTools.pens.ttGlyphPen import TTGlyphPen



PX = 85

GLYPHS = {   # caractère : (nom, rangée du haut au-dessus de la ligne de base, dessin)

	'(': ('parenleft', 7, ["..##", ".##.", "##..", "##..", "##..", "##..", ".##.", "..##"]),

	')': ('parenright', 7, ["##..", ".##.", "..##", "..##", "..##", "..##", ".##.", "##.."]),

	'/': ('slash', 7, ["....##", "...##.", "...##.", "..##..", "..##..", ".##...", ".##...", "##...."]),

	'%': ('percent', 6, ["##...##", "##..##.", "...##..", "..##...", ".##..##", "##...##"]),

	'·': ('periodcentered', 4, ["##", "##"]),

	'◆': ('uni25C6', 6, ["..##..", ".####.", "######", "######", ".####.", "..##.."]),

	'●': ('uni25CF', 6, [".####.", "######", "######", "######", "######", ".####."]),

	'→': ('uni2192', 6, ["...##..", "....##.", "#######", "#######", "....##.", "...##.."]),

	'×': ('multiply', 5, ["##..##", ".####.", "..##..", ".####.", "##..##"]),

	'—': ('emdash', 4, ["########", "########"]),

	'’': ('quoteright', 7, ["##", "##", ".#"]),

	'«': ('guillemotleft', 5, ["...##.##", "..##.##.", ".##.##..", "..##.##.", "...##.##"]),

	'»': ('guillemotright', 5, ["##.##...", ".##.##..", "..##.##.", ".##.##..", "##.##..."]),

	'✓': ('uni2713', 6, [".....##", "....##.", "##.##..", ".###...", "..#...."]),

	'♥': ('heart', 6, [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]),

	'★': ('uni2605', 7, ["...#...", "..###..", "#######", ".#####.", "..###..", ".##.##.", "##...##"]),

	'⌛': ('uni231B', 6, ["######", ".#..#.", "..##..", "..##..", ".#..#.", "######"]),

	'−': ('minus', 4, ["######", "######"]),

	'≥': ('greaterequal', 6, ["##....", "..##..", "....##", "..##..", "##....", "", "######"]),

	'°': ('degree', 7, [".##.", "#..#", "#..#", ".##."]),

	'≈': ('approxequal', 5, [".##..#", "#..##.", "", ".##..#", "#..##."]),

	'←': ('arrowleft', 6, ["..##...", ".##....", "#######", "#######", ".##....", "..##..."]),

	'÷': ('divide', 5, ["..##..", "", "######", "", "..##.."]),

	'↔': ('arrowboth', 6, ["..##..##..", ".##....##.", "##########", "##########", ".##....##.", "..##..##.."]),

	'_': ('underscore', 0, ["######"]),

	# Yoster remplace ces signes par des icônes (étoile, croix de manette...) : on remet de vrais signes
	'+': ('plus.jeu', 6, ["..##..", "..##..", "######", "######", "..##..", "..##.."]),
	'<': ('less.jeu', 6, ["...##", "..##.", ".##..", "##...", ".##..", "..##.", "...##"]),
	'>': ('greater.jeu', 6, ["##...", ".##..", "..##.", "...##", "..##.", ".##..", "##..."]),
	'*': ('asterisk.jeu', 7, ["#.#.#", ".###.", "#####", ".###.", "#.#.#"]),
	'#': ('numbersign.jeu', 6, [".##.##.", "#######", ".##.##.", "#######", ".##.##."]),
	'&': ('ampersand.jeu', 7, [".##...", "#..#..", ".##...", "#..#.#", "#...#.", ".###.#"]),
	'[': ('bracketleft.jeu', 7, ["###", "##.", "##.", "##.", "##.", "##.", "##.", "###"]),
	']': ('bracketright.jeu', 7, ["###", ".##", ".##", ".##", ".##", ".##", ".##", "###"]),
	'|': ('bar.jeu', 7, ["##", "##", "##", "##", "##", "##", "##", "##"]),
	'<lc>': ('dieresis_lc', 8, ["##.##"]),       # points du ë (même place que ceux du ä)

	'<uc>': ('dieresis_uc', 9, ["##.##"]),    # points du Ë

}

# Composés : glyphes déjà présents mis côte à côte (œ, Œ) ou avec des points (ë, Ë)

COMPOSITES = {

	'œ': ('oe', [('o', 0), ('e', 'adv_o')]),

	'Œ': ('OE', [('O', 0), ('E', 'adv_O')]),

	'ë': ('edieresis', [('e', 0), ('dieresis_lc', 0)]),

	'Ë': ('Edieresis', [('E', 0), ('dieresis_uc', 0)]),

}



src, dst = sys.argv[1], sys.argv[2]

f = TTFont(src)

order = f.getGlyphOrder()

glyf = f['glyf']

hmtx = f['hmtx']

for ch, (name, top, rows) in GLYPHS.items():

	pen = TTGlyphPen(None)

	w = max(len(r) for r in rows)

	for i, row in enumerate(rows):

		y = (top - i) * PX

		x = 0

		while x < len(row):

			if row[x] != '#':

				x += 1

				continue

			x2 = x

			while x2 < len(row) and row[x2] == '#':

				x2 += 1

			x0, x1 = (x + 1) * PX, (x2 + 1) * PX   # 1 pixel d'approche à gauche

			pen.moveTo((x0, y)); pen.lineTo((x0, y + PX)); pen.lineTo((x1, y + PX)); pen.lineTo((x1, y)); pen.closePath()

			x = x2

	if name not in order:

		order.append(name)

	glyf[name] = pen.glyph()

	glyf[name].recalcBounds(glyf)

	hmtx[name] = ((w + 2) * PX, PX)

	if len(ch) > 1:

		continue   # glyphe interne (pas de caractère)

	for t in f['cmap'].tables:

		if t.isUnicode():

			t.cmap[ord(ch)] = name



cmap = f.getBestCmap()

for ch, (name, parts) in COMPOSITES.items():

	pen = TTGlyphPen(glyf)

	adv = 0

	for base, dx in parts:

		gname = cmap[ord(base)] if len(base) == 1 else base

		if dx == 'adv_o' or dx == 'adv_O':

			dx = hmtx[cmap[ord(dx[-1])]][0] - PX

		pen.addComponent(gname, (1, 0, 0, 1, dx, 0))

		adv = max(adv, dx + hmtx[gname][0])

	if name not in order:

		order.append(name)

	glyf[name] = pen.glyph()

	hmtx[name] = (adv, 0)

	for t in f['cmap'].tables:

		if t.isUnicode():

			t.cmap[ord(ch)] = name

f.setGlyphOrder(order)

f['maxp'].numGlyphs = len(order)

f['hhea'].numberOfHMetrics = len(hmtx.metrics)

f.save(dst)

print('ok', len(GLYPHS), 'caractères ajoutés')

