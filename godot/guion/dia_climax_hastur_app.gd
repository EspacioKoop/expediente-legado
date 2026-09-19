## Dueño de campaña del clímax de Hastur (#1103).
##
## Escucha el handoff de OS98 pero no lee su estado privado. Persiste antes de
## abandonar el puesto, monta una confrontación propia y publica un contrato
## para el final político. El handoff sigue siendo transporte, no gameplay.
extends Node

signal final_politico_pendiente(contexto: Dictionary)

const REINTENTO_GUARDADO := 0.5

var _handoff: Node
var _capa: CanvasLayer
var _panel: ClimaxHasturPanel
var _capa_final: CanvasLayer
var _panel_final: FinalPoliticoPanel
var _esperando_guardado := false
var _accion_despues_guardar := ""
var _reintento_restante := 0.0


func _ready() -> void:
	call_deferred("_conectar_handoff")


func _exit_tree() -> void:
	var callback := Callable(self, "_al_handoff")
	if (
		is_instance_valid(_handoff)
		and (
			_handoff
			. is_connected(
				"climax_hastur_pendiente",
				callback,
			)
		)
	):
		_handoff.disconnect("climax_hastur_pendiente", callback)


func _process(delta: float) -> void:
	if not _esperando_guardado:
		return
	_reintento_restante -= delta
	if _reintento_restante > 0.0:
		return

	var dia := get_parent()
	if dia == null:
		return
	if _guardar(dia):
		_esperando_guardado = false
		var accion := _accion_despues_guardar
		_accion_despues_guardar = ""
		_despues_de_guardar(accion)
	else:
		_reintento_restante = REINTENTO_GUARDADO


func _conectar_handoff() -> void:
	var dia := get_parent()
	if dia == null:
		return
	var handoff := dia.get_node_or_null("ClimaxOs98Controller")
	if handoff == null or not handoff.has_signal("climax_hastur_pendiente"):
		return

	var callback := Callable(self, "_al_handoff")
	if not handoff.is_connected("climax_hastur_pendiente", callback):
		handoff.connect("climax_hastur_pendiente", callback)
	_handoff = handoff
	_reanudar_si_procede()


func _al_handoff(contexto: Dictionary) -> void:
	var dia := get_parent()
	var partida_actual := _partida(dia)
	if dia == null or partida_actual == null:
		return

	var cargas := {}
	var historias_actual = dia.get("historias")
	if historias_actual is Historias:
		cargas = historias_actual.cargas(partida_actual.estado)

	var resultado := (
		ClimaxHastur
		. iniciar(
			partida_actual.estado,
			dia.get("jornada"),
			contexto,
			cargas,
		)
	)
	if String(resultado.get("resultado", "")) == "sin_handoff":
		return
	_guardar_y_luego(dia, "activar")


func _reanudar_si_procede() -> void:
	var dia := get_parent()
	var partida_actual := _partida(dia)
	if dia == null or partida_actual == null:
		return
	var actual := ClimaxHastur.estado_actual(partida_actual.estado, dia.get("jornada"))
	if actual.is_empty():
		return
	_activar_estado()


func _activar_estado() -> void:
	var dia := get_parent()
	var partida_actual := _partida(dia)
	if dia == null or partida_actual == null:
		return

	_cerrar_puesto(dia)
	var actual := ClimaxHastur.estado_actual(partida_actual.estado, dia.get("jornada"))
	match String(actual.get("fase", "")):
		ClimaxHastur.FASE_COMBATE, ClimaxHastur.FASE_VICTORIA, ClimaxHastur.FASE_DERROTA:
			_mostrar_panel(dia, actual)
		ClimaxHastur.FASE_FINAL:
			_publicar_final(dia)
		_:
			_habilitar_movimiento(dia, true)


func _mostrar_panel(dia: Node, actual: Dictionary) -> void:
	if is_instance_valid(_capa):
		return
	_habilitar_movimiento(dia, false)

	_capa = CanvasLayer.new()
	_capa.name = "ClimaxHasturCapa"
	_capa.layer = 80
	dia.add_child(_capa)

	_panel = ClimaxHasturPanel.new()
	_panel.name = "ClimaxHasturPanel"
	_panel.configurar(actual)
	_panel.jugada_solicitada.connect(_al_jugada)
	_panel.continuar_solicitado.connect(_al_continuar)
	_capa.add_child(_panel)


func _al_jugada(tipo: String, habilidad: String) -> void:
	var dia := get_parent()
	var partida_actual := _partida(dia)
	if dia == null or partida_actual == null:
		return
	var resultado := (
		ClimaxHastur
		. jugar(
			partida_actual.estado,
			dia.get("jornada"),
			tipo,
			habilidad,
		)
	)
	if is_instance_valid(_panel):
		_panel.refrescar(resultado.get("ronda", {}))
	_guardar_y_luego(dia, "ronda")


func _al_continuar() -> void:
	var dia := get_parent()
	var partida_actual := _partida(dia)
	if dia == null or partida_actual == null:
		return
	var jornada: Dictionary = dia.get("jornada")
	var actual := ClimaxHastur.estado_actual(partida_actual.estado, jornada)
	var fase := String(actual.get("fase", ""))

	if fase == ClimaxHastur.FASE_VICTORIA:
		if ClimaxHastur.confirmar_victoria(partida_actual.estado, jornada):
			_guardar_y_luego(dia, "victoria")
		return

	if fase != ClimaxHastur.FASE_DERROTA:
		return
	var consecuencia := ClimaxHastur.aplicar_derrota(partida_actual.estado, jornada)
	var accion := (
		"derrota_despido" if bool(consecuencia.get("despido", false)) else "derrota_reintento"
	)
	_guardar_y_luego(dia, accion)


