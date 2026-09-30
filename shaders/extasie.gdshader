shader_type canvas_item;
// Extasie : la vision se trouble VRAIMENT. L'écran ondule fort, respire (zoom), se dédouble,
// les couleurs se séparent et tournent en permanence, avec des « montées » régulières.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength = 1.0;

vec3 hue_shift(vec3 c, float a) {
	// rotation de teinte (espace YIQ)
	const mat3 to_yiq = mat3(vec3(0.299, 0.596, 0.211), vec3(0.587, -0.274, -0.523), vec3(0.114, -0.322, 0.312));
	const mat3 to_rgb = mat3(vec3(1.0, 1.0, 1.0), vec3(0.956, -0.272, -1.106), vec3(0.621, -0.647, 1.703));
	vec3 yiq = to_yiq * c;
	float h = atan(yiq.z, yiq.y) + a;
	float chroma = length(yiq.yz) * 1.45;   // couleurs saturées
	return to_rgb * vec3(yiq.x, chroma * cos(h), chroma * sin(h));
}

void fragment() {
	// « Montées » : l'intensité enfle toutes les ~6 s
	float surge = (0.7 + 0.6 * pow(0.5 + 0.5 * sin(TIME * 1.05), 3.0)) * strength;
	vec2 uv = SCREEN_UV;
	// l'écran respire (zoom avant / arrière)
	uv = (uv - 0.5) * (1.0 + 0.045 * sin(TIME * 0.9) * surge) + 0.5;
	// grosses ondulations croisées
	uv.x += (sin(uv.y * 11.0 + TIME * 2.6) * 0.016 + sin(uv.y * 29.0 - TIME * 3.7) * 0.005) * surge;
	uv.y += (sin(uv.x * 9.0 + TIME * 2.0) * 0.013 + sin(uv.x * 23.0 + TIME * 4.1) * 0.004) * surge;
	// couleurs séparées (rouge / vert / bleu décalés)
	vec2 split = vec2(0.008, 0.003) * surge;
	vec3 c = vec3(texture(screen_tex, uv + split).r, texture(screen_tex, uv).g, texture(screen_tex, uv - split).b);
	// vision double : une copie fantôme qui tourne autour
	vec2 ghost_off = vec2(cos(TIME * 1.3), sin(TIME * 1.7)) * 0.022 * surge;
	vec3 ghost = texture(screen_tex, uv + ghost_off).rgb;
	c = mix(c, ghost, 0.38);
	// teinte qui tourne en continu
	vec3 shifted = hue_shift(c, TIME * 0.9 * strength);
	COLOR = vec4(mix(c, shifted, 0.85), 1.0);
}
