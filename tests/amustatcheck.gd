extends Node
## Vérifie que les amulettes à plusieurs stats donnent bien tout ce que dit leur description.


func _ready() -> void:
	Meta.no_save = true
	Run.start(0, 1)
	var img := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(4, 4, 8, 8), Pal.INK)
	Run.set_character(Image.create_empty(32, 32, false, Image.FORMAT_RGBA8), "")
	var base := Stats.player(Run)
	var bad := 0
	for id in ["plume", "piece", "chevalet", "colle", "encre_sympathique", "trefle", "lame", "gomme", "mine_plomb", "sceau"]:
		Run.amulets = []
		Run.set_amulet_art(id, img, "")
		Run.add_amulet(id, img, Vector2i(-99, -99))
		var st := Stats.player(Run)
		var diff := []
		for k in ["speed", "dodge", "armor", "harvest", "luck", "dmg", "range", "lifesteal", "thorns", "max_hp", "crit", "crit_mult", "atk_speed", "regen"]:
			var d: float = st[k] - base[k]
			var z: Dictionary = AmuletDB.ZONES[Run.amulets[0].zone]
			if z.stat == k:
				d -= z.v
			if absf(d) > 0.001:
				diff.append("%s %+.1f" % [k, d])
		print("AMU %-18s %s   ← %s" % [id, ", ".join(diff), AmuletDB.describe(AmuletDB.get_def(id))])
	get_tree().quit()
