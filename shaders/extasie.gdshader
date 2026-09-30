shader_type canvas_item;
// Extasie : la vision se trouble. L'écran ondule et les couleurs dérivent lentement.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float strength = 1.0;

vec3 hue_shift(vec3 c, float a) {
	// rotation de teinte (espace YIQ)
	const mat3 to_yiq = mat3(vec3(0.299, 0.596, 0.211), vec3(0.587, -0.274, -0.523), vec3(0.114, -0.322, 0.312));
	const mat3 to_rgb = mat3(vec3(1.0, 1.0, 1.0), vec3(0.956, -0.272, -1.106), vec3(0.621, -0.647, 1.703));
	vec3 yiq = to_yiq * c;
	float h = atan(yiq.z, yiq.y) + a;
	float chroma = length(yiq.yz) * 1.25;   // un peu plus saturé
	return to_rgb * vec3(yiq.x, chroma * cos(h), chroma * sin(h));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 16.0 + TIME * 2.1) * 0.006 * strength;
	uv.y += sin(uv.x * 12.0 + TIME * 1.6) * 0.005 * strength;
	vec3 c = texture(screen_tex, uv).rgb;
	vec3 shifted = hue_shift(c, sin(TIME * 0.45) * 2.4 * strength);
	COLOR = vec4(mix(c, shifted, 0.75), 1.0);
}
