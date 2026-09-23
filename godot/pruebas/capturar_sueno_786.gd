## Evidencia visual reproducible del sueño sin lecturas (#786).
##
## Renderiza dos encuadres sin HUD del caso exacto leido_hoy=[] usando la misma
## construcción de Espacio3D y la presentación SuenoVacio3D del runtime.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const ALTURA_JUGADOR := 1.65
const FORMA := "peine"

const ENCUADRES := [
	{
		"id": "entrada",
		"camara": Vector3(-8.2, ALTURA_JUGADOR, -7.8),
		"objetivo": Vector3(-3.8, 1.15, -1.5),
	},
	{
		"id": "interior",
		"camara": Vector3(0.0, ALTURA_JUGADOR, 6.2),
		"objetivo": Vector3(1.1, 1.05, 2.4),
	},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-sueno-786")
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
	mundo.name = "EvidenciaSuenoVacio786"
	root.add_child(mundo)

	var espacio := SuenoVacio.adaptar_espacio(Sueno.espacio(FORMA, 0, {}))
	_montar_entorno(mundo, espacio)
	Espacio3D.construir(mundo, espacio)
	var presentacion := SuenoVacio3D.montar(mundo, espacio)
	if presentacion == null:
		printerr("No se pudo montar SuenoVacio3D")
		quit(1)
		return

	var camara := Camera3D.new()
	camara.name = "CamaraJugadorSinHUD"
	camara.fov = FOV
	camara.current = true
	mundo.add_child(camara)

	var manifiesto := {
		"issue": 786,
		"forma": FORMA,
		"leido_hoy": [],
		"identidad_onirica": String(espacio.get("identidad_onirica", "")),
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"altura_jugador": ALTURA_JUGADOR,
		"hud": false,
		"capturas": [],
	}

	for encuadre in ENCUADRES:
		camara.position = Vector3(encuadre["camara"])
		camara.look_at(Vector3(encuadre["objetivo"]), Vector3.UP)
		for i in 10:
			await process_frame
		await RenderingServer.frame_post_draw

		var archivo := "%s.png" % String(encuadre["id"])
		if not _guardar_captura(salida.path_join(archivo)):
			quit(1)
			return
		manifiesto["capturas"].append(
			{
				"id": String(encuadre["id"]),
				"archivo": archivo,
				"camara": _vector_a_array(Vector3(encuadre["camara"])),
				"objetivo": _vector_a_array(Vector3(encuadre["objetivo"])),
			}
		)

	var ruta_manifiesto := salida.path_join("manifest.json")
	var archivo_manifiesto := FileAccess.open(ruta_manifiesto, FileAccess.WRITE)
	if archivo_manifiesto == null:
		printerr("No se pudo crear %s" % ruta_manifiesto)
		quit(1)
		return
	archivo_manifiesto.store_string(JSON.stringify(manifiesto, "\t") + "\n")
	archivo_manifiesto.close()
	print("manifiesto -> %s" % ruta_manifiesto)
	quit(0)


func _montar_entorno(mundo: Node3D, espacio: Dictionary) -> void:
	var ambiente: Color = espacio.get("ambiente", Color(0.075, 0.085, 0.09))
	var world_environment := WorldEnvironment.new()
	world_environment.name = "EntornoEvidencia786"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = ambiente.darkened(0.32)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = ambiente.lightened(0.34)
	entorno.ambient_light_energy = float(espacio.get("ambiente_energia", 0.38))
	world_environment.environment = entorno
	mundo.add_child(world_environment)


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("sueño vacío -> %s" % destino)
	return true


func _vector_a_array(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]
