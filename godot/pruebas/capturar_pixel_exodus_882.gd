## Evidencia reproducible de cierre de Pixel Exodus (#882).
##
## Ejecuta la ROM real mediante Siga98GB, conduce una partida completa, captura
## estados representativos, comprueba audio PCM y vuelve a montar la SRAM en una
## segunda instancia del emulador.
##
##   godot4 --headless --path godot --script res://pruebas/capturar_pixel_exodus_882.gd \
##       -- /tmp/pixel-exodus-882
extends SceneTree

const ROM := "res://roms/caza_pixeles_98.gbc"
const ANCHO := 160
const ALTO := 144
const BYTES_POR_PIXEL := 4
const TAM_FRAME := ANCHO * ALTO * BYTES_POR_PIXEL
const FRAMES_ARRANQUE := 60
const FRECUENCIA_AUDIO := 48000
const MAX_MUESTRA_AUDIO := 192000

const BTN_A := 1
const BTN_RIGHT := 1 << 4
const BTN_LEFT := 1 << 5
const BTN_UP := 1 << 6
const BTN_DOWN := 1 << 7

# Contrato WRAM de la SECTION "Variables" de main.asm. Mantener estas lecturas
# aqui hace que la evidencia falle de forma explícita si cambia el ABI interno.
const W_ESTADO := 0xC000
const W_JUGADOR_X := 0xC001
const W_JUGADOR_Y := 0xC002
const W_OBJETIVO_X := 0xC003
const W_OBJETIVO_Y := 0xC004
const W_PUNTOS := 0xC00B
const W_COMBO := 0xC00C
const W_RESTAURACION := 0xC010
const W_ETAPA_CHROMIA := 0xC012
const W_FASE := 0xC013
const W_TIEMPO := 0xC015
const W_BOSS_ACTIVO := 0xC01E
const W_BOSS_DERROTADO := 0xC01F
const W_BOSS_X := 0xC022
const W_BOSS_Y := 0xC023

const ESTADO_TITULO := 0
const ESTADO_JUEGO := 1
const ESTADO_FIN := 2

# Mismo espacio de coordenadas OAM que usa la ROM.
const OBSTACULOS := [
	[40, 56, 16, 8],
	[96, 72, 16, 8],
	[64, 96, 16, 8],
]

const CAPTURAS := [
	"titulo.png",
	"instrucciones.png",
	"fase1.png",
	"fase2-obstaculos.png",
	"fase3-restauracion.png",
	"behemoth.png",
	"final-records.png",
]

var _salida := ""
var _fallo := false
var _audio_activo := false
var _audio_total := 0
var _audio_no_cero := 0
var _audio_muestra := PackedByteArray()
var _checksums_audio: Dictionary = {}
var _desvio_boton := 0
var _desvio_restante := 0


func _init() -> void:
	_salida = _resolver_salida()
	if _salida.is_empty():
		return

	var emulador := _crear_emulador()
	if emulador == null or not _cargar_rom(emulador):
		return

	var frame := PackedByteArray()
	for _i in range(FRAMES_ARRANQUE):
		frame = _step(emulador, 0)
		if _fallo:
			return
	if not _capturar(frame, "titulo.png"):
		return
	if _leer(emulador, W_ESTADO) != ESTADO_TITULO:
		_fallar("ABI WRAM inesperado: wEstado no está en título tras el arranque")
		return

	if not _iniciar_partida(emulador):
		return
	_audio_activo = true

	# La intro/instrucciones dura 150 frames y congela el primer segundo real.
	for _i in range(12):
		frame = _step(emulador, 0)
	if not _capturar(frame, "instrucciones.png"):
		return
	if _leer(emulador, W_TIEMPO) != 45:
		_fallar("las instrucciones consumieron tiempo de partida")
		return

	for _i in range(155):
		frame = _step(emulador, 0)
	if _leer(emulador, W_FASE) != 1 or _leer(emulador, W_TIEMPO) != 45:
		_fallar("la intro no entregó el control con fase 1 / 45 s")
		return
	if not _capturar(frame, "fase1.png"):
		return

	if not _esperar_fase(emulador, 2, 1100):
		return
	for _i in range(55):
		frame = _step_autoplay(emulador)
	if not _capturar(frame, "fase2-obstaculos.png"):
		return

	if not _esperar_fase(emulador, 3, 1100):
		return
	for _i in range(55):
		frame = _step_autoplay(emulador)
	var intentos_restauracion := 0
	while (
		_leer(emulador, W_RESTAURACION) < 25
		and _leer(emulador, W_BOSS_ACTIVO) == 0
		and intentos_restauracion < 260
	):
		frame = _step_autoplay(emulador)
		intentos_restauracion += 1
	if _leer(emulador, W_RESTAURACION) <= 0:
		_fallar("el autoplayer no logró restaurar Chromia")
		return
	if not _capturar(frame, "fase3-restauracion.png"):
		return

	if not _esperar_boss(emulador, 650):
		return
	for _i in range(12):
		frame = _step_autoplay(emulador)
	if not _capturar(frame, "behemoth.png"):
		return

	if not _esperar_final(emulador, 650):
		return
	for _i in range(60):
		frame = _step(emulador, 0)
	if not _capturar(frame, "final-records.png"):
		return

	if _leer(emulador, W_BOSS_DERROTADO) != 1:
		_fallar("la partida de evidencia terminó sin limpiar el Glitch Behemoth")
		return
	if not _validar_audio(emulador):
		return
	if not _validar_sram_persistente(emulador):
		return
	if not _escribir_manifest(emulador):
		return
	if not _escribir_audio():
		return

	print(
		"Pixel Exodus #882: OK · score=%d combo=%d restauración=%d · audio=%d bytes"
		% [
			_leer(emulador, W_PUNTOS),
			_leer(emulador, W_COMBO),
			_leer(emulador, W_RESTAURACION),
			_audio_total,
		]
	)
	quit(0)


