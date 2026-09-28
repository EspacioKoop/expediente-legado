## Comentarios horarios diegéticos de compañeros (#963).
##
## Es una capa puramente contextual: recibe actor + hora canónica, devuelve una
## clave de traducción y no modifica estado persistente, presencia ni progreso.
class_name DialogoHorarioCompaneros
extends RefCounted

const CLAVES := {
	"cunado":
	{
		"mediodia": "COMPA_HORA_CUNADO_MEDIODIA",
		"tarde": "COMPA_HORA_CUNADO_TARDE",
		"noche": "COMPA_HORA_CUNADO_NOCHE",
	},
	"telefono":
	{
		"mediodia": "COMPA_HORA_TELEFONO_MEDIODIA",
		"tarde": "COMPA_HORA_TELEFONO_TARDE",
		"noche": "COMPA_HORA_TELEFONO_NOCHE",
	},
	"becario":
	{
		"mediodia": "COMPA_HORA_BECARIO_MEDIODIA",
		"tarde": "COMPA_HORA_BECARIO_TARDE",
		"noche": "COMPA_HORA_BECARIO_NOCHE",
	},
	"jubilacion":
	{
		"mediodia": "COMPA_HORA_JUBILACION_MEDIODIA",
		"tarde": "COMPA_HORA_JUBILACION_TARDE",
		"noche": "COMPA_HORA_JUBILACION_NOCHE",
	},
	"riegos":
	{
		"mediodia": "COMPA_HORA_RIEGOS_MEDIODIA",
		"tarde": "COMPA_HORA_RIEGOS_TARDE",
		"noche": "COMPA_HORA_RIEGOS_NOCHE",
	},
}


static func resolver(actor_id: String, hora_decimal: float) -> String:
	var por_actor: Dictionary = CLAVES.get(actor_id, {})
	if por_actor.is_empty():
		return ""
	return String(por_actor.get(franja(hora_decimal), ""))


static func franja(hora_decimal: float) -> String:
	var hora := clampf(hora_decimal, 0.0, 23.999)
	if hora < 7.0 or hora >= 19.0:
		return "noche"
	if hora < 11.0:
		return "manana"
	if hora < 15.0:
		return "mediodia"
	return "tarde"
