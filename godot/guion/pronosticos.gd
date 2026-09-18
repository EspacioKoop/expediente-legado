class_name Pronosticos
extends RefCounted

const ESTADO_ABIERTO := "abierto"
const ESTADO_ABANDONADO := "abandonado"
const ESTADO_ACERTADO := "acertado"
const ESTADO_FALLADO := "fallado"
const ESTADO_SIN_RESOLVER := "sin_resolver"
const ESTADOS := [
	ESTADO_ABIERTO,
	ESTADO_ABANDONADO,
	ESTADO_ACERTADO,
	ESTADO_FALLADO,
	ESTADO_SIN_RESOLVER,
]


static func nuevo() -> Dictionary:
	return {"por_expediente": {}}


static func completar(estado: Dictionary) -> Dictionary:
	if not estado.has("por_expediente") or typeof(estado["por_expediente"]) != TYPE_DICTIONARY:
		estado["por_expediente"] = {}
	return estado


static func validar(estado) -> Array:
	var errores := []
	if typeof(estado) != TYPE_DICTIONARY:
		return ["no es un objeto"]
	if not estado.has("por_expediente"):
		return errores
	if typeof(estado["por_expediente"]) != TYPE_DICTIONARY:
		return ["por_expediente no es un objeto"]

	for expediente_id in estado["por_expediente"]:
		var id := String(expediente_id).strip_edges()
		if id.is_empty():
			errores.append("expediente con id vacío")
			continue
		var pronostico = estado["por_expediente"][expediente_id]
		if typeof(pronostico) != TYPE_DICTIONARY:
			errores.append("%s no es un objeto" % id)
			continue
		if (
			typeof(pronostico.get("tipo")) != TYPE_STRING
			or String(pronostico.get("tipo", "")).strip_edges().is_empty()
		):
			errores.append("%s.tipo inválido" % id)
		if not pronostico.has("valor") or pronostico["valor"] == null:
			errores.append("%s.valor ausente" % id)
		var estado_actual = pronostico.get("estado", "")
		if typeof(estado_actual) != TYPE_STRING or not ESTADOS.has(estado_actual):
			errores.append("%s.estado inválido" % id)
	return errores


static func crear(
	estado: Dictionary, expediente_id: String, tipo: String, valor, expuesto: bool = false
) -> bool:
	completar(estado)
	if expediente_id.is_empty() or tipo.is_empty() or expuesto:
		return false
	if estado["por_expediente"].has(expediente_id):
		return false
	estado["por_expediente"][expediente_id] = {
		"tipo": tipo,
		"valor": valor,
		"estado": ESTADO_ABIERTO,
	}
	return true


static func abandonar(estado: Dictionary, expediente_id: String) -> bool:
	var pronostico := _obtener(estado, expediente_id)
	if pronostico.is_empty() or pronostico.get("estado", "") != ESTADO_ABIERTO:
		return false
	pronostico["estado"] = ESTADO_ABANDONADO
	return true


static func resolver(estado: Dictionary, expediente_id: String, resultado) -> String:
	var pronostico := _obtener(estado, expediente_id)
	if pronostico.is_empty():
		return ESTADO_SIN_RESOLVER
	if pronostico.get("estado", "") == ESTADO_ABANDONADO:
		return ESTADO_SIN_RESOLVER
	if pronostico.get("estado", "") != ESTADO_ABIERTO:
		return String(pronostico.get("estado", ESTADO_SIN_RESOLVER))
	if resultado == null:
		pronostico["estado"] = ESTADO_SIN_RESOLVER
	elif pronostico["valor"] == resultado:
		pronostico["estado"] = ESTADO_ACERTADO
	else:
		pronostico["estado"] = ESTADO_FALLADO
	return String(pronostico["estado"])


static func estado_de(estado: Dictionary, expediente_id: String) -> String:
	var pronostico := _obtener(estado, expediente_id)
	return (
		ESTADO_SIN_RESOLVER
		if pronostico.is_empty()
		else String(pronostico.get("estado", ESTADO_SIN_RESOLVER))
	)


static func historial(estado: Dictionary) -> Array:
	completar(estado)
	var filas := []
	for expediente_id in estado["por_expediente"]:
		var fila: Dictionary = estado["por_expediente"][expediente_id].duplicate(true)
		fila["expediente"] = expediente_id
		filas.append(fila)
	filas.sort_custom(func(a, b): return String(a["expediente"]) < String(b["expediente"]))
	return filas


static func _obtener(estado: Dictionary, expediente_id: String) -> Dictionary:
	completar(estado)
	var valor = estado["por_expediente"].get(expediente_id, {})
	return valor if typeof(valor) == TYPE_DICTIONARY else {}
