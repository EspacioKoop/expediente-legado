## Menú común a archivo, casa y sueño (#113).
##
## Recupera del menú web legado su contrato útil: diálogo modal, pausa real,
## navegación por foco, B/Escape para volver y restauración del foco previo.
## Vive como autoload para no duplicarse entre las tres partes del juego.
extends CanvasLayer

const RUTA_PRESENTACION_SELLOS := "res://datos/sellos_presentacion.json"
const RUTA_TEXTOS_REMAPEO := "res://datos/menu_remapeo_textos.json"
const RUTA_TEXTOS_DIFICULTAD := "res://datos/menu_dificultad_textos.json"
const ETIQUETAS_ACCIONES := {
	"mover_adelante": "Avanzar",
	"mover_atras": "Retroceder",
	"mover_izquierda": "Mover a la izquierda",
	"mover_derecha": "Mover a la derecha",
	"saltar": "Saltar",
	"correr": "Correr",
	"agacharse": "Agacharse",
	"interactuar": "Interactuar",
	"cancelar": "Volver / cancelar",
}

var _preferencias: Dictionary = {}
var _presentacion_sellos: Dictionary = {}
var _textos_remapeo: Dictionary = {}
var _textos_dificultad: Dictionary = {}
var _fondo: ColorRect
var _panel_principal: PanelContainer
var _panel_opciones: PanelContainer
var _panel_sellos: PanelContainer
var _panel_historial: PanelContainer
var _panel_incidencias: ParteIncidenciasApp
var _continuar: Button
var _opciones: Button
var _sellos: Button
var _historial_boton: Button
var _incidencias: Button
var _volver: Button
var _sellos_volver: Button
var _historial_volver: Button
var _historial_resumen: Label
var _historial_lista: VBoxContainer
var _salir: Button
var _volumen: HSlider
var _reduccion: CheckButton
var _dificultad: OptionButton
var _dificultad_detalle: Label
var _estado_dificultad: Label
var _sensibilidad_raton: HSlider
var _sensibilidad_mando: HSlider
var _invertir_y: CheckButton
var _estado_remapeo: Label
var _botones_remapeo: Dictionary = {}
var _captura_accion := ""
var _captura_tipo := ""
var _foco_previo: Control
var _mouse_previo := Input.MOUSE_MODE_VISIBLE
var _historias := Historias.new()
var _verificacion: VerificacionFalsa


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_preferencias = PreferenciasSiga.cargar()
	_presentacion_sellos = _cargar_presentacion_sellos()
	_textos_dificultad = _cargar_textos_dificultad()
	_historias.cargar()
	PreferenciasSiga.aplicar(_preferencias)
	_aplicar_volumen()
	_montar()


func _unhandled_input(evento: InputEvent) -> void:
	if not _captura_accion.is_empty():
		if evento is InputEventKey and evento.pressed and not evento.echo:
			_aplicar_remapeo("teclado", int(evento.physical_keycode))
			get_viewport().set_input_as_handled()
			return
		if evento is InputEventJoypadButton and evento.pressed:
			_aplicar_remapeo("mando", int(evento.button_index))
			get_viewport().set_input_as_handled()
			return
	# Start/Options/+ abre y cierra el menú como en cualquier juego. Con mando,
	# B solo vuelve atrás: abrir el menú al pulsarlo en el mundo era un tropiezo.
	var start: bool = (
		evento is InputEventJoypadButton
		and evento.pressed
		and evento.button_index == JOY_BUTTON_START
	)
	if start:
		if _fondo.visible:
			_cerrar()
		elif _puede_abrir():
			_abrir()
		get_viewport().set_input_as_handled()
		return
	if not evento.is_action_pressed("cancelar"):
		return
	if _verificacion != null and _verificacion.visible:
		_verificacion.ocultar()
		get_viewport().set_input_as_handled()
		return
	if not _fondo.visible and evento is InputEventJoypadButton:
		return
	if _fondo.visible:
		if _panel_incidencias.visible:
			_volver_de_incidencias()
		else:
			_cerrar()
	elif _puede_abrir():
		_abrir()
	get_viewport().set_input_as_handled()


func _puede_abrir() -> bool:
	var escena := get_tree().current_scene
	return escena != null and escena.scene_file_path == "res://escenas/dia.tscn"


