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

void sky() {
	float altura = clamp(EYEDIR.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 base = mix(horizonte.rgb, cielo_alto.rgb, smoothstep(0.08, 0.78, altura));
	float banda_ocaso = 1.0 - smoothstep(0.0, 0.34, abs(EYEDIR.y));
	base = mix(base, ocaso.rgb, banda_ocaso * ocaso_mezcla);

	if (LIGHT0_ENABLED) {
		float disco = smoothstep(sol_tamano, 0.0, distance(EYEDIR, LIGHT0_DIRECTION));
		base += sol_color.rgb * disco * LIGHT0_ENERGY;
	}

	COLOR = floor(base * bandas + 0.5) / bandas;
}
