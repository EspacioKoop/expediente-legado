## Modelo declarativo del correo corporativo del OS98 (#538).
##
## La entrega depende solo de contexto explícito de partida: día, acciones que
## quedan y plantilla de compañeros. Nunca mira el reloj real ni inventa pistas.
## Un mensaje entregado en un día anterior permanece en la bandeja en días
## posteriores; el umbral de acciones solo decide en qué punto del día aparece.
class_name CorreoSigaModelo
extends RefCounted

const RUTA_CATALOGO := "res://datos/correo_corporativo.json"

var _mensajes: Array[Dictionary] = []
var _contexto: Dictionary = {}


func _init(ruta: String = RUTA_CATALOGO) -> void:
	_mensajes = _cargar_catalogo(ruta)


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)


func catalogo() -> Array[Dictionary]:
	return _mensajes.duplicate(true)


## Devuelve la bandeja de más reciente a más antiguo.
func mensajes_disponibles() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for mensaje in _mensajes:
		if _esta_entregado(mensaje) and _corresponde_a_plantilla(mensaje):
			resultado.append(mensaje.duplicate(true))
	resultado.reverse()
	return resultado


func contar_no_leidos(leidos: Array[String]) -> int:
	var total := 0
	for mensaje in mensajes_disponibles():
		if not leidos.has(String(mensaje.get("id", ""))):
			total += 1
	return total


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