func _resolver_salida() -> String:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("pixel-exodus-882")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error := DirAccess.make_dir_recursive_absolute(salida)
	if error != OK:
		_fallar("no se pudo crear %s (error %d)" % [salida, error])
		return ""
	return salida


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
		_fallar("no existe %s" % ROM)
		return false
	var rom := FileAccess.get_file_as_bytes(ROM)
	if int(emulador.call("load_rom", rom)) != 0:
		_fallar("load_rom falló: %s" % emulador.call("last_error"))
		return false
	if String(emulador.call("rom_title")).find("CAZAPIXEL98") < 0:
		_fallar("se cargó una ROM distinta: %s" % emulador.call("rom_title"))
		return false
	return true


func _iniciar_partida(emulador: Object) -> bool:
	for indice in range(20):
		var boton := BTN_A if indice % 2 == 0 else 0
		_step(emulador, boton)
		if _fallo:
			return false
		if _leer(emulador, W_ESTADO) == ESTADO_JUEGO:
			return true
	_fallar("A/Start no inició Pixel Exodus")
	return false


func _esperar_fase(emulador: Object, fase: int, max_frames: int) -> bool:
	for _i in range(max_frames):
		_step_autoplay(emulador)
		if _fallo:
			return false
		if _leer(emulador, W_FASE) >= fase:
			return true
		if _leer(emulador, W_ESTADO) == ESTADO_FIN:
			break
	_fallar("no se alcanzó la fase %d" % fase)
	return false


func _esperar_boss(emulador: Object, max_frames: int) -> bool:
	for _i in range(max_frames):
		_step_autoplay(emulador)
		if _fallo:
			return false
		if _leer(emulador, W_BOSS_ACTIVO) == 1:
			return true
	_fallar("no apareció el Glitch Behemoth")
	return false


func _esperar_final(emulador: Object, max_frames: int) -> bool:
	for _i in range(max_frames):
		_step_autoplay(emulador)
		if _fallo:
			return false
		if _leer(emulador, W_ESTADO) == ESTADO_FIN:
			return true
	_fallar("la partida no llegó a la pantalla final")
	return false


func _step_autoplay(emulador: Object) -> PackedByteArray:
	var boton := _boton_autoplay(emulador)
	return _step(emulador, boton)


func _step(emulador: Object, botones: int) -> PackedByteArray:
	emulador.call("set_buttons", botones)
	var frame = emulador.call("run_frame_rgba")
	if not (frame is PackedByteArray) or frame.size() != TAM_FRAME:
		_fallar("frame RGBA inválido")
		return PackedByteArray()
	var pcm = emulador.call("drain_audio_pcm16")
	if pcm is PackedByteArray and _audio_activo:
		_registrar_audio(emulador, pcm)
	return frame


