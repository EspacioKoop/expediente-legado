## Modelo 3D autoral de alta densidad para la presencia del Minotauro.
## Las formas orgánicas y el material procedimental evitan depender de primitivas
## de baja resolución o de un asset externo con licencia que pueda caducar.
class_name ModeloMinotauroAutoral
extends RefCounted

const SHADER_PIEL := """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec4 tono : source_color = vec4(0.25, 0.12, 0.075, 1.0);
uniform float escala_grano = 95.0;
uniform float rugosidad_base = 0.78;
uniform float relieve = 0.035;

float hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float ruido(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash31(i), hash31(i + vec3(1, 0, 0)), f.x),
		mix(hash31(i + vec3(0, 1, 0)), hash31(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash31(i + vec3(0, 0, 1)), hash31(i + vec3(1, 0, 1)), f.x),
		mix(hash31(i + vec3(0, 1, 1)), hash31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fragment() {
	vec3 p = vec3(UV * escala_grano, 0.0);
	float amplio = ruido(p * 0.07);
	float fino = ruido(p + vec3(amplio * 1.7));
	float poro = ruido(p * 2.3);
	float variacion = (amplio - 0.5) * 0.24 + (fino - 0.5) * 0.10;
	ALBEDO = tono.rgb * (0.89 + variacion) * mix(0.94, 1.04, poro);
	ROUGHNESS = clamp(rugosidad_base + (poro - 0.5) * 0.12, 0.48, 0.96);
	METALLIC = 0.0;
	float relieve_fino = (ruido(p * 3.0) - 0.5) * relieve;
	NORMAL = normalize(NORMAL + vec3(dFdx(relieve_fino), dFdy(relieve_fino), 0.0));
}
"""


static func crear() -> Node3D:
	var modelo := Node3D.new()
	modelo.name = "Cabeza"
	var constructor := ModeloMinotauroAutoral.new()
	constructor._montar(modelo)
	return modelo


func _montar(raiz: Node3D) -> void:
	var piel := _material(Color(0.29, 0.15, 0.095), 88.0, 0.84, 0.03)
	var piel_sombra := _material(Color(0.19, 0.075, 0.047), 110.0, 0.91, 0.025)
	var morro := _material(Color(0.37, 0.22, 0.16), 145.0, 0.58, 0.018)
	var cuerno := _material(Color(0.77, 0.67, 0.49), 120.0, 0.31, 0.015)
	var casco := _material(Color(0.19, 0.17, 0.14), 115.0, 0.39, 0.01)
	var ojo := _material(Color(0.78, 0.48, 0.13), 180.0, 0.22, 0.005)
	var pupila := _material(Color(0.025, 0.015, 0.012), 200.0, 0.15, 0.0)
	var brillo := _material(Color(0.96, 0.88, 0.68), 200.0, 0.12, 0.0)
	_montar_cuerpo(raiz, piel, piel_sombra, morro, casco)
	var rostro := Node3D.new()
	rostro.name = "CabezaBovina"
	rostro.position.y = 2.42
	raiz.add_child(rostro)

	# Cabeza y cuello: silueta bovina legible desde frente y tres cuartos.
	_esfera(rostro, "Cráneo", Vector3(0.48, 0.60, 0.40), Vector3(0.0, 0.02, 0.0), piel)
	_esfera(rostro, "Frente", Vector3(0.42, 0.32, 0.29), Vector3(0.0, 0.34, -0.10), piel)
	_esfera(rostro, "Morro", Vector3(0.34, 0.24, 0.39), Vector3(0.0, -0.22, -0.37), morro)
	_esfera(rostro, "PuenteNasal", Vector3(0.18, 0.27, 0.20), Vector3(0.0, 0.03, -0.48), morro)
	_esfera(rostro, "Nariz", Vector3(0.29, 0.16, 0.13), Vector3(0.0, -0.25, -0.65), piel_sombra)
	for lado in [-1.0, 1.0]:
		_esfera(
			rostro, "Mejilla", Vector3(0.23, 0.28, 0.24), Vector3(lado * 0.30, -0.10, -0.12), piel
		)
		_esfera(
			rostro,
			"FosaNasal",
			Vector3(0.055, 0.036, 0.025),
			Vector3(lado * 0.15, -0.25, -0.766),
			pupila
		)
		_esfera(
			rostro,
			"CuencaOcular",
			Vector3(0.13, 0.11, 0.065),
			Vector3(lado * 0.225, 0.10, -0.333),
			piel_sombra
		)
		_esfera(
			rostro, "Ojo", Vector3(0.073, 0.064, 0.052), Vector3(lado * 0.225, 0.10, -0.385), ojo
		)
		_esfera(
			rostro,
			"Pupila",
			Vector3(0.025, 0.048, 0.022),
			Vector3(lado * 0.225, 0.10, -0.431),
			pupila
		)
		_esfera(
			rostro,
			"ReflejoOjo",
			Vector3(0.012, 0.014, 0.009),
			Vector3(lado * 0.205, 0.122, -0.448),
			brillo
		)
		_esfera(
			rostro,
			"Oreja",
			Vector3(0.20, 0.10, 0.25),
			Vector3(lado * 0.48, 0.29, 0.04),
			piel_sombra
		)
		_esfera(
			rostro,
			"InteriorOreja",
			Vector3(0.13, 0.045, 0.15),
			Vector3(lado * 0.49, 0.30, -0.055),
			morro
		)
		_tubo(
			rostro,
			"Cuerno",
			[
				Vector3(lado * 0.30, 0.39, 0.01),
				Vector3(lado * 0.43, 0.63, 0.03),
				Vector3(lado * 0.59, 0.82, 0.02),
				Vector3(lado * 0.66, 1.02, -0.05),
			],
			0.14,
			cuerno
		)
		# Pliegues suaves bajo el ojo y anillos de queratina en la base del cuerno.
		for pliegue in range(3):
			_esfera(
				rostro,
				"PliegueFacial",
				Vector3(0.14, 0.022, 0.018),
				Vector3(lado * (0.25 + pliegue * 0.012), -0.035 - pliegue * 0.055, -0.34),
				piel_sombra,
			)
		for anillo in range(3):
			_esfera(
				rostro,
				"AnilloCuerno",
				Vector3(0.115 - anillo * 0.012, 0.035, 0.12 - anillo * 0.01),
				Vector3(lado * (0.34 + anillo * 0.06), 0.45 + anillo * 0.075, 0.01),
				piel_sombra,
			)


