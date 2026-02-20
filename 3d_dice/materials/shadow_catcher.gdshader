shader_type spatial;

// ---------------------------------------------------------------------
// ⚙️ UNIFORMS (editable in Inspector via the .tres material)
// ---------------------------------------------------------------------

// Shadow color — black by default (vec3 = RGB, range 0–1)
uniform vec3 shadow_color : source_color = vec3(0.0, 0.0, 0.0);

// Shadow intensity — how strongly darkness appears in shadowed zones
// 0.0 → no visible shadow | 1.0 → full darkness
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.6;

// Maximum darkness limit — caps total shadow intensity
// 0.0 → extremely faint | 1.0 → can reach pure black
uniform float shadow_max_opacity : hint_range(0.0, 1.0) = 0.8;

// ---------------------------------------------------------------------
// 🧩 FRAGMENT — base surface definition
// ---------------------------------------------------------------------
void fragment() {
	// Base color of the plane (kept blackish)
	ALBEDO = shadow_color;

	// Plane itself invisible; only light() will reveal shadows
	ALPHA = 0.0;
}

// ---------------------------------------------------------------------
// 💡 LIGHT — runs per light source, applies shadow transparency
// ---------------------------------------------------------------------
void light() {
	// ATTENUATION = 1.0 (lit) → 0.0 (in shadow)
	// (1.0 - ATTENUATION) = how much of the pixel is shadowed
	float shadow_strength = shadow_opacity * (1.0 - ATTENUATION);

	// Clamp to prevent excessive opacity
	ALPHA = min(shadow_strength, shadow_max_opacity);
}