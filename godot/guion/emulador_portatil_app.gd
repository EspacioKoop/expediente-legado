## Superficie aislada para ejecutar ROMs GB desde la Portátil Color 98 (#124/#245).
##
## La UI pausa el mundo mientras está abierta y solo habla con la clase nativa
## Siga98GB. No conoce estado persistente, casos, economía ni guardados de campaña.
## La materialidad de #245 vive fuera del núcleo: un encendido breve antes de
## cargar, un shader LCD desactivable y sonidos físicos procedurales separados.
class_name EmuladorPortatilApp
extends CanvasLayer

signal cerrado

const TEXTOS := "res://datos/emulador_gb_textos.json"
const SRAM_DIR := "user://sram/gb"
const ANCHO := 160
const ALTO := 144
const CICLOS_CPU_DMG := 4194304.0
const CICLOS_POR_FRAME_DMG := 70224.0
const FPS_EMULADOR := CICLOS_CPU_DMG / CICLOS_POR_FRAME_DMG
const PASO_EMULADOR := 1.0 / FPS_EMULADOR
const MAX_FRAMES_POR_TICK := 4
const DURACION_ENCENDIDO := 0.32
const FRECUENCIA_SONIDO_FISICO := 22050
const VOLUMEN_SONIDO_FISICO_DB := -18.0

const SHADER_LCD := """
shader_type canvas_item;
uniform bool filtro_lcd = true;
uniform float variacion_brillo = 0.0;
uniform bool paleta_gb_activa = false;
uniform vec4 paleta_0 : source_color = vec4(0.10, 0.12, 0.10, 1.0);
uniform vec4 paleta_1 : source_color = vec4(0.28, 0.34, 0.24, 1.0);
uniform vec4 paleta_2 : source_color = vec4(0.58, 0.64, 0.42, 1.0);
uniform vec4 paleta_3 : source_color = vec4(0.86, 0.88, 0.68, 1.0);

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec3 rgb = base.rgb;
    if (filtro_lcd) {
        vec2 uv_previa = clamp(
            UV - vec2(TEXTURE_PIXEL_SIZE.x, 0.0),
            vec2(0.0),
            vec2(1.0)
        );
        vec4 arrastre = texture(TEXTURE, uv_previa);
        float rejilla = 1.0;
        if (mod(floor(FRAGCOORD.y), 3.0) < 1.0) {
            rejilla = 0.92;
        }
        rgb = mix(base.rgb, arrastre.rgb, 0.06) * rejilla;
        rgb *= 1.0 + variacion_brillo;
    }
    if (paleta_gb_activa) {
        float luma = dot(rgb, vec3(0.2126, 0.7152, 0.0722));
        if (luma < 0.25) {
            rgb = paleta_0.rgb;
        } else if (luma < 0.50) {
            rgb = paleta_1.rgb;
        } else if (luma < 0.75) {
            rgb = paleta_2.rgb;
        } else {
            rgb = paleta_3.rgb;
        }
    }
    COLOR = vec4(rgb, base.a);
}
"""

const BTN_A := 0x01
const BTN_B := 0x02
const BTN_SELECT := 0x04
const BTN_START := 0x08
const BTN_RIGHT := 0x10
const BTN_LEFT := 0x20
const BTN_UP := 0x40
const BTN_DOWN := 0x80

## Qué ROMs propias hay en el selector: incluidas + compradas (RomsPropias).
var roms_compradas: Array = []
var _textos: Dictionary = {}
var _emulador: Object = null
var _vista: TextureRect
var _estado: Label
var _lista: VBoxContainer
var _textura: ImageTexture
var _lcd_material: ShaderMaterial
var _paleta_selector: OptionButton
var _velo_encendido: ColorRect
var _audio_fisico: AudioStreamPlayer
var _sonidos_fisicos_cache: Dictionary = {}
var _jugando := false
var _pausa_anterior := false
var _abierto := false
var _tiempo_emulador := 0.0
var _tiempo_presentacion := 0.0
var _ruta_sram_actual := ""
var _huella_rom_actual := ""
var _rom_gb_clasica_actual := false
var _efectos_presentacion := true
var _imperfecciones_controladas := false
var _sonidos_fisicos := true
var _encendiendo := false
var _tiempo_encendido := 0.0
var _rom_pendiente := ""
var _botones_previos := 0
var _raton_anterior := Input.MOUSE_MODE_VISIBLE


