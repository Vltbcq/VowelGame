class_name Player
extends Node2D
## Le perso dessiné. Se déplace (ZQSD/WASD/flèches/manette), les armes attaquent toutes seules.

var arena: Arena
var st: Dictionary
var hp := 10.0
var radius := 6.0
var body: Node2D
var sprite: Sprite2D
var mat: ShaderMaterial
var weapons: Array[WeaponNode] = []
var inv := 0.0
var flash := 0.0
var t := 0.0
var moving := false
var max_hp := 10.0          # PV max de la vague (réduits quand la Toile Blanche gomme ton dessin)
var erase_mult := 1.0
var pimg: Image             # image du perso, modifiable (gomme)
var ptex: ImageTexture
var was_hurt := false       # a perdu des PV cette vague (La Joconde)


func setup(a: Arena) -> void:
	arena = a
	Run.recompute()   # stats qui dépendent de l'or ou des armes (Cadre doré, Collage)
	st = Run.stats
	max_hp = st.max_hp
	hp = clampf(Run.hp, 1.0, max_hp)   # les PV ne remontent pas entre les vagues
	var rest := Run.amulet_count("restauration")
	if rest > 0:
		hp = minf(max_hp, hp + max_hp * 0.3 * rest)
	radius = st.radius
	body = Node2D.new()
	add_child(body)
	mat = Gfx.material(Run.char_effect, Run.char_outline)
	pimg = Gfx.padded(Run.build_player_image())
	ptex = ImageTexture.create_from_image(pimg)
	sprite = Gfx.sprite(ptex, mat)
	sprite.centered = false
	# Le centre du dessin (hors amulettes) est l'origine du joueur.
	var r: Rect2i = Run.char_a.rect
	var c := Vector2(r.position) + Vector2(r.size) / 2.0 + Vector2(Run.PAD + 1, Run.PAD + 1)
	sprite.position = -c
	body.add_child(sprite)
	for w in Run.weapons:
		var wn := WeaponNode.new()
		add_child(wn)
		wn.setup(self, w)
		weapons.append(wn)


func _draw() -> void:
	draw_set_transform(Vector2(0, radius + 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius + 3, Color(0, 0, 0, 0.18))


func input_dir() -> Vector2:
	var d := Vector2.ZERO
	# Touches physiques : WASD sur QWERTY = ZQSD sur AZERTY
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		d.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		d.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		d.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		d.y += 1
	var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy.length() > 0.25:
		d += joy
	return d.limit_length(1.0) if d.length() > 1.0 else d


func tick(delta: float) -> void:
	t += delta
	var d := input_dir()
	moving = d.length() > 0.1
	# Flaques d'encre : ralentissent, et les traits frais font mal
	var hz := arena.hazard_effect(position, radius)
	position += d * st.move * hz[0] * delta
	if hz[1] > 0.0:
		take_hit(hz[1], 0, null)
	position.x = clampf(position.x, radius, Arena.W - radius)
	position.y = clampf(position.y, radius, Arena.H - radius)
	if absf(d.x) > 0.1:
		body.scale.x = -1.0 if d.x < 0 else 1.0
	# Petite animation de marche
	if moving:
		body.position.y = -absf(sin(t * 12.0)) * 2.0
		body.rotation = sin(t * 12.0) * 0.06
	else:
		body.position.y = lerpf(body.position.y, 0.0, 0.3)
		body.rotation = lerpf(body.rotation, 0.0, 0.3)

	if st.regen > 0.0:
		heal(st.regen * 0.2 * delta, false)
	inv -= delta
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 6.0)
		mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("alpha", 0.45 if inv > 0.0 and int(t * 20.0) % 2 == 0 else 1.0)

	for e in arena.near(position, radius + 1.0):
		if e.contact:
			take_hit(e.dmg, e.element, e)
			break
	for w in weapons:
		w.tick(delta)


func take_hit(dmg: float, element: int, src: Node) -> void:
	if inv > 0.0 or arena.ended:
		return
	if randf() * 100.0 < st.dodge:
		arena.float_text(position + Vector2(0, -14), "ESQUIVE", Pal.DIM)
		inv = 0.25
		return
	var d := dmg
	if st.armor >= 0.0:
		d /= 1.0 + st.armor / 15.0
	else:
		d *= 1.0 - st.armor / 15.0
	if element > 0:
		d *= 1.0 - st.res[element] / 100.0
	d = maxf(1.0, roundf(d))
	hp -= d
	was_hurt = true
	arena.player_hurt_fx(position)
	inv = 0.5
	flash = 1.0
	arena.shake(4.0)
	Sfx.play("hurt")
	arena.float_text(position + Vector2(0, -14), "-%d" % int(d), Pal.BAD if element == 0 else Pal.main_color(element))
	if st.thorns > 0.0 and src is Enemy:
		(src as Enemy).hurt(st.thorns, false, Vector2.ZERO)
	if hp <= 0.0:
		if Run.amulet_count("renaissance") > 0 and not Run.revived:
			Run.revived = true
			hp = maxf(1.0, roundf(max_hp * 0.5))
			inv = 2.0
			arena.explosion(position, 80.0, Color(Pal.GOOD, 0.9))
			for e in arena.near(position, 80.0):
				e.knock += (e.position - position).normalized() * 220.0
			arena.numbers.add(position + Vector2(0, -26), "RENAISSANCE !", Pal.GOOD, 1.8)
			return
		arena.player_died()


func refresh_max_hp() -> void:
	max_hp = maxf(1.0, roundf(st.max_hp * erase_mult))
	hp = minf(hp, max_hp)


## La Toile Blanche gomme un morceau de ton dessin : -12% PV max jusqu'à la fin de la vague.
func erase_at(_world: Vector2) -> void:
	var w := pimg.get_width()
	var h := pimg.get_height()
	var c := Vector2i(-1, -1)
	for i in 400:
		var q := Vector2i(randi() % w, randi() % h)
		if pimg.get_pixelv(q).a > 0.5:
			c = q
			break
	if c.x < 0:
		return
	var r := 5
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var q := c + Vector2i(x, y)
			if x * x + y * y <= r * r and q.x >= 0 and q.y >= 0 and q.x < w and q.y < h:
				pimg.set_pixelv(q, Color(0, 0, 0, 0))
	ptex.update(pimg)
	erase_mult = maxf(0.5, erase_mult - 0.12)
	refresh_max_hp()
	arena.float_text(position + Vector2(0, -22), "EFFACÉ !", Pal.TEXT)
	Sfx.play("explode")


func heal(n: float, show := true) -> void:
	var before := hp
	hp = minf(max_hp, hp + n)
	if show and hp - before >= 1.0:
		arena.float_text(position + Vector2(0, -14), "+%d" % int(hp - before), Pal.GOOD)
