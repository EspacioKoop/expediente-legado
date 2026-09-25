extends SceneTree

const Editor := preload("res://debug/editor_expedientes.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_documento_valido()
	_probar_registro_compatible()
	_probar_roundtrip()
	_probar_validacion()
	_probar_bbcode_seguro()
	_probar_plantillas_qa()
	_probar_calendario()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _base() -> Dictionary:
	return {
		"id": "memo-prueba@1",
		"tipo": "memorando",
		"folio": "MEMO-1998-001",
		"fecha": "1998-04-17",
		"remitente": "Archivo General",
		"destino": "Contraloría",
		"asunto": "Cotejo de folio",
		"clasificacion": "INTERNO",
		"contenido_bbcode": "Texto [b]importante[/b] y [i]anotado[/i].",
		"sello": "RECIBIDO",
		"firma": "JEFATURA",
	}


func _probar_documento_valido() -> void:
	var datos := _base()
	_comprobar(Editor.validar(datos).is_empty(), "acepta un documento SIGA válido")
	var paquete: Dictionary = Editor.paquete_desde_datos(datos)
	_comprobar(paquete.get("formato", "") == Editor.FORMATO, "versiona el formato exportado")


func _probar_registro_compatible() -> void:
	var registro: Dictionary = Editor.registro_desde_datos(_base())
	_comprobar(registro.get("id", "") == "memo-prueba@1", "conserva id del registro")
	_comprobar(registro.get("tipo", "") == "MEMORANDO", "normaliza el tipo para el visor")
	_comprobar(registro.get("folio", "") == "MEMO-1998-001", "conserva folio visible")
	_comprobar(registro.get("fecha", "") == "1998-04-17", "conserva fecha compatible")
	var contenido := String(registro.get("contenido", ""))
	_comprobar(
		contenido_sin_formato(contenido),
		"el cuerpo compatible no filtra etiquetas de edición",
	)
	_comprobar(
		contenido.contains("DE: Archivo General") and contenido.contains("SELLO: RECIBIDO"),
		"materializa metadatos editoriales en el texto compatible",
	)
	var meta: Dictionary = registro.get("editor_meta", {})
	_comprobar(
		String(meta.get("contenido_bbcode", "")).contains("[b]importante[/b]"),
		"preserva la fuente enriquecida fuera del contrato canónico",
	)


func _probar_roundtrip() -> void:
	var original := _base()
	var reconstruido: Dictionary = Editor.datos_desde_paquete(Editor.paquete_desde_datos(original))
	_comprobar(reconstruido.get("id", "") == original["id"], "roundtrip conserva identidad")
	_comprobar(
		reconstruido.get("contenido_bbcode", "") == original["contenido_bbcode"],
		"roundtrip conserva formato de autoría",
	)
	_comprobar(
		Editor.datos_desde_paquete({"formato": "desconocido", "registro": {}}).is_empty(),
		"rechaza formatos desconocidos sin excepción",
	)


func _probar_validacion() -> void:
	var fecha_rota := _base()
	fecha_rota["fecha"] = "1998-14-99"
	_comprobar(not Editor.validar(fecha_rota).is_empty(), "rechaza fechas fuera de rango")
	var id_roto := _base()
	id_roto["id"] = "../../casos"
	_comprobar(
		not Editor.validar(id_roto).is_empty(), "rechaza ids capaces de escapar del directorio"
	)
	var vacio := _base()
	vacio["contenido_bbcode"] = "[b][/b]"
	_comprobar(not Editor.validar(vacio).is_empty(), "rechaza un cuerpo vacío aunque tenga formato")


func _probar_bbcode_seguro() -> void:
	var datos := _base()
	datos["contenido_bbcode"] = "[b]válido[/b] [url=https://example.invalid]no[/url]"
	var vista: String = Editor.vista_bbcode(datos)
	_comprobar(vista.contains("[b]válido[/b]"), "la vista previa conserva el formato permitido")
	_comprobar(
		vista.contains("[lb]url=https://example.invalid]") and not vista.contains("[url=https://"),
		"la vista previa neutraliza BBCode no permitido",
	)


func _probar_plantillas_qa() -> void:
	_comprobar(Editor.PLANTILLAS.size() == 3, "incluye tres familias para validación humana")
	var oficial := Editor.datos_plantilla(0)
	var interno := Editor.datos_plantilla(1)
	var personal := Editor.datos_plantilla(2)
	_comprobar(oficial.get("tipo", "") == "OFICIO", "plantilla oficial cubre oficio")
	_comprobar(
		interno.get("clasificacion", "") == "INTERNO", "plantilla interna conserva clasificación"
	)
	_comprobar(personal.get("tipo", "") == "NOTA", "plantilla personal cubre nota")
	_comprobar(Editor.validar(oficial).is_empty(), "plantilla oficial es exportable")
	_comprobar(Editor.validar(interno).is_empty(), "plantilla interna es exportable")
	_comprobar(Editor.validar(personal).is_empty(), "plantilla personal es exportable")
	var recargado := Editor.datos_desde_paquete(Editor.paquete_desde_datos(personal))
	_comprobar(
		recargado.get("asunto", "") == personal["asunto"],
		"plantilla personal conserva metadatos al recargar"
	)


func _probar_calendario() -> void:
	var imposible := _base()
	imposible["fecha"] = "1998-02-31"
	_comprobar(not Editor.validar(imposible).is_empty(), "rechaza fechas inexistentes")
	var bisiesto := _base()
	bisiesto["fecha"] = "1996-02-29"
	_comprobar(Editor.validar(bisiesto).is_empty(), "acepta 29 de febrero en año bisiesto")
	var no_bisiesto := _base()
	no_bisiesto["fecha"] = "1999-02-29"
	_comprobar(
		not Editor.validar(no_bisiesto).is_empty(), "rechaza 29 de febrero fuera de bisiesto"
	)


func contenido_sin_formato(contenido: String) -> bool:
	return contenido.contains("Texto importante y anotado.") and not contenido.contains("[b]")


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO editor #953: " + nombre)
