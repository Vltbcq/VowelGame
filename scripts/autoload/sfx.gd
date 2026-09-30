extends Node
## Bruitages 8 bits générés en code (aucun fichier audio nécessaire).

const RATE := 22050
var sounds := {}
var players: Array[AudioStreamPlayer] = []
var last_played := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		players.append(p)
	sounds.click = _tone([[700, 700, 0.03]], "square", 0.25)
	sounds.paint = _tone([[500, 520, 0.02]], "tri", 0.2)
	sounds.shoot = _tone([[900, 450, 0.06]], "square", 0.18)
	sounds.swing = _tone([[300, 700, 0.07]], "noise", 0.2)
	sounds.hit = _tone([[200, 120, 0.05]], "noise", 0.3)
	sounds.kill = _tone([[320, 70, 0.14]], "tri", 0.45)
	sounds.pickup = _tone([[1200, 1800, 0.04]], "square", 0.12)
	sounds.hurt = _tone([[220, 80, 0.2]], "square", 0.35)
	sounds.level = _tone([[523, 523, 0.07], [659, 659, 0.07], [784, 784, 0.07], [1046, 1046, 0.14]], "square", 0.25)
	sounds.wave = _tone([[392, 392, 0.1], [523, 523, 0.1], [659, 784, 0.2]], "tri", 0.4)
	sounds.boss = _tone([[110, 70, 0.9]], "square", 0.35)
	sounds.explode = _tone([[160, 40, 0.3]], "noise", 0.45)
	sounds.buy = _tone([[800, 800, 0.05], [1200, 1200, 0.08]], "square", 0.22)
	sounds.enemy_shot = _tone([[500, 300, 0.07]], "tri", 0.25)
	sounds.zap = _tone([[1500, 600, 0.08]], "noise", 0.2)
	# Roulette : la bille qui cogne les cases, puis tombe dans la sienne
	sounds.tick = _tone([[3400, 2600, 0.006], [1900, 1500, 0.012]], "square", 0.1)
	sounds.clack = _tone([[1500, 1100, 0.018], [1, 1, 0.035], [1700, 1300, 0.014], [1, 1, 0.05], [1300, 1000, 0.02]], "tri", 0.3)
	sounds.whirr = _tone([[180, 420, 0.25]], "noise", 0.12)
	sounds.lose = _tone([[392, 392, 0.2], [330, 330, 0.2], [262, 200, 0.5]], "tri", 0.45)
	sounds.win = _tone([[523, 523, 0.12], [659, 659, 0.12], [784, 784, 0.12], [1046, 1046, 0.4]], "square", 0.28)


## segs = [[freq_debut, freq_fin, durée], ...]
func _tone(segs: Array, wave: String, vol: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	var phase := 0.0
	for seg in segs:
		var n := int(seg[2] * RATE)
		var start := data.size()
		data.resize(start + n * 2)
		for i in n:
			var t := float(i) / n
			var f := lerpf(seg[0], seg[1], t)
			phase += f / RATE
			var s := 0.0
			match wave:
				"square":
					s = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
				"tri":
					s = 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0
				"noise":
					s = randf() * 2.0 - 1.0
			var env := pow(1.0 - t, 1.5) * minf(1.0, t * 60.0 + 0.2)
			data.encode_s16(start + i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = data
	return st


var music_player: AudioStreamPlayer
const BANANA_MUSIC := "res://audio/plastic_and_flashing_lights.mp3"


## Musique : « Plastic and Flashing Lights » (Professor Kliq, CC BY-NC-SA) tant que tu as La Banane,
## en boutique et pendant les vagues. Sinon, pas de musique (en attendant celle du jeu).
func update_music() -> void:
	var want := Run.active and Run.amulet_count("banane") > 0
	if want:
		if music_player == null:
			music_player = AudioStreamPlayer.new()
			music_player.volume_db = -6.0
			add_child(music_player)
		if not music_player.playing:
			var st = load(BANANA_MUSIC)
			if st is AudioStreamMP3:
				st.loop = true
			music_player.stream = st
			music_player.play()
	else:
		stop_music()


func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()


func play(snd: String, pitch_var := 0.08) -> void:
	if not sounds.has(snd):
		return
	var now := Time.get_ticks_msec()
	if now - int(last_played.get(snd, -1000)) < 35:
		return
	last_played[snd] = now
	for p in players:
		if not p.playing:
			p.stream = sounds[snd]
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.play()
			return
