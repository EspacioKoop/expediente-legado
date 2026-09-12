## Segunda capa de profundidad de #286: marcadores personales sobre folios leídos.
##
## El marcador no descubre pistas, no cambia culpables y no decide nada por el
## jugador. Solo conserva qué documentos quiso recordar dentro de cada caso.
extends "res://guion/visor_combinaciones_app.gd"

const CLAVE_MARCADORES := "marcadores_folios"

var _marcar: Button


func _columna_documento() -> Control:
	var columna: Control = super._columna_documento()
	_marcar = Button.new()
	_marcar.text = tr("VISOR_MARCAR_FOLIO")
	_marcar.disabled = true
	_marcar.pressed.connect(_al_marcar_folio)
	columna.add_child(_marcar)
	return columna


func _al_elegir_documento(indice: int) -> void:
	super._al_elegir_documento(indice)
	_actualizar_boton_marcador()


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_actualizar_boton_marcador()


func _al_marcar_folio() -> void:
	if registro_actual.is_empty() or caso.is_empty() or _hay_guardado_a_medias():
		return
	var registro_id := String(registro_actual.get("id", ""))
	if registro_id.is_empty() or not _esta_leido(registro_id):
		return

	var marcadores := _marcadores_del_caso()
	if marcadores.has(registro_id):
		marcadores.erase(registro_id)
		_estado.text = tr("VISOR_MARCADOR_RETIRADO")
	else:
		marcadores.append(registro_id)
		_estado.text = tr("VISOR_MARCADOR_GUARDADO")
	_guardar_marcadores_del_caso(marcadores)
	_guardar_o_avisar()
	_actualizar_boton_marcador()


func _marcadores_del_caso() -> Array:
	if caso.is_empty():
		return []
	var todos: Dictionary = jornada.get(CLAVE_MARCADORES, {})
	return todos.get(String(caso["id"]), []).duplicate()


func _guardar_marcadores_del_caso(marcadores: Array) -> void:
	var todos: Dictionary = jornada.get(CLAVE_MARCADORES, {}).duplicate(true)
	var caso_id := String(caso["id"])
	if marcadores.is_empty():
		todos.erase(caso_id)
	else:
		todos[caso_id] = marcadores
	jornada[CLAVE_MARCADORES] = todos


func _actualizar_boton_marcador() -> void:
	if _marcar == null:
		return
	var registro_id := String(registro_actual.get("id", ""))
	_marcar.disabled = registro_id.is_empty() or not _esta_leido(registro_id)
	if not _marcar.disabled and _marcadores_del_caso().has(registro_id):
		_marcar.text = tr("VISOR_QUITAR_MARCADOR")
	else:
		_marcar.text = tr("VISOR_MARCAR_FOLIO")
