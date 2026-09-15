## Extensión de EmuladorPortatilApp que reproduce el PCM de SameBoy (#456).
##
## Mantiene el audio de la ROM separado de los sonidos físicos de #245. La cola
## nativa entrega S16LE estéreo a 48 kHz; aquí se convierte a Vector2 y se alimenta
## un AudioStreamGenerator con su propio volumen/mute y un backlog acotado.
class_name EmuladorPortatilAudioApp
extends EmuladorPortatilApp

const AUDIO_SAMPLE_RATE := 48000.0
const AUDIO_BUFFER_LENGTH := 0.12
const AUDIO_BYTES_PER_FRAME := 4
const AUDIO_PCM_SCALE := 32768.0
const MAX_FRAMES_AUDIO_PENDIENTE := 9600
const AUDIO_SILENCIO_DB := -80.0

var _audio_emulado: AudioStreamPlayer
var _audio_playback: AudioStreamGeneratorPlayback
var _audio_pendiente := PackedVector2Array()
var _audio_emulado_muted := false
var _audio_emulado_volumen := 0.80


func abrir() -> void:
	super.abrir()
	_preparar_audio_emulado()


func _process(delta: float) -> void:
	super._process(delta)
	if _jugando and _emulador != null:
		_bombear_audio_emulado()


func _cargar_rom(ruta: String) -> void:
	_limpiar_audio_emulado()
	super._cargar_rom(ruta)


func _cerrar() -> void:
	_limpiar_audio_emulado()
	if _audio_emulado != null:
		_audio_emulado.stop()
	super._cerrar()


func _exit_tree() -> void:
	_limpiar_audio_emulado()
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
	if pcm.is_empty():
		return
	if pcm.size() % AUDIO_BYTES_PER_FRAME != 0:
		push_warning("PCM GB desalineado; se descarta el bloque")
		return
	if _audio_emulado_muted:
		_audio_pendiente.clear()
		_audio_playback.clear_buffer()
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
	if cantidad <= 0:
		return
	var lote := _audio_pendiente.slice(0, cantidad)
	if _audio_playback.push_buffer(lote):
		_audio_pendiente = _audio_pendiente.slice(cantidad)


func _limpiar_audio_emulado() -> void:
	_audio_pendiente.clear()
	if _emulador != null:
		_emulador.call("drain_audio_pcm16")
	if _audio_playback != null:
		_audio_playback.clear_buffer()


func _aplicar_volumen_audio() -> void:
	if _audio_emulado == null:
		return
	if _audio_emulado_muted or _audio_emulado_volumen <= 0.0001:
		_audio_emulado.volume_db = AUDIO_SILENCIO_DB
	else:
		_audio_emulado.volume_db = linear_to_db(_audio_emulado_volumen)