func _guardar_y_luego(dia: Node, accion: String) -> void:
	if _guardar(dia):
		_despues_de_guardar(accion)
		return

	_esperando_guardado = true
	_accion_despues_guardar = accion
	_reintento_restante = REINTENTO_GUARDADO
	if is_instance_valid(_panel):
		_panel.bloquear(true)
	if is_instance_valid(_panel_final) and is_instance_valid(_panel_final._boton):
		_panel_final._boton.disabled = true


func _despues_de_guardar(accion: String) -> void:
	if is_instance_valid(_panel):
		_panel.bloquear(false)
	if is_instance_valid(_panel_final) and is_instance_valid(_panel_final._boton):
		_panel_final._boton.disabled = false
	match accion:
		"activar":
			_activar_estado()
		"victoria":
			_cerrar_panel()
			_publicar_final(get_parent())
		"derrota_reintento":
			var dia := get_parent()
			var partida_actual := _partida(dia)
			_cerrar_panel()
			if dia != null and partida_actual != null:
				var actual := (
					ClimaxHastur
					. estado_actual(
						partida_actual.estado,
						dia.get("jornada"),
					)
				)
				_mostrar_panel(dia, actual)
		"derrota_despido":
			_cerrar_panel()
			_reconstruir_vuelta(get_parent())
		"final_cerrado":
			_cerrar_final()


func _publicar_final(dia: Node) -> void:
	var partida_actual := _partida(dia)
	if dia == null or partida_actual == null:
		return
	var contrato := (
		ClimaxHastur
		. contrato_final(
			partida_actual.estado,
			dia.get("jornada"),
		)
	)
	dia.set_meta("climax_hastur_final_politico", contrato.duplicate(true))
	final_politico_pendiente.emit(contrato.duplicate(true))
	if not bool(contrato.get("pendiente", false)):
		_habilitar_movimiento(dia, true)
		return
	if bool(partida_actual.estado.get("final_politico_mostrado", false)):
		_habilitar_movimiento(dia, true)
		return
	_mostrar_final(dia, contrato)


func _mostrar_final(dia: Node, contrato: Dictionary) -> void:
	if is_instance_valid(_capa_final):
		return
	var partida_actual := _partida(dia)
	if partida_actual == null:
		return
	_habilitar_movimiento(dia, false)

	_capa_final = CanvasLayer.new()
	_capa_final.name = "FinalPoliticoCapa"
	_capa_final.layer = 81
	dia.add_child(_capa_final)

	_panel_final = FinalPoliticoPanel.new()
	_panel_final.name = "FinalPoliticoPanel"
	_panel_final.configurar(FinalPolitico.resumen(partida_actual.estado, contrato))
	_panel_final.continuar_solicitado.connect(_al_cerrar_final)
	_capa_final.add_child(_panel_final)


func _al_cerrar_final() -> void:
	var dia := get_parent()
	var partida_actual := _partida(dia)
	if dia == null or partida_actual == null:
		return
	FinalPolitico.confirmar_cierre(partida_actual.estado)
	var actual := ClimaxHastur.estado_actual(partida_actual.estado, dia.get("jornada"))
	if not actual.is_empty():
		actual["final_politico_pendiente"] = false
	_guardar_y_luego(dia, "final_cerrado")


func _cerrar_final() -> void:
	var dia := get_parent()
	if is_instance_valid(_capa_final):
		_capa_final.queue_free()
	_capa_final = null
	_panel_final = null
	_habilitar_movimiento(dia, true)


func _reconstruir_vuelta(dia: Node) -> void:
	if dia == null:
		return
	_habilitar_movimiento(dia, true)
	if dia.has_method("_entrar_en"):
		var jornada: Dictionary = dia.get("jornada")
		dia.call("_entrar_en", String(jornada.get("fase", "archivo")))
	if dia.has_method("_abrir_vuelta"):
		dia.call("_abrir_vuelta")


func _cerrar_puesto(dia: Node) -> void:
	var pantalla = dia.get("_pantalla")
	if pantalla != null and is_instance_valid(pantalla) and dia.has_method("_cerrar_expediente"):
		dia.call("_cerrar_expediente")


func _cerrar_panel() -> void:
	var dia := get_parent()
	if is_instance_valid(_capa):
		_capa.queue_free()
	_capa = null
	_panel = null
	_habilitar_movimiento(dia, true)


func _habilitar_movimiento(dia: Node, habilitado: bool) -> void:
	if dia == null:
		return
	var caminante = dia.get("_caminante")
	if caminante is CharacterBody3D:
		caminante.set_physics_process(habilitado)


func _guardar(dia: Node) -> bool:
	if dia == null:
		return false
	if dia.has_method("_guardar_o_avisar"):
		return bool(dia.call("_guardar_o_avisar", ""))
	var partida_actual := _partida(dia)
	return partida_actual.guardar() if partida_actual != null else false


func _partida(dia: Node) -> Partida:
	if dia == null:
		return null
	var partida_actual = dia.get("partida")
	return partida_actual if partida_actual is Partida else null