func abrir() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_textos = _cargar_textos()
	_pausa_anterior = get_tree().paused
	get_tree().paused = true
	# Se abre desde el mundo 3D, que tiene el ratón capturado: sin soltarlo no
	# hay cursor con el que elegir cartucho.
	_raton_anterior = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_abierto = true
	_tiempo_emulador = 0.0
	_construir_ui()
	_preparar_audio_fisico()
	_preparar_nucleo()
	_refrescar_roms()
	_enfocar_primera_rom.call_deferred()
	set_process(true)


func _process(delta: float) -> void:
	_actualizar_variacion_lcd(delta)
	if _encendiendo:
		_actualizar_encendido(delta)
		return
	if not _jugando or _emulador == null:
		return

	_tiempo_emulador = minf(
		_tiempo_emulador + maxf(delta, 0.0),
		PASO_EMULADOR * MAX_FRAMES_POR_TICK,
	)
	var botones := _botones()
	_emulador.call("set_buttons", botones)
	if botones != 0 and (botones & ~_botones_previos) != 0:
		_reproducir_sonido_fisico(&"boton")
	_botones_previos = botones

	var datos := PackedByteArray()
	var frames_ejecutados := 0
	while _tiempo_emulador >= PASO_EMULADOR and frames_ejecutados < MAX_FRAMES_POR_TICK:
		datos = _emulador.call("run_frame_rgba")
		if datos.size() != ANCHO * ALTO * 4:
			_jugando = false
			_tiempo_emulador = 0.0
			_estado.text = _formatear("error_runtime", [_emulador.call("last_error")])
			return
		_tiempo_emulador -= PASO_EMULADOR
		frames_ejecutados += 1

	if datos.is_empty():
		return
	var imagen := Image.create_from_data(ANCHO, ALTO, false, Image.FORMAT_RGBA8, datos)
	if _textura == null:
		_textura = ImageTexture.create_from_image(imagen)
		_vista.texture = _textura
	else:
		_textura.update(imagen)


func _input(event: InputEvent) -> void:
	if not _abierto:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cerrar()
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventJoypadButton or not event.pressed:
		return
	# Con un juego en marcha todos los botones son de la consola; salir pide
	# Select + Start a la vez, que ningún juego usa como jugada.
	if _jugando or _encendiendo:
		var combinacion: bool = (
			(event.button_index == JOY_BUTTON_START and _joy(JOY_BUTTON_BACK))
			or (event.button_index == JOY_BUTTON_BACK and _joy(JOY_BUTTON_START))
		)
		if combinacion:
			_cerrar()
		# Que la cruceta y A no muevan ni pulsen los botones de la lista.
		get_viewport().set_input_as_handled()
	elif event.button_index == JOY_BUTTON_B:
		_cerrar()
		get_viewport().set_input_as_handled()


func _enfocar_primera_rom() -> void:
	for hijo in _lista.get_children():
		if hijo is Button:
			hijo.grab_focus()
			return


func _exit_tree() -> void:
	_guardar_sram()
	if _abierto and get_tree() != null:
		get_tree().paused = _pausa_anterior
	_abierto = false


