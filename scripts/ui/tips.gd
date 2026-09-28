class_name Tips
extends RefCounted
## Tutoriel par conseils contextuels : chaque conseil n'apparaît qu'une fois, au moment
## où le joueur découvre la mécanique. Désactivable dans les options.

const TEXT := {
	"welcome": ["Bienvenue dans Vowel !",
		"Ici, tu dessines TOUT : ton perso, tes armes, tes balles, tes amulettes... et même tes ennemis.\n\nChaque trait change tes stats. Survis à 15 vagues de monstres (un boss toutes les 5 vagues) pour gagner.\n\nQuelques conseils vont apparaître au fil de ta première partie."],
	"draw_perso": ["Dessine ton perso",
		"• Seuls les TRAITS coûtent de l'encre : le contour d'une forme. Remplir l'intérieur (outil Remplir, touche F) est gratuit !\n• Gros perso = plus de PV, mais plus lent et plus facile à toucher. Petit = rapide mais fragile.\n• Symétrique = esquive, traits fins = critique.\n\nRegarde l'APERÇU à droite : il se met à jour à chaque trait. Clic droit = gomme, Ctrl+Z = défaire."],
	"colors": ["Les couleurs = les éléments",
		"Chaque couleur a un élément : rouge = Feu, bleu = Glace, jaune = Foudre...\n\n• Sur ton perso : une résistance et un bonus (dégâts, armure, vitesse d'attaque...).\n• Sur une arme : un effet (brûlure, gel, éclairs...). Plus il y a de pixels d'une couleur, plus l'effet se déclenche souvent.\n• 3 armes du même élément = une SYNERGIE."],
	"draw_weapon": ["Dessine ton arme",
		"Dessine-la POINTÉE VERS LA DROITE : c'est ce côté qui vise les ennemis.\n\n• Petite arme = coups très rapides + critique + plus d'effets élémentaires.\n• Grosse arme = gros coups, plus d'allonge, de zone et de recul.\nLes dégâts par seconde restent proches : c'est un choix de style.\n\nCe dessin servira pour toutes les copies de ce type d'arme."],
	"draw_bullet": ["Dessine tes balles",
		"• Chaque MORCEAU séparé devient un projectile : 5 petits points = une rafale de 5 balles !\n• Grosses balles = tirs lents et forts, petites = mitraillette.\n• Une balle allongée transperce les ennemis."],
	"draw_enemy": ["Dessine un ennemi",
		"Oui, tu dessines aussi tes ennemis !\n\n• Plus tu mets d'encre, plus il a de PV... mais plus il lâche de butin.\n• Sa couleur dominante devient son élément : il te fait des dégâts de cet élément et y résiste.\n\nIl est gardé dans ton CARNET pour les prochaines parties. « Au hasard » dessine un monstre pour toi."],
	"draw_amulet": ["Dessine ton amulette",
		"Plus tu mets d'encre, plus son effet est fort (jusqu'à ×1,5).\nChaque amulette a un bonus ET un défaut : choisis-les selon ton build.\n\nEnsuite tu la poseras où tu veux sur ton perso : l'endroit donne un bonus en plus."],
	"draw_mark": ["Dessine une marque",
		"En montant de niveau, tu peux dessiner une marque sur ton perso (tatouage, cicatrice...).\nElle ne compte PAS dans ta taille : tu ne deviens ni plus gros ni plus lent.\n\nPlus le bonus est rare, plus elle peut être grande. « Passer » si tu ne veux pas dessiner."],
	"carnet": ["Réutilise tes dessins",
		"Avant chaque dessin, le jeu te propose d'abord :\n• ton DERNIER dessin pour cet objet (à gauche) ;\n• tes dessins de la GALERIE qui conviennent (à droite).\n\nUn clic et c'est réglé. « Dessiner » ou « Nouveau » si tu veux un nouveau dessin. Dans l'écran de dessin, « < Choix » revient ici."],
	"arrange": ["Pose tes armes",
		"Clique pour poser ton arme n'importe où sur ou autour de ton perso : elle attaquera depuis là.\nClique une arme déjà posée pour la déplacer. R = tourner, M = miroir.\n\nTu pourras réorganiser tes armes à tout moment depuis la boutique (« Ranger mes armes »)."],
	"amulet_zones": ["Pose ton amulette",
		"L'endroit où tu la poses donne un bonus en plus :\nTête = critique, Cœur = PV, Mains = vitesse d'attaque, Pieds = vitesse, et autour du perso (Aura) = pourboire.\nR = tourner, M = miroir."],
	"controls": ["C'est parti !",
		"• ZQSD / WASD / flèches (ou manette) pour bouger.\n• Tes armes attaquent TOUTES SEULES l'ennemi le plus proche.\n• Ramasse les gouttes d'encre : elles donnent de l'or et de l'expérience.\n• Tes PV ne remontent PAS entre les vagues : fais attention !\n\nÉchap = pause · Molette = zoom. Survis jusqu'à la fin du chrono !"],
	"levelup": ["Niveau supérieur !",
		"Choisis 1 bonus parmi 3. Sa couleur indique sa rareté.\nLes « PACTES » donnent un bonus doublé... mais font baisser un autre attribut.\n\nPlus tu montes de niveau, plus les bonus rares apparaissent."],
	"shop": ["La boutique",
		"• Achète des armes (max 6) et des amulettes. Un « ? » = pas encore dessiné.\n• Les potions (quand il y en a) sont ta seule façon de te soigner.\n• Relancer coûte de plus en plus cher à chaque fois.\n• 2 armes identiques = FUSION en une arme plus rare.\n• Tout devient plus cher au fil des vagues : dépense bien !"],
	"end": ["Fin de partie",
		"Tu gagnes des PIGMENTS ◆ à chaque partie, même en perdant.\n\nDépense-les dans l'ATELIER (menu principal) : nouvelles couleurs, plus d'encre, outils de dessin, effets animés..."],
	"atelier": ["L'Atelier",
		"Ici tu débloques des choses pour tes prochaines parties.\nConseil : commence par le PACK PRIMAIRE (rouge, bleu, jaune) : les couleurs ouvrent les éléments et les synergies."],
	# Bandeaux pendant les vagues (non bloquants)
	"hint_hazard": ["", "Les flaques d'encre te ralentissent, et les traits frais d'un Gribouille font mal !"],
	"hint_boss": ["", "Un BOSS ! La vague se termine quand il meurt. Suis la grosse flèche rouge s'il sort de l'écran."],
	"hint_lowhp": ["", "PV bas ! Ils ne remontent pas entre les vagues : cherche une potion en boutique."],
	"hint_elite": ["", "Un ÉLITE (aura dorée) : 3× plus de PV, mais 3× plus de butin."],
}


