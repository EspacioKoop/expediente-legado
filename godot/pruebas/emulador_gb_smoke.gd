extends SceneTree

const ROM := "res://roms/caza_pixeles_98.gbc"
const TAM_FRAME := 160 * 144 * 4


func _init() -> void:
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

	var distintos := false
	var primero := frame[0]
	for valor in frame:
		if valor != primero:
			distintos = true
			break
	if not distintos:
		_fallar("el framebuffer quedó uniforme")
		return

	print("Emulador GB smoke: OK · %s · %d bytes/frame" % [emulador.call("rom_title"), TAM_FRAME])
	quit(0)


func _fallar(mensaje: String) -> void:
	push_error("Emulador GB smoke: %s" % mensaje)
	quit(1)
