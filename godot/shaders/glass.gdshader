// Stylised glass: pale tint, plum edges where the surface turns away (a drawn outline look)
// and a soft vertical highlight streak. No inverted hull, so the contents stay visible.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.86, 0.94, 1.0, 0.16);
uniform vec4 edge_color : source_color = vec4(0.231, 0.137, 0.251, 1.0);
uniform float edge_start = 0.82;
uniform float edge_end = 0.9;
uniform float streak = 0.55;
// same order as toon.gdshader so shared instance parameters line up
instance uniform float cook = 0.0;
instance uniform float frost = 0.0;
instance uniform float flash = 0.0;
instance uniform float fade_out = 0.0;

void fragment() {
	float nv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float f = 1.0 - nv;
	float edge = smoothstep(edge_start, edge_end, f);
	// highlight streak on the left side of the glass in view space
	float sx = NORMAL.x;
	float hi = smoothstep(-0.78, -0.62, sx) * (1.0 - smoothstep(-0.52, -0.36, sx)) * streak;
	float hi2 = smoothstep(0.42, 0.5, sx) * (1.0 - smoothstep(0.52, 0.58, sx)) * streak * 0.6;
	vec3 col = mix(tint.rgb, vec3(1.0), hi + hi2);
	col = mix(col, vec3(0.93, 0.97, 1.0), frost * 0.7);
	col = mix(col, edge_color.rgb, edge);
	ALBEDO = col;
	ALPHA = clamp(max(max(tint.a + frost * 0.5, edge), hi + hi2), 0.0, 1.0);
}
