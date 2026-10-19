## Evidencia reproducible de la apertura de créditos #795/#2527.
##
## Rueda los 40 planos con el reproductor real, no recreaciones 2D.
## Las imágenes y el mosaico se adjuntan como artifact de CI; no se
## insertan binarios efímeros ni datos personales en el repositorio.
extends SceneTree

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")
const ANCHO := 1920
const ALTO := 1080
const CUADRICULA_COLUMNAS := 8
const MINIATURA := Vector2i(256, 144)
const INDICES_REDUCIDOS := [0, 24, 39]

var _salida := ""
var _fallos := 0
var _capturas: Array[Dictionary] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_salida = (
		String(args[0])
		if not args.is_empty()
		else OS.get_user_data_dir().path_join("evidencia-creditos-795")
	)
	if not _salida.is_absolute_path():
		_salida = ProjectSettings.globalize_path("res://").path_join(_salida)
	var error := DirAccess.make_dir_recursive_absolute(_salida)
	if error != OK:
		printerr("No se pudo crear el directorio de evidencia: %s" % _salida)
		quit(1)
		return
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	root.size = Vector2i(ANCHO, ALTO)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size = Vector2i(ANCHO, ALTO)

	var reproductor := ESCENA_CINEMATICA.instantiate()
	root.add_child(reproductor)
	var planos := CreditosInicioCinematica.planos()
	_comprobar(planos.size() == 40, "rodaje completo de 40 planos")
	_comprobar(Cinematica.validar(planos).is_empty(), "rodaje valido")
	_comprobar(
		RenderingServer.get_current_rendering_method() == "forward_plus",
		"renderer real Forward+ sin fallback"
	)

	# Un fotograma de cada plano, incluido su rótulo. Reproducir la toma
	# aislada no cambia Partida/Jornada ni reinicia el menú del usuario.
	for i in planos.size():
		await _capturar_plano(reproductor, planos[i], i, false)

	# Muestras comparables con la alternativa accesible.
	for indice in INDICES_REDUCIDOS:
		await _capturar_plano(reproductor, planos[indice], indice, true)

	reproductor.queue_free()
	await process_frame
	_generar_mosaico()
	_guardar_manifiesto()
	if _fallos > 0:
		print("EVIDENCIA_CREDITOS_795_FALLO fallos=%d" % _fallos)
		quit(1)
		return
	print(
		"EVIDENCIA_CREDITOS_795_OK capturas=%d resolucion=%dx%d" % [_capturas.size(), ANCHO, ALTO]
	)
	quit(0)


func _capturar_plano(reproductor: Node3D, plano: Dictionary, indice: int, reduccion: bool) -> void:
	reproductor.reproducir([plano])
	if reduccion:
		reproductor.set("_reduccion_movimiento", true)
	for _paso in 4:
		await process_frame
	reproductor.call("_mover_camara", plano, 0.5)
	await RenderingServer.frame_post_draw

	var imagen := root.get_texture().get_image()
	var sufijo := "reducido" if reduccion else "normal"
	var nombre := "plano_%02d_%s.jpg" % [indice, sufijo]
	_comprobar(not imagen.is_empty(), "%s: imagen no vacia" % nombre)
	if imagen.is_empty():
		reproductor.saltar()
		return
	_comprobar(
		imagen.get_width() == ANCHO and imagen.get_height() == ALTO,
		"%s: resolucion 1920x1080" % nombre
	)
	var muestras := _colores_de_imagen(imagen)
	_comprobar(muestras >= 5, "%s: detalle visible, no pantalla plana (%d)" % [nombre, muestras])
	var lectura := _lectura_central(imagen)
	_comprobar(
		float(lectura["media"]) >= 18.0,
		"%s: plano demasiado oscuro (%.1f/255)" % [nombre, float(lectura["media"])]
	)
	_comprobar(
		float(lectura["contraste"]) >= 10.0,
		"%s: encuadre plano sin contraste (%.1f)" % [nombre, float(lectura["contraste"])]
	)
	var ruta := _salida.path_join(nombre)
	var resultado := imagen.save_jpg(ruta, 0.88)
	_comprobar(resultado == OK, "%s: guardar imagen" % nombre)
	if resultado == OK:
		(
			_capturas
			. append(
				{
					"indice": indice,
					"id": String(plano.get("nombre", "")),
					"archivo": nombre,
					"movimiento_reducido": reduccion,
					"rotulo": String(plano.get("rotulo", "")),
					"colores_muestra": muestras,
					"luminancia_media": lectura["media"],
					"contraste_p10_p90": lectura["contraste"],
					"sha256": FileAccess.get_sha256(ruta),
				}
			)
		)
	reproductor.saltar()