func _construir_ui() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.025, 0.03, 0.028, 0.97)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 36)
	margen.add_theme_constant_override("margin_right", 36)
	margen.add_theme_constant_override("margin_top", 24)
	margen.add_theme_constant_override("margin_bottom", 24)
	add_child(margen)

	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 12)
	margen.add_child(raiz)

	var titulo := Label.new()
	titulo.text = _texto("titulo")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 26)
	raiz.add_child(titulo)

	var cuerpo := HBoxContainer.new()
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_theme_constant_override("separation", 24)
	raiz.add_child(cuerpo)

	var izquierda := VBoxContainer.new()
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(izquierda)

	_vista = TextureRect.new()
	_vista.custom_minimum_size = Vector2(480, 432)
	_vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_vista.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preparar_filtro_lcd()
	izquierda.add_child(_vista)

	_velo_encendido = ColorRect.new()
	_velo_encendido.name = "VeloEncendidoLCD"
	_velo_encendido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo_encendido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_velo_encendido.color = Color(0.70, 0.80, 0.69, 0.0)
	_velo_encendido.visible = false
	_vista.add_child(_velo_encendido)

	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.custom_minimum_size = Vector2(480, 52)
	izquierda.add_child(_estado)

	# La columna crece con cada cartucho comprado: sin desplazamiento, «Cerrar»
	# acababa fuera de la ventana.
	var desplazable := ScrollContainer.new()
	desplazable.custom_minimum_size = Vector2(380, 0)
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desplazable.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(desplazable)
	var derecha := VBoxContainer.new()
	derecha.custom_minimum_size = Vector2(360, 0)
	derecha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	derecha.add_theme_constant_override("separation", 8)
	desplazable.add_child(derecha)

	var carpeta := Label.new()
	carpeta.text = _formatear("carpeta", [CatalogoRomsUsuario.ruta_absoluta()])
	carpeta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(carpeta)

	var efectos := CheckButton.new()
	efectos.text = _texto("efectos_presentacion")
	efectos.button_pressed = _efectos_presentacion
	efectos.toggled.connect(_al_cambiar_efectos)
	derecha.add_child(efectos)

	var efectos_aviso := Label.new()
	efectos_aviso.text = _texto("efectos_aviso")
	efectos_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(efectos_aviso)

	var imperfecciones := CheckButton.new()
	imperfecciones.name = "ImperfeccionesControladasPortatil"
	imperfecciones.text = _texto("imperfecciones_controladas")
	imperfecciones.button_pressed = _imperfecciones_controladas
	imperfecciones.toggled.connect(_al_cambiar_imperfecciones)
	derecha.add_child(imperfecciones)

	var imperfecciones_aviso := Label.new()
	imperfecciones_aviso.text = _texto("imperfecciones_aviso")
	imperfecciones_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(imperfecciones_aviso)

	_preparar_selector_paleta(derecha)

	var sonidos := CheckButton.new()
	sonidos.text = _texto("sonidos_fisicos")
	sonidos.button_pressed = _sonidos_fisicos
	sonidos.toggled.connect(_al_cambiar_sonidos)
	derecha.add_child(sonidos)

	var sonidos_aviso := Label.new()
	sonidos_aviso.text = _texto("sonidos_fisicos_aviso")
	sonidos_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(sonidos_aviso)

	_lista = VBoxContainer.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	derecha.add_child(_lista)

	var aviso := Label.new()
	aviso.text = _texto("aviso")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(aviso)

	var audio := Label.new()
	audio.text = _texto("audio")
	audio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	derecha.add_child(audio)

	var salir := Button.new()
	salir.text = _texto("cerrar")
	salir.pressed.connect(_cerrar)
	derecha.add_child(salir)


func _preparar_filtro_lcd() -> void:
	var shader := Shader.new()
	shader.code = SHADER_LCD
	_lcd_material = ShaderMaterial.new()
	_lcd_material.shader = shader
	_lcd_material.set_shader_parameter("filtro_lcd", _efectos_presentacion)
	_lcd_material.set_shader_parameter("paleta_gb_activa", false)
	_vista.material = _lcd_material


func _preparar_selector_paleta(contenedor: VBoxContainer) -> void:
	var titulo := Label.new()
	titulo.text = _texto("paleta_gb_titulo")
	contenedor.add_child(titulo)

	_paleta_selector = OptionButton.new()
	_paleta_selector.name = "SelectorPaletaGbClasico"
	for id in PaletasGbClasico.ids():
		var indice := _paleta_selector.item_count
		_paleta_selector.add_item(PaletasGbClasico.nombre(id))
		_paleta_selector.set_item_metadata(indice, id)
	_paleta_selector.disabled = true
	_paleta_selector.item_selected.connect(_al_seleccionar_paleta)
	contenedor.add_child(_paleta_selector)

	var aviso := Label.new()
	aviso.text = _texto("paleta_gb_aviso")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contenedor.add_child(aviso)


