## Extensión de EmuladorPortatilApp que reproduce el PCM de SameBoy (#456).
##
## Mantiene el audio de la ROM separado de los sonidos físicos de #245. La cola
## nativa entrega S16LE estéreo a 48 kHz; aquí se convierte a Vector2 y se alimenta
## un AudioStreamGenerator con su propio volumen/mute y un backlog acotado.
##
## El cambio de ROM también se presenta como un cartucho físico: con los efectos
## activos se detiene la ROM saliente, se muestra expulsión/ranura/inserción y solo
## entonces se delega el encendido al flujo base. Con efectos desactivados la carga
## sigue siendo inmediata.
class_name EmuladorPortatilAudioApp
extends EmuladorPortatilApp

const AUDIO_SAMPLE_RATE := 48000.0
const AUDIO_BUFFER_LENGTH := 0.12
const AUDIO_BYTES_PER_FRAME := 4
const AUDIO_PCM_SCALE := 32768.0
const MAX_FRAMES_AUDIO_PENDIENTE := 9600
const AUDIO_SILENCIO_DB := -80.0
const DURACION_EXPULSION_CARTUCHO := 0.12
const DURACION_RANURA_VACIA := 0.06
const DURACION_INSERCION_CARTUCHO := 0.14
const DURACION_ENTRADA_AUDIO := 0.18

var link_cable: LinkCablePortatil = null
var puerto_ir: PuertoIRPortatil = null
var impresora_termica: ImpresoraTermicaPortatil = null
var _audio_emulado: AudioStreamPlayer
var _audio_playback: AudioStreamGeneratorPlayback
var _audio_pendiente := PackedVector2Array()
var _audio_emulado_muted := false
var _audio_emulado_volumen := 0.80
var _cartucho_visual: Label
var _link_cable_panel: VBoxContainer
var _link_cable_estado: Label
var _link_cable_boton: Button
var _puerto_ir_panel: VBoxContainer
var _puerto_ir_estado: Label
var _puerto_ir_boton: Button
var _impresora_panel: VBoxContainer
var _impresora_estado: Label
var _impresora_boton: Button
var _ruta_cartucho_actual := ""
var _rom_cartucho_pendiente := ""
var _cambiando_cartucho := false
var _cambio_cartucho_token := 0
var _retardo_audio_restante := 0.0
var _espera_audio_al_arrancar := false


func abrir() -> void:
	super.abrir()
	_preparar_audio_emulado()
	_preparar_cartucho_visual()
	_preparar_link_cable()
	_preparar_puerto_ir()
	_preparar_impresora_termica()


func _process(delta: float) -> void:
	var jugando_antes := _jugando
	super._process(delta)
	if not jugando_antes and _jugando and _espera_audio_al_arrancar:
		_retardo_audio_restante = DURACION_ENTRADA_AUDIO
		_espera_audio_al_arrancar = false
	if _retardo_audio_restante > 0.0:
		_retardo_audio_restante = maxf(0.0, _retardo_audio_restante - maxf(delta, 0.0))
	if _jugando and _emulador != null:
		_bombear_audio_emulado()


