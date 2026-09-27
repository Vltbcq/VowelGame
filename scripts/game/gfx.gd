class_name Gfx
extends RefCounted
## Transforme les dessins en sprites (marge pour le contour + shader).

const FX_ID := {"": 0, "pulse": 1, "rainbow": 2, "shimmer": 3}
static var shader: Shader = preload("res://shaders/sprite.gdshader")


## Ajoute 1px de marge transparente pour que le contour tienne dans la texture.
static func padded(img: Image) -> Image:
	var s := img.get_size()
	var out := Image.create_empty(s.x + 2, s.y + 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, s), Vector2i(1, 1))
	return out


## Applique miroir puis rotation (quarts de tour horaires). Renvoie une copie.
static func transformed(img: Image, rot: int, flip: bool) -> Image:
	var out := img.duplicate()
	if flip:
		out.flip_x()
	for i in posmod(rot, 4):
		out.rotate_90(CLOCKWISE)
	return out


## Ajoute un contour noir de 1px autour du dessin, dans l'image elle-même
## (pour les amulettes collées sur le perso). L'image doit avoir 1px de marge libre.
static func baked_outline(img: Image) -> Image:
	var s := img.get_size()
	var out := Image.create_empty(s.x + 2, s.y + 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, s), Vector2i(1, 1))
	var src := out.duplicate()
	for y in s.y + 2:
		for x in s.x + 2:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < s.x + 2 and q.y < s.y + 2 and src.get_pixelv(q).a > 0.5:
					out.set_pixel(x, y, Color("1a1423"))
					break
	return out


## Petites icônes dessinées à la main pour l'interface.
const ICON_UNKNOWN := [
	"................",
	".....######.....",
	"....##....##....",
	"...##......##...",
	"...##......##...",
	"....#......##...",
	"..........##....",
	".........##.....",
	"........##......",
	".......##.......",
	".......##.......",
	".......#........",
	"................",
	".......##.......",
	".......##.......",
	"................",
]
const ICON_POTION := [
	"......cccc......",
	"......#cc#......",
	"......#..#......",
	".....##..##.....",
	"....#......#....",
	"...#........#...",
	"..#.w........#..",
	"..#w.........#..",
	"..#llllllllll#..",
	"..#llllllllll#..",
	"..#llllllwlll#..",
	"..#dlllllllld#..",
	"...#dllllllb#...",
	"....########....",
	"................",
	"................",
]


static func icon(rows: Array, liquid := Color("4faa4c")) -> Image:
	var pal := {"#": Color("1a1423"), "w": Color.WHITE, "c": Color("b07d1c"),
		"l": liquid, "d": liquid.darkened(0.3), "b": liquid.darkened(0.3)}
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if pal.has(row[x]):
				img.set_pixel(x, y, pal[row[x]])
	return img


static func texture(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(padded(img))


static func material(effect: String, outline := true) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("effect", FX_ID.get(effect, 0))
	m.set_shader_parameter("outline", outline)
	return m


static func sprite(tex: Texture2D, mat: ShaderMaterial) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.material = mat
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s
