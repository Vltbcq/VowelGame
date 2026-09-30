extends Node
## Progression permanente entre les parties : pigments, déblocages, galerie de dessins.
## 3 SAUVEGARDES : chacune a sa progression, sa galerie, son Bestiaire et sa partie en cours.
## La sauvegarde 1 garde les emplacements historiques (user://vowel_save.json, user://gallery...),
## les 2 et 3 sont dans user://slot2/ et user://slot3/. Les réglages sont communs (settings.json).

const SLOTS := 3
const RUN_SCRIPT := preload("res://scripts/autoload/run.gd")
const GALLERY_MAX_PER_KIND := 60

const DIFFICULTIES := [
	{"name": "Esquisse", "desc": "Déjà pas facile.", "hp": 1.0, "dmg": 1.0, "spawn": 1.0, "reward": 1.0},
	{"name": "Croquis", "desc": "Ennemis plus coriaces. Les élites arrivent.", "hp": 1.3, "dmg": 1.2, "spawn": 1.15, "reward": 1.3},
	{"name": "Aquarelle", "desc": "Plus d'ennemis, plus rapides. Les tireurs visent où tu vas.", "hp": 1.7, "dmg": 1.45, "spawn": 1.3, "reward": 1.6},
	{"name": "Huile", "desc": "Les ennemis frappent très fort. Élites à pouvoirs, taches qui ralentissent.", "hp": 2.2, "dmg": 1.75, "spawn": 1.45, "reward": 2.0},
	{"name": "Chef-d'œuvre", "desc": "Seuls les vrais artistes survivent. Les boss entrent en fureur.", "hp": 2.9, "dmg": 2.1, "spawn": 1.6, "reward": 2.5},
]

const DEFAULT_SETTINGS := {"volume": 0.8, "fullscreen": false, "speed": 1.0, "zoom": 1.5, "tips": true}

var data := {}
var settings := {}
var slot := 1
var root := "user://"       # dossier des sauvegardes (les tests le redirigent vers un dossier temporaire)
var no_save := false        # tests : interdit toute écriture de la sauvegarde / galerie / carnet


func _ready() -> void:
	_load_settings()
	slot = clampi(int(settings.get("slot", 1)), 1, SLOTS)
	load_data()
	apply_settings()


# ------------------------------------------------------------------ Emplacements de sauvegarde

func slot_dir(n := -1) -> String:
	n = slot if n < 0 else n
	return root if n == 1 else root + "slot%d/" % n


func settings_path() -> String:
	return root + "settings.json"


func save_path(n := -1) -> String:
	return slot_dir(n) + "vowel_save.json"


func run_path(n := -1) -> String:
	return slot_dir(n) + "run_save.dat"


func gallery_dir(n := -1) -> String:
	return slot_dir(n) + "gallery"


func bestiary_dir(n := -1) -> String:
	return slot_dir(n) + "bestiary"


## Change de sauvegarde (et s'en souvient pour le prochain lancement).
func select_slot(n: int) -> void:
	slot = clampi(n, 1, SLOTS)
	settings["slot"] = slot
	_save_settings()
	load_data()


func slot_exists(n: int) -> bool:
	return FileAccess.file_exists(save_path(n))


## Résumé d'une sauvegarde sans la charger : {} si elle est vide.
func slot_summary(n: int) -> Dictionary:
	if not slot_exists(n):
		return {}
	var d := _read_json(save_path(n))
	var out := {"pigments": int(d.get("pigments", 0)), "runs": int(d.get("runs", 0)), "wins": int(d.get("wins", 0)),
		"best_wave": int(d.get("best_wave", 0)), "drawings": (d.get("gallery", []) as Array).size()}
	var r := read_run(n)
	if not r.is_empty():
		out.run = "Vague %d · %s" % [int(r.wave), DIFFICULTIES[int(r.difficulty)].name]
	return out


## Efface une sauvegarde : progression, partie en cours, galerie et Bestiaire.
func delete_slot(n: int) -> void:
	if no_save:
		return
	for f in [save_path(n), run_path(n)]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	for dir in [gallery_dir(n), bestiary_dir(n)]:
		var da := DirAccess.open(dir)
		if da == null:
			continue
		for f in da.get_files():
			if f.get_extension() == "png":
				DirAccess.remove_absolute(dir + "/" + f)
	if n == slot:
		load_data()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


