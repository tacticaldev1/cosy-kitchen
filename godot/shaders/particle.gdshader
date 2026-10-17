// Billboard particle: unshaded, soft alpha, coloured by the particle's COLOR (colour ramp).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D tex : source_color, filter_linear_mipmap, hint_default_white;
uniform float alpha_scale = 1.0;
uniform bool additive_glow = false;

void vertex() {
	// face the camera, keep the particle's own scale and spin
	mat4 billboard = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	vec3 scl = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	float spin = atan(MODEL_MATRIX[0].y, MODEL_MATRIX[0].x);
	mat4 rot = mat4(vec4(cos(spin), sin(spin), 0.0, 0.0), vec4(-sin(spin), cos(spin), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * billboard * rot * mat4(vec4(scl.x, 0.0, 0.0, 0.0), vec4(0.0, scl.y, 0.0, 0.0), vec4(0.0, 0.0, scl.z, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 t = texture(tex, UV);
	ALBEDO = COLOR.rgb * t.rgb;
	ALPHA = clamp(COLOR.a * t.a * alpha_scale, 0.0, 1.0);
	if (additive_glow) {
		EMISSION = ALBEDO * 0.4;
	}
}
