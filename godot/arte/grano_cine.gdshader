// Grano y viñeta de las cinemáticas (#395). Va por encima de la imagen y por
// debajo de las franjas y el rótulo: texturiza el plano, nunca el texto.
shader_type canvas_item;

uniform float grano : hint_range(0.0, 0.3) = 0.045;
uniform float vineta : hint_range(0.0, 1.0) = 0.35;
// Con reducción de movimiento el grano no parpadea: se queda quieto.
uniform bool quieto = false;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float semilla = quieto ? 0.0 : floor(TIME * 24.0);
	float ruido = azar(FRAGCOORD.xy + semilla) - 0.5;
	vec2 centro = UV - 0.5;
	float borde = smoothstep(0.35, 0.85, length(centro * vec2(1.0, 0.8)));
	float oscuro = borde * vineta;
	// Grano en gris neutro sobre transparente, más la viñeta como negro.
	COLOR = vec4(vec3(0.5 + ruido), abs(ruido) * grano * 2.0);
	COLOR = mix(COLOR, vec4(0.0, 0.0, 0.0, 1.0), oscuro);
}
