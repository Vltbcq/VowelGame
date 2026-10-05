extends Node
## Test : les ennemis tirent leurs stats de leur dessin comme le perso (PV, vitesse, esquive,
## armure en %, dégâts, résistances, à moitié), et leur butin monte avec.
## Godot --headless --path . res://tests/enemystatstest.tscn

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _art(fill_rect: Rect2i, col: Color, ring := false) -> Dictionary:
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(fill_rect, col)
	if ring:
		var r := fill_rect.grow(-2)
		img.fill_rect(r, Color(0, 0, 0, 0))
	return Stats.enemy_art(Analyzer.analyze(img), 160)


func _show(name: String, m: Dictionary) -> void:
	print("%-22s PV×%.2f vit×%.2f esq %d%% arm %d%% dég +%d%% butin×%.2f rés %s" % [name, m.hp, m.speed, roundi(m.dodge), roundi(m.armor), roundi(m.dmg), m.loot, m.res])


func _ready() -> void:
	var red := _art(Rect2i(2, 2, 20, 20), Pal.SHADES[Pal.FEU][1])
	var blue := _art(Rect2i(2, 2, 20, 20), Pal.SHADES[Pal.GLACE][1])
	var white := _art(Rect2i(2, 2, 20, 20), Pal.SHADES[Pal.LUMIERE][1])
	var ring := _art(Rect2i(2, 2, 20, 20), Pal.SHADES[0][1], true)
	var tiny := _art(Rect2i(10, 10, 3, 3), Pal.SHADES[0][1])
	for x in [["carré rouge plein", red], ["carré bleu plein", blue], ["carré blanc plein", white], ["anneau noir", ring], ["petit point noir", tiny]]:
		_show(x[0], x[1])
	_check(red.dmg > 0.0 and red.res[Pal.FEU] > 0.0, "rouge : plus de dégâts et résiste au Feu")
	_check(blue.armor > red.armor, "bleu : plus d'armure")
	_check(white.dodge > red.dodge, "blanc : plus d'esquive")
	_check(ring.armor < red.armor, "anneau (traits fins) : moins d'armure qu'un dessin plein")
	_check(tiny.loot < red.loot and tiny.speed > red.speed, "petit : moins de butin, plus rapide")
	_check(red.armor <= 35.0 and white.dodge <= 20.0 and red.dmg <= 15.0, "valeurs à moitié de celles du perso (armure ≤ 35 %, esquive ≤ 20 %, dégâts ≤ 15 %)")
	_check(red.loot > _art(Rect2i(2, 2, 20, 20), Pal.SHADES[0][1], true).loot, "plus de stats = plus de butin")
	print("ENNEMIS : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
