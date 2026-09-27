## Microgestos para figuras abstractas de sueño (#134).
##
## No añade navegación, colisión ni estado de juego: solo rompe la inmovilidad
## de la silueta procedural. Todas respiran y mueven levemente brazos/cabeza;
## únicamente quien venga marcado con `mirar_jugador` puede seguir de forma
## acotada la cámara cercana. En el sueño ese privilegio se reserva al acusado,
## para que «me están mirando» sea una decisión y no ruido de toda la sala.
class_name FiguraIdle3D
extends Node

const AMPLITUD_RESPIRACION := 0.007
const AMPLITUD_CABEZA := deg_to_rad(6.0)
const AMPLITUD_INCLINACION := deg_to_rad(1.5)
const AMPLITUD_BRAZO := deg_to_rad(2.0)
const DISTANCIA_ATENCION := 3.2
const GIRO_ATENCION_MAX := deg_to_rad(12.0)
const VELOCIDAD_GIRO := deg_to_rad(55.0)
const VELOCIDAD := 1.2

var objetivo: Node3D
var fase := 0.0
var mirar_jugador := false
var reduccion_movimiento := false

var _tiempo := 0.0
var _escala_base := Vector3.ONE
var _cabeza: Node3D
var _brazo_izquierdo: Node3D
var _brazo_derecho: Node3D
var _rotacion_cabeza := Vector3.ZERO
var _rotacion_brazo_izquierdo := Vector3.ZERO
var _rotacion_brazo_derecho := Vector3.ZERO
var _giro_cabeza := 0.0


func configurar(nuevo: Node3D, nueva_fase: float = 0.0, seguir: bool = false) -> void:
	objetivo = nuevo
	fase = nueva_fase
	mirar_jugador = seguir
	reduccion_movimiento = bool(
		PreferenciasSiga.cargar().get("reduccion_movimiento", false)
	)
	_escala_base = objetivo.scale
	_cabeza = objetivo.get_node_or_null("Cabeza") as Node3D
	_brazo_izquierdo = objetivo.get_node_or_null("BrazoIzquierdo") as Node3D
	_brazo_derecho = objetivo.get_node_or_null("BrazoDerecho") as Node3D
	if _cabeza != null:
		_rotacion_cabeza = _cabeza.rotation
	if _brazo_izquierdo != null:
		_rotacion_brazo_izquierdo = _brazo_izquierdo.rotation
	if _brazo_derecho != null:
		_rotacion_brazo_derecho = _brazo_derecho.rotation


func _process(delta: float) -> void:
	if not is_instance_valid(objetivo):
		return
	if reduccion_movimiento:
		_restaurar()
		return

	var paso := maxf(delta, 0.0)
	_tiempo += paso * VELOCIDAD
	var pulso := sin(_tiempo + fase)
	objetivo.scale = Vector3(
		_escala_base.x,
		_escala_base.y * (1.0 + pulso * AMPLITUD_RESPIRACION),
		_escala_base.z
	)

	var giro_ambiente := sin(_tiempo * 0.45 + fase * 1.7) * AMPLITUD_CABEZA
	var destino_giro := _destino_atencion(giro_ambiente)
	_giro_cabeza = move_toward(_giro_cabeza, destino_giro, VELOCIDAD_GIRO * paso)
	if is_instance_valid(_cabeza):
		_cabeza.rotation.y = _rotacion_cabeza.y + _giro_cabeza
		_cabeza.rotation.z = (
			_rotacion_cabeza.z
			+ sin(_tiempo * 0.31 + fase * 0.8) * AMPLITUD_INCLINACION
		)

	var balanceo := sin(_tiempo * 0.72 + fase * 1.3) * AMPLITUD_BRAZO
	if is_instance_valid(_brazo_izquierdo):
		_brazo_izquierdo.rotation.z = _rotacion_brazo_izquierdo.z + balanceo
	if is_instance_valid(_brazo_derecho):
		_brazo_derecho.rotation.z = _rotacion_brazo_derecho.z - balanceo


func _destino_atencion(respaldo: float) -> float:
	if not mirar_jugador or not is_instance_valid(objetivo):
		return respaldo
	var camara := get_viewport().get_camera_3d()
	if camara == null:
		return respaldo
	if objetivo.global_position.distance_to(camara.global_position) > DISTANCIA_ATENCION:
		return respaldo
	var local := objetivo.to_local(camara.global_position)
	# Frente de Godot es -Z. Si ya has pasado a su espalda vuelve al microgesto.
	if local.z >= 0.0:
		return respaldo
	return clampf(atan2(local.x, -local.z), -GIRO_ATENCION_MAX, GIRO_ATENCION_MAX)


func _restaurar() -> void:
	if is_instance_valid(objetivo):
		objetivo.scale = _escala_base
	_giro_cabeza = 0.0
	if is_instance_valid(_cabeza):
		_cabeza.rotation = _rotacion_cabeza
	if is_instance_valid(_brazo_izquierdo):
		_brazo_izquierdo.rotation = _rotacion_brazo_izquierdo
	if is_instance_valid(_brazo_derecho):
		_brazo_derecho.rotation = _rotacion_brazo_derecho


func _exit_tree() -> void:
	_restaurar()
