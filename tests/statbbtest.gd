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
	var c := UI.stat_bbcode("+30% dégâts · Renvoie 5 dégâts au contact")
	print(c)
	_check(c.contains("dmg.png") and c.contains("5 dégâts au contact"), "« dégâts au contact » : texte")
	var d := UI.stat_bbcode("+2 épines")
	_check(d == "+2 [img=12x12]res://assets/ui/stats/thorns.png[/img]", "bonus de niveau : « +2 » + icône")
	var f := UI.stat_bbcode("Touché : tu lances 6 épines d'encre tout autour (dégâts = épines ×2, min 4)")
	print(f)
	_check(f.contains("6 épines d'encre") and f.contains("= [img=12x12]res://assets/ui/stats/thorns.png[/img] ×2"), "Oursin : « 6 épines d'encre » en texte, « = épines ×2 » en icône")
	var ca := UI.stat_bbcode("Épines +25% de ton armure")
	print(ca)
	_check(ca.begins_with("[img") and ca.contains("ton [img=12x12]res://assets/ui/stats/armor.png"), "Carapace : « Épines » et « ton armure » en icônes")
	var he := UI.stat_bbcode("Tes épines frappent EN CONTINU les ennemis collés à toi")
	_check(he.begins_with("Tes [img"), "Hérisson : « Tes épines » en icône")
	var pa := UI.stat_bbcode("+2% dégâts par niveau atteint · +3% vit. d'attaque pendant 3 s")
	_check(pa.contains("dmg.png") and pa.contains("atk_speed.png"), "« par » et « pendant » : icônes (c'est ta stat)")
	var mp := UI.stat_bbcode("Critiques +0.5 (×2 → ×2,5), +3% critique")
	_check(mp.begins_with("Critiques +0.5") and mp.contains("crit.png"), "Mine de plomb : « Critiques » (puissance) en texte")
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
