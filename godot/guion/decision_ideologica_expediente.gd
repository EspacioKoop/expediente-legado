## Decisiones ideológicas ligadas a hechos de expediente (#924).
##
## Este módulo no vuelve a interpretar los hechos ni cambia un veredicto. Espera
## a que exista un cierre real, ofrece una decisión de consecuencia posterior y
## registra únicamente esa elección en el contrato común de Prometeo (#919).
##
## La primera vertical usa caso@1 porque sus hechos ya están catalogados. No se
## fuerza una matriz de cuatro ejes: este contexto expone tres salidas plausibles.
## Las reacciones sociales también pasan por aquí para que un actor solo pueda
## reaccionar a un evento que el corte declara observable para él.
class_name DecisionIdeologicaExpediente
extends RefCounted

const CASO_VERTICAL := "caso@1"
const EVENTO_VERTICAL := "expediente:caso@1:postcierre"
const ACTOR_CUNADO := "cunado"
const PREFIJO_OPCION := "opcion:"

const DECISIONES := {
	CASO_VERTICAL:
	{
		"id": EVENTO_VERTICAL,
		"opciones":
		[
			{
				"id": "responsabilidad_compartida",
				"eje": "comunismo",
				"etiquetas": ["responsabilidad_colectiva", "control_interno"],
			},
			{
				"id": "revision_procedimental",
				"eje": "socialdemocrata",
				"etiquetas": ["garantias_procedimiento", "revision_institucional"],
			},
			{
				"id": "conciliacion_interna",
				"eje": "centrista",
				"etiquetas": ["conciliacion", "acuerdo_interno"],
			},
		],
		"observadores":
		{
			ACTOR_CUNADO:
			{
				"responsabilidad_compartida": "cierre_colectivo",
				"revision_procedimental": "cierre_procedimental",
				"conciliacion_interna": "cierre_negociado",
			}
		},
	}
}


static func definicion(caso_id: String) -> Dictionary:
	var valor = DECISIONES.get(caso_id, {})
	return valor.duplicate(true) if typeof(valor) == TYPE_DICTIONARY else {}


static func opciones(caso_id: String) -> Array:
	var actual := definicion(caso_id)
	var valor = actual.get("opciones", [])
	return valor.duplicate(true) if typeof(valor) == TYPE_ARRAY else []


static func disponible(estado: Dictionary, caso_id: String) -> bool:
	var actual := definicion(caso_id)
	if actual.is_empty() or not _cerrado(estado, caso_id):
		return false
	return _evento(estado, String(actual.get("id", ""))).is_empty()


static func resolver(
	estado: Dictionary,
	caso_id: String,
	opcion_id: String,
) -> Dictionary:
	var actual := definicion(caso_id)
	if actual.is_empty():
		return {"resultado": "sin_decision"}

	var evento_id := String(actual.get("id", ""))
	var previa := _evento(estado, evento_id)
	if not previa.is_empty():
		return {"resultado": "ya_resuelta", "evento": previa}
	if not _cerrado(estado, caso_id):
		return {"resultado": "no_disponible"}

	var opcion := _opcion(actual, opcion_id)
	if opcion.is_empty():
		return {"resultado": "opcion_invalida"}

	var etiquetas: Array = opcion.get("etiquetas", []).duplicate()
	etiquetas.append("expediente")
	etiquetas.append(PREFIJO_OPCION + opcion_id)
	var registrada := (
		Prometeo
		. registrar_eleccion_ideologica(
			estado,
			evento_id,
			"expediente",
			String(opcion.get("eje", "")),
			caso_id,
			_jornada_actual(estado),
			etiquetas,
		)
	)
	if not registrada:
		return {"resultado": "rechazada"}

	return {"resultado": "registrada", "evento": _evento(estado, evento_id)}


static func opcion_registrada(estado: Dictionary, caso_id: String) -> String:
	var actual := definicion(caso_id)
	if actual.is_empty():
		return ""
	var evento := _evento(estado, String(actual.get("id", "")))
	if evento.is_empty():
		return ""
	var etiquetas = evento.get("etiquetas", [])
	if typeof(etiquetas) != TYPE_ARRAY:
		return ""
	for etiqueta in etiquetas:
		var texto := String(etiqueta)
		if texto.begins_with(PREFIJO_OPCION):
			var opcion_id := texto.trim_prefix(PREFIJO_OPCION)
			if not _opcion(actual, opcion_id).is_empty():
				return opcion_id
	return ""


static func reaccion_para(estado: Dictionary, caso_id: String, actor: String) -> String:
	var actual := definicion(caso_id)
	if actual.is_empty():
		return ""
	var opcion_id := opcion_registrada(estado, caso_id)
	if opcion_id.is_empty():
		return ""

	var observadores = actual.get("observadores", {})
	if typeof(observadores) != TYPE_DICTIONARY or not observadores.has(actor):
		return ""
	var reacciones = observadores[actor]
	if typeof(reacciones) != TYPE_DICTIONARY:
		return ""
	return String(reacciones.get(opcion_id, ""))


static func registrar_lectura_social(
	estado: Dictionary,
	caso_id: String,
	actor: String,
) -> bool:
	var actual := definicion(caso_id)
	if actual.is_empty():
		return false
	var reaccion := reaccion_para(estado, caso_id, actor)
	if reaccion.is_empty():
		return false

	var evento_id := String(actual.get("id", ""))
	if _evento(estado, evento_id).is_empty():
		return false
	var opcion_id := opcion_registrada(estado, caso_id)
	return (
		Prometeo
		. registrar_lectura_social(
			estado,
			actor,
			evento_id,
			reaccion,
			["expediente", "postcierre", PREFIJO_OPCION + opcion_id],
		)
	)


static func _cerrado(estado: Dictionary, caso_id: String) -> bool:
	var veredictos = estado.get("veredictos", {})
	return typeof(veredictos) == TYPE_DICTIONARY and veredictos.has(caso_id)


static func _evento(estado: Dictionary, evento_id: String) -> Dictionary:
	if evento_id.is_empty():
		return {}
	for evento in Prometeo.elecciones_ideologicas(estado):
		if typeof(evento) == TYPE_DICTIONARY and String(evento.get("id", "")) == evento_id:
			return evento.duplicate(true)
	return {}


static func _opcion(actual: Dictionary, opcion_id: String) -> Dictionary:
	var candidatas = actual.get("opciones", [])
	if typeof(candidatas) != TYPE_ARRAY:
		return {}
	for opcion in candidatas:
		if typeof(opcion) == TYPE_DICTIONARY and String(opcion.get("id", "")) == opcion_id:
			return opcion.duplicate(true)
	return {}


static func _jornada_actual(estado: Dictionary) -> int:
	var jornada = estado.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return 0
	return int(jornada.get("dia", 0))
