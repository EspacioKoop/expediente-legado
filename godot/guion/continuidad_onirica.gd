## Continuidad entre sueños: lucidez local y motivos que se filtran de un sueño a otro (#2433).
##
## Deliberadamente PURO: no escribe en Partida/Jornada y no decide escenas.
## Quien monta un sueño declara qué acciones lúcidas admite y qué motivos de
## otros sueños acepta. La salida es metadata de presentación que puede ignorarse.
class_name ContinuidadOnirica
extends RefCounted

const LUCIDEZ_BAJA := 1
const LUCIDEZ_ALTA := 2
const MAX_MOTIVOS_PRIMER_CORTE := 1


static func accion_lucida(nivel: int, contrato: Dictionary) -> Dictionary:
	var normalizado := clampi(nivel, 0, LUCIDEZ_ALTA)
	var crudo: Variant = contrato.get("acciones_lucidas", [])
	if not crudo is Array:
		return {}

	var candidatas: Array[Dictionary] = []
	for valor in crudo as Array:
		if not valor is Dictionary:
			continue
		var accion: Dictionary = valor
		var id := String(accion.get("id", "")).strip_edges()
		var minimo := clampi(
			int(accion.get("nivel_minimo", LUCIDEZ_BAJA)), LUCIDEZ_BAJA, LUCIDEZ_ALTA
		)
		if id.is_empty() or minimo > normalizado:
			continue
		var copia := accion.duplicate(true)
		copia["id"] = id
		copia["nivel_minimo"] = minimo
		copia["afecta_estado_global"] = false
		candidatas.append(copia)

	if candidatas.is_empty():
		return {}
	candidatas.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var nivel_a := int(a["nivel_minimo"])
			var nivel_b := int(b["nivel_minimo"])
			if nivel_a != nivel_b:
				return nivel_a > nivel_b
			return String(a["id"]) < String(b["id"])
	)
	return candidatas[0]


static func seleccionar_motivos(
	motivos: Array,
	destino: String,
	raiz: int,
	permitidos: Array[String] = [],
	cantidad_maxima: int = MAX_MOTIVOS_PRIMER_CORTE
) -> Array[Dictionary]:
	var destino_limpio := destino.strip_edges()
	if destino_limpio.is_empty() or cantidad_maxima <= 0:
		return []

	var candidatas: Array[Dictionary] = []
	var ids_vistos: Array[String] = []
	for valor in motivos:
		if not valor is Dictionary:
			continue
		var motivo: Dictionary = valor
		var id := String(motivo.get("id", "")).strip_edges()
		var origen := String(motivo.get("origen", "")).strip_edges()
		if id.is_empty() or origen.is_empty() or origen == destino_limpio:
			continue
		if ids_vistos.has(id):
			continue
		if not permitidos.is_empty() and not permitidos.has(id):
			continue

		var destinos_crudos: Variant = motivo.get("destinos", [])
		if destinos_crudos is Array and not (destinos_crudos as Array).is_empty():
			if not (destinos_crudos as Array).has(destino_limpio):
				continue

		var copia := motivo.duplicate(true)
		copia["id"] = id
		copia["origen"] = origen
		copia["afecta_navegacion"] = false
		copia["afecta_objetivo"] = false
		candidatas.append(copia)
		ids_vistos.append(id)

	if candidatas.is_empty():
		return []

	candidatas.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"])
	)
	var firma_ids: Array[String] = []
	for candidata in candidatas:
		firma_ids.append(String(candidata["id"]))

	var rng := RandomNumberGenerator.new()
	rng.seed = Azar.derivar_texto(
		raiz, "sueno", "contaminacion|%s|%s" % [destino_limpio, ",".join(firma_ids)], [2433]
	)
	_barajar(candidatas, rng)
	return candidatas.slice(0, mini(cantidad_maxima, candidatas.size()))


static func aplicar(espacio: Dictionary, seleccion: Array[Dictionary]) -> Dictionary:
	var resultado := espacio.duplicate(true)
	if seleccion.is_empty():
		return resultado
	var presentacion: Array[Dictionary] = []
	for motivo in seleccion:
		presentacion.append(
			{
				"id": String(motivo.get("id", "")),
				"origen": String(motivo.get("origen", "")),
				"presentacion": motivo.get("presentacion", {}).duplicate(true),
				"afecta_navegacion": false,
				"afecta_objetivo": false,
			}
		)
	resultado["contaminacion_onirica"] = presentacion
	return resultado


static func _barajar(lista: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado := lista[i]
		lista[i] = lista[j]
		lista[j] = guardado