func _preparar_audio_fisico() -> void:
	_audio_fisico = AudioStreamPlayer.new()
	_audio_fisico.name = "AudioFisicoPortatil"
	_audio_fisico.process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_fisico.volume_db = VOLUMEN_SONIDO_FISICO_DB
	add_child(_audio_fisico)
	_sonidos_fisicos_cache = {
		&"encendido": _crear_sonido_fisico(95.0, 230.0, 0.055, 0.52),
		&"apagado": _crear_sonido_fisico(230.0, 72.0, 0.065, 0.50),
		&"cartucho": _crear_sonido_fisico(170.0, 65.0, 0.070, 0.58),
		&"cable": _crear_sonido_fisico(240.0, 105.0, 0.050, 0.36),
		&"boton": _crear_sonido_fisico(760.0, 420.0, 0.028, 0.30),
	}


func _crear_sonido_fisico(
	frecuencia_inicial: float, frecuencia_final: float, duracion: float, intensidad: float
) -> AudioStreamWAV:
	var muestras := maxi(1, int(round(duracion * FRECUENCIA_SONIDO_FISICO)))
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	var fase := 0.0
	for indice in range(muestras):
		var progreso := float(indice) / float(maxi(muestras - 1, 1))
		var frecuencia := lerpf(frecuencia_inicial, frecuencia_final, progreso)
		fase += TAU * frecuencia / float(FRECUENCIA_SONIDO_FISICO)
		var envolvente := 1.0 - progreso
		envolvente *= envolvente
		var onda := sin(fase) * 0.78 + sin(fase * 2.11) * 0.22
		var muestra := int(clampf(onda * envolvente * intensidad, -1.0, 1.0) * 32767.0)
		datos.encode_s16(indice * 2, muestra)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = FRECUENCIA_SONIDO_FISICO
	stream.stereo = false
	stream.data = datos
	return stream


func _reproducir_sonido_fisico(tipo: StringName) -> void:
	if not _sonidos_fisicos or _audio_fisico == null:
		return
	var sonido = _sonidos_fisicos_cache.get(tipo)
	if sonido is not AudioStream:
		return
	_audio_fisico.stream = sonido
	_audio_fisico.play()


func _al_cambiar_sonidos(activos: bool) -> void:
	_sonidos_fisicos = activos
	if not activos and _audio_fisico != null:
		_audio_fisico.stop()


func _al_cambiar_imperfecciones(activos: bool) -> void:
	_imperfecciones_controladas = activos


func _mostrar_ruido_contacto() -> void:
	if (
		not _efectos_presentacion
		or not _imperfecciones_controladas
		or _vista == null
		or not is_instance_valid(_vista)
	):
		return
	var efecto := EfectoContactoCartucho.new()
	_vista.add_child(efecto)
	efecto.iniciar()


func _preparar_nucleo() -> void:
	if not ClassDB.class_exists(&"Siga98GB"):
		_estado.text = _texto("sin_nucleo")
		return
	_emulador = ClassDB.instantiate(&"Siga98GB")


func _refrescar_roms() -> void:
	for hijo in _lista.get_children():
		hijo.queue_free()

	var entradas: Array[Dictionary] = []
	var propias := RomsPropias.en_consola(roms_compradas)
	for rom in propias:
		var etiqueta := "rom_propia" if bool(rom.get("incluida", false)) else "rom_comprada"
		entradas.append({"nombre": _formatear(etiqueta, [rom["titulo"]]), "ruta": rom["rom"]})
	if propias.is_empty() and _emulador != null:
		_estado.text = _texto("rom_propia_ausente")
	entradas.append_array(CatalogoRomsUsuario.listar())

	if entradas.is_empty():
		var vacio := Label.new()
		vacio.text = _texto("sin_roms")
		vacio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_lista.add_child(vacio)
		return

	for entrada in entradas:
		var boton := Button.new()
		boton.text = String(entrada.get("nombre", ""))
		boton.pressed.connect(_cargar_rom.bind(String(entrada.get("ruta", ""))))
		_lista.add_child(boton)


