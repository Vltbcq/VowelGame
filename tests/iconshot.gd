extends Node
## Capture des icônes d'événements de la boutique (agrandies).
## Godot --path . res://tests/iconshot.tscn -- <capture.png>


func _ready() -> void:
	Meta.no_save = true
	var shop := ShopScreen.new()
	var imgs := []
	for k in ["auction", "scratch", "restorer", "patron"]:
		imgs.append(shop._event_icon(k))
	var out := Image.create_empty(4 * 136, 136, false, Image.FORMAT_RGBA8)
	out.fill(Color("efe6cf"))
	for i in imgs.size():
		var im: Image = imgs[i]
		im.resize(128, 128, Image.INTERPOLATE_NEAREST)
		out.blend_rect(im, Rect2i(0, 0, 128, 128), Vector2i(4 + i * 136, 4))
	out.save_png(OS.get_cmdline_user_args()[0])
	shop.free()
	get_tree().quit()
