## Editor de expedientes de desarrollo (#953).
##
## Vive bajo debug/** y el cargador solo lo instancia con una activación
## explícita. Exporta registros compatibles con el visor actual: el cuerpo
## canónico queda en texto plano y los datos de edición enriquecida viven en
## `editor_meta`, que el juego ignora si el documento se incorpora a un caso.
extends Window

const FORMATO := "siga98-editor-v1"
const DIRECTORIO := "user://editor_expedientes"
const MAX_CONTENIDO := 12000
const MAX_CAMPO := 200
const ETIQUETAS_FORMATO := [
	"[b]",
	"[/b]",
	"[i]",
	"[/i]",
	"[left]",
	"[/left]",
	"[center]",
	"[/center]",
	"[right]",
	"[/right]",
]
const SELLOS := ["SIN SELLO", "RECIBIDO", "CONFIDENCIAL", "COPIA", "ARCHIVO"]
const FIRMAS := ["SIN FIRMA", "JEFATURA", "CONTRALORÍA", "SECRETARÍA"]
const PLANTILLAS := [
	{
		"nombre": "Oficial · 1992",
		"tipo": "OFICIO",
		"folio": "OF-1992-001",
		"fecha": "1992-03-18",
		"remitente": "Secretaría General",
		"destino": "Archivo Central",
		"asunto": "Remisión de antecedentes",
		"clasificacion": "OFICIAL",
		"contenido_bbcode":
		"Se remiten los antecedentes indicados para su [b]incorporación al expediente[/b].",
		"sello": "RECIBIDO",
		"firma": "SECRETARÍA",
	},
	{
		"nombre": "Interno · 1996",
		"tipo": "MEMORANDO",
		"folio": "MEM-1996-014",
		"fecha": "1996-11-07",
		"remitente": "Contraloría",
		"destino": "Jefatura",
		"asunto": "Cotejo interno",
		"clasificacion": "INTERNO",
		"contenido_bbcode": "Pendiente de [i]cotejo interno[/i] antes de su archivo definitivo.",
		"sello": "ARCHIVO",
		"firma": "CONTRALORÍA",
	},
	{
		"nombre": "Personal · 1999",
		"tipo": "NOTA",
		"folio": "NOTA-1999-003",
		"fecha": "1999-06-24",
		"remitente": "M. R.",
		"destino": "Archivo personal",
		"asunto": "Recordatorio",
		"clasificacion": "PERSONAL",
		"contenido_bbcode":
		"Recordar revisar la carpeta antes del viernes.\n[center]No adjuntar al registro principal.[/center]",
		"sello": "SIN SELLO",
		"firma": "SIN FIRMA",
	},
]

var _id: LineEdit
var _tipo: LineEdit
var _folio: LineEdit
var _fecha: LineEdit
var _remitente: LineEdit
var _destino: LineEdit
var _asunto: LineEdit
var _clasificacion: LineEdit
var _cuerpo: TextEdit
var _sello: OptionButton
var _firma: OptionButton
var _plantilla: OptionButton
var _vista: RichTextLabel
var _estado: Label


func _ready() -> void:
	title = "SIGA-98 · Editor de expedientes (QA)"
	size = Vector2i(1480, 900)
	min_size = Vector2i(980, 680)
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_requested.connect(hide)
	_montar()
	_nuevo()
	popup_centered()


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	if evento.keycode == KEY_F10 and evento.ctrl_pressed and evento.shift_pressed:
		if visible:
			hide()
		else:
			popup_centered()
		get_viewport().set_input_as_handled()


static func validar(datos: Dictionary) -> PackedStringArray:
	var errores := PackedStringArray()
	var id := String(datos.get("id", "")).strip_edges()
	var tipo := String(datos.get("tipo", "")).strip_edges()
	var folio := String(datos.get("folio", "")).strip_edges()
	var cuerpo := String(datos.get("contenido_bbcode", ""))
	if id.is_empty():
		errores.append("Falta id")
	elif not _id_ruta_valido(id):
		errores.append("El id contiene caracteres no válidos para un archivo")
	if tipo.is_empty():
		errores.append("Falta tipo")
	if folio.is_empty():
		errores.append("Falta folio")
	elif folio.length() > 64:
		errores.append("El folio supera 64 caracteres")
	if _quitar_formato(cuerpo).strip_edges().is_empty():
		errores.append("Falta contenido")
	elif cuerpo.length() > MAX_CONTENIDO:
		errores.append("El contenido supera %d caracteres" % MAX_CONTENIDO)
	var fecha := String(datos.get("fecha", "")).strip_edges()
	if not fecha.is_empty() and not _fecha_valida(fecha):
		errores.append("La fecha debe usar AAAA-MM-DD")
	for clave in ["remitente", "destino", "asunto", "clasificacion"]:
		if String(datos.get(clave, "")).length() > MAX_CAMPO:
			errores.append("%s supera %d caracteres" % [clave, MAX_CAMPO])
	return errores


