// Halo de la silueta del rival en el Juicio: segunda pasada aditiva que solo
// ilumina el contorno (fresnel). La silueta sigue sin cara ni textura; el halo
// solo la despega del fondo y le da el color del mito.
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_back;

uniform vec3 color : source_color = vec3(0.6, 0.5, 0.3);
uniform float fuerza = 1.4;
uniform float afilado = 2.6;

void fragment() {
	float borde = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), afilado);
	ALBEDO = color * borde * fuerza;
}
