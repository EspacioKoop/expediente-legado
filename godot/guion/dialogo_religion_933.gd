## Variantes de diálogo religioso basadas en hechos observables (#933).
##
## Esta capa solo LEE ReligionEventos. Cada interlocutor consume hechos
## únicamente cuando puede conocerlos: públicos o incluidos de forma explícita
## en conocido_por. Exposición, práctica y convicción declarada siguen siendo
## canales separados; una reacción a convicción exige una declaración real.
class_name DialogoReligion933
extends RefCounted

const ACTOR_CUNADO := "cunado"
const ACTOR_CORRESPONDENCIA := "correspondencia"
const ACTOR_PACO := "paco"
const ACTOR_TELEFONO_COMUNITARIO := "telefono_comunitario"

const CLAVE_CUNADO_EXPOSICION := "RELIGION_933_CUNADO_EXPOSICION"
const CLAVE_CORRESPONDENCIA_PRACTICA := "RELIGION_933_CORRESPONDENCIA_PRACTICA"
const CLAVE_CUNADO_CONVICCION := "RELIGION_933_CUNADO_CONVICCION"
const CLAVE_CORRESPONDENCIA_CONVICCION := "RELIGION_933_CORRESPONDENCIA_CONVICCION"
const CLAVE_PACO_EXPOSICION := "RELIGION_933_PACO_EXPOSICION"
const CLAVE_PACO_PRACTICA := "RELIGION_933_PACO_PRACTICA"
const CLAVE_PACO_CONVICCION := "RELIGION_933_PACO_CONVICCION"
const CLAVE_TELEFONO_EXPOSICION := "RELIGION_933_TELEFONO_EXPOSICION"
const CLAVE_TELEFONO_PRACTICA := "RELIGION_933_TELEFONO_PRACTICA"
const CLAVE_TELEFONO_CONVICCION := "RELIGION_933_TELEFONO_CONVICCION"


static func resolver_clave(estado: Dictionary, actor: String) -> String:
	var actor_limpio := actor.strip_edges()
	var prioridades := _prioridades_para(actor_limpio)
	if prioridades.is_empty():
		return ""

	var registro_bruto: Variant = estado.get(ReligionEventos.CLAVE_ESTADO, {})
	if not registro_bruto is Dictionary:
		return ""
	var jornada_bruta: Variant = estado.get("jornada", {})
	var vuelta := 1
	if jornada_bruta is Dictionary:
		vuelta = maxi(1, int((jornada_bruta as Dictionary).get("vuelta", 1)))

	for prioridad_valor in prioridades:
		var prioridad: Dictionary = prioridad_valor
		var canal := String(prioridad.get("canal", ""))
		var clave := String(prioridad.get("clave", ""))
		var hechos: Array = ReligionEventos.eventos_de_vuelta(
			registro_bruto as Dictionary, canal, vuelta
		)
		for indice in range(hechos.size() - 1, -1, -1):
			var valor: Variant = hechos[indice]
			if valor is Dictionary and _hecho_conocido_por(valor as Dictionary, actor_limpio):
				return clave
	return ""


static func _prioridades_para(actor: String) -> Array:
	match actor:
		ACTOR_CUNADO:
			return [
				{
					"canal": ReligionEventos.CANAL_CONVICCION,
					"clave": CLAVE_CUNADO_CONVICCION,
				},
				{
					"canal": ReligionEventos.CANAL_EXPOSICION,
					"clave": CLAVE_CUNADO_EXPOSICION,
				},
			]
		ACTOR_CORRESPONDENCIA:
			return [
				{
					"canal": ReligionEventos.CANAL_CONVICCION,
					"clave": CLAVE_CORRESPONDENCIA_CONVICCION,
				},
				{
					"canal": ReligionEventos.CANAL_PRACTICA,
					"clave": CLAVE_CORRESPONDENCIA_PRACTICA,
				},
			]
		ACTOR_PACO:
			return [
				{"canal": ReligionEventos.CANAL_CONVICCION, "clave": CLAVE_PACO_CONVICCION},
				{"canal": ReligionEventos.CANAL_PRACTICA, "clave": CLAVE_PACO_PRACTICA},
				{"canal": ReligionEventos.CANAL_EXPOSICION, "clave": CLAVE_PACO_EXPOSICION},
			]
		ACTOR_TELEFONO_COMUNITARIO:
			return [
				{
					"canal": ReligionEventos.CANAL_CONVICCION,
					"clave": CLAVE_TELEFONO_CONVICCION,
				},
				{
					"canal": ReligionEventos.CANAL_PRACTICA,
					"clave": CLAVE_TELEFONO_PRACTICA,
				},
				{
					"canal": ReligionEventos.CANAL_EXPOSICION,
					"clave": CLAVE_TELEFONO_EXPOSICION,
				},
			]
		_:
			return []


static func _hecho_conocido_por(evento: Dictionary, actor: String) -> bool:
	if bool(evento.get("publico", false)):
		return true
	var conocidos: Variant = evento.get("conocido_por", [])
	return conocidos is Array and (conocidos as Array).has(actor)
