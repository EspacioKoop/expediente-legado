## Contrato de maduración narrativa para las decisiones políticas (#287).
##
## Al aparecer una carta se congela el contexto que el jugador ya conocía. La
## decisión madura cuando después aparece contexto real nuevo: otro documento,
## una pista/conclusión, un expediente cerrado o el avance de la jornada. No hay
## temporizador ni umbral numérico arbitrario, y una partida antigua sin
## instantánea no queda bloqueada.
extends RefCounted

const CLAVE := "historias_contexto"


static func registrar(estado: Dictionary, carta_id: String) -> bool:
	if carta_id.is_empty() or tiene_registro(estado, carta_id):
		return false
	var registros := _registros(estado)
	registros[carta_id] = {
		"leidos": _leidos(estado),
		"pistas": _pistas(estado),
		"veredictos": _veredictos(estado),
		"dia": _dia(estado),
		"fase": _fase(estado),
	}
	estado[CLAVE] = registros
	return true


static func tiene_registro(estado: Dictionary, carta_id: String) -> bool:
	return _registros(estado).has(carta_id)


static func maduro(estado: Dictionary, carta_id: String) -> bool:
	var registros := _registros(estado)
	# Compatibilidad: una historia pospuesta antes de existir este contrato no
	# debe exigir una lectura artificial solo por actualizar la versión.
	if not registros.has(carta_id):
		return true
	var anterior: Variant = registros[carta_id]
	if typeof(anterior) != TYPE_DICTIONARY:
		return true
	var contexto: Dictionary = anterior
	return (
		_hay_nuevo(_leidos(estado), contexto.get("leidos", []))
		or _hay_nuevo(_pistas(estado), contexto.get("pistas", []))
		# Los snapshots previos a esta ampliación no guardaban veredictos,
		# día ni fase. Esas dimensiones solo cuentan si ya existían al congelar
		# el contexto, evitando desbloqueos retroactivos al actualizar.
		or (
			contexto.has("veredictos")
			and _hay_nuevo(_veredictos(estado), contexto.get("veredictos", []))
		)
		or _jornada_avanzada(estado, contexto)
	)


static func _registros(estado: Dictionary) -> Dictionary:
	var valor: Variant = estado.get(CLAVE, {})
	return valor.duplicate(true) if typeof(valor) == TYPE_DICTIONARY else {}


static func _leidos(estado: Dictionary) -> Array:
	var jornada: Variant = estado.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return []
	return _ids(jornada.get("leidos_total", []))


static func _pistas(estado: Dictionary) -> Array:
	return _ids(estado.get("pistas_descubiertas", []))


static func _veredictos(estado: Dictionary) -> Array:
	var valor: Variant = estado.get("veredictos", {})
	if typeof(valor) != TYPE_DICTIONARY:
		return []
	var veredictos: Dictionary = valor
	return _ids(veredictos.keys())


static func _dia(estado: Dictionary) -> int:
	var jornada: Variant = estado.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return 1
	return int(jornada.get("dia", 1))


static func _fase(estado: Dictionary) -> String:
	var jornada: Variant = estado.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return ""
	return String(jornada.get("fase", ""))


static func _jornada_avanzada(estado: Dictionary, contexto: Dictionary) -> bool:
	if not contexto.has("dia") and not contexto.has("fase"):
		return false
	if contexto.has("dia") and _dia(estado) != int(contexto.get("dia", _dia(estado))):
		return true
	if contexto.has("fase"):
		var fase_anterior := String(contexto.get("fase", ""))
		var fase_actual := _fase(estado)
		if fase_anterior == "archivo" and fase_actual != "archivo":
			return true
	return false


static func _ids(valor: Variant) -> Array:
	var salida: Array = []
	if typeof(valor) != TYPE_ARRAY:
		return salida
	for item in valor:
		var identificador := String(item)
		if not identificador.is_empty() and not salida.has(identificador):
			salida.append(identificador)
	salida.sort()
	return salida


static func _hay_nuevo(actuales: Array, anteriores: Variant) -> bool:
	var base := _ids(anteriores)
	for identificador in actuales:
		if not base.has(identificador):
			return true
	return false
