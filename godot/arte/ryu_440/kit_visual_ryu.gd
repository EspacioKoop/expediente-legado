@tool
extends Node3D

## Kit visual autónomo para el sueño de Ryū (#440).
##
## Estas piezas son dressing opcional: no alteran objetivos, semillas, flujo ni
## navegación. Se construyen con PrimitiveMesh de Godot para mantener el corte
## editable, determinista y libre de assets externos.

const NOMBRE_RAIZ := "KitRyuVisual"

const COLOR_LACA := Color(0.38, 0.055, 0.045)
const COLOR_LACA_OSCURA := Color(0.15, 0.025, 0.025)
const COLOR_METAL_HUMEDO := Color(0.20, 0.24, 0.26)
const COLOR_AGUA := Color(0.14, 0.60, 0.74, 0.72)
const COLOR_AGUA_LUZ := Color(0.42, 0.86, 0.92, 0.82)
const COLOR_NUBE := Color(0.44, 0.50, 0.55)
const COLOR_NUBE_LUZ := Color(0.62, 0.69, 0.72)
const COLOR_HUESO := Color(0.64, 0.59, 0.46)
const COLOR_HUESO_OSCURO := Color(0.31, 0.29, 0.24)
const COLOR_ORO := Color(0.78, 0.59, 0.20)

@export var construir_al_cargar := true


func _ready() -> void:
	if construir_al_cargar and get_node_or_null(NOMBRE_RAIZ) == null:
		construir()


func construir() -> void:
	var existente := get_node_or_null(NOMBRE_RAIZ)
	if existente != null:
		existente.queue_free()

	var raiz := Node3D.new()
	raiz.name = NOMBRE_RAIZ
	add_child(raiz)

	_montar_torii_suspendido(raiz)
	_montar_cascada_invertida(raiz)
	_montar_nube_interior(raiz)
	_montar_puente_vertebra(raiz)
	_montar_faroles_de_lluvia(raiz)


