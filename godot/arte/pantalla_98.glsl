// Filtro de pantalla de época para el render 3D (#1270).
//
// Un solo pase de cómputo que se lanza desde `EfectoPantalla98` como
// CompositorEffect: corre ANTES del lienzo 2D, así que el visor y el HUD nunca
// pasan por aquí (frontera de #115: el texto tiene que seguir leyéndose).
//
// Cada grupo de trabajo es dueño de UNA fila entera: la carga en memoria
// compartida, espera y la reescribe en sitio. Todo lo que se lee está en esa
// misma fila, así que nadie pisa lo que otro grupo lee y no hace falta copiar
// el búfer de color. En la GPU integrada de referencia esa copia sola costaba
// 2,6 ms a 1080p.
//
// Coste medido en esa GPU (Intel Alder Lake-N) a 1080p: ~3 ms los paga
// cualquier pase que lea y escriba la pantalla entera, y ~2,5 ms más son el
// filtro. Por eso es opcional y viene apagado.
//
// El sangrado de color y las franjas por codificación YIQ son una adaptación de
// KinoTube (https://github.com/keijiro/KinoTube), vía el port a Godot de
// GodotRetro (https://github.com/ahopness/GodotRetro, `crt_basic.glsl`).
// Aquí se reescribe el muestreo (el port muestreaba a `taps * i` en vez de
// `delta * i`, y leía demasiado para una GPU integrada) conservando la idea:
// crominancia corrida en YIQ y franjas por diferencia de luminancia.
//
//   MIT License
//
//   Copyright (c) 2017 Keijiro Takahashi
//
//   Permission is hereby granted, free of charge, to any person obtaining a copy
//   of this software and associated documentation files (the "Software"), to
//   deal in the Software without restriction, including without limitation the
//   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//   sell copies of the Software, and to permit persons to whom the Software is
//   furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in
//   all copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//   IN THE SOFTWARE.
//
// Líneas de barrido, viñeta, grano y temblor son propios del proyecto.

#[compute]
#version 450

#define HILOS 256
// Ancho máximo que cabe en memoria compartida (8 bytes por píxel, 32 KiB).
// `EfectoPantalla98.ANCHO_MAXIMO` no lanza el pase por encima de esto.
#define ANCHO_MAX 4096

