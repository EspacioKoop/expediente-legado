## Presentación placeholder de Arpía sobre HOSTIGADOR (#2087/#2359).
##
## Consume exclusivamente la salida pública de JuicioCombateHostigador3D.
## El corredor lineal, movimiento, impacto y timers siguen perteneciendo al
## runtime común; aquí solo se transforma su lectura en un picado alado.
class_name JuicioCombateArpia3D
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const FEEDBACK = preload("res://guion/juicio_combate_feedback_3d.gd")

const COLOR_PLUMA := Color(0.30, 0.23, 0.20)
const COLOR_PLUMA_CLARA := Color(0.48, 0.38, 0.31)
const COLOR_PIEL := Color(0.58, 0.45, 0.37)
const COLOR_OJO := Color(0.96, 0.52, 0.14)

const ALTURA_BASE := 0.16


static func montar(rival: Node3D) -> Dictionary:
	if rival == null:
		return {}

	var raiz := Node3D.new()
	raiz.name = "ArpiaHostigadora"
	raiz.position.y = ALTURA_BASE
	rival.add_child(raiz)

	var torso := _caja(
		raiz,
		"Torso",
		Vector3(0.62, 0.96, 0.42),
		Vector3(0.0, 1.18, 0.0),
		COLOR_PIEL,
	)

	var cabeza := MeshInstance3D.new()
	cabeza.name = "Cabeza"
	var malla_cabeza := SphereMesh.new()
	malla_cabeza.radius = 0.27
	malla_cabeza.height = 0.50
	cabeza.mesh = malla_cabeza
	cabeza.position = Vector3(0.0, 1.88, 0.06)
	cabeza.material_override = FEEDBACK.material(COLOR_PIEL)
	raiz.add_child(cabeza)

	var ala_izq := _ala(raiz, "AlaIzq", -1.0)
	var ala_der := _ala(raiz, "AlaDer", 1.0)

	var pata_izq := _caja(
		raiz,
		"GarraIzq",
		Vector3(0.16, 0.54, 0.18),
		Vector3(-0.20, 0.48, 0.10),
		COLOR_PLUMA_CLARA,
	)
	pata_izq.rotation.x = deg_to_rad(-12.0)
	var pata_der := _caja(
		raiz,
		"GarraDer",
		Vector3(0.16, 0.54, 0.18),
		Vector3(0.20, 0.48, 0.10),
		COLOR_PLUMA_CLARA,
	)
	pata_der.rotation.x = deg_to_rad(-12.0)

	var ojo_izq := _ojo(cabeza, "OjoIzq", -0.09)
	var ojo_der := _ojo(cabeza, "OjoDer", 0.09)

	return {
		"raiz": raiz,
		"torso": torso,
		"cabeza": cabeza,
		"ala_izq": ala_izq,
		"ala_der": ala_der,
		"pata_izq": pata_izq,
		"pata_der": pata_der,
		"ojo_izq": ojo_izq,
		"ojo_der": ojo_der,
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
	if raiz == null or cabeza == null or ala_izq == null or ala_der == null:
		return

	var unidad = salida_runtime.get("unidad", {})
	if not unidad is Dictionary:
		return
	var estado := String(unidad.get("estado", ""))

	_restablecer_pose(raiz, cabeza, ala_izq, ala_der)

	match estado:
		ARQUETIPOS.TELEGRAFIAR:
			# Abre las alas y eleva el pecho: la trayectoria está anunciada,
			# pero el cuerpo todavía no se lanza.
			raiz.position.y = ALTURA_BASE + 0.22
			raiz.rotation.x = deg_to_rad(-7.0)
			ala_izq.rotation.z = deg_to_rad(-58.0)
			ala_der.rotation.z = deg_to_rad(58.0)
		ARQUETIPOS.DISPARAR_LINEA:
			# El cuerpo visual se inclina sobre el mismo corredor lineal que ya
			# resuelve HOSTIGADOR. No se altera la posición física del rival.
			raiz.position.y = ALTURA_BASE + 0.04
			raiz.rotation.x = deg_to_rad(-32.0)
			cabeza.rotation.x = deg_to_rad(-16.0)
			ala_izq.rotation.z = deg_to_rad(-26.0)
			ala_der.rotation.z = deg_to_rad(26.0)
		ARQUETIPOS.VULNERABLE:
			# Tras el picado la silueta queda baja y abierta: ventana visible
			# aun con reducción de movimiento.
			raiz.position.y = ALTURA_BASE - 0.08
			raiz.rotation.x = deg_to_rad(18.0)
			cabeza.position.y = 1.76
			ala_izq.rotation.z = deg_to_rad(-78.0)
			ala_der.rotation.z = deg_to_rad(78.0)
		_:
			if not reduccion_movimiento:
				var pulso := sin(float(Time.get_ticks_msec()) * 0.003) * 0.035
				ala_izq.rotation.z += pulso
				ala_der.rotation.z -= pulso

	_pintar_ojos(presentacion, estado)


static func limpiar(presentacion: Dictionary) -> void:
	var raiz := presentacion.get("raiz") as Node3D
	if raiz != null and is_instance_valid(raiz):
		raiz.queue_free()
	presentacion.clear()


static func _restablecer_pose(
	raiz: Node3D,
	cabeza: MeshInstance3D,
	ala_izq: MeshInstance3D,
	ala_der: MeshInstance3D,
) -> void:
	raiz.position.y = ALTURA_BASE
	raiz.rotation = Vector3.ZERO
	cabeza.position.y = 1.88
	cabeza.rotation = Vector3.ZERO
	ala_izq.rotation = Vector3(deg_to_rad(-10.0), deg_to_rad(8.0), deg_to_rad(-34.0))
	ala_der.rotation = Vector3(deg_to_rad(-10.0), deg_to_rad(-8.0), deg_to_rad(34.0))


static func _pintar_ojos(presentacion: Dictionary, estado: String) -> void:
	var energia := 0.75
	if estado == ARQUETIPOS.TELEGRAFIAR:
		energia = 1.35
	elif estado == ARQUETIPOS.DISPARAR_LINEA:
		energia = 1.70
	elif estado == ARQUETIPOS.VULNERABLE:
		energia = 0.35

	for clave in ["ojo_izq", "ojo_der"]:
		var ojo := presentacion.get(clave) as MeshInstance3D
		if ojo == null:
			continue
		var material := ojo.material_override as StandardMaterial3D
		if material != null:
			material.emission_energy_multiplier = energia


static func _ala(padre: Node3D, nombre: String, lado: float) -> MeshInstance3D:
	var ala := _caja(
		padre,
		nombre,
		Vector3(0.84, 1.08, 0.13),
		Vector3(lado * 0.64, 1.38, -0.05),
		COLOR_PLUMA,
	)
	ala.rotation = Vector3(
		deg_to_rad(-10.0),
		deg_to_rad(-8.0 * lado),
		deg_to_rad(34.0 * lado),
	)
	return ala


static func _ojo(padre: Node3D, nombre: String, x: float) -> MeshInstance3D:
	var ojo := MeshInstance3D.new()
	ojo.name = nombre
	var malla := SphereMesh.new()
	malla.radius = 0.045
	malla.height = 0.08
	ojo.mesh = malla
	ojo.position = Vector3(x, 0.02, 0.245)
	ojo.scale = Vector3(1.0, 0.82, 0.52)
	ojo.material_override = FEEDBACK.material(COLOR_OJO, true)
	padre.add_child(ojo)
	return ojo


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
