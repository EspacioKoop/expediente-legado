## Evidencia visual de los estados activos de los rituales de #779.
##
##   xvfb-run -a godot4 --path godot --script res://pruebas/capturar_feedback_779.gd \
##       -- /tmp/juicio-779-feedback
extends SceneTree

const CASOS := [
	{
		"archivo": "sol-maui-interrupcion",
		"arcano": "el-sol",
		"nombre": "El Sol",
		"mito": "maui_tamanuitera",
		"estado": "sol",
	},
	{
		"archivo": "colgado-anansi-enredo",
		"arcano": "el-colgado",
		"nombre": "El Colgado",
		"mito": "anansi_akan",
		"estado": "anansi",
	},
	{
		"archivo": "muerte-hidra-retorno",
		"arcano": "la-muerte",
		"nombre": "La Muerte",
		"mito": "hidra",
		"estado": "hidra",
	},
]


class Anfitrion:
	extends Node3D
	var partida := Partida.new()


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("capturas-juicio-779-feedback")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = Vector2i(1280, 720)
	for caso in CASOS:
		await _capturar(caso, salida)
	quit(0)


func _capturar(caso: Dictionary, salida: String) -> void:
	var anfitrion := Anfitrion.new()
	anfitrion.partida.estado = {
		"tarot":
		[
			{
				"id": String(caso["arcano"]),
				"nombre": String(caso["nombre"]),
				"recogida": true,
				"gastada": false,
			}
		],
		"jornada": {"dia": 4},
	}
	SemillasOniricas.activar_semilla_onirica(
		anfitrion.partida.estado["jornada"], String(caso["mito"]), "captura:feedback-779"
	)
	root.add_child(anfitrion)

	var juicio := JuicioCombate3D.new()
	juicio.configurar({"id": "reclamante_feedback", "nombre": "RECLAMANTE DE ARCHIVO"}, 0, false)
	anfitrion.add_child(juicio)
	await process_frame
	juicio.set_process(false)
	juicio._jugador.position = Vector3(0.0, 0.0, -1.1)
	juicio._actualizar_camara()

	var feedback := juicio.get_node_or_null("FeedbackRitualActivo") as JuicioFeedbackRitual
	if feedback == null:
		printerr("No se montó FeedbackRitualActivo")
		quit(1)
		return
	feedback._process(0.0)

	match String(caso["estado"]):
		"sol":
			juicio._iniciar_ataque_rival()
			feedback._process(0.0)
			juicio._recarga_jugador = 0.0
			juicio._atacar(2, 2.15, 0.58, true)
			feedback._process(0.0)
		"anansi":
			juicio._recarga_jugador = 0.0
			juicio._atacar(1, 1.75, 0.28, false)
			feedback._process(0.0)
		"hidra":
			juicio._determinacion_rival = 1
			feedback._process(0.0)
			juicio._recarga_jugador = 0.0
			juicio._atacar(1, 1.75, 0.28, false)
			feedback._process(0.0)
	feedback.set_process(false)

	for i in 12:
		await process_frame
	_guardar(salida, String(caso["archivo"]))
	anfitrion.queue_free()
	await process_frame


func _guardar(salida: String, archivo: String) -> void:
	var destino := salida.path_join("%s.png" % archivo)
	var imagen := root.get_texture().get_image()
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		quit(1)
		return
	print("juicio feedback %s -> %s" % [archivo, destino])