func _cargar_rom(ruta: String) -> void:
	_limpiar_audio_emulado()
	_retardo_audio_restante = 0.0
	_espera_audio_al_arrancar = false
	if _emulador == null or ruta.is_empty() or _cambiando_cartucho:
		return
	_espera_audio_al_arrancar = _efectos_presentacion and _imperfecciones_controladas
	if not _efectos_presentacion:
		_ruta_cartucho_actual = ruta
		_actualizar_cartucho_visual()
		super._cargar_rom(ruta)
		return

	_cambiando_cartucho = true
	_rom_cartucho_pendiente = ruta
	_cambio_cartucho_token += 1
	var token := _cambio_cartucho_token
	_guardar_sram()
	_ruta_sram_actual = ""
	_jugando = false
	_tiempo_emulador = 0.0
	_botones_previos = 0
	_cancelar_encendido()

	if not _ruta_cartucho_actual.is_empty():
		_estado.text = _formatear(
			"cartucho_expulsando",
			[_nombre_cartucho(_ruta_cartucho_actual)],
		)
		_reproducir_sonido_fisico(&"cartucho")
		var sigue_expulsion := await _esperar_cambio_cartucho(
			DURACION_EXPULSION_CARTUCHO,
			token,
		)
		if not sigue_expulsion:
			return

	_ruta_cartucho_actual = ""
	_actualizar_cartucho_visual()
	_estado.text = _texto("cartucho_ranura_vacia")
	var sigue_vacio := await _esperar_cambio_cartucho(DURACION_RANURA_VACIA, token)
	if not sigue_vacio:
		return

	_estado.text = _formatear("cartucho_insertando", [_nombre_cartucho(ruta)])
	var sigue_insercion := await _esperar_cambio_cartucho(
		DURACION_INSERCION_CARTUCHO,
		token,
	)
	if not sigue_insercion:
		return

	_mostrar_ruido_contacto()
	_ruta_cartucho_actual = ruta
	_actualizar_cartucho_visual()
	_cambiando_cartucho = false
	_rom_cartucho_pendiente = ""
	# El padre aporta el clic de inserción, el encendido cancelable y la carga real.
	super._cargar_rom(ruta)


func _al_cambiar_efectos(activos: bool) -> void:
	super._al_cambiar_efectos(activos)
	if not activos:
		_retardo_audio_restante = 0.0
		_espera_audio_al_arrancar = false
	if activos or not _cambiando_cartucho:
		return
	var ruta := _rom_cartucho_pendiente
	_cancelar_cambio_cartucho()
	if ruta.is_empty():
		return
	_ruta_cartucho_actual = ruta
	_actualizar_cartucho_visual()
	# Al desactivar presentación en mitad del gesto se salta toda espera restante.
	super._cargar_rom(ruta)


func _al_cambiar_imperfecciones(activos: bool) -> void:
	super._al_cambiar_imperfecciones(activos)
	if not activos:
		_retardo_audio_restante = 0.0
		_espera_audio_al_arrancar = false
	elif _efectos_presentacion and _cambiando_cartucho:
		_espera_audio_al_arrancar = true


func _cerrar() -> void:
	_cancelar_cambio_cartucho()
	_retardo_audio_restante = 0.0
	_espera_audio_al_arrancar = false
	_limpiar_audio_emulado(false)
	if _audio_emulado != null:
		_audio_emulado.stop()
	super._cerrar()


func _exit_tree() -> void:
	_cancelar_cambio_cartucho()
	_retardo_audio_restante = 0.0
	_espera_audio_al_arrancar = false
	_limpiar_audio_emulado(false)
	if _audio_emulado != null:
		_audio_emulado.stop()
	super._exit_tree()


func set_audio_emulado_muted(muted: bool) -> void:
	_audio_emulado_muted = muted
	_aplicar_volumen_audio()
	if muted:
		_limpiar_audio_emulado()


func set_audio_emulado_volumen(volumen: float) -> void:
	_audio_emulado_volumen = clampf(volumen, 0.0, 1.0)
	_aplicar_volumen_audio()


func _preparar_cartucho_visual() -> void:
	if _lista == null:
		return
	_cartucho_visual = Label.new()
	_cartucho_visual.name = "EstadoCartuchoPortatil"
	_cartucho_visual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cartucho_visual.custom_minimum_size = Vector2(0, 42)
	_lista.add_child(_cartucho_visual)
	_lista.move_child(_cartucho_visual, 0)
	_actualizar_cartucho_visual()


func _actualizar_cartucho_visual() -> void:
	if _cartucho_visual == null:
		return
	if _ruta_cartucho_actual.is_empty():
		_cartucho_visual.text = _texto("cartucho_ranura_vacia")
		return
	_cartucho_visual.text = _formatear(
		"cartucho_insertado",
		[_nombre_cartucho(_ruta_cartucho_actual)],
	)


