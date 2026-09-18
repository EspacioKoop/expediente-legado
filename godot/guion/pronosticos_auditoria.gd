## Cuarto corte de #153: resolver apuestas desde hechos ya decididos por el juego.
##
## Esta capa no concede premios ni cambia ninguna regla. Solo traduce el
## resultado real de una firma o del fin de jornada al valor que Pronosticos
## compara con la apuesta registrada.
class_name PronosticosAuditoria
extends RefCounted


static func resolver_cierre(estado: Dictionary, caso: Dictionary, acusacion: Dictionary) -> String:
	var pronosticos: Dictionary = estado.get("pronosticos", {})
	Pronosticos.completar(pronosticos)
	estado["pronosticos"] = pronosticos

	var expediente_id := String(caso.get("id", ""))
	var actual := _actual(pronosticos, expediente_id)
	if actual.is_empty() or String(actual.get("estado", "")) != Pronosticos.ESTADO_ABIERTO:
		return Pronosticos.estado_de(pronosticos, expediente_id)
	if String(acusacion.get("resultado", "")) != "cerrado":
		return Pronosticos.estado_de(pronosticos, expediente_id)

	var resultado: Variant = null
	match String(actual.get("tipo", "")):
		"habra_duelo":
			var duelo: Variant = acusacion.get("duelo", {})
			resultado = typeof(duelo) == TYPE_DICTIONARY and not duelo.is_empty()
		"acusacion_precipitada":
			resultado = bool(acusacion.get("precipitada", false))
		"cierre_hoy":
			resultado = true
		"arrastra_manana":
			resultado = false
		"documento_clave":
			resultado = tipo_documento_clave(caso, estado.get("pistas_descubiertas", []))
		_:
			resultado = null
	return Pronosticos.resolver(pronosticos, expediente_id, resultado)


## Al abandonar la oficina ya no puede ocurrir ningún cierre más ese día.
## Solo se resuelven aquí las dos apuestas cuyo hecho definitivo es el cambio
## de jornada; careo, precipitación y documento clave esperan a una firma real.
static func resolver_fin_jornada(estado: Dictionary) -> int:
	var pronosticos: Dictionary = estado.get("pronosticos", {})
	Pronosticos.completar(pronosticos)
	estado["pronosticos"] = pronosticos
	var resueltos := 0

	for expediente_id in pronosticos["por_expediente"]:
		var actual := _actual(pronosticos, String(expediente_id))
		if actual.is_empty() or String(actual.get("estado", "")) != Pronosticos.ESTADO_ABIERTO:
			continue
		var cerrado := Acusacion.esta_cerrado(estado, String(expediente_id))
		match String(actual.get("tipo", "")):
			"cierre_hoy":
				Pronosticos.resolver(pronosticos, String(expediente_id), cerrado)
				resueltos += 1
			"arrastra_manana":
				Pronosticos.resolver(pronosticos, String(expediente_id), not cerrado)
				resueltos += 1
	return resueltos


## "Documento clave" no inventa una verdad editorial: observa qué tipos de
## registro originaron más pistas que el jugador llegó a descubrir. Cada pista
## cuenta como mucho una vez por tipo aunque relacione dos documentos iguales.
## Sin evidencia o con empate no hay un ganador justificable.
static func tipo_documento_clave(caso: Dictionary, descubiertas: Array) -> Variant:
	var tipos_por_registro := {}
	for registro in caso.get("registros", []):
		var registro_id := String(registro.get("id", ""))
		var tipo := String(registro.get("tipo", "")).strip_edges()
		if not registro_id.is_empty() and not tipo.is_empty():
			tipos_por_registro[registro_id] = tipo

	var puntos := {}
	for pista in caso.get("pistas", []):
		if not descubiertas.has(pista.get("id", "")):
			continue
		var tipos_pista: Array[String] = []
		for clave in pista:
			var nombre := String(clave)
			if not nombre.begins_with("registroOrigen"):
				continue
			var registro_id := String(pista.get(clave, ""))
			if not tipos_por_registro.has(registro_id):
				continue
			var tipo := String(tipos_por_registro[registro_id])
			if not tipos_pista.has(tipo):
				tipos_pista.append(tipo)
		for tipo in tipos_pista:
			puntos[tipo] = int(puntos.get(tipo, 0)) + 1

	if puntos.is_empty():
		return null

	var mejor := ""
	var maximo := -1
	var empate := false
	for tipo in puntos:
		var cantidad := int(puntos[tipo])
		if cantidad > maximo:
			mejor = String(tipo)
			maximo = cantidad
			empate = false
		elif cantidad == maximo:
			empate = true
	return null if empate else mejor


static func _actual(pronosticos: Dictionary, expediente_id: String) -> Dictionary:
	var actual: Variant = pronosticos.get("por_expediente", {}).get(expediente_id, {})
	return actual if typeof(actual) == TYPE_DICTIONARY else {}
