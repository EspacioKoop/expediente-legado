## Evidencia perceptiva reproducible del sueño de la Hidra (#439).
##
## Captura el mismo encuentro desde una cámara fija sin HUD en tres estados:
## inicial, proliferación con la raíz ya deducible y resolución. El artifact
## permite comparar causalidad visual sin convertir métricas en juicio artístico.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 4
const ESCALA_ENCUENTRO := 0.58
const POSICION_CAMARA := Vector3(0.0, 3.4, 10.5)
const OBJETIVO_CAMARA := Vector3(0.0, 1.25, 2.0)


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-hidra-439")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = TAMANO
	var mundo := Node3D.new()
	mundo.name = "EvidenciaHidra439"
	root.add_child(mundo)
	_montar_entorno(mundo)
	_montar_camara(mundo)

	var encuentro := SuenoHidraInteraccion3D.new()
	encuentro.name = "SuenoHidraEvidencia"
	encuentro.scale = Vector3.ONE * ESCALA_ENCUENTRO
	mundo.add_child(encuentro)

	var semillas := {}
	semillas[SuenoHidra.SEMILLA] = {"fuente": "rom:hydra_loop_98"}
	if not encuentro.configurar(semillas, false, 3):
		printerr("La semilla de Hidra no habilitó el encuentro")
		quit(1)
		return

	var hidra := encuentro.get_node_or_null("HidraProcedural") as SuenoHidra
	var sintoma := encuentro.get_node_or_null("SintomaHidra") as Interactuable3D
	var nodo := encuentro.get_node_or_null("NodoComunHidra") as Interactuable3D
	if hidra == null or sintoma == null or nodo == null:
		printerr("No se montó el vertical jugable completo de Hidra")
		quit(1)
		return

	var actor := Node.new()
	actor.name = "ActorEvidencia"
	mundo.add_child(actor)

	var manifiesto := {
		"issue": 439,
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"renderer": "forward_plus",
		"criterio": "evidencia_para_revision_humana",
		"estados": [],
	}

	if not await _capturar_estado(salida, "01_inicial.png", "inicial", hidra, manifiesto):
		quit(1)
		return

	if not sintoma.interactuar(actor) or not sintoma.interactuar(actor):
		printerr("No se pudo llevar la Hidra al estado de proliferación")
		quit(1)
		return
	if not await _capturar_estado(
		salida,
		"02_proliferacion.png",
		"proliferacion",
		hidra,
		manifiesto,
	):
		quit(1)
		return

	if not nodo.interactuar(actor):
		printerr("El nodo común no quedó resoluble tras hacer legible la raíz")
		quit(1)
		return
	if not await _capturar_estado(salida, "03_resuelta.png", "resuelta", hidra, manifiesto):
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
	print("evidencia #439 -> %s" % salida)
	quit(0)


func _capturar_estado(
	salida: String,
	archivo: String,
	id_estado: String,
	hidra: SuenoHidra,
	manifiesto: Dictionary,
) -> bool:
	for _i in FRAMES_ESTABILIZACION:
		await process_frame
	await RenderingServer.frame_post_draw

	var destino := salida.path_join(archivo)
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false

	var estado := hidra.estado_actual()
	manifiesto["estados"].append(
		{
			"id": id_estado,
			"captura": archivo,
			"cabezas": int(estado.get("cabezas", 0)),
			"regeneraciones": int(estado.get("regeneraciones", 0)),
			"nodo_legible": estado.get("nodo_legible", false) == true,
			"resuelta": estado.get("resuelta", false) == true,
			"sha256": FileAccess.get_sha256(destino),
		}
	)
	print("%s -> %s" % [id_estado, destino])
	return true


func _montar_entorno(mundo: Node3D) -> void:
	var world_environment := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.035, 0.04, 0.055)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.34, 0.36, 0.42)
	entorno.ambient_light_energy = 0.62
	world_environment.environment = entorno
	mundo.add_child(world_environment)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzEvidencia"
	luz.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	luz.light_color = Color(0.88, 0.84, 0.73)
	luz.light_energy = 1.15
	luz.shadow_enabled = true
	mundo.add_child(luz)

	var suelo := MeshInstance3D.new()
	suelo.name = "SueloNeutro"
	var malla := BoxMesh.new()
	malla.size = Vector3(13.0, 0.12, 18.0)
	suelo.mesh = malla
	suelo.position = Vector3(0.0, -0.08, 2.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.12, 0.13)
	material.roughness = 0.94
	suelo.material_override = material
	mundo.add_child(suelo)


func _montar_camara(mundo: Node3D) -> void:
	var camara := Camera3D.new()
	camara.name = "CamaraJugadorSinHUD"
	camara.position = POSICION_CAMARA
	camara.fov = FOV
	camara.current = true
	mundo.add_child(camara)
	camara.look_at(OBJETIVO_CAMARA, Vector3.UP)
