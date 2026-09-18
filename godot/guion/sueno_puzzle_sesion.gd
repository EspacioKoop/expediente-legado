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


static func actual(jornada: Dictionary) -> Dictionary:
	if String(jornada.get("fase", "")) != "sueño":
		return {}
	var valor: Variant = jornada.get(CLAVE, {})
	if not valor is Dictionary:
		return {}
	var sesion: Dictionary = valor
	if int(sesion.get("dia", -1)) != int(jornada.get("dia", 0)):
		return {}
	if not TIPOS.has(String(sesion.get("tipo", ""))):
		return {}
	if String(sesion.get("caso_id", "")).is_empty():
		return {}
	if String(sesion.get("reward_id", "")).is_empty():
		return {}
	var datos: Variant = sesion.get("datos", {})
	if not datos is Dictionary or datos.is_empty():
		return {}
	return sesion.duplicate(true)


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
	jornada[CLAVE] = {
		"dia": int(jornada.get("dia", 0)),
		"tipo": tipo,
		"caso_id": caso_id,
		"reward_id": reward_id,
		"datos": datos.duplicate(true),
	}
	return true


static func tipo_actual(jornada: Dictionary) -> String:
	return String(actual(jornada).get("tipo", ""))


static func es_tipo(jornada: Dictionary, tipo: String) -> bool:
	return tipo_actual(jornada) == tipo