static func registro_desde_datos(datos: Dictionary) -> Dictionary:
	var contenido := _contenido_plano(datos)
	var fecha := String(datos.get("fecha", "")).strip_edges()
	return {
		"id": String(datos.get("id", "")).strip_edges(),
		"tipo": String(datos.get("tipo", "")).strip_edges().to_upper(),
		"folio": String(datos.get("folio", "")).strip_edges(),
		"contenido": contenido,
		"fecha": null if fecha.is_empty() else fecha,
		"editor_meta":
		{
			"remitente": String(datos.get("remitente", "")).strip_edges(),
			"destino": String(datos.get("destino", "")).strip_edges(),
			"asunto": String(datos.get("asunto", "")).strip_edges(),
			"clasificacion": String(datos.get("clasificacion", "")).strip_edges(),
			"contenido_bbcode": String(datos.get("contenido_bbcode", "")),
			"sello": String(datos.get("sello", SELLOS[0])),
			"firma": String(datos.get("firma", FIRMAS[0])),
		},
	}


static func paquete_desde_datos(datos: Dictionary) -> Dictionary:
	return {"formato": FORMATO, "registro": registro_desde_datos(datos)}


static func datos_desde_paquete(paquete: Dictionary) -> Dictionary:
	if String(paquete.get("formato", "")) != FORMATO:
		return {}
	var registro_var: Variant = paquete.get("registro", {})
	if not registro_var is Dictionary:
		return {}
	var registro: Dictionary = registro_var
	var meta_var: Variant = registro.get("editor_meta", {})
	var meta: Dictionary = meta_var if meta_var is Dictionary else {}
	var cuerpo := String(meta.get("contenido_bbcode", registro.get("contenido", "")))
	return {
		"id": String(registro.get("id", "")),
		"tipo": String(registro.get("tipo", "")),
		"folio": String(registro.get("folio", "")),
		"fecha": "" if registro.get("fecha") == null else String(registro.get("fecha")),
		"remitente": String(meta.get("remitente", "")),
		"destino": String(meta.get("destino", "")),
		"asunto": String(meta.get("asunto", "")),
		"clasificacion": String(meta.get("clasificacion", "")),
		"contenido_bbcode": cuerpo,
		"sello": String(meta.get("sello", SELLOS[0])),
		"firma": String(meta.get("firma", FIRMAS[0])),
	}


static func vista_bbcode(datos: Dictionary) -> String:
	var lineas := PackedStringArray()
	(
		lineas
		. append(
			(
				"[b]%s · %s[/b]"
				% [
					BBCode.escapar(String(datos.get("folio", "")).strip_edges()),
					BBCode.escapar(String(datos.get("tipo", "")).strip_edges().to_upper()),
				]
			)
		)
	)
	var fecha := String(datos.get("fecha", "")).strip_edges()
	if not fecha.is_empty():
		lineas.append(BBCode.escapar(fecha))
	_agregar_meta_bbcode(lineas, "DE", datos.get("remitente", ""))
	_agregar_meta_bbcode(lineas, "PARA", datos.get("destino", ""))
	_agregar_meta_bbcode(lineas, "ASUNTO", datos.get("asunto", ""))
	_agregar_meta_bbcode(lineas, "CLASIFICACIÓN", datos.get("clasificacion", ""))
	lineas.append("")
	lineas.append(_bbcode_seguro(String(datos.get("contenido_bbcode", ""))))
	var sello := String(datos.get("sello", SELLOS[0]))
	if sello != SELLOS[0]:
		lineas.append("\n[center][b]SELLO: %s[/b][/center]" % BBCode.escapar(sello))
	var firma := String(datos.get("firma", FIRMAS[0]))
	if firma != FIRMAS[0]:
		lineas.append("[right]Firma: %s[/right]" % BBCode.escapar(firma))
	return "\n".join(lineas)


