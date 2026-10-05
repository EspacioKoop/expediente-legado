## Panel diegético para la vertical de La Entrada 49 (#2477).
##
## Recibe el estado ya propiedad de DiaApp y un callback de guardado. No conoce
## Partida ni Jornada y no decide progresión fuera de la política Entrada49.
class_name Entrada49Panel
extends RefCounted

const RUTA := "res://datos/entrada49.json"
const CLAVE_ESTADO := "entrada49"


static func montar(pantalla: CanvasLayer, estado: Dictionary, guardar: Callable) -> Button:
	var acceso := Button.new()
	acceso.name = "Entrada49Acceso"
	acceso.text = "Entrada 49"
	acceso.theme = EstiloSiga.tema()
	acceso.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	acceso.offset_left = -190
	acceso.offset_top = -52
	acceso.offset_right = -8
	acceso.offset_bottom = -8
	acceso.pressed.connect(_abrir.bind(pantalla, estado, guardar))
	pantalla.add_child(acceso)
	return acceso


static func _abrir(pantalla: CanvasLayer, estado: Dictionary, guardar: Callable) -> void:
	if pantalla.get_node_or_null("Entrada49Panel") != null:
		return
	var datos := _cargar()
	if datos.is_empty():
		return

	var fondo := PanelContainer.new()
	fondo.name = "Entrada49Panel"
	fondo.theme = EstiloSiga.tema()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	fondo.offset_left = -310
	fondo.offset_top = -190
	fondo.offset_right = 310
	fondo.offset_bottom = 190
	pantalla.add_child(fondo)

	var columna := VBoxContainer.new()
	fondo.add_child(columna)

	var titulo := Label.new()
	titulo.text = "IMPORTACIÓN PATRIMONIAL · ENTRADA 49"
	columna.add_child(titulo)

	var analisis := Entrada49.analizar_fuentes(datos)
	var resumen := Label.new()
	resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resumen.text = (
		"Fuentes cotejadas: %d\nTrabajadores consignados: %d\nRaciones registradas: %d\n"
		% [
			int(analisis.get("fuentes_validas", 0)),
			int(analisis.get("trabajadores", 0)),
			int(analisis.get("raciones", 0)),
		]
	)
	columna.add_child(resumen)

	var estado_previo: Dictionary = estado.get(CLAVE_ESTADO, {})
	var resultado := Label.new()
	resultado.name = "Resultado"
	resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resultado.text = _texto_resultado(estado_previo)
	columna.add_child(resultado)

	var fila := HBoxContainer.new()
	columna.add_child(fila)
	for decision in Entrada49.DECISIONES:
		var boton := Button.new()
		boton.text = _etiqueta(decision)
		boton.pressed.connect(_decidir.bind(datos, estado, guardar, resultado, decision))
		fila.add_child(boton)

	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(fondo.queue_free)
	columna.add_child(cerrar)


static func _decidir(
	datos: Dictionary,
	estado: Dictionary,
	guardar: Callable,
	resultado: Label,
	decision: String,
) -> void:
	var resolucion := Entrada49.procesar_importacion(datos, decision)
	if not bool(resolucion.get("ok", false)):
		return
	estado[CLAVE_ESTADO] = resolucion
	if guardar.is_valid():
		guardar.call("")
	resultado.text = _texto_resultado(resolucion)


static func _cargar() -> Dictionary:
	var fichero := FileAccess.open(RUTA, FileAccess.READ)
	if fichero == null:
		return {}
	var valor: Variant = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	return valor if valor is Dictionary else {}


static func _etiqueta(decision: String) -> String:
	match decision:
		"aislar":
			return "Aislar"
		"validar":
			return "Validar"
		"borrar":
			return "Borrar"
		"investigar":
			return "Investigar"
	return decision


static func _texto_resultado(resolucion: Dictionary) -> String:
	if resolucion.is_empty():
		return "SIGA detecta una discrepancia de una unidad. No hay resolución registrada."
	var estado_registro := String(resolucion.get("estado", ""))
	var id := String(resolucion.get("registro_id", Entrada49.REGISTRO_EXTRA))
	var reaparece := bool(resolucion.get("reaparece", false))
	var texto := "Registro %s · estado: %s." % [id, estado_registro]
	if reaparece:
		texto += " El registro reaparece tras la eliminación."
	return texto
