shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// --------------------------------------------
//  UNIFORMS  (editable in Inspector)
// --------------------------------------------
uniform vec3  shadow_color       : source_color = vec3(0.0, 0.0, 0.0);
uniform float shadow_opacity     : hint_range(0.0, 1.0) = 0.7;
uniform float shadow_max_opacity : hint_range(0.0, 1.0) = 0.9;

// --------------------------------------------
//  FRAGMENT — base layer (fully transparent)
// --------------------------------------------
void fragment() {
	ALBEDO = shadow_color; // defines base tint
	ALPHA  = 0.9;          // plane invisible by default
}

// --------------------------------------------
//  LIGHT — apply shadow attenuation
// --------------------------------------------
void light() {
	// ATTENUATION → 1.0 lit, 0.0 full shadow
	float shadow_strength = shadow_opacity * (1.0 - ATTENUATION);
	float alpha_val       = min(shadow_strength, shadow_max_opacity);

	// DARKEN the light contribution (not ALBEDO)
	DIFFUSE_LIGHT = mix(LIGHT, shadow_color, alpha_val);
	ALPHA         = alpha_val;
}
