shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_base : source_color = vec4(0.32, 0.31, 0.29, 1.0);
uniform float metallic_amount : hint_range(0.0, 1.0) = 0.0;
uniform float roughness_base : hint_range(0.02, 1.0) = 0.72;
uniform float grime_strength : hint_range(0.0, 1.0) = 0.18;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 8.0) = 0.0;
uniform float micro_scale : hint_range(2.0, 96.0) = 28.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = UV * micro_scale;
	float grain = value_noise(p);
	float broad = value_noise(UV * vec2(6.0, 15.0));
	float streak = smoothstep(0.58, 0.94, value_noise(vec2(UV.x * 10.0, UV.y * 44.0)));
	float grime = clamp(grime_strength * (grain * 0.55 + broad * 0.55), 0.0, 0.82);
	vec3 grime_color = vec3(0.065, 0.058, 0.052);

	ALBEDO = mix(albedo_base.rgb, grime_color, grime);
	METALLIC = metallic_amount;
	ROUGHNESS = clamp(
		roughness_base + (grain - 0.5) * 0.16 - wetness * (0.24 + streak * 0.34),
		0.035,
		1.0
	);
	SPECULAR = mix(0.42, 0.68, wetness);
	EMISSION = emission_color.rgb * emission_energy;
}