func _cargar_rom(ruta: String) -> void:
	if _emulador == null or ruta.is_empty():
		return
	_guardar_sram()
	_ruta_sram_actual = ""
	_reproducir_sonido_fisico(&"cartucho")
	# El foco se suelta: si no, A y la cruceta seguirían pulsando la lista
	# mientras se juega.
	get_viewport().gui_release_focus()
	if not _efectos_presentacion:
		_cargar_rom_ahora(ruta)
		return

	_jugando = false
	_tiempo_emulador = 0.0
	_rom_pendiente = ruta
	_tiempo_encendido = DURACION_ENCENDIDO
	_encendiendo = true
	_estado.text = _texto("encendiendo")
	if _velo_encendido != null:
		_velo_encendido.color = Color(0.70, 0.80, 0.69, 0.92)
		_velo_encendido.visible = true


func _actualizar_encendido(delta: float) -> void:
	_tiempo_encendido = maxf(0.0, _tiempo_encendido - maxf(delta, 0.0))
	if _velo_encendido != null:
		var proporcion := _tiempo_encendido / DURACION_ENCENDIDO
		_velo_encendido.color = Color(0.70, 0.80, 0.69, proporcion * 0.92)
	if _tiempo_encendido > 0.0:
		return

	var ruta := _rom_pendiente
	_cancelar_encendido()
	_reproducir_sonido_fisico(&"encendido")
	_cargar_rom_ahora(ruta)


func _cancelar_encendido() -> void:
	_encendiendo = false
	_tiempo_encendido = 0.0
	_rom_pendiente = ""
	if _velo_encendido != null:
		_velo_encendido.visible = false


func _al_cambiar_efectos(activos: bool) -> void:
	_efectos_presentacion = activos
	if _lcd_material != null:
		_lcd_material.set_shader_parameter("filtro_lcd", activos)
		if not activos:
			_lcd_material.set_shader_parameter("variacion_brillo", 0.0)
	if activos or not _encendiendo:
		return

	var ruta := _rom_pendiente
	_cancelar_encendido()
	_reproducir_sonido_fisico(&"encendido")
	_cargar_rom_ahora(ruta)


func _cargar_rom_ahora(ruta: String) -> void:
	if _emulador == null or ruta.is_empty():
		return
	_estado.text = _formatear("cargando", [ruta.get_file()])
	var rom := FileAccess.get_file_as_bytes(ruta)
	var resultado := int(_emulador.call("load_rom", rom))
	if resultado == 3:
		_estado.text = _texto("error_cgb")
		_jugando = false
		_tiempo_emulador = 0.0
		return
	if resultado != 0:
		_estado.text = _formatear("error_rom", [_emulador.call("last_error")])
		_jugando = false
		_tiempo_emulador = 0.0
		return
	_huella_rom_actual = _huella_rom(rom)
	_rom_gb_clasica_actual = _es_rom_gb_clasica(rom)
	_configurar_paleta_rom_actual()
	_ruta_sram_actual = _ruta_sram(rom)
	_restaurar_sram()
	_tiempo_emulador = 0.0
	_botones_previos = 0
	_jugando = true
	var titulo := String(_emulador.call("rom_title"))
	if titulo.is_empty():
		titulo = ruta.get_file()
	_estado.text = _formatear("ejecutando", [titulo])


func _huella_rom(rom: PackedByteArray) -> String:
	var contexto := HashingContext.new()
	if contexto.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if contexto.update(rom) != OK:
		return ""
	return contexto.finish().hex_encode()


func _ruta_sram(rom: PackedByteArray) -> String:
	var huella := _huella_rom(rom)
	return SRAM_DIR + "/" + huella + ".sav" if not huella.is_empty() else ""


func _es_rom_gb_clasica(rom: PackedByteArray) -> bool:
	return rom.size() > 0x143 and int(rom[0x143]) == 0x00


func _configurar_paleta_rom_actual() -> void:
	if _paleta_selector == null:
		return
	_paleta_selector.disabled = not _rom_gb_clasica_actual
	var id := PaletasGbClasico.NORMAL
	if _rom_gb_clasica_actual:
		id = PaletasGbClasico.cargar_preferencia(_huella_rom_actual)
	_seleccionar_paleta_en_ui(id)
	_aplicar_paleta(id)


