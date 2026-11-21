// Spinning dust wall of the tornado around Elst. UV.x runs around the
// cylinder, so the noise repeats every `bands` cells and the seam never shows.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 dust_color : source_color = vec4(0.52, 0.44, 0.36, 1.0);
uniform vec4 dark_color : source_color = vec4(0.24, 0.21, 0.19, 1.0);
// Noise cells around the cylinder and from bottom to top.
uniform float bands = 32.0;
uniform float rows = 6.0;
// Turns per second, and how fast the streaks rise.
uniform float spin_speed = 0.01;
uniform float rise_speed = 0.08;
uniform float opacity : hint_range(0.0, 1.0) = 0.85;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p, float period) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(vec2(mod(i.x, period), i.y));
	float b = hash(vec2(mod(i.x + 1.0, period), i.y));
	float c = hash(vec2(mod(i.x, period), i.y + 1.0));
	float d = hash(vec2(mod(i.x + 1.0, period), i.y + 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p, float period) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += noise(p, period) * amplitude;
		p *= 2.0;
		period *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	float around = fract(UV.x + TIME * spin_speed);
	// The streaks lean as they rise, like wind spiralling upwards.
	float lean = UV.y * 10.0;
	vec2 p = vec2(around * bands + lean, UV.y * rows - TIME * rise_speed);
	float clouds = fbm(p, bands);
	float streaks = 0.5 + 0.5 * sin((around * bands + lean) * 0.785398 * 2.0 + clouds * 4.0);
	float density = smoothstep(0.25, 0.8, clouds * 0.75 + streaks * 0.35);
	ALBEDO = mix(dark_color.rgb, dust_color.rgb, density);
	float edges = smoothstep(0.0, 0.15, UV.y) * smoothstep(1.0, 0.85, UV.y);
	ALPHA = opacity * mix(0.55, 1.0, density) * edges;
}
