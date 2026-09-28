## Ciclo de vida laboral del día (#1761).
##
## Posee las pantallas temporales de último recurso, auditorías de nueva vida y
## la cinemática de reincorporación. Las reglas siguen en Acusacion, Auditorias,
## Sellos, ClimaxHastur y EntradaCinematica; este nodo solo coordina presentación
## y devuelve a DiaApp la transición de reasignación.
class_name DiaCicloLaboralApp
extends Node

signal reasignacion_solicitada
signal vuelta_solicitada
signal vuelta_terminada

const SELLO_REINCORPORACION := "reincorporacion-administrativa"

var _partida: Partida
var _caminante: CharacterBody3D
var _hud: CanvasLayer
var _guardar: Callable
var _jornada: Dictionary = {}

var _entrada: Node3D
var _ultimo_recurso: UltimoRecursoApp
var _auditorias_nueva_vida: AuditoriasNuevaVidaApp


func configurar(
	partida: Partida,
	caminante: CharacterBody3D,
	hud: CanvasLayer,
	guardar: Callable,
) -> void:
	_partida = partida
	_caminante = caminante
	_hud = hud
	_guardar = guardar


## Devuelve true si la decisión bloqueante de vida cero quedó abierta.
func abrir_ultimo_recurso_pendiente(jornada: Dictionary) -> bool:
	_jornada = jornada
	if not Acusacion.despido_pendiente(_partida.estado):
		return false
	if is_instance_valid(_ultimo_recurso):
		_ultimo_recurso.actualizar(_partida.estado)
		return true
	if is_instance_valid(_caminante):
		_caminante.set_physics_process(false)
	_ultimo_recurso = UltimoRecursoApp.new()
	_ultimo_recurso.name = "UltimoRecurso"
	_ultimo_recurso.canje_solicitado.connect(_al_canjear_ultimo_recurso)
	_ultimo_recurso.cese_solicitado.connect(_al_aceptar_cese)
	add_child(_ultimo_recurso)
	_ultimo_recurso.abrir(_partida.estado)
	return true


func abrir_vuelta(jornada: Dictionary) -> void:
	_jornada = jornada
	if jornada["fase"] != "archivo" or jornada["dia"] != 1:
		return
	if jornada["acciones"] != Jornada.ACCIONES_POR_DIA:
		return
	if int(jornada.get("vuelta", 1)) > 1 and Auditorias.seleccion_pendiente(_partida.estado):
		_abrir_auditorias_nueva_vida()
		return

	_registrar_reincorporacion()
	_caminante.set_physics_process(false)
	_hud.visible = false

	_entrada = load("res://escenas/cinematica.tscn").instantiate()
	add_child(_entrada)
	_entrada.terminada.connect(_notificar_vuelta_terminada)
	var vistas := Cinematica.vistas_de(_partida.estado, EntradaCinematica.ID)
	(
		_entrada
		. reproducir(
			EntradaCinematica.planos_de(vistas),
			EntradaCinematica.ID,
			_partida.estado,
		)
	)


func _al_canjear_ultimo_recurso(carta_id: String) -> void:
	var resultado := Acusacion.canjear_carta_por_vida(_partida.estado, carta_id)
	if String(resultado.get("resultado", "")) != "canje":
		if is_instance_valid(_ultimo_recurso):
			_ultimo_recurso.actualizar(_partida.estado)
		return

	ClimaxHastur.reanudar_tras_ultimo_recurso(_partida.estado, _jornada)
	var guardado := bool(_guardar.call(""))
	_cerrar_ultimo_recurso()
	if not guardado:
		if is_instance_valid(_caminante):
			_caminante.set_physics_process(true)
		return

	var anfitrion := get_parent()
	var climax := anfitrion.get_node_or_null("ClimaxHasturOwnerController")
	if climax != null and climax.has_method("_reanudar_si_procede"):
		climax.call_deferred("_reanudar_si_procede")
	elif is_instance_valid(_caminante):
		_caminante.set_physics_process(true)


func _al_aceptar_cese() -> void:
	var resultado := Acusacion.aceptar_cese(_partida.estado, _jornada)
	if not bool(resultado.get("despido", false)):
		if is_instance_valid(_ultimo_recurso):
			_ultimo_recurso.actualizar(_partida.estado)
		return
	_guardar.call("")
	_cerrar_ultimo_recurso()
	reasignacion_solicitada.emit()


func _cerrar_ultimo_recurso() -> void:
	if is_instance_valid(_ultimo_recurso):
		_ultimo_recurso.queue_free()
	_ultimo_recurso = null


func _abrir_auditorias_nueva_vida() -> void:
	if is_instance_valid(_auditorias_nueva_vida):
		return
	if is_instance_valid(_caminante):
		_caminante.set_physics_process(false)
	if is_instance_valid(_hud):
		_hud.visible = false
	_auditorias_nueva_vida = AuditoriasNuevaVidaApp.new()
	_auditorias_nueva_vida.name = "AuditoriasNuevaVida"
	_auditorias_nueva_vida.seleccion_confirmada.connect(_confirmar_auditorias_nueva_vida)
	add_child(_auditorias_nueva_vida)
	_auditorias_nueva_vida.abrir(_partida.estado)


func _confirmar_auditorias_nueva_vida(seleccion: Array) -> void:
	var anterior := Dictionary(_partida.estado.get(Auditorias.CLAVE_ESTADO, {})).duplicate(true)
	if not Auditorias.resolver_seleccion(_partida.estado, seleccion):
		return
	if not bool(_guardar.call("")):
		_partida.estado[Auditorias.CLAVE_ESTADO] = anterior
		return
	if is_instance_valid(_auditorias_nueva_vida):
		_auditorias_nueva_vida.queue_free()
	_auditorias_nueva_vida = null
	vuelta_solicitada.emit()


func _registrar_reincorporacion() -> Dictionary:
	if int(_jornada.get("vuelta", 1)) <= 1:
		return {"resultado": "no-cumplido", "id": SELLO_REINCORPORACION}
	return Sellos.registrar_sello(_partida.estado, SELLO_REINCORPORACION)


func entrada_activa() -> bool:
	return is_instance_valid(_entrada)


func cerrar_vuelta() -> void:
	if not entrada_activa():
		return
	_entrada.queue_free()
	_entrada = null
	_caminante.set_physics_process(true)
	_hud.visible = true
	_guardar.call("")


func _notificar_vuelta_terminada() -> void:
	vuelta_terminada.emit()