func _nombre_cartucho(ruta: String) -> String:
	var archivo := ruta.get_file()
	var nombre := archivo.get_basename()
	return nombre if not nombre.is_empty() else archivo


func _esperar_cambio_cartucho(segundos: float, token: int) -> bool:
	await get_tree().create_timer(segundos, true).timeout
	return _abierto and token == _cambio_cartucho_token


func _cancelar_cambio_cartucho() -> void:
	_cambio_cartucho_token += 1
	_cambiando_cartucho = false
	_rom_cartucho_pendiente = ""


func _preparar_link_cable() -> void:
	if _lista == null:
		return
	if link_cable == null:
		link_cable = LinkCablePortatil.new()

	_link_cable_panel = VBoxContainer.new()
	_link_cable_panel.name = "PanelLinkCablePortatil"
	_link_cable_panel.add_theme_constant_override("separation", 4)

	var titulo := Label.new()
	titulo.text = _texto("link_cable_titulo")
	_link_cable_panel.add_child(titulo)

	_link_cable_estado = Label.new()
	_link_cable_estado.name = "EstadoLinkCablePortatil"
	_link_cable_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_link_cable_panel.add_child(_link_cable_estado)

	_link_cable_boton = Button.new()
	_link_cable_boton.name = "BotonLinkCablePortatil"
	_link_cable_boton.pressed.connect(_alternar_link_cable)
	_link_cable_panel.add_child(_link_cable_boton)

	var aviso := Label.new()
	aviso.text = _texto("link_cable_aviso")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_link_cable_panel.add_child(aviso)

	_lista.add_child(_link_cable_panel)
	_lista.move_child(_link_cable_panel, mini(1, _lista.get_child_count() - 1))
	link_cable.estado_cambiado.connect(_al_cambiar_estado_link_cable)
	_actualizar_link_cable_ui()


func _alternar_link_cable() -> void:
	if link_cable == null:
		return
	link_cable.alternar()
	_reproducir_sonido_fisico(&"cable")


func _al_cambiar_estado_link_cable(_conectado: bool) -> void:
	_actualizar_link_cable_ui()


func _actualizar_link_cable_ui() -> void:
	if link_cable == null or _link_cable_estado == null or _link_cable_boton == null:
		return
	if link_cable.esta_conectado():
		_link_cable_estado.text = _texto("link_cable_esperando")
		_link_cable_boton.text = _texto("link_cable_desconectar")
	else:
		_link_cable_estado.text = _texto("link_cable_desconectado")
		_link_cable_boton.text = _texto("link_cable_conectar")


func _preparar_puerto_ir() -> void:
	if _lista == null:
		return
	if puerto_ir == null:
		puerto_ir = PuertoIRPortatil.new()

	_puerto_ir_panel = VBoxContainer.new()
	_puerto_ir_panel.name = "PanelPuertoIRPortatil"
	_puerto_ir_panel.add_theme_constant_override("separation", 4)

	var titulo := Label.new()
	titulo.text = _texto("ir_titulo")
	_puerto_ir_panel.add_child(titulo)

	_puerto_ir_estado = Label.new()
	_puerto_ir_estado.name = "EstadoPuertoIRPortatil"
	_puerto_ir_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_puerto_ir_panel.add_child(_puerto_ir_estado)

	_puerto_ir_boton = Button.new()
	_puerto_ir_boton.name = "BotonPuertoIRPortatil"
	_puerto_ir_boton.text = _texto("ir_emitir")
	_puerto_ir_boton.pressed.connect(_emitir_pulso_ir)
	_puerto_ir_panel.add_child(_puerto_ir_boton)

	var aviso := Label.new()
	aviso.text = _texto("ir_aviso")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_puerto_ir_panel.add_child(aviso)

	_lista.add_child(_puerto_ir_panel)
	_lista.move_child(_puerto_ir_panel, mini(2, _lista.get_child_count() - 1))
	puerto_ir.pulso_emitido.connect(_al_pulso_ir)
	_actualizar_puerto_ir_ui(puerto_ir.pulsos_emitidos())


