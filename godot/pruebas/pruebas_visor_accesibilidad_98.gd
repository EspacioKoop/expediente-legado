## Comprueba el texto accesible del visor con un folio real, sin abrir ni guardar
## una partida del usuario.
extends SceneTree

const Visor := preload("res://guion/visor_expediente.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var visor := Visor.new()
	visor.theme = EstiloSiga.tema()
	_comprobar(visor.contenido.cargar(), "carga el catálogo real de expedientes")
	visor.caso = visor.contenido.casos[0]
	visor.partida.estado = Partida.nueva()
	visor.jornada = Jornada.nueva(123)
	visor._construir()

	var archivo := visor._archivo as ItemList
	var lista := visor._lista as ItemList
	var documento := visor._documento as RichTextLabel
	_comprobar(archivo.accessibility_name == visor.tr("ARCHIVO_TITULO"), "identifica expedientes")
	_comprobar(lista.accessibility_name == visor.tr("VISOR_DOCUMENTOS"), "identifica folios")
	_comprobar(documento.focus_mode == Control.FOCUS_ALL, "permite enfocar el documento")
	_comprobar(documento.scroll_active, "permite recorrer documentos largos")

	var registro: Dictionary = visor.caso["registros"][3]
	_comprobar(String(registro["contenido"]).length() > 140, "acta real supera el extracto")
	visor._mostrar_registro(registro)
	_comprobar(documento.accessibility_name == visor._cabecera.text, "anuncia el folio abierto")
	_comprobar(
		documento.accessibility_description == documento.get_parsed_text(),
		"anuncia el contenido visible sin etiquetas BBCode",
	)
	_comprobar(
		documento.accessibility_description.contains(String(registro["contenido"]).right(50)),
		"conserva el final del acta fuera de un extracto de 140 caracteres",
	)

	visor._al_elegir_caso(1)
	_comprobar(
		documento.accessibility_description.is_empty(), "el otro caso no lee el acta anterior"
	)
	_comprobar(
		documento.accessibility_name == visor.tr("VISOR_ELIJA"),
		"el visor vuelve a pedir un documento",
	)
	_comprobar(visor.jornada.get("leido_hoy", []).is_empty(), "consultar no altera la jornada")

	visor.free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
