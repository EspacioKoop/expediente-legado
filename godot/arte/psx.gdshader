// El aspecto de una consola de 32 bits, en un solo sitio.
//
// Cuatro cosas y ninguna es un filtro sobre la interfaz: son cómo dibujaba
// aquella máquina, y por eso van en el material del mundo 3D.
//
// 1. TEMBLOR DE VÉRTICES. Los vértices caen en una rejilla de pantalla y las
//    aristas bailan al mover la cámara.
// 2. LUZ POR VÉRTICE (`vertex_lighting`). La luz se calcula en las esquinas y
//    se interpola sobre la cara.
// 3. COLOR CORTADO. El color se escalona antes de llegar al framebuffer.
// 4. DITHERING ORDENADO. Un patrón Bayer 4x4 reparte el error de cuantización
//    entre píxeles vecinos. Se aplica aquí, en los materiales 3D, para que el
//    visor, los documentos y el HUD sigan completamente limpios y legibles.
//
// Lo que NO hace es el mapeado AFÍN —esa deformación de las texturas al girar
// una pared—, y es una renuncia consciente: exige coordenadas por cara, y aquí
// la textura se pega en coordenadas del mundo (triplanar) para que un muro de
// catorce metros y uno de dos tengan el mismo grano. Se puede tener una cosa o
// la otra, y la escala consistente vale más.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

uniform vec4 color_base : source_color = vec4(1.0);
// Filtro lineal con mipmaps, no `filter_nearest`: estas texturas vienen de
// fotografía a 1024 y con NEAREST sin mipmaps una pared lejana centellea a
// cada paso. El aspecto de la máquina lo siguen dando el temblor de
// vértices, la luz por vértice, el color cortado y el dithering.
uniform sampler2D textura : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform bool con_textura = false;
uniform float escala_textura = 1.0;
uniform vec4 emision : source_color = vec4(0.0);
uniform float emision_fuerza = 0.0;

// Lo fina que es la rejilla donde caen los vértices. Más alto es más limpio;
// por debajo de ~120 el temblor deja de leerse como una máquina y empieza a
// leerse como un fallo.
uniform float rejilla = 190.0;
// Cuántos escalones de color. 32 por canal es aproximadamente lo que daba un
// framebuffer de 15 bits.
uniform float tonos = 32.0;
// 0 apaga el patrón; 1 reparte aproximadamente un escalón completo de error.
// El valor por defecto es deliberadamente moderado: debe verse como limitación
// de color, no como una trama decorativa sobre toda la imagen.
uniform float dithering : hint_range(0.0, 1.0, 0.05) = 0.65;

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec4 proyectado = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// Se redondea en coordenadas normalizadas y se devuelve a las de recorte,
	// que es donde la rejilla es la de la pantalla y no la del modelo.
	vec2 normalizado = proyectado.xy / max(abs(proyectado.w), 0.0001);
	normalizado = round(normalizado * rejilla) / rejilla;
	proyectado.xy = normalizado * abs(proyectado.w);
	POSITION = proyectado;
}

// Triplanar a mano: tres muestras y mezcla por la normal. Lo hace el material
// estándar, pero al escribir un shader propio hay que traérselo.
vec3 muestra_triplanar(vec3 punto, vec3 normal) {
	vec3 peso = abs(normal);
	peso /= max(peso.x + peso.y + peso.z, 0.0001);
	vec3 p = punto * escala_textura;
	return texture(textura, p.zy).rgb * peso.x
		+ texture(textura, p.xz).rgb * peso.y
		+ texture(textura, p.xy).rgb * peso.z;
}

// Índice Bayer 2x2: 0 2 / 3 1. Componiéndolo consigo mismo se obtiene un
// patrón 4x4 con los 16 valores exactamente una vez, sin textura auxiliar.
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
		color = muestra_triplanar(mundo, NORMAL);
	}

	float niveles = max(tonos, 1.0);
	float error_ordenado = (bayer_4x4(FRAGCOORD.xy) - 0.5) * dithering / niveles;
	color = clamp(color + vec3(error_ordenado), vec3(0.0), vec3(1.0));
	ALBEDO = floor(color * niveles) / niveles;
	EMISSION = emision.rgb * emision_fuerza;
}
