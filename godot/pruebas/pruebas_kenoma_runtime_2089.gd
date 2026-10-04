## Regresión del Eco del Kenoma (#2089 / #2401).
extends SceneTree

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")
const RUNTIME = preload("res://guion/juicio_combate_kenoma_runtime_2089.gd")

var _pasadas := 0
var _fallos := 0


func _init() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	_probar_limite_y_determinismo()
	_probar_spawn_y_repeticion_diferida()
	_probar_reduccion_solo_presentacion()
	_probar_destruccion_sin_crecimiento()
	print("pruebas_kenoma_runtime_2089: %d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos > 0 else 0)


func _probar_limite_y_determinismo() -> void:
	var a := RUNTIME.nuevo(2089, 99)
	var b := RUNTIME.nuevo(2089, 99)
	var ecos: Array = a.get("ecos", [])
	_comprobar(ecos.size() == RUNTIME.LIMITE_ECOS, "respeta el límite duro")
	_comprobar(a == b, "misma seed y cantidad producen el mismo estado")
	for indice in range(ecos.size()):
		var eco: Dictionary = ecos[indice]
		_comprobar(int(eco.get("indice", -1)) == indice, "índice estable %d" % indice)
		var unidad: Dictionary = eco.get("unidad", {})
		_comprobar(String(unidad.get("tipo", "")) == ARQUETIPOS.MIMETICO, "cada eco es MIMÉTICO")


func _probar_spawn_y_repeticion_diferida() -> void:
	var estado := RUNTIME.nuevo(77, 2)
	var original := estado.duplicate(true)
	var primero := RUNTIME.avanzar(estado, 0.0, "linea")
	_comprobar(estado == original, "avanzar no muta el estado de entrada")
	_comprobar(primero.get("solicitudes_spawn", []) == [0, 1], "spawn inicial aparece una sola vez")
	_comprobar(
		primero.get("ventana_respuesta", []).is_empty(), "el señuelo inicial no abre ventana"
	)
	_comprobar(_patrones(primero) == ["linea", "linea"], "ambos ecos recuerdan el patrón observado")

	var segundo := RUNTIME.avanzar(primero["estado"], 1.0, "carga_lineal")
	_comprobar(segundo.get("solicitudes_spawn", []).is_empty(), "el spawn no se repite")
	_comprobar(
		_patrones(segundo) == ["linea", "linea"], "un patrón nuevo no sustituye al pendiente"
	)
	_comprobar(
		_telegraphs(segundo) == ["linea", "linea"], "la repetición anuncia el patrón copiado"
	)

	var tercero := RUNTIME.avanzar(segundo["estado"], 1.0, "zona")
	_comprobar(_patrones(tercero) == ["linea", "linea"], "mantiene el patrón hasta cerrar el ciclo")
	_comprobar(tercero.get("ventana_respuesta", []) == [0, 1], "la recuperación abre ventana")
	_comprobar(_telegraphs(tercero) == ["vulnerable", "vulnerable"], "la ventana es legible")


func _probar_reduccion_solo_presentacion() -> void:
	var estado := RUNTIME.nuevo(91, 2)
	var normal := RUNTIME.avanzar(estado, 0.0, "carga_lineal", [], false)
	var reducido := RUNTIME.avanzar(estado, 0.0, "carga_lineal", [], true)
	for clave in [
		"estado",
		"patron_copiado",
		"ventana_respuesta",
		"solicitudes_spawn",
		"solicitudes_despawn",
	]:
		_comprobar(normal.get(clave) == reducido.get(clave), "reducción no cambia " + clave)
	_comprobar(
		_telegraphs(normal) == _telegraphs(reducido),
		"reducción conserva el telegraph mecánico",
	)


func _probar_destruccion_sin_crecimiento() -> void:
	var inicial := RUNTIME.avanzar(RUNTIME.nuevo(101, 3), 0.0, "")
	var estado: Dictionary = inicial["estado"]
	_comprobar(inicial.get("solicitudes_spawn", []) == [0, 1, 2], "consume el spawn inicial")

	var uno := RUNTIME.avanzar(estado, 0.0, "", [1, 1, -1])
	_comprobar(
		uno.get("solicitudes_despawn", []) == [1], "destruir duplicado genera un solo despawn"
	)
	_comprobar(uno.get("solicitudes_spawn", []).is_empty(), "destruir no genera spawn")
	_comprobar((uno["estado"]["ecos"] as Array).size() == 2, "queda exactamente un eco menos")

	var repetido := RUNTIME.avanzar(uno["estado"], 0.0, "", [1])
	_comprobar(
		repetido.get("solicitudes_despawn", []).is_empty(), "destruir de nuevo es idempotente"
	)
	_comprobar((repetido["estado"]["ecos"] as Array).size() == 2, "no reaparece el eco destruido")

	var todos := RUNTIME.avanzar(repetido["estado"], 0.0, "", [0, 2, 0])
	_comprobar(todos.get("solicitudes_despawn", []) == [0, 2], "los restantes desaparecen una vez")
	_comprobar((todos["estado"]["ecos"] as Array).is_empty(), "la arena converge a cero ecos")
	_comprobar(todos.get("solicitudes_spawn", []).is_empty(), "cero ecos no provoca crecimiento")
	for prohibido in ["dano", "partida", "jornada"]:
		_comprobar(not todos.has(prohibido), "la salida no crea autoridad " + prohibido)


func _patrones(salida: Dictionary) -> Array:
	var patrones: Array = []
	for item in salida.get("patron_copiado", []):
		patrones.append(String((item as Dictionary).get("patron", "")))
	return patrones


func _telegraphs(salida: Dictionary) -> Array:
	var patrones: Array = []
	for item in salida.get("telegraph", []):
		patrones.append(String((item as Dictionary).get("patron", "")))
	return patrones


func _comprobar(condicion: bool, mensaje: String) -> void:
	_pasadas += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO #2401 Kenoma: " + mensaje)
