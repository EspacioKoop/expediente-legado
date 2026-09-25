// Salpicaduras de lluvia en toda la calzada (efectos ligeros). Un plano con
// una rejilla de celdas de ~40 cm: en cada una nace un anillo pequeño en un
// momento propio y se apaga. Sin partículas.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;

// 0 con reducción de movimiento: los anillos se quedan quietos y tenues.
uniform float velocidad = 1.0;
// Tamaño del plano en metros, para que la celda mida lo mismo en cualquier suelo.
uniform vec2 escala = vec2(8.0, 32.0);
uniform float celda = 0.4;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 metros = UV * escala / celda;
	vec2 id = floor(metros);
	vec2 dentro = fract(metros) - 0.5;
	float semilla = azar(id);
	// Solo una de cada tres celdas salpica en cada ciclo.
	float ciclo = fract(TIME * velocidad * (0.9 + semilla * 0.8) + semilla * 7.0);
	float activa = step(0.66, azar(id + floor(TIME * velocidad * 0.9 + semilla * 7.0)));
	vec2 centro = vec2(azar(id + 3.1), azar(id + 5.7)) * 0.5 - 0.25;
	float radio = ciclo * 0.35;
	float anillo = smoothstep(0.03, 0.0, abs(length(dentro - centro) - radio));
	float brillo = anillo * (1.0 - ciclo) * activa;
	ALBEDO = vec3(0.55, 0.62, 0.72) * brillo;
	ALPHA = brillo;
}