func _montar() -> void:
	_fondo = ColorRect.new()
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.color = Color(0.0, 0.0, 0.0, 0.72)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_fondo.visible = false
	add_child(_fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.add_child(centro)

	_panel_principal = _crear_panel()
	centro.add_child(_panel_principal)
	var principal := _caja(_panel_principal)
	_principal_contenido(principal)

	_panel_opciones = _crear_panel()
	_panel_opciones.visible = false
	centro.add_child(_panel_opciones)
	var opciones := _caja(_panel_opciones)
	_opciones_contenido(opciones)

	_panel_sellos = _crear_panel()
	_panel_sellos.visible = false
	centro.add_child(_panel_sellos)
	var sellos := _caja(_panel_sellos)
	_sellos_contenido(sellos)

	_panel_historial = _crear_panel()
	_panel_historial.custom_minimum_size = Vector2(760, 520)
	_panel_historial.visible = false
	centro.add_child(_panel_historial)
	var historial := _caja(_panel_historial)
	_historial_contenido(historial)

	_panel_incidencias = ParteIncidenciasApp.new()
	_panel_incidencias.volver.connect(_volver_de_incidencias)
	centro.add_child(_panel_incidencias)

	_verificacion = VerificacionFalsa.new()
	_verificacion.cerrada.connect(_al_cerrar_verificacion)
	_fondo.add_child(_verificacion)


func _crear_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 300)
	panel.theme = EstiloSiga.tema()
	return panel


func _caja(panel: PanelContainer) -> VBoxContainer:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	panel.add_child(margen)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	margen.add_child(caja)
	return caja


