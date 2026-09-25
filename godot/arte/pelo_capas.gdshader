// Pelo por capas (#275): barba, bigote y pelo corto sobre avatares Rocketbox.
//
// Cada capa es la propia piel de la cara, desplazada hacia fuera por la
// normal. Aquí se recorta en mechones: la UV de la cara se parte en celdas y
// cada celda es un pelo que adelgaza con la altura de la capa, así que la
// base es densa y la punta rala. COLOR.r trae la altura de la capa (0 piel,
// 1 punta) y COLOR.g la máscara de la región, que apura el borde.
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_lambert, specular_disabled;

uniform vec4 raiz : source_color = vec4(0.10, 0.08, 0.06, 1.0);
uniform vec4 punta : source_color = vec4(0.30, 0.26, 0.21, 1.0);
// Pelos por unidad de UV. La cara de Rocketbox ocupa ~medio atlas.
uniform float densidad = 200.0;
// Grosor del pelo en la raíz, en fracción de celda.
uniform float grosor = 0.8;
// Cuánto varía el tono de un pelo a otro: las canas salen de aquí.
uniform float variacion = 0.35;
// Cuánta piel tapa la capa de base: 1 es pelo cerrado (bigote, cabeza), menos
// deja ver la piel entre pelos como en una barba de pocos días.
uniform float cobertura = 0.85;

varying float altura;
varying float mascara;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	altura = COLOR.r;
	mascara = COLOR.g;
}

void fragment() {
	vec2 p = UV * densidad;
	vec2 celda = floor(p);
	vec2 dentro = fract(p) - 0.5;
	float semilla = azar(celda);
	vec2 centro = vec2(azar(celda + 1.7), azar(celda + 4.3)) * 0.5 - 0.25;
	// Los pelos cortos acaban antes: no todos llegan a la punta.
	float largo = mix(0.55, 1.0, semilla) * smoothstep(0.0, 0.35, mascara);
	float radio = grosor * (1.0 - altura / max(largo, 0.001));
	// El borde de la región se deshilacha en vez de acabar en línea.
	if (mascara < semilla * 0.85) {
		discard;
	}
	// La capa 0 es la sombra de la barba sobre la piel. Las demás, solo el pelo.
	if (altura < 0.01) {
		// Base: sombra de barba con piel asomando entre pelos, no un fieltro.
		if (azar(celda + 2.3) > cobertura * mascara) {
			discard;
		}
	} else if (length(dentro - centro) > radio * 0.5) {
		discard;
	}
	float tono = mix(1.0 - variacion, 1.0 + variacion * 0.5, azar(celda + 9.1));
	vec3 color = mix(raiz.rgb, punta.rgb, altura) * tono;
	ALBEDO = color;
	// Oclusión de raíz: entre pelos no entra la luz.
	AO = mix(0.65, 1.0, altura);
	ROUGHNESS = 0.85;
}
