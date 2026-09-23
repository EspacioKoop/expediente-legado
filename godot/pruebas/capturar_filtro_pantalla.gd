## Capturas A/B del filtro de pantalla (#1270) en GPU real.
##
## Entra en archivo y trayecto con la cámara jugable y el HUD visible —el HUD
## es justo lo que tiene que salir igual— y guarda una captura por preajuste.
## Sin casa: al entrar desde aquí se abre la interfaz de la portátil, que no es
## lo que se compara y enseña rutas locales del equipo que captura.
## No toca las preferencias guardadas: aplica los preajustes en memoria. El
## coste se mide aparte, en `medir_filtro_pantalla.gd`. Uso:
## env DISPLAY=:0 godot4 --path godot --script res://pruebas/capturar_filtro_pantalla.gd
extends SceneTree

const SALIDA := "res://../docs/evidencias/filtro-pantalla/"
const FASES := ["archivo", "trayecto"]


func _initialize() -> void:
	call_deferred("_capturar")


func _capturar() -> void:
	TranslationServer.set_locale("es")
	root.size = Vector2i(1280, 720)
	var dia: Node = load("res://escenas/dia.tscn").instantiate()
	root.add_child(dia)
	await process_frame
	if dia._entrada != null:
		dia._entrada.saltar()
		await process_frame

	for fase in FASES:
		dia._entrar_en(fase)
		await create_timer(1.5).timeout
		# La escena se queda quieta para que las cuatro capturas sean el mismo
		# cuadro salvo por el filtro.
		dia.set_process(false)
		for id in FiltroPantalla.ids():
			FiltroPantalla.refrescar(self, {"filtro_pantalla": id})
			await create_timer(0.4).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg(
				ProjectSettings.globalize_path(SALIDA + "%s-%s.jpg" % [fase, id]), 0.9
			)
		dia.set_process(true)
	quit(0)
