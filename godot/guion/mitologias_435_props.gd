## Kit de props 3D PBR reutilizables para la épica mitológica #435.
##
## Son piezas visuales sin lógica de puzzle: cada fábrica devuelve un Node3D
## autónomo que puede vestirse en sueños o escenas de evidencia sin crear
## estados paralelos ni introducir hechos narrativos.
class_name Mitologias435Props
extends RefCounted

const ARCILLA := preload("res://arte/mitologias_435/materiales/arcilla_uruk.tres")
const METAL := preload("res://arte/mitologias_435/materiales/metal_archivo_oxidado.tres")
const BRONCE := preload("res://arte/mitologias_435/materiales/bronce_votivo.tres")
const ESCAMA := preload("res://arte/mitologias_435/materiales/escama_hidra.tres")
const JADE := preload("res://arte/mitologias_435/materiales/jade_ryu_humedo.tres")
const CALIZA := preload("res://arte/mitologias_435/materiales/caliza_duat.tres")
const PAPEL := preload("res://arte/mitologias_435/materiales/papel_archivo_envejecido.tres")


static func tablilla_uruk() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "TablillaUrukPBR"
	var soporte := _caja(
		raiz, "Tablilla", Vector3(2.4, 1.65, 0.22), Vector3.ZERO, ARCILLA
	)
	soporte.rotation_degrees.z = -3.0
	for fila in 5:
		for columna in 7:
			var cunia := _caja(
				raiz,
				"Cunia_%02d_%02d" % [fila, columna],
				Vector3(0.12, 0.025, 0.08),
				Vector3(-0.86 + columna * 0.28, 0.56 - fila * 0.27, -0.13),
				BRONCE,
			)
			cunia.rotation_degrees.z = -18.0 + float((fila + columna) % 3) * 18.0
	for indice in 3:
		var grieta := _caja(
			raiz,
			"Grieta%02d" % indice,
			Vector3(0.035, 0.62 + indice * 0.12, 0.04),
			Vector3(-0.45 + indice * 0.48, -0.15 + indice * 0.08, -0.13),
			METAL,
		)
		grieta.rotation_degrees.z = -24.0 + indice * 21.0
	return raiz


static func archivador_onirico() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "ArchivadorOniricoPBR"
	_caja(raiz, "Cuerpo", Vector3(1.55, 3.8, 1.45), Vector3(0.0, 1.9, 0.0), METAL)
	for indice in 4:
		var y := 3.18 - indice * 0.88
		var cajon := _caja(
			raiz,
			"Cajon%02d" % indice,
			Vector3(1.38, 0.74, 0.16),
			Vector3(0.0, y, -0.76 - (0.23 if indice in [0, 2] else 0.0)),
			METAL,
		)
		if indice in [0, 2]:
			cajon.position.z -= 0.34
			_caja(
				raiz,
				"Papel%02d" % indice,
				Vector3(0.9, 0.045, 0.62),
				Vector3(0.05, y + 0.34, -1.08),
				PAPEL,
			)
		_cilindro(
			raiz,
			"Asa%02d" % indice,
			0.055,
			0.055,
			0.72,
			Vector3(0.0, y, -0.92 - (0.34 if indice in [0, 2] else 0.0)),
			BRONCE,
			10,
			Vector3(90.0, 0.0, 0.0),
		)
	return raiz


static func panoplia_aquiles() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "PanopliaAquilesPBR"
	var escudo := _cilindro(
		raiz,
		"Escudo",
		1.25,
		1.25,
		0.16,
		Vector3(-0.35, 1.35, 0.0),
		BRONCE,
		40,
		Vector3(90.0, 0.0, 0.0),
	)
	escudo.scale.y = 0.78
	_cilindro(
		raiz,
		"Umbo",
		0.28,
		0.42,
		0.30,
		Vector3(-0.35, 1.35, -0.18),
		BRONCE,
		24,
		Vector3(90.0, 0.0, 0.0),
	)
	var greba := _cilindro(
		raiz,
		"Greba",
		0.30,
		0.42,
		1.55,
		Vector3(1.1, 0.78, 0.05),
		BRONCE,
		24,
		Vector3.ZERO,
	)
	greba.scale.z = 0.58
	_caja(
		raiz, "MarcaTalon", Vector3(0.30, 0.08, 0.34), Vector3(1.1, 0.10, -0.28), PAPEL
	)
	return raiz


static func busto_hidra() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "BustoHidraPBR"
	_cilindro(
		raiz, "Pedestal", 1.25, 1.55, 0.55, Vector3(0.0, 0.28, 0.0), CALIZA, 24
	)
	for indice in 5:
		var angulo := deg_to_rad(-54.0 + indice * 27.0)
		var x := sin(angulo) * 1.05
		var z := cos(angulo) * 0.38
		var altura := 1.55 + absf(float(indice - 2)) * -0.15
		var cuello := _cilindro(
			raiz,
			"Cuello%02d" % indice,
			0.20,
			0.31,
			altura,
			Vector3(x, 0.72 + altura * 0.5, z),
			ESCAMA,
			18,
			Vector3(0.0, 0.0, -22.0 + indice * 11.0),
		)
		cuello.rotation_degrees.y = -35.0 + indice * 17.0
		_esfera(
			raiz,
			"Cabeza%02d" % indice,
			Vector3(x * 1.25, 1.48 + altura * 0.48, z - 0.16),
			Vector3(0.37, 0.28, 0.52),
			ESCAMA,
		)
		_cilindro(
			raiz,
			"Cuerno%02d" % indice,
			0.02,
			0.08,
			0.45,
			Vector3(x * 1.25, 1.78 + altura * 0.48, z - 0.10),
			BRONCE,
			8,
			Vector3(18.0, 0.0, -12.0 + indice * 5.0),
		)
	return raiz


