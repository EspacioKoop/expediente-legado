shader_type canvas_item;

// Seis señales CRT procedurales y estáticas para el escaparate de #142.
// El canal decide la familia visual; la semilla introduce una variación leve.
// No hay reproducción de vídeo ni refresco temporal.
uniform int canal = 0;
uniform float semilla = 0.0;

float rect_mask(vec2 uv, vec2 centro, vec2 mitad) {
	vec2 d = abs(uv - centro) - mitad;
	return 1.0 - step(0.0, max(d.x, d.y));
}

float circle_mask(vec2 uv, vec2 centro, float radio) {
	return 1.0 - smoothstep(radio - 0.008, radio + 0.008, distance(uv, centro));
}

float line_mask(float valor, float centro, float grosor) {
	return 1.0 - smoothstep(grosor, grosor + 0.004, abs(valor - centro));
}

vec3 barras_tecnicas(float x) {
	if (x < 0.166) {
		return vec3(0.84, 0.84, 0.80);
	}
	if (x < 0.333) {
		return vec3(0.78, 0.70, 0.30);
	}
	if (x < 0.500) {
		return vec3(0.28, 0.64, 0.60);
	}
	if (x < 0.666) {
		return vec3(0.34, 0.57, 0.31);
	}
	if (x < 0.833) {
		return vec3(0.64, 0.29, 0.38);
	}
	return vec3(0.63, 0.23, 0.21);
}

vec3 informativo(vec2 uv) {
	vec3 color = vec3(0.20, 0.30, 0.43);
	float cabeza = circle_mask(uv, vec2(0.30, 0.38), 0.11);
	float cuerpo = rect_mask(uv, vec2(0.30, 0.60), vec2(0.16, 0.13));
	float columna_a = rect_mask(uv, vec2(0.68, 0.28), vec2(0.20, 0.018));
	float columna_b = rect_mask(uv, vec2(0.64, 0.39), vec2(0.16, 0.018));
	float columna_c = rect_mask(uv, vec2(0.70, 0.50), vec2(0.22, 0.018));
	float faldon = rect_mask(uv, vec2(0.50, 0.86), vec2(0.46, 0.10));
	color = mix(color, vec3(0.78, 0.74, 0.66), max(cabeza, cuerpo));
	color = mix(color, vec3(0.82, 0.82, 0.78), max(columna_a, max(columna_b, columna_c)));
	color = mix(color, vec3(0.12, 0.22, 0.37), faldon);
	return color;
}

vec3 deporte(vec2 uv) {
	vec3 color = vec3(0.20, 0.40, 0.22);
	float centro_h = line_mask(uv.y, 0.50, 0.006);
	float centro_v = line_mask(uv.x, 0.50, 0.006);
	float circulo = 1.0 - smoothstep(0.008, 0.018, abs(distance(uv, vec2(0.50)) - 0.16));
	float jugadores = max(
		circle_mask(uv, vec2(0.26, 0.34), 0.025),
		max(
			circle_mask(uv, vec2(0.38, 0.66), 0.025),
			max(circle_mask(uv, vec2(0.68, 0.33), 0.025), circle_mask(uv, vec2(0.78, 0.68), 0.025))
		)
	);
	color = mix(color, vec3(0.82, 0.82, 0.74), max(max(centro_h, centro_v), max(circulo, jugadores)));
	float marcador = rect_mask(uv, vec2(0.22, 0.15), vec2(0.17, 0.07));
	return mix(color, vec3(0.10, 0.19, 0.31), marcador);
}

vec3 institucional(vec2 uv) {
	vec3 color = vec3(0.48, 0.56, 0.53);
	float sol = circle_mask(uv, vec2(0.78, 0.22), 0.08);
	float horizonte = step(0.60 + 0.22 * abs(uv.x - 0.48), uv.y);
	float placa = rect_mask(uv, vec2(0.73, 0.78), vec2(0.18, 0.08));
	color = mix(color, vec3(0.75, 0.65, 0.36), sol);
	color = mix(color, vec3(0.25, 0.38, 0.33), horizonte);
	color = mix(color, vec3(0.68, 0.54, 0.24), placa);
	return color;
}

