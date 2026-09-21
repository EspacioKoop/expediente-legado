## Evidencia reproducible del gate visual de comercios de barrio (#676).
##
## Captura cuatro vistas del trayecto real con cámara jugable y HUD oculto:
## Bit 98 exterior, Bit 98 interior, Quiosco Avenida y El Trastero.
##
## El runner no decide si el arte es suficiente: produce evidencia comparable
## para revisión humana y falla solo ante roturas objetivas del contrato.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 3

const CASOS_CALLE := [
	{
		"id": "bit98_exterior",
		"posicion": Vector3(2.55, 0.0, -9.15),
		"objetivo": Vector3(5.55, 1.55, -6.45),
		"criterio": "Bit 98 se reconoce como tienda de videojuegos desde la acera",
	},
	{
		"id": "quiosco_avenida",
		"posicion": Vector3(2.45, 0.0, 1.35),
		"objetivo": Vector3(4.75, 1.45, 3.75),
		"criterio": "Quiosco Avenida se reconoce como punto de prensa y compra de barrio",
	},
	{
		"id": "el_trastero",
		"posicion": Vector3(-4.05, 0.0, 9.20),
		"objetivo": Vector3(-4.80, 1.45, 11.15),
		"criterio": "El Trastero se reconoce como segunda mano sin bloquear la lectura de la calle",
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-comercios-676")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	TranslationServer.set_locale("es")
	root.size = TAMANO
	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame

	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame
	dia.set_process(false)
	dia._entrar_en("trayecto")
	await process_frame

	var calle := dia._mundo.get_node_or_null("CalleIdentidad") as Node3D
	if calle == null:
		printerr("El trayecto no montó CalleIdentidad")
		quit(1)
		return
	var locales := calle.get_node_or_null("LocalesComerciales") as CalleLocalesComerciales3D
	if locales == null:
		printerr("El trayecto no montó LocalesComerciales")
		quit(1)
		return
	var comercio := calle.get_node_or_null("ComercioBarrioFisico") as ComercioBarrio3D
	if comercio == null:
		printerr("El trayecto no montó ComercioBarrioFisico")
		quit(1)
		return
	if not _validar_rotulos(calle):
		quit(1)
		return

	var manifiesto := {
		"issue": 676,
		"escena": "res://escenas/dia.tscn",
		"fase": "trayecto",
		"locale": TranslationServer.get_locale(),
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"camara": "jugable",
		"criterio": "evidencia_para_revision_humana",
		"veredicto_automatico": false,
		"casos": [],
	}

	for caso in CASOS_CALLE:
		if not await _capturar_caso(dia, salida, manifiesto, caso, "calle"):
			quit(1)
			return

	var fachada_bit98 := calle.get_node_or_null("TiendaVideojuegos") as Node3D
	if fachada_bit98 == null:
		printerr("Falta fachada de Bit 98")
		quit(1)
		return
	var entrar_bit98 := (
		fachada_bit98.get_node_or_null("EntrarTiendaVideojuegos") as Interactuable3D
	)
	var interior_bit98 := locales.get_node_or_null("InteriorBit98") as Node3D
	if entrar_bit98 == null or interior_bit98 == null:
		printerr("Bit 98 no expone entrada e interior para evidencia")
		quit(1)
		return
	entrar_bit98.interactuar(dia._caminante)
	await process_frame
	if not interior_bit98.visible or dia._caminante.global_position.x < 40.0:
		printerr("La entrada real de Bit 98 no activó el interior")
		quit(1)
		return

	var caso_interior := {
		"id": "bit98_interior",
		"posicion": interior_bit98.global_position + Vector3(0.0, 0.0, 2.35),
		"objetivo": interior_bit98.global_position + Vector3(0.0, 1.45, -1.10),
		"criterio": "Bit 98 interior se lee como tienda con mostrador, baldas y producto propio",
	}
	if not await _capturar_caso(dia, salida, manifiesto, caso_interior, "interior"):
		quit(1)
		return

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #676 -> %s" % salida)
	quit(0)


func _capturar_caso(
	dia,
	salida: String,
	manifiesto: Dictionary,
	caso: Dictionary,
	espacio: String,
) -> bool:
	_preparar_camara(dia, caso)
	for i in FRAMES_ESTABILIZACION:
		await process_frame
	_ocultar_hud(dia)
	await RenderingServer.frame_post_draw

	var archivo := "%s.png" % String(caso["id"])
	var destino := salida.path_join(archivo)
	if not _guardar_captura(destino):
		return false
	(
		manifiesto["casos"]
		. append(
			{
				"id": String(caso["id"]),
				"espacio": espacio,
				"captura": archivo,
				"criterio": String(caso["criterio"]),
				"sha256": FileAccess.get_sha256(destino),
			}
		)
	)
	return true


func _preparar_camara(dia, caso: Dictionary) -> void:
	dia._caminante.situar(Vector3(caso["posicion"]), 0.0)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	camara.fov = FOV
	camara.look_at(Vector3(caso["objetivo"]), Vector3.UP)


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _validar_rotulos(calle: Node3D) -> bool:
	for nodo in calle.find_children("*", "Label3D", true, false):
		var rotulo := nodo as Label3D
		if rotulo != null and rotulo.text.begins_with("CALLE_"):
			printerr("Rótulo sin traducir en evidencia #676: %s" % rotulo.text)
			return false
	return true


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("captura -> %s" % destino)
	return true
