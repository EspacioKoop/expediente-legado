## Capturas comparables para el criterio visual de #797 y su segunda pasada #883.
##
## Ejecutar con renderer real, no `--headless`:
##
##   xvfb-run -a godot4 --path godot --script res://pruebas/capturar_climas_797.gd \
##       -- /tmp/climas-797
##
## Genera despejado/nublado/lluvia/niebla/nieve desde la misma entrada y con
## la misma orientación del trayecto. Es una ayuda de revisión: las imágenes
## deben MIRARSE antes de considerar resuelto un cambio visual.
extends SceneTree

const ESTADOS := [
	Clima.DESPEJADO,
	Clima.NUBLADO,
	Clima.LLUVIA,
	Clima.NIEBLA,
	Clima.NIEVE,
]


func _init() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if argumentos.size() > 0
		else OS.get_user_data_dir().path_join("capturas-clima-797")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	var dia = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame

	# La entrada laboral tapa la escena durante el día 1. Para esta herramienta
	# se salta: lo que se compara es exactamente el mismo punto del trayecto.
	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame

	for estado in ESTADOS:
		dia.jornada["clima_forzado"] = estado
		dia._entrar_en("trayecto")
		# `_entrar_en` ya usa la entrada/mirada del catálogo. Se repite aquí para
		# neutralizar cualquier pequeño desplazamiento de física entre capturas.
		var entrada: Vector3 = dia._espacio_actual["entrada"]
		var mirada = dia._espacio_actual.get("mirada", NAN)
		dia._caminante.situar(entrada, mirada)

		# Da tiempo a controllers, partículas y renderer. #883 aumenta la densidad
		# y añade viento/acumulaciones, así que se estabiliza un poco más que #797.
		for i in 48:
			await process_frame

		var destino := salida.path_join("%s.png" % estado)
		var imagen := root.get_texture().get_image()
		var error_png := imagen.save_png(destino)
		if error_png != OK:
			printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
			quit(1)
			return
		print("clima %s -> %s" % [estado, destino])

	quit(0)
