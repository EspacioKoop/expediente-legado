extends SceneTree

## Evidencia visual reproducible del menú de inicio 3D (#830).
##
## Renderiza la escena real a 1920x1080 en dos estados: movimiento normal y
## reducción de movimiento. No modifica preferencias ni guardados; la reducción
## se aplica directamente al diorama ya montado para comparar legibilidad y
## composición con el mismo estado de menú.

const ANCHO := 1920
const ALTO := 1080
const MINIMO_BYTES_PNG := 12000

var _salida := ""
var _fallos := 0
var _capturas: Array[Dictionary] = []


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	_salida = (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-inicio-830")
	)
	DirAccess.make_dir_recursive_absolute(_salida)
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var ventana := get_root()
	ventana.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	ventana.content_scale_size = Vector2i(ANCHO, ALTO)
	ventana.size = Vector2i(ANCHO, ALTO)

	var inicio := load("res://escenas/inicio.tscn").instantiate()
	ventana.add_child(inicio)
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw

	_comprobar(inicio.get_node_or_null("FondoInicio") != null, "la escena conserva FondoInicio")
	_comprobar(inicio._diorama is InicioDiorama3D, "el menú usa InicioDiorama3D real")
	_comprobar(not inicio._diorama.get("_reduccion_movimiento"), "el primer estado tiene movimiento normal")
	await _capturar("inicio-normal.png", "menú con movimiento ambiental normal")

	inicio._diorama.configurar_reduccion_movimiento(true)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	_comprobar(inicio._diorama.get("_reduccion_movimiento"), "el segundo estado reduce movimiento")
	_comprobar(
		inicio._diorama.get("_exterior").get("_reduccion_movimiento"),
		"la reducción llega a la ventana exterior",
	)
	var vapor := inicio._diorama.find_child("VaporTaza", true, false) as MeshInstance3D
	_comprobar(vapor != null and not vapor.visible, "la reducción oculta el vapor no esencial")
	await _capturar("inicio-reduccion-movimiento.png", "menú con reducción de movimiento")

	_guardar_manifest()
	inicio.queue_free()
	await process_frame
	if _fallos > 0:
		print("EVIDENCIA_INICIO_830_FALLO fallos=%d" % _fallos)
		quit(1)
		return
	print(
		(
			"EVIDENCIA_INICIO_830_OK capturas=%d resolucion=%dx%d"
			% [_capturas.size(), ANCHO, ALTO]
		)
	)
	quit(0)


func _capturar(nombre_archivo: String, superficie: String) -> void:
	var imagen := get_root().get_texture().get_image()
	_comprobar(not imagen.is_empty(), "%s produce imagen" % superficie)
	_comprobar(
		imagen.get_width() == ANCHO and imagen.get_height() == ALTO,
		"%s mantiene 1920x1080" % superficie,
	)
	var png := imagen.save_png_to_buffer()
	_comprobar(png.size() >= MINIMO_BYTES_PNG, "%s codifica PNG no trivial" % superficie)
	var error := imagen.save_png(_salida.path_join(nombre_archivo))
	_comprobar(error == OK, "%s se guarda" % nombre_archivo)
	(
		_capturas
		. append(
			{
				"archivo": nombre_archivo,
				"superficie": superficie,
				"bytes": png.size(),
			}
		)
	)


func _guardar_manifest() -> void:
	var manifest := {
		"issue": 830,
		"resolucion": [ANCHO, ALTO],
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
	_fallos += 1
	push_error("FALLO evidencia inicio #830: %s" % mensaje)
