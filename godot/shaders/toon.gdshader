// Cosy Kitchen toon shader.
// Soft two-band cel shading, lavender shadows (from the environment's ambient light),
// a warm rim light and a crisp cartoon glint. Colour usually comes from vertex colours,
// so a whole dish can be one merged mesh with one material.
//   COLOR.rgb  albedo (sRGB)
//   UV2.x      outline width scale (read by outline.gdshader)
//   UV2.y      gloss: 0 = matte, 1 = wet/shiny (syrup, cherries, sauces)
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_vertex_color = true;
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap;
uniform bool use_texture = false;
uniform float band : hint_range(-1.0, 1.0) = 0.12;
uniform float softness : hint_range(0.001, 0.5) = 0.07;
uniform float rim_amount : hint_range(0.0, 2.0) = 0.38;
uniform float glint_amount : hint_range(0.0, 3.0) = 0.9;
uniform float base_gloss : hint_range(0.0, 1.0) = 0.22;
uniform float emission_amount : hint_range(0.0, 8.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(1.0, 0.8, 0.5, 1.0);

// Per-instance knobs, set with set_instance_shader_parameter().
instance uniform float cook = 0.0;     // 0 raw .. 1 cooked .. 1.7 burnt
instance uniform float frost = 0.0;    // 0..1 icy
instance uniform float flash = 0.0;    // 0..1 white feedback flash
instance uniform float fade_out = 0.0; // dither fade 0 (solid) .. 1 (gone); zero-default is safe on WebGL

varying float v_gloss;

vec3 srgb_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	v_gloss = UV2.y;
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int idx = x + y * 4;
	float m[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return (m[idx] + 0.5) / 16.0;
}

void fragment() {
	if (fade_out > 0.001 && 1.0 - fade_out < bayer4(FRAGCOORD.xy)) {
		discard;
	}
	vec3 c = albedo.rgb;
	if (use_vertex_color) {
		c *= srgb_to_linear(COLOR.rgb);
	}
	if (use_texture) {
		c *= texture(albedo_texture, UV).rgb;
	}
	// Cooking: warm golden-brown first, then charcoal once it burns.
	float k = clamp(cook, 0.0, 1.0);
	c = mix(c, c * vec3(1.0, 0.70, 0.40) + vec3(0.03, 0.012, 0.0), k * 0.55);
	float burnt = smoothstep(1.12, 1.55, cook);
	c = mix(c, vec3(0.045, 0.032, 0.036), burnt * 0.82);
	c = mix(c, vec3(0.80, 0.90, 1.0), frost * 0.55);
	c = mix(c, vec3(1.0), flash);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	METALLIC = 0.0;
	EMISSION = emission_color.rgb * emission_amount * c;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(band - softness, band + softness, ndl);
	float att = ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		// crisp toon shadows from the sun/key light
		att = smoothstep(0.25, 0.65, att);
	}
	float l = lit * att;
	vec3 lc = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += lc * l;
	if (LIGHT_IS_DIRECTIONAL) {
		// warm rim light on edges that face the light a little
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		float rim = smoothstep(0.42, 0.62, fres) * smoothstep(-0.3, 0.4, ndl) * att;
		DIFFUSE_LIGHT += lc * rim * rim_amount * vec3(1.0, 0.93, 0.86);
		// cartoon glint
		float g = max(base_gloss, v_gloss);
		vec3 h = normalize(LIGHT + VIEW);
		float s = smoothstep(0.955 - g * 0.05, 0.975 - g * 0.04, dot(NORMAL, h));
		SPECULAR_LIGHT += lc * s * glint_amount * g * att;
	}
}
