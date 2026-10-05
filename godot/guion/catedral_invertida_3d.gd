## Runtime 3D mínimo para la catedral invertida (#2431).
##
## Rota únicamente el contenedor de arquitectura alrededor de un ancla estable.
## El jugador y la cámara deben vivir fuera de este nodo para no heredar la
## transformación. CatedralInvertida sigue siendo la fuente de verdad.
class_name CatedralInvertida3D
extends Node3D

@export var reduccion_movimiento := false

var _arquitectura: Node3D
var _tween: Tween
var _orientacion := CatedralInvertida.SUELO
var _montada := false


func preparar() -> void:
	if _montada:
		return
	_montada = true
	_arquitectura = Node3D.new()
	_arquitectura.name = "Arquitectura"
	add_child(_arquitectura)

	_crear_caja("Suelo", Vector3(12.0, 0.24, 8.0), Vector3(0.0, -0.12, 0.0), Color(0.16, 0.15, 0.18))
	_crear_caja("Techo", Vector3(12.0, 0.24, 8.0), Vector3(0.0, 5.0, 0.0), Color(0.12, 0.11, 0.14))
	_crear_caja("MuroDerecho", Vector3(0.24, 5.2, 8.0), Vector3(6.0, 2.5, 0.0), Color(0.23, 0.21, 0.25))
	_crear_caja("MuroIzquierdo", Vector3(0.24, 5.2, 8.0), Vector3(-6.0, 2.5, 0.0), Color(0.23, 0.21, 0.25))
	_crear_caja("ReferenciaCentral", Vector3(0.40, 3.8, 0.40), Vector3(0.0, 1.9, 0.0), Color(0.58, 0.52, 0.42))


func orientacion_actual() -> String:
	return _orientacion


func plan_hasta(destino: String) -> Dictionary:
	return CatedralInvertida.plan_transicion(_orientacion, destino, reduccion_movimiento, global_position)


func aplicar_orientacion(destino: String) -> Dictionary:
	preparar()
	var plan := plan_hasta(destino)
	_orientacion = String(plan["destino"])

	if _tween != null and _tween.is_valid():
		_tween.kill()

	var rotacion: Vector3 = plan["rotacion_destino"]
	if not bool(plan["animar"]):
		_arquitectura.rotation_degrees = rotacion
		return plan

	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_arquitectura, "rotation_degrees", rotacion, float(plan["duracion"]))
	return plan


func avanzar() -> Dictionary:
	return aplicar_orientacion(CatedralInvertida.siguiente(_orientacion))


func nodo_arquitectura() -> Node3D:
	preparar()
	return _arquitectura


func _crear_caja(nombre: String, tam: Vector3, posicion: Vector3, color: Color) -> MeshInstance3D:
	var malla := BoxMesh.new()
	malla.size = tam
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	nodo.mesh = malla
	nodo.position = posicion
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	nodo.material_override = material
	_arquitectura.add_child(nodo)
	return nodo
