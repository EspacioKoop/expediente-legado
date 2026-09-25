// Suelo del Juicio por Combate: losa de piedra oscura con un círculo ritual
// grabado (anillos, marcas radiales y un borde que se apaga hacia fuera). El
// grabado lleva el color del mito y brilla poco: se lee desde la cámara alta
// sin competir con el aviso rojo del ataque rival.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec3 piedra : source_color = vec3(0.13, 0.13, 0.14);
uniform vec3 grabado : source_color = vec3(0.55, 0.45, 0.25);
// Radio del disco en metros: los anillos se colocan en metros, no en UV.
uniform float radio = 6.5;
uniform float radio_ritual = 4.0;
uniform float brillo = 0.55;

varying vec3 local;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1, 0)), f.x), mix(azar(i + vec2(0, 1)), azar(i + vec2(1, 1)), f.x), f.y);
}

float linea(float d, float r, float grosor) {
	return smoothstep(grosor, 0.0, abs(d - r));
}

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 p = local.xz;
	float d = length(p);
	float ang = atan(p.y, p.x);
	// Losas: juntas radiales y concéntricas, como un suelo de templo.
	float anillo_losa = fract(d / 1.15);
	float sector = fract(ang / 6.2831853 * (d < 2.3 ? 8.0 : 16.0));
	float junta = max(smoothstep(0.035, 0.0, anillo_losa) , smoothstep(0.02, 0.0, min(sector, 1.0 - sector)) * step(0.6, d));
	float grano = ruido(p * 3.0) * 0.5 + ruido(p * 11.0) * 0.25;
	vec3 color = piedra * (0.82 + grano * 0.35) * (1.0 - junta * 0.45);

	// Círculo ritual: dos anillos en el límite y marcas. Nada en el centro: un
	// anillo alrededor del jugador se leía como un círculo de selección.
	float trazo = linea(d, radio_ritual, 0.035) + linea(d, radio_ritual - 0.22, 0.02);
	float marcas = step(0.965, fract(ang / 6.2831853 * 24.0 + 0.5)) * step(radio_ritual - 0.22, d) * step(d, radio_ritual);
	trazo = clamp(trazo + marcas, 0.0, 1.0);
	color = mix(color, grabado, trazo * 0.85);

	// El borde se hunde en la oscuridad: la arena no acaba en un canto.
	float borde = smoothstep(radio, radio - 1.6, d);
	ALBEDO = color * borde;
	EMISSION = grabado * trazo * brillo * borde;
	ROUGHNESS = 0.78 - junta * 0.2;
	SPECULAR = 0.3;
}
