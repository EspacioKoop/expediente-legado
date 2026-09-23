## Condiciones declarativas de conversación ideológica (#920).
##
## Esta capa solo LEE el contrato transversal de Prometeo (#919): elecciones,
## exposición y lecturas sociales siguen separados. No decide hechos del caso,
## no añade pistas y no altera opciones de combate.
class_name DialogoIdeologico
extends RefCounted

const SUPERFICIE_OFICINA_CUNADO := "oficina:cunado:postcierre"
const SUPERFICIE_CAREO_EXPOSICION := "careo:exposicion"

const VARIANTES := {
	SUPERFICIE_OFICINA_CUNADO:
	[
		{
			"clave": "IDEOLOGIA_924_CUNADO_COLECTIVO",
			"requiere_evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
			"requiere_eleccion":
			{
				"evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
				"etiqueta": "opcion:responsabilidad_compartida",
			},
			"respuesta_registra":
			{
				"actor": DecisionIdeologicaExpediente.ACTOR_CUNADO,
				"evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
				"reaccion": "cierre_colectivo",
				"etiquetas": ["expediente", "postcierre", "opcion:responsabilidad_compartida"],
			},
		},
		{
			"clave": "IDEOLOGIA_924_CUNADO_PROCEDIMIENTO",
			"requiere_evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
			"requiere_eleccion":
			{
				"evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
				"etiqueta": "opcion:revision_procedimental",
			},
			"respuesta_registra":
			{
				"actor": DecisionIdeologicaExpediente.ACTOR_CUNADO,
				"evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
				"reaccion": "cierre_procedimental",
				"etiquetas": ["expediente", "postcierre", "opcion:revision_procedimental"],
			},
		},
		{
			"clave": "IDEOLOGIA_924_CUNADO_NEGOCIADO",
			"requiere_evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
			"requiere_eleccion":
			{
				"evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
				"etiqueta": "opcion:conciliacion_interna",
			},
			"respuesta_registra":
			{
				"actor": DecisionIdeologicaExpediente.ACTOR_CUNADO,
				"evento": DecisionIdeologicaExpediente.EVENTO_VERTICAL,
				"reaccion": "cierre_negociado",
				"etiquetas": ["expediente", "postcierre", "opcion:conciliacion_interna"],
			},
		},
	],
	SUPERFICIE_CAREO_EXPOSICION:
	[
		{
			"clave": "IDEOLOGIA_920_CAREO_EXP_COMUNISMO",
			"requiere_exposicion": {"eje": "comunismo"},
		},
		{
			"clave": "IDEOLOGIA_920_CAREO_EXP_SOCIALDEMOCRATA",
			"requiere_exposicion": {"eje": "socialdemocrata"},
		},
		{
			"clave": "IDEOLOGIA_920_CAREO_EXP_CENTRISTA",
			"requiere_exposicion": {"eje": "centrista"},
		},
		{
			"clave": "IDEOLOGIA_920_CAREO_EXP_NEOLIBERAL",
			"requiere_exposicion": {"eje": "neoliberal"},
		},
	],
}


## Devuelve una variante ya resuelta. Si varias exposiciones cumplen, gana la
## consumida más recientemente, no la posición del eje en Prometeo.EJES.
static func resolver(superficie: String, estado: Dictionary) -> Dictionary:
	var valor = VARIANTES.get(superficie, [])
	if typeof(valor) != TYPE_ARRAY:
		return {}

	var mejor: Dictionary = {}
	var mejor_recencia := -2
	for candidato in valor:
		if typeof(candidato) != TYPE_DICTIONARY:
			continue
		var variante: Dictionary = candidato
		if not cumple(estado, variante):
			continue
		var recencia := _recencia_exposicion(estado, variante.get("requiere_exposicion", {}))
		if mejor.is_empty() or recencia > mejor_recencia:
			mejor = variante.duplicate(true)
			mejor_recencia = recencia
	return mejor


## Contrato de condiciones reutilizable por futuras conversaciones.
## Soporta los equivalentes de requiere_evento, requiere_eleccion,
## requiere_exposicion y actor_recuerda propuestos en #920.
static func cumple(estado: Dictionary, condiciones: Dictionary) -> bool:
	var evento := String(condiciones.get("requiere_evento", ""))
	if not evento.is_empty() and _eleccion_por_id(estado, evento).is_empty():
		return false

	var eleccion = condiciones.get("requiere_eleccion", {})
	if typeof(eleccion) == TYPE_DICTIONARY and not eleccion.is_empty():
		if not _cumple_eleccion(estado, eleccion):
			return false

	var exposicion = condiciones.get("requiere_exposicion", {})
	if typeof(exposicion) == TYPE_DICTIONARY and not exposicion.is_empty():
		if _indice_exposicion_que_cumple(estado, exposicion) < 0:
			return false

	var recuerdo = condiciones.get("actor_recuerda", {})
	if typeof(recuerdo) == TYPE_DICTIONARY and not recuerdo.is_empty():
		if not _actor_recuerda(estado, recuerdo):
			return false

	return true


