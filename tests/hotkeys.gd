extends Node
## Test des raccourcis clavier : on simule des touches et on regarde ce que l'écran renvoie.


func _ready() -> void:
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	await get_tree().process_frame
	var res := []
	res.append(["Accueil N", await _press(TitleScreen.new(), KEY_N)])
	res.append(["Accueil Entrée", await _press(TitleScreen.new(), KEY_ENTER)])
	res.append(["Accueil G", await _press(TitleScreen.new(), KEY_G)])
	res.append(["Difficulté 1 (touche physique)", await _press(ChoiceScreens.difficulty(), KEY_1, true)])
	res.append(["Difficulté Échap", await _press(ChoiceScreens.difficulty(), KEY_ESCAPE)])
	res.append(["Arme pavé num 2", await _press(ChoiceScreens.weapon_kind(), KEY_KP_2)])
	res.append(["Fin Espace", await _press(ChoiceScreens.end_run(true, 1), KEY_SPACE)])
	res.append(["Options Échap", await _press(OptionsPanel.new(), KEY_ESCAPE)])
	Run.start(0)
	var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(10, 6, 12, 20), Pal.INK)
	Run.set_character(img, "")
	Run.wave = 2
	Run.recompute()
	res.append(["Niveau 3", await _press(LevelUpScreen.new(), KEY_3, true)])
	Run.new_shop()
	res.append(["Boutique Entrée", await _press(ShopScreen.new(), KEY_ENTER)])
	res.append(["Boutique A", await _press(ShopScreen.new(), KEY_A)])
	res.append(["Bestiaire Échap", await _press(CodexScreen.new("armes"), KEY_ESCAPE)])
	res.append(["Carnet N", await _press(BestiaryPrompt.new(DrawCfg.enemy("tache"), null, 2), KEY_N)])
	res.append(["Dessin Échap", await _press(DrawScreen.new(DrawCfg.weapon("epee", 0, true)), KEY_ESCAPE)])
	for r in res:
		print("TOUCHE %s -> %s" % [r[0], r[1]])
	get_tree().quit()


func _press(scr: Node, key: int, physical := false):
	add_child(scr)
	await get_tree().process_frame
	await get_tree().process_frame
	var got := ["(rien)"]
	scr.done.connect(func(r = null): got[0] = r)
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		if physical:
			ev.physical_keycode = key
		else:
			ev.keycode = key
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
	scr.queue_free()
	await get_tree().process_frame
	return got[0]
