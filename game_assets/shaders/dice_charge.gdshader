shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ── Uniforms ──────────────────────────────────────────────────────────────────
uniform float charge          : hint_range(0.0, 1.0) = 0.0;   // 0=idle  1=full
uniform float time_offset     = 0.0;                           // pass TIME from GDScript
uniform vec4  energy_color    : source_color = vec4(0.2, 0.6, 1.0, 1.0);
uniform vec4  base_color      : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D texture_albedo : hint_default_white, filter_linear_mipmap;

// ── Helpers ───────────────────────────────────────────────────────────────────
float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

// Simple 1-D noise  (smooth random value)
float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

// Equalizer band value for a given vertical position and time
// Returns 0‥1  — each band has its own random envelope
float eq_band(float y_uv, float t) {
	// 8 bands across the V axis
	float band_count = 8.0;
	float band_id    = floor(y_uv * band_count);
	// Each band scrolls at a slightly different speed and phase
	float speed   = 3.0 + hash(band_id + 0.1) * 5.0;
	float phase   = hash(band_id + 7.3) * 6.28;
	float raw     = noise1(t * speed + phase + band_id * 1.7);
	// Add a slow "drop and surge" envelope
	float surge   = noise1(t * 0.8 + band_id * 0.4);
	float height  = mix(raw * 0.4, raw, surge);          // drops low sometimes
	// Is this pixel inside the bar?
	float bar_top = height;
	float in_bar  = step(y_uv - fract(y_uv * band_count) / band_count, bar_top);
	return in_bar * height;
}

// ── Vertex ────────────────────────────────────────────────────────────────────
void vertex() {
	// Tremor: random positional shake that grows with charge
	float t       = time_offset;
	float shake   = charge * charge * 0.04;              // max ~4 cm at full charge
	// Three independent low-freq noise axes
	float sx = (noise1(t * 18.0 + 0.0) - 0.5) * 2.0 * shake;
	float sy = (noise1(t * 21.0 + 3.7) - 0.5) * 2.0 * shake;
	float sz = (noise1(t * 15.0 + 7.1) - 0.5) * 2.0 * shake;
	VERTEX += vec3(sx, sy, sz);
}

// ── Fragment ──────────────────────────────────────────────────────────────────
void fragment() {
	vec2  uv       = UV;
	float t        = time_offset;

	// Base dice texture
	vec4 tex       = texture(texture_albedo, uv);
	vec3 albedo    = tex.rgb * base_color.rgb;

	// ── Equalizer overlay (on the surface, UV-space) ─────────────────────────
	float eq       = eq_band(uv.y, t) * charge;
	// Horizontal scan-line thinning so bars look like discrete segments
	float segments = 16.0;
	float seg_mask = step(0.15, fract(uv.y * segments));   // gaps between segments
	eq            *= seg_mask;

	// Slightly different hue for peak flashes
	float peak     = smoothstep(0.7, 1.0, eq);
	vec3 eq_col    = mix(energy_color.rgb, vec3(1.0, 1.0, 0.4), peak);

	// Blend EQ bars over base texture
	albedo         = mix(albedo, eq_col, eq * 0.65);

	// ── Rim glow (fresnel) ────────────────────────────────────────────────────
	float rim      = 1.0 - max(0.0, dot(NORMAL, VIEW));
	rim            = pow(rim, 2.5);
	// Pulse the rim so it breathes (equalizer-style)
	float rim_pulse = 0.6 + 0.4 * noise1(t * 4.0);
	float rim_strength = charge * rim * rim_pulse;
	albedo         = mix(albedo, energy_color.rgb, rim_strength * 0.9);

	// ── Emission glow ─────────────────────────────────────────────────────────
	// Core emission: rim + eq bars
	vec3 emission  = energy_color.rgb * (rim_strength * 1.5 + eq * charge * 0.8);
	// Global pulse so the whole dice breathes
	float breathe  = 0.5 + 0.5 * noise1(t * 2.5);
	emission      *= mix(0.7, 1.0, breathe * charge);

	ALBEDO         = albedo;
	EMISSION       = emission;
	ROUGHNESS      = mix(0.6, 0.15, charge);   // shinier when charged
	METALLIC       = charge * 0.4;
	ALPHA          = tex.a;
}
