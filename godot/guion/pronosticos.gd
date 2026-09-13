class_name Pronosticos
extends RefCounted

const ESTADO_ABIERTO := "abierto"
const ESTADO_ABANDONADO := "abandonado"
const ESTADO_ACERTADO := "acertado"
const ESTADO_FALLADO := "fallado"
const ESTADO_SIN_RESOLVER := "sin_resolver"


static func nuevo() -> Dictionary:
	return {"por_expediente": {}}


static func completar(estado: Dictionary) -> Dictionary:
	if not estado.has("por_expediente") or typeof(estado["por_expediente"]) != TYPE_DICTIONARY:
		estado["por_expediente"] = {}
	return estado


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
	if pronostico.is_empty() or pronostico["estado"] != ESTADO_ABIERTO:
		return false
	pronostico["estado"] = ESTADO_ABANDONADO
	return true


static func resolver(estado: Dictionary, expediente_id: String, resultado) -> String:
	var pronostico := _obtener(estado, expediente_id)
	if pronostico.is_empty():
		return ESTADO_SIN_RESOLVER
	if pronostico["estado"] == ESTADO_ABANDONADO:
		return ESTADO_SIN_RESOLVER
	if pronostico["estado"] != ESTADO_ABIERTO:
		return String(pronostico["estado"])
	if resultado == null:
		pronostico["estado"] = ESTADO_SIN_RESOLVER
	elif pronostico["valor"] == resultado:
		pronostico["estado"] = ESTADO_ACERTADO
	else:
		pronostico["estado"] = ESTADO_FALLADO
	return String(pronostico["estado"])


static func estado_de(estado: Dictionary, expediente_id: String) -> String:
	var pronostico := _obtener(estado, expediente_id)
	return ESTADO_SIN_RESOLVER if pronostico.is_empty() else String(pronostico["estado"])


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