func _boton_autoplay(emulador: Object) -> int:
	if _leer(emulador, W_ESTADO) != ESTADO_JUEGO:
		return 0
	var px := _leer(emulador, W_JUGADOR_X)
	var py := _leer(emulador, W_JUGADOR_Y)
	var boss := _leer(emulador, W_BOSS_ACTIVO) == 1
	var tx := _leer(emulador, W_BOSS_X if boss else W_OBJETIVO_X)
	var ty := _leer(emulador, W_BOSS_Y if boss else W_OBJETIVO_Y)
	var fase := _leer(emulador, W_FASE)

	if _desvio_restante > 0 and _movimiento_seguro(px, py, _desvio_boton, fase, boss):
		_desvio_restante -= 1
		return _desvio_boton
	_desvio_restante = 0
	_desvio_boton = 0

	var horizontal := 0
	var vertical := 0
	if tx > px + 2:
		horizontal = BTN_RIGHT
	elif tx < px - 2:
		horizontal = BTN_LEFT
	if ty > py + 2:
		vertical = BTN_DOWN
	elif ty < py - 2:
		vertical = BTN_UP

	var candidatos: Array[int] = []
	if abs(tx - px) >= abs(ty - py):
		if horizontal != 0:
			candidatos.append(horizontal)
		if vertical != 0:
			candidatos.append(vertical)
	else:
		if vertical != 0:
			candidatos.append(vertical)
		if horizontal != 0:
			candidatos.append(horizontal)

	for boton in candidatos:
		if _movimiento_seguro(px, py, boton, fase, boss):
			return boton

	# Una barrera corta la ruta directa: mantener un desvío durante suficientes
	# píxeles evita oscilar contra su borde en frames consecutivos.
	for boton in [BTN_UP, BTN_DOWN, BTN_LEFT, BTN_RIGHT]:
		if _movimiento_seguro(px, py, boton, fase, boss):
			_desvio_boton = boton
			_desvio_restante = 20
			return boton
	return 0


func _movimiento_seguro(px: int, py: int, boton: int, fase: int, boss: bool) -> bool:
	var nx := px
	var ny := py
	match boton:
		BTN_RIGHT:
			nx += 1
		BTN_LEFT:
			nx -= 1
		BTN_UP:
			ny -= 1
		BTN_DOWN:
			ny += 1
		_:
			return false
	if nx < 8 or nx > 160 or ny < 32 or ny > 152:
		return false
	return not _choca_obstaculo(nx, ny, fase, boss)


func _choca_obstaculo(px: int, py: int, fase: int, boss: bool) -> bool:
	if fase < 2 or boss:
		return false
	var cantidad := 2 if fase == 2 else 3
	for indice in range(cantidad):
		var obstaculo: Array = OBSTACULOS[indice]
		var ox := int(obstaculo[0])
		var oy := int(obstaculo[1])
		var ow := int(obstaculo[2])
		var oh := int(obstaculo[3])
		if px + 8 > ox and px < ox + ow and py + 8 > oy and py < oy + oh:
			return true
	return false


func _registrar_audio(emulador: Object, pcm: PackedByteArray) -> void:
	if pcm.is_empty():
		return
	_audio_total += pcm.size()
	var clave := _clave_audio(emulador)
	var checksum := int(_checksums_audio.get(clave, 0))
	for indice in range(0, pcm.size(), 32):
		var valor := int(pcm[indice])
		checksum = (checksum * 33 + valor) % 65521
		if valor != 0:
			_audio_no_cero += 1
	_checksums_audio[clave] = checksum

	if _audio_muestra.size() < MAX_MUESTRA_AUDIO:
		var restantes := MAX_MUESTRA_AUDIO - _audio_muestra.size()
		_audio_muestra.append_array(pcm.slice(0, mini(restantes, pcm.size())))


func _clave_audio(emulador: Object) -> String:
	var estado := _leer(emulador, W_ESTADO)
	if estado == ESTADO_FIN:
		return "final"
	if _leer(emulador, W_BOSS_ACTIVO) == 1:
		return "boss"
	return "fase%d" % _leer(emulador, W_FASE)


func _validar_audio(emulador: Object) -> bool:
	if not bool(emulador.call("supports_audio")):
		_fallar("Siga98GB no anunció audio")
		return false
	if int(emulador.call("audio_sample_rate")) != FRECUENCIA_AUDIO:
		_fallar("frecuencia de audio inesperada")
		return false
	if _audio_total <= 0 or _audio_no_cero <= 0:
		_fallar("la partida no produjo PCM audible")
		return false
	for clave in ["fase1", "fase2", "fase3", "boss", "final"]:
		if not _checksums_audio.has(clave):
			_fallar("falta evidencia PCM para %s" % clave)
			return false
	var firmas: Dictionary = {}
	for clave in ["fase1", "fase2", "fase3", "boss"]:
		firmas[int(_checksums_audio[clave])] = true
	if firmas.size() < 3:
		_fallar("los motivos por fase no dejaron firmas PCM suficientemente distintas")
		return false
	return true


