shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.91, 0.91, 0.87, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.46;
uniform float dimple_scale : hint_range(10.0, 80.0) = 38.0;
uniform float dimple_depth : hint_range(0.0, 1.0) = 0.52;

void fragment() {
	vec2 grid = UV * vec2(dimple_scale, dimple_scale * 0.50);
	float row = floor(grid.y);
	grid.x += mod(row, 2.0) * 0.5;
	vec2 cell = fract(grid) - vec2(0.5);
	float radius = length(cell);
	float mask = 1.0 - smoothstep(0.16, 0.28, radius);
	vec2 direction = normalize(cell + vec2(0.0001));
	vec2 slope = -direction * mask * dimple_depth;

	NORMAL_MAP = vec3(0.5 + slope.x * 0.5, 0.5 + slope.y * 0.5, 1.0);
	ALBEDO = base_color.rgb * (0.985 + mask * 0.015);
	ROUGHNESS = clamp(roughness_value + mask * 0.09, 0.0, 1.0);
	METALLIC = 0.02;
}
