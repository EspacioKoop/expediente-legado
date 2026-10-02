extends SceneTree

## Evidencia visual reproducible de los iconos propios del OS98 (#781).
##
## Monta el EscritorioSigaVisual real a 1920x1080, registra las siete
## aplicaciones cubiertas por el atlas de programas y captura las superficies
## de 32 px (escritorio) y 16 px (menú/barra/título). No autoaprueba el juicio
## artístico: solo demuestra que el wiring integrado se renderiza de extremo a
## extremo y deja PNGs comparables para la revisión humana exigida por #781.

const ANCHO := 1920
const ALTO := 1080
const MINIMO_BYTES_PNG := 4096
const PROGRAMAS := [
	{"id": "explorador", "titulo": "Explorador"},
	{"id": "web98", "titulo": "Web98"},
	{"id": "software", "titulo": "Archivo de programas"},
	{"id": "correo", "titulo": "Correo interno"},
	{"id": "bloc-notas", "titulo": "Bloc de notas"},
	{"id": "calculadora", "titulo": "Calculadora"},
	{"id": "catalogo-anomalias", "titulo": "Catálogo de anomalías"},
]

var _salida := ""
var _fallos := 0
var _capturas: Array[Dictionary] = []


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	_salida = (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-iconos-programas-781")
	)
	DirAccess.make_dir_recursive_absolute(_salida)
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var ventana := get_root()
	ventana.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	ventana.size = Vector2i(ANCHO, ALTO)

	var escritorio := EscritorioSigaVisual.new()
	escritorio.name = "EscritorioIconos781"
	ventana.add_child(escritorio)
	await process_frame

	for programa in PROGRAMAS:
		var id := String(programa["id"])
		var titulo := String(programa["titulo"])
		escritorio.registrar_identidad_visual(id, id)
		escritorio.registrar_aplicacion(
			id,
			titulo,
			Callable(self, "_crear_contenido").bind(titulo),
			Vector2(360, 220),
			Vector2(560, 360)
		)

	await process_frame
	_comprobar_iconos(escritorio, 32)
	await RenderingServer.frame_post_draw
	await _capturar("iconos-programas-32.png", "escritorio con siete lanzadores de 32 px")

	escritorio.abrir_aplicacion("correo")
	await process_frame
	escritorio._alternar_menu()
	await process_frame
	_comprobar_iconos(escritorio, 16)
	_comprobar_superficies_ventana(escritorio, "correo")
	await RenderingServer.frame_post_draw
	await _capturar("iconos-programas-16.png", "menú, tarea y título con iconos de 16 px")

	_guardar_manifest()
	escritorio.queue_free()
	await process_frame

	if _fallos > 0:
		print("EVIDENCIA_ICONOS_781_FALLO fallos=%d" % _fallos)
		quit(1)
		return
	print(
		"EVIDENCIA_ICONOS_781_OK programas=%d capturas=%d resolucion=%dx%d"
		% [PROGRAMAS.size(), _capturas.size(), ANCHO, ALTO]
	)
	quit(0)


func _crear_contenido(titulo: String) -> Control:
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 20)
	margen.add_theme_constant_override("margin_right", 20)
	margen.add_theme_constant_override("margin_top", 18)
	margen.add_theme_constant_override("margin_bottom", 18)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)
	var cabecera := Label.new()
	cabecera.text = titulo
	cabecera.add_theme_font_override("font", EstiloSiga.fuente_titulo())
	columna.add_child(cabecera)
	var detalle := Label.new()
	detalle.text = "Superficie de evidencia visual #781"
	columna.add_child(detalle)
	return margen


func _comprobar_iconos(escritorio: EscritorioSigaVisual, tamano: int) -> void:
	for indice in PROGRAMAS.size():
		var programa: Dictionary = PROGRAMAS[indice]
		var id := String(programa["id"])
		var nombre := ("Lanzador_%s" if tamano == 32 else "Programa_%s") % id
		var raiz := escritorio._iconos if tamano == 32 else escritorio._programas_menu
		var boton := raiz.get_node_or_null(nombre) as Button
		_comprobar(boton != null, "%s existe" % nombre)
		if boton == null:
			continue
		_comprobar(boton.icon != null, "%s tiene icono" % nombre)
		if boton.icon is AtlasTexture:
			var atlas := boton.icon as AtlasTexture
			_comprobar(
				atlas.region
				== Rect2(float(indice * tamano), 0.0, float(tamano), float(tamano)),
				"%s usa la celda esperada del atlas de programas" % nombre,
			)
		else:
			_fallar("%s no usa AtlasTexture" % nombre)


func _comprobar_superficies_ventana(escritorio: EscritorioSigaVisual, id: String) -> void:
	_comprobar(escritorio._ventanas.has(id), "la app abierta crea ventana")
	if not escritorio._ventanas.has(id):
		return
	var datos: Dictionary = escritorio._ventanas[id]
	var tarea := datos.get("tarea") as Button
	_comprobar(tarea != null and tarea.icon != null, "la barra de tareas usa icono propio")
	var barra := datos.get("titulo_barra") as PanelContainer
	_comprobar(barra != null, "la ventana conserva barra de título")
	if barra == null or barra.get_child_count() == 0:
		return
	var fila := barra.get_child(0)
	var icono := fila.get_node_or_null("IconoAplicacion") if fila != null else null
	_comprobar(icono is TextureRect, "la barra de título usa icono propio")


func _capturar(nombre_archivo: String, superficie: String) -> void:
	var imagen := get_root().get_texture().get_image()
	_comprobar(not imagen.is_empty(), "%s produce imagen" % superficie)
	_comprobar(
		imagen.get_width() == ANCHO and imagen.get_height() == ALTO,
		"%s mantiene 1920x1080" % superficie,
	)
	var png := imagen.save_png_to_buffer()
	_comprobar(png.size() >= MINIMO_BYTES_PNG, "%s codifica PNG no trivial" % superficie)
	var ruta := _salida.path_join(nombre_archivo)
	var error := imagen.save_png(ruta)
	_comprobar(error == OK, "%s se guarda" % nombre_archivo)
	_capturas.append(
		{
			"archivo": nombre_archivo,
			"superficie": superficie,
			"bytes": png.size(),
		}
	)


func _guardar_manifest() -> void:
	var manifest := {
		"issue": 781,
		"resolucion": [ANCHO, ALTO],
		"programas": PROGRAMAS,
		"capturas": _capturas,
		"veredicto_automatico": false,
	}
	var archivo := FileAccess.open(_salida.path_join("manifest.json"), FileAccess.WRITE)
	_comprobar(archivo != null, "se puede crear manifest.json")
	if archivo == null:
		return
	archivo.store_string(JSON.stringify(manifest, "\t"))
	archivo.close()


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		return
	_fallar(mensaje)


func _fallar(mensaje: String) -> void:
	_fallos += 1
	push_error("FALLO evidencia iconos #781: %s" % mensaje)
