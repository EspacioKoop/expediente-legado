## Evidencia visual reproducible para las tres familias originales de #435
## que todavía no tenían capturador dedicado: Gilgamesh #436, Aquiles #438
## y Duat #441.
##
## Genera estados comparables sin emitir un veredicto artístico automático.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FRAMES_ESTABILIZACION := 18


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-mitologias-435")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = TAMANO
	var manifiesto := {
		"issue": 435,
		"familias": [436, 438, 441],
		"veredicto_automatico": false,
		"requiere_revision_humana": true,
		"tamano": [TAMANO.x, TAMANO.y],
		"capturas": [],
	}

	if not await _capturar_gilgamesh(salida, manifiesto):
		quit(1)
		return
	if not await _capturar_aquiles(salida, manifiesto):
		quit(1)
		return
	if not await _capturar_duat(salida, manifiesto):
		quit(1)
		return
	if not _guardar_manifiesto(salida, manifiesto):
		quit(1)
		return

	print("Evidencia #435 para revisión humana: %s" % salida)
	quit(0)


func _capturar_gilgamesh(salida: String, manifiesto: Dictionary) -> bool:
	var mundo := _nuevo_mundo("EvidenciaGilgamesh436", Color(0.055, 0.045, 0.035))
	var sueno := SuenoGilgamesh.new()
	sueno.name = "GilgameshEvidencia"
	mundo.add_child(sueno)
	await _estabilizar()

	if not await _guardar(
		salida, "436_gilgamesh_inicial.png", "gilgamesh_inicial", 436, manifiesto
	):
		return false

	var fragmentos: Array = SuenoGilgamesh.ENCAJES.keys()
	fragmentos.sort()
	for bruto in fragmentos:
		var fragmento := String(bruto)
		var ancla := String(SuenoGilgamesh.ENCAJES[fragmento])
		var resultado := sueno.colocar_fragmento(fragmento, ancla, true)
		if not bool(resultado.get("aceptada", false)):
			printerr("Gilgamesh no aceptó %s -> %s" % [fragmento, ancla])
			return false
	if not sueno.resuelto():
		printerr("Gilgamesh no alcanzó el estado resuelto")
		return false

	if not await _guardar(
		salida, "436_gilgamesh_resuelto.png", "gilgamesh_resuelto", 436, manifiesto
	):
		return false
	mundo.queue_free()
	await process_frame
	return true


func _capturar_aquiles(salida: String, manifiesto: Dictionary) -> bool:
	var mundo := _nuevo_mundo("EvidenciaAquiles438", Color(0.045, 0.045, 0.055))
	var sueno := SuenoAquiles.new()
	sueno.name = "AquilesEvidencia"
	mundo.add_child(sueno)
	await _estabilizar()

	if not sueno.aplicar_lectura_espacial(true, false):
		printerr("Aquiles no reveló el talón con la lectura espacial")
		return false
	if not await _guardar(
		salida, "438_aquiles_revelado.png", "aquiles_revelado", 438, manifiesto
	):
		return false

	if not sueno.aplicar_resolucion("sellar", true):
		printerr("Aquiles no aceptó la resolución por sellado")
		return false
	if not await _guardar(
		salida, "438_aquiles_resuelto.png", "aquiles_resuelto", 438, manifiesto
	):
		return false
	mundo.queue_free()
	await process_frame
	return true


func _capturar_duat(salida: String, manifiesto: Dictionary) -> bool:
	var mundo := _nuevo_mundo("EvidenciaDuat441", Color(0.035, 0.032, 0.028))
	var estado := SuenoDuat.preparar_pesaje(
		[
			{
				"id": "expediente_evidencia",
				"peso": 1.0,
				"manipulado_hoy": true,
			}
		],
		0,
	)
	if estado.is_empty():
		printerr("Duat no generó un pesaje reproducible")
		return false

	var prototipo := SuenoDuat.crear_prototipo_3d(estado, true)
	prototipo.name = "DuatEvidencia"
	mundo.add_child(prototipo)
	_montar_camara_duat(mundo)
	await _estabilizar()

	if not await _guardar(salida, "441_duat_inicial.png", "duat_inicial", 441, manifiesto):
		return false

	var resultado := SuenoDuat.aplicar_pesaje_3d(
		prototipo,
		estado,
		{"expediente_evidencia": false},
		true,
	)
	if not bool(resultado.get("equilibrado", false)):
		printerr("Duat no alcanzó el equilibrio determinista")
		return false
	if not await _guardar(
		salida, "441_duat_equilibrado.png", "duat_equilibrado", 441, manifiesto
	):
		return false
	mundo.queue_free()
	await process_frame
	return true


func _nuevo_mundo(nombre: String, fondo: Color) -> Node3D:
	var mundo := Node3D.new()
	mundo.name = nombre
	root.add_child(mundo)

	var world_environment := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = fondo
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.40, 0.39, 0.37)
	entorno.ambient_light_energy = 0.58
	world_environment.environment = entorno
	mundo.add_child(world_environment)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzComparativa"
	luz.rotation_degrees = Vector3(-52.0, -30.0, 0.0)
	luz.light_color = Color(0.88, 0.82, 0.72)
	luz.light_energy = 1.05
	luz.shadow_enabled = true
	mundo.add_child(luz)
	return mundo


func _montar_camara_duat(mundo: Node3D) -> void:
	var camara := Camera3D.new()
	camara.name = "CamaraDuatEvidencia"
	camara.look_at_from_position(Vector3(0.0, 5.8, 14.5), Vector3(0.0, 2.1, -3.6), Vector3.UP)
	camara.fov = 64.0
	camara.current = true
	mundo.add_child(camara)


func _estabilizar() -> void:
	for _i in FRAMES_ESTABILIZACION:
		await process_frame
	await RenderingServer.frame_post_draw


func _guardar(
	salida: String,
	archivo: String,
	id_estado: String,
	issue: int,
	manifiesto: Dictionary,
) -> bool:
	await _estabilizar()
	var destino := salida.path_join(archivo)
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	(
		manifiesto["capturas"]
		. append(
			{
				"issue": issue,
				"id": id_estado,
				"archivo": archivo,
				"sha256": FileAccess.get_sha256(destino),
			}
		)
	)
	print("%s -> %s" % [id_estado, destino])
	return true


func _guardar_manifiesto(salida: String, manifiesto: Dictionary) -> bool:
	var destino := salida.path_join("manifest.json")
	var archivo := FileAccess.open(destino, FileAccess.WRITE)
	if archivo == null:
		printerr("No se pudo escribir %s" % destino)
		return false
	archivo.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo.close()
	return true
