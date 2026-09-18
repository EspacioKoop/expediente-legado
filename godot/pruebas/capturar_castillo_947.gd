## Evidencia visual reproducible del castillo onírico (#947).
##
## Renderiza las cuatro composiciones con la misma cámara e iluminación y añade
## una quinta toma del claustro con mutación de giro, una sexta de la capilla
## tras la tercera campanada y una séptima del scriptorium tras leer el códice. No sustituye el pase humano
## de #398: sirve para comparar silueta, profundidad y regresiones.
extends SceneTree

const CASOS := [
	{"nombre": "patio", "variante": "patio", "mutacion": "estable"},
	{"nombre": "scriptorium", "variante": "scriptorium", "mutacion": "estable"},
	{
		"nombre": "scriptorium_lectura",
		"variante": "scriptorium",
		"mutacion": "estable",
		"lectura": true
	},
	{"nombre": "torre_capilla", "variante": "torre_capilla", "mutacion": "estable"},
	{
		"nombre": "torre_capilla_pulso",
		"variante": "torre_capilla",
		"mutacion": "estable",
		"pulso": 2
	},
	{"nombre": "claustro", "variante": "claustro_reflejado", "mutacion": "estable"},
	{"nombre": "claustro_giro", "variante": "claustro_reflejado", "mutacion": "giro"},
]

const TAMANO := Vector2i(1024, 680)


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-castillo-947")
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
	mundo.name = "EvidenciaCastillo947"
	root.add_child(mundo)
	_montar_entorno(mundo)
	var camara := _montar_camara(mundo)

	for caso in CASOS:
		var espacio := {
			"identidad_onirica": SuenoCastillo.ID,
			"variante_castillo": caso["variante"],
			"mutacion_castillo": caso["mutacion"],
		}
		var presentacion := SuenoCastillo3D.montar(mundo, espacio)
		if presentacion == null:
			printerr("No se pudo montar %s" % caso["nombre"])
			quit(1)
			return
		for i in 12:
			await process_frame
		if bool(caso.get("lectura", false)):
			var controlador_lectura := (
				presentacion.get_node_or_null("PulsoArquitectonico") as SuenoCastilloPulso3D
			)
			if controlador_lectura != null:
				controlador_lectura.set_process(false)
				controlador_lectura.aplicar_pulso(-1)
			SuenoCastillo3D.reaccionar_a_lectura(mundo)
		if caso.has("pulso"):
			var controlador := (
				presentacion.get_node_or_null("PulsoArquitectonico") as SuenoCastilloPulso3D
			)
			if controlador != null:
				controlador.set_process(false)
				controlador.aplicar_pulso(int(caso["pulso"]))
		camara.look_at(Vector3(0.0, 2.2, 0.0), Vector3.UP)
		for i in 2:
			await process_frame
		var destino := salida.path_join("%s.png" % caso["nombre"])
		if not _guardar_captura(destino):
			quit(1)
			return
		presentacion.queue_free()
		await process_frame

	quit(0)


func _montar_entorno(mundo: Node3D) -> void:
	var world_environment := WorldEnvironment.new()
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.025, 0.022, 0.028)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.46, 0.43, 0.39)
	entorno.ambient_light_energy = 0.72
	world_environment.environment = entorno
	mundo.add_child(world_environment)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sol.light_color = Color(0.78, 0.70, 0.60)
	sol.light_energy = 0.96
	sol.shadow_enabled = true
	mundo.add_child(sol)


func _montar_camara(mundo: Node3D) -> Camera3D:
	var camara := Camera3D.new()
	camara.position = Vector3(13.5, 8.2, 15.5)
	camara.fov = 58.0
	camara.current = true
	mundo.add_child(camara)
	camara.look_at(Vector3(0.0, 2.2, 0.0), Vector3.UP)
	return camara


func _guardar_captura(destino: String) -> bool:
	var imagen := root.get_texture().get_image()
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	print("castillo -> %s" % destino)
	return true
