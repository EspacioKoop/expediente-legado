## Compositor factual de epílogo religioso (#937).
##
## Consume snapshots archivados por ReligionEventos y produce una capa
## descriptiva sobre un final ya decidido. Nunca calcula una identidad global,
## puntuación, ganador ni jerarquía entre declaraciones.
class_name ReligionTrayectoria
extends RefCounted

const MODULO_DECLARACIONES := "declaraciones"
const MODULO_PRACTICAS_EXPOSICIONES := "practicas_exposiciones"
const MODULO_VINCULOS := "vinculos"


static func resumir(snapshot: Dictionary) -> Dictionary:
	var valor_canales = snapshot.get("canales", {})
	if typeof(valor_canales) != TYPE_DICTIONARY:
		return _resumen_vacio(snapshot)

	var canales: Dictionary = valor_canales
	var modulos: Array = []

	var declaraciones := _hechos_de(canales, [ReligionEventos.CANAL_CONVICCION])
	if not declaraciones.is_empty():
		(
			modulos
			. append(
				_modulo(
					MODULO_DECLARACIONES,
					[ReligionEventos.CANAL_CONVICCION],
					declaraciones,
				)
			)
		)

	var practicas_exposiciones := _hechos_de(
		canales,
		[
			ReligionEventos.CANAL_PRACTICA,
			ReligionEventos.CANAL_EXPOSICION,
		],
	)
	if not practicas_exposiciones.is_empty():
		(
			modulos
			. append(
				_modulo(
					MODULO_PRACTICAS_EXPOSICIONES,
					[
						ReligionEventos.CANAL_PRACTICA,
						ReligionEventos.CANAL_EXPOSICION,
					],
					practicas_exposiciones,
				)
			)
		)

	var vinculos := _hechos_de(canales, [ReligionEventos.CANAL_VINCULO])
	if not vinculos.is_empty():
		(
			modulos
			. append(
				_modulo(
					MODULO_VINCULOS,
					[ReligionEventos.CANAL_VINCULO],
					vinculos,
				)
			)
		)

	return {
		"vuelta": maxi(0, int(snapshot.get("vuelta", 0))),
		"estado": "factual" if not modulos.is_empty() else "ausente",
		"modulos": modulos,
	}


## El final principal pertenece a su sistema dueño. Religión solo adjunta hechos
## observables; un snapshot vacío conserva exactamente el mismo final base.
static func derivar_epilogo(final_base: String, snapshot: Dictionary) -> Dictionary:
	return {
		"final_base": final_base,
		"religion": resumir(snapshot),
		"bloquea_final_base": false,
	}


static func _resumen_vacio(snapshot: Dictionary) -> Dictionary:
	return {
		"vuelta": maxi(0, int(snapshot.get("vuelta", 0))),
		"estado": "ausente",
		"modulos": [],
	}


static func _hechos_de(canales: Dictionary, canales_objetivo: Array) -> Array:
	var hechos: Array = []
	for canal_valor in canales_objetivo:
		var canal := String(canal_valor)
		var valores = canales.get(canal, [])
		if typeof(valores) != TYPE_ARRAY:
			continue
		for valor in valores:
			if typeof(valor) != TYPE_DICTIONARY:
				continue
			var hecho: Dictionary = valor
			if String(hecho.get("canal", "")) != canal:
				continue
			if not ReligionEventos.evento_valido(hecho):
				continue
			hechos.append(hecho.duplicate(true))
	hechos.sort_custom(_hecho_antes)
	return hechos


static func _modulo(id_modulo: String, canales: Array, hechos: Array) -> Dictionary:
	return {
		"id": id_modulo,
		"canales": canales.duplicate(),
		"hechos": hechos.duplicate(true),
		"requiere_citar_hechos": true,
	}


static func _hecho_antes(a: Dictionary, b: Dictionary) -> bool:
	var jornada_a := int(a.get("jornada", 0))
	var jornada_b := int(b.get("jornada", 0))
	if jornada_a != jornada_b:
		return jornada_a < jornada_b
	return String(a.get("id", "")) < String(b.get("id", ""))
