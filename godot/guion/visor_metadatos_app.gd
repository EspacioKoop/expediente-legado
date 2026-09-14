## Tercera capa de profundidad de #286: metadatos examinables del folio.
##
## Solo presenta datos ya existentes en el registro (folio, tipo y fecha).
## No descubre pistas, no interpreta contenido y no altera acusación ni careo.
extends "res://guion/visor_anotaciones_app.gd"

var _metadatos: Label


func _columna_documento() -> Control:
	var columna: Control = super._columna_documento()
	_metadatos = Label.new()
	_metadatos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_metadatos.text = ""
	columna.add_child(_metadatos)
	return columna


func _al_elegir_documento(indice: int) -> void:
	super._al_elegir_documento(indice)
	_actualizar_metadatos()


func _al_elegir_caso(indice: int) -> void:
	super._al_elegir_caso(indice)
	_actualizar_metadatos()


func _actualizar_metadatos() -> void:
	if _metadatos == null:
		return
	_metadatos.text = _texto_metadatos(registro_actual)


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
