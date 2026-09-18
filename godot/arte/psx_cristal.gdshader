// Vidrio urbano compatible con el tratamiento PSX de #115/#399.
//
// Mantiene el temblor de vértices, la cuantización y el dithering del shader
// espacial canónico, pero entra en la tubería transparente para escaparates y
// puertas de cristal. El patrón de suciedad sigue siendo triplanar para que la
// escala no dependa de las dimensiones de cada paño.
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, vertex_lighting, diffuse_lambert, specular_disabled;

uniform vec4 color_base : source_color = vec4(0.55, 0.65, 0.72, 0.22);
uniform sampler2D textura : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform bool con_textura = true;
uniform float escala_textura = 1.4;
uniform float emision_fuerza : hint_range(0.0, 1.0, 0.05) = 0.1;
uniform float rejilla = 190.0;
uniform float tonos = 32.0;
uniform float dithering : hint_range(0.0, 1.0, 0.05) = 0.45;

varying vec3 mundo;


void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec4 proyectado = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 normalizado = proyectado.xy / max(abs(proyectado.w), 0.0001);
	normalizado = round(normalizado * rejilla) / rejilla;
	proyectado.xy = normalizado * abs(proyectado.w);
	POSITION = proyectado;
}


vec3 muestra_triplanar(vec3 punto, vec3 normal) {
	vec3 peso = abs(normal);
	peso /= max(peso.x + peso.y + peso.z, 0.0001);
	vec3 p = punto * escala_textura;
	return texture(textura, p.zy).rgb * peso.x
		+ texture(textura, p.xz).rgb * peso.y
		+ texture(textura, p.xy).rgb * peso.z;
}


float bayer_2x2(vec2 pixel) {
	int x = int(mod(pixel.x, 2.0));
	int y = int(mod(pixel.y, 2.0));
	if (x == 0 && y == 0) {
		return 0.0;
	}
	if (x == 1 && y == 0) {
		return 2.0;
	}
	if (x == 0 && y == 1) {
		return 3.0;
	}
	return 1.0;
}


float bayer_4x4(vec2 pixel) {
	vec2 entero = floor(pixel);
	float menor = bayer_2x2(mod(entero, 2.0));
	float mayor = bayer_2x2(mod(floor(entero / 2.0), 2.0));
	return (menor * 4.0 + mayor + 0.5) / 16.0;
}


void fragment() {
	vec3 color = color_base.rgb;
	if (con_textura) {
		color *= muestra_triplanar(mundo, NORMAL);
	}

	float niveles = max(tonos, 1.0);
	float error_ordenado = (bayer_4x4(FRAGCOORD.xy) - 0.5) * dithering / niveles;
	color = clamp(color + vec3(error_ordenado), vec3(0.0), vec3(1.0));
	vec3 cuantizado = floor(color * niveles) / niveles;
	ALBEDO = cuantizado;
	EMISSION = cuantizado * emision_fuerza;
	ALPHA = color_base.a;
}
