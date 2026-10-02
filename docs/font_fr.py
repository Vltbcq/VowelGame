"""Usage : python docs/font_fr.py docs/Stonckarish.otf assets/fonts/Stonckarish_fr.otf  (pip install fonttools)
Adapte Stonckarish.otf au jeu : accents retirés (é → e, À → A...), et symboles du jeu ajoutés
dans le style de la police (pixels de 64 unités, 8 de haut). Usage : python font_fr.py <src.otf> <dst.otf>"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.transformPen import TransformPen

src, dst = sys.argv[1], sys.argv[2]
f = TTFont(src)
cmap = f.getBestCmap()
gs = f.getGlyphSet()
cff = f['CFF '].cff
top = cff.topDictIndex[0]
cs = top.CharStrings
order = f.getGlyphOrder()
PX = 64

# --- 1) Accents : la lettre accentuée prend le glyphe de la lettre de base
STRIP = {
	'àâäáã': 'a', 'éèêë': 'e', 'îïíì': 'i', 'ôöóò': 'o', 'ùûüú': 'u', 'ç': 'c', 'ÿ': 'y', 'ñ': 'n',
	'ÀÂÄÁÃ': 'A', 'ÉÈÊË': 'E', 'ÎÏÍÌ': 'I', 'ÔÖÓÒ': 'O', 'ÙÛÜÚ': 'U', 'Ç': 'C', 'Ÿ': 'Y', 'Ñ': 'N',
	'’‘': "'", '«»“”': '"', '−–': '-',
}
new_map = {}
for chars, base in STRIP.items():
	for ch in chars:
		new_map[ord(ch)] = cmap[ord(base)]


def add_glyph(name, rows, adv=None, y_top=7):
	"""Glyphe dessiné en pixels : rows = liste de chaînes ('#' = pixel), la 1re rangée est en haut.
	y_top = rangée (depuis la ligne de base) de la 1re ligne."""
	w = max(len(r) for r in rows)
	pen = T2CharStringPen(0, None)
	for i, row in enumerate(rows):
		y = (y_top - i) * PX
		x = 0
		while x < len(row):
			if row[x] == '#':
				x2 = x
				while x2 < len(row) and row[x2] == '#':
					x2 += 1
				x0p, x1p = (x + 1) * PX, (x2 + 1) * PX
				pen.moveTo((x0p, y)); pen.lineTo((x1p, y)); pen.lineTo((x1p, y + PX)); pen.lineTo((x0p, y + PX)); pen.closePath()
				x = x2
			else:
				x += 1
	advance = adv if adv is not None else (w + 2) * PX
	pen_cs = pen.getCharString(private=top.Private, globalSubrs=cff.GlobalSubrs)
	_register(name, pen_cs, advance)


def _register(name, charstring, advance):
	if name not in cs.charStrings:
		cs.charStrings[name] = len(cs.charStringsIndex)
		cs.charStringsIndex.append(charstring)
		top.charset.append(name)
		order.append(name)
	else:
		cs.charStringsIndex[cs.charStrings[name]] = charstring
	f['hmtx'].metrics[name] = (advance, 0)


def add_ligature(name, a, b):
	"""Œ / œ : les deux glyphes l'un après l'autre (un peu rapprochés)."""
	pen = T2CharStringPen(0, None)
	ga, gb = cmap[ord(a)], cmap[ord(b)]
	adv_a = f['hmtx'][ga][0] - PX
	gs[ga].draw(pen)
	gs[gb].draw(TransformPen(pen, (1, 0, 0, 1, adv_a, 0)))
	_register(name, pen.getCharString(private=top.Private, globalSubrs=cff.GlobalSubrs), adv_a + f['hmtx'][gb][0])


SYM = {
	'·': ('uni00B7', ["", "", "", "##", "##"]),
	'•': ('uni2022', ["", "", "###", "###", "###"]),
	'×': ('uni00D7', ["", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"]),
	'÷': ('uni00F7', ["", "..#..", "", "#####", "", "..#.."]),
	'●': ('uni25CF', [".####.", "######", "######", "######", "######", ".####."]),
	'◆': ('uni25C6', ["...#...", "..###..", ".#####.", "#######", ".#####.", "..###..", "...#..."]),
	'♥': ('uni2665', [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]),
	'★': ('uni2605', ["...#...", "...#...", "#######", ".#####.", "..###..", ".##.##.", "##...##"]),
	'✓': ('uni2713', ["......##", ".....##.", "#...##..", "##.##...", ".###....", "..#....."]),
	'→': ('uni2192', ["", "....#..", "....##.", "#######", "....##.", "....#.."]),
	'←': ('uni2190', ["", "..#....", ".##....", "#######", ".##....", "..#...."]),
	'↔': ('uni2194', ["", "..#...#..", ".##...##.", "#########", ".##...##.", "..#...#.."]),
	'—': ('uni2014', ["", "", "", "#########"]),
	'°': ('uni00B0', [".##.", "#..#", "#..#", ".##."]),
	'⌛': ('uni231B', ["######", "#....#", ".#..#.", "..##..", ".#..#.", "#.##.#", "######"]),
	'…': ('uni2026', ["", "", "", "", "", "##.##.##", "##.##.##"]),
}
for ch, (name, rows) in SYM.items():
	add_glyph(name, rows, y_top=7 if ch not in '—·' else 7)
	new_map[ord(ch)] = name
add_ligature('oe', 'o', 'e')
add_ligature('OE', 'O', 'E')
new_map[ord('œ')] = 'oe'
new_map[ord('Œ')] = 'OE'

f.setGlyphOrder(order)
f['maxp'].numGlyphs = len(order)
f['hhea'].numberOfHMetrics = len(f['hmtx'].metrics)
for t in f['cmap'].tables:
	if t.isUnicode():
		for cp, g in new_map.items():
			if t.format in (4,) and cp > 0xFFFF:
				continue
			t.cmap[cp] = g
f.save(dst)
print('ok', len(new_map), 'codes ajoutés')
