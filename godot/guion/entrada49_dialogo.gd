## Reacción contextual de compañeros a La Entrada 49 (#2477).
##
## Es read-only: no registra memoria social ni crea pistas. Expresa cómo una
## irregularidad ya descubierta contamina la conversación cotidiana.
class_name Entrada49Dialogo
extends RefCounted

const CLAVE_ESTADO := "entrada49"

const REACCIONES := {
	"cunado":
	{
		"investigar": "¿Cuarenta y nueve? Pues llama al cuarenta y nueve y que firme.",
		"borrar": "Si lo has borrado y ha vuelto, yo no lo tocaría otra vez.",
	},
	"becario":
	{
		"investigar": "He contado las líneas tres veces. No me salen cuarenta y ocho.",
		"validar": "Si SIGA dice que existe, alguien tendrá que tener su mesa, ¿no?",
	},
	"jubilacion":
	{
		"aislar": "Antes estas cosas se metían en una carpeta y se cerraba el armario.",
		"borrar": "Los papeles borrados siempre dejan marca. En el ordenador debería ser distinto.",
	},
	"correspondencia":
	{
		"investigar": "Una copia puede equivocarse. Tres copias iguales ya son correspondencia.",
	},
}


static func resolver(actor_id: String, estado: Dictionary) -> String:
	var bruto: Variant = estado.get(CLAVE_ESTADO, {})
	if not bruto is Dictionary:
		return ""
	var resolucion := bruto as Dictionary
	if not bool(resolucion.get("ok", false)):
		return ""
	var decision := String(resolucion.get("decision", ""))
	var por_actor: Dictionary = REACCIONES.get(actor_id, {})
	return String(por_actor.get(decision, ""))
