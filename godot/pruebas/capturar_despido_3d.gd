## Capturas del despido 3D (#899) en GPU real: cada plano al empezar y al
## terminar su travelling, y la mañana sin gato. Uso:
## env DISPLAY=:0 godot4 --path godot --script res://pruebas/capturar_despido_3d.gd
extends SceneTree

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")
const SALIDA := "res://../docs/evidencias/despido-3d/"


func _initialize() -> void:
	call_deferred("_capturar")


func _capturar() -> void:
	TranslationServer.set_locale("es")
	root.size = Vector2i(1280, 720)
	var reproductor: Node = ESCENA_CINEMATICA.instantiate()
	root.add_child(reproductor)
	var tomas := [
		["con-gato", DespidoCinematica.planos_de(true, 0, Cunado.clave_despido(1))],
		["sin-gato", DespidoCinematica.planos_de(false)],
	]
	for toma in tomas:
		var rodaje: Array = toma[1]
		for i in rodaje.size():
			if toma[0] == "sin-gato" and i < 2:
				continue
			var plano: Dictionary = rodaje[i].duplicate(true)
			plano["segundos"] = 999.0
			reproductor.reproducir([plano])
			for avance in [0.0, 1.0]:
				reproductor._mover_camara(plano, avance)
				await create_timer(0.8).timeout
				reproductor._mover_camara(plano, avance)
				await process_frame
				var imagen := root.get_texture().get_image()
				imagen.save_jpg(
					ProjectSettings.globalize_path(
						SALIDA + "%s-%d-%s-%s.jpg" % [toma[0], i, plano["nombre"], int(avance)]
					),
					0.85
				)
			reproductor.saltar()
	quit(0)
