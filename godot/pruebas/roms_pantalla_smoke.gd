## Lo que las ROMs propias dibujan, visto con el MISMO núcleo que usa la
## Portátil Color 98 (#805). Tras arrancar, pulsar Start y dejar correr la
## partida, el mapa de fondo visible no puede estar lleno de índices de tile
## sueltos: es la huella del bucle de limpieza que escribía el contador.
##
## Una pantalla de arte CGB a pantalla completa (#808) también usa cientos de
## tiles, pero con varias paletas: la basura del #805 salía con una sola, porque
## esas ROMs nunca tocaban el mapa de atributos. Por eso muchos tiles solo son
## fallo si el fotograma tiene pocos colores.
##
##     godot4 --headless --path godot --script res://pruebas/roms_pantalla_smoke.gd \
##         -- ruta/a/rom1.gbc [ruta/a/rom2.gbc ...]
extends SceneTree

const BG_MAP := 0x9800
const FOTOGRAMAS_TITULO := 120
const FOTOGRAMAS_START := 6
const FOTOGRAMAS_JUEGO := 300
const BTN_START := 0x08
## Una pantalla sana usa unas pocas decenas de tiles distintos. El mapa sucio
## del #805 tenía más de cien en las 360 celdas visibles.
const MAX_TILES_DISTINTOS := 64
## Una sola paleta de fondo son 4 colores; con los sprites, unos pocos más.
const MAX_COLORES_UNA_PALETA := 8


func _init() -> void:
	var rutas := OS.get_cmdline_user_args()
	if rutas.is_empty():
		_fallar("sin ROMs que comprobar")
		return
	if not ClassDB.class_exists(&"Siga98GB"):
		_fallar("Siga98GB no está registrada")
		return
	var fallos := 0
	for ruta in rutas:
		var medida := _medir(ruta)
		if medida.is_empty():
			fallos += 1
			continue
		var distintos: int = medida["tiles"]
		var colores: int = medida["colores"]
		var ok := distintos <= MAX_TILES_DISTINTOS or colores > MAX_COLORES_UNA_PALETA
		print(
			(
				"%s %s: %d tiles distintos y %d colores en pantalla"
				% ["OK" if ok else "FALLO", ruta.get_file(), distintos, colores]
			)
		)
		if not ok:
			fallos += 1
	quit(1 if fallos > 0 else 0)


func _medir(ruta: String) -> Dictionary:
	var rom := FileAccess.get_file_as_bytes(ruta)
	if rom.is_empty():
		_fallar("no se pudo leer %s" % ruta)
		return {}
	var emulador = ClassDB.instantiate(&"Siga98GB")
	var resultado := int(emulador.call("load_rom", rom))
	if resultado != 0:
		_fallar("load_rom %s: %s" % [ruta, emulador.call("last_error")])
		return {}
	var total := FOTOGRAMAS_TITULO + FOTOGRAMAS_START + FOTOGRAMAS_JUEGO
	var fotograma_rgba := PackedByteArray()
	for fotograma in total:
		var pulsando := (
			fotograma >= FOTOGRAMAS_TITULO and fotograma < FOTOGRAMAS_TITULO + FOTOGRAMAS_START
		)
		emulador.call("set_buttons", BTN_START if pulsando else 0)
		fotograma_rgba = emulador.call("run_frame_rgba")
	var vistos := {}
	for fila in 18:
		for columna in 20:
			vistos[int(emulador.call("read_memory_u8", BG_MAP + fila * 32 + columna))] = true
	var colores := {}
	for i in range(0, fotograma_rgba.size(), 4):
		colores[fotograma_rgba.decode_u32(i)] = true
	return {"tiles": vistos.size(), "colores": colores.size()}


func _fallar(mensaje: String) -> void:
	push_error(mensaje)
	quit(1)
