extends SceneTree

const ROM := "res://roms/caza_pixeles_98.gbc"
const BYTES_POR_PIXEL := 4
const TAM_FRAME := 160 * 144 * BYTES_POR_PIXEL
const BYTES_POR_MUESTRA_ESTEREO := 4
const FRECUENCIA_AUDIO := 48000
## La boot ROM CGB de SameBoy tarda ~16 frames en ceder el control al cartucho.
const FRAMES_ARRANQUE := 60


func _init() -> void:
	if not _autoprobar_detector():
		return
	var emulador := _crear_emulador()
	if emulador == null:
		return
	if not _cargar_rom(emulador):
		return
	if not _probar_sram(emulador):
		return
	var frame := _ejecutar_frames(emulador)
	if frame.is_empty():
		return
	if not _frame_tiene_variacion(frame):
		_fallar("el framebuffer quedó uniforme por píxel RGBA")
		return
	var bytes_audio := _probar_audio_nativo(emulador)
	if bytes_audio < 0:
		return

	print(
		(
			"Emulador GB smoke: OK · %s · %d bytes/frame · %d bytes PCM"
			% [emulador.call("rom_title"), TAM_FRAME, bytes_audio]
		)
	)
	quit(0)


func _autoprobar_detector() -> bool:
	var uniforme := PackedByteArray([17, 34, 51, 255, 17, 34, 51, 255])
	if _frame_tiene_variacion(uniforme):
		_fallar("la autoprueba aceptó dos píxeles RGBA idénticos")
		return false
	var variado := PackedByteArray([17, 34, 51, 255, 17, 35, 51, 255])
	if not _frame_tiene_variacion(variado):
		_fallar("la autoprueba no detectó variación entre píxeles RGBA")
		return false
	return true


func _crear_emulador() -> Object:
	if not ClassDB.class_exists(&"Siga98GB"):
		_fallar("Siga98GB no está registrada")
		return null
	var emulador = ClassDB.instantiate(&"Siga98GB")
	if emulador == null:
		_fallar("no se pudo instanciar Siga98GB")
	return emulador


func _cargar_rom(emulador: Object) -> bool:
	if not FileAccess.file_exists(ROM):
		_fallar("no existe la ROM propia preparada")
		return false
	var rom := FileAccess.get_file_as_bytes(ROM)
	var resultado := int(emulador.call("load_rom", rom))
	if resultado != 0:
		_fallar("load_rom falló: %s" % emulador.call("last_error"))
		return false
	return true


func _probar_sram(emulador: Object) -> bool:
	var sram = emulador.call("save_ram")
	if not (sram is PackedByteArray):
		_fallar("save_ram no devolvió PackedByteArray")
		return false
	if not bool(emulador.call("load_save_ram", sram)):
		_fallar("load_save_ram rechazó su propio snapshot")
		return false
	return true


func _ejecutar_frames(emulador: Object) -> PackedByteArray:
	var frame := PackedByteArray()
	for _indice in range(FRAMES_ARRANQUE):
		emulador.call("set_buttons", 0)
		frame = emulador.call("run_frame_rgba")
		if frame.size() != TAM_FRAME:
			_fallar("frame inválido: %d bytes" % frame.size())
			return PackedByteArray()
	return frame


func _probar_audio_nativo(emulador: Object) -> int:
	if bool(emulador.call("supports_audio")):
		_fallar("supports_audio no debe activarse antes de conectar AudioStreamGenerator")
		return -1
	if int(emulador.call("audio_sample_rate")) != FRECUENCIA_AUDIO:
		_fallar("frecuencia PCM inesperada")
		return -1
	var pcm = emulador.call("drain_audio_pcm16")
	if not (pcm is PackedByteArray):
		_fallar("drain_audio_pcm16 no devolvió PackedByteArray")
		return -1
	if pcm.is_empty():
		_fallar("SameBoy no produjo muestras PCM tras ejecutar frames")
		return -1
	if pcm.size() % BYTES_POR_MUESTRA_ESTEREO != 0:
		_fallar("el PCM no está alineado a S16LE estéreo")
		return -1
	var vacio = emulador.call("drain_audio_pcm16")
	if not (vacio is PackedByteArray) or not vacio.is_empty():
		_fallar("drain_audio_pcm16 no vació la cola nativa")
		return -1
	return pcm.size()


func _frame_tiene_variacion(frame: PackedByteArray) -> bool:
	if frame.size() < BYTES_POR_PIXEL * 2 or frame.size() % BYTES_POR_PIXEL != 0:
		return false
	for indice in range(BYTES_POR_PIXEL, frame.size(), BYTES_POR_PIXEL):
		for canal in range(BYTES_POR_PIXEL):
			if frame[indice + canal] != frame[canal]:
				return true
	return false


func _fallar(mensaje: String) -> void:
	push_error("Emulador GB smoke: %s" % mensaje)
	quit(1)
