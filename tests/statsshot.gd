extends Node
## Captures : le menu Statistiques (4 onglets), avec un historique inventé (jamais sauvegardé).
## Godot --path . res://tests/statsshot.tscn -- <dossier>


func _ready() -> void:
	Meta.no_save = true
	Meta.data = Meta.data.duplicate(true)
	var args := OS.get_cmdline_user_args()
	var h := []
	var ws := WeaponDB.TYPES.keys()
	var ams := AmuletDB.LIST.map(func(d): return d.id)
	var killers := ["tache", "crachoir", "rature", "gribouille", "tache"]
	for i in 40:
		var win := randf() < 0.3
		h.append({"t": 0, "map": 1, "diff": randi() % 4, "wave": 15 if win else randi_range(3, 14), "win": win,
			"endless": false, "kills": randi_range(80, 600), "damage": randi_range(2000, 40000), "gold": randi_range(100, 900),
			"time": randi_range(300, 1500), "level": randi_range(3, 20), "weapons": [ws.pick_random(), ws.pick_random()],
			"amulets": [ams.pick_random(), ams.pick_random(), ams.pick_random()], "familiars": ["moustique"] if randf() < 0.4 else [],
			"killer": "" if win else killers.pick_random(), "colors": []})
	Meta.data.history = h
	Meta.data.play_time = 36000.0 + 1234.0
	Meta.data.pixels_painted = 123456
	Meta.data.best_endless = 22
	var s := StatsScreen.new()
	add_child(s)
	for tab in ["resume", "parties", "objets", "dessins"]:
		s.tab = tab
		s._build()
		for k in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if args.size() > 0:
			get_viewport().get_texture().get_image().save_png(args[0] + "/stats_%s.png" % tab)
	get_tree().quit()
