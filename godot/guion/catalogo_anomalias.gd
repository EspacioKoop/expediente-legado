## Catálogo y memoria de reconocimiento de anomalías oníricas (#149).
##
## Esta capa no conoce Partida, Jornada ni objetivos: recibe un diccionario de
## estado y mantiene dos lecturas del mismo hallazgo. La colección total puede
## persistirse entre vidas laborales; la colección de vuelta se reinicia al
## comenzar una nueva. El wiring con Partida se hace en un corte separado.
class_name CatalogoAnomalias
extends RefCounted

const RUTA_CATALOGO := "res://datos/anomalias_sueno.json"
const CLAVE_TOTAL := "anomalias_descubiertas"
const CLAVE_VUELTA := "anomalias_descubiertas_vuelta"


static func catalogo() -> Array:
	var fichero := FileAccess.open(RUTA_CATALOGO, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s" % RUTA_CATALOGO)
		return []
	var datos = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if typeof(datos) != TYPE_ARRAY:
		push_error("El catálogo de anomalías no es una lista")
		return []
	return datos


static func ficha(anomalia_id: String) -> Dictionary:
	for entrada in catalogo():
		if String(entrada.get("id", "")) == anomalia_id:
			return entrada
	return {}


static func conocida(estado: Dictionary, anomalia_id: String) -> bool:
	return _ids(estado, CLAVE_TOTAL).has(anomalia_id)


static func conocida_en_vuelta(estado: Dictionary, anomalia_id: String) -> bool:
	return _ids(estado, CLAVE_VUELTA).has(anomalia_id)


## Registra reconocimiento, no resolución.
##
## Una anomalía ya conocida puede reaparecer en una vida laboral nueva. En ese
## caso se conserva una sola copia en el total y se añade a la vuelta actual.
static func registrar(estado: Dictionary, anomalia_id: String) -> Dictionary:
	if ficha(anomalia_id).is_empty():
		push_warning("Anomalía desconocida: %s" % anomalia_id)
		return {"resultado": "desconocida", "id": anomalia_id}

	var total := _ids(estado, CLAVE_TOTAL)
	var vuelta := _ids(estado, CLAVE_VUELTA)
	var estaba_total := total.has(anomalia_id)
	var estaba_vuelta := vuelta.has(anomalia_id)

	if not estaba_total:
		total.append(anomalia_id)
		estado[CLAVE_TOTAL] = total
	if not estaba_vuelta:
		vuelta.append(anomalia_id)
		estado[CLAVE_VUELTA] = vuelta

	if not estaba_total:
		return {"resultado": "registrada", "id": anomalia_id}
	if not estaba_vuelta:
		return {"resultado": "reencontrada", "id": anomalia_id}
	return {"resultado": "ya-reconocida", "id": anomalia_id}


## Empieza una vida laboral sin borrar lo aprendido en las anteriores.
static func reiniciar_vuelta(estado: Dictionary) -> void:
	estado[CLAVE_VUELTA] = []


## Datos suficientes para una futura pantalla de catálogo, sin ubicación ni
## condiciones de puzzle. Los contadores son derivados: no crean otra fuente de
## verdad que pueda desincronizarse de las colecciones de ids.
static func progreso(estado: Dictionary) -> Dictionary:
	var entradas := catalogo()
	var ids_validos := []
	for entrada in entradas:
		ids_validos.append(String(entrada.get("id", "")))
	var total := _filtrar_conocidas(_ids(estado, CLAVE_TOTAL), ids_validos)
	var vuelta := _filtrar_conocidas(_ids(estado, CLAVE_VUELTA), ids_validos)
	return {
		"catalogo": entradas.size(),
		"descubiertas_total": total.size(),
		"descubiertas_vuelta": vuelta.size(),
		"vuelta_completa": not entradas.is_empty() and vuelta.size() == entradas.size(),
	}


static func _ids(estado: Dictionary, clave: String) -> Array:
	var valor = estado.get(clave, [])
	if typeof(valor) != TYPE_ARRAY:
		return []
	return valor.duplicate()


static func _filtrar_conocidas(ids: Array, validos: Array) -> Array:
	var filtradas := []
	for anomalia_id in ids:
		if validos.has(anomalia_id) and not filtradas.has(anomalia_id):
			filtradas.append(anomalia_id)
	return filtradas
