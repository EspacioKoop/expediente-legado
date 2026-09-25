// Charco de calle con lluvia (efectos ligeros). Sin partículas: agua oscura
// que refleja el cielo por fresnel, borde irregular que se funde con el
// asfalto y anillos de gota que nacen en puntos fijos y se abren.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform float desfase = 0.0;
// 0 con reducción de movimiento: el charco sigue ahí, las ondas quietas.
uniform float velocidad = 1.0;
uniform vec3 agua = vec3(0.05, 0.06, 0.07);
// Lo que el charco devuelve del cielo nublado: sin esto, en el renderer de
// compatibilidad se leía como una mancha de aceite.
uniform vec3 cielo = vec3(0.46, 0.53, 0.64);

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float anillos(vec2 uv, float t) {
	float suma = 0.0;
	for (int i = 0; i < 5; i++) {
		vec2 centro = vec2(azar(vec2(float(i), desfase)), azar(vec2(desfase, float(i) + 3.0)));
		centro = mix(vec2(0.2), vec2(0.8), centro);
		float ciclo = fract(t * 0.6 + float(i) * 0.37);
		float radio = ciclo * 0.35;
		float d = abs(length(uv - centro) - radio);
		suma += smoothstep(0.02, 0.0, d) * (1.0 - ciclo);
	}
	return suma;
}

void fragment() {
	vec2 c = UV - 0.5;
	// Borde irregular: la mancha no es una elipse perfecta.
	float irregular = 0.42 + 0.05 * sin(atan(c.y, c.x) * 5.0 + desfase);
	float cuerpo = smoothstep(irregular, irregular - 0.12, length(c));
	float t = TIME * velocidad + desfase;
	float onda = anillos(UV, t);
	float rasante = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	ALBEDO = mix(agua, cielo, 0.55 + rasante * 0.4) + vec3(onda * 0.5);
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.9;
	NORMAL_MAP = normalize(vec3(0.5 + onda * 0.25, 0.5 + onda * 0.25, 1.0));
	ALPHA = cuerpo * 0.9;
}
