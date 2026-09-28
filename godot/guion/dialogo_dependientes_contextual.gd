## Ramificación ligera para dependientes del trayecto (#1672).
##
## Conserva como máximo un hecho por dependiente durante la vida laboral:
## qué enfoque eligió el jugador en su primera conversación ramificada. No hay
## afinidad, reputación ni puntuación; Jornada aporta persistencia y se reinicia
## al empezar otra vida laboral.
class_name DialogoDependientesContextual
extends RefCounted

const CAMPO := "dialogos_dependientes"

const RAMAS := {
	"paco":
	{
		"pragmatica":
		{
			"texto": "DIALOGO_DEP_OPCION_PRAGMATICA",
			"respuesta": "DIALOGO_DEP_PACO_PRAGMATICA_RESPUESTA",
			"reentrada": "DIALOGO_DEP_PACO_PRAGMATICA_REENTRADA",
		},
		"curiosidad":
		{
			"texto": "DIALOGO_DEP_OPCION_CURIOSIDAD",
			"respuesta": "DIALOGO_DEP_PACO_CURIOSIDAD_RESPUESTA",
			"reentrada": "DIALOGO_DEP_PACO_CURIOSIDAD_REENTRADA",
		},
		"cliente":
		{
			"texto": "DIALOGO_DEP_OPCION_CLIENTE",
			"respuesta": "DIALOGO_DEP_PACO_CLIENTE_RESPUESTA",
			"reentrada": "DIALOGO_DEP_PACO_CLIENTE_REENTRADA",
		},
		"tiempo":
		{
			"texto": "DIALOGO_DEP_OPCION_TIEMPO",
			"respuesta": "DIALOGO_DEP_PACO_TIEMPO_RESPUESTA",
			"reentrada": "DIALOGO_DEP_PACO_TIEMPO_REENTRADA",
		},
	},
	"remedios":
	{
		"pragmatica":
		{
			"texto": "DIALOGO_DEP_OPCION_PRAGMATICA",
			"respuesta": "DIALOGO_DEP_REMEDIOS_PRAGMATICA_RESPUESTA",
			"reentrada": "DIALOGO_DEP_REMEDIOS_PRAGMATICA_REENTRADA",
		},
		"curiosidad":
		{
			"texto": "DIALOGO_DEP_OPCION_CURIOSIDAD",
			"respuesta": "DIALOGO_DEP_REMEDIOS_CURIOSIDAD_RESPUESTA",
			"reentrada": "DIALOGO_DEP_REMEDIOS_CURIOSIDAD_REENTRADA",
		},
		"cliente":
		{
			"texto": "DIALOGO_DEP_OPCION_CLIENTE",
			"respuesta": "DIALOGO_DEP_REMEDIOS_CLIENTE_RESPUESTA",
			"reentrada": "DIALOGO_DEP_REMEDIOS_CLIENTE_REENTRADA",
		},
		"tiempo":
		{
			"texto": "DIALOGO_DEP_OPCION_TIEMPO",
			"respuesta": "DIALOGO_DEP_REMEDIOS_TIEMPO_RESPUESTA",
			"reentrada": "DIALOGO_DEP_REMEDIOS_TIEMPO_REENTRADA",
		},
	},
	"kike":
	{
		"pragmatica":
		{
			"texto": "DIALOGO_DEP_OPCION_PRAGMATICA",
			"respuesta": "DIALOGO_DEP_KIKE_PRAGMATICA_RESPUESTA",
			"reentrada": "DIALOGO_DEP_KIKE_PRAGMATICA_REENTRADA",
		},
		"curiosidad":
		{
			"texto": "DIALOGO_DEP_OPCION_CURIOSIDAD",
			"respuesta": "DIALOGO_DEP_KIKE_CURIOSIDAD_RESPUESTA",
			"reentrada": "DIALOGO_DEP_KIKE_CURIOSIDAD_REENTRADA",
		},
		"cliente":
		{
			"texto": "DIALOGO_DEP_OPCION_CLIENTE",
			"respuesta": "DIALOGO_DEP_KIKE_CLIENTE_RESPUESTA",
			"reentrada": "DIALOGO_DEP_KIKE_CLIENTE_REENTRADA",
		},
		"tiempo":
		{
			"texto": "DIALOGO_DEP_OPCION_TIEMPO",
			"respuesta": "DIALOGO_DEP_KIKE_TIEMPO_RESPUESTA",
			"reentrada": "DIALOGO_DEP_KIKE_TIEMPO_REENTRADA",
		},
	},
}