static func compuerta_ryu() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "CompuertaRyuPBR"
	_caja(raiz, "Base", Vector3(2.5, 0.42, 1.75), Vector3(0.0, 0.21, 0.0), METAL)
	_caja(raiz, "PilarI", Vector3(0.34, 2.35, 0.42), Vector3(-0.88, 1.38, 0.0), JADE)
	_caja(raiz, "PilarD", Vector3(0.34, 2.35, 0.42), Vector3(0.88, 1.38, 0.0), JADE)
	_cilindro(
		raiz,
		"Eje",
		0.26,
		0.26,
		1.9,
		Vector3(0.0, 1.72, 0.0),
		BRONCE,
		20,
		Vector3(90.0, 0.0, 0.0),
	)
	var palanca := _cilindro(
		raiz,
		"Palanca",
		0.11,
		0.15,
		2.25,
		Vector3(0.55, 2.50, -0.18),
		JADE,
		18,
		Vector3(0.0, 0.0, -52.0),
	)
	palanca.rotation_degrees.y = 10.0
	_esfera(raiz, "Pomo", Vector3(1.35, 3.08, -0.18), Vector3.ONE * 0.28, JADE)
	return raiz


static func balanza_duat() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "BalanzaDuatPBR"
	_cilindro(raiz, "Base", 0.92, 1.18, 0.44, Vector3(0.0, 0.22, 0.0), CALIZA, 24)
	_caja(raiz, "Pilar", Vector3(0.38, 2.8, 0.50), Vector3(0.0, 1.78, 0.0), CALIZA)
	var brazo := _caja(
		raiz, "Brazo", Vector3(4.6, 0.18, 0.30), Vector3(0.0, 3.12, 0.0), BRONCE
	)
	brazo.rotation_degrees.z = 1.8
	for lado in [-1.0, 1.0]:
		_cilindro(
			raiz,
			"Bandeja%s" % ("I" if lado < 0.0 else "D"),
			0.72,
			0.84,
			0.10,
			Vector3(lado * 1.82, 2.08, 0.0),
			BRONCE,
			28,
		)
		for cadena in [-0.42, 0.42]:
			var tramo := _cilindro(
				raiz,
				"Cadena_%s_%s" % [str(lado), str(cadena)],
				0.025,
				0.025,
				1.10,
				Vector3(lado * 1.82 + cadena, 2.62, 0.0),
				BRONCE,
				8,
			)
			tramo.rotation_degrees.z = lado * cadena * 13.0
	return raiz


static func legajo_siga() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "LegajoSigaPBR"
	for indice in 9:
		var hoja := _caja(
			raiz,
			"Hoja%02d" % indice,
			Vector3(2.15 - indice * 0.025, 0.055, 1.52 - indice * 0.018),
			Vector3(
				0.025 * float((indice % 3) - 1),
				0.05 + indice * 0.055,
				0.018 * float((indice % 2) * 2 - 1),
			),
			PAPEL,
		)
		hoja.rotation_degrees.y = -2.5 + indice * 0.6
	_caja(raiz, "TapaInferior", Vector3(2.25, 0.10, 1.62), Vector3(0.0, 0.02, 0.0), METAL)
	_caja(raiz, "TapaSuperior", Vector3(2.22, 0.08, 1.58), Vector3(0.0, 0.58, 0.0), PAPEL)
	_caja(raiz, "CuerdaX", Vector3(2.48, 0.07, 0.07), Vector3(0.0, 0.66, 0.0), BRONCE)
	_caja(raiz, "CuerdaZ", Vector3(0.07, 0.07, 1.88), Vector3(0.0, 0.67, 0.0), BRONCE)
	_cilindro(
		raiz, "Sello", 0.24, 0.27, 0.08, Vector3(0.0, 0.74, -0.02), BRONCE, 24
	)
	return raiz


static func _material_local(material: StandardMaterial3D) -> StandardMaterial3D:
	var copia := material.duplicate() as StandardMaterial3D
	copia.resource_local_to_scene = true
	return copia


static func _caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	material: StandardMaterial3D,
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = mesh
	nodo.position = posicion
	nodo.material_override = _material_local(material)
	padre.add_child(nodo)
	return nodo


static func _cilindro(
	padre: Node3D,
	nombre: String,
	radio_superior: float,
	radio_inferior: float,
	altura: float,
	posicion: Vector3,
	material: StandardMaterial3D,
	segmentos: int,
	rotacion: Vector3 = Vector3.ZERO,
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radio_superior
	mesh.bottom_radius = radio_inferior
	mesh.height = altura
	mesh.radial_segments = segmentos
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = mesh
	nodo.position = posicion
	nodo.rotation_degrees = rotacion
	nodo.material_override = _material_local(material)
	padre.add_child(nodo)
	return nodo


static func _esfera(
	padre: Node3D,
	nombre: String,
	posicion: Vector3,
	escala: Vector3,
	material: StandardMaterial3D,
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = mesh
	nodo.position = posicion
	nodo.scale = escala
	nodo.material_override = _material_local(material)
	padre.add_child(nodo)
	return nodo
