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
	var cw := 140.0
	for i in choices.size():
		var u: Dictionary = choices[i]
		var rc: Color = Pal.RARITY[u.rar]
		var p := UI.panel(Pal.PANEL, rc, 2)
		UI.put(self, p, Vector2(20 + i * (cw + 10.0), 130), Vector2(cw, 150))
		UI.put(p, UI.label(Pal.RARITY_NAMES[u.rar], 10, rc, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 10), Vector2(cw, 12))
		if u.get("pact", false):
			UI.put(p, UI.label("PACTE : bonus doublé, mais...", 10, Pal.BAD, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 24), Vector2(cw, 12))
		# Le bonus avec l'icône de la stat à la place du mot (son nom au survol)
		var big: bool = String(u.text).length() <= 14
		var l := UI.rich(u.text, 20 if big else 10, Pal.TEXT, 32 if big else 14, true)
		l.custom_minimum_size.x = cw - 16
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.tooltip_text = "%s : %s" % [StatText.KEY_NAMES.get(String(u.stat), ""), u.text]
		UI.put(p, l, Vector2(8, 44 if big else 40), Vector2(cw - 16, 66))
		var up: Dictionary = u
		UI.put(p, UI.button("Choisir", func(): done.emit(up)), Vector2((cw - 100.0) / 2.0, 116), Vector2(100, 20))
	# Les stats actuelles du perso, pour choisir en connaissance de cause
	var sp := UI.panel(Pal.PANEL, Pal.BORDER, 2)
	UI.put(self, sp, Vector2(474, 112), Vector2(150, 236))
	UI.put(sp, UI.label("TON PERSO", 10, Pal.ACCENT, HORIZONTAL_ALIGNMENT_CENTER), Vector2(0, 6), Vector2(150, 12))
	var stx := StatText.new(2)
	UI.put(sp, stx, Vector2(8, 22), Vector2(136, 208))
	stx.set_text(Stats.describe_player(Run.stats))
