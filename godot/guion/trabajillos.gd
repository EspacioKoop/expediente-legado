## Trabajillos de casa (#94).
##
## No son otra profesión ni otra economía: un lote pequeño, una vez por noche,
## que compra algo de margen a cambio de descanso. El estado vive dentro de la
## jornada para que guardar/cargar no pueda repetir el cobro.
class_name Trabajillos
extends RefCounted

const PAGO_TRANSCRIPCION := 20
const ESCENAS_SUENO_PERDIDAS := 1


static func _estado(jornada: Dictionary) -> Dictionary:
	if not jornada.has("trabajillos") or typeof(jornada["trabajillos"]) != TYPE_DICTIONARY:
		jornada["trabajillos"] = {"ultimo_dia": 0, "hechos": 0}
	var estado: Dictionary = jornada["trabajillos"]
	estado["ultimo_dia"] = int(estado.get("ultimo_dia", 0))
	estado["hechos"] = int(estado.get("hechos", 0))
	return estado


static func disponible(jornada: Dictionary) -> bool:
	if jornada.get("fase", "") != "casa":
		return false
	return int(_estado(jornada)["ultimo_dia"]) != int(jornada.get("dia", 1))


static func hacer_transcripcion(jornada: Dictionary) -> Dictionary:
	if not disponible(jornada):
		return {}
	var estado := _estado(jornada)
	var dia := int(jornada.get("dia", 1))
	estado["ultimo_dia"] = dia
	estado["hechos"] += 1
	jornada["dinero"] = int(jornada.get("dinero", 0)) + PAGO_TRANSCRIPCION
	return {
		"dia": dia,
		"importe": PAGO_TRANSCRIPCION,
		"dinero": jornada["dinero"],
		"hechos": estado["hechos"],
	}


static func hecho_hoy(jornada: Dictionary) -> bool:
	return int(_estado(jornada)["ultimo_dia"]) == int(jornada.get("dia", 1))


static func escenas_de_sueno(jornada: Dictionary, cantidad_normal: int) -> int:
	if not hecho_hoy(jornada):
		return cantidad_normal
	return maxi(1, cantidad_normal - ESCENAS_SUENO_PERDIDAS)
