// La luz de una ventana ajena (#1230).
//
// Todas las ventanas animadas de la calle son UN lote MultiMesh y por tanto una
// sola llamada de dibujo. Lo que distingue a cada una viaja en sus datos de
// instancia: el color de la habitación y qué clase de luz es.
//
// El parpadeo no se escribe desde GDScript. Una tele cambia de plano varias
// veces por segundo y eso, hecho en CPU, serían miles de escrituras al buffer
// por minuto para algo que la tarjeta calcula gratis. Desde fuera solo llega
// QUÉ es esa ventana; CÓMO tiembla es asunto del shader.
shader_type spatial;
render_mode unshaded, shadows_disabled;

// Mismos escalones de color que `psx.gdshader`: una ventana no puede ser lo
// único de la calle con color continuo.
uniform float tonos = 32.0;
// Cada cuánto cambia de plano la tele, en segundos.
uniform float plano_tv = 1.4;

varying vec3 luz;
varying float modo;
varying float semilla;

void vertex() {
	luz = INSTANCE_CUSTOM.rgb;
	modo = INSTANCE_CUSTOM.a;
	// La posición de la instancia en el mundo basta como semilla: dos ventanas
	// del mismo edificio nunca comparten alféizar.
	semilla = MODEL_MATRIX[3].y * 3.7 + MODEL_MATRIX[3].z * 1.31;
}

float ruido(float x) {
	return fract(sin(x * 12.9898) * 43758.5453);
}

void fragment() {
	vec3 color = luz;
	if (modo > 0.5) {
		// Un plano dura lo que dura; dentro de él la imagen sigue latiendo.
		float plano = floor(TIME / max(plano_tv, 0.05) + semilla);
		float brillo = 0.45 + 0.95 * ruido(plano + semilla);
		brillo *= 0.92 + 0.08 * sin(TIME * 19.0 + semilla);
		color *= brillo;
	}
	float niveles = max(tonos, 1.0);
	ALBEDO = floor(clamp(color, vec3(0.0), vec3(1.0)) * niveles) / niveles;
}
