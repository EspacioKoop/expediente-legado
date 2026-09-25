// Neblina baja del sueño (efectos ligeros): un plano grande a ras de suelo con
// ruido que se desplaza despacio. Se desvanece en los bordes y cerca de la
// cámara para no tapar el suelo que se pisa. Sin partículas.
shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never, shadows_disabled;

// 0 con reducción de movimiento: la neblina está, pero no se mueve.
uniform float velocidad = 1.0;
uniform vec3 color : source_color = vec3(0.72, 0.74, 0.82);
uniform float densidad = 0.35;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = azar(i);
	float b = azar(i + vec2(1.0, 0.0));
	float c = azar(i + vec2(0.0, 1.0));
	float d = azar(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float t = TIME * velocidad * 0.03;
	vec2 p = UV * 6.0;
	float n = ruido(p + vec2(t, t * 0.6)) * 0.6 + ruido(p * 2.1 - vec2(t * 1.3, 0.0)) * 0.4;
	float borde = smoothstep(0.5, 0.3, length(UV - 0.5));
	float cerca = smoothstep(0.6, 3.0, length(VERTEX));
	ALBEDO = color;
	ALPHA = smoothstep(0.35, 0.8, n) * densidad * borde * cerca;
}