func _principal_contenido(caja: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = tr("MENU_GLOBAL_TITULO")
	caja.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = tr("MENU_GLOBAL_SUBTITULO")
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(subtitulo)

	_continuar = Button.new()
	_continuar.text = tr("MENU_GLOBAL_CONTINUAR")
	_continuar.pressed.connect(_cerrar)
	caja.add_child(_continuar)

	_opciones = Button.new()
	_opciones.text = tr("MENU_GLOBAL_OPCIONES")
	_opciones.pressed.connect(_mostrar_opciones)
	caja.add_child(_opciones)

	_sellos = Button.new()
	_sellos.text = String(_presentacion_sellos.get("titulo", ""))
	_sellos.pressed.connect(_mostrar_sellos)
	caja.add_child(_sellos)

	_historial_boton = Button.new()
	_historial_boton.text = tr("MENU_GLOBAL_HISTORIAL_DECISIONES")
	_historial_boton.pressed.connect(_mostrar_historial)
	caja.add_child(_historial_boton)

	_incidencias = Button.new()
	_incidencias.text = ParteIncidencias.ETIQUETA
	_incidencias.pressed.connect(_mostrar_incidencias)
	caja.add_child(_incidencias)

	_salir = Button.new()
	_salir.text = tr("MENU_GLOBAL_SALIR")
	_salir.pressed.connect(func(): get_tree().quit())
	caja.add_child(_salir)


func _opciones_contenido(caja: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = tr("MENU_GLOBAL_OPCIONES")
	caja.add_child(titulo)

	_montar_dificultad(caja)

	var separador_dificultad := HSeparator.new()
	caja.add_child(separador_dificultad)

	var volumen_titulo := Label.new()
	volumen_titulo.text = tr("MENU_GLOBAL_VOLUMEN")
	caja.add_child(volumen_titulo)

	_volumen = HSlider.new()
	_volumen.min_value = 0.0
	_volumen.max_value = 1.0
	_volumen.step = 0.05
	_volumen.value = float(_preferencias.get("volumen", 1.0))
	_volumen.accessibility_name = volumen_titulo.text
	_volumen.value_changed.connect(_al_cambiar_volumen)
	caja.add_child(_volumen)

	_reduccion = CheckButton.new()
	_reduccion.text = tr("MENU_GLOBAL_REDUCCION_MOVIMIENTO")
	_reduccion.button_pressed = bool(_preferencias.get("reduccion_movimiento", false))
	_reduccion.toggled.connect(_al_cambiar_reduccion)
	caja.add_child(_reduccion)

	_montar_preferencias_camara(caja)

	var separador := HSeparator.new()
	caja.add_child(separador)
	_montar_remapeo(caja)

	_volver = Button.new()
	_volver.text = tr("MENU_GLOBAL_VOLVER")
	_volver.pressed.connect(_mostrar_principal)
	caja.add_child(_volver)


func _montar_dificultad(caja: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = String(_textos_dificultad.get("titulo", ""))
	caja.add_child(titulo)

	_dificultad = OptionButton.new()
	for opcion in _textos_dificultad.get("opciones", []):
		if not (opcion is Dictionary):
			continue
		var opcion_id := String(opcion.get("id", ""))
		if not Acusacion.DIFICULTADES.has(opcion_id):
			continue
		_dificultad.add_item(String(opcion.get("nombre", opcion_id)))
		var indice := _dificultad.item_count - 1
		_dificultad.set_item_metadata(indice, opcion_id)
		_dificultad.set_item_tooltip(indice, String(opcion.get("detalle", "")))
	_dificultad.item_selected.connect(_al_cambiar_dificultad)
	caja.add_child(_dificultad)

	_dificultad_detalle = Label.new()
	_dificultad_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_dificultad_detalle)

	var ayuda := Label.new()
	ayuda.text = String(_textos_dificultad.get("ayuda", ""))
	ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(ayuda)

	_estado_dificultad = Label.new()
	_estado_dificultad.accessibility_live = AccessibilityServer.LIVE_POLITE
	_estado_dificultad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_estado_dificultad)
	_refrescar_dificultad()


func _refrescar_dificultad() -> void:
	if _dificultad == null:
		return
	var partida_actual := _partida_actual()
	_dificultad.disabled = partida_actual == null
	if partida_actual == null:
		_dificultad.select(-1)
		_dificultad_detalle.text = ""
		return

	var actual := String(partida_actual.estado.get("dificultad", "normal"))
	for indice in _dificultad.item_count:
		if String(_dificultad.get_item_metadata(indice)) != actual:
			continue
		_dificultad.select(indice)
		_actualizar_detalle_dificultad(indice)
		return


func _actualizar_detalle_dificultad(indice: int) -> void:
	if indice < 0 or indice >= _dificultad.item_count:
		_dificultad_detalle.text = ""
		return
	_dificultad_detalle.text = _dificultad.get_item_tooltip(indice)


func _al_cambiar_dificultad(indice: int) -> void:
	var partida_actual := _partida_actual()
	if partida_actual == null or indice < 0 or indice >= _dificultad.item_count:
		return

	var nueva := String(_dificultad.get_item_metadata(indice))
	Acusacion.cambiar_dificultad(partida_actual.estado, nueva)
	# Cambiar la dificultad es un evento real de Tarot. Si La Fuerza era la
	# última carta válida pendiente, El Mundo se evalúa aquí y no al cargar.
	var contenido := Contenido.new()
	if contenido.cargar():
		Prometeo.sincronizar_tarot_mundo(partida_actual.estado, contenido.principales())
	_actualizar_detalle_dificultad(indice)

	_estado_dificultad.text = (
		String(_textos_dificultad.get("guardado_ok", ""))
		if partida_actual.guardar()
		else String(_textos_dificultad.get("guardado_error", ""))
	)


func _montar_preferencias_camara(caja: VBoxContainer) -> void:
	_sensibilidad_raton = _slider_preferencia(
		caja,
		tr("MENU_GLOBAL_SENSIBILIDAD_RATON"),
		float(_preferencias.get("sensibilidad_camara_raton", 1.0)),
		_al_cambiar_sensibilidad_raton
	)
	_sensibilidad_mando = _slider_preferencia(
		caja,
		tr("MENU_GLOBAL_SENSIBILIDAD_MANDO"),
		float(_preferencias.get("sensibilidad_camara_mando", 1.0)),
		_al_cambiar_sensibilidad_mando
	)
	_invertir_y = CheckButton.new()
	_invertir_y.text = tr("MENU_GLOBAL_INVERTIR_CAMARA_Y")
	_invertir_y.button_pressed = bool(_preferencias.get("invertir_camara_y", false))
	_invertir_y.toggled.connect(_al_cambiar_invertir_y)
	caja.add_child(_invertir_y)


func _slider_preferencia(
	caja: VBoxContainer, etiqueta: String, valor: float, al_cambiar: Callable
) -> HSlider:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	caja.add_child(fila)

	var nombre := Label.new()
	nombre.text = etiqueta
	nombre.custom_minimum_size.x = 210
	fila.add_child(nombre)

	var slider := HSlider.new()
	slider.min_value = PreferenciasSiga.SENSIBILIDAD_CAMARA_MIN
	slider.max_value = PreferenciasSiga.SENSIBILIDAD_CAMARA_MAX
	slider.step = 0.05
	slider.value = valor
	slider.accessibility_name = etiqueta
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(al_cambiar)
	fila.add_child(slider)
	return slider


func _sellos_contenido(caja: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = String(_presentacion_sellos.get("titulo", ""))
	caja.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = String(_presentacion_sellos.get("subtitulo", ""))
	caja.add_child(subtitulo)

	for entrada in Sellos.catalogo():
		var fila := Label.new()
		fila.name = "Sello_%s" % String(entrada.get("id", "sin-id"))
		fila.text = _texto_sello(entrada)
		fila.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.custom_minimum_size.x = 560
		caja.add_child(fila)

	_sellos_volver = Button.new()
	_sellos_volver.text = tr("MENU_GLOBAL_VOLVER")
	_sellos_volver.pressed.connect(_mostrar_principal)
	caja.add_child(_sellos_volver)


func _historial_contenido(caja: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = tr("MENU_GLOBAL_HISTORIAL_DECISIONES")
	caja.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = tr("MENU_GLOBAL_HISTORIAL_SUBTITULO")
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(subtitulo)

	_historial_resumen = Label.new()
	_historial_resumen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(_historial_resumen)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(scroll)

	_historial_lista = VBoxContainer.new()
	_historial_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_historial_lista.add_theme_constant_override("separation", 10)
	scroll.add_child(_historial_lista)

	_historial_volver = Button.new()
	_historial_volver.text = tr("MENU_GLOBAL_VOLVER")
	_historial_volver.pressed.connect(_mostrar_principal)
	caja.add_child(_historial_volver)


func _refrescar_historial() -> void:
	for nodo in _historial_lista.get_children():
		_historial_lista.remove_child(nodo)
		nodo.queue_free()

	var estado := _estado_partida_actual()
	var presion := _historias.presion_indecision(estado)
	var nivel := clampi(int(presion.get("nivel", 0)), 0, 2)
	_historial_resumen.text = (
		tr("MENU_GLOBAL_HISTORIAL_RESUMEN")
		% [int(presion.get("total", 0)), int(presion.get("reiteradas", 0))]
	)
	var aviso := Label.new()
	aviso.text = _texto_presion_historial(nivel)
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_historial_lista.add_child(aviso)

	var eventos := _historias.historial(estado)
	if eventos.is_empty():
		var vacio := Label.new()
		vacio.text = tr("MENU_GLOBAL_HISTORIAL_VACIO")
		_historial_lista.add_child(vacio)
		return

	for evento in eventos:
		if not (evento is Dictionary):
			continue
		var fila := Label.new()
		fila.text = _texto_evento_historial(evento)
		fila.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fila.custom_minimum_size.x = 640
		_historial_lista.add_child(fila)


func _texto_presion_historial(nivel: int) -> String:
	match nivel:
		1:
			return tr("MENU_GLOBAL_HISTORIAL_PRESION_1")
		2:
			return tr("MENU_GLOBAL_HISTORIAL_PRESION_2")
		_:
			return tr("MENU_GLOBAL_HISTORIAL_PRESION_0")


func _texto_evento_historial(evento: Dictionary) -> String:
	var carta_id := String(evento.get("carta", ""))
	var nombre := _nombre_carta(carta_id)
	var legado := bool(evento.get("legado", false))
	var contexto := (
		tr("MENU_GLOBAL_HISTORIAL_LEGADO")
		if legado
		else (
			tr("MENU_GLOBAL_HISTORIAL_CONTEXTO")
			% [
				int(evento.get("dia", 0)),
				String(evento.get("fase", "")).replace("_", " ").capitalize(),
			]
		)
	)
	var tipo := String(evento.get("tipo", ""))
	if tipo == "pospuesta":
		return (
			tr("MENU_GLOBAL_HISTORIAL_POSPUESTA")
			% [nombre, int(evento.get("posposiciones", 1)), contexto]
		)

	var eleccion := _texto_eleccion(carta_id, String(evento.get("eleccion", "")))
	return tr("MENU_GLOBAL_HISTORIAL_RESUELTA") % [nombre, contexto, eleccion]


func _nombre_carta(carta_id: String) -> String:
	for carta in _estado_partida_actual().get("tarot", []):
		if String(carta.get("id", "")) == carta_id:
			return String(carta.get("nombre", carta_id))
	return carta_id.replace("-", " ").capitalize()


func _texto_eleccion(carta_id: String, eje: String) -> String:
	var historia := _historias.de(carta_id)
	for opcion in historia.get("opciones", []):
		if String(opcion.get("eje", "")) == eje:
			return String(opcion.get("texto", ""))
	return eje.replace("_", " ").capitalize()


func _cargar_presentacion_sellos() -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_PRESENTACION_SELLOS))
	return datos if datos is Dictionary else {}


func _cargar_textos_dificultad() -> Dictionary:
	var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS_DIFICULTAD))
	return datos if datos is Dictionary else {}


