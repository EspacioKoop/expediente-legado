// Adaptación mínima para SIGA-98 del concepto de Godot Skies, de Binbun.
// Fuente CC0: https://binbun3d.itch.io/godot-skies
// Código de referencia también publicado como CC0 en:
// https://godotshaders.com/shader/customizable-sky-shader/
//
// No incluye presets ni texturas del pack completo. Conserva solo la idea de
// gradiente día/ocaso/noche y sol ligado a la luz direccional, con una paleta
// más apagada y sin animación continua para no recalcular el cielo cada frame.
shader_type sky;

uniform vec4 cielo_alto : source_color = vec4(0.055, 0.075, 0.11, 1.0);
uniform vec4 horizonte : source_color = vec4(0.18, 0.17, 0.17, 1.0);
uniform vec4 ocaso : source_color = vec4(0.30, 0.16, 0.10, 1.0);
uniform vec4 sol_color : source_color = vec4(0.82, 0.72, 0.54, 1.0);
uniform float ocaso_mezcla : hint_range(0.0, 1.0) = 0.18;
uniform float sol_tamano : hint_range(0.001, 0.08) = 0.012;
uniform float bandas : hint_range(8.0, 128.0) = 42.0;
// Noche urbana de 1998 (#398): luna, pocas estrellas y el resplandor anaranjado
// de las farolas de sodio sobre el horizonte. Todo estático, sin animación.
uniform vec3 luna_direccion = vec3(-0.30, 0.42, 0.86);
uniform vec4 luna_color : source_color = vec4(0.92, 0.90, 0.80, 1.0);
uniform float luna_tamano : hint_range(0.005, 0.1) = 0.035;
uniform float luna_halo : hint_range(0.0, 0.25) = 0.09;
uniform vec4 resplandor_ciudad : source_color = vec4(0.42, 0.24, 0.12, 1.0);
uniform float resplandor_fuerza : hint_range(0.0, 1.0) = 0.55;
uniform vec4 bruma_horizonte : source_color = vec4(0.20, 0.19, 0.22, 1.0);
uniform float bruma_fuerza : hint_range(0.0, 1.0) = 0.32;
uniform vec4 nube_color : source_color = vec4(0.12, 0.13, 0.17, 1.0);
uniform float nubes : hint_range(0.0, 1.0) = 0.28;
uniform float estrellas : hint_range(0.0, 1.0) = 0.5;
uniform float estrellas_secundarias : hint_range(0.0, 1.0) = 0.35;

void sky() {
	float altura = clamp(EYEDIR.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(horizonte.rgb, cielo_alto.rgb, smoothstep(0.08, 0.78, altura));
	float banda_ocaso = 1.0 - smoothstep(0.0, 0.34, abs(EYEDIR.y));
	base = mix(base, ocaso.rgb, banda_ocaso * ocaso_mezcla);

	if (LIGHT0_ENABLED) {
		float disco = smoothstep(sol_tamano, 0.0, distance(EYEDIR, LIGHT0_DIRECTION));
		base += sol_color.rgb * disco * LIGHT0_ENERGY;
	}

	// Resplandor de ciudad: sube desde el horizonte y se apaga hacia lo alto.
	float bajo = 1.0 - smoothstep(0.0, 0.28, EYEDIR.y);
	base = mix(base, resplandor_ciudad.rgb, bajo * resplandor_fuerza * step(0.0, EYEDIR.y + 0.05));

	// Una capa corta de contaminación y humedad separa fachadas del cielo alto.
	float bruma = (1.0 - smoothstep(0.02, 0.24, EYEDIR.y)) * step(0.0, EYEDIR.y);
	base = mix(base, bruma_horizonte.rgb, bruma * bruma_fuerza);

	// Nubes bajas estáticas: dos frecuencias amplias, sin reloj ni textura.
	float onda_a = sin(EYEDIR.x * 19.0 + EYEDIR.z * 13.0 + EYEDIR.y * 5.0);
	float onda_b = sin(EYEDIR.x * -31.0 + EYEDIR.z * 23.0 - EYEDIR.y * 7.0);
	float ruido_nube = onda_a * 0.34 + onda_b * 0.16 + 0.5;
	float franja_nube = smoothstep(0.08, 0.22, EYEDIR.y) * (1.0 - smoothstep(0.58, 0.82, EYEDIR.y));
	float mascara_nube = smoothstep(0.54, 0.72, ruido_nube) * franja_nube;
	base = mix(base, nube_color.rgb, mascara_nube * nubes);

	vec3 luna = normalize(luna_direccion);
	float cercania = distance(EYEDIR, luna);
	float disco_luna = smoothstep(luna_tamano, luna_tamano * 0.8, cercania);
	// Sombra desplazada: una luna menguante, no un foco redondo.
	float sombra = smoothstep(luna_tamano * 0.85, luna_tamano * 0.65, distance(EYEDIR, normalize(luna + vec3(0.02, 0.012, 0.0))));
	base = mix(base, luna_color.rgb, disco_luna * (1.0 - sombra * 0.85));
	base += luna_color.rgb * luna_halo * smoothstep(luna_tamano * 5.0, 0.0, cercania);

	// Dos tamaños de estrella, deterministas y parcialmente tapados por nubes.
	vec3 celda = floor(EYEDIR * 180.0);
	float h = fract(sin(dot(celda, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	vec3 celda_lejana = floor(EYEDIR * 93.0 + vec3(7.0, 13.0, 3.0));
	float h2 = fract(sin(dot(celda_lejana, vec3(39.346, 11.135, 83.155))) * 24634.6345);
	float alto = smoothstep(0.18, 0.55, EYEDIR.y);
	float cielo_despejado = 1.0 - mascara_nube * nubes * 0.9;
	float estrella_grande = step(1.0 - 0.0025 * estrellas, h);
	float estrella_pequena = step(1.0 - 0.0014 * estrellas_secundarias, h2);
	base += vec3(0.75, 0.78, 0.85) * (estrella_grande + estrella_pequena * 0.45) * alto * cielo_despejado;

	COLOR = floor(base * bandas + 0.5) / bandas;
}
