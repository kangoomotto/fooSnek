shader_type canvas_item;

uniform float base_inner_radius = 0.48;
uniform float base_outer_radius = 0.85;

uniform float rotation_speed = 1.6;
uniform float runtime_speed_boost = 1.0;

uniform float swirl_strength = 0.12;
uniform float noise_frequency = 6.0;
uniform float glow_power = 2.2;

uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(i), hash(i + 1.0), f);
}

void fragment() {
	// Normalized UV centered at (0,0)
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);

	// Polar angle
	float angle = atan(uv.y, uv.x);

	// Tangential swirl (angle distortion, NOT radius distortion)
	float swirl = noise(r * noise_frequency + TIME) * swirl_strength;

	angle += TIME * rotation_speed * runtime_speed_boost + swirl;

	// Ring mask (stable thickness)
	float ring = smoothstep(base_inner_radius, base_inner_radius + 0.04, r)
	           * (1.0 - smoothstep(base_outer_radius - 0.06, base_outer_radius, r));

	// Tangential erosion (energy flowing around the ring)
	float erosion = noise(angle * noise_frequency - TIME * 2.0);
	ring *= smoothstep(0.25, 1.0, erosion);

	// Color blending driven by angular noise
	float color_mix = noise(angle * noise_frequency + TIME * 0.5);
	vec4 color = mix(core_color, edge_color, color_mix);

	// Glow shaping
	color.rgb *= pow(ring, 0.35) * glow_power;

	COLOR = vec4(color.rgb, ring);
}