func _montar_torii_suspendido(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "ToriiSuspendido"
	grupo.position = Vector3(-6.8, 1.4, 0.0)
	grupo.rotation_degrees = Vector3(0.0, 18.0, -4.0)
	raiz.add_child(grupo)

	for lado in [-1.0, 1.0]:
		_cilindro(
			grupo,
			"Pilar%s" % ("Izquierdo" if lado < 0.0 else "Derecho"),
			0.34,
			0.45,
			4.4,
			Vector3(lado * 1.85, 0.0, 0.0),
			COLOR_LACA,
		)
		_caja(
			grupo,
			"BaseFlotante%s" % ("Izquierda" if lado < 0.0 else "Derecha"),
			Vector3(1.1, 0.22, 1.1),
			Vector3(lado * 1.85, -2.28, 0.0),
			COLOR_LACA_OSCURA,
		)

	_caja(grupo, "Kasagi", Vector3(5.4, 0.34, 0.62), Vector3(0.0, 2.25, 0.0), COLOR_LACA)
	_caja(
		grupo,
		"Nuki",
		Vector3(4.35, 0.24, 0.38),
		Vector3(0.0, 1.45, 0.0),
		COLOR_LACA_OSCURA,
	)
	_esfera(grupo, "GotaOro", 0.22, Vector3(0.0, 1.85, 0.0), COLOR_ORO, true)


func _montar_cascada_invertida(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "CascadaInvertida"
	grupo.position = Vector3(-1.1, 0.1, 1.8)
	grupo.rotation_degrees.y = -12.0
	raiz.add_child(grupo)

	for indice in range(12):
		var t := float(indice) / 11.0
		var x := sin(t * PI * 2.4) * 0.42
		var z := cos(t * PI * 1.8) * 0.28
		var y := t * 6.6
		var tam := Vector3(0.52 - t * 0.18, 0.72, 1.35 - t * 0.35)
		_caja(
			grupo,
			"Laminar%02d" % indice,
			tam,
			Vector3(x, y, z),
			COLOR_AGUA if indice % 2 == 0 else COLOR_AGUA_LUZ,
			true,
		)

	_esfera(grupo, "NacimientoSuspendido", 0.78, Vector3(0.0, 7.0, 0.0), COLOR_AGUA_LUZ, true)
	for indice in range(5):
		_esfera(
			grupo,
			"GotaAscendente%02d" % indice,
			0.09 + float(indice % 2) * 0.035,
			Vector3(-0.55 + float(indice) * 0.28, 5.7 + float(indice) * 0.32, 0.55),
			COLOR_AGUA_LUZ,
			true,
		)


func _montar_nube_interior(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "NubeInterior"
	grupo.position = Vector3(5.8, 4.8, -1.8)
	raiz.add_child(grupo)

	var posiciones := [
		Vector3(-1.45, 0.0, 0.0),
		Vector3(-0.75, 0.42, 0.18),
		Vector3(0.05, 0.18, -0.12),
		Vector3(0.82, 0.48, 0.12),
		Vector3(1.48, 0.02, -0.08),
		Vector3(-0.55, -0.38, 0.35),
		Vector3(0.45, -0.34, 0.42),
		Vector3(0.02, 0.82, 0.0),
	]
	for indice in range(posiciones.size()):
		var radio := 0.72 + float((indice * 3) % 4) * 0.13
		_esfera(
			grupo,
			"Volumen%02d" % indice,
			radio,
			posiciones[indice],
			COLOR_NUBE_LUZ if indice % 3 == 0 else COLOR_NUBE,
		)

	_caja(
		grupo,
		"UmbralDentroDeNube",
		Vector3(1.6, 2.35, 0.22),
		Vector3(0.0, -0.15, 0.45),
		COLOR_METAL_HUMEDO,
	)


func _montar_puente_vertebra(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "PuenteVertebra"
	grupo.position = Vector3(2.4, 0.85, 4.3)
	grupo.rotation_degrees.y = 8.0
	raiz.add_child(grupo)

	for indice in range(10):
		var x := -4.5 + float(indice)
		var y := sin(float(indice) * 0.52) * 0.34
		var z := sin(float(indice) * 0.31) * 0.25
		_caja(
			grupo,
			"Vertebra%02d" % indice,
			Vector3(0.72, 0.28, 1.65),
			Vector3(x, y, z),
			COLOR_HUESO if indice % 2 == 0 else COLOR_HUESO_OSCURO,
		)
		_cilindro(
			grupo,
			"Arco%02d" % indice,
			0.10,
			0.16,
			2.25,
			Vector3(x, y + 0.78, z),
			COLOR_HUESO,
			Vector3(90.0, 0.0, 0.0),
		)

	_caja(
		grupo,
		"EjeTransitable",
		Vector3(10.2, 0.12, 0.75),
		Vector3(0.0, -0.02, 0.0),
		COLOR_METAL_HUMEDO,
	)


func _montar_faroles_de_lluvia(raiz: Node3D) -> void:
	var grupo := Node3D.new()
	grupo.name = "FarolesDeLluvia"
	grupo.position = Vector3(0.5, 2.2, -4.7)
	raiz.add_child(grupo)

	for indice in range(5):
		var x := -3.0 + float(indice) * 1.5
		var y := sin(float(indice) * 0.9) * 0.45
		_caja(
			grupo,
			"Farol%02d" % indice,
			Vector3(0.52, 0.72, 0.52),
			Vector3(x, y, 0.0),
			Color(0.34, 0.30, 0.20),
		)
		_esfera(
			grupo,
			"Nucleo%02d" % indice,
			0.18,
			Vector3(x, y, 0.0),
			COLOR_ORO,
			true,
		)
		for gota in range(3):
			_caja(
				grupo,
				"Gota%02d_%02d" % [indice, gota],
				Vector3(0.035, 0.42, 0.035),
				Vector3(x - 0.22 + float(gota) * 0.22, y + 0.72 + float(gota) * 0.34, 0.0),
				COLOR_AGUA_LUZ,
				true,
			)


func _caja(
	padre: Node3D,
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
	transparente: bool = false,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color, transparente)
	padre.add_child(nodo)
	return nodo


func _cilindro(
	padre: Node3D,
	nombre: String,
	radio_superior: float,
	radio_inferior: float,
	altura: float,
	posicion: Vector3,
	color: Color,
	rotacion: Vector3 = Vector3.ZERO,
) -> MeshInstance3D:
	var malla := CylinderMesh.new()
	malla.top_radius = radio_superior
	malla.bottom_radius = radio_inferior
	malla.height = altura
	malla.radial_segments = 10
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.rotation_degrees = rotacion
	nodo.material_override = _material(color)
	padre.add_child(nodo)
	return nodo


func _esfera(
	padre: Node3D,
	nombre: String,
	radio: float,
	posicion: Vector3,
	color: Color,
	emisivo: bool = false,
) -> MeshInstance3D:
	var malla := SphereMesh.new()
	malla.radius = radio
	malla.height = radio * 2.0
	malla.radial_segments = 12
	malla.rings = 7
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	nodo.material_override = _material(color, color.a < 0.99, emisivo)
	padre.add_child(nodo)
	return nodo


func _material(
	color: Color, transparente: bool = false, emisivo: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	material.metallic = 0.16
	if transparente:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emisivo:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b) * 0.85
	return material