func _texto_remapeo(clave: String) -> String:
	if _textos_remapeo.is_empty():
		var datos = JSON.parse_string(FileAccess.get_file_as_string(RUTA_TEXTOS_REMAPEO))
		if datos is Dictionary:
			_textos_remapeo = datos
	return String(_textos_remapeo.get(clave, ""))


func _texto_sello(entrada: Dictionary) -> String:
	var sello_id := String(entrada.get("id", ""))
	var obtenido := Sellos.tiene_sello(_estado_partida_actual(), sello_id)
	var marca := "◆" if obtenido else "◇"
	var clave_titulo := String(entrada.get("titulo", ""))
	var titulo := tr(clave_titulo) if not clave_titulo.is_empty() else ""
	if titulo.is_empty() or titulo == clave_titulo:
		titulo = sello_id.replace("-", " ").capitalize()

	var clave_descripcion := String(entrada.get("descripcion", ""))
	var descripcion := tr(clave_descripcion) if not clave_descripcion.is_empty() else ""
	if descripcion.is_empty() or descripcion == clave_descripcion:
		return "%s  %s" % [marca, titulo]
	return "%s  %s\n    %s" % [marca, titulo, descripcion]


func _partida_actual() -> Partida:
	var escena := get_tree().current_scene
	if escena == null:
		return null
	var partida_actual = escena.get("partida")
	return partida_actual if partida_actual is Partida else null