func _emitir_pulso_ir() -> void:
	if puerto_ir == null:
		return
	puerto_ir.emitir_pulso()


func _al_pulso_ir(secuencia: int) -> void:
	_actualizar_puerto_ir_ui(secuencia)


func _actualizar_puerto_ir_ui(secuencia: int) -> void:
	if _puerto_ir_estado == null:
		return
	if secuencia <= 0:
		_puerto_ir_estado.text = _texto("ir_listo")
	else:
		_puerto_ir_estado.text = _formatear("ir_pulso_emitido", [secuencia])


func _preparar_impresora_termica() -> void:
	if _lista == null:
		return
	if impresora_termica == null:
		impresora_termica = ImpresoraTermicaPortatil.new()

	_impresora_panel = VBoxContainer.new()
	_impresora_panel.name = "PanelImpresoraTermica"
	_impresora_panel.add_theme_constant_override("separation", 4)

	var titulo := Label.new()
	titulo.text = _texto("impresora_titulo")
	_impresora_panel.add_child(titulo)

	_impresora_estado = Label.new()
	_impresora_estado.name = "EstadoImpresoraTermica"
	_impresora_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_impresora_panel.add_child(_impresora_estado)

	_impresora_boton = Button.new()
	_impresora_boton.name = "BotonImpresoraTermica"
	_impresora_boton.pressed.connect(_usar_impresora_termica)
	_impresora_panel.add_child(_impresora_boton)

	var aviso := Label.new()
	aviso.text = _texto("impresora_aviso")
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_impresora_panel.add_child(aviso)

	_lista.add_child(_impresora_panel)
	_lista.move_child(_impresora_panel, mini(3, _lista.get_child_count() - 1))
	impresora_termica.estado_cambiado.connect(_al_cambiar_estado_impresora)
	impresora_termica.progreso_cambiado.connect(_al_cambiar_progreso_impresora)
	_actualizar_impresora_termica_ui()


func _usar_impresora_termica() -> void:
	if impresora_termica == null:
		return
	match impresora_termica.estado():
		ImpresoraTermicaPortatil.Estado.APAGADA:
			impresora_termica.encender()
		ImpresoraTermicaPortatil.Estado.LISTA:
			impresora_termica.encolar_imagen(ImpresoraTermicaPortatil.crear_patron_prueba())


func _al_cambiar_estado_impresora(_estado: int) -> void:
	_actualizar_impresora_termica_ui()


func _al_cambiar_progreso_impresora(_progreso: float) -> void:
	_actualizar_impresora_termica_ui()


func _actualizar_impresora_termica_ui() -> void:
	if impresora_termica == null or _impresora_estado == null or _impresora_boton == null:
		return
	match impresora_termica.estado():
		ImpresoraTermicaPortatil.Estado.APAGADA:
			_impresora_estado.text = _texto("impresora_apagada")
			_impresora_boton.text = _texto("impresora_encender")
			_impresora_boton.disabled = false
		ImpresoraTermicaPortatil.Estado.LISTA:
			_impresora_estado.text = _texto("impresora_lista")
			_impresora_boton.text = _texto("impresora_imprimir_prueba")
			_impresora_boton.disabled = false
		ImpresoraTermicaPortatil.Estado.IMPRIMIENDO:
			var porcentaje := int(round(impresora_termica.progreso() * 100.0))
			_impresora_estado.text = _formatear("impresora_imprimiendo", [porcentaje])
			_impresora_boton.text = _texto("impresora_imprimiendo_boton")
			_impresora_boton.disabled = true
		ImpresoraTermicaPortatil.Estado.PAPEL_DISPONIBLE:
			_impresora_estado.text = _texto("impresora_papel_disponible")
			_impresora_boton.text = _texto("impresora_recoger_en_casa")
			_impresora_boton.disabled = true


