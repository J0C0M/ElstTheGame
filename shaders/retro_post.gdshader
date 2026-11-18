// Light retro post-process for the 3D world, applied by RetroScreen.
// Faint film grain, colour quantisation with 4x4 Bayer dithering and a soft
// vignette. The world texture is read once per source pixel, so the grain and
// dither pattern line up with the low-resolution pixels.
shader_type canvas_item;

uniform float color_levels : hint_range(2.0, 256.0) = 32.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.75;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_inner : hint_range(0.0, 1.5) = 0.6;
uniform float vignette_outer : hint_range(0.0, 2.0) = 1.5;
uniform float noise_strength : hint_range(0.0, 0.2) = 0.02;
uniform float noise_fps : hint_range(1.0, 60.0) = 24.0;

const float BAYER_4X4[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
	vec3 color = texture(TEXTURE, (pixel + 0.5) * TEXTURE_PIXEL_SIZE).rgb;

	// Film grain, refreshed noise_fps times per second.
	float frame = floor(TIME * noise_fps);
	color += (hash(pixel + frame * vec2(13.7, 7.3)) - 0.5) * noise_strength;

	// Quantise each channel to color_levels steps. The Bayer value shifts the
	// rounding point per pixel, so gradients dither instead of banding.
	int bayer_index = int(mod(pixel.y, 4.0)) * 4 + int(mod(pixel.x, 4.0));
	float threshold = (BAYER_4X4[bayer_index] + 0.5) / 16.0 - 0.5;
	float steps = color_levels - 1.0;
	color = floor(color * steps + 0.5 + threshold * dither_strength) / steps;

	// Soft vignette: 0 in the middle, 1 in the corners.
	float edge = length((UV - 0.5) * 2.0);
	color *= 1.0 - vignette_strength * smoothstep(vignette_inner, vignette_outer, edge);

	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
