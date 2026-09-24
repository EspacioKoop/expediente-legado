// Variante del shader PSX para superficies con set PBR real (#399).
//
// El shader PSX canónico NO se toca: esta ruta es opt-in y solo se usa cuando
// existen binarios PBR preparados bajo `assets/texturas/pbr/<nombre>/`.
//
// Conserva las tres señales de imagen que más definen el tratamiento espacial:
// temblor de vértices, cuantización de color y dithering Bayer. La iluminación
// pasa a ser por píxel en esta variante porque normal/roughness/AO necesitan
// información por fragmento para aportar volumen real.
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

uniform vec4 color_base : source_color = vec4(1.0);

uniform sampler2D textura : source_color, filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;
uniform sampler2D mapa_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mapa_roughness : hint_roughness_gray, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mapa_ao : filter_linear_mipmap_anisotropic, repeat_enable, hint_default_white;

uniform bool usar_uv = true;
uniform float escala_textura = 1.0;
uniform bool con_normal = false;
uniform bool con_roughness = false;
uniform bool con_ao = false;
uniform float fuerza_normal : hint_range(0.0, 2.0, 0.05) = 0.65;
uniform float especular : hint_range(0.0, 1.0, 0.05) = 0.22;

uniform vec4 emision : source_color = vec4(0.0);
uniform float emision_fuerza = 0.0;

uniform float rejilla = 190.0;
uniform float tonos = 32.0;
uniform float dithering : hint_range(0.0, 1.0, 0.05) = 0.65;

varying vec3 mundo;


void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vec4 proyectado = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 normalizado = proyectado.xy / max(abs(proyectado.w), 0.0001);
	normalizado = round(normalizado * rejilla) / rejilla;
	proyectado.xy = normalizado * abs(proyectado.w);
	POSITION = proyectado;
}


vec3 pesos_triplanar(vec3 normal) {
	vec3 peso = abs(normal);
	return peso / max(peso.x + peso.y + peso.z, 0.0001);
}


vec3 muestra_albedo_triplanar(vec3 punto, vec3 normal) {
	vec3 peso = pesos_triplanar(normal);
	vec3 p = punto * escala_textura;
	return texture(textura, p.zy).rgb * peso.x
		+ texture(textura, p.xz).rgb * peso.y
		+ texture(textura, p.xy).rgb * peso.z;
}


float muestra_roughness_triplanar(vec3 punto, vec3 normal) {
	vec3 peso = pesos_triplanar(normal);
	vec3 p = punto * escala_textura;
	return texture(mapa_roughness, p.zy).r * peso.x
		+ texture(mapa_roughness, p.xz).r * peso.y
		+ texture(mapa_roughness, p.xy).r * peso.z;
}


float muestra_ao_triplanar(vec3 punto, vec3 normal) {
	vec3 peso = pesos_triplanar(normal);
	vec3 p = punto * escala_textura;
	return texture(mapa_ao, p.zy).r * peso.x
		+ texture(mapa_ao, p.xz).r * peso.y
		+ texture(mapa_ao, p.xy).r * peso.z;
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
	vec2 uv_material = UV * escala_textura;
	vec3 color = color_base.rgb;

	if (usar_uv) {
		color = texture(textura, uv_material).rgb * color_base.rgb;
	} else {
		color = muestra_albedo_triplanar(mundo, NORMAL) * color_base.rgb;
	}

	if (con_normal && usar_uv) {
		NORMAL_MAP = texture(mapa_normal, uv_material).rgb;
		NORMAL_MAP_DEPTH = fuerza_normal;
	}

	ROUGHNESS = 0.86;
	if (con_roughness) {
		if (usar_uv) {
			ROUGHNESS = texture(mapa_roughness, uv_material).r;
		} else {
			ROUGHNESS = muestra_roughness_triplanar(mundo, NORMAL);
		}
	}
	SPECULAR = especular;

	if (con_ao) {
		if (usar_uv) {
			AO = texture(mapa_ao, uv_material).r;
		} else {
			AO = muestra_ao_triplanar(mundo, NORMAL);
		}
	}

	float niveles = max(tonos, 1.0);
	float error_ordenado = (bayer_4x4(FRAGCOORD.xy) - 0.5) * dithering / niveles;
	color = clamp(color + vec3(error_ordenado), vec3(0.0), vec3(1.0));
	ALBEDO = floor(color * niveles) / niveles;
	EMISSION = emision.rgb * emision_fuerza;
}
