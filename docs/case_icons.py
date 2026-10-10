"""Icônes des caisses de « Case opening » (bois, argent, or, diamant × armes / amulettes), en pixel
art 32 × 32 dans la DA du jeu : une vraie caisse vue de 3/4 (dessus, face, côté), planches ou
plaques, renforts aux coins, fermoir, un gros emblème peint sur la face (épée ou pendentif) et
des éclats autour des caisses d'or et de diamant. Contour d'encre d'1 pixel.

Usage : python docs/case_icons.py [planche.png]
  - écrit assets/ui/cases/case_<rang>_<weapon|amulet>.png (rang 0 à 3)
  - avec un chemin : une planche d'aperçu (icônes agrandies ×6 sur le fond de la boutique)
(pip install pillow)
"""
import os
import sys
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "cases")
N = 32
INK = (0x1a, 0x14, 0x23, 255)


def rgb(h):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


# matière : face, dessus (clair), côté (sombre), rainures, renforts, rivets, reflet
TIERS = [
    {"face": "c0905a", "top": "dcb27a", "side": "8a5a2a", "line": "7a4c20", "iron": "8a8f9c", "rivet": "d8dce6", "shine": None},
    {"face": "c2cad4", "top": "e8edf2", "side": "858d98", "line": "767e8a", "iron": "5a6270", "rivet": "f4f6f8", "shine": "f4f7fa"},
    {"face": "e8b53a", "top": "fbe38c", "side": "b07d1c", "line": "9a6a12", "iron": "8c5a10", "rivet": "fff2b8", "shine": "fff3c4"},
    {"face": "7fe0ee", "top": "d2f8fc", "side": "38a3bd", "line": "2c8ba4", "iron": "eefcff", "rivet": "ffffff", "shine": "f2feff"},
]

# géométrie (3/4 vu d'en haut à gauche)
FX0, FX1 = 3, 24      # face : colonnes
FY0, FY1 = 12, 28     # face : lignes
DX, DY = 4, 5         # décalage du fond (vers la droite et le haut)


def crate(tier):
    t = {k: (rgb(v) if v else None) for k, v in TIERS[tier].items()}
    img = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    top = [(FX0, FY0), (FX1, FY0), (FX1 + DX, FY0 - DY), (FX0 + DX, FY0 - DY)]
    side = [(FX1, FY0), (FX1 + DX, FY0 - DY), (FX1 + DX, FY1 - DY), (FX1, FY1)]
    d.polygon(top, fill=t["top"])
    d.polygon(side, fill=t["side"])
    d.rectangle([FX0, FY0, FX1, FY1], fill=t["face"])
    # planches / plaques : rainures horizontales sur la face, qui tournent sur le côté
    for y in (FY0 + 5, FY0 + 11):
        d.line([(FX0 + 1, y), (FX1 - 1, y)], fill=t["line"])
        d.line([(FX1 + 1, y - 1), (FX1 + DX - 1, y - DY + 1)], fill=t["line"])
    # dessus : une rainure dans la longueur
    d.line([(FX0 + 3, FY0 - 2), (FX1 + 2, FY0 - 2)], fill=t["line"])
    # reflet en biais sur la face (métaux et diamant)
    if t["shine"]:
        for k in range(5):
            d.point((FX0 + 2 + k, FY0 + 6 - k), fill=t["shine"])
            d.point((FX0 + 3 + k, FY0 + 6 - k), fill=t["shine"])
        d.line([(FX0 + 6, FY0 - 4), (FX0 + 11, FY0 - 4)], fill=t["shine"])
    if tier == 3:
        # facettes du diamant : grands traits clairs en biais
        for x in (FX1 - 9, FX1 - 5):
            d.line([(x, FY1 - 2), (x + 5, FY1 - 7)], fill=t["shine"])
    # renforts aux quatre coins de la face, avec un rivet
    for cx, cy in ((FX0, FY0), (FX1 - 3, FY0), (FX0, FY1 - 3), (FX1 - 3, FY1 - 3)):
        d.rectangle([cx, cy, cx + 3, cy + 3], fill=t["iron"])
        d.point((cx + 1 + (1 if cx > FX0 else 0), cy + 1 + (1 if cy > FY0 else 0)), fill=t["rivet"])
    # contours d'encre
    d.line(top + [top[0]], fill=INK)
    d.line(side + [side[0]], fill=INK)
    d.rectangle([FX0, FY0, FX1, FY1], outline=INK)
    # fermoir sur l'arête du couvercle
    fx = (FX0 + FX1) // 2
    d.rectangle([fx - 1, FY0 - 2, fx + 2, FY0 + 1], fill=INK)
    d.rectangle([fx, FY0 - 1, fx + 1, FY0], fill=rgb("f0c43a") if tier != 2 else rgb("fff2b8"))
    return img, t


