shader_type canvas_item;

// Motivo estático para el escaparate (#142). La semilla solo cambia orientación
// y matiz entre aparatos; no depende del reloj, así que el SubViewport puede
// renderizarse una sola vez.
uniform float semilla = 0.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= 1.3333333;

	float lado = mix(-1.0, 1.0, step(1.0, mod(semilla, 2.0)));
	float exterior = 1.0 - smoothstep(0.285, 0.305, length(p));
	float interior = 1.0 - smoothstep(
		0.225,
		0.245,
		length(p - vec2(0.115 * lado, 0.0))
	);
	float luna = max(exterior - interior, 0.0);

	float variante = mod(semilla, 3.0) / 2.0;
	vec3 fondo = vec3(0.012, 0.017, 0.016);
	vec3 verde_crt = vec3(0.58, 0.86, 0.64);
	vec3 ambar_crt = vec3(0.90, 0.72, 0.42);
	vec3 brillo = mix(verde_crt, ambar_crt, variante);
	float scanline = 0.94 + 0.06 * sin(UV.y * 192.0 * 3.14159265);

	COLOR = vec4(mix(fondo, brillo * scanline, luna), 1.0);
}
