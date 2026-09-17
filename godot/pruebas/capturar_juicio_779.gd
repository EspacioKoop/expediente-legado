## Evidencia visual reproducible del Juicio por Combate (#779).
##
## Ejecutar con renderer real, no `--headless`:
##
##   xvfb-run -a godot4 --path godot --script res://pruebas/capturar_juicio_779.gd \
##       -- /tmp/juicio-779
##
## Genera tres arenas con una sola carta y una sola semilla cada una para que el
## ritual resultante sea determinista y comparable entre revisiones. Justicia +
## Duat añade una cuarta captura con el aviso real de ataque rival activo.
extends SceneTree

const CASOS := [
	{
		"archivo": "luna-minotauro",
		"arcano": "la-luna",
		"nombre": "La Luna",
		"mito": "minotauro",
	},
	{
		"archivo": "justicia-duat",
		"arcano": "la-justicia",
		"nombre": "La Justicia",
		"mito": "duat",
	},
	{
		"archivo": "fuerza-aquiles",
		"arcano": "la-fuerza",
		"nombre": "La Fuerza",
		"mito": "aquiles",
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
		else OS.get_user_data_dir().path_join("capturas-juicio-779")
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
		await _capturar_caso(caso, salida)

	quit(0)


func _capturar_caso(caso: Dictionary, salida: String) -> void:
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
		anfitrion.partida.estado["jornada"], String(caso["mito"]), "captura:juicio-779"
	)
	root.add_child(anfitrion)

	var juicio := JuicioCombate3D.new()
	(
		juicio
		. configurar(
			{"id": "reclamante_captura", "nombre": "RECLAMANTE DE ARCHIVO"},
			1,
			false,
		)
	)
	anfitrion.add_child(juicio)
	await process_frame
	juicio.set_process(false)

	# Deja que materiales, fuentes y viewport completen varios ciclos de render.
	for i in 12:
		await process_frame

	_guardar_captura(salida, String(caso["archivo"]))

	if String(caso["archivo"]) == "justicia-duat":
		juicio._jugador.position = Vector3(0.0, 0.0, -1.1)
		juicio._actualizar_camara()
		juicio._iniciar_ataque_rival()
		await process_frame
		await process_frame
		_guardar_captura(salida, "telegraph-ataque")

	anfitrion.queue_free()
	await process_frame


func _guardar_captura(salida: String, archivo: String) -> void:
	var destino := salida.path_join("%s.png" % archivo)
	var imagen := root.get_texture().get_image()
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		quit(1)
		return
	print("juicio %s -> %s" % [archivo, destino])
