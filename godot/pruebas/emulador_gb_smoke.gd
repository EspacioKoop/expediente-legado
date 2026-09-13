extends SceneTree

const ROM := "res://roms/caza_pixeles_98.gbc"
const BYTES_POR_PIXEL := 4
const TAM_FRAME := 160 * 144 * BYTES_POR_PIXEL


func _init() -> void:
	if _frame_tiene_variacion(PackedByteArray([17, 34, 51, 255, 17, 34, 51, 255])):
		_fallar("la autoprueba aceptó dos píxeles RGBA idénticos")
		return
	if not _frame_tiene_variacion(PackedByteArray([17, 34, 51, 255, 17, 35, 51, 255])):
		_fallar("la autoprueba no detectó variación entre píxeles RGBA")
		return

	if not ClassDB.class_exists(&"Siga98GB"):
		_fallar("Siga98GB no está registrada")
		return
	if not FileAccess.file_exists(ROM):
		_fallar("no existe la ROM propia preparada")
		return

	var emulador = ClassDB.instantiate(&"Siga98GB")
	if emulador == null:
		_fallar("no se pudo instanciar Siga98GB")
		return
	var rom := FileAccess.get_file_as_bytes(ROM)
	var resultado := int(emulador.call("load_rom", rom))
	if resultado != 0:
		_fallar("load_rom falló: %s" % emulador.call("last_error"))
		return

	var frame: PackedByteArray
	for _indice in range(12):
		emulador.call("set_buttons", 0)
		frame = emulador.call("run_frame_rgba")
		if frame.size() != TAM_FRAME:
			_fallar("frame inválido: %d bytes" % frame.size())
			return

	if not _frame_tiene_variacion(frame):
		_fallar("el framebuffer quedó uniforme por píxel RGBA")
		return

	print("Emulador GB smoke: OK · %s · %d bytes/frame" % [emulador.call("rom_title"), TAM_FRAME])
	quit(0)


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
