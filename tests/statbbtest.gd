extends Node
## Test : dans les descriptions, les quantités de stats deviennent leurs icônes (« +4 PV max » -> « +4 » + cœur),
## sans toucher aux phrases (« les dégâts des familiers »).
## Godot --headless --path . res://tests/statbbtest.tscn

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	var a := UI.stat_bbcode("+4 PV max, +1 régénération · -5% vitesse")
	print(a)
	_check(a.contains("+4 [img=12x12]res://assets/ui/stats/max_hp.png[/img]") and a.contains("regen.png") and a.contains("-5% [img=12x12]res://assets/ui/stats/move.png"), "PV max, régénération, vitesse en icônes")
	var b := UI.stat_bbcode("+8% vit. d'attaque, +2% critique · -3 PV max")
	print(b)
	_check(b.contains("atk_speed.png") and b.contains("crit.png") and not b.contains("vit. d'attaque"), "vit. d'attaque (avec le point) et critique")
	var c := UI.stat_bbcode("+30% dégâts · Renvoie les dégâts")
	print(c)
	_check(c.contains("dmg.png") and c.contains("Renvoie les dégâts"), "seulement après un nombre")
	var d := UI.stat_bbcode("+2 épines")
	_check(d == "+2 [img=12x12]res://assets/ui/stats/thorns.png[/img]", "bonus de niveau : « +2 » + icône")
	var f := UI.stat_bbcode("Touché : tu lances 6 épines d'encre tout autour (dégâts = épines ×2, min 4)")
	_check(not f.contains("[img"), "Oursin : « 6 épines d'encre » reste du texte")
	var g := UI.stat_bbcode("+12% dégâts de MÊLÉE · -8% dégâts à distance")
	_check(not g.contains("[img"), "Spatule : « dégâts de mêlée / à distance » reste du texte")
	var vi := UI.stat_bbcode("+12% dégâts À DISTANCE · -8% dégâts de mêlée")
	_check(not vi.contains("[img"), "Viseur : « dégâts À DISTANCE / de mêlée » reste du texte")
	var h := UI.stat_bbcode("+35% dégâts contre boss et élites, +30% dégâts des familiers")
	_check(not h.contains("[img"), "dégâts contre… / des… : texte")
	var e := UI.stat_bbcode("Insensible aux flaques d'encre ennemies")
	_check(e == "Insensible aux flaques d'encre ennemies", "texte sans stat : inchangé")
	print("ICONES TEXTE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
