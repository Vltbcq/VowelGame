"""Ajoute à Yoster Island les caractères du jeu qui lui manquent, dessinés dans son style
(pixels de 85 unités, traits de 2 pixels) : ( ) / % · ◆ ● → × — ’.
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
	for t in f['cmap'].tables:
		if t.isUnicode():
			t.cmap[ord(ch)] = name
f.setGlyphOrder(order)
f['maxp'].numGlyphs = len(order)
f['hhea'].numberOfHMetrics = len(hmtx.metrics)
f.save(dst)
print('ok', len(GLYPHS), 'caractères ajoutés')
