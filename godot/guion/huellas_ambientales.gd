## Estado persistente de las huellas ambientales (#959).
##
## Esta capa no pinta nada y no conoce escenas. Recibe el estado de Partida y
## conserva únicamente ids estables + intensidad derivada de usos deliberados.
## Así una huella sobrevive a recarga sin serializar nodos ni coordenadas.
class_name HuellasAmbientales
extends RefCounted

const CLAVE := "huellas_ambientales"
const TIPOS := ["uso", "apertura", "roce", "lectura", "paso"]
const MAX_HUELLAS := 64
const USOS_MAX := 8
const INTENSIDAD_BASE := 0.14
const PASO_INTENSIDAD := 0.055
const INTENSIDAD_MAX := 0.525


static func completar(estado_partida: Dictionary) -> Dictionary:
	var huellas = estado_partida.get(CLAVE, {})
	if typeof(huellas) != TYPE_DICTIONARY:
		huellas = {}
		estado_partida[CLAVE] = huellas
	return huellas


static func registrar(
	estado_partida: Dictionary,
	id: String,
	tipo: String,
	fase: String,
) -> Dictionary:
	var huella_id := id.strip_edges()
	if huella_id.is_empty():
		return {}
	var huellas := completar(estado_partida)
	if not huellas.has(huella_id) and huellas.size() >= MAX_HUELLAS:
		return {}

	var anterior = huellas.get(huella_id, {})
	var usos := 0
	if typeof(anterior) == TYPE_DICTIONARY:
		usos = int(anterior.get("usos", 0))
	usos = mini(USOS_MAX, usos + 1)
	var tipo_seguro := tipo if TIPOS.has(tipo) else "uso"
	var intensidad := minf(INTENSIDAD_MAX, INTENSIDAD_BASE + PASO_INTENSIDAD * float(usos - 1))
	var huella := {
		"tipo": tipo_seguro,
		"fase": fase,
		"usos": usos,
		"intensidad": intensidad,
	}
	huellas[huella_id] = huella
	return huella.duplicate(true)


static func de_fase(estado_partida: Dictionary, fase: String) -> Array:
	var salida := []
	var huellas := completar(estado_partida)
	for id in huellas:
		var entrada = huellas[id]
		if typeof(entrada) != TYPE_DICTIONARY or String(entrada.get("fase", "")) != fase:
			continue
		var copia: Dictionary = entrada.duplicate(true)
		copia["id"] = String(id)
		salida.append(copia)
	salida.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
	return salida


static func intensidad_de(estado_partida: Dictionary, id: String) -> float:
	var huellas := completar(estado_partida)
	var entrada = huellas.get(id, {})
	if typeof(entrada) != TYPE_DICTIONARY:
		return 0.0
	return clampf(float(entrada.get("intensidad", 0.0)), 0.0, INTENSIDAD_MAX)


static func validar(huellas) -> Array:
	var errores := []
	if typeof(huellas) != TYPE_DICTIONARY:
		return ["no es un objeto"]
	if huellas.size() > MAX_HUELLAS:
		errores.append("supera el máximo de %d" % MAX_HUELLAS)
	for clave in huellas:
		var id := String(clave).strip_edges()
		if id.is_empty():
			errores.append("contiene id vacío")
			continue
		var entrada = huellas[clave]
		if typeof(entrada) != TYPE_DICTIONARY:
			errores.append("%s no es un objeto" % id)
			continue
		var tipo = entrada.get("tipo", "")
		if typeof(tipo) != TYPE_STRING or not TIPOS.has(String(tipo)):
			errores.append("%s.tipo inválido" % id)
		var fase = entrada.get("fase", "")
		if typeof(fase) != TYPE_STRING or not Jornada.FASES.has(String(fase)):
			errores.append("%s.fase inválida" % id)
		var usos = entrada.get("usos", 0)
		if not _entero_en_rango(usos, 1, USOS_MAX):
			errores.append("%s.usos inválido" % id)
		var intensidad = entrada.get("intensidad", -1.0)
		if (
			typeof(intensidad) not in [TYPE_INT, TYPE_FLOAT]
			or not is_finite(float(intensidad))
			or float(intensidad) < 0.0
			or float(intensidad) > INTENSIDAD_MAX
		):
			errores.append("%s.intensidad inválida" % id)
	return errores


static func _entero_en_rango(valor, minimo: int, maximo: int) -> bool:
	if typeof(valor) == TYPE_INT:
		return valor >= minimo and valor <= maximo
	if typeof(valor) != TYPE_FLOAT or not is_finite(valor):
		return false
	return floor(valor) == valor and valor >= minimo and valor <= maximo
