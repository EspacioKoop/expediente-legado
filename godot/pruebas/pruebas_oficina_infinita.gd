extends SceneTree

const OficinaInfinita := preload("res://guion/oficina_infinita.gd")

var _pasadas = 0
var _fallos = 0


func _initialize() -> void:
	_probar_determinismo()
	_probar_mutacion_segura()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_determinismo() -> void:
	var jornada = {"dia": 5, "vuelta": 2}
	var raiz = 12345
	var sel1 = OficinaInfinita.seleccionar(jornada, raiz)
	var sel2 = OficinaInfinita.seleccionar(jornada, raiz)
	_comprobar(sel1 == sel2, "selección determinista idéntica")
	_comprobar(sel1.has("id"), "selección contiene id")


func _probar_mutacion_segura() -> void:
	var espacio_original = {"bloques": []}
	var mutador = {"id": OficinaInfinita.HUMEDAD}
	var result = OficinaInfinita.aplicar(espacio_original, mutador, false)
	_comprobar(result != espacio_original, "aplicar devuelve copia")
	_comprobar(result.has("mutador_nocturno"), "copia contiene mutador_nocturno")
	# mutador inválido
	var mutador_invalid = {"id": "NO_EXISTENT"}
	var result_invalid = OficinaInfinita.aplicar(espacio_original, mutador_invalid, false)
	_comprobar(result_invalid == espacio_original, "mutador inválido no cambia espacio")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO OficinaInfinita: " + nombre)
