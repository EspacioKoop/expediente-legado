## Cliente opcional del ranking online del golf (#158).
##
## Nunca es requisito para jugar. La partida puede registrar primero en
## RankingGolf y luego intentar sincronizar. No guarda credenciales ni IDs de
## cuenta; solo publica alias, golpes y número de hoyos.
class_name RankingGolfOnline
extends Node

signal ranking_recibido(entradas: Array)
signal publicacion_completada(entrada: Dictionary)
signal error_online(motivo: String)

const RUTA_API := "/api/golf/ranking"

@export var endpoint_base := ""

var _http: HTTPRequest
var _operacion := ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_al_completar)


func configurar(url_base: String) -> void:
	endpoint_base = url_base.strip_edges().trim_suffix("/")


func disponible() -> bool:
	return not endpoint_base.is_empty() and _http != null


func obtener() -> bool:
	if not disponible():
		error_online.emit("ranking_online_no_configurado")
		return false
	_operacion = "obtener"
	var error := _http.request(endpoint_base + RUTA_API)
	if error != OK:
		_operacion = ""
		error_online.emit("ranking_online_solicitud_fallida")
		return false
	return true


func publicar(alias: String, golpes: int) -> bool:
	if not disponible():
		error_online.emit("ranking_online_no_configurado")
		return false
	var item := RankingGolf.entrada(alias, golpes)
	var valida := RankingGolf.registrar([], item, 1)
	if valida.is_empty():
		error_online.emit("ranking_online_puntuacion_invalida")
		return false
	var cabeceras := PackedStringArray(["Content-Type: application/json"])
	var cuerpo := (
		JSON
		. stringify(
			{
				"alias": String(item["alias"]),
				"golpes": int(item["golpes"]),
				"hoyos": int(item["hoyos"]),
			}
		)
	)
	_operacion = "publicar"
	var error := _http.request(endpoint_base + RUTA_API, cabeceras, HTTPClient.METHOD_POST, cuerpo)
	if error != OK:
		_operacion = ""
		error_online.emit("ranking_online_solicitud_fallida")
		return false
	return true


func _al_completar(
	resultado: int, codigo_respuesta: int, _cabeceras: PackedStringArray, cuerpo: PackedByteArray
) -> void:
	var operacion := _operacion
	_operacion = ""
	if resultado != HTTPRequest.RESULT_SUCCESS:
		error_online.emit("ranking_online_transporte_fallido")
		return
	if codigo_respuesta < 200 or codigo_respuesta >= 300:
		error_online.emit("ranking_online_http_%d" % codigo_respuesta)
		return
	var datos = JSON.parse_string(cuerpo.get_string_from_utf8())
	if operacion == "obtener":
		if not (datos is Array):
			error_online.emit("ranking_online_respuesta_invalida")
			return
		ranking_recibido.emit(datos)
		return
	if operacion == "publicar":
		if not (datos is Dictionary):
			error_online.emit("ranking_online_respuesta_invalida")
			return
		publicacion_completada.emit(datos)