vec3 tecnica(vec2 uv) {
	vec3 color = vec3(0.10, 0.14, 0.22);
	float zona = rect_mask(uv, vec2(0.50, 0.53), vec2(0.42, 0.28));
	if (zona > 0.5) {
		color = barras_tecnicas(clamp((uv.x - 0.08) / 0.84, 0.0, 1.0));
	}
	float cabecera = rect_mask(uv, vec2(0.50, 0.14), vec2(0.32, 0.025));
	float pie = rect_mask(uv, vec2(0.50, 0.88), vec2(0.28, 0.018));
	color = mix(color, vec3(0.80, 0.80, 0.76), max(cabecera, pie));
	return color;
}

vec3 anomalia(vec2 uv) {
	vec3 color = vec3(0.18, 0.23, 0.24);
	float agua = step(0.62 + 0.035 * sin(uv.x * 20.0), uv.y);
	color = mix(color, vec3(0.30, 0.39, 0.41), agua);

	vec2 p = uv - vec2(0.62, 0.38);
	p.x *= 1.3333333;
	float lado = mix(-1.0, 1.0, step(1.0, mod(semilla, 2.0)));
	float exterior = 1.0 - smoothstep(0.19, 0.205, length(p));
	float interior = 1.0 - smoothstep(0.145, 0.16, length(p - vec2(0.075 * lado, 0.0)));
	float luna = max(exterior - interior, 0.0);
	color = mix(color, vec3(0.67, 0.83, 0.70), luna);

	float figura = max(circle_mask(uv, vec2(0.30, 0.58), 0.045), rect_mask(uv, vec2(0.30, 0.73), vec2(0.025, 0.13)));
	return mix(color, vec3(0.06, 0.08, 0.08), figura);
}

vec3 ocio(vec2 uv) {
	vec3 color = vec3(0.52, 0.34, 0.28);
	float cara = circle_mask(uv, vec2(0.50, 0.46), 0.20);
	float ojo_a = circle_mask(uv, vec2(0.43, 0.42), 0.035);
	float ojo_b = circle_mask(uv, vec2(0.57, 0.42), 0.035);
	float pupila_a = circle_mask(uv, vec2(0.43, 0.42), 0.014);
	float pupila_b = circle_mask(uv, vec2(0.57, 0.42), 0.014);
	float sonrisa = 1.0 - smoothstep(0.012, 0.025, abs(distance(uv, vec2(0.50, 0.49)) - 0.105));
	sonrisa *= step(0.49, uv.y);
	color = mix(color, vec3(0.30, 0.55, 0.43), cara);
	color = mix(color, vec3(0.86, 0.80, 0.64), max(ojo_a, ojo_b));
	color = mix(color, vec3(0.08, 0.08, 0.07), max(max(pupila_a, pupila_b), sonrisa));
	return color;
}

void fragment() {
	vec2 uv = UV;
	vec3 color;
	if (canal == 0) {
		color = informativo(uv);
	} else if (canal == 1) {
		color = deporte(uv);
	} else if (canal == 2) {
		color = institucional(uv);
	} else if (canal == 3) {
		color = tecnica(uv);
	} else if (canal == 4) {
		color = anomalia(uv);
	} else {
		color = ocio(uv);
	}

	float scanline = 0.94 + 0.06 * sin(uv.y * 192.0 * 3.14159265);
	float variacion = 0.96 + 0.04 * fract(sin(semilla * 12.9898 + 0.17) * 43758.5453);
	float vineta = 1.0 - 0.20 * smoothstep(0.32, 0.72, length((uv - vec2(0.5)) * vec2(1.0, 1.15)));
	COLOR = vec4(color * scanline * variacion * vineta, 1.0);
}
