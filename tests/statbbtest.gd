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
	var c := UI.stat_bbcode("+30% dégâts des familiers · Renvoie les dégâts")
	print(c)
	_check(c.contains("dmg.png") and c.contains("Renvoie les dégâts"), "seulement après un nombre")
	var d := UI.stat_bbcode("+2 épines")
	_check(d == "+2 [img=12x12]res://assets/ui/stats/thorns.png[/img]", "bonus de niveau : « +2 » + icône")
	var e := UI.stat_bbcode("Insensible aux flaques d'encre ennemies")
	_check(e == "Insensible aux flaques d'encre ennemies", "texte sans stat : inchangé")
	print("ICONES TEXTE : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
