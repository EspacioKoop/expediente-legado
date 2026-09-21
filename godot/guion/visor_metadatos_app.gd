## Tercera capa de profundidad de #286: metadatos examinables del folio.
##
## Solo presenta datos ya existentes en el registro (folio, tipo y fecha).
## #961 observa aquí gestos deliberados ya disponibles, sin barra visible y sin
## descubrir pistas críticas ni alterar acusación/careo.
extends "res://guion/visor_anotaciones_app.gd"

const MeticulosidadEstado := preload("res://guion/meticulosidad.gd")

var _metadatos: Label
var _scroll_meticulosidad: VScrollBar
var _documento_meticulosidad_id := ""


func _columna_documento() -> Control:
	var columna: Control = super._columna_documento()
	_metadatos = Label.new()
	_metadatos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_metadatos.text = ""
	columna.add_child(_metadatos)
	_conectar_scroll_meticulosidad()
	return columna


func _al_elegir_documento(indice: int) -> void:
	var esperado: Dictionary = caso["registros"][indice]
	var esperado_id := String(esperado.get("id", ""))
	var era_leido: bool = jornada.get("leidos_total", []).has(esperado_id)
	super._al_elegir_documento(indice)
	_actualizar_metadatos()
	if String(registro_actual.get("id", "")) != esperado_id:
		return

	_documento_meticulosidad_id = esperado_id
	if era_leido:
		var motivo := (
			"fecha" if not String(registro_actual.get("fecha", "")).is_empty() else "relectura"
		)
		_registrar_meticulosidad(registro_actual, "relectura", motivo)


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_documento_meticulosidad_id = ""
	_actualizar_metadatos()


func _al_marcar_folio() -> void:
	var registro_id := String(registro_actual.get("id", ""))
	var estaba_marcado: bool = (\n\t\tnot registro_id.is_empty() and _marcadores_del_caso().has(registro_id)\n\t)
	super._al_marcar_folio()
	if (
		not registro_id.is_empty()
		and not estaba_marcado
		and _marcadores_del_caso().has(registro_id)
	):
		_registrar_meticulosidad(registro_actual, "marcador", "folio")


func _al_relacionar() -> void:
	var primero := _origen_relacion
	var actual := String(registro_actual.get("id", ""))
	super._al_relacionar()
	if primero.is_empty() or actual.is_empty() or primero == actual:
		return
	# El segundo gesto termina el intento tanto si la relación está catalogada
	# como si no. La atención está en comparar, no en acertar.
	if _origen_relacion.is_empty():
		_registrar_meticulosidad_por_id(primero, "relacion", "relacion")
		_registrar_meticulosidad(registro_actual, "relacion", "relacion")


func _actualizar_metadatos() -> void:
	if _metadatos == null:
		return
	_metadatos.text = _texto_metadatos(registro_actual)


func _conectar_scroll_meticulosidad() -> void:
	if _documento == null:
		return
	_scroll_meticulosidad = _documento.get_v_scroll_bar()
	if (
		_scroll_meticulosidad != null
		and not _scroll_meticulosidad.value_changed.is_connected(_al_desplazar_documento)
	):
		_scroll_meticulosidad.value_changed.connect(_al_desplazar_documento)


func _al_desplazar_documento(_valor: float) -> void:
	if _scroll_meticulosidad == null or _documento_meticulosidad_id.is_empty():
		return
	if _scroll_meticulosidad.max_value <= _scroll_meticulosidad.page + 1.0:
		return
	if (
		_scroll_meticulosidad.value + _scroll_meticulosidad.page
		< _scroll_meticulosidad.max_value - 2.0
	):
		return
	_registrar_meticulosidad(registro_actual, "lectura_completa", "margen")


func _registrar_meticulosidad(registro: Dictionary, evento: String, motivo: String) -> void:
	var registro_id := String(registro.get("id", ""))
	if registro_id.is_empty():
		return
	if MeticulosidadEstado.registrar(jornada, registro_id, evento, motivo):
		_guardar_o_avisar()


func _registrar_meticulosidad_por_id(registro_id: String, evento: String, motivo: String) -> void:
	if registro_id.is_empty():
		return
	if MeticulosidadEstado.registrar(jornada, registro_id, evento, motivo):
		_guardar_o_avisar()


static func _texto_metadatos(registro: Dictionary) -> String:
	if registro.is_empty():
		return ""
	var folio := String(registro.get("folio", ""))
	var tipo := String(registro.get("tipo", ""))
	var fecha := String(registro.get("fecha", ""))
	var partes: Array[String] = []
	for valor in [folio, tipo, fecha]:
		if not valor.is_empty():
			partes.append(valor)
	return " · ".join(partes)
