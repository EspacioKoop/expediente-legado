extends SceneTree

## Smoke visual reproducible del shell OS98 (#534).
##
## No sustituye una revisión humana: monta el EscritorioSigaVisual real a una
## resolución fija, fuerza dos estados representativos y codifica capturas PNG
## para que CI demuestre que la composición puede renderizarse de extremo a
## extremo. Además valida estructura y diversidad mínima de la imagen para no
## aceptar una captura vacía o monocroma como evidencia.
##
## Para inspección manual puede usarse --output=user://directorio (o cualquier
## ruta aceptada por Godot). CI valida los buffers PNG en memoria y no depende
## de que Python y FileAccess compartan el mismo namespace de rutas.

const ANCHO := 1024
const ALTO := 680
const MINIMO_COLORES_MUESTREADOS := 8
const MINIMO_BYTES_PNG := 2048

var _salida := ""
var _fallos := 0


func _initialize() -> void:
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with("--output="):
			_salida = argumento.trim_prefix("--output=")
	if not _salida.is_empty():
		DirAccess.make_dir_recursive_absolute(_salida)
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var ventana := get_root()
	ventana.size = Vector2i(ANCHO, ALTO)

	var escritorio := EscritorioSigaVisual.new()
	escritorio.name = "EscritorioSmokeVisual"
	ventana.add_child(escritorio)
	await process_frame

	escritorio.registrar_identidad_visual("smoke-a", "siga")
	escritorio.registrar_identidad_visual("smoke-b", "ayuda")
	escritorio.registrar_aplicacion(
		"smoke-a",
		"SIGA-98 · prueba",
		Callable(self, "_crear_contenido").bind("Expediente 041", "Consulta de documentos"),
		Vector2(320, 220),
		Vector2(470, 330)
	)
	escritorio.registrar_aplicacion(
		"smoke-b",
		"Ayuda · prueba",
		Callable(self, "_crear_contenido").bind("Ayuda del sistema", "Navegación y foco"),
		Vector2(300, 210),
		Vector2(430, 300)
	)
	escritorio.establecer_reloj_narrativo("DÍA 04 · 09:20")
	escritorio.abrir_aplicacion("smoke-a")
	escritorio.abrir_aplicacion("smoke-b")
	escritorio._alternar_menu()
	await process_frame
	await process_frame

	_comprobar(escritorio._ventanas.size() == 2, "el estado base contiene dos ventanas")
	_comprobar(escritorio._menu.visible, "el menú del sistema está visible en la captura base")
	_comprobar(
		escritorio.get_node_or_null("WallpaperCorporativo") != null,
		"la piel visual conserva el wallpaper corporativo"
	)
	_comprobar(
		escritorio.get_node_or_null("MarcaSistema") != null,
		"la piel visual conserva la marca del sistema"
	)
	_comprobar(
		escritorio.get_node_or_null("BarraInferior") != null,
		"la barra inferior forma parte de la composición"
	)

	var captura_base := await _capturar("escritorio-ventanas.png", "estado con dos ventanas y menú")

	escritorio._menu.visible = false
	var modal := VBoxContainer.new()
	modal.add_theme_constant_override("separation", 10)
	var aviso := Label.new()
	aviso.text = "Confirmación de sistema"
	modal.add_child(aviso)
	var detalle := Label.new()
	detalle.text = "El foco debe permanecer dentro de esta ventana."
	modal.add_child(detalle)
	var aceptar := Button.new()
	aceptar.text = "Aceptar"
	modal.add_child(aceptar)
	escritorio.abrir_modal("smoke-modal", "Aviso", modal)
	await process_frame
	await process_frame

	_comprobar(
		escritorio._modal_id == "smoke-modal", "la segunda captura contiene una modal activa"
	)
	_comprobar(
		escritorio.get_node_or_null("BloqueadorModal") != null,
		"la modal incluye su bloqueador visual"
	)
	var captura_modal := await _capturar("escritorio-modal.png", "estado modal")
	_comprobar(
		captura_base != captura_modal, "los estados base y modal producen capturas PNG distintas"
	)

	escritorio.queue_free()
	await process_frame
	if _fallos > 0:
		print("SMOKE_VISUAL_ESCRITORIO_FALLO fallos=%d" % _fallos)
		quit(1)
		return
	print(
		(
			"SMOKE_VISUAL_ESCRITORIO_OK captures=2 resolution=%dx%d bytes_base=%d bytes_modal=%d distinct=1"
			% [ANCHO, ALTO, captura_base.size(), captura_modal.size()]
		)
	)
	quit(0)


func _crear_contenido(titulo_texto: String, detalle_texto: String) -> Control:
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 18)
	margen.add_theme_constant_override("margin_right", 18)
	margen.add_theme_constant_override("margin_top", 16)
	margen.add_theme_constant_override("margin_bottom", 16)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = titulo_texto
	columna.add_child(titulo)
	var detalle := Label.new()
	detalle.text = detalle_texto
	columna.add_child(detalle)
	var boton := Button.new()
	boton.text = "Abrir"
	columna.add_child(boton)
	return margen


func _capturar(nombre_archivo: String, nombre: String) -> PackedByteArray:
	var imagen := get_root().get_texture().get_image()
	_comprobar(not imagen.is_empty(), "%s produce una imagen no vacía" % nombre)
	_comprobar(
		imagen.get_width() == ANCHO and imagen.get_height() == ALTO,
		"%s mantiene la resolución de referencia" % nombre
	)
	_comprobar(
		_contar_colores_muestreados(imagen) >= MINIMO_COLORES_MUESTREADOS,
		"%s conserva diversidad visual mínima" % nombre
	)
	var png := imagen.save_png_to_buffer()
	_comprobar(png.size() >= MINIMO_BYTES_PNG, "%s codifica un PNG no trivial" % nombre)
	if not _salida.is_empty():
		var error := imagen.save_png(_salida.path_join(nombre_archivo))
		_comprobar(error == OK, "%s se guarda como PNG cuando se solicita" % nombre)
	return png


func _contar_colores_muestreados(imagen: Image) -> int:
	var colores := {}
	for y in range(0, imagen.get_height(), 32):
		for x in range(0, imagen.get_width(), 32):
			colores[imagen.get_pixel(x, y).to_rgba32()] = true
	return colores.size()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		return
	_fallar(mensaje)


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error("FALLO smoke visual escritorio: %s" % mensaje)
