extends SceneTree

const Catedral3D := preload("res://guion/catedral_invertida_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_montaje()
	_probar_giro_reducido()
	_probar_giro_normal()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _nueva() -> CatedralInvertida3D:
	var nodo := Catedral3D.new()
	get_root().add_child(nodo)
	nodo.preparar()
	return nodo


func _probar_montaje() -> void:
	var nodo := _nueva()
	_comprobar(nodo.orientacion_actual() == CatedralInvertida.SUELO, "parte en suelo")
	var arquitectura := nodo.nodo_arquitectura()
	_comprobar(arquitectura != null, "crea un contenedor de arquitectura")
	_comprobar(arquitectura.get_parent() == nodo, "la arquitectura cuelga del runtime")
	_comprobar(nodo.get_node_or_null("Arquitectura/ReferenciaCentral") != null, "mantiene referencia visual central")
	_comprobar(nodo.get_node_or_null("Arquitectura/Suelo") != null, "monta suelo en contenedor rotatorio")
	_comprobar(nodo.get_node_or_null("Arquitectura/Techo") != null, "monta techo en contenedor rotatorio")
	nodo.queue_free()


func _probar_giro_reducido() -> void:
	var nodo := _nueva()
	nodo.reduccion_movimiento = true
	var plan := nodo.aplicar_orientacion(CatedralInvertida.MURO_DERECHO)
	_comprobar(not plan.get("animar", true), "modo reducido no anima")
	_comprobar(nodo.orientacion_actual() == CatedralInvertida.MURO_DERECHO, "actualiza orientación lógica")
	_comprobar(nodo.nodo_arquitectura().rotation_degrees == Vector3(0.0, 0.0, -90.0), "aplica giro sobre arquitectura")
	_comprobar(nodo.rotation_degrees == Vector3.ZERO, "no rota el nodo raíz")
	nodo.queue_free()


func _probar_giro_normal() -> void:
	var nodo := _nueva()
	nodo.reduccion_movimiento = false
	var raiz_antes := nodo.rotation_degrees
	var plan := nodo.avanzar()
	_comprobar(plan.get("animar", false), "modo normal planifica tween")
	_comprobar(nodo.orientacion_actual() == CatedralInvertida.MURO_DERECHO, "avanzar cambia orientación")
	_comprobar(nodo.rotation_degrees == raiz_antes, "el runtime no rota su raíz")
	_comprobar(nodo.nodo_arquitectura() != nodo, "jugador y cámara pueden vivir fuera del contenedor")
	nodo.queue_free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO catedral invertida 3D: " + nombre)