func _montar_cuerpo(
	raiz: Node3D, piel: Material, sombra: Material, morro: Material, casco: Material
) -> void:
	_esfera(raiz, "Pelvis", Vector3(0.57, 0.38, 0.39), Vector3(0.0, 0.88, 0.0), sombra)
	_esfera(raiz, "Abdomen", Vector3(0.49, 0.64, 0.34), Vector3(0.0, 1.34, 0.0), piel)
	_esfera(raiz, "Torso", Vector3(0.72, 0.73, 0.41), Vector3(0.0, 1.88, 0.0), piel)
	_esfera(raiz, "PechoIzquierdo", Vector3(0.39, 0.29, 0.22), Vector3(-0.35, 1.91, -0.30), piel)
	_esfera(raiz, "PechoDerecho", Vector3(0.39, 0.29, 0.22), Vector3(0.35, 1.91, -0.30), piel)
	_esfera(raiz, "Cuello", Vector3(0.39, 0.43, 0.36), Vector3(0.0, 2.36, 0.04), piel)
	var cola: Array[Vector3] = [
		Vector3(0.0, 1.04, 0.25),
		Vector3(0.0, 0.82, 0.48),
		Vector3(0.0, 0.48, 0.65),
		Vector3(0.0, 0.30, 0.89),
	]
	_tubo(raiz, "Cola", cola, 0.065, sombra)
	_esfera(raiz, "MechónCola", Vector3(0.105, 0.18, 0.12), Vector3(0.0, 0.24, 0.92), sombra)
	var pelaje := _material(Color(0.22, 0.105, 0.061), 160.0, 0.93, 0.04)
	for lado in [-1.0, 1.0]:
		_esfera(raiz, "Hombro", Vector3(0.38, 0.43, 0.40), Vector3(lado * 0.72, 2.08, 0.0), piel)
		_esfera(raiz, "Bíceps", Vector3(0.24, 0.48, 0.25), Vector3(lado * 0.91, 1.69, -0.02), piel)
		_esfera(
			raiz, "Antebrazo", Vector3(0.20, 0.48, 0.21), Vector3(lado * 1.00, 1.22, -0.06), piel
		)
		_esfera(raiz, "Mano", Vector3(0.19, 0.24, 0.16), Vector3(lado * 1.02, 0.87, -0.13), sombra)
		for dedo in range(4):
			var desplazamiento := (float(dedo) - 1.5) * 0.075
			_esfera(
				raiz,
				"Dedo",
				Vector3(0.045, 0.14, 0.05),
				Vector3(lado * 1.02 + desplazamiento, 0.68, -0.17),
				sombra,
			)
		_esfera(raiz, "Muslo", Vector3(0.34, 0.62, 0.34), Vector3(lado * 0.39, 0.48, 0.0), piel)
		_esfera(
			raiz, "Rodilla", Vector3(0.25, 0.28, 0.27), Vector3(lado * 0.39, -0.06, -0.04), piel
		)
		_esfera(
			raiz, "Corvejón", Vector3(0.22, 0.48, 0.23), Vector3(lado * 0.39, -0.43, 0.12), piel
		)
		_esfera(
			raiz, "Cuartilla", Vector3(0.17, 0.30, 0.18), Vector3(lado * 0.39, -0.78, -0.02), sombra
		)
		_esfera(
			raiz, "Pezuña", Vector3(0.24, 0.17, 0.32), Vector3(lado * 0.39, -0.98, -0.10), casco
		)
		_esfera(
			raiz,
			"HendiduraPezuña",
			Vector3(0.018, 0.12, 0.26),
			Vector3(lado * 0.39, -0.98, -0.355),
			sombra
		)
		_esfera(
			raiz,
			"VetaPezuña",
			Vector3(0.015, 0.08, 0.018),
			Vector3(lado * 0.39, -0.94, -0.39),
			morro
		)
		for indice in range(9):
			var angulo := TAU * float(indice) / 9.0
			_esfera(
				raiz,
				"MechónNuca",
				Vector3(0.12, 0.19, 0.10),
				Vector3(lado * (0.52 + cos(angulo) * 0.08), 2.39 + sin(angulo) * 0.09, 0.20),
				pelaje,
			)