func _estado_partida_actual() -> Dictionary:
	var partida_actual := _partida_actual()
	return partida_actual.estado if partida_actual != null else {}


func _montar_remapeo(caja: VBoxContainer) -> void:
	_botones_remapeo.clear()
	for accion in PreferenciasSiga.ACCIONES:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		caja.add_child(fila)

		var nombre := Label.new()
		nombre.text = _nombre_accion(accion)
		nombre.custom_minimum_size.x = 200
		fila.add_child(nombre)

		for tipo in ["teclado", "mando"]:
			var boton := Button.new()
			boton.custom_minimum_size.x = 160
			boton.pressed.connect(_iniciar_captura.bind(accion, tipo))
			fila.add_child(boton)
			_botones_remapeo[_clave_boton(accion, tipo)] = boton

	var controles := HBoxContainer.new()
	controles.add_theme_constant_override("separation", 8)
	caja.add_child(controles)

	_estado_remapeo = Label.new()
	_estado_remapeo.accessibility_live = AccessibilityServer.LIVE_POLITE
	_estado_remapeo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controles.add_child(_estado_remapeo)

	var restaurar := Button.new()
	restaurar.text = "↺"
	restaurar.tooltip_text = _texto_remapeo("restaurar_tooltip")
	restaurar.accessibility_name = restaurar.tooltip_text
	restaurar.pressed.connect(_restaurar_controles)
	controles.add_child(restaurar)
	_refrescar_remapeo()


func _clave_boton(accion: String, tipo: String) -> String:
	return accion + ":" + tipo