static func _contenido_plano(datos: Dictionary) -> String:
	var lineas := PackedStringArray()
	_agregar_meta_plano(lineas, "DE", datos.get("remitente", ""))
	_agregar_meta_plano(lineas, "PARA", datos.get("destino", ""))
	_agregar_meta_plano(lineas, "ASUNTO", datos.get("asunto", ""))
	_agregar_meta_plano(lineas, "CLASIFICACIÓN", datos.get("clasificacion", ""))
	if not lineas.is_empty():
		lineas.append("")
	lineas.append(_quitar_formato(String(datos.get("contenido_bbcode", ""))))
	var sello := String(datos.get("sello", SELLOS[0]))
	if sello != SELLOS[0]:
		lineas.append("\nSELLO: %s" % sello)
	var firma := String(datos.get("firma", FIRMAS[0]))
	if firma != FIRMAS[0]:
		lineas.append("FIRMA: %s" % firma)
	return "\n".join(lineas).strip_edges()


static func _quitar_formato(texto: String) -> String:
	var salida := texto
	for etiqueta in ETIQUETAS_FORMATO:
		salida = salida.replace(etiqueta, "")
	return salida


static func _bbcode_seguro(texto: String) -> String:
	var salida := BBCode.escapar(texto)
	for etiqueta in ETIQUETAS_FORMATO:
		salida = salida.replace("[lb]" + etiqueta.trim_prefix("["), etiqueta)
	return salida


static func _id_ruta_valido(id: String) -> bool:
	for prohibido in ["..", "/", "\\", ":", "*", "?", '"', "<", ">", "|"]:
		if id.contains(prohibido):
			return false
	return true


static func _fecha_valida(fecha: String) -> bool:
	if fecha.length() != 10 or fecha.substr(4, 1) != "-" or fecha.substr(7, 1) != "-":
		return false
	var anio := fecha.substr(0, 4)
	var mes := fecha.substr(5, 2)
	var dia := fecha.substr(8, 2)
	if not anio.is_valid_int() or not mes.is_valid_int() or not dia.is_valid_int():
		return false
	var anio_num := int(anio)
	var mes_num := int(mes)
	var dia_num := int(dia)
	if mes_num < 1 or mes_num > 12 or dia_num < 1:
		return false
	var dias_mes := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var bisiesto := anio_num % 4 == 0 and (anio_num % 100 != 0 or anio_num % 400 == 0)
	if bisiesto:
		dias_mes[1] = 29
	return dia_num <= dias_mes[mes_num - 1]


static func _agregar_meta_plano(
	lineas: PackedStringArray, etiqueta: String, valor: Variant
) -> void:
	var texto := String(valor).strip_edges()
	if not texto.is_empty():
		lineas.append("%s: %s" % [etiqueta, texto])


static func _agregar_meta_bbcode(
	lineas: PackedStringArray, etiqueta: String, valor: Variant
) -> void:
	var texto := String(valor).strip_edges()
	if not texto.is_empty():
		lineas.append("[b]%s:[/b] %s" % [etiqueta, BBCode.escapar(texto)])


func _montar() -> void:
	var margen := MarginContainer.new()
	margen.theme = EstiloSiga.tema()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 12)
	margen.add_theme_constant_override("margin_top", 12)
	margen.add_theme_constant_override("margin_right", 12)
	margen.add_theme_constant_override("margin_bottom", 12)
	add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 8)
	margen.add_child(raiz)

	var ayuda := Label.new()
	ayuda.text = "Herramienta QA. Guarda en user://editor_expedientes. Ctrl+Shift+F10 muestra/oculta."
	raiz.add_child(ayuda)

	var division := HSplitContainer.new()
	division.size_flags_vertical = Control.SIZE_EXPAND_FILL
	division.split_offset = 690
	raiz.add_child(division)
	division.add_child(_montar_formulario())
	division.add_child(_montar_vista())

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(_estado)


