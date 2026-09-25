## Tercera capa de profundidad de #286: metadatos examinables del folio.
##
## Solo presenta datos ya existentes en el registro (folio, tipo y fecha).
## #961 observa aquí gestos deliberados ya disponibles, sin barra visible y sin
## descubrir pistas críticas ni alterar acusación/careo.
extends "res://guion/visor_anotaciones_app.gd"

const MeticulosidadEstado := preload("res://guion/meticulosidad.gd")
const FalsificacionDocumentalModelo := preload("res://guion/falsificacion_documental.gd")
const DetallesMeticulosidadCatalogo := preload("res://guion/detalles_meticulosidad.gd")
const RUTA_DETALLES_METICULOSIDAD := "res://datos/detalles_meticulosidad.json"
const RUTA_ANALISIS_DOCUMENTAL := "res://datos/analisis_documental.json"
const CLAVES_CALIDAD_FALSIFICACION := {
	"baja": "VISOR_FALSIFICACION_951_CALIDAD_BAJA",
	"media": "VISOR_FALSIFICACION_951_CALIDAD_MEDIA",
	"alta": "VISOR_FALSIFICACION_951_CALIDAD_ALTA",
}
const CLAVES_RIESGO_FALSIFICACION := {
	"alto": "VISOR_FALSIFICACION_951_RIESGO_ALTO",
	"medio": "VISOR_FALSIFICACION_951_RIESGO_MEDIO",
	"bajo": "VISOR_FALSIFICACION_951_RIESGO_BAJO",
}
const CLAVES_ANALISIS_DOCUMENTAL := [
	"VISOR_ANALISIS_951_FACTURA4_SELLO",
	"VISOR_ANALISIS_951_FACTURA4_RFC",
	"VISOR_ANALISIS_951_ACTA6_SELLO",
	"VISOR_ANALISIS_951_CIRCULAR6_FECHA",
	"VISOR_ANALISIS_951_MEMO5_FECHA",
]

var _metadatos: Label
var _detalle_meticulosidad: Label
var _scroll_meticulosidad: VScrollBar
var _documento_meticulosidad_id := ""
var _catalogo_detalles_meticulosidad: Dictionary = {}
var _analizar_documento: Button
var _resultado_analisis: Label
var _catalogo_analisis_documental: Dictionary = {}
var _selector_falsificacion: OptionButton
var _crear_falsificacion: Button
var _resultado_falsificacion: Label
var _borrador_falsificacion: Dictionary = {}


func _columna_documento() -> Control:
	var columna: Control = super._columna_documento()
	_metadatos = Label.new()
	_metadatos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_metadatos.text = ""
	columna.add_child(_metadatos)

	_detalle_meticulosidad = Label.new()
	_detalle_meticulosidad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detalle_meticulosidad.visible = false
	_detalle_meticulosidad.text = ""
	columna.add_child(_detalle_meticulosidad)

	_analizar_documento = Button.new()
	_analizar_documento.text = tr("VISOR_ANALISIS_951_ACCION")
	_analizar_documento.tooltip_text = tr("VISOR_ANALISIS_951_AYUDA")
	_analizar_documento.disabled = true
	_analizar_documento.pressed.connect(_analizar_documento_actual)
	columna.add_child(_analizar_documento)

	_resultado_analisis = Label.new()
	_resultado_analisis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resultado_analisis.visible = false
	_resultado_analisis.text = ""
	columna.add_child(_resultado_analisis)

	_selector_falsificacion = OptionButton.new()
	_selector_falsificacion.add_item(tr("VISOR_FALSIFICACION_951_FECHA"))
	_selector_falsificacion.set_item_metadata(0, "fecha")
	_selector_falsificacion.add_item(tr("VISOR_FALSIFICACION_951_SELLO"))
	_selector_falsificacion.set_item_metadata(1, "sello")
	_selector_falsificacion.add_item(tr("VISOR_FALSIFICACION_951_FIRMA"))
	_selector_falsificacion.set_item_metadata(2, "firma")
	_selector_falsificacion.disabled = true
	columna.add_child(_selector_falsificacion)

	_crear_falsificacion = Button.new()
	_crear_falsificacion.text = tr("VISOR_FALSIFICACION_951_ACCION")
	_crear_falsificacion.tooltip_text = tr("VISOR_FALSIFICACION_951_AYUDA")
	_crear_falsificacion.disabled = true
	_crear_falsificacion.pressed.connect(_crear_copia_falsificada)
	columna.add_child(_crear_falsificacion)

	_resultado_falsificacion = Label.new()
	_resultado_falsificacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resultado_falsificacion.visible = false
	_resultado_falsificacion.text = ""
	columna.add_child(_resultado_falsificacion)

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

	_reiniciar_analisis_documental()
	_reiniciar_falsificacion_documental()
	_documento_meticulosidad_id = esperado_id
	if era_leido:
		var motivo := (
			"fecha" if not String(registro_actual.get("fecha", "")).is_empty() else "relectura"
		)
		_registrar_meticulosidad(registro_actual, "relectura", motivo)


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_documento_meticulosidad_id = ""
	_reiniciar_analisis_documental()
	_reiniciar_falsificacion_documental()
	_actualizar_metadatos()


