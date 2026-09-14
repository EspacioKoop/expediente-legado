## Contrato de maduración narrativa para las decisiones políticas (#287).
##
## Al aparecer una carta se congela el contexto que el jugador ya conocía. La
## decisión madura cuando después aparece información real nueva: otro documento
## leído o una pista/conclusión descubierta. No hay temporizador ni umbral
## numérico arbitrario, y una partida antigua sin instantánea no queda bloqueada.
extends RefCounted

const CLAVE := "historias_contexto"


static func registrar(estado: Dictionary, carta_id: String) -> bool:
	if carta_id.is_empty() or tiene_registro(estado, carta_id):
		return false
	var registros := _registros(estado)
	registros[carta_id] = {
		"leidos": _leidos(estado),
		"pistas": _pistas(estado),
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
