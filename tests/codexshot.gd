extends Node
## Capture du Bestiaire (onglet et sélection en argument) : -- <capture.png> <onglet> <id> [défilement]


func _ready() -> void:
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	Meta.unlock_all()   # tout visible pour la capture (copie de la sauvegarde, rien n'est écrit)
	var a := OS.get_cmdline_user_args()
	var cx := CodexScreen.new(a[1], a[2])
	cx.size = Vector2(640, 360)
	add_child(cx)
	await get_tree().process_frame
	if a.size() > 3:
		var sc: ScrollContainer = cx.find_children("*", "ScrollContainer", true, false)[0]
		for f in 4:
			await get_tree().process_frame
		sc.scroll_vertical = int(a[3])
		for f in 2:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(a[0])
	get_tree().quit()