static func tiene_ramas(id_dependiente: String) -> bool:
	return RAMAS.has(id_dependiente)


## Siempre ofrece una respuesta pragmática y una de conversación. Cliente y
## tiempo solo aparecen cuando el estado normal del juego las justifica.
static func opciones(
	dependiente: Dictionary, jornada: Dictionary, clima: String
) -> Array[Dictionary]:
	var id_dependiente := String(dependiente.get("id", ""))
	if not RAMAS.has(id_dependiente):
		return []

	var ids := ["pragmatica", "curiosidad"]
	if DependientesTiendas.es_cliente(dependiente, jornada):
		ids.append("cliente")
	if [Clima.LLUVIA, Clima.NIEVE, Clima.NIEBLA].has(clima):
		ids.append("tiempo")

	var salida: Array[Dictionary] = []
	var ramas: Dictionary = RAMAS[id_dependiente]
	for id_rama in ids:
		var rama: Dictionary = ramas.get(id_rama, {})
		if rama.is_empty():
			continue
		(
			salida
			. append(
				{
					"id": id_rama,
					"texto": String(rama.get("texto", "")),
				}
			)
		)
	return salida


## Primera escritura gana. Repetir el callback o intentar cambiar de enfoque no
## reinterpreta la conversación ya guardada.
static func registrar(jornada: Dictionary, id_dependiente: String, id_rama: String) -> Dictionary:
	var rama := _rama(id_dependiente, id_rama)
	if rama.is_empty():
		return {"valida": false}

	var memorias := _memorias(jornada)
	var previa = memorias.get(id_dependiente, {})
	if typeof(previa) == TYPE_DICTIONARY and not previa.is_empty():
		var anterior := _rama(id_dependiente, String(previa.get("rama", "")))
		if anterior.is_empty():
			return {"valida": false}
		return {
			"valida": true,
			"nueva": false,
			"respuesta": String(anterior.get("reentrada", "")),
		}

	memorias[id_dependiente] = {
		"rama": id_rama,
		"dia": maxi(1, int(jornada.get("dia", 1))),
	}
	jornada[CAMPO] = memorias
	return {
		"valida": true,
		"nueva": true,
		"respuesta": String(rama.get("respuesta", "")),
	}


static func reentrada(jornada: Dictionary, id_dependiente: String) -> String:
	var memorias := _memorias(jornada)
	var memoria = memorias.get(id_dependiente, {})
	if typeof(memoria) != TYPE_DICTIONARY:
		return ""
	var rama := _rama(id_dependiente, String(memoria.get("rama", "")))
	return String(rama.get("reentrada", "")) if not rama.is_empty() else ""


static func claves(id_dependiente: String) -> Array[String]:
	var salida: Array[String] = []
	var ramas: Dictionary = RAMAS.get(id_dependiente, {})
	for rama_bruta in ramas.values():
		if typeof(rama_bruta) != TYPE_DICTIONARY:
			continue
		var rama: Dictionary = rama_bruta
		for campo in ["texto", "respuesta", "reentrada"]:
			var clave := String(rama.get(campo, ""))
			if not clave.is_empty() and not salida.has(clave):
				salida.append(clave)
	return salida


static func _rama(id_dependiente: String, id_rama: String) -> Dictionary:
	var ramas = RAMAS.get(id_dependiente, {})
	if typeof(ramas) != TYPE_DICTIONARY:
		return {}
	var rama = ramas.get(id_rama, {})
	return rama if typeof(rama) == TYPE_DICTIONARY else {}


static func _memorias(jornada: Dictionary) -> Dictionary:
	var actual = jornada.get(CAMPO, {})
	return actual.duplicate(true) if typeof(actual) == TYPE_DICTIONARY else {}
