shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 paper_color : source_color = vec4(0.84, 0.82, 0.74, 1.0);
uniform float deformation : hint_range(0.0, 0.02) = 0.0055;

void vertex() {
	float n = sin(VERTEX.x * 121.0 + VERTEX.y * 77.0)
		+ sin(VERTEX.y * 143.0 - VERTEX.z * 91.0)
		+ sin(VERTEX.z * 109.0 + VERTEX.x * 63.0);
	VERTEX += NORMAL * n * deformation / 3.0;
}

void fragment() {
	float fibers = 0.025 * sin(UV.x * 510.0) * sin(UV.y * 390.0);
	ALBEDO = paper_color.rgb + vec3(fibers);
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
}
