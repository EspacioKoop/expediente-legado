// Interrupción CRT opt-in para planos 3D del montaje onírico 1998.
//
// Efecto breve de "señal perdida": scanlines, desincronía vertical, ruido
// analógico y corte a negro momentáneo. Se activa por plano con
// `interrupcion_crt: true` y respeta `reduccion_movimiento` (sin parpadeo).
shader_type canvas_item;

uniform float intensidad : hint_range(0.0, 1.0) = 0.6;
uniform float duracion : hint_range(0.05, 1.0) = 0.15;
uniform float semilla : hint_range(0.0, 1000.0) = 0.0;
uniform bool quieto = false;

float azar(vec2 p, float s) {
    return fract(sin(dot(p + vec2(s, s * 2.3), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    float t = quieto ? 0.0 : TIME;
    float fase = fract(t / duracion);
    float pulso = smoothstep(0.0, 0.5, fase) * smoothstep(1.0, 0.5, fase);
    float activo = step(0.01, pulso) * intensidad;

    if (activo < 0.01) {
        COLOR = vec4(0.0);
        return;
    }

    vec2 uv = FRAGCOORD.xy / vec2(1920.0, 1080.0);
    float scanline = 0.7 + 0.3 * sin(uv.y * 240.0 * 3.14159265 + t * 40.0);
    float desincronia = sin(t * 60.0 + uv.x * 10.0) * 0.02;
    float ruido = azar(uv * 100.0 + vec2(t * 17.0, semilla), semilla) - 0.5;
    float roll = sin(t * 8.0) * 0.005;

    vec2 uv_dist = uv + vec2(desincronia + roll, 0.0);
    float viñeta = 1.0 - smoothstep(0.3, 0.9, length(uv_dist - 0.5) * 1.2);

    COLOR = vec4(vec3(0.15 + ruido * 0.1) * scanline * viñeta, activo);
}