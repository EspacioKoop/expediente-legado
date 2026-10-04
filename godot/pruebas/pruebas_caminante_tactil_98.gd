## Regresión pura del movimiento táctil del Caminante (#2290 / #98).
extends SceneTree

const CAMINANTE = preload("res://guion/caminante.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	_probar_zona_izquierda()
	_probar_vector_analogico()
	_probar_guardas()
	print("caminante_tactil_98: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_zona_izquierda() -> void:
	var tamano := Vector2(1000.0, 600.0)
	_comprobar(CAMINANTE.es_zona_movimiento_tactil(Vector2(100.0, 300.0), tamano), "izquierda reclama movimiento")
	_comprobar(CAMINANTE.es_zona_movimiento_tactil(Vector2(450.0, 599.0), tamano), "borde 45 por ciento incluido")
	_comprobar(not CAMINANTE.es_zona_movimiento_tactil(Vector2(451.0, 300.0), tamano), "derecha queda libre para mirar")
	_comprobar(not CAMINANTE.es_zona_movimiento_tactil(Vector2(-1.0, 20.0), tamano), "fuera de viewport no reclama")
	_comprobar(not CAMINANTE.es_zona_movimiento_tactil(Vector2(20.0, 20.0), Vector2.ZERO), "viewport invalido no reclama")


func _probar_vector_analogico() -> void:
	var origen := Vector2(200.0, 300.0)
	var arriba := CAMINANTE.vector_movimiento_tactil(origen, Vector2(200.0, 252.0), 96.0)
	_comprobar(is_equal_approx(arriba.x, 0.0), "arriba no introduce lateral")
	_comprobar(is_equal_approx(arriba.y, -0.5), "arriba conserva convención de avanzar")
	var diagonal := CAMINANTE.vector_movimiento_tactil(origen, Vector2(400.0, 500.0), 96.0)
	_comprobar(is_equal_approx(diagonal.length(), 1.0), "arrastre largo se acota a uno")
	_comprobar(diagonal.x > 0.0 and diagonal.y > 0.0, "diagonal conserva dirección")
	_comprobar(CAMINANTE.vector_movimiento_tactil(origen, origen, 96.0) == Vector2.ZERO, "origen es reposo")
	_comprobar(CAMINANTE.vector_movimiento_tactil(origen, Vector2.ZERO, 0.0) == Vector2.ZERO, "radio invalido es seguro")


func _probar_guardas() -> void:
	_comprobar(CAMINANTE.debe_procesar_movimiento_tactil(true, false), "gameplay activo acepta movimiento")
	_comprobar(not CAMINANTE.debe_procesar_movimiento_tactil(false, false), "fisica desactivada bloquea movimiento")
	_comprobar(not CAMINANTE.debe_procesar_movimiento_tactil(true, true), "pausa bloquea movimiento")


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if condicion:
		return
	_fallos += 1
	push_error("FALLO #2290 TACTIL: " + mensaje)
