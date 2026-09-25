## Consumidor de trayectoria literaria para epílogos (#1175/#1184).
##
## No calcula una identidad, nivel ni alignment. Resume hechos concretos del
## registro persistente y los adjunta a un final ya resuelto sin reemplazarlo.
class_name LiteraturaTrayectoria
extends RefCounted


static func resumir(registro: Dictionary) -> Dictionary:
	var por_obra := {}
	for canal in LiteraturaEventos.CANALES:
		for evento_bruto in LiteraturaEventos.eventos(registro, canal):
			if typeof(evento_bruto) != TYPE_DICTIONARY:
				continue
			var evento: Dictionary = evento_bruto
			if not LiteraturaEventos.evento_valido(evento):
				continue
			var obra_id := String(evento.get("obra_id", "")).strip_edges()
			if obra_id.is_empty():
				continue
			var ficha: Dictionary = (
				por_obra
				. get(
					obra_id,
					{
						"obra_id": obra_id,
						"canales": [],
						"eventos": [],
						"procedencias": [],
					},
				)
			)
			_agregar_unico(ficha["canales"], canal)
			var evento_id := String(evento.get("id", ""))
			_agregar_unico(ficha["eventos"], evento_id)
			ficha["procedencias"].append(_procedencia(evento))
			por_obra[obra_id] = ficha

	var ids := por_obra.keys()
	ids.sort()
	var obras := []
	var variaciones := []
	var firmas := []
	for obra_id in ids:
		var ficha: Dictionary = por_obra[obra_id]
		ficha["canales"].sort()
		ficha["eventos"].sort()
		ficha["procedencias"].sort_custom(_procedencia_antes)
		obras.append(ficha)
		for canal in ficha["canales"]:
			var firma := "%s:%s" % [obra_id, canal]
			firmas.append(firma)
			var variacion := _variacion_para_canal(String(canal))
			if not variacion.is_empty():
				_agregar_unico(variaciones, variacion)

	var estado := "ausente"
	if firmas.size() == 1:
		estado = "singular"
	elif firmas.size() > 1:
		estado = "plural"

	variaciones.sort()
	firmas.sort()
	return {
		"estado": estado,
		"plural": firmas.size() > 1,
		"obras": obras,
		"variaciones": variaciones,
		"firmas": firmas,
	}


## El final principal ya viene decidido por su sistema dueño. Literatura solo
## añade una capa descriptiva derivada; una trayectoria vacía sigue devolviendo
## exactamente el mismo id de final base.
static func derivar_epilogo(final_base: String, registro: Dictionary) -> Dictionary:
	return {
		"final_base": final_base,
		"literatura": resumir(registro),
		"bloquea_final_base": false,
	}


static func _procedencia(evento: Dictionary) -> Dictionary:
	return {
		"id": String(evento.get("id", "")),
		"canal": String(evento.get("canal", "")),
		"fuente": String(evento.get("fuente", "")),
		"contexto": String(evento.get("contexto", "")),
		"jornada": maxi(0, int(evento.get("jornada", 0))),
	}


static func _procedencia_antes(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("id", "")) < String(b.get("id", ""))


static func _variacion_para_canal(canal: String) -> String:
	match canal:
		LiteraturaEventos.CANAL_CONOCIMIENTO:
			return "obra_conocida"
		LiteraturaEventos.CANAL_POSESION:
			return "ejemplar_poseido"
		LiteraturaEventos.CANAL_INSIGHT:
			return "insight_contextual"
		LiteraturaEventos.CANAL_RITUAL:
			return "ritual_ejecutado"
		_:
			return ""


static func _agregar_unico(lista: Array, valor) -> void:
	if not lista.has(valor):
		lista.append(valor)
