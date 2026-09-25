## Contrato del lenguaje de cine de las cinemáticas (#395): formato, franjas,
## óptica y cámara en mano, con y sin reducción de movimiento, y su efecto real
## en el reproductor común.
extends SceneTree

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	_probar_formato()
	_probar_franjas()
	_probar_optica()
	_probar_mano()
	await _probar_reproductor()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_formato() -> void:
	var alto := LenguajeCine.alto_franja(Vector2(1920, 1080))
	var imagen := 1080.0 - 2.0 * alto
	_comprobar(
		absf(1920.0 / imagen - LenguajeCine.RELACION_PANORAMICA) < 0.01, "1080p queda en 2,39:1"
	)
	_comprobar(
		LenguajeCine.alto_franja(Vector2(2560, 1000)) == 0.0,
		"una pantalla ya panorámica no lleva franjas"
	)
	_comprobar(LenguajeCine.alto_franja(Vector2.ZERO) == 0.0, "sin tamaño no hay franjas")


func _probar_franjas() -> void:
	_comprobar(
		LenguajeCine.apertura_franjas(0.0, 10.0, false) == 0.0, "las franjas entran desde fuera"
	)
	_comprobar(LenguajeCine.apertura_franjas(5.0, 5.0, false) == 1.0, "a mitad están puestas")
	_comprobar(LenguajeCine.apertura_franjas(9.9, 0.0, false) == 0.0, "al acabar han salido")
	var media := LenguajeCine.apertura_franjas(LenguajeCine.SEGUNDOS_FRANJAS / 2.0, 10.0, false)
	_comprobar(media > 0.0 and media < 1.0, "entran de forma gradual")
	_comprobar(
		LenguajeCine.apertura_franjas(0.0, 0.0, true) == 1.0,
		"con reducción de movimiento no se animan"
	)


func _probar_optica() -> void:
	_comprobar(LenguajeCine.fov_de({}) == LenguajeCine.FOV, "sin fov, la óptica de cine")
	_comprobar(LenguajeCine.fov_de({"fov": 30.0}) == 30.0, "un plano puede cerrar la focal")
	_comprobar(LenguajeCine.fov_de({"fov": 500.0}) <= 90.0, "la focal se acota")
	var foco := LenguajeCine.foco_de({}, Vector3.ZERO, Vector3(0, 0, -3))
	_comprobar(is_equal_approx(foco, 3.0), "el foco cae en lo que mira la cámara")
	_comprobar(
		LenguajeCine.foco_de({"foco": 1.2}, Vector3.ZERO, Vector3(0, 0, -3)) == 1.2,
		"un plano puede fijar el foco"
	)
	var atributos := LenguajeCine.atributos(3.0)
	_comprobar(
		atributos.dof_blur_far_enabled and atributos.dof_blur_far_distance > 3.0,
		"el fondo se desenfoca detrás del sujeto"
	)


func _probar_mano() -> void:
	var maximo := 0.0
	for i in 600:
		var d := LenguajeCine.mano(float(i) / 30.0, false)
		maximo = maxf(maximo, d.length())
	_comprobar(maximo > 0.0 and maximo < 0.03, "la mano mueve menos de 3 cm (%.3f)" % maximo)
	var una := LenguajeCine.mano(1.7, false)
	var otra := LenguajeCine.mano(1.7, false)
	_comprobar(una.is_equal_approx(otra) and una != Vector3.ZERO, "la mano es determinista")
	_comprobar(
		LenguajeCine.mano(1.7, true) == Vector3.ZERO, "con reducción de movimiento no hay mano"
	)


func _probar_reproductor() -> void:
	# Headless abre una ventana de 64 px: se mide a la resolución de referencia.
	root.size = Vector2i(1920, 1080)
	var escena: Node3D = load("res://guion/cinematica_app.gd").new()
	root.add_child(escena)
	await process_frame
	var plano := {"tipo": "3d", "segundos": 2.0, "camara": Vector3(0, 1.6, 3), "mira": Vector3.ZERO}
	escena.reproducir([plano, plano.duplicate()])
	await process_frame
	escena._process(1.0)
	_comprobar(
		escena._franja_inferior.size.y > 100.0, "las franjas están puestas a mitad de la secuencia"
	)
	_comprobar(
		is_equal_approx(escena._camara.fov, LenguajeCine.FOV),
		"la cámara rueda con la focal de cine"
	)
	_comprobar(
		escena._camara.attributes is CameraAttributesPractical,
		"la cámara lleva profundidad de campo"
	)
	_comprobar(escena._grano.visible, "el grano está sobre la imagen")
	_comprobar(
		escena._voz.offset_top > -LenguajeCine.alto_franja(escena._lienzo.size) - 1.0,
		"la voz va dentro de la franja, como un subtítulo"
	)
	escena.saltar()
	_comprobar(escena._franja_inferior.size.y == 0.0, "al saltar las franjas desaparecen")
	_comprobar(not escena._grano.visible, "y el grano también")
	escena.queue_free()
	await process_frame


func _comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)
