## Regresión del Eco del Kenoma (#2089 / #2401 / #2394).
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
	_probar_cantidades_extremas()
	_probar_ciclo_por_patron()
	_probar_secuencia_larga()
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


func _probar_cantidades_extremas() -> void:
	for cantidad in [-99, 0, 1, 2, 3, 99]:
		var estado := RUNTIME.nuevo(2394, cantidad)
		var salida := RUNTIME.avanzar(estado, 0.0, "linea")
		var esperados := clampi(cantidad, 0, 3)
		_comprobar(estado["ecos"].size() == esperados, "acota cantidad %d" % cantidad)
		_comprobar(
			salida["solicitudes_spawn"].size() == esperados,
			"solo solicita ecos existentes %d" % cantidad,
		)
		_comprobar(
			salida["estado"]["ecos"].size() == esperados,
			"el primer avance respeta cantidad %d" % cantidad,
		)


func _probar_ciclo_por_patron() -> void:
	for patron in ["linea", "carga_lineal", "ataque_corto", "zona"]:
		var observado := RUNTIME.avanzar(RUNTIME.nuevo(2394, 1), 0.0, patron)
		_comprobar(_fase(observado) == ARQUETIPOS.TELEGRAFIAR_ECO, "anuncia antes de repetir")
		var anuncio := RUNTIME.avanzar(
			observado["estado"], ARQUETIPOS.MIMETICO_TELEGRAFO / 2.0, "zona"
		)
		_comprobar(_fase(anuncio) == ARQUETIPOS.TELEGRAFIAR_ECO, "respeta retraso del anuncio")
		_comprobar(_patrones(anuncio) == [patron], "retiene el patrón durante el anuncio")
		var repetido := RUNTIME.avanzar(
			anuncio["estado"], ARQUETIPOS.MIMETICO_TELEGRAFO, "ataque_corto"
		)
		_comprobar(_fase(repetido) == ARQUETIPOS.REPETIR, "repite después del anuncio")
		_comprobar(_telegraphs(repetido) == [patron], "expone el patrón repetido")
		_comprobar(repetido["ventana_respuesta"].is_empty(), "repetir no abre recuperación")
		var ventana := RUNTIME.avanzar(repetido["estado"], ARQUETIPOS.MIMETICO_REPETICION, "linea")
		_comprobar(_fase(ventana) == ARQUETIPOS.RECUPERAR, "la repetición termina en recuperación")
		_comprobar(ventana["ventana_respuesta"] == [0], "la recuperación abre respuesta")
		var libre := RUNTIME.avanzar(ventana["estado"], ARQUETIPOS.MIMETICO_RECUPERACION, "zona")
		_comprobar(_fase(libre) == ARQUETIPOS.OBSERVAR, "vuelve a observar tras recuperarse")
		_comprobar(_patrones(libre) == [""], "descarta el patrón anterior al terminar")
		var siguiente := RUNTIME.avanzar(libre["estado"], 0.0, "carga_lineal")
		_comprobar(_patrones(siguiente) == ["carga_lineal"], "acepta un nuevo patrón en otro ciclo")


func _probar_secuencia_larga() -> void:
	var estado := RUNTIME.nuevo(2394, 3)
	for paso in range(64):
		var destruidos: Array = []
		if paso in [8, 16, 24]:
			var indice: int = {8: 1, 16: 0, 24: 2}[paso]
			destruidos = [indice, indice, -1, 99]
		var original := estado.duplicate(true)
		var indices_originales := destruidos.duplicate()
		var patron: String = ["linea", "zona", "carga_lineal", "ataque_corto"][paso % 4]
		var normal := RUNTIME.avanzar(estado, 0.1, patron, destruidos, false)
		var repetido := RUNTIME.avanzar(estado, 0.1, patron, destruidos, false)
		var reducido := RUNTIME.avanzar(estado, 0.1, patron, destruidos, true)
		_comprobar(normal == repetido, "misma entrada produce misma salida en tick %d" % paso)
		_comprobar(estado == original, "no muta estado en tick %d" % paso)
		_comprobar(destruidos == indices_originales, "no muta índices destruidos")
		for clave in [
			"estado",
			"patron_copiado",
			"ventana_respuesta",
			"solicitudes_spawn",
			"solicitudes_despawn"
		]:
			_comprobar(normal[clave] == reducido[clave], "reducción conserva " + clave)
		_comprobar(_telegraphs(normal) == _telegraphs(reducido), "reducción conserva telegraph")
		_comprobar(normal["estado"]["ecos"].size() <= 3, "límite duro durante toda la secuencia")
		if paso > 0:
			_comprobar(
				normal["solicitudes_spawn"].is_empty(), "no reaparecen ecos tras spawn inicial"
			)
		if paso >= 24:
			_comprobar(normal["estado"]["ecos"].is_empty(), "cero ecos es estable")
		estado = normal["estado"]


func _fase(salida: Dictionary) -> String:
	return String(salida["estado"]["ecos"][0]["unidad"]["estado"])


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
