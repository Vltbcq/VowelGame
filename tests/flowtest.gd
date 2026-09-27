extends Node
## Test du parcours « sélection avant dessin » de main.gd (n'écrit rien dans la sauvegarde).


func _ready() -> void:
	Meta.no_save = true   # ne jamais toucher la vraie sauvegarde
	Meta.settings = Meta.settings.duplicate()
	Meta.settings.tips = false
	var main: Node = load("res://scripts/main.gd").new()
	add_child(main)
	await get_tree().process_frame
	Run.start(0)
	var steps := []
	var done_flag := [false]
	var result := [0]
	var run := func():
		result[0] = await main._obtain("__test_key__", DrawCfg.amulet(AmuletDB.get_def("oeil")), 0, "TEST")
		done_flag[0] = true
	run.call()
	for i in 6:
		await get_tree().process_frame
		var cur: Node = main.current
		if done_flag[0]:
			break
		if cur is BestiaryPrompt:
			steps.append("sélection")
			cur.done.emit({"a": "draw"} if steps.count("sélection") == 1 else {"a": "cancel"})
		elif cur is DrawScreen:
			steps.append("dessin (bouton %s)" % cur.cfg.cancel_label)
			cur.done.emit(null)
	print("FLOW : ", " -> ".join(steps), " -> résultat = ", result[0])
	get_tree().quit()