# ------------------------------------------------------------------ Partie en cours (reprise)

func has_run() -> bool:
	return FileAccess.file_exists(run_path())


## Fichier texte lisible (journal de partie). Jamais pendant les tests.
func write_text(path: String, text: String) -> void:
	if no_save:
		return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)


func save_run(state: Dictionary) -> void:
	if no_save:
		return
	var f := FileAccess.open(run_path(), FileAccess.WRITE)
	if f:
		f.store_var(state)


func read_run(n := -1) -> Dictionary:
	var p := run_path(n)
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var v = f.get_var()
	return v if v is Dictionary else {}


func clear_run() -> void:
	if no_save:
		return
	if FileAccess.file_exists(run_path()):
		DirAccess.remove_absolute(run_path())


func default_data() -> Dictionary:
	return {"pigments": 0, "unlocks": {}, "gallery": [], "best_wave": 0, "max_diff": 0,
		"runs": 0, "wins": 0, "next_id": 1, "achievements": {}, "total_kills": 0, "pending_unlocks": []}


func load_data() -> void:
	data = default_data()
	var parsed := _read_json(save_path())
	for k in parsed:
		data[k] = parsed[k]
	data.erase("settings")   # les réglages sont communs aux sauvegardes (settings.json)
	# Anciennes sauvegardes : couleurs achetées une par une -> packs
	var u: Dictionary = data.unlocks
	for old in ["col_rouge", "col_bleu", "col_jaune"]:
		if u.has(old):
			u["pack_primaires"] = 1
	for old in ["col_vert", "col_violet", "col_blanc"]:
		if u.has(old):
			u["pack_secondaires"] = 1
	u.erase("tool_fill")
	_retro_achievements()
	data.erase("zoom")
	if not no_save:
		DirAccess.make_dir_recursive_absolute(gallery_dir())
		DirAccess.make_dir_recursive_absolute(bestiary_dir())


# ------------------------------------------------------------------ Réglages

func setting(key: String):
	return settings.get(key, DEFAULT_SETTINGS[key])


func set_setting(key: String, value, persist := true) -> void:
	settings[key] = value
	if persist:
		_save_settings()
	apply_settings()


## Réglages communs. Première fois : on reprend ceux de l'ancienne sauvegarde unique.
func _load_settings() -> void:
	settings = _read_json(settings_path())
	if settings.is_empty():
		var old := _read_json(root + "vowel_save.json")
		settings = (old.get("settings", {}) as Dictionary).duplicate()
		if old.has("zoom"):
			settings["zoom"] = old.zoom


## Au lancement du jeu : crée settings.json s'il n'existe pas encore (migration des réglages).
func ensure_settings_file() -> void:
	if not FileAccess.file_exists(settings_path()):
		settings["slot"] = slot
		_save_settings()


func _save_settings() -> void:
	if no_save:
		return
	var f := FileAccess.open(settings_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings, "\t"))


