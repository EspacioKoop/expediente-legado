extends SceneTree

## Gate end-to-end de #456: usa la UI real de la Portátil Color 98 para
## persistir SRAM a disco, reabrirla en otra instancia y aislar dos ROMs.
const FRAMES_ARRANQUE := 60
const MARCADOR_A := 0x31
const MARCADOR_B := 0x42
const SRAM_DIR := "user://sram/gb"


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.size() != 2:
		_fallar("se esperaban las rutas de sram_a.gbc y sram_b.gbc")
		return
	if not ClassDB.class_exists(&"Siga98GB"):
		_fallar("Siga98GB no está registrada")
		return
	if not _probar(String(argumentos[0]), String(argumentos[1])):
		return
	print("Emulador SRAM smoke: OK · cierre/reapertura + aislamiento por ROM")
	quit(0)


func _probar(ruta_a: String, ruta_b: String) -> bool:
	var rom_a := FileAccess.get_file_as_bytes(ruta_a)
	var rom_b := FileAccess.get_file_as_bytes(ruta_b)
	if rom_a.is_empty() or rom_b.is_empty():
		_fallar("no se pudieron leer las dos fixtures SRAM")
		return false
	var save_a := _ruta_sram(rom_a)
	var save_b := _ruta_sram(rom_b)
	if save_a.is_empty() or save_b.is_empty() or save_a == save_b:
		_fallar("las fixtures no producen identidades SRAM distintas")
		return false
	_limpiar_save(save_a)
	_limpiar_save(save_b)
	if not _probar_cierre_y_reapertura(ruta_a, save_a):
		return false
	return _probar_aislamiento(ruta_a, ruta_b, save_a, save_b)


func _probar_cierre_y_reapertura(ruta: String, save: String) -> bool:
	var primera := _abrir_app(ruta)
	var estado_inicial := _ejecutar_fixture(primera)
	_cerrar_app(primera)
	if not _estado_es(estado_inicial, MARCADOR_A, 1):
		_fallar("la primera sesión no escribió marcador A + contador 1")
		return false
	var disco_inicial := FileAccess.get_file_as_bytes(save)
	if disco_inicial != estado_inicial:
		_fallar("cerrar la portátil no persistió exactamente la SRAM inicial")
		return false

	var segunda := _abrir_app(ruta)
	var restaurado := _snapshot_sram(segunda)
	if not _estado_es(restaurado, MARCADOR_A, 1):
		_cerrar_app(segunda)
		_fallar("reabrir la portátil no restauró la SRAM antes de ejecutar la ROM")
		return false
	var estado_segundo := _ejecutar_fixture(segunda)
	_cerrar_app(segunda)
	if not _estado_es(estado_segundo, MARCADOR_A, 2):
		_fallar("la segunda sesión no continuó el contador restaurado")
		return false
	if FileAccess.get_file_as_bytes(save) != estado_segundo:
		_fallar("el segundo cierre no reemplazó atómicamente la SRAM")
		return false
	return true


func _probar_aislamiento(ruta_a: String, ruta_b: String, save_a: String, save_b: String) -> bool:
	var a_antes := FileAccess.get_file_as_bytes(save_a)
	var app_b := _abrir_app(ruta_b)
	var estado_b := _ejecutar_fixture(app_b)
	_cerrar_app(app_b)
	if not _estado_es(estado_b, MARCADOR_B, 1):
		_fallar("la ROM B no creó su propio estado inicial")
		return false
	if FileAccess.get_file_as_bytes(save_b) != estado_b:
		_fallar("la SRAM de la ROM B no llegó a su ruta SHA-256")
		return false
	if FileAccess.get_file_as_bytes(save_a) != a_antes:
		_fallar("guardar la ROM B modificó la SRAM de la ROM A")
		return false

	var app_a := _abrir_app(ruta_a)
	var restaurado_a := _snapshot_sram(app_a)
	_cerrar_app(app_a)
	if not _estado_es(restaurado_a, MARCADOR_A, 2):
		_fallar("volver a A tras usar B no recuperó su save aislado")
		return false
	return true


func _abrir_app(ruta: String) -> EmuladorPortatilApp:
	var app := EmuladorPortatilApp.new()
	get_root().add_child(app)
	app.set("_efectos_presentacion", false)
	app.abrir()
	app.call("_cargar_rom_ahora", ruta)
	return app


func _ejecutar_fixture(app: EmuladorPortatilApp) -> PackedByteArray:
	var emulador = app.get("_emulador")
	if emulador == null:
		return PackedByteArray()
	for _indice in range(FRAMES_ARRANQUE):
		emulador.call("set_buttons", 0)
		emulador.call("run_frame_rgba")
	return emulador.call("save_ram")


func _snapshot_sram(app: EmuladorPortatilApp) -> PackedByteArray:
	var emulador = app.get("_emulador")
	if emulador == null:
		return PackedByteArray()
	return emulador.call("save_ram")


func _cerrar_app(app: EmuladorPortatilApp) -> void:
	app.call("_cerrar")
	# _cerrar() ya guardó. Evita que _exit_tree() reescriba un snapshot viejo
	# cuando varias instancias queue_free se liberen al terminar este smoke.
	app.set("_ruta_sram_actual", "")


func _estado_es(datos: PackedByteArray, marcador: int, contador: int) -> bool:
	return datos.size() >= 2 and int(datos[0]) == marcador and int(datos[1]) == contador


func _ruta_sram(rom: PackedByteArray) -> String:
	var contexto := HashingContext.new()
	if contexto.start(HashingContext.HASH_SHA256) != OK:
		return ""
	if contexto.update(rom) != OK:
		return ""
	var huella := contexto.finish().hex_encode()
	return SRAM_DIR + "/" + huella + ".sav" if not huella.is_empty() else ""


func _limpiar_save(ruta: String) -> void:
	for sufijo in ["", ".nuevo", ".anterior", ".roto"]:
		var candidata := ruta + sufijo
		if FileAccess.file_exists(candidata):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidata))


func _fallar(mensaje: String) -> void:
	push_error("SRAM smoke #456: %s" % mensaje)
	quit(1)
