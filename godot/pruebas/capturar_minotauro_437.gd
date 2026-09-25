## Evidencia visual reproducible de la regla espacial del Minotauro (#437).
##
## No decide si la escena "se entiende": genera tres estados comparables para
## revisión humana, sin HUD ni texto explicativo superpuesto.
extends SceneTree

const CAPTURAS := ["inicial", "marca-estable", "marca-desplazada"]

func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("minotauro-437")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = Vector2i(1280, 720)
	var mundo := Node3D.new()
	mundo.name = "EvidenciaMinotauro437"
	root.add_child(mundo)

	var camara := Camera3D.new()
	camara.name = "CamaraEvidencia"
	camara.position = Vector3(0.0, 10.5, 13.0)
	camara.look_at(Vector3(0.0, 0.0, -1.0), Vector3.UP)
	camara.fov = 58.0
	mundo.add_child(camara)
	camara.current = true

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	luz.light_energy = 1.25
	mundo.add_child(luz)

	var minotauro := SuenoMinotauro3D.new()
	minotauro.reduccion_movimiento = true
	mundo.add_child(minotauro)
	minotauro.preparar()

	for i in 8:
		await process_frame
	_guardar(salida, CAPTURAS[0])

	if not minotauro.marcar_y_cruzar(SuenoMinotauro.CRUCE_NORTE):
		printerr("No se pudo crear la primera marca")
		quit(1)
		return
	for i in 4:
		await process_frame
	_guardar(salida, CAPTURAS[1])

	# Dos repliegues deterministas hacen que la primera marca real del cruce
	# norte reaparezca en el cruce sur aparente. El hilo sigue la topología real.
	if not minotauro.marcar_y_cruzar(SuenoMinotauro.BISAGRA):
		printerr("No se pudo cruzar la bisagra")
		quit(1)
		return
	if not minotauro.marcar_y_cruzar(SuenoMinotauro.CENTRO):
		printerr("No se pudo cruzar el centro")
		quit(1)
		return
	for i in 4:
		await process_frame
	_guardar(salida, CAPTURAS[2])

	var estado := minotauro.estado()
	var lectura := SuenoMinotauro.leer_marca(estado, 0)
	var manifiesto := {
		"issue": 437,
		"veredicto_automatico": false,
		"fase_topologica": int(estado.get("fase_topologica", -1)),
		"primera_marca": lectura,
		"capturas": CAPTURAS,
	}
	var archivo := FileAccess.open(salida.path_join("manifest.json"), FileAccess.WRITE)
	if archivo == null:
		printerr("No se pudo escribir manifest.json")
		quit(1)
		return
	archivo.store_string(JSON.stringify(manifiesto, "\t"))
	archivo.close()
	print("Evidencia #437 lista para revisión humana: %s" % salida)
	quit(0)


func _guardar(salida: String, nombre: String) -> void:
	var destino := salida.path_join("%s.png" % nombre)
	var imagen := root.get_texture().get_image()
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		quit(1)
