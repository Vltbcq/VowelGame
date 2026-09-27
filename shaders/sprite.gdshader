shader_type canvas_item;
// Contour 1px, flash blanc quand on est touché, et effets d'encre animée.

uniform vec4 outline_color : source_color = vec4(0.10, 0.08, 0.14, 1.0);
uniform bool outline = true;
uniform float flash = 0.0;
uniform float alpha = 1.0;
uniform vec4 tint = vec4(1.0);
uniform int effect = 0; // 0 aucun, 1 pulse, 2 arc-en-ciel, 3 scintille

vec3 rainbow(float t) {
	return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) {
		float a = 0.0;
		if (outline) {
			vec2 px = TEXTURE_PIXEL_SIZE;
			a = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
				+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		}
		if (a > 0.5) {
			COLOR = vec4(mix(outline_color.rgb, vec3(1.0), flash), outline_color.a * alpha);
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		vec3 col = c.rgb;
		if (effect == 1) {
			col *= 0.8 + 0.4 * (0.5 + 0.5 * sin(TIME * 6.0));
		} else if (effect == 2) {
			col = mix(col, rainbow(TIME * 0.5 + UV.y * 1.5 + UV.x * 0.5), 0.5);
		} else if (effect == 3) {
			vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE);
			float r = fract(sin(dot(cell + floor(TIME * 7.0), vec2(12.9898, 78.233))) * 43758.5453);
			if (r > 0.93) col = vec3(1.0);
		}
		col = clamp(col * tint.rgb, 0.0, 1.0);
		col = mix(col, vec3(1.0), flash);
		COLOR = vec4(col, c.a * alpha);
	}
}