def emblem(img, kind, t):
    """Gros emblème peint sur la face : épée (armes) ou pendentif (amulettes)."""
    d = ImageDraw.Draw(img)
    ox, oy = FX0 + 6, FY0 + 4   # coin de la zone 11 × 11
    light = t["top"]
    if kind == "weapon":
        # une épée droite, pointe en haut, parfaitement symétrique au milieu de la face :
        # lame large (contour d'encre, cœur clair), garde épaisse, poignée et pommeau
        cx = (FX0 + FX1) // 2          # l'axe passe entre les colonnes cx et cx+1
        y0 = FY0 + 3                   # pointe (juste sous le fermoir)
        d.rectangle([cx, y0, cx + 1, y0], fill=INK)                    # pointe
        d.rectangle([cx - 1, y0 + 1, cx + 2, y0 + 6], fill=INK)        # lame
        d.rectangle([cx, y0 + 1, cx + 1, y0 + 6], fill=light)
        d.rectangle([cx - 4, y0 + 7, cx + 5, y0 + 8], fill=INK)        # garde
        d.rectangle([cx - 3, y0 + 7, cx + 4, y0 + 7], fill=rgb("f0c43a"))
        d.rectangle([cx, y0 + 7, cx + 1, y0 + 7], fill=INK)
        d.rectangle([cx, y0 + 9, cx + 1, y0 + 10], fill=INK)           # poignée
        d.rectangle([cx - 1, y0 + 11, cx + 2, y0 + 12], fill=INK)      # pommeau
        d.rectangle([cx, y0 + 11, cx + 1, y0 + 11], fill=rgb("f0c43a"))
    else:
        # chaîne en V, puis la pierre taillée en losange
        d.line([(ox + 1, oy), (ox + 5, oy + 4)], fill=INK)
        d.line([(ox + 9, oy), (ox + 5, oy + 4)], fill=INK)
        d.point((ox + 1, oy), fill=INK)
        cx, cy = ox + 5, oy + 7
        d.polygon([(cx, cy - 4), (cx + 4, cy), (cx, cy + 4), (cx - 4, cy)], fill=INK)
        d.polygon([(cx, cy - 2), (cx + 2, cy), (cx, cy + 2), (cx - 2, cy)], fill=light)
        d.point((cx - 1, cy - 1), fill=(255, 255, 255, 255))


def sparkles(img, tier):
    """Éclats autour des caisses d'or et de diamant."""
    if tier < 2:
        return
    d = ImageDraw.Draw(img)
    col = rgb("fff3c4") if tier == 2 else rgb("ffffff")
    for x, y, big in ((2, 5, True), (29, 27, False), (28, 2, True)) if tier == 3 else ((2, 5, True), (29, 27, False)):
        r = 2 if big else 1
        d.line([(x - r, y), (x + r, y)], fill=col)
        d.line([(x, y - r), (x, y + r)], fill=col)
        d.point((x, y), fill=(255, 255, 255, 255))


def make(tier, kind):
    img, t = crate(tier)
    emblem(img, kind, t)
    sparkles(img, tier)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    icons = []
    for tier in range(4):
        for kind in ("weapon", "amulet"):
            im = make(tier, kind)
            im.save(os.path.join(OUT, "case_%d_%s.png" % (tier, kind)))
            icons.append(im)
    if len(sys.argv) > 1:
        z = 6
        sheet = Image.new("RGBA", (4 * (N * z + 16) + 16, 2 * (N * z + 16) + 16), rgb("4a1f2c"))
        for i, im in enumerate(icons):
            tier, k = divmod(i, 2)
            big = im.resize((N * z, N * z), Image.NEAREST)
            sheet.alpha_composite(big, (16 + tier * (N * z + 16), 16 + k * (N * z + 16)))
        sheet.save(sys.argv[1])
        print(sys.argv[1])


if __name__ == "__main__":
    main()