func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, float(setting("volume")))))
	# On ne touche à la fenêtre que si le plein écran change : une fenêtre agrandie (maximisée)
	# n'est pas « fenêtrée », et la repasser en fenêtré la rétrécissait (ex. à chaque cran de zoom).
	var fs := bool(setting("fullscreen"))
	var cur := DisplayServer.window_get_mode()
	var is_fs := cur == DisplayServer.WINDOW_MODE_FULLSCREEN or cur == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fs and not is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not fs and is_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func save() -> void:
	if no_save:
		return
	DirAccess.make_dir_recursive_absolute(gallery_dir())
	DirAccess.make_dir_recursive_absolute(bestiary_dir())
	var f := FileAccess.open(save_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


# ------------------------------------------------------------------ Déblocages

func level(id: String) -> int:
	return int(data.unlocks.get(id, 0))


func has(id: String) -> bool:
	return id == "" or level(id) > 0


func next_cost(id: String) -> int:
	var def := UnlockDB.get_def(id)
	var lv := level(id)
	if def.is_empty() or lv >= def.cost.size():
		return -1
	return int(def.cost[lv])


func buy(id: String) -> bool:
	if not UnlockDB.for_pigments(UnlockDB.get_def(id)):
		return false   # se débloque par un succès
	var c := next_cost(id)
	if c < 0 or int(data.pigments) < c:
		return false
	var req: String = UnlockDB.get_def(id).get("req", "")
	if req != "" and not has(req):
		return false
	data.pigments = int(data.pigments) - c
	data.unlocks[id] = level(id) + 1
	save()
	return true


func pigments() -> int:
	return int(data.pigments)


func base_ink() -> int:
	return 120 + 25 * level("ink")


## Pigments minimum gagnés par partie : on débloque vite le pack primaire.
const MIN_PIGMENTS := 6


func weapon_ink_bonus() -> int:
	return 10 * level("ink")


func canvas_bonus() -> int:
	return 8 * level("canvas")


## Éléments (couleurs) disponibles. Le noir est toujours là.
func elements() -> Array:
	var out := [0]
	for e in range(1, Pal.COUNT):
		if has(Pal.UNLOCK[e]):
			out.append(e)
	return out


func effects() -> Array:
	var out := [""]
	for fx in Stats.EFFECT_UNLOCK:
		if has(Stats.EFFECT_UNLOCK[fx]):
			out.append(fx)
	return out


# ------------------------------------------------------------------ Succès

## OUTIL DE DEV : débloque tout sur la sauvegarde (objets, succès, Atelier au max, cartes, difficultés).
func unlock_all() -> void:
	if not data.has("item_unlocks"):
		data.item_unlocks = {}
	for key in ItemUnlockDB.CONDS:
		data.item_unlocks[key] = true
	if not data.has("achievements"):
		data.achievements = {}
	for a in AchievementDB.LIST:
		data.achievements[a.id] = true
	for u in UnlockDB.LIST:
		data.unlocks[u.id] = (u.cost as Array).size()
	var top := DIFFICULTIES.size() - 1
	var m: Dictionary = data.get("max_diff_map", {})
	for id in MapDB.MAPS:
		data.unlocks["map%d" % id] = 1
		m[str(id)] = top
	data.max_diff_map = m
	data.max_diff = top
	data.pending_unlocks = []
	save()


## Arme / amulette disponible ? (pas de condition, ou succès obtenu et partie terminée)
func item_open(key: String) -> bool:
	return not ItemUnlockDB.CONDS.has(key) or bool(data.get("item_unlocks", {}).get(key, false))


## Arme / amulette déjà croisée en boutique (sinon : « ! » sur son tableau).
func item_seen(key: String) -> bool:
	return bool(data.get("seen_items", {}).get(key, false))


func mark_seen(key: String) -> void:
	if not data.has("seen_items"):
		data.seen_items = {}
	data.seen_items[key] = true


func achieved(id: String) -> bool:
	return bool(data.get("achievements", {}).get(id, false))


## Succès obtenu pendant la partie en cours : son amélioration n'arrive qu'à la fin.
func pending(id: String) -> bool:
	return id in data.get("pending_unlocks", [])


## Fin de partie (victoire, défaite, abandon, partie remplacée) : applique les améliorations
## des succès obtenus pendant la partie. Retourne leurs ids (pour le récapitulatif).
func apply_pending_unlocks() -> Array:
	var out: Array = (data.get("pending_unlocks", []) as Array).duplicate()
	for id in out:
		if String(id).begins_with("w:") or String(id).begins_with("a:"):
			if not data.has("item_unlocks"):
				data.item_unlocks = {}
			data.item_unlocks[id] = true
			continue
		var a := AchievementDB.get_def(id)
		if not a.is_empty() and level(a.unlock) == 0:
			data.unlocks[a.unlock] = 1
	data.pending_unlocks = []
	if not out.is_empty():
		save()
	return out


## Anciennes sauvegardes : les succès déjà mérités (record, victoires, galerie) ou dont
## l'amélioration a déjà été achetée sont cochés, sans notification.
func _retro_achievements() -> void:
	if not data.has("achievements"):
		data.achievements = {}
	var wins := int(data.get("wins", 0))
	# (Run est chargé après Meta : on lit la constante dans le script, pas sur le nœud)
	var ctx := {"cleared": mini(int(data.get("best_wave", 0)), RUN_SCRIPT.WAVES), "win": wins > 0,
		"diff": int(data.get("max_diff", 0)) - 1, "gallery": (data.gallery as Array).size(),
		"total_kills": int(data.get("total_kills", 0))}
	if wins > 0:
		data.unlocks["map2"] = 1   # déjà gagné une partie : Le Tableau noir est ouvert
	if not data.has("item_unlocks"):
		data.item_unlocks = {}
	var ictx := {"cleared": ctx.cleared, "win": wins > 0, "diff": ctx.diff, "gallery": ctx.gallery,
		"total_kills": ctx.total_kills, "runs": int(data.get("runs", 0)), "bosses": data.get("bosses_beaten", {}),
		"total_elites": int(data.get("total_elites", 0))}
	for key in ItemUnlockDB.CONDS:
		if ItemUnlockDB.met(ItemUnlockDB.CONDS[key], ictx):
			data.item_unlocks[key] = true
	for a in AchievementDB.LIST:
		if achieved(a.id):
			continue
		if level(a.unlock) > 0 or AchievementDB.met(a, ctx):
			data.achievements[a.id] = true
			if level(a.unlock) == 0:
				data.unlocks[a.unlock] = 1


## Vérifie tous les succès avec ce contexte. Pendant une partie, l'amélioration gagnée est mise
## de côté et n'est appliquée qu'à la fin (apply_pending_unlocks) ; hors partie, tout de suite.
func check_achievements(ctx: Dictionary) -> void:
	if not data.has("achievements"):
		data.achievements = {}
	if not data.has("pending_unlocks"):
		data.pending_unlocks = []
	ctx = ctx.duplicate()
	ctx.total_kills = int(data.get("total_kills", 0)) + int(ctx.get("kills", 0))
	ctx.total_elites = int(data.get("total_elites", 0)) + int(ctx.get("elites", 0))
	var bosses: Dictionary = (data.get("bosses_beaten", {}) as Dictionary).duplicate()
	bosses.merge(ctx.get("bosses", {}))
	ctx.bosses = bosses
	ctx.runs = int(data.get("runs", 0)) + (1 if Run.active else 0)
	ctx.gallery = (data.gallery as Array).size()
	var changed := false
	# Succès d'objets (armes / amulettes) : conditions visibles dans le Bestiaire
	if not data.has("item_unlocks"):
		data.item_unlocks = {}
	var fresh := []
	for key in ItemUnlockDB.CONDS:
		if item_open(key) or key in data.pending_unlocks or not ItemUnlockDB.met(ItemUnlockDB.CONDS[key], ctx):
			continue
		changed = true
		fresh.append(key)
		if Run.active:
			data.pending_unlocks.append(key)
		else:
			data.item_unlocks[key] = true
	# Une seule notification, même si plusieurs objets tombent d'un coup
	if not fresh.is_empty():
		var head := "DÉBLOQUÉ À LA FIN DE LA PARTIE" if Run.active else "DÉBLOQUÉ"
		UI.toast(head + "\n" + (ItemUnlockDB.label(fresh[0]) if fresh.size() == 1 else "%d nouveaux objets" % fresh.size()))
	for a in AchievementDB.LIST:
		if achieved(a.id) or not AchievementDB.met(a, ctx):
			continue
		data.achievements[a.id] = true
		var reward: String = UnlockDB.get_def(a.unlock).name
		if Run.active:
			data.pending_unlocks.append(a.id)
			UI.toast("SUCCÈS : %s\n%s : débloqué à la fin de la partie" % [a.name, reward])
		else:
			if level(a.unlock) == 0:
				data.unlocks[a.unlock] = 1
			UI.toast("SUCCÈS : %s\nDébloque : %s" % [a.name, reward])
		changed = true
		Sfx.play("level")
	if changed:
		save()


# ------------------------------------------------------------------ Galerie

func add_to_gallery(kind: String, img: Image, effect: String) -> void:
	if kind in GALLERY_HIDDEN:
		return
	if no_save:
		return
	if Analyzer.count_pixels(img) == 0:
		return
	var h := str(hash(img.get_data()))
	for e in data.gallery:
		if e.kind == kind and e.get("hash", "") == h:
			return
	var id := int(data.next_id)
	data.next_id = id + 1
	var path := "%s/%s_%d.png" % [gallery_dir(), kind, id]
	img.save_png(path)
	data.gallery.append({"id": id, "kind": kind, "file": path, "effect": effect, "hash": h,
		"w": img.get_width(), "h": img.get_height(), "px": Analyzer.count_pixels(img)})
	# On garde les plus récents
	var same: Array = data.gallery.filter(func(e): return e.kind == kind)
	if same.size() > GALLERY_MAX_PER_KIND:
		var old: Dictionary = same[0]
		DirAccess.remove_absolute(old.file)
		data.gallery.erase(old)
	save()
	check_achievements({})


## Dessins qu'on ne garde plus dans la galerie (marques, tirs ennemis : plus utiles).
const GALLERY_HIDDEN := ["mark", "eproj"]


func gallery(kind: String) -> Array:
	var out: Array = data.gallery.filter(func(e): return (e.kind == kind or (kind == "all" and not e.kind in GALLERY_HIDDEN)) and FileAccess.file_exists(e.file))
	out.reverse()
	return out


# ------------------------------------------------------------------ Bestiaire (carnet des ennemis)

## Dessin du carnet pour un ennemi (clé = id, ou id + "_elite"), ou null.
func bestiary_get(key: String):
	var b: Dictionary = data.get("bestiary", {})
	if not b.has(key):
		return null
	var e: Dictionary = b[key]
	if not FileAccess.file_exists(e.file):
		return null
	var img := Image.load_from_file(e.file)
	if img == null:
		return null
	return {"image": img, "effect": e.get("effect", ""), "outline": e.get("outline", false)}


func bestiary_set(key: String, img: Image, effect: String, outline: bool) -> void:
	if no_save:
		return
	if not data.has("bestiary"):
		data.bestiary = {}
	var path := "%s/%s.png" % [bestiary_dir(), key]
	img.save_png(path)
	data.bestiary[key] = {"file": path, "effect": effect, "outline": outline}
	save()


func bestiary_remove(key: String) -> void:
	if no_save:
		return
	var b: Dictionary = data.get("bestiary", {})
	if b.has(key):
		DirAccess.remove_absolute(b[key].file)
		b.erase(key)
		save()


func add_pigments(n: int) -> void:
	if no_save:
		return
	data.pigments = int(data.pigments) + n
	save()


## Retire un dessin de la galerie (et son fichier).
func remove_from_gallery(entry: Dictionary) -> void:
	if no_save:
		return
	for e in data.gallery:
		if e.file == entry.file:
			DirAccess.remove_absolute(e.file)
			data.gallery.erase(e)
			break
	save()


func gallery_image(entry: Dictionary) -> Image:
	return Image.load_from_file(entry.file)


# ------------------------------------------------------------------ Fin de partie

## Difficulté maximale débloquée SUR CETTE CARTE (chaque carte a sa propre progression).
## Anciennes sauvegardes : l'ancienne progression globale compte pour La Feuille.
func max_diff(map_id: int) -> int:
	var m: Dictionary = data.get("max_diff_map", {})
	if m.has(str(map_id)):
		return int(m[str(map_id)])
	return int(data.get("max_diff", 0)) if map_id == 1 else 0


## Carte jouable ? La 1re toujours ; la 2e après une victoire sur la 1re.
func map_unlocked(id: int) -> bool:
	return id == 1 or level("map%d" % id) > 0


## Retourne true si cette partie vient de débloquer une nouvelle carte.
func record_run(wave_reached: int, win: bool, difficulty: int, earned: int, kills := 0, map_id := 1) -> bool:
	var new_map := false
	data.total_elites = int(data.get("total_elites", 0)) + Run.elite_kills
	var bb: Dictionary = data.get("bosses_beaten", {})
	bb.merge(Run.boss_ids)
	data.bosses_beaten = bb
	if win and map_id == 1 and not map_unlocked(2):
		data.unlocks["map2"] = 1
		new_map = true
	data.total_kills = int(data.get("total_kills", 0)) + kills
	data.runs = int(data.runs) + 1
	data.pigments = int(data.pigments) + earned
	data.best_wave = maxi(int(data.best_wave), wave_reached)
	if win:
		data.wins = int(data.wins) + 1
		var next := mini(difficulty + 1, DIFFICULTIES.size() - 1)
		var m: Dictionary = data.get("max_diff_map", {})
		m[str(map_id)] = maxi(max_diff(map_id), next)
		if not m.has("1"):
			m["1"] = max_diff(1)
		data.max_diff_map = m
		data.max_diff = maxi(int(data.max_diff), next)   # meilleure difficulté toutes cartes (succès)
	save()
	return new_map
