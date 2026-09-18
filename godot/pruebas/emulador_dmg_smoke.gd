extends SceneTree

## Gate DMG-only de #456: carga una ROM propia con flag CGB 0x00 y exige que
## SameBoy la ejecute hasta producir un framebuffer 160x144 no uniforme.
## Uso: godot4 --headless --path godot --script res://pruebas/emulador_dmg_smoke.gd -- <rom>

const TAM_FRAME := 160 * 144 * 4
const FRAMES_ARRANQUE := 60


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.is_empty():
		_fallar("falta ruta a la ROM DMG-only")
		return

	var rom := _leer_fixture(String(argumentos[0]))
	if rom.is_empty():
		return

	var emulador := _crear_emulador(rom)
	if emulador == null:
		return

	var frame := _arrancar(emulador)
	if frame.is_empty():
		return

	print("Emulador DMG smoke: OK · %s · %d bytes/frame" % [emulador.call("rom_title"), TAM_FRAME])
	quit(0)


func _leer_fixture(ruta: String) -> PackedByteArray:
	if not FileAccess.file_exists(ruta):
		_fallar("no existe la ROM: %s" % ruta)
		return PackedByteArray()
	var rom := FileAccess.get_file_as_bytes(ruta)
	if rom.size() < 0x150:
		_fallar("ROM DMG truncada")
		return PackedByteArray()
	if int(rom[0x143]) != 0x00:
		_fallar("la fixture no es DMG-only: flag CGB=0x%02X" % int(rom[0x143]))
		return PackedByteArray()
	return rom


func _crear_emulador(rom: PackedByteArray) -> Object:
	if not ClassDB.class_exists(&"Siga98GB"):
		_fallar("Siga98GB no esta registrada")
		return null
	var emulador = ClassDB.instantiate(&"Siga98GB")
	if emulador == null:
		_fallar("no se pudo instanciar Siga98GB")
		return null
	if String(emulador.call("core_name")) != "SameBoy":
		_fallar("el nucleo activo no es SameBoy")
		return null
	if int(emulador.call("load_rom", rom)) != 0:
		_fallar("load_rom fallo: %s" % emulador.call("last_error"))
		return null
	if String(emulador.call("rom_title")).find("SIGA98DMG") < 0:
		_fallar("titulo inesperado: %s" % emulador.call("rom_title"))
		return null
	return emulador


func _arrancar(emulador: Object) -> PackedByteArray:
	var frame := PackedByteArray()
	for _i in range(FRAMES_ARRANQUE):
		frame = emulador.call("run_frame_rgba")
	if not (frame is PackedByteArray) or frame.size() != TAM_FRAME:
		_fallar("framebuffer DMG invalido")
		return PackedByteArray()
	if not _frame_tiene_variacion(frame):
		_fallar("la ROM DMG arranco pero no dibujo un framebuffer util")
		return PackedByteArray()
	return frame


func _frame_tiene_variacion(frame: PackedByteArray) -> bool:
	if frame.size() < 8:
		return false
	for indice in range(4, frame.size(), 4):
		for canal in range(4):
			if frame[indice + canal] != frame[canal]:
				return true
	return false


func _fallar(mensaje: String) -> void:
	push_error("DMG smoke #456: %s" % mensaje)
	quit(1)
