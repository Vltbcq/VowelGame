extends Node
## Capture : écran titre et choix de sauvegarde (nom du jeu).
## Godot --path . res://tests/titleshot.tscn -- <titre.png> <sauvegardes.png> [<titre_vide.png>]
## (3e image : sans aucun dessin, l'expo « en cours d'installation »)


func _ready() -> void:
	Meta.no_save = true
	var args := OS.get_cmdline_user_args()
	var t := TitleScreen.new()
	add_child(t)
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if args.size() > 0:
		get_viewport().get_texture().get_image().save_png(args[0])
	t.queue_free()
	var s := ChoiceScreens.slots()
	add_child(s)
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if args.size() > 1:
		get_viewport().get_texture().get_image().save_png(args[1])
	if args.size() > 2:
		s.queue_free()
		Meta.data = Meta.data.duplicate(true)
		Meta.data.gallery = []
		var e := TitleScreen.new()
		add_child(e)
		await get_tree().create_timer(2.5).timeout   # les déménageurs ont avancé
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[2])
	print("WINDOW TITLE : ", ProjectSettings.get_setting("application/config/name"))
	get_tree().quit()
