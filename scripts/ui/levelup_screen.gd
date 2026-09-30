class_name LevelUpScreen
extends Control
## Montée de niveau : choisis 1 bonus parmi 3. Tu dessineras ensuite une marque sur ton perso.
## done(upgrade) avec upgrade = {stat, v, rar, text}

signal done(result)

var choices: Array = []


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	UI.fill_bg(self)
	if Run.levelup_choices.is_empty():
		Run.levelup_choices = Run.roll_upgrades()
	choices = Run.levelup_choices
	(func(): Tips.show(self, "levelup")).call_deferred()
	UI.put(self, UI.label("NIVEAU %d !" % (Run.level - Run.pending_levels + 1), 40, Pal.GOOD, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 24), Vector2(640, 48))
	var sub := "Choisis un bonus parmi les trois."
	UI.put(self, UI.label(sub, 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 80), Vector2(640, 14))
	if Run.pending_levels > 1:
		UI.put(self, UI.label("Encore %d niveau(x) après celui-ci" % (Run.pending_levels - 1), 10, Pal.DIM, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 96), Vector2(640, 14))
	for i in choices.size():
		var u: Dictionary = choices[i]
		var rc: Color = Pal.RARITY[u.rar]
		var p := UI.panel(Pal.PANEL, rc, 2)
		UI.put(self, p, Vector2(60 + i * 180, 130), Vector2(160, 150))
		UI.put(p, UI.label(Pal.RARITY_NAMES[u.rar], 10, rc, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 10), Vector2(160, 12))
		if u.get("pact", false):
			UI.put(p, UI.label("PACTE : bonus doublé, mais...", 10, Pal.BAD, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 24), Vector2(160, 12))
		var big: bool = String(u.text).length() <= 16
		var l := UI.label(u.text, 20 if big else 10, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.put(p, l, Vector2(8, 44), Vector2(144, 66))
		var up: Dictionary = u
		UI.put(p, UI.button("Choisir", func(): done.emit(up)), Vector2(30, 116), Vector2(100, 20))
