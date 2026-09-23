## Evidencia visual reproducible del sueño de Ryū (#440).
##
## Monta el mismo Espacio3D base y la misma escala usada por el controller nocturno,
## sin HUD. Genera tres estados comparables para que la revisión humana juzgue
## silueta, lectura del cauce/reacción y reducción de movimiento.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const ALTURA_JUGADOR := 1.65
const FORMA := "peine"
const ESCALA_RYU := 0.48

const CASOS := [
	{"id": "normal_inicial", "reduccion_movimiento": false, "resolver": false},
	{"id": "normal_resuelto", "reduccion_movimiento": false, "resolver": true},
	{"id": "reducido_resuelto", "reduccion_movimiento": true, "resolver": true},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-ryu-440")
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
		"issue": 440,
		"gate_humano": 398,
		"forma": FORMA,
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"altura_jugador": ALTURA_JUGADOR,
		"escala_ryu": ESCALA_RYU,
		"hud": false,
		"casos": [],
	}

	for caso in CASOS:
		var mundo := Node3D.new()
		mundo.name = "EvidenciaRyu440_%s" % String(caso["id"])
		root.add_child(mundo)

		var espacio := Sueno.espacio(FORMA, 0, {})
		_montar_entorno(mundo, espacio)
		Espacio3D.construir(mundo, espacio)

		var ryu := SuenoRyu.new()
		ryu.name = "SuenoRyuEvidencia"
		ryu.reduccion_movimiento = bool(caso["reduccion_movimiento"])
		ryu.preparar()
		ryu.scale = Vector3.ONE * ESCALA_RYU
		var ancla := _ancla_entre_entrada_y_salida(espacio)
		ryu.position = ancla
		mundo.add_child(ryu)

		var camara := _montar_camara(mundo, ancla)
		if bool(caso["resolver"]):
			if not _resolver_flujo(ryu, mundo):
				quit(1)
				return

		for i in 70:
			await process_frame
		await RenderingServer.frame_post_draw

		var arquitectura := ryu.get_node_or_null("ArquitecturaRyu")
		var lluvia := (
			arquitectura.get_node_or_null("LluviaSuspendida") if arquitectura != null else null
		)
		var archivo := "%s.png" % String(caso["id"])
		if not _guardar_captura(salida.path_join(archivo)):
			quit(1)
			return
		(
			manifiesto["casos"]
			. append(
				{
					"id": String(caso["id"]),
					"archivo": archivo,
					"reduccion_movimiento": bool(caso["reduccion_movimiento"]),
					"resuelto": ryu.resuelto(),
					"estado_compuertas": ryu.estado_compuertas(),
					"gotas": lluvia.get_child_count() if lluvia != null else -1,
					"ancla": _vector_a_array(ancla),
					"camara": _vector_a_array(camara.position),
					"objetivo": _vector_a_array(ancla + Vector3(0.0, 1.55, 0.0)),
				}
			)
		)

		mundo.queue_free()
		await process_frame

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
	var ambiente: Color = espacio.get("ambiente", Color(0.055, 0.075, 0.085))
	var world_environment := WorldEnvironment.new()
	world_environment.name = "EntornoEvidenciaRyu440"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = ambiente.darkened(0.38)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.30, 0.42, 0.46)
	entorno.ambient_light_energy = 0.58
	world_environment.environment = entorno
	mundo.add_child(world_environment)

	var luz := DirectionalLight3D.new()
	luz.name = "LuzComparativaRyu"
	luz.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	luz.light_color = Color(0.70, 0.80, 0.82)
	luz.light_energy = 0.92
	luz.shadow_enabled = true
	mundo.add_child(luz)


func _montar_camara(mundo: Node3D, ancla: Vector3) -> Camera3D:
	var camara := Camera3D.new()
	camara.name = "CamaraJugadorSinHUD"
	# El Ryū se ancla en el dedo central de la forma peine. Mirarlo desde +x/+z
	# sacaba la cámara fuera de la planta y la evidencia atravesaba un muro.
	# Este punto queda dentro del mismo pasillo, a altura real de jugador.
	camara.position = Vector3(ancla.x, ALTURA_JUGADOR, ancla.z - 6.2)
	camara.fov = FOV
	camara.current = true
	mundo.add_child(camara)
	camara.look_at(ancla + Vector3(0.0, 1.15, 0.4), Vector3.UP)
	return camara


func _resolver_flujo(ryu: SuenoRyu, mundo: Node3D) -> bool:
	var arquitectura := ryu.get_node_or_null("ArquitecturaRyu")
	if arquitectura == null:
		printerr("Ryū no montó ArquitecturaRyu")
		return false
	var actor := Node.new()
	actor.name = "ActorEvidencia"
	mundo.add_child(actor)
	for indice in range(1, 4):
		var compuerta := (
			arquitectura.get_node_or_null("CompuertaCauce%d" % indice) as Interactuable3D
		)
		if compuerta == null or not compuerta.interactuar(actor):
			printerr("No se pudo accionar compuerta %d" % indice)
			return false
	return ryu.resuelto()


func _ancla_entre_entrada_y_salida(espacio: Dictionary) -> Vector3:
	var entrada: Vector3 = espacio.get("entrada", Vector3.ZERO)
	var salidas: Array = espacio.get("salidas", [])
	if salidas.is_empty():
		return entrada
	var salida: Vector3 = salidas[0].get("pos", entrada)
	return entrada.lerp(salida, 0.5)


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Viewport vacío para %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("Ryū -> %s" % destino)
	return true


func _vector_a_array(vector: Vector3) -> Array:
	return [vector.x, vector.y, vector.z]
