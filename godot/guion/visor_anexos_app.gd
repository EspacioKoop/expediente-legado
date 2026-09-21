## Segundo corte de #319: anexos documentales explícitos y examinables.
##
## Solo muestra anexos catalogados. Abrirlos no consume acción, no guarda estado,
## no descubre pistas y no altera acusación/careo.
extends "res://guion/visor_meticulosidad_app.gd"

const RUTA_ANEXOS := "res://datos/anexos_documentales.json"
const IdentidadExpedientes := preload("res://guion/visor_identidad_app.gd")

var _boton_anexo: Button
var _detalle_anexo: Label
var _catalogo_anexos: Dictionary = {}
var _anexo_abierto := false
var _identidad_expedientes := IdentidadExpedientes.new()


func _columna_documento() -> Control:
	var columna: Control = super._columna_documento()
	_identidad_expedientes.montar(columna, caso)

	_boton_anexo = Button.new()
	_boton_anexo.visible = false
	_boton_anexo.pressed.connect(_alternar_anexo)
	columna.add_child(_boton_anexo)

	_detalle_anexo = Label.new()
	_detalle_anexo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detalle_anexo.visible = false
	columna.add_child(_detalle_anexo)
	return columna


func _refrescar_archivo() -> void:
	super._refrescar_archivo()
	_identidad_expedientes.aplicar_archivo(_archivo, contenido.casos)


func _al_elegir_documento(indice: int) -> void:
	super._al_elegir_documento(indice)
	if not registro_actual.is_empty():
		_identidad_expedientes.mostrar_portada(false)
	_anexo_abierto = false
	_actualizar_anexo()


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_anexo_abierto = false
	_actualizar_anexo()
	_identidad_expedientes.actualizar(caso)
	_identidad_expedientes.mostrar_portada(true)


func _alternar_anexo() -> void:
	_anexo_abierto = not _anexo_abierto
	_actualizar_anexo()


func _actualizar_anexo() -> void:
	if _boton_anexo == null or _detalle_anexo == null:
		return
	var anexos := _anexos_actuales()
	if anexos.is_empty():
		_boton_anexo.visible = false
		_detalle_anexo.visible = false
		_detalle_anexo.text = ""
		return

	var anexo: Dictionary = anexos[0]
	var titulo := String(anexo.get("titulo", anexo.get("etiqueta", "")))
	_boton_anexo.visible = true
	_boton_anexo.text = ("▼ %s" if _anexo_abierto else "▶ %s") % titulo
	_detalle_anexo.text = String(anexo.get("contenido", ""))
	_detalle_anexo.visible = _anexo_abierto


func _anexos_actuales() -> Array:
	if registro_actual.is_empty():
		return []
	if _catalogo_anexos.is_empty():
		_catalogo_anexos = _cargar_catalogo()
	var registro_id := String(registro_actual.get("id", ""))
	var anexos: Variant = _catalogo_anexos.get(registro_id, [])
	if not anexos is Array:
		return []
	var ficha := {"anexos": anexos}
	if not AnexosDocumentales.es_valido(ficha):
		return []
	return AnexosDocumentales.anexos_de(ficha)


static func _cargar_catalogo() -> Dictionary:
	if not FileAccess.file_exists(RUTA_ANEXOS):
		return {}
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUTA_ANEXOS))
	if datos is Dictionary:
		return datos
	return {}