func _preparar_audio_emulado() -> void:
	if _emulador == null or not bool(_emulador.call("supports_audio")):
		return
	var frecuencia := float(_emulador.call("audio_sample_rate"))
	if not is_equal_approx(frecuencia, AUDIO_SAMPLE_RATE):
		push_warning("Frecuencia inesperada del audio GB: %s Hz" % frecuencia)
		return

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = AUDIO_SAMPLE_RATE
	stream.buffer_length = AUDIO_BUFFER_LENGTH
	_audio_emulado = AudioStreamPlayer.new()
	_audio_emulado.name = "AudioEmuladoPortatil"
	_audio_emulado.process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_emulado.stream = stream
	add_child(_audio_emulado)
	_aplicar_volumen_audio()
	_audio_emulado.play()
	_audio_playback = _audio_emulado.get_stream_playback() as AudioStreamGeneratorPlayback
	if _audio_playback == null:
		push_warning("No se pudo obtener AudioStreamGeneratorPlayback para la portátil")


func _bombear_audio_emulado() -> void:
	if _audio_playback == null or _emulador == null:
		return
	var pcm_variante = _emulador.call("drain_audio_pcm16")
	if not (pcm_variante is PackedByteArray):
		return
	var pcm: PackedByteArray = pcm_variante
	var descartar := pcm.is_empty()
	if pcm.size() % AUDIO_BYTES_PER_FRAME != 0:
		push_warning("PCM GB desalineado; se descarta el bloque")
		descartar = true
	if _retardo_audio_restante > 0.0:
		# El núcleo sigue avanzando: el PCM se drena y se descarta solo como presentación.
		_audio_pendiente.clear()
		descartar = true
	if _audio_emulado_muted:
		# El búfer ya se vació al silenciar; aquí basta con no acumular.
		_audio_pendiente.clear()
		descartar = true
	if descartar:
		return

	var cantidad_frames := int(pcm.size() / AUDIO_BYTES_PER_FRAME)
	var nuevos_frames := PackedVector2Array()
	nuevos_frames.resize(cantidad_frames)
	for indice in range(nuevos_frames.size()):
		var offset := indice * AUDIO_BYTES_PER_FRAME
		nuevos_frames[indice] = Vector2(
			float(pcm.decode_s16(offset)) / AUDIO_PCM_SCALE,
			float(pcm.decode_s16(offset + 2)) / AUDIO_PCM_SCALE,
		)
	_audio_pendiente.append_array(nuevos_frames)
	if _audio_pendiente.size() > MAX_FRAMES_AUDIO_PENDIENTE:
		_audio_pendiente = (
			_audio_pendiente
			. slice(
				_audio_pendiente.size() - MAX_FRAMES_AUDIO_PENDIENTE,
			)
		)

	var disponibles := _audio_playback.get_frames_available()
	var cantidad := mini(disponibles, _audio_pendiente.size())
	if cantidad > 0:
		var lote := _audio_pendiente.slice(0, cantidad)
		if _audio_playback.push_buffer(lote):
			_audio_pendiente = _audio_pendiente.slice(cantidad)


func _limpiar_audio_emulado(reanudar: bool = true) -> void:
	_audio_pendiente.clear()
	if _emulador != null:
		_emulador.call("drain_audio_pcm16")
	if not reanudar or not is_inside_tree():
		_audio_playback = null
	elif _audio_emulado != null and _audio_playback != null:
		# `clear_buffer()` falla con el generador activo, y `playing` no basta
		# para saberlo (con el árbol en pausa sigue activo). Reiniciar el player
		# descarta lo encolado y deja un playback nuevo y vacío.
		_audio_emulado.stop()
		_audio_emulado.play()
		_audio_playback = _audio_emulado.get_stream_playback() as AudioStreamGeneratorPlayback


func _aplicar_volumen_audio() -> void:
	if _audio_emulado == null:
		return
	if _audio_emulado_muted or _audio_emulado_volumen <= 0.0001:
		_audio_emulado.volume_db = AUDIO_SILENCIO_DB
	else:
		_audio_emulado.volume_db = linear_to_db(_audio_emulado_volumen)
