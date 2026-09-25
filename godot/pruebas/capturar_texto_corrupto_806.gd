## Evidencia visual reproducible para #806.
##
## Renderiza las dos superficies reales exigidas por el criterio de aceptación:
## el VisorDocumento de ExploradorSiga y el Label3D DestinoArchivado montado
## sobre ArchivadorInteractivo3D. No modifica estado de campaña.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const COLOR_FONDO := Color(0.035, 0.045, 0.055)
const CONTEXTO := {
	"efecto_texto":
	{
		"activo": true,
		"intensidad": 0.88,
		"duracion": 1.0,
		"semilla": "evidencia-806-climax",
	},
}


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-texto-corrupto-806")
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
	var manifiesto := {
		"issue": 806,
		"locale": TranslationServer.get_locale(),
		"tamano": [TAMANO.x, TAMANO.y],
		"veredicto_automatico": false,
		"casos": [],
	}

	var caso_documento := await _capturar_documento(salida)
	if caso_documento.is_empty():
		quit(1)
		return
	manifiesto["casos"].append(caso_documento)

	var caso_rotulo := await _capturar_rotulo_3d(salida)
	if caso_rotulo.is_empty():
		quit(1)
		return
	manifiesto["casos"].append(caso_rotulo)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo.close()
	print("evidencia #806 -> %s" % salida)
	quit(0)


func _capturar_documento(salida: String) -> Dictionary:
	var fondo := ColorRect.new()
	fondo.color = COLOR_FONDO
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fondo)

	var marco := PanelContainer.new()
	marco.position = Vector2(150, 85)
	marco.size = Vector2(980, 550)
	fondo.add_child(marco)

	var explorador := ExploradorSiga.new()
	explorador.name = "ExploradorSigaEvidencia"
	marco.add_child(explorador)
	await process_frame

	var visor := explorador.find_child("VisorDocumento", true, false) as RichTextLabel
	if visor == null:
		printerr("ExploradorSiga no montó VisorDocumento")
		fondo.queue_free()
		return {}
	visor.text = (
		"MEMORÁNDUM INTERNO 13-B / ACCESO RESTRINGIDO\n\n"
		+ "Las referencias cruzadas ya no coinciden con el índice. "
		+ "No reenviar este documento fuera de SIGA."
	)

	var controlador := load("res://guion/dia_climax_os98_app.gd").new()
	controlador._sincronizar_documento(explorador, CONTEXTO, false, 0.78)
	var original := String(controlador._texto_original)
	var visual := visor.text
	if visual == original:
		printerr("El documento no alcanzó un estado visual corrupto")
		controlador.free()
		fondo.queue_free()
		return {}

	await process_frame
	await RenderingServer.frame_post_draw
	var destino := salida.path_join("documento-os98.png")
	if not _guardar_captura(destino):
		controlador.free()
		fondo.queue_free()
		return {}

	var caso := {
		"id": "documento-os98",
		"captura": "documento-os98.png",
		"superficie": "ExploradorSiga/VisorDocumento",
		"texto_original": original,
		"texto_visual": visual,
		"sha256": FileAccess.get_sha256(destino),
	}
	controlador.free()
	fondo.queue_free()
	await process_frame
	return caso


func _capturar_rotulo_3d(salida: String) -> Dictionary:
	var mundo := Node3D.new()
	mundo.name = "MundoEvidencia806"
	root.add_child(mundo)

	var entorno := WorldEnvironment.new()
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = COLOR_FONDO
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.72, 0.74, 0.78)
	ambiente.ambient_light_energy = 1.2
	entorno.environment = ambiente
	mundo.add_child(entorno)

	var archivador := ArchivadorInteractivo3D.new()
	archivador.name = "ArchivadorEvidencia"
	mundo.add_child(archivador)
	archivador.configurar(Vector3(1.8, 2.2, 0.8))

	var cuerpo := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = Vector3(1.8, 2.2, 0.8)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.20, 0.21)
	malla.material = material
	cuerpo.mesh = malla
	archivador.add_child(cuerpo)

	var rotulo := Label3D.new()
	rotulo.name = "DestinoArchivado"
	rotulo.text = "ARCHIVO CENTRAL"
	rotulo.font_size = 46
	rotulo.pixel_size = 0.006
	rotulo.position = Vector3(0.0, 0.55, 0.43)
	rotulo.modulate = Color(0.96, 0.88, 0.66)
	rotulo.outline_size = 8
	archivador.add_child(rotulo)

	var camara := Camera3D.new()
	camara.position = Vector3(0.0, 0.25, 4.2)
	camara.fov = 45.0
	mundo.add_child(camara)
	camara.look_at(Vector3(0.0, 0.3, 0.0), Vector3.UP)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	luz.light_energy = 1.5
	mundo.add_child(luz)

	var controlador := load("res://guion/dia_climax_os98_app.gd").new()
	controlador._sincronizar_rotulos_3d(mundo, CONTEXTO, false, 0.78)
	var original := String(rotulo.get_meta("_texto_corrupto_original_806", ""))
	var visual := rotulo.text
	if visual == original:
		printerr("El rótulo 3D no alcanzó un estado visual corrupto")
		controlador.free()
		mundo.queue_free()
		return {}

	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var destino := salida.path_join("rotulo-3d.png")
	if not _guardar_captura(destino):
		controlador.free()
		mundo.queue_free()
		return {}

	var caso := {
		"id": "rotulo-3d",
		"captura": "rotulo-3d.png",
		"superficie": "ArchivadorInteractivo3D/DestinoArchivado",
		"texto_original": original,
		"texto_visual": visual,
		"sha256": FileAccess.get_sha256(destino),
	}
	controlador.free()
	mundo.queue_free()
	await process_frame
	return caso


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
