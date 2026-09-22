## Evidencia visual reproducible del navegador Web98 para #794.
##
## Ejecutar con renderer real:
##   xvfb-run -a godot4 --path godot --rendering-method gl_compatibility \
##     --script res://pruebas/capturar_web98_794.gd -- /tmp/web98-794
##
## Captura el control real NavegadorSiga, no una maqueta paralela.
extends SceneTree

const TAM := Vector2i(1024, 720)
const CONTEXTO := {"dia": 1, "conocimiento": [], "urls_caidas": []}


func _initialize() -> void:
	_ejecutar.call_deferred()


func _ejecutar() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var salida := (
		String(argumentos[0])
		if not argumentos.is_empty()
		else OS.get_user_data_dir().path_join("evidencia-web98-794")
	)
	if not salida.is_absolute_path():
		salida = ProjectSettings.globalize_path("res://").path_join(salida)
	var error_dir := DirAccess.make_dir_recursive_absolute(salida)
	if error_dir != OK:
		printerr("No se pudo crear %s (error %d)" % [salida, error_dir])
		quit(1)
		return

	root.size = TAM
	var fondo := ColorRect.new()
	fondo.color = Color("2f343a")
	root.add_child(fondo)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var navegador := NavegadorSiga.new()
	navegador.configurar_contexto(CONTEXTO)
	root.add_child(navegador)
	navegador.position = Vector2(24, 24)
	navegador.size = Vector2(TAM.x - 48, TAM.y - 48)
	await _estabilizar()

	navegador.navegar("http://byte.local/")
	if not await _guardar(salida.path_join("byte-local.png")):
		quit(1)
		return

	navegador._mostrar_busqueda("coño")
	if not await _guardar(salida.path_join("busqueda-sin-falso-positivo.png")):
		quit(1)
		return

	navegador.navegar("http://usuarios.red98/~becario/")
	if not await _guardar(salida.path_join("pagina-personal.png")):
		quit(1)
		return

	print("Evidencia Web98 #794 -> %s" % salida)
	quit(0)


func _estabilizar() -> void:
	for _i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw


func _guardar(destino: String) -> bool:
	await _estabilizar()
	var imagen := root.get_texture().get_image()
	if imagen == null or imagen.is_empty():
		printerr("Captura vacía: %s" % destino)
		return false
	var error_png := imagen.save_png(destino)
	if error_png != OK:
		printerr("No se pudo guardar %s (error %d)" % [destino, error_png])
		return false
	return true
