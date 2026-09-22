// El mismo aspecto de 32 bits, pero con la luz calculada por PÍXEL.
//
// No es otro tratamiento: el cuerpo de este shader es BYTE A BYTE el de
// `psx.gdshader` a partir del primer uniform, y `scripts/test_iluminacion_789.py`
// falla si los dos se separan. Lo único que cambia es el `render_mode`, y por
// eso existe este fichero en vez de un parámetro: el modo de iluminación se fija
// al compilar y no hay uniform que pueda cambiarlo en marcha.
//
// POR QUÉ. La luz por vértice es uno de los cuatro rasgos deliberados de la
// máquina que se imita (#115), y donde hay superficie suficiente se sostiene
// sola. Pero NO aplica sombras: las que #1121 encendió al pasar a Forward+ se
// calculaban y el material las tiraba, así que en la oficina no había una sola
// sombra de contacto y las figuras humanas —pocos vértices y muy juntos— salían
// como siluetas negras. Medido renderizando el mismo encuadre con y sin
// `vertex_lighting` (#789).
//
// DÓNDE SE USA. Solo lo pide el sitio que lo necesita, con `luz_por_pixel` en su
// entrada del catálogo. El mundo que no lo pide sigue compilando exactamente el
// shader canónico, así que calle, casa y sueño no cambian ni un píxel y las
// líneas base de #399, #282 y #284 siguen valiendo.
//
// El precedente de tener una variante opt-in del tratamiento PSX en vez de
// tocar el canónico es `psx_pbr.gdshader` (#399).
//
// Los comentarios del cuerpo describen el shader canónico y se copian tal cual,
// incluido el que enumera la luz por vértice entre sus rasgos: son los suyos, y
// reescribirlos aquí rompería la igualdad byte a byte que los mantiene unidos.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 color_base : source_color = vec4(1.0);
// Filtro lineal con mipmaps, no `filter_nearest`: estas texturas vienen de
// fotografía a 1024 y con NEAREST sin mipmaps una pared lejana centellea a
// cada paso. El aspecto de la máquina lo siguen dando el temblor de
// vértices, la luz por vértice, el color cortado y el dithering.
uniform sampler2D textura : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
// El sueño puede pedir un mip algo más nítido sin renunciar a mipmaps.
// El mundo normal deja el sesgo en 0 y conserva exactamente el filtrado base.
uniform bool preservar_detalle_textura = false;
uniform float sesgo_detalle_textura = -1.0;
uniform bool con_textura = false;
// Los assets con atlas conservan sus UV; el escenario sigue siendo triplanar.
uniform bool usar_uv = false;
uniform float escala_textura = 1.0;
// Warp opt-in por ejes. El mundo ordinario deja este vector en 1,1,1;
// el sueño puede estirar o invertir una superficie reconocible sin necesitar
// otra textura ni romper el contrato triplanar.
uniform vec3 deformacion_textura = vec3(1.0);
uniform vec4 emision : source_color = vec4(0.0);
uniform float emision_fuerza = 0.0;

// VIENTO. Balanceo opt-in en el dominio de vértices (#1230). La fuerza en cero
// —lo normal— no toca un solo vértice: un muro y una farola siguen dibujándose
// exactamente igual que antes de existir esto. Solo lo pide el follaje.
//
// La amplitud crece con la altura sobre el pivote del modelo, que es donde un
// árbol tiene el tronco: abajo no se mueve nada y arriba se mueve la copa.
uniform float viento_fuerza = 0.0;
uniform vec2 viento_direccion = vec2(1.0, 0.0);
uniform float viento_frecuencia = 1.1;
// A qué altura sobre el pivote el balanceo ya es pleno. Un árbol de seis metros
// y un arbusto de uno no pueden compartir la misma rampa.
uniform float viento_altura = 4.0;

// RESPIRACIÓN. El sueño hincha y deshincha la superficie a lo largo de su
// normal (#1230). Va aquí, en el vértice, y no en la transformación del nodo,
// **a propósito**: el muro que ves respira y el muro contra el que chocas no se
// mueve ni un milímetro. Una animación no puede abrir un agujero por donde
// caerse (#784).
uniform float respiracion_fuerza = 0.0;
uniform float respiracion_frecuencia = 0.14;
uniform float respiracion_fase = 0.0;

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
	if (viento_fuerza > 0.0) {
		vec2 direccion = length(viento_direccion) > 0.0001
			? normalize(viento_direccion)
			: vec2(1.0, 0.0);
		// El desfase por posición del modelo evita que un bosque entero se
		// incline a la vez, que es lo que delata un balanceo de escaparate.
		float desfase = (MODEL_MATRIX[3].x + MODEL_MATRIX[3].z) * 0.6;
		float rampa = clamp(VERTEX.y / max(viento_altura, 0.0001), 0.0, 1.0);
		float ola = sin(TIME * viento_frecuencia + desfase + VERTEX.y * 0.25);
		// Una racha no es una onda pura: la segunda armónica la despeina.
		ola += 0.35 * sin(TIME * viento_frecuencia * 2.7 + desfase);
		VERTEX.xz += direccion * ola * viento_fuerza * rampa;
	}
	if (respiracion_fuerza > 0.0) {
		float pulso = sin(TIME * respiracion_frecuencia * TAU + respiracion_fase);
		VERTEX += NORMAL * pulso * respiracion_fuerza;
	}

	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec4 proyectado = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	// Se redondea en coordenadas normalizadas y se devuelve a las de recorte,
	// que es donde la rejilla es la de la pantalla y no la del modelo.
	vec2 normalizado = proyectado.xy / max(abs(proyectado.w), 0.0001);
	normalizado = round(normalizado * rejilla) / rejilla;
	proyectado.xy = normalizado * abs(proyectado.w);
	POSITION = proyectado;
}

vec3 muestra_2d(vec2 uv) {
	float sesgo = preservar_detalle_textura ? sesgo_detalle_textura : 0.0;
	return texture(textura, uv, sesgo).rgb;
}

// Triplanar a mano: tres muestras y mezcla por la normal. Lo hace el material
// estándar, pero al escribir un shader propio hay que traérselo.
vec3 muestra_triplanar(vec3 punto, vec3 normal) {
	vec3 peso = abs(normal);
	peso /= max(peso.x + peso.y + peso.z, 0.0001);
	vec3 p = punto * escala_textura * deformacion_textura;
	return muestra_2d(p.zy) * peso.x
		+ muestra_2d(p.xz) * peso.y
		+ muestra_2d(p.xy) * peso.z;
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
		if (usar_uv) {
			color = muestra_2d(UV) * color_base.rgb;
		} else {
			color = muestra_triplanar(mundo, NORMAL);
		}
	}

	float niveles = max(tonos, 1.0);
	float error_ordenado = (bayer_4x4(FRAGCOORD.xy) - 0.5) * dithering / niveles;
	color = clamp(color + vec3(error_ordenado), vec3(0.0), vec3(1.0));
	ALBEDO = floor(color * niveles) / niveles;
	EMISSION = emision.rgb * emision_fuerza;
}
