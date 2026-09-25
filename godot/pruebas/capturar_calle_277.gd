## Evidencia reproducible del gate visual de #277.
##
## Captura cuatro vistas del trayecto real con la cámara jugable y sin HUD:
## 1) desde el spawn hacia casa, para juzgar si se lee como exterior;
## 2) desde la mitad del recorrido, para comprobar que la calle conserva profundidad;
## 3) el escaparate de electrodomésticos, para juzgar si las CRT tienen contexto;
## 4) la aproximación al portal 7, para juzgar si el destino se entiende.
##
## Este runner no decide el resultado artístico: produce evidencia comparable para
## revisión humana y falla solo ante roturas objetivas del contrato de captura.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 3

const CASOS := [
	{
		"id": "spawn_exterior",
		"usar_entrada": true,
		"objetivo": Vector3(0.0, 1.8, 15.5),
		"criterio": "desde el spawn se reconoce una calle exterior sin HUD",
	},
	{
		"id": "mitad_recorrido",
		"posicion": Vector3(0.0, 0.0, 3.5),
		"objetivo": Vector3(0.0, 1.8, 13.5),
		"criterio":
		"desde la mitad del trayecto se conserva cielo, profundidad urbana y lectura de calle",
	},
	{
		"id": "escaparate_crt",
		"posicion": Vector3(0.0, 0.0, -1.5),
		"objetivo": Vector3(-5.7, 1.55, -1.5),
		"criterio":
		"las CRT se leen como escaparate de electrodomesticos y no como pantallas arbitrarias",
	},
	{
		"id": "portal_casa",
		"posicion": Vector3(0.0, 0.0, 8.0),
		"objetivo": Vector3(0.0, 1.7, 16.3),
		"criterio": "el portal 7 se reconoce como destino de vivienda al final del recorrido",
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-calle-277")
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

	if not _validar_rotulos_calle(dia):
		quit(1)
		return

	var manifiesto := {
		"issue": 277,
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

	for caso in CASOS:
		_preparar_camara(dia, caso)
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
	print("evidencia #277 -> %s" % salida)
	quit(0)


func _preparar_camara(dia, caso: Dictionary) -> void:
	var posicion: Vector3
	if bool(caso.get("usar_entrada", false)):
		posicion = dia._espacio_actual["entrada"]
	else:
		posicion = caso["posicion"]
	dia._caminante.situar(posicion, 0.0)
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


func _validar_rotulos_calle(dia) -> bool:
	var calle := dia._mundo.get_node_or_null("CalleIdentidad") as Node3D
	if calle == null:
		printerr("El trayecto no monto CalleIdentidad")
		return false
	for nodo in calle.find_children("*", "Label3D", true, false):
		var rotulo := nodo as Label3D
		if rotulo != null and rotulo.text.begins_with("CALLE_"):
			printerr("Rotulo sin traducir en evidencia #277: %s" % rotulo.text)
			return false
	return true


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