func _montar_formulario() -> Control:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 560
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	scroll.add_child(lista)

	_plantilla = _opciones(lista, "Plantilla QA", _nombres_plantillas())
	_plantilla.item_selected.connect(_aplicar_plantilla)
	_id = _campo(lista, "ID", "doc-prueba@1")
	_tipo = _campo(lista, "Tipo", "MEMORANDO")
	_folio = _campo(lista, "Folio", "MEMO-1998-001")
	_fecha = _campo(lista, "Fecha (AAAA-MM-DD)", "1998-01-01")
	_remitente = _campo(lista, "Remitente", "")
	_destino = _campo(lista, "Destino", "")
	_asunto = _campo(lista, "Asunto", "")
	_clasificacion = _campo(lista, "Clasificación", "")

	lista.add_child(_etiqueta("Formato del cuerpo"))
	var barra := HBoxContainer.new()
	lista.add_child(barra)
	_boton_formato(barra, "Negrita", "[b]", "[/b]")
	_boton_formato(barra, "Cursiva", "[i]", "[/i]")
	_boton_formato(barra, "Izq.", "[left]", "[/left]")
	_boton_formato(barra, "Centro", "[center]", "[/center]")
	_boton_formato(barra, "Der.", "[right]", "[/right]")

	_cuerpo = TextEdit.new()
	_cuerpo.custom_minimum_size.y = 300
	_cuerpo.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_cuerpo.text_changed.connect(_refrescar_vista)
	lista.add_child(_cuerpo)

	_sello = _opciones(lista, "Sello", SELLOS)
	_firma = _opciones(lista, "Firma", FIRMAS)

	var acciones := HBoxContainer.new()
	lista.add_child(acciones)
	_boton_accion(acciones, "Nuevo", _nuevo)
	_boton_accion(acciones, "Guardar JSON", _guardar)
	_boton_accion(acciones, "Cargar por ID", _cargar)
	return scroll


func _montar_vista() -> Control:
	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_child(_etiqueta("Vista previa SIGA"))
	_vista = RichTextLabel.new()
	_vista.bbcode_enabled = true
	_vista.fit_content = false
	_vista.scroll_active = true
	_vista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vista.add_theme_stylebox_override("normal", _papel())
	_vista.add_theme_color_override("default_color", EstiloSiga.NEGRO)
	_vista.add_theme_font_override("normal_font", EstiloSiga.fuente_documento())
	_vista.add_theme_font_size_override("normal_font_size", 15)
	caja.add_child(_vista)
	return caja


func _campo(padre: VBoxContainer, rotulo: String, placeholder: String) -> LineEdit:
	padre.add_child(_etiqueta(rotulo))
	var campo := LineEdit.new()
	campo.placeholder_text = placeholder
	campo.text_changed.connect(_al_cambiar_texto)
	padre.add_child(campo)
	return campo


static func _nombres_plantillas() -> Array:
	var nombres: Array = []
	for plantilla in PLANTILLAS:
		nombres.append(String(plantilla["nombre"]))
	return nombres


static func datos_plantilla(indice: int) -> Dictionary:
	if indice < 0 or indice >= PLANTILLAS.size():
		return {}
	var datos: Dictionary = PLANTILLAS[indice].duplicate(true)
	datos.erase("nombre")
	datos["id"] = (
		"qa-%s"
		% String(PLANTILLAS[indice]["nombre"]).to_lower().replace(" · ", "-").replace(" ", "-")
	)
	return datos


func _opciones(padre: VBoxContainer, rotulo: String, valores: Array) -> OptionButton:
	padre.add_child(_etiqueta(rotulo))
	var opcion := OptionButton.new()
	for valor in valores:
		opcion.add_item(String(valor))
	opcion.item_selected.connect(_al_cambiar_opcion)
	padre.add_child(opcion)
	return opcion


func _boton_formato(padre: HBoxContainer, rotulo: String, apertura: String, cierre: String) -> void:
	var boton := Button.new()
	boton.text = rotulo
	boton.pressed.connect(_aplicar_formato.bind(apertura, cierre))
	padre.add_child(boton)


func _boton_accion(padre: HBoxContainer, rotulo: String, accion: Callable) -> void:
	var boton := Button.new()
	boton.text = rotulo
	boton.pressed.connect(accion)
	padre.add_child(boton)