static func enabled() -> bool:
	return bool(Meta.setting("tips"))


static func seen(id: String) -> bool:
	return bool(Meta.data.get("tips_seen", {}).get(id, false))


static func mark(id: String) -> void:
	if not Meta.data.has("tips_seen"):
		Meta.data.tips_seen = {}
	Meta.data.tips_seen[id] = true
	Meta.save()


static func reset() -> void:
	Meta.data.tips_seen = {}
	Meta.save()


## Affiche un conseil (une seule fois) par-dessus `parent`. Plusieurs conseils s'enchaînent.
## pause_game : met le jeu en pause pendant la lecture (pendant une vague).
static func show(parent: Control, id: String, pause_game := false) -> void:
	if not enabled() or seen(id) or not TEXT.has(id):
		return
	var q: _TipOverlay = parent.get_node_or_null("TipOverlay")
	if q == null:
		q = _TipOverlay.new()
		q.name = "TipOverlay"
		q.pause_game = pause_game
		q.queue_tip(id)          # AVANT add_child : _ready affiche le premier conseil
		parent.add_child(q)
	else:
		q.queue_tip(id)


class _TipOverlay extends Control:
	var queue: Array[String] = []
	var pause_game := false
	var box: Control

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		# Taille de l'écran entier, quel que soit le parent : le conseil bloque TOUS les clics derrière lui
		position = Vector2.ZERO
		size = get_viewport_rect().size
		mouse_filter = Control.MOUSE_FILTER_STOP
		process_mode = Node.PROCESS_MODE_ALWAYS
		z_index = 100
		if pause_game:
			get_tree().paused = true
		_next()

	## Les raccourcis clavier de l'écran derrière (chiffres de la boutique...) sont bloqués ;
	## seuls ceux du conseil (Compris !) passent, car ils sont traités avant.
	func _shortcut_input(ev: InputEvent) -> void:
		if ev is InputEventKey:
			get_viewport().set_input_as_handled()

	func _unhandled_input(ev: InputEvent) -> void:
		if ev is InputEventKey:
			get_viewport().set_input_as_handled()

	func queue_tip(id: String) -> void:
		if id in queue:
			return
		queue.append(id)
		if is_inside_tree() and box == null:
			_next()

	func _next() -> void:
		if box:
			box.queue_free()
			box = null
		if queue.is_empty():
			if pause_game:
				get_tree().paused = false
			queue_free()
			return
		var id: String = queue.pop_front()
		Tips.mark(id)
		box = Control.new()
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(box)
		UI.fill_bg(box, Color(0, 0, 0, 0.55))
		var t: Array = Tips.TEXT[id]
		var body := UI.label(t[1], 10, Pal.TEXT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var w := 420.0
		body.custom_minimum_size = Vector2(w - 28, 0)
		# Hauteur réelle du texte avec la police pixel (+ interligne), pour que rien ne déborde
		var ts := UI.font.get_multiline_string_size(t[1], HORIZONTAL_ALIGNMENT_LEFT, w - 28, 10)
		var lines := String(t[1]).count("\n") + 1 + int(ts.x > w - 28)
		var text_h := ts.y + lines * 2.0 + 10.0
		var h := minf(340.0, 90.0 + text_h)
		var p := UI.panel(Pal.BG, Pal.ACCENT, 2)
		UI.put(box, p, Vector2((640 - w) / 2.0, (360 - h) / 2.0), Vector2(w, h))
		UI.put(p, UI.label("CONSEIL", 10, Pal.DIM), Vector2(14, 8))
		UI.put(p, UI.label(t[0], 20, Pal.ACCENT), Vector2(14, 20), Vector2(w - 28, 24))
		UI.put(p, body, Vector2(14, 50), Vector2(w - 28, h - 96))
		var ok := UI.hotkey(UI.button("Compris !", _next), [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE])
		UI.put(p, ok, Vector2(w - 124, h - 30), Vector2(110, 20))
		var off := UI.button("Plus de conseils", func():
			Meta.set_setting("tips", false)
			queue.clear()
			_next())
		off.tooltip_text = "Réactivables dans les options"
		UI.put(p, off, Vector2(14, h - 28), Vector2(120, 16))
		Sfx.play("click")
