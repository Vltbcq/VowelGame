extends "res://scripts/main.gd"
## Test : Échap partout (titre → sauvegardes, sauvegardes → quitter, sinon les options),
## volumes séparés musique / bruitages, et les dessins qui se baladent devant le menu.

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("OK   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _esc() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _ready() -> void:   # (pas le vrai menu)
	Meta.no_save = true
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	# Volumes
	_check(AudioServer.get_bus_index(Meta.BUS_MUSIC) >= 0 and AudioServer.get_bus_index(Meta.BUS_SFX) >= 0, "bus Musique et Bruitages créés")
	_check(Sfx.music_players[0].bus == Meta.BUS_MUSIC and Sfx.players[0].bus == Meta.BUS_SFX, "musique et bruitages branchés chacun sur leur bus")
	Meta.set_setting("music_volume", 0.25, false)
	_check(absf(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Meta.BUS_MUSIC))) - 0.25) < 0.01, "le réglage Musique change le volume de la musique")
	# Titre : Échap → retour au choix de la sauvegarde
	var res := []
	var t := TitleScreen.new()
	_swap(t)
	t.done.connect(func(r): res.append(r))
	await get_tree().process_frame
	await _esc()
	_check(res == ["slots"], "titre : Échap ramène au choix de la sauvegarde (%s)" % str(res))
	_check(t.parade.z_index > 0, "les dessins qui se baladent passent devant le menu")
	# Sauvegardes : Échap → quitter (avec confirmation, gérée par main)
	res.clear()
	var s := ChoiceScreens.slots()
	_swap(s)
	s.done.connect(func(r): res.append(r))
	await get_tree().process_frame
	await _esc()
	_check(res.size() == 1 and res[0].a == "quit", "sauvegardes : Échap = Quitter le jeu (%s)" % str(res))
	# Écran sans retour (niveau) : Échap ouvre les options par-dessus, Échap les referme
	Run.start(0, 1)
	var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(6, 6, 12, 12), Pal.SHADES[1][1])
	Run.set_character(img, "")
	Run.recompute()
	var lu := LevelUpScreen.new()
	_swap(lu)
	await get_tree().process_frame
	await _esc()
	_check(is_instance_valid(_esc_panel), "niveau : Échap ouvre les options")
	await _esc()
	await get_tree().process_frame
	_check(not is_instance_valid(_esc_panel) or _esc_panel.is_queued_for_deletion(), "Échap referme les options")
	Run.active = false
	print("ECHAP : %d échec(s)" % fails)
	get_tree().quit(1 if fails else 0)