static func _colores_de_imagen(imagen: Image) -> int:
	# Se ignoran los márgenes de texto y se mide el centro de imagen 3D.
	# Un fondo gris plano ya produjo PNG falsamente válidos en #830.
	var colores := {}
	for y in range(220, 860, 80):
		for x in range(360, 1560, 100):
			var pixel := imagen.get_pixel(x, y)
			var clave := Vector3i(int(pixel.r * 20), int(pixel.g * 20), int(pixel.b * 20))
			colores[clave] = true
	return colores.size()


## No basta con cinco colores distintos: una pared gris o un plano negro
## con ruido de textura supera el detector anterior. La lectura recorta barras
## cinematográficas y compara p10/p90 para no confundir ruido con composición.
static func _lectura_central(imagen: Image) -> Dictionary:
	var valores: Array[float] = []
	var total := 0.0
	for y in range(220, 860, 80):
		for x in range(360, 1560, 100):
			var p := imagen.get_pixel(x, y)
			var luz := 255.0 * (0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b)
			valores.append(luz)
			total += luz
	valores.sort()
	var ultimo := valores.size() - 1
	var p10 := valores[int(float(ultimo) * 0.10)]
	var p90 := valores[int(float(ultimo) * 0.90)]
	return {"media": total / float(valores.size()), "contraste": p90 - p10}


func _generar_mosaico() -> void:
	var filas := 5
	var mosaico := Image.create(
		CUADRICULA_COLUMNAS * MINIATURA.x, filas * MINIATURA.y, false, Image.FORMAT_RGBA8
	)
	mosaico.fill(Color.BLACK)
	for entrada in _capturas:
		if bool(entrada["movimiento_reducido"]):
			continue
		var miniatura := Image.new()
		var resultado := miniatura.load(_salida.path_join(String(entrada["archivo"])))
		if resultado != OK:
			_comprobar(false, "se puede leer la miniatura: " + String(entrada["archivo"]))
			continue
		miniatura.resize(MINIATURA.x, MINIATURA.y, Image.INTERPOLATE_BILINEAR)
		miniatura.convert(Image.FORMAT_RGBA8)
		var indice := int(entrada["indice"])
		mosaico.blit_rect(
			miniatura,
			Rect2i(Vector2i.ZERO, MINIATURA),
			Vector2i(
				(indice % CUADRICULA_COLUMNAS) * MINIATURA.x,
				(indice / CUADRICULA_COLUMNAS) * MINIATURA.y
			)
		)
	_comprobar(mosaico.save_png(_salida.path_join("contacto_creditos_795.png")) == OK, "mosaico")


func _guardar_manifiesto() -> void:
	var por_defecto := 0
	var reducidas := 0
	for captura in _capturas:
		if bool(captura["movimiento_reducido"]):
			reducidas += 1
		else:
			por_defecto += 1
	_comprobar(por_defecto == 40, "40 fotogramas principales")
	_comprobar(reducidas == INDICES_REDUCIDOS.size(), "muestras con movimiento reducido")
	var datos := {
		"issue": 795,
		"corte": 2527,
		"resolucion": [ANCHO, ALTO],
		"capturas": _capturas,
		"cantidad_normales": por_defecto,
		"cantidad_movimiento_reducido": reducidas,
		"mosaico": "contacto_creditos_795.png",
		"veredicto_automatico": false,
		"requiere_revision_humana": true,
	}
	var archivo := FileAccess.open(_salida.path_join("manifest.json"), FileAccess.WRITE)
	_comprobar(archivo != null, "manifiesto")
	if archivo != null:
		archivo.store_string(JSON.stringify(datos, "\t"))
		archivo.close()


func _comprobar(ok: bool, mensaje: String) -> void:
	if ok:
		return
	_fallos += 1
	push_error("FALLO evidencia créditos #795: " + mensaje)
