// Pantalla del monitor del diorama del menú de inicio (#830).
//
// Comparte la dirección verde/ámbar y las scanlines de `media_luna.gdshader`,
// pero anima un parpadeo lento de contenido en vez de fijarse por semilla: el
// monitor es el foco de luz principal de la escena y debe sentirse "vivo" sin
// ser un elemento legible por sí mismo. `activo` congela la animación cuando
// el jugador pide reducir movimiento.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 color_fosforo : source_color = vec4(0.32, 0.95, 0.55, 1.0);
uniform float tiempo_manual : hint_range(0.0, 1000.0) = 0.0;
uniform bool activo = true;

void fragment() {
	float t = activo ? TIME : tiempo_manual;
	float scanline = 0.85 + 0.15 * sin(UV.y * 180.0 * PI);
	float parpadeo = 0.92 + 0.08 * sin(t * 1.7) + 0.03 * sin(t * 11.0);
	float brillo_borde = smoothstep(0.5, 0.06, distance(UV, vec2(0.5)));
	ALBEDO = color_fosforo.rgb * scanline;
	EMISSION = color_fosforo.rgb * scanline * parpadeo * brillo_borde * 1.4;
}