func _validar_sram_persistente(emulador: Object) -> bool:
	var sram = emulador.call("save_ram")
	if not (sram is PackedByteArray) or sram.size() < 10:
		_fallar("snapshot SRAM inválido")
		return false
	if sram[0] != 0x50 or sram[1] != 0x58 or sram[2] != 0x39 or sram[3] != 0x38:
		_fallar("la SRAM no contiene la firma PX98")
		return false
	if int(sram[5]) <= 0 or int(sram[7]) < 4 or int(sram[8]) <= 0:
		_fallar("los récords persistidos no reflejan la partida completada")
		return false

	var reabierto := _crear_emulador()
	if reabierto == null or not _cargar_rom(reabierto):
		return false
	if not bool(reabierto.call("load_save_ram", sram)):
		_fallar("una segunda instancia rechazó la SRAM PX98")
		return false
	for _i in range(FRAMES_ARRANQUE):
		reabierto.call("set_buttons", 0)
		var frame = reabierto.call("run_frame_rgba")
		if not (frame is PackedByteArray) or frame.size() != TAM_FRAME:
			_fallar("la reapertura con SRAM no produjo framebuffer válido")
			return false
		reabierto.call("drain_audio_pcm16")
	var sram_reabierta = reabierto.call("save_ram")
	if not (sram_reabierta is PackedByteArray):
		_fallar("save_ram falló tras reabrir")
		return false
	if sram_reabierta.slice(0, 10) != sram.slice(0, 10):
		_fallar("los récords PX98 cambiaron al cerrar/reabrir")
		return false
	return true


func _capturar(frame: PackedByteArray, nombre: String) -> bool:
	if frame.size() != TAM_FRAME or not _frame_tiene_variacion(frame):
		_fallar("frame no capturable: %s" % nombre)
		return false
	var imagen := Image.create_from_data(ANCHO, ALTO, false, Image.FORMAT_RGBA8, frame)
	var error := imagen.save_png(_salida.path_join(nombre))
	if error != OK:
		_fallar("no se pudo guardar %s (error %d)" % [nombre, error])
		return false
	return true


func _frame_tiene_variacion(frame: PackedByteArray) -> bool:
	if frame.size() < BYTES_POR_PIXEL * 2:
		return false
	for indice in range(BYTES_POR_PIXEL, frame.size(), BYTES_POR_PIXEL):
		for canal in range(BYTES_POR_PIXEL):
			if frame[indice + canal] != frame[canal]:
				return true
	return false


func _escribir_manifest(emulador: Object) -> bool:
	var sram = emulador.call("save_ram")
	var manifest := {
		"issue": 882,
		"rom": String(emulador.call("rom_title")),
		"capturas": CAPTURAS,
		"partida": {
			"score": _leer(emulador, W_PUNTOS),
			"combo_actual": _leer(emulador, W_COMBO),
			"restauracion": _leer(emulador, W_RESTAURACION),
			"fase": _leer(emulador, W_FASE),
			"boss_derrotado": _leer(emulador, W_BOSS_DERROTADO),
		},
		"audio": {
			"sample_rate": FRECUENCIA_AUDIO,
			"bytes_pcm": _audio_total,
			"checksums_por_tramo": _checksums_audio,
		},
		"sram": {
			"magic": "PX98",
			"version": int(sram[4]),
			"mejor_score": int(sram[5]),
			"mejor_combo": int(sram[6]),
			"mejor_fase": int(sram[7]),
			"mejor_restauracion": int(sram[8]),
			"reapertura_verificada": true,
		},
	}
	var archivo := FileAccess.open(_salida.path_join("manifest.json"), FileAccess.WRITE)
	if archivo == null:
		_fallar("no se pudo crear manifest.json")
		return false
	archivo.store_string(JSON.stringify(manifest, "\t"))
	return true


func _escribir_audio() -> bool:
	if _audio_muestra.is_empty():
		_fallar("no hay muestra PCM para adjuntar")
		return false
	var archivo := FileAccess.open(_salida.path_join("audio-sample-s16le-stereo-48k.pcm"), FileAccess.WRITE)
	if archivo == null:
		_fallar("no se pudo crear la muestra PCM")
		return false
	archivo.store_buffer(_audio_muestra)
	return true


func _leer(emulador: Object, direccion: int) -> int:
	return int(emulador.call("read_memory_u8", direccion))


func _fallar(mensaje: String) -> void:
	if _fallo:
		return
	_fallo = true
	push_error("Pixel Exodus #882: %s" % mensaje)
	quit(1)