func _seleccionar_paleta_en_ui(id: String) -> void:
	if _paleta_selector == null:
		return
	for indice in range(_paleta_selector.item_count):
		if String(_paleta_selector.get_item_metadata(indice)) == id:
			_paleta_selector.select(indice)
			return
	_paleta_selector.select(0)


func _al_seleccionar_paleta(indice: int) -> void:
	if (
		_paleta_selector == null
		or _paleta_selector.disabled
		or not _rom_gb_clasica_actual
		or indice < 0
		or indice >= _paleta_selector.item_count
	):
		return
	var id := String(_paleta_selector.get_item_metadata(indice))
	_aplicar_paleta(id)
	if not PaletasGbClasico.guardar_preferencia(_huella_rom_actual, id):
		push_warning("No se pudo guardar la paleta de GB para esta ROM")


func _aplicar_paleta(id: String) -> void:
	if _lcd_material == null:
		return
	var activa := _rom_gb_clasica_actual and id != PaletasGbClasico.NORMAL
	if not activa:
		_lcd_material.set_shader_parameter("paleta_gb_activa", false)
		return
	var colores := PaletasGbClasico.colores(id)
	if colores.size() != 4:
		_lcd_material.set_shader_parameter("paleta_gb_activa", false)
		return
	for indice in range(4):
		_lcd_material.set_shader_parameter("paleta_%d" % indice, colores[indice])
	_lcd_material.set_shader_parameter("paleta_gb_activa", true)


func _restaurar_sram() -> void:
	if _emulador == null or _ruta_sram_actual.is_empty():
		return
	_recuperar_respaldo_sram()
	if not FileAccess.file_exists(_ruta_sram_actual):
		return
	var datos := FileAccess.get_file_as_bytes(_ruta_sram_actual)
	if bool(_emulador.call("load_save_ram", datos)):
		return
	var rota := _ruta_sram_actual + ".roto"
	_eliminar_si_existe(rota)
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_ruta_sram_actual), ProjectSettings.globalize_path(rota)
	)
	if error != OK:
		push_warning("No se pudo apartar SRAM incompatible: %s" % _ruta_sram_actual)
	else:
		push_warning("SRAM incompatible apartada en %s" % rota)


func _guardar_sram() -> bool:
	var datos := PackedByteArray()
	if _emulador != null and not _ruta_sram_actual.is_empty():
		datos = _emulador.call("save_ram")
	if datos.is_empty():
		return true
	var carpeta_absoluta := ProjectSettings.globalize_path(SRAM_DIR)
	var error_carpeta := DirAccess.make_dir_recursive_absolute(carpeta_absoluta)
	if error_carpeta != OK and error_carpeta != ERR_ALREADY_EXISTS:
		push_warning("No se pudo preparar la carpeta de SRAM")
		return false

	var temporal := _ruta_sram_actual + ".nuevo"
	var respaldo := _ruta_sram_actual + ".anterior"
	var archivo := FileAccess.open(temporal, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo escribir SRAM temporal")
		return false
	archivo.store_buffer(datos)
	archivo.flush()
	archivo.close()

	_eliminar_si_existe(respaldo)
	if FileAccess.file_exists(_ruta_sram_actual):
		var mover_actual := (
			DirAccess
			. rename_absolute(
				ProjectSettings.globalize_path(_ruta_sram_actual),
				ProjectSettings.globalize_path(respaldo),
			)
		)
		if mover_actual != OK:
			_eliminar_si_existe(temporal)
			push_warning("No se pudo preparar el reemplazo de SRAM")
			return false

	var mover_nuevo := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporal), ProjectSettings.globalize_path(_ruta_sram_actual)
	)
	if mover_nuevo != OK:
		if FileAccess.file_exists(respaldo):
			(
				DirAccess
				. rename_absolute(
					ProjectSettings.globalize_path(respaldo),
					ProjectSettings.globalize_path(_ruta_sram_actual),
				)
			)
		_eliminar_si_existe(temporal)
		push_warning("No se pudo reemplazar la SRAM")
		return false
	_eliminar_si_existe(respaldo)
	return true


