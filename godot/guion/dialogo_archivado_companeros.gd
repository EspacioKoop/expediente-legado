## Reacciones contextuales al desorden de archivado (#965).
##
## No persiste nada: recibe el actor y la cantidad de errores pendientes que ya
## calcula ArchivadoBandeja. Sirve como fallback narrativo entre reacciones de
## mayor prioridad y los comentarios horarios genéricos.
class_name DialogoArchivadoCompaneros
extends RefCounted

const UMBRAL_ALTO := 3
const CLAVES := {
	"cunado":
	{
		"leve": "COMPA_ARCHIVO_CUNADO_LEVE",
		"alto": "COMPA_ARCHIVO_CUNADO_ALTO",
	},
	"becario":
	{
		"leve": "COMPA_ARCHIVO_BECARIO_LEVE",
		"alto": "COMPA_ARCHIVO_BECARIO_ALTO",
	},
	"jubilacion":
	{
		"leve": "COMPA_ARCHIVO_JUBILACION_LEVE",
		"alto": "COMPA_ARCHIVO_JUBILACION_ALTO",
	},
	"riegos":
	{
		"leve": "COMPA_ARCHIVO_RIEGOS_LEVE",
		"alto": "COMPA_ARCHIVO_RIEGOS_ALTO",
	},
}


static func resolver(actor_id: String, desorden_total: int) -> String:
	if desorden_total <= 0:
		return ""
	var por_actor: Dictionary = CLAVES.get(actor_id, {})
	if por_actor.is_empty():
		return ""
	var nivel := "alto" if desorden_total >= UMBRAL_ALTO else "leve"
	return String(por_actor.get(nivel, ""))