func _nombre_accion(accion: String) -> String:
	return String(ETIQUETAS_ACCIONES.get(accion, accion.replace("_", " ").capitalize()))


func _nombre_boton_mando(codigo: int) -> String:
	return PreferenciasSiga.nombre_boton_mando(codigo)


func _iniciar_captura(accion: String, tipo: String) -> void:
	_cancelar_captura()
	_captura_accion = accion
	_captura_tipo = tipo
	var dispositivo := (
		_texto_remapeo("captura_teclado") if tipo == "teclado" else _texto_remapeo("captura_mando")
	)
	_estado_remapeo.text = _texto_remapeo("captura_estado") % [_nombre_accion(accion), dispositivo]
	var boton: Button = _botones_remapeo[_clave_boton(accion, tipo)]
	boton.text = "…"
	boton.grab_focus()


func _aplicar_remapeo(tipo: String, codigo: int) -> void:
	if tipo != _captura_tipo:
		return
	var accion := _captura_accion
	var resultado := PreferenciasSiga.remapear(_preferencias, accion, tipo, codigo)
	if resultado.get("ok", false):
		PreferenciasSiga.aplicar(_preferencias)
		PreferenciasSiga.guardar(_preferencias)
		_estado_remapeo.text = _texto_remapeo("asignado") % _nombre_accion(accion)
	else:
		var conflicto := String(resultado.get("accion", ""))
		_estado_remapeo.text = (
			_texto_remapeo("conflicto") % _nombre_accion(conflicto)
			if not conflicto.is_empty()
			else _texto_remapeo("error_asignacion")
		)
	_captura_accion = ""
	_captura_tipo = ""
	_refrescar_remapeo()


func _cancelar_captura() -> void:
	if _captura_accion.is_empty():
		return
	_captura_accion = ""
	_captura_tipo = ""
	_refrescar_remapeo()


func _restaurar_controles() -> void:
	_preferencias["acciones"] = PreferenciasSiga.nuevas()["acciones"].duplicate(true)
	PreferenciasSiga.aplicar(_preferencias)
	PreferenciasSiga.guardar(_preferencias)
	_estado_remapeo.text = _texto_remapeo("restaurado")
	_refrescar_remapeo()


func _refrescar_remapeo() -> void:
	for accion in _preferencias.get("acciones", {}):
		var mapa: Dictionary = _preferencias["acciones"][accion]
		var tecla: Button = _botones_remapeo.get(_clave_boton(accion, "teclado"))
		var mando: Button = _botones_remapeo.get(_clave_boton(accion, "mando"))
		if tecla != null:
			tecla.text = OS.get_keycode_string(int(mapa.get("teclado", 0)))
			tecla.tooltip_text = _texto_remapeo("tooltip_teclado") % _nombre_accion(accion)
		if mando != null:
			mando.text = _nombre_boton_mando(int(mapa.get("mando", 0)))
			mando.tooltip_text = _texto_remapeo("tooltip_mando") % _nombre_accion(accion)


func _abrir() -> void:
	_foco_previo = get_viewport().gui_get_focus_owner()
	_mouse_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_panel_principal.visible = true
	_panel_opciones.visible = false
	_panel_sellos.visible = false
	_panel_historial.visible = false
	_panel_incidencias.visible = false
	_fondo.visible = true
	get_tree().paused = true
	_continuar.grab_focus()
	_quizas_mostrar_verificacion()


func _cerrar() -> void:
	if not _fondo.visible:
		return
	_cancelar_captura()
	if _verificacion != null:
		_verificacion.ocultar()
	_fondo.visible = false
	get_tree().paused = false
	Input.mouse_mode = _mouse_previo
	if is_instance_valid(_foco_previo) and _foco_previo.is_inside_tree():
		_foco_previo.grab_focus()
	_foco_previo = null


func _quizas_mostrar_verificacion() -> void:
	var partida_actual := _partida_actual()
	if partida_actual == null or _verificacion == null:
		return
	var tiradas := _tiradas_verificacion(partida_actual.estado)
	if not VerificacionFalsa.debe_mostrar(int(tiradas["aparicion"])):
		return

	# Igual que en el legado, la APARICIÓN de la verificación es el evento.
	# Abrir el menú sin que aparezca no concede nada; confirmar tampoco añade
	# una segunda condición.
	_verificacion.mostrar(int(tiradas["pregunta"]))
	if not VerificacionFalsa.registrar(partida_actual.estado):
		return

	var contenido := Contenido.new()
	if contenido.cargar():
		Prometeo.sincronizar_tarot_mundo(partida_actual.estado, contenido.principales())
	if not partida_actual.guardar():
		push_warning("No se pudo persistir el evento de verificación falsa.")


