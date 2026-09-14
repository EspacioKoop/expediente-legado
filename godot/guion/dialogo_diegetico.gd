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
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "DialogoDiegetico"
	panel.theme = EstiloSiga.tema()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -330
	panel.offset_top = -126
	panel.offset_right = 330
	panel.offset_bottom = -30

	var etiqueta := Label.new()
	etiqueta.name = "TextoDialogoDiegetico"
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.custom_minimum_size.x = 620
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var nombre := companero.nombre_visible.strip_edges()
	if nombre.is_empty():
		nombre = "…"
	var direccion := _marca_direccion(caminante, companero.global_position)
	etiqueta.text = "%s  %s\n%s" % [direccion, nombre, texto]
	panel.add_child(etiqueta)
	hud.add_child(panel)
	hud.registrar(HUDLayer.DIALOGO, panel)
	hud.activar(HUDLayer.DIALOGO)

	Sonido.sonar_stream(hud, _tono())
	hud.get_tree().create_timer(DURACION).timeout.connect(_retirar.bind(panel, hud))
	return panel


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