func _etiqueta(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	return etiqueta


func _papel() -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = EstiloSiga.BLANCO
	caja.border_color = EstiloSiga.GRIS_OSCURO
	caja.set_border_width_all(2)
	caja.set_content_margin_all(14)
	return caja


func _datos() -> Dictionary:
	return {
		"id": _id.text,
		"tipo": _tipo.text,
		"folio": _folio.text,
		"fecha": _fecha.text,
		"remitente": _remitente.text,
		"destino": _destino.text,
		"asunto": _asunto.text,
		"clasificacion": _clasificacion.text,
		"contenido_bbcode": _cuerpo.text,
		"sello": _sello.get_item_text(_sello.selected),
		"firma": _firma.get_item_text(_firma.selected),
	}


func _al_cambiar_texto(_texto: String) -> void:
	_refrescar_vista()


func _al_cambiar_opcion(_indice: int) -> void:
	_refrescar_vista()


func _aplicar_plantilla(indice: int) -> void:
	var datos := datos_plantilla(indice)
	if datos.is_empty():
		return
	_aplicar_datos(datos)
	_estado.text = "Plantilla QA aplicada; edita antes de guardar si necesitas otra variante."


func _refrescar_vista() -> void:
	if _vista != null:
		_vista.text = vista_bbcode(_datos())


func _aplicar_formato(apertura: String, cierre: String) -> void:
	var seleccionado := _cuerpo.get_selected_text()
	if _cuerpo.has_selection():
		_cuerpo.delete_selection()
	_cuerpo.insert_text_at_caret(apertura + seleccionado + cierre)
	_refrescar_vista()
	_cuerpo.grab_focus()


func _nuevo() -> void:
	if _id == null:
		return
	_id.text = ""
	_tipo.text = "MEMORANDO"
	_folio.text = ""
	_fecha.text = "1998-01-01"
	_remitente.text = ""
	_destino.text = ""
	_asunto.text = ""
	_clasificacion.text = ""
	_cuerpo.text = ""
	_sello.select(0)
	_firma.select(0)
	_estado.text = "Documento nuevo; aún no se ha escrito nada en disco."
	_refrescar_vista()


func _guardar() -> void:
	var datos := _datos()
	var errores := validar(datos)
	if not errores.is_empty():
		_estado.text = "No se guardó: " + "; ".join(errores)
		return
	var error := DirAccess.make_dir_recursive_absolute(DIRECTORIO)
	if error != OK:
		_estado.text = "No se pudo crear %s (error %d)." % [DIRECTORIO, error]
		return
	var ruta := _ruta(String(datos["id"]))
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_estado.text = "No se pudo abrir %s para escritura." % ruta
		return
	archivo.store_string(JSON.stringify(paquete_desde_datos(datos), "  "))
	_estado.text = "Guardado: %s" % ruta


func _cargar() -> void:
	var id := _id.text.strip_edges()
	if id.is_empty() or not _id_ruta_valido(id):
		_estado.text = "Escribe un ID válido para cargar."
		return
	var ruta := _ruta(id)
	if not FileAccess.file_exists(ruta):
		_estado.text = "No existe: %s" % ruta
		return
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		_estado.text = "No se pudo leer: %s" % ruta
		return
	var paquete_var: Variant = JSON.parse_string(archivo.get_as_text())
	if not paquete_var is Dictionary:
		_estado.text = "JSON inválido o no compatible."
		return
	var datos := datos_desde_paquete(paquete_var)
	if datos.is_empty():
		_estado.text = "El archivo no usa %s." % FORMATO
		return
	_aplicar_datos(datos)
	_estado.text = "Cargado: %s" % ruta


func _aplicar_datos(datos: Dictionary) -> void:
	_id.text = String(datos.get("id", ""))
	_tipo.text = String(datos.get("tipo", ""))
	_folio.text = String(datos.get("folio", ""))
	_fecha.text = String(datos.get("fecha", ""))
	_remitente.text = String(datos.get("remitente", ""))
	_destino.text = String(datos.get("destino", ""))
	_asunto.text = String(datos.get("asunto", ""))
	_clasificacion.text = String(datos.get("clasificacion", ""))
	_cuerpo.text = String(datos.get("contenido_bbcode", ""))
	_seleccionar_texto(_sello, String(datos.get("sello", SELLOS[0])))
	_seleccionar_texto(_firma, String(datos.get("firma", FIRMAS[0])))
	_refrescar_vista()


func _seleccionar_texto(opcion: OptionButton, texto: String) -> void:
	for i in opcion.item_count:
		if opcion.get_item_text(i) == texto:
			opcion.select(i)
			return
	opcion.select(0)


func _ruta(id: String) -> String:
	return "%s/%s.json" % [DIRECTORIO, id]
