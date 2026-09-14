extends SceneTree

const ESCENA_CINEMATICA := preload("res://escenas/cinematica.tscn")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	call_deferred("_probar")


func _probar() -> void:
	var reproductor = ESCENA_CINEMATICA.instantiate()
	root.add_child(reproductor)
	await process_frame

	var terminadas := [0]
	reproductor.terminada.connect(func(): terminadas[0] += 1)
	var rodaje := [
		{
			"tipo": "2d",
			"segundos": 10.0,
			"figura": [],
			"rotulo": "Prueba",
			"voz": "",
		}
	]

	reproductor.reproducir(rodaje)
	_comprobar(reproductor._reproduciendo, "la cinemática empieza reproduciéndose")

	var movimiento := InputEventAction.new()
	movimiento.action = "ui_left"
	movimiento.pressed = true
	reproductor._unhandled_input(movimiento)
	_comprobar(reproductor._reproduciendo, "movimiento no salta la cinemática")
	_comprobar(terminadas[0] == 0, "movimiento no emite terminada")

	var aceptar := InputEventAction.new()
	aceptar.action = "ui_accept"
	aceptar.pressed = true
	reproductor._unhandled_input(aceptar)
	_comprobar(not reproductor._reproduciendo, "aceptar salta la cinemática")
	_comprobar(terminadas[0] == 1, "aceptar emite terminada una vez")

	reproductor.reproducir(rodaje)
	var soltar := InputEventAction.new()
	soltar.action = "ui_cancel"
	soltar.pressed = false
	reproductor._unhandled_input(soltar)
	_comprobar(reproductor._reproduciendo, "soltar una acción no salta la cinemática")

	reproductor.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, mensaje: String) -> void:
	if condicion:
		_pasadas += 1
	else:
		_fallos += 1
		push_error(mensaje)
