## Integra la ronda física de cierre con la jornada real (#156).
##
## La oferta aparece de forma determinista algunas tardes. Ignorarla o salir de
## la oficina nunca bloquea el ciclo diario; abandonar solo queda registrado en
## el mismo fragmento persistido que ya valida Partida.
extends Node

const HORA_OFERTA := 15 * 60
const CICLO_OFERTA := 3

var _fase_anterior := ""
var _mundo_id := 0
var _capa: RondaCierre3D


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var fase := String(dia.jornada.get("fase", ""))
	if _fase_anterior == "archivo" and fase != "archivo":
		_abandonar_si_pendiente(dia)
	_fase_anterior = fase

	if fase != "archivo":
		_capa = null
	else:
		_procesar_archivo(dia)


func _procesar_archivo(dia) -> void:
	var estado_var = dia.jornada.get("ronda_cierre", {})
	if typeof(estado_var) != TYPE_DICTIONARY:
		return
	var estado: Dictionary = estado_var

	if estado.is_empty():
		if Jornada.hora_minutos(dia.jornada) < HORA_OFERTA:
			return
		if not ofrecida(int(dia.jornada.get("dia", 1)), int(dia.jornada.get("raiz", 0))):
			return
		estado = Jornada.asegurar_ronda_cierre(dia.jornada, _cunado_presente(dia._mundo))
		_guardar(dia)

	if bool(estado.get("abandonada", false)) or bool(estado.get("finalizada", false)):
		return
	if bool(RondaCierre.progreso(estado).get("completa", false)):
		RondaCierre.finalizar(estado)
		_guardar(dia)
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if is_instance_valid(_capa) and _mundo_id == mundo_id:
		_capa.refrescar()
		return

	var existente := mundo.get_node_or_null(RondaCierre3D.NOMBRE_RAIZ) as RondaCierre3D
	if existente != null:
		_capa = existente
	else:
		_capa = RondaCierre3D.new()
		mundo.add_child(_capa)
		_capa.configurar(estado)
		_capa.punto_completado.connect(_al_completar_punto)
	_mundo_id = mundo_id

static func ofrecida(dia: int, raiz: int) -> bool:
	# Dos tardes de cada tres para una misma semilla. No usa RNG global y por
	# tanto guardar/recargar nunca cambia si hoy había ronda.
	return posmod(maxi(dia, 1) + raiz, CICLO_OFERTA) != 0


func _cunado_presente(mundo: Node3D) -> bool:
	for hijo in mundo.get_children():
		if not hijo is CompaneroInteractivo3D:
			continue
		var companero := hijo as CompaneroInteractivo3D
		var pies := companero.position - Vector3.UP * RondaCierre3D.ALTURA_CONVERSABLE
		if pies.distance_to(RondaCierre3D.POS_CUNADO) <= 0.2:
			return true
	return false


func _al_completar_punto(_id_punto: String) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var estado_var = dia.jornada.get("ronda_cierre", {})
	if typeof(estado_var) != TYPE_DICTIONARY:
		return
	var estado: Dictionary = estado_var
	if bool(RondaCierre.progreso(estado).get("completa", false)):
		RondaCierre.finalizar(estado)
	if is_instance_valid(_capa):
		_capa.refrescar()
	_guardar(dia)


func _abandonar_si_pendiente(dia) -> void:
	var estado_var = dia.jornada.get("ronda_cierre", {})
	if typeof(estado_var) != TYPE_DICTIONARY:
		return
	var estado: Dictionary = estado_var
	if estado.is_empty():
		return
	if bool(estado.get("finalizada", false)) or bool(estado.get("abandonada", false)):
		return
	RondaCierre.abandonar(estado)
	_guardar(dia)


func _guardar(dia) -> void:
	if dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
