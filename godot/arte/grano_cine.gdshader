// Grano y viñeta de las cinemáticas (#395). Va por encima de la imagen y por
// debajo de las franjas y el rótulo: texturiza el plano, nunca el texto.
//
// Modo "no estroboscópico" para montaje onírico 1998: grano que respira
// en vez de parpadear a 24Hz; usa tiempo continuo y octavas de ruido.
shader_type canvas_item;

uniform float grano : hint_range(0.0, 0.3) = 0.045;
uniform float vineta : hint_range(0.0, 1.0) = 0.35;
// Con reducción de movimiento el grano no parpadea: se queda quieto.
uniform bool quieto = false;
// Modo no estroboscópico: grano continuo tipo película, sin salto de frame.
uniform bool no_estroboscopico = false;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float ruido_octavas(vec2 p, float t) {
    float n = 0.0;
    n += azar(p * 1.0 + vec2(t * 0.7, t * 1.3)) * 0.5;
    n += azar(p * 2.3 + vec2(t * 1.1, t * 0.9)) * 0.25;
    n += azar(p * 4.7 + vec2(t * 0.5, t * 1.7)) * 0.125;
    n += azar(p * 8.1 + vec2(t * 1.9, t * 0.3)) * 0.0625;
    return n - 0.5;
}

void fragment() {
	float t = quieto ? 0.0 : (no_estroboscopico ? TIME : floor(TIME * 24.0));
	float ruido = no_estroboscopico 
        ? ruido_octavas(FRAGCOORD.xy * 0.01, t) 
        : azar(FRAGCOORD.xy + t) - 0.5;
	vec2 centro = UV - 0.5;
	float borde = smoothstep(0.35, 0.85, length(centro * vec2(1.0, 0.8)));
	float oscuro = borde * vineta;
	// Grano en gris neutro sobre transparente, más la viñeta como negro.
	COLOR = vec4(vec3(0.5 + ruido), abs(ruido) * grano * 2.0);
	COLOR = mix(COLOR, vec4(0.0, 0.0, 0.0, 1.0), oscuro);
}
