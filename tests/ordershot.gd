extends Node
## Capture : l'objectif du Carnet de commandes annoncé en début de vague.
## Godot --path . res://tests/ordershot.tscn -- <png>


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var args := OS.get_cmdline_user_args()
	Run.start(0, 1)
	Run.wave = 4
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 16, 16), Pal.SHADES[Pal.FEU][1])
	Run.set_character(img, "")
	for id in EnemyDB.TYPES:
		Run.set_enemy_art(id, img, "")
	Run.set_weapon_art("epee", 0, img, "", null, "")
	Run.add_weapon("epee", 0, 10, Vector2.ZERO)
	var dot := Image.create_empty(6, 6, false, Image.FORMAT_RGBA8)
	dot.fill(Pal.INK)
	Run.set_amulet_art("carnet_commandes", dot, "")
	Run.add_amulet("carnet_commandes", dot, Vector2i(2, 2))
	Run.recompute()
	Run.order = {"kind": "elem", "n": 10, "progress": 0.0, "reward": 35, "done": false, "text": "Tue 10 ennemis touchés par un élément (brûlés, gelés...)"}
	var a := Arena.new()
	add_child(a)
	await get_tree().create_timer(2.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	Run.active = false
	get_tree().quit()
