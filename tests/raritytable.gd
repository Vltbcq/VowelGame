extends Node
## Mesure (dev) : % de boutiques avec au moins une offre épique / légendaire, selon la vague et la chance.
## Godot --headless --path . res://tests/raritytable.tscn


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	Run.start(0)
	print("boutique avant la vague | chance 0 : épique / légendaire | chance 20 | chance 40")
	for w in range(1, Run.WAVES):
		var line := "%23d |" % (w + 1)
		for luck in [0.0, 20.0, 40.0]:
			Run.wave = w
			Run.stats = {"luck": luck}
			var epi := 0
			var leg := 0
			for i in 2000:
				Run.roll_shop()
				var has := [false, false]
				for o in Run.shop_offers:
					if o.type != "heal" and o.rar == 2:
						has[0] = true
					if o.type != "heal" and o.rar == 3:
						has[1] = true
				epi += int(has[0])
				leg += int(has[1])
			line += "  %3d%% / %3d%%  |" % [epi / 20, leg / 20]
		print(line)
	get_tree().quit()
