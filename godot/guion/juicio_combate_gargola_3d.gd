## Presentación placeholder de la Gárgola de Umbral (#2092/#2196).
##
## Consume únicamente la salida del runtime compuesto BLOQUEADOR→EMBESTIDOR.
## No avanza estados, no mueve al rival, no detecta colisiones y no aplica daño.
class_name JuicioCombateGargola3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const COLOR_PIEDRA := Color(0.30, 0.31, 0.29)
const COLOR_PIEDRA_CLARA := Color(0.43, 0.44, 0.40)
const COLOR_UMBRAL := Color(0.72, 0.58, 0.34)
const COLOR_CARGA := Color(0.86, 0.34, 0.16, 0.34)


static func montar(rival: Node3D) -> Dictionary:
	if rival == null:
		return {}

	var raiz := Node3D.new()
	raiz.name = "GargolaUmbral"
	rival.add_child(raiz)

	var pedestal := _caja(
		raiz,
		"PedestalUmbral",
		Vector3(1.22, 0.18, 0.82),
		Vector3(0.0, 0.09, 0.0),
		COLOR_PIEDRA_CLARA,
	)
	var torso := _caja(
		raiz,
		"TorsoPiedra",
		Vector3(0.86, 1.02, 0.54),
		Vector3(0.0, 0.78, 0.0),
		COLOR_PIEDRA,
	)
	var cabeza := _caja(
		raiz,
		"CabezaCanal",
		Vector3(0.58, 0.44, 0.50),
		Vector3(0.0, 1.49, 0.10),
		COLOR_PIEDRA_CLARA,
	)
	_caja(
		raiz,
		"AlaPlegadaIzq",
		Vector3(0.20, 0.78, 0.48),
		Vector3(-0.52, 0.98, 0.08),
		COLOR_PIEDRA,
	).rotation.z = deg_to_rad(-18.0)
	_caja(
		raiz,
		"AlaPlegadaDer",
		Vector3(0.20, 0.78, 0.48),
		Vector3(0.52, 0.98, 0.08),
		COLOR_PIEDRA,
	).rotation.z = deg_to_rad(18.0)

	var placa := MeshInstance3D.new()
	placa.name = "PlacaGuardiaFrontal"
	var malla_placa := BoxMesh.new()
	malla_placa.size = Vector3(1.18, 1.30, 0.055)
	placa.mesh = malla_placa
	placa.position = Vector3(0.0, 0.88, 0.39)
	var material_placa := FEEDBACK.material(Color(COLOR_UMBRAL, 0.38), true)
	material_placa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	placa.material_override = material_placa
	placa.visible = true
	raiz.add_child(placa)

	var linea := MeshInstance3D.new()
	linea.name = "LineaCargaUmbral"
	var malla_linea := BoxMesh.new()
	malla_linea.size = Vector3(0.76, 0.035, 3.2)
	linea.mesh = malla_linea
	linea.position = Vector3(0.0, 0.04, -1.78)
	var material_linea := FEEDBACK.material(COLOR_CARGA, true)
	material_linea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	linea.material_override = material_linea
	linea.visible = false
	raiz.add_child(linea)

	return {
		"raiz": raiz,
		"pedestal": pedestal,
		"torso": torso,
		"cabeza": cabeza,
		"placa": placa,
		"linea": linea,
	}


static func pintar(
	presentacion: Dictionary,
	salida_runtime: Dictionary,
	reduccion_movimiento: bool,
) -> void:
	var raiz := presentacion.get("raiz") as Node3D
	var torso := presentacion.get("torso") as MeshInstance3D
	var cabeza := presentacion.get("cabeza") as MeshInstance3D
	var placa := presentacion.get("placa") as MeshInstance3D
	var linea := presentacion.get("linea") as MeshInstance3D
	if raiz == null or torso == null or cabeza == null or placa == null or linea == null:
		return

	var guardia := bool(salida_runtime.get("guardia_frontal", false))
	var telegraph := String(salida_runtime.get("telegraph", ""))
	var estado_interno: Dictionary = salida_runtime.get("estado", {})
	var embestidor: Dictionary = estado_interno.get("embestidor", {})
	var estado_embestidor := String(embestidor.get("estado", ""))
	var recuperando := estado_embestidor == ARQUETIPOS.RECUPERAR

	placa.visible = guardia
	linea.visible = telegraph == "carga_lineal"
	raiz.rotation.x = 0.0
	torso.position.y = 0.78
	cabeza.position.y = 1.49

	if recuperando:
		placa.visible = false
		raiz.rotation.x = deg_to_rad(10.0)
		torso.position.y = 0.72
		cabeza.position.y = 1.38
	elif bool(salida_runtime.get("inicio_carga", false)):
		raiz.rotation.x = deg_to_rad(-12.0)
	elif String(salida_runtime.get("modo", "")) == "embestidor":
		raiz.rotation.x = deg_to_rad(-7.0)

	if reduccion_movimiento:
		# La lectura se conserva con geometría estática: placa y línea no dependen
		# de oscilaciones, tweens ni animaciones decorativas.
		raiz.rotation.x = 0.0 if guardia else raiz.rotation.x


static func _caja(
	padre: Node3D,
	nombre: String,
	tamano: Vector3,
	posicion: Vector3,
	color: Color,
) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	pieza.mesh = malla
	pieza.position = posicion
	pieza.material_override = FEEDBACK.material(color)
	padre.add_child(pieza)
	return pieza
