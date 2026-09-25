class_name BabaYagaHabitacionGiratoria
extends Node3D

const POSICIONES_FASE := [
	Vector3(5.35, 2.55, 4.45),
	Vector3(5.15, 2.70, 4.30),
	Vector3(5.55, 2.95, 4.10),
	Vector3(5.30, 2.65, 4.35),
]
const ROTACIONES_FASE := [
	Vector3.ZERO,
	Vector3(0.0, 0.0, 18.0),
	Vector3(0.0, 0.0, 90.0),
	Vector3(0.0, 0.0, 112.0),
]
const ESTADOS_EXTERIOR := [false, false, true, true]
const DURACION_GIRO := 0.24

const COLOR_SUELO := Color(0.13, 0.15, 0.13)
const COLOR_MADERA := Color(0.32, 0.23, 0.15)
const COLOR_ARCHIVO := Color(0.28, 0.31, 0.30)
const COLOR_CABANA := Color(0.42, 0.31, 0.20)
const COLOR_INTERIOR := Color(0.54, 0.43, 0.27)
const COLOR_COMPARACION := Color(0.72, 0.78, 0.67)

var _tween: Tween
var _montada := false


func preparar() -> void:
	if _montada:
		return
	_montada = true
	name = "HabitacionGiratoria"

	_crear_caja(
		"SueloHabitacion",
		Vector3(3.20, 0.10, 2.60),
		Vector3(0.0, -1.30, 0.0),
		COLOR_INTERIOR,
	)
	_crear_caja(
		"ParedFondo",
		Vector3(3.20, 2.60, 0.10),
		Vector3(0.0, 0.0, -1.30),
		COLOR_ARCHIVO,
	)
	_crear_caja(
		"ParedLateral",
		Vector3(0.10, 2.60, 2.60),
		Vector3(-1.60, 0.0, 0.0),
		COLOR_ARCHIVO,
	)
	_crear_caja(
		"TechoHabitacion",
		Vector3(3.20, 0.10, 2.60),
		Vector3(0.0, 1.30, 0.0),
		COLOR_SUELO,
	)

	var interior := Node3D.new()
	interior.name = "LecturaInterior"
	add_child(interior)
	_crear_caja(
		"MesaInterior",
		Vector3(1.25, 0.12, 0.75),
		Vector3(0.45, -0.75, 0.15),
		COLOR_MADERA,
		interior,
	)
	_crear_caja(
		"LuzInterior",
		Vector3(1.35, 0.06, 0.18),
		Vector3(0.0, 1.12, 0.0),
		COLOR_COMPARACION,
		interior,
	)

	var exterior := Node3D.new()
	exterior.name = "LecturaExterior"
	add_child(exterior)
	_crear_caja(
		"AleroExterior",
		Vector3(3.45, 0.18, 0.70),
		Vector3(0.0, 1.28, -1.18),
		COLOR_MADERA,
		exterior,
	)
	for i in 4:
		_crear_caja(
			"ListonFachada%02d" % (i + 1),
			Vector3(0.12, 2.20, 0.12),
			Vector3(-1.15 + float(i) * 0.76, 0.0, -1.38),
			COLOR_CABANA,
			exterior,
		)


static func estado_para_fase(fase: int) -> Dictionary:
	var indice := posmod(fase, POSICIONES_FASE.size())
	return {
		"fase": indice,
		"posicion": POSICIONES_FASE[indice],
		"rotacion": ROTACIONES_FASE[indice],
		"exterior": ESTADOS_EXTERIOR[indice],
	}


func aplicar_estado(fase: int) -> void:
	preparar()
	var estado := estado_para_fase(fase)
	position = estado["posicion"]
	rotation_degrees = estado["rotacion"]
	var interior := get_node_or_null("LecturaInterior") as Node3D
	var exterior := get_node_or_null("LecturaExterior") as Node3D
	if interior != null:
		interior.visible = not bool(estado["exterior"])
	if exterior != null:
		exterior.visible = bool(estado["exterior"])


func plan_giro(origen: Dictionary, fase: int, reduccion_movimiento: bool) -> Dictionary:
	return {
		"aplicado": true,
		"modo": "corte_fundido" if reduccion_movimiento else "giro_habitacion",
		"animar": not reduccion_movimiento,
		"origen": origen.duplicate(true),
		"destino": estado_para_fase(fase),
		"duracion": 0.0 if reduccion_movimiento else DURACION_GIRO,
		"desplazar_jugador": false,
		"mover_camara": false,
	}


func aplicar_giro(origen: Dictionary, fase: int, reduccion_movimiento: bool) -> Dictionary:
	preparar()
	var plan := plan_giro(origen, fase, reduccion_movimiento)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var destino: Dictionary = plan["destino"]
	if reduccion_movimiento:
		position = destino["posicion"]
		rotation_degrees = destino["rotacion"]
		return plan

	position = origen["posicion"]
	rotation_degrees = origen["rotacion"]
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "position", destino["posicion"], DURACION_GIRO)
	_tween.tween_property(self, "rotation_degrees", destino["rotacion"], DURACION_GIRO)
	return plan


func _crear_caja(
	nombre: String,
	tam: Vector3,
	posicion: Vector3,
	color: Color,
	padre: Node3D = self,
) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	nodo.material_override = material
	padre.add_child(nodo)
	return nodo
