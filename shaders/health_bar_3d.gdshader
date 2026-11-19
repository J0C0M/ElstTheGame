// Health bar that floats above an enemy and always faces the camera. The fill
// comes from the per-instance fill_ratio, so all bars share one material.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

instance uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.82, 0.16, 0.13, 1.0);
uniform vec4 empty_color : source_color = vec4(0.22, 0.06, 0.06, 1.0);
uniform vec4 border_color : source_color = vec4(0.05, 0.04, 0.05, 1.0);
// Border thickness as a share of the bar's width and height.
uniform vec2 border = vec2(0.025, 0.2);

void vertex() {
	// Billboard that keeps the node's scale.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 inner = (UV - border) / (1.0 - 2.0 * border);
	bool in_border = any(lessThan(inner, vec2(0.0))) || any(greaterThan(inner, vec2(1.0)));
	vec4 color = inner.x <= fill_ratio ? fill_color : empty_color;
	ALBEDO = in_border ? border_color.rgb : color.rgb;
}
