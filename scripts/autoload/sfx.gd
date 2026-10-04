extends Node
## Bruitages 8 bits générés en code, et musiques (assets/music, par Eric Matyas – soundimage.org).

const RATE := 22050
var sounds := {}
var players: Array[AudioStreamPlayer] = []
var last_played := {}

## Musiques : menus, entre les vagues (niveaux, boutique, dessins), pendant les vagues.
const MUSIC := {
	"menu": "res://assets/music/Bozos-Arcade.ogg",
	"transition": "res://assets/music/Bumbling-Burglars_Looping.ogg",
	"vague": "res://assets/music/Cartoon-Chaos.ogg",
}
const MUSIC_DB := -10.0      # la musique reste sous les bruitages
const FADE := 0.8            # fondu entre deux musiques (s)
var music_players: Array[AudioStreamPlayer] = []
var music_now := ""
var _music_i := 0
var _fade_out: Tween
var _fade_in: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		players.append(p)
	for i in 2:
		var mp := AudioStreamPlayer.new()
		mp.volume_db = -80.0
		add_child(mp)
		music_players.append(mp)
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
	sounds.coin = _tone([[1318, 1318, 0.05], [1976, 1976, 0.14]], "square", 0.2)
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


## Change de musique avec un fondu (rien si c'est déjà celle-là). "" = silence.
func music(id: String) -> void:
	if id == music_now:
		return
	music_now = id
	var old := music_players[_music_i]
	_music_i = 1 - _music_i
	var nw := music_players[_music_i]
	if _fade_out:
		_fade_out.kill()
	if _fade_in:
		_fade_in.kill()
	_fade_out = create_tween()
	_fade_out.tween_property(old, "volume_db", -80.0, FADE)
	_fade_out.tween_callback(func():
		if music_players[_music_i] != old:   # (si on n'est pas revenu dessus entre-temps)
			old.stop())
	if id == "" or not MUSIC.has(id) or not ResourceLoader.exists(MUSIC[id]):
		return
	var st := load(MUSIC[id]) as AudioStream
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	nw.stream = st
	nw.volume_db = -80.0
	nw.play()
	_fade_in = create_tween()
	_fade_in.tween_property(nw, "volume_db", MUSIC_DB, FADE)
