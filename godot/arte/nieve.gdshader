shader_type canvas_item;

uniform float semilla = 0.0;
uniform float velocidad = 12.0;
uniform vec4 claro : source_color = vec4(0.86, 0.86, 0.83, 1.0);
uniform vec4 oscuro : source_color = vec4(0.12, 0.12, 0.14, 1.0);

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 celda = floor(UV * vec2(96.0, 72.0));
	float paso = floor(TIME * velocidad);
	float valor = ruido(celda + vec2(paso, semilla * 37.0));
	float banda = smoothstep(0.0, 0.08, abs(fract(UV.y + TIME * 0.12) - 0.5) - 0.42);
	valor = clamp(valor + banda * 0.35, 0.0, 1.0);
	COLOR = mix(oscuro, claro, valor);
}
