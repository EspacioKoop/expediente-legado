## Persistencia mínima de un puzzle onírico durante la noche (#89).
##
## Vive dentro de Jornada para aprovechar el guardado canónico de Partida sin
## crear un archivo paralelo. La entrada lleva día y tipo: un guardado viejo o
## de otra noche jamás puede bloquear ni alimentar la actual.
class_name SuenoPuzzleSesion
extends RefCounted

const CLAVE := "puzzle_onirico_actual"
const TIPO_ECOS := "ecos"
const TIPO_RELACION := "relacion"
const TIPOS := [TIPO_ECOS, TIPO_RELACION]


static func registrada_esta_noche(jornada: Dictionary) -> bool:
	if String(jornada.get("fase", "")) != "sueño" or not jornada.has(CLAVE):
		return false
	var valor: Variant = jornada.get(CLAVE)
	if not valor is Dictionary or not valor.has("dia"):
		return true
	return int(valor.get("dia", -1)) == int(jornada.get("dia", 0))


static func actual(jornada: Dictionary) -> Dictionary:
	if String(jornada.get("fase", "")) != "sueño":
		return {}
	var valor: Variant = jornada.get(CLAVE, {})
	if not valor is Dictionary:
		return {}
	var sesion: Dictionary = valor
	if not _sesion_valida(sesion, jornada):
		return {}
	return sesion.duplicate(true)


static func _sesion_valida(sesion: Dictionary, jornada: Dictionary) -> bool:
	var datos: Variant = sesion.get("datos", {})
	return (
		int(sesion.get("dia", -1)) == int(jornada.get("dia", 0))
		and TIPOS.has(String(sesion.get("tipo", "")))
		and not String(sesion.get("caso_id", "")).is_empty()
		and not String(sesion.get("reward_id", "")).is_empty()
		and datos is Dictionary
		and not datos.is_empty()
	)


static func guardar(
	jornada: Dictionary,
	tipo: String,
	caso_id: String,
	reward_id: String,
	datos: Dictionary,
) -> bool:
	if String(jornada.get("fase", "")) != "sueño":
		return false
	if not TIPOS.has(tipo):
		return false
	if caso_id.is_empty() or reward_id.is_empty() or datos.is_empty():
		return false
	if registrada_esta_noche(jornada):
		var existente := actual(jornada)
		if existente.is_empty() or not _misma_identidad(existente, tipo, caso_id, reward_id):
			return false
	jornada[CLAVE] = {
		"dia": int(jornada.get("dia", 0)),
		"tipo": tipo,
		"caso_id": caso_id,
		"reward_id": reward_id,
		"datos": datos.duplicate(true),
	}
	return true


static func terminal(sesion: Dictionary) -> bool:
	var datos: Variant = sesion.get("datos", {})
	if not datos is Dictionary:
		return true
	var nucleo: Variant = datos.get("nucleo", {})
	return not nucleo is Dictionary or String(nucleo.get("state", "")) != "pendiente"


static func _misma_identidad(
	sesion: Dictionary,
	tipo: String,
	caso_id: String,
	reward_id: String,
) -> bool:
	return (
		String(sesion.get("tipo", "")) == tipo
		and String(sesion.get("caso_id", "")) == caso_id
		and String(sesion.get("reward_id", "")) == reward_id
	)


static func tipo_actual(jornada: Dictionary) -> String:
	return String(actual(jornada).get("tipo", ""))


static func es_tipo(jornada: Dictionary, tipo: String) -> bool:
	return tipo_actual(jornada) == tipo
