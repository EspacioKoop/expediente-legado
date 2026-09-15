extends SceneTree

## Gate CGB-only de #456: la ROM `gbc/fixtures/cgb_only_smoke` programa la paleta
## BG con rojo y verde puros. Un núcleo DMG no puede producir esos píxeles, así que
## verlos en el framebuffer demuestra ejecución Game Boy Color real.
## Uso: godot4 --headless --path godot --script res://pruebas/emulador_gbc_smoke.gd -- <rom>

const CARGA_OK := 0
const BYTES_POR_PIXEL := 4
const TAM_FRAME := 160 * 144 * BYTES_POR_PIXEL
const FRAMES := 90


func _init() -> void:
	var rom := _leer_rom()
	if rom.is_empty():
		return
	var emulador := _crear_emulador(rom)
	if emulador == null:
		return
	var frame := _ejecutar_frames(emulador)
	if frame.is_empty():
		return
	if not _contiene(frame, 0) or not _contiene(frame, 1):
		_fallar("el framebuffer no muestra la paleta CGB roja y verde")
		return

	print(
		(
			"Emulador GBC smoke: OK · %s · %s"
			% [emulador.call("core_name"), emulador.call("rom_title")]
		)
	)
	quit(0)


func _leer_rom() -> PackedByteArray:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		_fallar("falta la ruta de la ROM CGB-only")
		return PackedByteArray()
	if not FileAccess.file_exists(args[0]):
		_fallar("no existe la ROM %s" % args[0])
		return PackedByteArray()
	var rom := FileAccess.get_file_as_bytes(args[0])
	if rom.size() <= 0x143 or rom[0x143] != 0xC0:
		_fallar("la ROM no está marcada como CGB-only")
		return PackedByteArray()
	return rom


func _crear_emulador(rom: PackedByteArray) -> Object:
	if not ClassDB.class_exists(&"Siga98GB"):
		_fallar("Siga98GB no está registrada")
		return null
	var emulador = ClassDB.instantiate(&"Siga98GB")
	if not bool(emulador.call("supports_cgb")):
		_fallar("el núcleo %s no declara soporte CGB" % emulador.call("core_name"))
		return null
	var resultado := int(emulador.call("load_rom", rom))
	if resultado != CARGA_OK:
		_fallar("load_rom falló (%d): %s" % [resultado, emulador.call("last_error")])
		return null
	return emulador


func _ejecutar_frames(emulador: Object) -> PackedByteArray:
	var frame := PackedByteArray()
	for _indice in range(FRAMES):
		frame = emulador.call("run_frame_rgba")
		if frame.size() != TAM_FRAME:
			_fallar("frame inválido: %d bytes" % frame.size())
			return PackedByteArray()
	return frame


## Busca un píxel donde el canal indicado domina claramente a los otros dos.
func _contiene(frame: PackedByteArray, canal: int) -> bool:
	for indice in range(0, frame.size(), BYTES_POR_PIXEL):
		var dominante := frame[indice + canal]
		var resto := 0
		for otro in range(3):
			if otro != canal:
				resto = maxi(resto, frame[indice + otro])
		if dominante >= 160 and resto <= 80:
			return true
	return false


func _fallar(mensaje: String) -> void:
	push_error("Emulador GBC smoke: %s" % mensaje)
	quit(1)
