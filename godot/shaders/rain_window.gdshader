// The rainy evening outside the café window: a dusk gradient, soft bokeh city lights,
// falling rain streaks and drops sliding down the glass.
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 sky_top : source_color = vec4(0.20, 0.22, 0.42, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.62, 0.45, 0.62, 1.0);
uniform float rain = 1.0;
uniform float night = 0.0; // 0 = dusk, 1 = night

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	vec3 top = mix(sky_top.rgb, vec3(0.08, 0.09, 0.2), night);
	vec3 bot = mix(sky_bottom.rgb, vec3(0.25, 0.2, 0.38), night);
	vec3 col = mix(top, bot, smoothstep(0.0, 1.0, uv.y));
	// city silhouette
	float h = 0.62 + 0.08 * step(0.5, hash(vec2(floor(uv.x * 9.0), 1.0))) + 0.06 * hash(vec2(floor(uv.x * 23.0), 4.0));
	float city = step(h, uv.y);
	col = mix(col, mix(vec3(0.24, 0.2, 0.36), vec3(0.12, 0.1, 0.2), night), city * 0.85);
	// bokeh lights
	for (int i = 0; i < 18; i++) {
		float fi = float(i);
		vec2 c = vec2(hash(vec2(fi, 2.0)), 0.55 + 0.4 * hash(vec2(fi, 7.0)));
		float r = 0.025 + 0.035 * hash(vec2(fi, 9.0));
		float d = length((uv - c) * vec2(2.2, 1.0));
		vec3 lc = mix(vec3(1.0, 0.75, 0.45), vec3(1.0, 0.55, 0.7), hash(vec2(fi, 3.0)));
		float tw = 0.75 + 0.25 * sin(TIME * (0.6 + hash(vec2(fi, 5.0))) + fi);
		col += lc * smoothstep(r, r * 0.6, d) * 0.35 * tw * (0.6 + night);
	}
	// rain streaks
	vec2 ru = uv * vec2(70.0, 6.0);
	ru.y -= TIME * 9.0;
	ru.x += ru.y * 0.06;
	float lane = floor(ru.x);
	float off = hash(vec2(lane, 1.0));
	float y = fract(ru.y + off * 7.0);
	float streak = smoothstep(0.0, 0.05, y) * (1.0 - smoothstep(0.05, 0.4, y)) * step(0.55, hash(vec2(lane, 3.0)));
	streak *= 1.0 - smoothstep(0.02, 0.12, abs(fract(ru.x) - 0.5));
	col += vec3(0.75, 0.82, 1.0) * streak * 0.4 * rain;
	// drops on the glass
	vec2 du = uv * vec2(14.0, 8.0);
	vec2 cell = floor(du);
	float dh = hash(cell);
	vec2 dc = vec2(0.5 + 0.3 * (hash(cell + 3.1) - 0.5), fract(dh - TIME * 0.05 * (0.5 + dh)));
	float dd = length((fract(du) - dc) * vec2(1.0, 1.6));
	float drop = smoothstep(0.12, 0.06, dd) * step(0.6, dh) * rain;
	col = mix(col, col * 1.25 + vec3(0.1), drop);
	ALBEDO = col;
}
