## Presentación breve de intervenciones de compañeros (#276/#397).
##
## No decide qué se dice ni cuándo: recibe el NPC que el jugador acaba de
## activar y el texto ya resuelto por la capa del día. La procedencia deja de
## inferirse por cercanía: el mismo objeto con el que se habló firma el subtítulo.
class_name DialogoDiegetico
extends RefCounted

const DURACION := 3.4
const FRECUENCIA := 22_050
const DURACION_TONO := 0.08

static var _tono_cache: AudioStreamWAV


static func mostrar(
	hud: HUDLayer,
	caminante: Node3D,
	companero: CompaneroInteractivo3D,
	texto: String,
	duracion: float = DURACION,
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "DialogoDiegetico"
	panel.theme = EstiloSiga.tema()
	panel.add_theme_stylebox_override("panel", HUDEstilo.caja_dialogo())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -330
	panel.offset_top = -126
	panel.offset_right = 330
	panel.offset_bottom = -30

	var contenido := VBoxContainer.new()
	contenido.name = "ContenidoDialogoDiegetico"
	contenido.add_theme_constant_override("separation", 4)
	panel.add_child(contenido)

	var nombre := companero.nombre_visible.strip_edges()
	if nombre.is_empty():
		nombre = "…"
	var direccion := _marca_direccion(caminante, companero.global_position)

	var hablante := Label.new()
	hablante.name = "HablanteDialogoDiegetico"
	hablante.text = "%s  %s" % [direccion, nombre]
	hablante.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	hablante.add_theme_color_override("font_color", HUDEstilo.HABLANTE_DIALOGO)
	hablante.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(hablante)

	var etiqueta := Label.new()
	etiqueta.name = "TextoDialogoDiegetico"
	etiqueta.text = texto
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.custom_minimum_size.x = 620
	etiqueta.add_theme_color_override("font_color", HUDEstilo.TEXTO_DIALOGO)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_child(etiqueta)
	hud.add_child(panel)
	hud.registrar(HUDLayer.DIALOGO, panel)
	hud.activar(HUDLayer.DIALOGO)

	Sonido.sonar_stream(hud, _tono())
	if duracion > 0.0:
		hud.get_tree().create_timer(duracion).timeout.connect(_retirar.bind(panel, hud))
	return panel


## Variante interactiva del mismo subtítulo. No crea otro HUD: parte del panel
## diegético normal, suspende únicamente su retirada automática y añade botones
## de rama dentro del mismo contenido.
static func mostrar_eleccion(
	hud: HUDLayer,
	caminante: Node3D,
	companero: CompaneroInteractivo3D,
	texto: String,
	opciones: Array,
	al_elegir: Callable,
) -> PanelContainer:
	var panel := mostrar(hud, caminante, companero, texto, 0.0)
	panel.offset_top = -260
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var contenido := panel.get_node_or_null("ContenidoDialogoDiegetico") as VBoxContainer
	var etiqueta := (
		panel.get_node_or_null("ContenidoDialogoDiegetico/TextoDialogoDiegetico") as Label
	)
	if contenido == null or etiqueta == null:
		hud.get_tree().create_timer(DURACION).timeout.connect(_retirar.bind(panel, hud))
		return panel

	var lista := VBoxContainer.new()
	lista.name = "OpcionesDialogoDiegetico"
	lista.add_theme_constant_override("separation", 6)
	contenido.add_child(lista)

	var primer_boton: Button = null
	for opcion_bruta in opciones:
		if typeof(opcion_bruta) != TYPE_DICTIONARY:
			continue
		var opcion: Dictionary = opcion_bruta
		var id_opcion := String(opcion.get("id", "")).strip_edges()
		var texto_opcion := String(opcion.get("texto", "")).strip_edges()
		if id_opcion.is_empty() or texto_opcion.is_empty():
			continue
		var boton := Button.new()
		boton.text = texto_opcion
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.focus_mode = Control.FOCUS_ALL
		boton.pressed.connect(
			_resolver_eleccion.bind(panel, hud, etiqueta, lista, id_opcion, al_elegir)
		)
		lista.add_child(boton)
		if primer_boton == null:
			primer_boton = boton

	if primer_boton == null:
		hud.get_tree().create_timer(DURACION).timeout.connect(_retirar.bind(panel, hud))
	else:
		primer_boton.call_deferred("grab_focus")
	return panel


static func _resolver_eleccion(
	panel: PanelContainer,
	hud: HUDLayer,
	etiqueta: Label,
	lista: VBoxContainer,
	id_opcion: String,
	al_elegir: Callable,
) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(etiqueta):
		return
	if is_instance_valid(lista):
		lista.visible = false
		for hijo in lista.get_children():
			if hijo is Button:
				hijo.disabled = true

	var respuesta := ""
	if al_elegir.is_valid():
		var valor = al_elegir.call(id_opcion)
		if typeof(valor) == TYPE_STRING:
			respuesta = String(valor)
	if not respuesta.is_empty():
		etiqueta.text = respuesta

	if is_instance_valid(lista):
		lista.queue_free()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(hud):
		hud.get_tree().create_timer(DURACION).timeout.connect(_retirar.bind(panel, hud))


static func _marca_direccion(caminante: Node3D, posicion: Vector3) -> String:
	if caminante == null:
		return "•"
	var hacia := posicion - caminante.global_position
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return "•"
	var derecha := caminante.global_transform.basis.x
	derecha.y = 0.0
	var lateral := derecha.normalized().dot(hacia.normalized())
	if lateral > 0.28:
		return "▶"
	if lateral < -0.28:
		return "◀"
	return "▲"


static func _tono() -> AudioStreamWAV:
	if _tono_cache != null:
		return _tono_cache
	var pista := AudioStreamWAV.new()
	pista.format = AudioStreamWAV.FORMAT_16_BITS
	pista.mix_rate = FRECUENCIA
	pista.stereo = false
	var muestras := int(FRECUENCIA * DURACION_TONO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in muestras:
		var t := float(i) / FRECUENCIA
		var envolvente := 1.0 - float(i) / muestras
		var muestra := sin(TAU * 176.0 * t) * envolvente * 0.16
		var valor := int(clampf(muestra, -1.0, 1.0) * 32767.0)
		if valor < 0:
			valor += 65536
		datos[i * 2] = valor & 0xFF
		datos[i * 2 + 1] = (valor >> 8) & 0xFF
	pista.data = datos
	_tono_cache = pista
	return pista


static func _retirar(panel: PanelContainer, hud: HUDLayer) -> void:
	if is_instance_valid(panel):
		panel.queue_free()
	if is_instance_valid(hud):
		hud.desactivar(HUDLayer.DIALOGO)