## Aplica únicamente el efecto declarativo de la respuesta. En este corte es una
## lectura social: registrar que el actor observó un evento real ya existente.
## No añade elecciones ni exposición.
static func registrar_respuesta(estado: Dictionary, variante: Dictionary) -> bool:
	var valor = variante.get("respuesta_registra", {})
	if typeof(valor) != TYPE_DICTIONARY or valor.is_empty():
		return false
	var respuesta: Dictionary = valor
	var actor := String(respuesta.get("actor", ""))
	var evento := String(respuesta.get("evento", ""))
	if actor.is_empty() or evento.is_empty() or _eleccion_por_id(estado, evento).is_empty():
		return false
	var etiquetas = respuesta.get("etiquetas", [])
	var lista: Array = etiquetas.duplicate() if typeof(etiquetas) == TYPE_ARRAY else []
	return (
		Prometeo
		. registrar_lectura_social(
			estado,
			actor,
			evento,
			String(respuesta.get("reaccion", "")),
			lista,
		)
	)


static func _eleccion_por_id(estado: Dictionary, evento_id: String) -> Dictionary:
	for valor in Prometeo.elecciones_ideologicas(estado):
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = valor
		if String(evento.get("id", "")) == evento_id:
			return evento.duplicate(true)
	return {}


static func _cumple_eleccion(estado: Dictionary, condicion: Dictionary) -> bool:
	var minimo := maxi(1, int(condicion.get("minimo", 1)))
	var coincidencias := 0
	for valor in Prometeo.elecciones_ideologicas(estado):
		if typeof(valor) != TYPE_DICTIONARY:
			continue
		var evento: Dictionary = valor
		if _coincide(evento, condicion):
			coincidencias += 1
			if coincidencias >= minimo:
				return true
	return false


static func _recencia_exposicion(estado: Dictionary, condicion) -> int:
	if typeof(condicion) != TYPE_DICTIONARY or condicion.is_empty():
		return -1
	return _indice_exposicion_que_cumple(estado, condicion)


static func _indice_exposicion_que_cumple(estado: Dictionary, condicion: Dictionary) -> int:
	var valor = estado.get(Prometeo.CLAVE_EXPOSICION_IDEOLOGICA, [])
	if typeof(valor) != TYPE_ARRAY:
		return -1
	var exposiciones: Array = valor
	for indice in range(exposiciones.size() - 1, -1, -1):
		var exposicion = exposiciones[indice]
		if typeof(exposicion) == TYPE_DICTIONARY and _coincide(exposicion, condicion):
			return indice
	return -1


static func _actor_recuerda(estado: Dictionary, condicion: Dictionary) -> bool:
	var actor := String(condicion.get("actor", ""))
	var evento := String(condicion.get("evento", ""))
	if actor.is_empty() or evento.is_empty():
		return false
	var valor = estado.get(Prometeo.CLAVE_LECTURAS_SOCIALES, [])
	if typeof(valor) != TYPE_ARRAY:
		return false
	for lectura in valor:
		if typeof(lectura) != TYPE_DICTIONARY:
			continue
		if (
			String(lectura.get("actor", "")) == actor
			and String(lectura.get("evento_observado", "")) == evento
		):
			return true
	return false


static func _coincide(evento: Dictionary, condicion: Dictionary) -> bool:
	var evento_id := String(condicion.get("evento", ""))
	if not evento_id.is_empty() and String(evento.get("id", "")) != evento_id:
		return false
	var eje := String(condicion.get("eje", ""))
	if not eje.is_empty() and String(evento.get("eje", "")) != eje:
		return false
	var fuente := String(condicion.get("fuente", ""))
	if not fuente.is_empty() and String(evento.get("fuente", "")) != fuente:
		return false
	var fuente_prefijo := String(condicion.get("fuente_prefijo", ""))
	if (
		not fuente_prefijo.is_empty()
		and not String(evento.get("fuente", "")).begins_with(fuente_prefijo)
	):
		return false
	var etiqueta := String(condicion.get("etiqueta", ""))
	if not etiqueta.is_empty():
		var etiquetas = evento.get("etiquetas", [])
		if typeof(etiquetas) != TYPE_ARRAY or not etiquetas.has(etiqueta):
			return false
	return true
