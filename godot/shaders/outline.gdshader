// Inverted-hull outline used as a next_pass on toon materials.
// The hull is pushed out in clip space by a constant number of pixels, so lines look the
// same in a 200px recipe icon and a 1080p kitchen, with a gentle falloff far from camera.
// When use_uv2_width is on, UV2.x scales the width per vertex (0 = no outline for tiny bits).
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, fog_disabled;

uniform vec4 outline_color : source_color = vec4(0.231, 0.137, 0.251, 1.0);
uniform float width_px = 2.2;
uniform float full_distance = 6.0;
uniform bool use_uv2_width = true;

void vertex() {
	float w = width_px;
	if (use_uv2_width) {
		w *= UV2.x;
	}
	vec4 vp = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * vp;
	// Directional shadow passes use an orthographic projection: never grow the hull there.
	if (PROJECTION_MATRIX[3][3] > 0.5) {
		w = 0.0;
	}
	float d = max(-vp.z, 0.01);
	w *= clamp(full_distance / d, 0.6, 1.0);
	vec3 vn = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec2 cn = (PROJECTION_MATRIX * vec4(vn, 0.0)).xy;
	float l = length(cn);
	if (l > 1e-5) {
		cn /= l;
		// WebGL can report a zero viewport size here: fall back to 1080p and clamp the push.
		vec2 vs = VIEWPORT_SIZE.x > 1.0 ? VIEWPORT_SIZE : vec2(1920.0, 1080.0);
		vec2 push = clamp(cn * w * 2.0 / vs, vec2(-0.02), vec2(0.02));
		clip.xy += push * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	if (use_uv2_width && UV2.x <= 0.001) {
		discard;
	}
	ALBEDO = outline_color.rgb;
}
