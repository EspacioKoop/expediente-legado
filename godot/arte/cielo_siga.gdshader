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
uniform vec3 resplandor_direccion = vec3(0.72, 0.0, -0.69);
uniform float resplandor_asimetria : hint_range(0.0, 1.0) = 0.55;
uniform vec4 bruma_horizonte : source_color = vec4(0.20, 0.19, 0.22, 1.0);
uniform float bruma_fuerza : hint_range(0.0, 1.0) = 0.32;
uniform vec4 nube_color : source_color = vec4(0.12, 0.13, 0.17, 1.0);
uniform float nubes : hint_range(0.0, 1.0) = 0.28;
uniform vec4 cirro_color : source_color = vec4(0.16, 0.17, 0.20, 1.0);
uniform float cirros : hint_range(0.0, 1.0) = 0.18;
uniform float luz_lunar_nubes : hint_range(0.0, 1.0) = 0.32;
uniform vec3 via_lactea_normal = vec3(0.18, 0.84, -0.51);
uniform vec4 via_lactea_color : source_color = vec4(0.16, 0.17, 0.22, 1.0);
uniform float via_lactea : hint_range(0.0, 1.0) = 0.08;
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

	// La contaminación no forma un aro perfecto: una ciudad ilumina más en la
	// dirección del centro y deja respirar el cielo del lado contrario.
	float bajo = 1.0 - smoothstep(0.0, 0.28, EYEDIR.y);
	vec2 horizontal = EYEDIR.xz;
	vec2 vista_azimut = horizontal / max(length(horizontal), 0.0001);
	vec2 ciudad_azimut = normalize(resplandor_direccion.xz);
	float foco_ciudad = pow(max(dot(vista_azimut, ciudad_azimut), 0.0), 2.0);
	float mascara_ciudad = mix(1.0, foco_ciudad, resplandor_asimetria);
	float luz_ciudad = bajo * resplandor_fuerza * mascara_ciudad * step(0.0, EYEDIR.y + 0.05);
	base = mix(base, resplandor_ciudad.rgb, luz_ciudad);

	// Una capa corta de contaminación y humedad separa fachadas del cielo alto.
	float bruma = (1.0 - smoothstep(0.02, 0.24, EYEDIR.y)) * step(0.0, EYEDIR.y);
	base = mix(base, bruma_horizonte.rgb, bruma * bruma_fuerza);

	vec3 luna = normalize(luna_direccion);
	float cercania = distance(EYEDIR, luna);
	float halo_nubes = smoothstep(luna_tamano * 13.0, luna_tamano * 2.5, cercania);

	// Nubes bajas estáticas: masas anchas que recogen algo de luz lunar.
	float onda_a = sin(EYEDIR.x * 19.0 + EYEDIR.z * 13.0 + EYEDIR.y * 5.0);
	float onda_b = sin(EYEDIR.x * -31.0 + EYEDIR.z * 23.0 - EYEDIR.y * 7.0);
	float ruido_nube = onda_a * 0.34 + onda_b * 0.16 + 0.5;
	float franja_nube = smoothstep(0.08, 0.22, EYEDIR.y) * (1.0 - smoothstep(0.58, 0.82, EYEDIR.y));
	float mascara_nube = smoothstep(0.54, 0.72, ruido_nube) * franja_nube;
	vec3 nube_iluminada = mix(nube_color.rgb, luna_color.rgb, halo_nubes * luz_lunar_nubes);
	base = mix(base, nube_iluminada, mascara_nube * nubes);

	// Cirros altos: más finos y separados de la capa baja para que el cielo
	// tenga profundidad incluso sin mover una sola nube.
	float cirro_a = sin(EYEDIR.x * 41.0 + EYEDIR.z * 17.0 - EYEDIR.y * 11.0);
	float cirro_b = sin(EYEDIR.x * -67.0 + EYEDIR.z * 29.0 + EYEDIR.y * 19.0);
	float ruido_cirro = cirro_a * 0.28 + cirro_b * 0.12 + 0.5;
	float franja_cirro = smoothstep(0.30, 0.46, EYEDIR.y) * (1.0 - smoothstep(0.78, 0.94, EYEDIR.y));
	float mascara_cirro = smoothstep(0.56, 0.70, ruido_cirro) * franja_cirro;
	vec3 cirro_iluminado = mix(cirro_color.rgb, luna_color.rgb, halo_nubes * luz_lunar_nubes * 0.75);
	base = mix(base, cirro_iluminado, mascara_cirro * cirros);

	// La Vía Láctea apenas vence la contaminación. No es una franja pintada:
	// el grano por celda rompe su borde y desaparece cerca del horizonte urbano.
	vec3 normal_via = normalize(via_lactea_normal);
	float distancia_via = abs(dot(EYEDIR, normal_via));
	float banda_via = (1.0 - smoothstep(0.035, 0.17, distancia_via)) * smoothstep(0.18, 0.50, EYEDIR.y);
	vec3 celda_via = floor(EYEDIR * 74.0 + vec3(3.0, 11.0, 19.0));
	float grano_via = fract(sin(dot(celda_via, vec3(21.347, 57.113, 91.733))) * 31821.431);
	float bloqueo_nubes = clamp(mascara_nube * nubes + mascara_cirro * cirros, 0.0, 1.0);
	float visibilidad_via = banda_via * via_lactea * mix(0.30, 1.0, grano_via);
	visibilidad_via *= (1.0 - luz_ciudad * 0.80) * (1.0 - bloqueo_nubes * 0.85);
	base += via_lactea_color.rgb * visibilidad_via;

	float disco_luna = smoothstep(luna_tamano, luna_tamano * 0.8, cercania);
	// Sombra desplazada: una luna menguante, no un foco redondo.
	float sombra = smoothstep(luna_tamano * 0.85, luna_tamano * 0.65, distance(EYEDIR, normalize(luna + vec3(0.02, 0.012, 0.0))));
	base = mix(base, luna_color.rgb, disco_luna * (1.0 - sombra * 0.85));
	base += luna_color.rgb * luna_halo * smoothstep(luna_tamano * 5.0, 0.0, cercania);

	// Dos tamaños y dos temperaturas de estrella. La variación es fija: da
	// profundidad cromática sin parpadeo ni coste de actualización.
	vec3 celda = floor(EYEDIR * 180.0);
	float h = fract(sin(dot(celda, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
	vec3 celda_lejana = floor(EYEDIR * 93.0 + vec3(7.0, 13.0, 3.0));
	float h2 = fract(sin(dot(celda_lejana, vec3(39.346, 11.135, 83.155))) * 24634.6345);
	float tono = fract(sin(dot(celda, vec3(17.31, 43.17, 71.91))) * 12973.173);
	vec3 estrella_fria = vec3(0.72, 0.79, 0.92);
	vec3 estrella_calida = vec3(0.94, 0.84, 0.70);
	vec3 color_estrella = mix(estrella_fria, estrella_calida, step(0.72, tono));
	float alto = smoothstep(0.18, 0.55, EYEDIR.y);
	float cielo_despejado = 1.0 - bloqueo_nubes * 0.90;
	float estrella_grande = step(1.0 - 0.0025 * estrellas, h);
	float estrella_pequena = step(1.0 - 0.0014 * estrellas_secundarias, h2);
	base += color_estrella * (estrella_grande + estrella_pequena * 0.45) * alto * cielo_despejado;

	COLOR = floor(base * bandas + 0.5) / bandas;
}
