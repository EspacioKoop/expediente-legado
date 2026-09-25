## Identidad histórica secundaria para avatares Rocketbox (#275).
##
## Mantiene intacta la cabeza, piel, cabello, ropa y texturas del avatar. Solo
## añade volúmenes/accesorios low-poly anclados al hueso Head para recuperar
## señales reconocibles que se perdieron al migrar desde persona.fbx.
extends RefCounted

const PERSONAJES := {
	"emperador": "Puyi",
	"aduanero_ny": "Herman Melville",
	"correspondencia": "Fernando Pessoa",
	"riegos": "Constantino Cavafis",
	"fielato": "Henri Rousseau",
}


static func aplicar(pieza: Node3D, retrato: String) -> void:
	var personaje := String(PERSONAJES.get(retrato, ""))
	if personaje.is_empty():
		return
	var esqueleto := _esqueleto(pieza)
	if esqueleto == null:
		return
	var cabeza := esqueleto.find_bone("Head")
	var cuello := esqueleto.find_bone("Neck")
	if cabeza < 0 or cuello < 0:
		return

	var alto := maxf(
		(
			absf(
				(
					esqueleto.get_bone_global_rest(cabeza).origin.y
					- esqueleto.get_bone_global_rest(cuello).origin.y
				)
			)
			* 1.9
		),
		0.18
	)
	var enganche := BoneAttachment3D.new()
	enganche.name = "IdentidadHistorica275"
	enganche.bone_idx = cabeza
	esqueleto.add_child(enganche)
	esqueleto.set_meta("identidad_historica_275", retrato)

	var oscuro := Color(0.075, 0.065, 0.055)
	var pelo := Color(0.12, 0.105, 0.09)
	match personaje:
		"Puyi":
			_gafas(enganche, alto, "GafasPuyi", 0.96)
		"Herman Melville":
			_barba(enganche, alto, "BarbaMelville", Color(0.20, 0.18, 0.16))
		"Fernando Pessoa":
			_gafas(enganche, alto, "GafasPessoa", 0.90)
			_bigote(enganche, alto, "BigotePessoa", oscuro, 0.78)
			_sombrero(enganche, alto, "SombreroPessoa", oscuro)
		"Constantino Cavafis":
			_gafas(enganche, alto, "GafasCavafis", 0.92)
			_bigote(enganche, alto, "BigoteCavafis", pelo, 0.88)
			_sienes(enganche, alto, "SienesCavafis", pelo, 0.74)
		"Henri Rousseau":
			_bigote(enganche, alto, "BigoteRousseau", oscuro, 1.15)
			_sienes(enganche, alto, "SienesRousseau", pelo, 1.02)


static func _grupo(padre: Node3D, nombre: String) -> Node3D:
	var grupo := Node3D.new()
	grupo.name = nombre
	padre.add_child(grupo)
	return grupo


static func _gafas(padre: Node3D, alto: float, nombre: String, escala: float) -> void:
	var grupo := _grupo(padre, nombre)
	var separacion := alto * 0.19 * escala
	var radio := alto * 0.105 * escala
	var y := alto * 0.18
	var z := alto * 0.40
	var color := Color(0.055, 0.05, 0.045)
	_aro(grupo, Vector3(-separacion, y, z), radio, alto * 0.014, color)
	_aro(grupo, Vector3(separacion, y, z), radio, alto * 0.014, color)
	_esfera(
		grupo, Vector3(0.0, y, z), Vector3(alto * 0.095, alto * 0.012, alto * 0.012), color
	)


static func _barba(padre: Node3D, alto: float, nombre: String, color: Color) -> void:
	var grupo := _grupo(padre, nombre)
	var z := alto * 0.31
	_esfera(
		grupo,
		Vector3(-alto * 0.10, -alto * 0.10, z),
		Vector3(alto * 0.19, alto * 0.24, alto * 0.11),
		color
	)
	_esfera(
		grupo,
		Vector3(alto * 0.10, -alto * 0.10, z),
		Vector3(alto * 0.19, alto * 0.24, alto * 0.11),
		color
	)
	_esfera(
		grupo,
		Vector3(0.0, -alto * 0.28, alto * 0.25),
		Vector3(alto * 0.24, alto * 0.30, alto * 0.13),
		color
	)
	_bigote(grupo, alto, "BigoteMelville", color.darkened(0.08), 0.92)


static func _bigote(
	padre: Node3D, alto: float, nombre: String, color: Color, ancho: float
) -> void:
	var grupo := _grupo(padre, nombre)
	var y := -alto * 0.055
	var z := alto * 0.43
	for lado in [-1.0, 1.0]:
		_esfera(
			grupo,
			Vector3(lado * alto * 0.070, y, z),
			Vector3(alto * 0.12 * ancho, alto * 0.030, alto * 0.025),
			color
		)


static func _sombrero(padre: Node3D, alto: float, nombre: String, color: Color) -> void:
	var grupo := _grupo(padre, nombre)
	var ala := MeshInstance3D.new()
	var malla_ala := CylinderMesh.new()
	malla_ala.top_radius = alto * 0.54
	malla_ala.bottom_radius = alto * 0.54
	malla_ala.height = alto * 0.035
	malla_ala.radial_segments = 12
	ala.mesh = malla_ala
	ala.position = Vector3(0.0, alto * 0.56, 0.0)
	ala.scale.z = 0.72
	ala.material_override = _material(color)
	grupo.add_child(ala)

	var copa := MeshInstance3D.new()
	var malla_copa := CylinderMesh.new()
	malla_copa.top_radius = alto * 0.28
	malla_copa.bottom_radius = alto * 0.34
	malla_copa.height = alto * 0.34
	malla_copa.radial_segments = 10
	copa.mesh = malla_copa
	copa.position = Vector3(0.0, alto * 0.70, -alto * 0.015)
	copa.scale.z = 0.82
	copa.material_override = _material(color)
	grupo.add_child(copa)


static func _sienes(
	padre: Node3D, alto: float, nombre: String, color: Color, volumen: float
) -> void:
	var grupo := _grupo(padre, nombre)
	for lado in [-1.0, 1.0]:
		_esfera(
			grupo,
			Vector3(lado * alto * 0.31, alto * 0.31, -alto * 0.01),
			Vector3(alto * 0.11 * volumen, alto * 0.20, alto * 0.10),
			color
		)


static func _aro(
	padre: Node3D, posicion: Vector3, radio: float, grosor: float, color: Color
) -> void:
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = maxf(radio * 0.2, radio - grosor)
	toro.outer_radius = radio
	toro.rings = 12
	toro.ring_segments = 4
	aro.mesh = toro
	aro.position = posicion
	aro.rotation.x = PI / 2.0
	aro.material_override = _material(color)
	padre.add_child(aro)


static func _esfera(
	padre: Node3D, posicion: Vector3, escala: Vector3, color: Color
) -> void:
	var rasgo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 6
	esfera.rings = 4
	rasgo.mesh = esfera
	rasgo.position = posicion
	rasgo.scale = escala
	rasgo.material_override = _material(color)
	padre.add_child(rasgo)


static func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(Espacio3D.shader_del_sitio())
	material.set_shader_parameter("color_base", color)
	material.set_meta("identidad_historica_275", true)
	return material


static func _esqueleto(nodo: Node) -> Skeleton3D:
	if nodo is Skeleton3D:
		return nodo
	for hijo in nodo.get_children():
		var encontrado := _esqueleto(hijo)
		if encontrado != null:
			return encontrado
	return null
