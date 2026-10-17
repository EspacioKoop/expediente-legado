// Superposición tipográfica irregular opt-in para planos 3D del montaje onírico 1998.
//
// Texto "roto" que aparece y desaparece: caracteres desplazados, ruido,
// corte de línea, scanlines. Se activa por plano con `superposicion_texto`.
// Respeta `reduccion_movimiento` (texto estático legible, sin animación).
shader_type canvas_item;

uniform sampler2D texto_textura;
uniform float intensidad : hint_range(0.0, 1.0) = 0.8;
uniform float ruido_amplitud : hint_range(0.0, 0.1) = 0.02;
uniform float scanline_fuerza : hint_range(0.0, 1.0) = 0.3;
uniform float semilla : hint_range(0.0, 1000.0) = 0.0;
uniform bool quieto = false;

float azar(vec2 p, float s) {
    return fract(sin(dot(p + vec2(s, s * 1.7), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    float t = quieto ? 0.0 : TIME;
    vec2 uv = UV;
    
    // Scanlines base
    float scanline = 1.0 - scanline_fuerza * 0.5 * (1.0 + sin(uv.y * 180.0 * 3.14159265 + t * 20.0));
    
    if (quieto) {
        // En reducción de movimiento: solo muestra el texto limpio con scanlines sutiles
        vec4 txt = texture(texto_textura, uv);
        COLOR = vec4(txt.rgb * scanline, txt.a * intensidad);
        return;
    }
    
    // Desplazamiento irregular por carácter (simulado por bloques UV)
    vec2 bloque = floor(uv * vec2(40.0, 20.0)) / vec2(40.0, 20.0);
    vec2 desplazamiento = vec2(
        (azar(bloque + vec2(0.0, t * 0.5), semilla) - 0.5) * ruido_amplitud * 2.0,
        (azar(bloque + vec2(100.0, t * 0.3), semilla) - 0.5) * ruido_amplitud
    );
    
    // Corte de línea ocasional
    float corte = step(0.98, azar(vec2(uv.x * 10.0, floor(uv.y * 20.0) + t * 2.0), semilla));
    
    vec2 uv_texto = uv + desplazamiento;
    vec4 txt = texture(texto_textura, uv_texto);
    
    float alpha = txt.a * intensidad * (1.0 - corte * 0.7);
    COLOR = vec4(txt.rgb * scanline, alpha);
}