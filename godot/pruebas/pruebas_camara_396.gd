## Regresión runtime de la cámara libre (#396).
##
## El caso reproduce la condición que escapaba a la cobertura estática: una GUI
## capaz de consumir MouseMotion convive con el caminante. La cámara debe girar
## en _input antes de que esa GUI procese el mismo evento.
extends SceneTree

const CAMINANTE_ESCENA := preload("res://escenas/caminante.tscn")


class ConsumidorMouse:
	extends Control
	var movimientos := 0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _gui_input(evento: InputEvent) -> void:
		if evento is InputEventMouseMotion:
			movimientos += 1
			accept_event()


var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _probar() -> void:
	var caminante := CAMINANTE_ESCENA.instantiate() as CharacterBody3D
	root.add_child(caminante)
	var consumidor := ConsumidorMouse.new()
	root.add_child(consumidor)
	await process_frame

	var camara := caminante.get_node("Camara") as Camera3D
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await process_frame

	var yaw_inicial := caminante.rotation.y
	var pitch_inicial := camara.rotation.x
	var movimiento := InputEventMouseMotion.new()
	movimiento.relative = Vector2(120.0, -48.0)
	movimiento.position = Vector2(512.0, 340.0)

	# Orden real de Godot: _input precede a _gui_input. La GUI acepta después el
	# evento para demostrar que consumirlo no puede deshacer el giro ya aplicado.
	caminante.call("_input", movimiento)
	consumidor.call("_gui_input", movimiento)

	_comprobar(consumidor.movimientos == 1, "la GUI consume MouseMotion")
	_comprobar(
		not is_equal_approx(caminante.rotation.y, yaw_inicial),
		"MouseMotion cambia yaw antes de la GUI",
	)
	_comprobar(
		not is_equal_approx(camara.rotation.x, pitch_inicial),
		"MouseMotion cambia pitch antes de la GUI",
	)

	var yaw_tras_giro := caminante.rotation.y
	caminante.set_physics_process(false)
	caminante.call("_input", movimiento)
	_comprobar(
		is_equal_approx(caminante.rotation.y, yaw_tras_giro),
		"una pantalla que desactiva la física bloquea el giro",
	)
	caminante.set_physics_process(true)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	caminante.call("_input", movimiento)
	_comprobar(
		is_equal_approx(caminante.rotation.y, yaw_tras_giro),
		"ratón visible no mueve la cámara de gameplay",
	)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var extremo := InputEventMouseMotion.new()
	extremo.relative = Vector2(0.0, -100000.0)
	caminante.call("_input", extremo)
	_comprobar(
		camara.rotation.x <= deg_to_rad(85.0) + 0.0001,
		"el pitch conserva el límite superior",
	)
	extremo.relative = Vector2(0.0, 100000.0)
	caminante.call("_input", extremo)
	_comprobar(
		camara.rotation.x >= -deg_to_rad(85.0) - 0.0001,
		"el pitch conserva el límite inferior",
	)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	root.remove_child(consumidor)
	consumidor.free()
	root.remove_child(caminante)
	caminante.free()

	if _fallos == 0:
		print("Camara #396 runtime: OK (%d comprobaciones)" % _pasadas)
		quit(0)
		return
	push_error("Camara #396 runtime: %d fallos" % _fallos)
	quit(1)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO Camara #396: " + nombre)
