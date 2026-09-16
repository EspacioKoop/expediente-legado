## Modelo declarativo del correo corporativo del OS98 (#538, #665).
##
## La entrega depende solo de contexto explícito de partida: día, acciones que
## quedan y plantilla de compañeros. Nunca mira el reloj real ni inventa pistas.
## Un mensaje entregado en un día anterior permanece en la bandeja en días
## posteriores; el umbral de acciones solo decide en qué punto del día aparece.
class_name CorreoSigaModelo
extends RefCounted

const RUTA_CATALOGO := "res://datos/correo_corporativo.json"
const RUTA_FOLKLORE := "res://datos/correo_folklore.json"
const RUTA_RESPUESTAS := "res://datos/correo_respuestas.json"

var _mensajes: Array[Dictionary] = []
var _hilos: Dictionary = {}
var _contexto: Dictionary = {}
var _respuestas_enviadas: Dictionary = {}


func _init(ruta: String = RUTA_CATALOGO, ruta_respuestas: String = RUTA_RESPUESTAS) -> void:
	_mensajes = _cargar_catalogo(ruta)
	# El folklore es una extensión del buzón normal. Solo se añade al catálogo
	# principal para que los catálogos de prueba/fixture sigan siendo aislados.
	if ruta == RUTA_CATALOGO:
		_mensajes.append_array(_cargar_catalogo(RUTA_FOLKLORE))
	_hilos = _cargar_hilos(ruta_respuestas)


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)


func configurar_respuestas_enviadas(valores: Dictionary) -> void:
	_respuestas_enviadas = valores.duplicate(true)


func catalogo() -> Array[Dictionary]:
	return _mensajes.duplicate(true)


