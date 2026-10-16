class_name SuenoMuseoVidasNoOcurridas
extends RefCounted

## Contrato puro para generar el museo de vidas no ocurridas (#2467).
##
## Lee el estado (contexto) de forma inmutable y, a partir de una semilla,
## devuelve de forma determinista exactamente 3 posibilidades no canónicas.
## Nunca modifica el contexto original y usa el generador del dominio "sueno".


## Devuelve tres variaciones de vidas que no sucedieron basadas en el contexto.
##
## [param contexto] El estado actual (día, fase, eventos, etc.).
## [param semilla] La raíz de azar para la generación determinista.
static func posibilidades(contexto: Dictionary, semilla: int) -> Array:
	var disponibles := _candidatos(contexto)

	disponibles.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("id", "")) < String(b.get("id", ""))
	)

	var rng := Azar.generador(semilla, "sueno", ["museo_vidas_no_ocurridas"])

	var seleccionados := []
	while seleccionados.size() < 3 and not disponibles.is_empty():
		var indice := rng.randi_range(0, disponibles.size() - 1)
		var elegida: Dictionary = disponibles[indice].duplicate(true)
		elegida["canonica"] = false
		elegida["explorable"] = false
		seleccionados.append(elegida)
		disponibles.remove_at(indice)

	var indice_explorable := rng.randi_range(0, seleccionados.size() - 1)
	seleccionados[indice_explorable]["explorable"] = true

	return seleccionados


static func _candidatos(contexto: Dictionary) -> Array:
	var opciones := []

	opciones.append(
		{"id": "huida_inicial", "clave_texto": "SUENO_MUSEO_HUIDA_INICIAL", "origen": "inicio"}
	)
	opciones.append(
		{"id": "rechazo_oferta", "clave_texto": "SUENO_MUSEO_RECHAZO_OFERTA", "origen": "inicio"}
	)
	opciones.append(
		{
			"id": "despido_prematuro",
			"clave_texto": "SUENO_MUSEO_DESPIDO_PREMATURO",
			"origen": "inicio"
		}
	)

	var dia := int(contexto.get("dia", 1))
	if dia > 1:
		opciones.append(
			{"id": "abandono_dia_1", "clave_texto": "SUENO_MUSEO_ABANDONO_DIA_1", "origen": "dia"}
		)

	var vuelta := int(contexto.get("vuelta", 1))
	if vuelta > 1:
		opciones.append(
			{
				"id": "rendicion_vuelta_1",
				"clave_texto": "SUENO_MUSEO_RENDICION_VUELTA_1",
				"origen": "vuelta"
			}
		)

	var fase := String(contexto.get("fase", ""))
	if fase == "archivo":
		opciones.append(
			{
				"id": "atrapado_archivo",
				"clave_texto": "SUENO_MUSEO_ATRAPADO_ARCHIVO",
				"origen": "fase"
			}
		)
	elif fase == "trayecto":
		opciones.append(
			{"id": "perdido_calle", "clave_texto": "SUENO_MUSEO_PERDIDO_CALLE", "origen": "fase"}
		)

	var companeros: Variant = contexto.get("companeros", [])
	if companeros is Array and not (companeros as Array).is_empty():
		opciones.append(
			{
				"id": "aislamiento_voluntario",
				"clave_texto": "SUENO_MUSEO_AISLAMIENTO",
				"origen": "companeros"
			}
		)

	var eventos: Variant = contexto.get("eventos", [])
	if eventos is Array and not (eventos as Array).is_empty():
		opciones.append(
			{
				"id": "abrumado_eventos",
				"clave_texto": "SUENO_MUSEO_ABRUMADO_EVENTOS",
				"origen": "eventos"
			}
		)

	return opciones


## Devuelve una copia profunda del contexto para demostrar que la evaluación
## no altera el estado original.
static func snapshot(contexto: Dictionary) -> Dictionary:
	return contexto.duplicate(true)


## Compara dos diccionarios para garantizar la pureza tras operar sobre ellos.
static func es_igual(a: Dictionary, b: Dictionary) -> bool:
	return str(a) == str(b)