func _recuperar_respaldo_sram() -> void:
	var respaldo := _ruta_sram_actual + ".anterior"
	if FileAccess.file_exists(_ruta_sram_actual) or not FileAccess.file_exists(respaldo):
		return
	(
		DirAccess
		. rename_absolute(
			ProjectSettings.globalize_path(respaldo),
			ProjectSettings.globalize_path(_ruta_sram_actual),
		)
	)


func _eliminar_si_existe(ruta: String) -> void:
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))


func _botones() -> int:
	var botones := 0
	if _tecla(KEY_RIGHT) or _tecla(KEY_D) or _joy(JOY_BUTTON_DPAD_RIGHT):
		botones |= BTN_RIGHT
	if _tecla(KEY_LEFT) or _tecla(KEY_A) or _joy(JOY_BUTTON_DPAD_LEFT):
		botones |= BTN_LEFT
	if _tecla(KEY_UP) or _tecla(KEY_W) or _joy(JOY_BUTTON_DPAD_UP):
		botones |= BTN_UP
	if _tecla(KEY_DOWN) or _tecla(KEY_S) or _joy(JOY_BUTTON_DPAD_DOWN):
		botones |= BTN_DOWN
	if _tecla(KEY_Z) or _tecla(KEY_SPACE) or _joy(JOY_BUTTON_A):
		botones |= BTN_A
	if _tecla(KEY_X) or _joy(JOY_BUTTON_B):
		botones |= BTN_B
	if _tecla(KEY_ENTER) or _joy(JOY_BUTTON_START):
		botones |= BTN_START
	if _tecla(KEY_TAB) or _joy(JOY_BUTTON_BACK):
		botones |= BTN_SELECT
	return botones


func _tecla(codigo: Key) -> bool:
	return Input.is_key_pressed(codigo)


func _joy(boton: JoyButton) -> bool:
	return Input.is_joy_button_pressed(0, boton)


func _actualizar_variacion_lcd(delta: float) -> void:
	if _lcd_material == null:
		return
	if not _efectos_presentacion:
		_lcd_material.set_shader_parameter("variacion_brillo", 0.0)
		return
	_tiempo_presentacion += maxf(delta, 0.0)
	# Variación determinista y deliberadamente pequeña: materialidad, no fallo.
	var variacion := sin(_tiempo_presentacion * 1.7) * 0.012
	_lcd_material.set_shader_parameter("variacion_brillo", variacion)


func _lanzar_apagado_fisico() -> void:
	if get_tree() == null:
		return
	var textura: Texture2D = null
	var material_lcd: Material = null
	var rect := Rect2()
	if _efectos_presentacion and _vista != null and _vista.texture != null:
		textura = _vista.texture
		material_lcd = _vista.material
		rect = _vista.get_global_rect()
	var sonido: AudioStream = null
	if _sonidos_fisicos:
		var candidato = _sonidos_fisicos_cache.get(&"apagado")
		if candidato is AudioStream:
			sonido = candidato
	if textura == null and sonido == null:
		return
	var efecto := EfectoApagadoPortatil.new()
	get_tree().root.add_child(efecto)
	efecto.iniciar(textura, material_lcd, rect, sonido, VOLUMEN_SONIDO_FISICO_DB)


func _cerrar() -> void:
	if not _abierto:
		return
	_guardar_sram()
	_jugando = false
	_tiempo_emulador = 0.0
	_botones_previos = 0
	_cancelar_encendido()
	# El residuo visual/sonoro queda en root y no retiene la UI ni el mundo pausado.
	_lanzar_apagado_fisico()
	if _audio_fisico != null:
		_audio_fisico.stop()
	_abierto = false
	get_tree().paused = _pausa_anterior
	Input.mouse_mode = _raton_anterior
	cerrado.emit()
	queue_free()


func _cargar_textos() -> Dictionary:
	if not FileAccess.file_exists(TEXTOS):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(TEXTOS))
	return datos if datos is Dictionary else {}


func _texto(clave: String) -> String:
	return String(_textos.get(clave, clave))


func _formatear(clave: String, valores: Array) -> String:
	return _texto(clave) % valores
