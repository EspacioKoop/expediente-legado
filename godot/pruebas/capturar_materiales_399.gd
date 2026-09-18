## Evidencia reproducible del gate visual de materiales de #399.
##
## Renderiza las cuatro fases del recorrido real desde `dia.tscn`, con el HUD
## oculto y la cámara del jugador. Las PNG se publican como artifact de CI: no se
## versionan porque el repositorio reserva los binarios de imagen para Git LFS.
##
## Esto NO sustituye el juicio humano de legibilidad. Solo garantiza que quien
## revise #399 mira siempre cuatro encuadres reproducibles del juego real.
extends SceneTree

const TAMANO := Vector2i(1280, 720)
const FOV := 70.0
const FRAMES_ESTABILIZACION := 24

const CASOS := [
	{"id": "oficina", "fase": "archivo"},
	{"id": "calle", "fase": "trayecto"},
	{"id": "casa", "fase": "casa"},
	{"id": "sueno", "fase": "sueño", "escena": "patio"},
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("evidencia-materiales-399")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = TAMANO
	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame

	# La cinemática de entrada no pertenece al gate de materiales. La herramienta
	# aterriza directamente en las fases y desactiva el reloj principal para que
	# el sueño no pueda agotarse durante una captura lenta de CI.
	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame
	dia.set_process(false)

	var manifiesto := {
		"issue": 399,
		"escena": "res://escenas/dia.tscn",
		"tamano": [TAMANO.x, TAMANO.y],
		"fov": FOV,
		"hud": false,
		"casos": [],
	}

	for caso in CASOS:
		if String(caso["fase"]) == "sueño":
			dia.jornada["sueno_escenas"] = [String(caso["escena"])]
		dia._entrar_en(String(caso["fase"]))
		_estabilizar_camara(dia)

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
					"fase": String(caso["fase"]),
					"captura": archivo,
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
	print("evidencia #399 -> %s" % salida)
	quit(0)


func _estabilizar_camara(dia) -> void:
	var entrada: Vector3 = dia._espacio_actual["entrada"]
	var mirada = dia._espacio_actual.get("mirada", NAN)
	dia._caminante.situar(entrada, mirada)
	dia._caminante.set_physics_process(false)
	var camara := dia._caminante.get_node("Camara") as Camera3D
	camara.fov = FOV
	camara.rotation.x = 0.0


func _ocultar_hud(dia) -> void:
	if dia._hud_prioridades != null:
		dia._hud_prioridades.visible = false
	for capa in dia.find_children("*", "CanvasLayer", true, false):
		if capa is CanvasLayer:
			capa.visible = false


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