layout(local_size_x = HILOS, local_size_y = 1, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform restrict image2D imagen_color;

// Mismo orden que `EfectoPantalla98.parametros()`. 48 bytes: múltiplo de 16.
layout(push_constant, std430) uniform Parametros {
	vec2 tamano;
	float tiempo;
	float lineas;
	float sangrado;
	float franjas;
	float vineta;
	float grano;
	float temblor;
	float desfase_color;
	float lineas_pantalla;
	float reservado;
} p;

// La fila ya en YIQ y gamma: cada píxel se convierte UNA vez al cargarla, no
// una vez por cada muestra que lo lee (eran cinco).
shared uvec2 fila[ANCHO_MAX];

const float PI = 3.14159265359;

// El compositor trabaja en lineal; YIQ y el grano se piensan en gamma.
vec3 a_gamma(vec3 c) {
	// Gamma 2,0 (raíz y cuadrado) en vez de 2,2: `pow` por muestra era caro y
	// la diferencia no se ve bajo un filtro que ya corre el color.
	return sqrt(max(c, vec3(0.0)));
}

vec3 a_lineal(vec3 c) {
	return c * c;
}

const mat3 A_YIQ = mat3(
	vec3(0.299, 0.596, 0.211), vec3(0.587, -0.274, -0.523), vec3(0.114, -0.322, 0.313)
);
const mat3 A_RGB = mat3(
	vec3(1.0, 1.0, 1.0), vec3(0.956, -0.272, -1.106), vec3(0.621, -0.647, 1.703)
);

// Hash entero (PCG): el azar con `sin` costaba más que el resto del grano.
float azar(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z;
	return float(v.x & 0xFFFFu) / 65535.0;
}

vec4 texel(int x) {
	uvec2 v = fila[x];
	return vec4(unpackHalf2x16(v.x), unpackHalf2x16(v.y));
}

// YIQ interpolado en la fila, a [param x] píxeles.
vec3 leer(float x, float ultimo) {
	float xf = clamp(x - 0.5, 0.0, ultimo);
	int x0 = int(xf);
	int x1 = min(x0 + 1, int(ultimo));
	return mix(texel(x0).xyz, texel(x1).xyz, xf - float(x0));
}

void main() {
	int y = int(gl_WorkGroupID.y);
	int ancho = int(p.tamano.x);
	// Todo el grupo comparte `y`: si sale, sale entero y la barrera no queda coja.
	if (y >= int(p.tamano.y) || ancho > ANCHO_MAX) {
		return;
	}
	for (int x = int(gl_LocalInvocationID.x); x < ancho; x += HILOS) {
		vec4 c = imageLoad(imagen_color, ivec2(x, y));
		vec3 yiq = A_YIQ * a_gamma(clamp(c.rgb, 0.0, 1.0));
		fila[x] = uvec2(packHalf2x16(yiq.xy), packHalf2x16(vec2(yiq.z, c.a)));
	}
	memoryBarrierShared();
	barrier();

	// Lo que solo depende de la fila se calcula una vez por hilo.
	float v = (float(y) + 0.5) / p.tamano.y;
	// Una línea de vídeo, no un píxel: a 1080p las líneas de un televisor de
	// 1998 son varias filas de la pantalla de hoy.
	float linea = floor(v * p.lineas_pantalla);
	// Temblor horizontal de cinta: una onda lenta más un tirón por línea.
	float onda = sin(v * 38.0 + p.tiempo * 2.3) * 0.0016;
	float tiron = (azar(uvec3(uint(linea), uint(p.tiempo * 12.0), 7u)) - 0.5) * 0.0022;
	float corrimiento = (onda + tiron) * p.temblor * p.tamano.x;
	float barrido = 0.5 + 0.5 * cos(fract(v * p.lineas_pantalla) * 2.0 * PI);
	float oscurecer = mix(1.0, 0.55 + 0.45 * barrido, p.lineas);
	// Cinco muestras a dos distancias. Cerca (±f, un par de píxeles): franjas
	// —Y a un lado menos Y al otro— y desfase de cañones. Lejos (±b): solo el
	// sangrado de crominancia. Con una sola distancia para todo, el sangrado
	// ancho arrastraba franjas y desfase y la imagen salía doble.
	float f = max(1.0, 0.0015 * p.tamano.x * max(p.franjas, p.desfase_color));
	float b = max(f, 0.012 * p.tamano.x * p.sangrado);
	float mezcla_sangrado = clamp(p.sangrado * 1.4, 0.0, 1.0);
	float desfase = 0.6 * clamp(p.desfase_color, 0.0, 1.0);
	float ultimo = p.tamano.x - 1.0;
	uint semilla = uint(fract(p.tiempo) * 9973.0);

	for (int x = int(gl_LocalInvocationID.x); x < ancho; x += HILOS) {
		float centro = float(x) + 0.5 + corrimiento;
		vec3 m2 = leer(centro - b, ultimo);
		vec3 m1 = leer(centro - f, ultimo);
		vec3 yiq = leer(centro, ultimo);
		vec3 p1 = leer(centro + f, ultimo);
		vec3 p2 = leer(centro + b, ultimo);

		// Sangrado de crominancia: I se arrastra desde la izquierda y Q desde
		// la derecha, como en el vídeo compuesto.
		vec2 corrida = vec2((yiq.y + m1.y + m2.y) / 3.0, (yiq.z + p1.z + p2.z) / 3.0);
		vec3 compuesto = vec3(yiq.x, mix(yiq.yz, corrida, mezcla_sangrado));
		compuesto.yz += (p1.x - m1.x) * 0.5 * p.franjas;

		// Desfase de cañones: rojo y azul se separan un poco del verde.
		vec3 gamma = clamp(A_RGB * compuesto, 0.0, 1.0);
		gamma.r = mix(gamma.r, clamp((A_RGB * m1).r, 0.0, 1.0), desfase);
		gamma.b = mix(gamma.b, clamp((A_RGB * p1).b, 0.0, 1.0), desfase);

		gamma *= oscurecer;
		vec2 uv = vec2((float(x) + 0.5) / p.tamano.x, v);
		float borde = length((uv - 0.5) * vec2(1.0, p.tamano.y / p.tamano.x) * 1.6);
		gamma *= mix(1.0, smoothstep(1.05, 0.35, borde), p.vineta);
		gamma += (azar(uvec3(uint(x), uint(y), semilla)) - 0.5) * p.grano;

		imageStore(imagen_color, ivec2(x, y), vec4(a_lineal(gamma), texel(x).w));
	}
}
