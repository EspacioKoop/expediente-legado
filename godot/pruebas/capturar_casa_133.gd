## Evidencia reproducible del gate visual de #133.
##
## Captura tres vistas de la casa real con cámara jugable y HUD oculto:
## 1) lectura general desde la entrada;
## 2) transición salón/dormitorio con cocina al fondo;
## 3) aproximación al rincón de TV y consola.
##
## No decide si la composición es suficiente: produce evidencia estable para
## revisión humana y falla solo si la escena o el contrato de captura se rompen.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 3

const CASOS := [
	{
		"id": "entrada_vivienda",
		"posicion": Vector3(0.45, 0.0, 3.35),
		"objetivo": Vector3(-1.35, 1.15, 0.15),
		"criterio": "desde la entrada se entiende una vivienda con zonas domésticas diferenciadas",
	},
	{
		"id": "salon_dormitorio",
		"posicion": Vector3(0.80, 0.0, 0.95),
		"objetivo": Vector3(-1.65, 1.10, -1.55),
		"criterio": "el dormitorio se lee como estancia separada y conectada al salón",
	},
	{
		"id": "consola_television",
		"posicion": Vector3(-1.45, 0.0, 2.35),
		"objetivo_nodo": "ConsolaSobremesa98",
		"criterio": "televisor y consola forman un rincón de ocio accesible desde el salón",
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-casa-133")
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
	dia._entrar_en("casa")
	await process_frame

	var requisitos := [
		"CasaHogarCC0",
		"HabitacionesCasa",
		"TransicionesCasa",
		"ConsolaSobremesa98",
		"TelevisorCasaInteractuable",
	]
	for nombre in requisitos:
		if dia._mundo.get_node_or_null(nombre) == null:
			printerr("Falta nodo requerido por #133: %s" % nombre)
			quit(1)
			return

	var manifiesto := {
		"issue": 133,
		"escena": "res://escenas/dia.tscn",
		"fase": "casa",
		"locale": TranslationServer.get_locale(),
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"camara": "jugable",
		"criterio": "evidencia_para_revision_humana",
		"veredicto_automatico": false,
		"casos": [],
	}

	for caso in CASOS:
		if not _preparar_camara(dia, caso):
			quit(1)
			return
		for i in FRAMES_ESTABILIZACION:
			await process_frame
		_ocultar_hud(dia)
		await RenderingServer.frame_post_draw

		var archivo := "%s.png" % String(caso["id"])
		var destino := salida.path_join(archivo)
		if not _guardar_captura(destino):
			quit(1)
			return
		(
			manifiesto["casos"]
			. append(
				{
					"id": String(caso["id"]),
					"captura": archivo,
					"criterio": String(caso["criterio"]),
					"sha256": FileAccess.get_sha256(destino),
				}
			)
		)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("evidencia #133 -> %s" % salida)
	quit(0)


func _preparar_camara(dia, caso: Dictionary) -> bool:
	dia._caminante.situar(Vector3(caso["posicion"]), 0.0)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	camara.fov = FOV

	var objetivo: Vector3
	if caso.has("objetivo_nodo"):
		var nodo := dia._mundo.get_node_or_null(String(caso["objetivo_nodo"])) as Node3D
		if nodo == null:
			printerr("No existe objetivo de cámara: %s" % String(caso["objetivo_nodo"]))
			return false
		objetivo = nodo.global_position + Vector3(0.0, 0.20, 0.0)
	else:
		objetivo = Vector3(caso["objetivo"])
	camara.look_at(objetivo, Vector3.UP)
	return true


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacio para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("captura -> %s" % destino)
	return true
