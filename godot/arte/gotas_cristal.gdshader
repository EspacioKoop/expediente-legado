// Gotas que resbalan por una ventana cuando llueve (efectos ligeros). Va en un
// quad pegado al cristal: columnas de gotas que bajan a ritmos distintos y
// dejan un rastro, sin partículas ni texturas.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never;

// 0 con reducción de movimiento: el cristal sigue mojado, las gotas quietas.
uniform float velocidad = 1.0;
uniform float columnas = 22.0;

float azar(float x) {
	return fract(sin(x * 91.3458) * 47453.5453);
}

void fragment() {
	vec2 uv = UV;
	float columna = floor(uv.x * columnas);
	float semilla = azar(columna + 1.0);
	float t = TIME * velocidad * (0.08 + semilla * 0.12) + semilla * 10.0;
	float y = fract(uv.y - t);
	float x = fract(uv.x * columnas) - 0.5;
	// Cabeza de la gota: redonda; rastro: fino y más tenue por encima.
	float gota = smoothstep(0.18, 0.05, length(vec2(x, (y - 0.92) * 3.5)));
	float rastro = smoothstep(0.06, 0.0, abs(x)) * smoothstep(0.92, 0.55, y) * 0.35;
	// Solo algunas columnas llevan gota a la vez.
	float activa = step(0.45, semilla);
	float intensidad = (gota + rastro) * activa;
	ALBEDO = vec3(0.82, 0.88, 0.95);
	ALPHA = intensidad * 0.55;
}
