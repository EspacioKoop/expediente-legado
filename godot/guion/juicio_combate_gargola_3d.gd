## Presentacion placeholder de la Gargola de Umbral (#2092/#2196).
##
## Consume solo las senales publicas del runtime compuesto. No mueve al rival,
## no calcula transiciones, no detecta colisiones y no aplica dano.
class_name JuicioCombateGargola3D
extends RefCounted

const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const COLOR_PIEDRA := Color(0.30, 0.31, 0.32)
const COLOR_PIEDRA_CLARA := Color(0.43, 0.44, 0.45)
const COLOR_CANAL := Color(0.12, 0.13, 0.14)
const COLOR_PLACA := Color(0.74, 0.72, 0.64, 0.42)
const COLOR_CARGA := Color(0.92, 0.38, 0.12, 0.42)

const TELEGRAPH_GUARDIA := "guardia"
const TELEGRAPH_CARGA := "carga_lineal"
const TELEGRAPH_VULNERABLE := "vulnerable"


static func montar(rival: Node3D) -> Dictionary:
	if rival == null:
		return {}

	var raiz := Node3D.new()
	raiz.name = "GargolaUmbral"
	rival.add_child(raiz)

	var torso := _caja(
		raiz,
		"TorsoPiedra",
		Vector3(1.04, 1.18, 0.66),
		Vector3(0.0, 1.05, 0.0),
		COLOR_PIEDRA,
	)
	var pecho := _caja(
		raiz,
		"PechoUmbral",
		Vector3(0.72, 0.58, 0.16),
		Vector3(0.0, 1.12, 0.38),
		COLOR_PIEDRA_CLARA,
	)

	var cabeza := MeshInstance3D.new()
	cabeza.name = "CabezaGrotesca"
	var malla_cabeza := SphereMesh.new()
	malla_cabeza.radius = 0.34
	malla_cabeza.height = 0.64
	cabeza.mesh = malla_cabeza
	cabeza.position = Vector3(0.0, 1.86, 0.08)
	cabeza.scale = Vector3(1.08, 0.88, 0.94)
	cabeza.material_override = FEEDBACK.material(COLOR_PIEDRA_CLARA)
	raiz.add_child(cabeza)

	var canal := _caja(
		raiz,
		"CanalTallado",
		Vector3(0.14, 0.62, 0.055),
		Vector3(0.0, 1.10, 0.475),
		COLOR_CANAL,
	)

	var ala_izq := _caja(
		raiz,
		"AlaPlegadaIzq",
		Vector3(0.30, 0.92, 0.18),
		Vector3(-0.64, 1.28, -0.08),
		COLOR_PIEDRA,
	)
	ala_izq.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(16.0), deg_to_rad(24.0))

	var ala_der := _caja(
		raiz,
		"AlaPlegadaDer",
		Vector3(0.30, 0.92, 0.18),
		Vector3(0.64, 1.28, -0.08),
		COLOR_PIEDRA,
	)
	ala_der.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(-16.0), deg_to_rad(-24.0))

	var placa := _caja(
		raiz,
		"PlacaGuardia",
		Vector3(1.22, 1.02, 0.08),
		Vector3(0.0, 1.08, 0.56),
		COLOR_PLACA,
		true,
	)
	placa.visible = false

	var linea := MeshInstance3D.new()
	linea.name = "LineaCarga"
	var malla_linea := BoxMesh.new()
	malla_linea.size = Vector3(0.72, 0.045, 5.6)
	linea.mesh = malla_linea
	var material_linea := FEEDBACK.material(COLOR_CARGA, true)
	material_linea.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	linea.material_override = material_linea
	linea.position = Vector3(0.0, 0.055, -2.90)
	linea.visible = false
	raiz.add_child(linea)

	return {
		"raiz": raiz,
		"torso": torso,
		"pecho": pecho,
		"cabeza": cabeza,
		"canal": canal,
		"ala_izq": ala_izq,
		"ala_der": ala_der,
		"placa": placa,
		"linea": linea,
	}


static func pintar(
	presentacion: Dictionary,
	salida_runtime: Dictionary,
	reduccion_movimiento: bool,
) -> void:
	var raiz := presentacion.get("raiz") as Node3D
	var cabeza := presentacion.get("cabeza") as MeshInstance3D
	var ala_izq := presentacion.get("ala_izq") as MeshInstance3D
	var ala_der := presentacion.get("ala_der") as MeshInstance3D
	var placa := presentacion.get("placa") as MeshInstance3D
	var linea := presentacion.get("linea") as MeshInstance3D
	if raiz == null or cabeza == null or ala_izq == null or ala_der == null:
		return
	if placa == null or linea == null:
		return

	var modo := String(salida_runtime.get("modo", ""))
	var telegraph := String(salida_runtime.get("telegraph", ""))
	var guardia_frontal := bool(salida_runtime.get("guardia_frontal", false))
	var inicio_carga := bool(salida_runtime.get("inicio_carga", false))
	var abrir_ventana := bool(salida_runtime.get("abrir_ventana", false))
	var cargando := telegraph == TELEGRAPH_CARGA or inicio_carga
	var vulnerable := telegraph == TELEGRAPH_VULNERABLE or abrir_ventana

	# Pose base: piedra frontal, alas plegadas y volumen asentado.
	raiz.rotation.x = 0.0
	cabeza.position.y = 1.86
	cabeza.rotation.x = 0.0
	ala_izq.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(16.0), deg_to_rad(24.0))
	ala_der.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(-16.0), deg_to_rad(-24.0))

	placa.visible = guardia_frontal or telegraph == TELEGRAPH_GUARDIA
	linea.visible = cargando

	if vulnerable:
		# La recuperacion abre la silueta y apaga la placa: la ventana debe leerse
		# incluso sin texto, particulas ni animacion.
		placa.visible = false
		raiz.rotation.x = deg_to_rad(11.0)
		cabeza.position.y = 1.76
		cabeza.rotation.x = deg_to_rad(14.0)
		ala_izq.rotation.z = deg_to_rad(42.0)
		ala_der.rotation.z = deg_to_rad(-42.0)
	elif cargando:
		raiz.rotation.x = deg_to_rad(-13.0)
		cabeza.position.y = 1.78
		cabeza.rotation.x = deg_to_rad(-11.0)
	elif guardia_frontal or telegraph == TELEGRAPH_GUARDIA:
		raiz.rotation.x = deg_to_rad(-4.0)

	# La reduccion de movimiento mantiene exactamente las mismas poses estaticas;
	# solo evita el realce efimero del evento de inicio de carga.
	var material_linea := linea.material_override as StandardMaterial3D
	if material_linea != null:
		material_linea.emission_energy_multiplier = (
			1.15 if inicio_carga and not reduccion_movimiento else 0.72
		)

	# Leer `modo` mantiene el contrato explicito sin convertirlo en una segunda
	# maquina de estados. Una cadena desconocida no cambia la presentacion.
	if modo.is_empty():
		return


static func _caja(
	padre: Node3D,
	nombre: String,
	tamano: Vector3,
	posicion: Vector3,
	color: Color,
	transparente: bool = false,
) -> MeshInstance3D:
	var pieza := MeshInstance3D.new()
	pieza.name = nombre
	var malla := BoxMesh.new()
	malla.size = tamano
	pieza.mesh = malla
	pieza.position = posicion
	var material := FEEDBACK.material(color, transparente)
	if transparente:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pieza.material_override = material
	padre.add_child(pieza)
	return pieza