func opciones_respuesta(mensaje_id: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	var hilo: Variant = _hilos.get(mensaje_id, {})
	if not hilo is Dictionary:
		return resultado
	for valor in (hilo as Dictionary).get("opciones", []):
		if valor is Dictionary:
			resultado.append((valor as Dictionary).duplicate(true))
	return resultado


## Devuelve la bandeja de más reciente a más antiguo.
func mensajes_disponibles() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for mensaje in _mensajes:
		if _esta_entregado(mensaje) and _corresponde_a_plantilla(mensaje):
			resultado.append(mensaje.duplicate(true))
	resultado.reverse()
	for contestacion in _contestaciones_disponibles():
		resultado.push_front(contestacion)
	return resultado


func contar_no_leidos(leidos: Array[String]) -> int:
	var total := 0
	for mensaje in mensajes_disponibles():
		if not leidos.has(String(mensaje.get("id", ""))):
			total += 1
	return total


func _contestaciones_disponibles() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for clave in _respuestas_enviadas:
		var mensaje_id := String(clave)
		var envio: Variant = _respuestas_enviadas.get(clave, {})
		var hilo: Variant = _hilos.get(mensaje_id, {})
		if not envio is Dictionary or not hilo is Dictionary:
			continue
		var opcion_id := String((envio as Dictionary).get("opcion_id", ""))
		var opcion := _buscar_opcion(hilo as Dictionary, opcion_id)
		if opcion.is_empty():
			continue
		var objetivo := _objetivo_contestacion(envio as Dictionary, hilo as Dictionary)
		if not _objetivo_alcanzado(objetivo):
			continue
		var original := _mensaje_por_id(mensaje_id)
		if original.is_empty() or not _corresponde_a_plantilla(original):
			continue
		resultado.append(_crear_contestacion(original, opcion, objetivo))
	return resultado


func _objetivo_contestacion(envio: Dictionary, hilo: Dictionary) -> Dictionary:
	var dia := maxi(1, int(envio.get("dia", 1)))
	var acciones := clampi(
		int(envio.get("acciones", Jornada.ACCIONES_POR_DIA)), 0, Jornada.ACCIONES_POR_DIA
	)
	var espera := maxi(1, int(hilo.get("espera_acciones", 1)))
	acciones -= espera
	while acciones < 0:
		dia += 1
		acciones += Jornada.ACCIONES_POR_DIA + 1
	return {"dia": dia, "acciones": acciones}


func _objetivo_alcanzado(objetivo: Dictionary) -> bool:
	if String(_contexto.get("fase", "archivo")) != "archivo":
		return false
	var dia_actual := int(_contexto.get("dia", 1))
	var dia_objetivo := int(objetivo.get("dia", 1))
	if dia_actual > dia_objetivo:
		return true
	if dia_actual < dia_objetivo:
		return false
	return (
		int(_contexto.get("acciones", Jornada.ACCIONES_POR_DIA))
		<= int(objetivo.get("acciones", Jornada.ACCIONES_POR_DIA))
	)


func _crear_contestacion(
	original: Dictionary, opcion: Dictionary, objetivo: Dictionary
) -> Dictionary:
	var mensaje_id := String(original.get("id", ""))
	var opcion_id := String(opcion.get("id", ""))
	var asunto := String(original.get("asunto", ""))
	if not asunto.begins_with("RE:"):
		asunto = "RE: " + asunto
	return {
		"id": "contestacion-%s-%s" % [mensaje_id, opcion_id],
		"remitente": String(original.get("remitente", "")),
		"direccion": String(original.get("direccion", "")),
		"asunto": asunto,
		"cuerpo": String(opcion.get("contestacion", "")),
		"companero_id": String(original.get("companero_id", "")),
		"dia_entrega": int(objetivo.get("dia", 1)),
		"acciones_max": int(objetivo.get("acciones", Jornada.ACCIONES_POR_DIA)),
		"hora": _hora_para_acciones(int(objetivo.get("acciones", Jornada.ACCIONES_POR_DIA))),
		"tipo": "respuesta_companero",
		"importancia_narrativa": false,
		"adjunto": "",
		"respuesta_a": mensaje_id,
	}


func _hora_para_acciones(acciones: int) -> String:
	var acciones_validas := clampi(acciones, 0, Jornada.ACCIONES_POR_DIA)
	var consumidas := Jornada.ACCIONES_POR_DIA - acciones_validas
	var pasos := maxi(1, Jornada.ACCIONES_POR_DIA)
	var minutos := 8 * 60 + 16 + int(round(float(consumidas) * 480.0 / float(pasos)))
	return "%02d:%02d" % [int(minutos / 60), minutos % 60]


func _buscar_opcion(hilo: Dictionary, opcion_id: String) -> Dictionary:
	for valor in hilo.get("opciones", []):
		if valor is Dictionary and String((valor as Dictionary).get("id", "")) == opcion_id:
			return (valor as Dictionary).duplicate(true)
	return {}


func _mensaje_por_id(mensaje_id: String) -> Dictionary:
	for mensaje in _mensajes:
		if String(mensaje.get("id", "")) == mensaje_id:
			return mensaje.duplicate(true)
	return {}


func _esta_entregado(mensaje: Dictionary) -> bool:
	if String(_contexto.get("fase", "archivo")) != "archivo":
		return false
	var dia_actual := int(_contexto.get("dia", 1))
	var dia_entrega := int(mensaje.get("dia_entrega", 1))
	if dia_actual > dia_entrega:
		return true
	if dia_actual < dia_entrega:
		return false
	var acciones := int(_contexto.get("acciones", Jornada.ACCIONES_POR_DIA))
	var umbral := int(mensaje.get("acciones_max", Jornada.ACCIONES_POR_DIA))
	return acciones <= umbral


func _corresponde_a_plantilla(mensaje: Dictionary) -> bool:
	var companero_id := String(mensaje.get("companero_id", ""))
	if companero_id.is_empty():
		return true
	var presentes: Variant = _contexto.get("companeros", [])
	return presentes is Array and (presentes as Array).has(companero_id)


func _cargar_catalogo(ruta: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	if not FileAccess.file_exists(ruta):
		return resultado
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return resultado
	var vistos: Dictionary = {}
	for valor in (datos as Dictionary).get("mensajes", []):
		if not valor is Dictionary:
			continue
		var mensaje := valor as Dictionary
		var id := String(mensaje.get("id", ""))
		if id.is_empty() or vistos.has(id):
			continue
		if String(mensaje.get("remitente", "")).is_empty():
			continue
		if String(mensaje.get("asunto", "")).is_empty():
			continue
		vistos[id] = true
		resultado.append(mensaje.duplicate(true))
	return resultado


func _cargar_hilos(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return {}
	var hilos: Variant = (datos as Dictionary).get("hilos", {})
	if not hilos is Dictionary:
		return {}
	return (hilos as Dictionary).duplicate(true)