func _al_marcar_folio() -> void:
	var registro_id := String(registro_actual.get("id", ""))
	var estaba_marcado: bool = (
		not registro_id.is_empty() and _marcadores_del_caso().has(registro_id)
	)
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
	if _analizar_documento != null:
		_analizar_documento.disabled = registro_actual.is_empty()
	if _selector_falsificacion != null:
		_selector_falsificacion.disabled = registro_actual.is_empty()
	if _crear_falsificacion != null:
		_crear_falsificacion.disabled = registro_actual.is_empty()
	_actualizar_detalles_meticulosidad()


func _reiniciar_falsificacion_documental() -> void:
	_borrador_falsificacion = {}
	if _resultado_falsificacion == null:
		return
	_resultado_falsificacion.text = ""
	_resultado_falsificacion.visible = false


func _crear_copia_falsificada() -> void:
	if (
		registro_actual.is_empty()
		or _selector_falsificacion == null
		or _resultado_falsificacion == null
	):
		return
	var intervencion := String(_selector_falsificacion.get_selected_metadata())
	_borrador_falsificacion = FalsificacionDocumentalModelo.crear_copia(
		registro_actual,
		intervencion,
		MeticulosidadEstado.puntos(jornada),
	)
	if _borrador_falsificacion.is_empty():
		return

	var calidad := String(_borrador_falsificacion.get("calidad", "baja"))
	var riesgo := String(_borrador_falsificacion.get("riesgo", "alto"))
	_resultado_falsificacion.text = (
		tr("VISOR_FALSIFICACION_951_RESULTADO")
		% [
			tr(String(CLAVES_CALIDAD_FALSIFICACION.get(calidad, ""))),
			tr(String(CLAVES_RIESGO_FALSIFICACION.get(riesgo, ""))),
		]
	)
	_resultado_falsificacion.visible = true


func _reiniciar_analisis_documental() -> void:
	if _resultado_analisis == null:
		return
	_resultado_analisis.text = ""
	_resultado_analisis.visible = false


func _analizar_documento_actual() -> void:
	if registro_actual.is_empty() or _resultado_analisis == null:
		return
	if _catalogo_analisis_documental.is_empty():
		_catalogo_analisis_documental = _cargar_catalogo_analisis_documental()

	var registro_id := String(registro_actual.get("id", "")).strip_edges()
	var entradas: Variant = _catalogo_analisis_documental.get(registro_id, [])
	var textos: Array[String] = []
	if entradas is Array:
		for valor in entradas:
			if not valor is Dictionary:
				continue
			var clave := String((valor as Dictionary).get("texto", "")).strip_edges()
			if CLAVES_ANALISIS_DOCUMENTAL.has(clave):
				textos.append(tr(clave))

	if textos.is_empty():
		_resultado_analisis.text = tr("VISOR_ANALISIS_951_SIN_HALLAZGOS")
	else:
		_resultado_analisis.text = tr("VISOR_ANALISIS_951_RESULTADO") % "\n".join(textos)
	_resultado_analisis.visible = true


static func _cargar_catalogo_analisis_documental() -> Dictionary:
	if not FileAccess.file_exists(RUTA_ANALISIS_DOCUMENTAL):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_ANALISIS_DOCUMENTAL))
	if datos is Dictionary:
		return datos
	return {}


func _actualizar_detalles_meticulosidad() -> void:
	if _detalle_meticulosidad == null:
		return
	var detalles := _detalles_meticulosidad_actuales()
	if detalles.is_empty():
		_detalle_meticulosidad.text = ""
		_detalle_meticulosidad.visible = false
		return

	var textos: Array[String] = []
	for detalle in detalles:
		var clave := String(detalle.get("texto", "")).strip_edges()
		if not clave.is_empty():
			textos.append(tr(clave))
	if textos.is_empty():
		_detalle_meticulosidad.text = ""
		_detalle_meticulosidad.visible = false
		return
	_detalle_meticulosidad.text = tr("VISOR_DETALLE_961_OBSERVACION") % "\n".join(textos)
	_detalle_meticulosidad.visible = true


func _detalles_meticulosidad_actuales() -> Array[Dictionary]:
	if registro_actual.is_empty():
		return []
	if _catalogo_detalles_meticulosidad.is_empty():
		_catalogo_detalles_meticulosidad = _cargar_catalogo_detalles_meticulosidad()
	var registro_id := String(registro_actual.get("id", "")).strip_edges()
	return (
		DetallesMeticulosidadCatalogo
		. visibles(
			_catalogo_detalles_meticulosidad,
			jornada,
			registro_id,
		)
	)


static func _cargar_catalogo_detalles_meticulosidad() -> Dictionary:
	if not FileAccess.file_exists(RUTA_DETALLES_METICULOSIDAD):
		return {}
	var datos: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(RUTA_DETALLES_METICULOSIDAD)
	)
	if datos is Dictionary:
		return datos
	return {}


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
		_actualizar_detalles_meticulosidad()


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