static func _esfera(
	padre: Node3D, nombre: String, escala: Vector3, posicion: Vector3, material: Material
) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radial_segments = 48
	malla.rings = 32
	malla.radius = 1.0
	malla.height = 2.0
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	pieza.mesh = malla
	pieza.position = posicion
	pieza.scale = escala
	pieza.material_override = material
	padre.add_child(pieza)
	return pieza


static func _material(
	color: Color, escala_grano: float, rugosidad: float, relieve: float
) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER_PIEL
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tono", color)
	material.set_shader_parameter("escala_grano", escala_grano)
	material.set_shader_parameter("rugosidad_base", rugosidad)
	material.set_shader_parameter("relieve", relieve)
	return material


static func _tubo(
	padre: Node3D, nombre: String, puntos: Array[Vector3], radio: float, material: Material
) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var segmentos := 32
	var lados := 18
	for segmento in range(segmentos + 1):
		var t := float(segmento) / float(segmentos)
		var centro := _bezier(puntos, t)
		var tangente := (
			(_bezier(puntos, minf(t + 0.002, 1.0)) - _bezier(puntos, maxf(t - 0.002, 0.0)))
			. normalized()
		)
		var lateral := tangente.cross(Vector3.FORWARD).normalized()
		if lateral.length_squared() < 0.01:
			lateral = tangente.cross(Vector3.RIGHT).normalized()
		var arriba := tangente.cross(lateral).normalized()
		var radio_local := radio * pow(1.0 - t, 0.82)
		for lado in range(lados):
			var angulo := TAU * float(lado) / float(lados)
			vertices.append(centro + (lateral * cos(angulo) + arriba * sin(angulo)) * radio_local)
	for segmento in range(segmentos):
		for lado in range(lados):
			var siguiente := (lado + 1) % lados
			var a := segmento * lados + lado
			var b := segmento * lados + siguiente
			var c := (segmento + 1) * lados + siguiente
			var d := (segmento + 1) * lados + lado
			indices.append_array(PackedInt32Array([a, b, c, a, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var superficie := SurfaceTool.new()
	superficie.create_from(malla, 0)
	superficie.generate_normals()
	malla = superficie.commit()
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	pieza.mesh = malla
	pieza.material_override = material
	padre.add_child(pieza)
	return pieza


static func _bezier(puntos: Array[Vector3], t: float) -> Vector3:
	var inverso := 1.0 - t
	return (
		puntos[0] * inverso * inverso * inverso
		+ puntos[1] * 3.0 * inverso * inverso * t
		+ puntos[2] * 3.0 * inverso * t * t
		+ puntos[3] * t * t * t
	)
