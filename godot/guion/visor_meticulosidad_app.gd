## Capa pasiva de #961 sobre los metadatos documentales.
##
## Observa gestos que ya existen en el visor. No muestra puntuación, no consume
## acciones y no descubre pistas críticas: solo conserva señales de atención
## para que otros sistemas opcionales, especialmente el sueño, puedan reaccionar.
extends "res://guion/visor_metadatos_app.gd"

var _scroll_meticulosidad: VScrollBar
var _documento_meticulosidad_id := ""


func _ready() -> void:
	super._ready()
	_conectar_scroll_meticulosidad()


func _al_elegir_documento(indice: int) -> void:
	var esperado: Dictionary = caso["registros"][indice]
	var esperado_id := String(esperado.get("id", ""))
	var era_leido := jornada.get("leidos_total", []).has(esperado_id)
	super._al_elegir_documento(indice)
	if String(registro_actual.get("id", "")) != esperado_id:
		return

	_documento_meticulosidad_id = esperado_id
	if era_leido:
		var motivo := "fecha" if not String(registro_actual.get("fecha", "")).is_empty() else "relectura"
		_registrar_meticulosidad(registro_actual, "relectura", motivo)


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_documento_meticulosidad_id = ""


func _al_marcar_folio() -> void:
	var registro_id := String(registro_actual.get("id", ""))
	var estaba_marcado := not registro_id.is_empty() and _marcadores_del_caso().has(registro_id)
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
	if Meticulosidad.registrar(jornada, registro_id, evento, motivo):
		_guardar_o_avisar()


func _registrar_meticulosidad_por_id(registro_id: String, evento: String, motivo: String) -> void:
	if registro_id.is_empty():
		return
	if Meticulosidad.registrar(jornada, registro_id, evento, motivo):
		_guardar_o_avisar()