## El resultado depende solo de estado guardado: misma semilla, vuelta, día,
## acciones y fase producen la misma aparición y la misma pregunta tras recargar.
func _tiradas_verificacion(estado: Dictionary) -> Dictionary:
	var jornada: Dictionary = estado.get("jornada", {})
	var indices := [
		int(jornada.get("vuelta", 1)),
		int(jornada.get("dia", 1)),
		int(jornada.get("acciones", 0)),
	]
	var fase := String(jornada.get("fase", ""))
	var raiz := int(estado.get("semilla", 0))
	return {
		"aparicion": Azar.derivar_texto(raiz, "dia", "verificacion_falsa:%s" % fase, indices),
		"pregunta":
		Azar.derivar_texto(raiz, "presentacion", "verificacion_falsa:%s" % fase, indices),
	}


func _al_cerrar_verificacion() -> void:
	if _fondo.visible and is_instance_valid(_continuar):
		_continuar.grab_focus()


func _mostrar_opciones() -> void:
	_panel_principal.visible = false
	_panel_sellos.visible = false
	_panel_historial.visible = false
	_panel_incidencias.visible = false
	_panel_opciones.visible = true
	_refrescar_dificultad()
	_volumen.grab_focus()


func _mostrar_sellos() -> void:
	_panel_principal.visible = false
	_panel_opciones.visible = false
	_panel_historial.visible = false
	_panel_incidencias.visible = false
	_panel_sellos.visible = true
	_sellos_volver.grab_focus()


func _mostrar_historial() -> void:
	_panel_principal.visible = false
	_panel_opciones.visible = false
	_panel_sellos.visible = false
	_panel_incidencias.visible = false
	_panel_historial.visible = true
	_refrescar_historial()
	_historial_volver.grab_focus()


func _mostrar_incidencias() -> void:
	_panel_principal.visible = false
	_panel_opciones.visible = false
	_panel_sellos.visible = false
	_panel_historial.visible = false
	_panel_incidencias.abrir(_preferencias)


func _volver_de_incidencias() -> void:
	_panel_incidencias.visible = false
	_panel_opciones.visible = false
	_panel_sellos.visible = false
	_panel_historial.visible = false
	_panel_principal.visible = true
	_incidencias.grab_focus()


func _mostrar_principal() -> void:
	_cancelar_captura()
	_panel_opciones.visible = false
	_panel_sellos.visible = false
	_panel_historial.visible = false
	_panel_incidencias.visible = false
	_panel_principal.visible = true
	_opciones.grab_focus()


func _al_cambiar_volumen(valor: float) -> void:
	_preferencias["volumen"] = valor
	_aplicar_volumen()
	PreferenciasSiga.guardar(_preferencias)


func _al_cambiar_reduccion(activa: bool) -> void:
	_preferencias["reduccion_movimiento"] = activa
	PreferenciasSiga.guardar(_preferencias)


func _al_cambiar_sensibilidad_raton(valor: float) -> void:
	_preferencias["sensibilidad_camara_raton"] = valor
	_guardar_y_notificar_camara()


func _al_cambiar_sensibilidad_mando(valor: float) -> void:
	_preferencias["sensibilidad_camara_mando"] = valor
	_guardar_y_notificar_camara()


func _al_cambiar_invertir_y(activa: bool) -> void:
	_preferencias["invertir_camara_y"] = activa
	_guardar_y_notificar_camara()


func _guardar_y_notificar_camara() -> void:
	PreferenciasSiga.guardar(_preferencias)
	get_tree().call_group("caminante_camara", "recargar_preferencias_camara")


func _aplicar_volumen() -> void:
	var volumen := clampf(float(_preferencias.get("volumen", 1.0)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volumen, 0.0001)))
	AudioServer.set_bus_mute(0, volumen <= 0.0)
