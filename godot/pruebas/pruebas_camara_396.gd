## Regresión runtime de la cámara libre (#396).
##
## El caso reproduce la condición que escapaba a la cobertura estática: una GUI
## capaz de consumir MouseMotion convive con el caminante. El backend headless
## no puede capturar un puntero real, así que el contrato separa los guardas de
## entrada de la aplicación del delta y prueba ambas piezas sin fingir hardware.
extends SceneTree

const CAMINANTE_ESCENA := preload("res://escenas/caminante.tscn")
const CAMINANTE_SCRIPT := preload("res://guion/caminante.gd")


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
	var yaw_inicial := caminante.rotation.y
	var pitch_inicial := camara.rotation.x
	var movimiento := InputEventMouseMotion.new()
	movimiento.relative = Vector2(120.0, -48.0)
	movimiento.position = Vector2(512.0, 340.0)

	_comprobar(
		CAMINANTE_SCRIPT.debe_procesar_movimiento_raton(
			true, true, false, false
		),
		"captura activa permite MouseMotion de gameplay",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_procesar_movimiento_raton(
			false, true, false, false
		),
		"ratón visible bloquea MouseMotion de gameplay",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_procesar_movimiento_raton(
			true, false, false, false
		),
		"física inactiva bloquea MouseMotion de gameplay",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_procesar_movimiento_raton(
			true, true, true, false
		),
		"árbol pausado bloquea MouseMotion de gameplay",
	)
	_comprobar(
		not CAMINANTE_SCRIPT.debe_procesar_movimiento_raton(
			true, true, false, true
		),
		"cámara de diálogo bloquea MouseMotion de gameplay",
	)

	# La aplicación del delta es independiente del backend de ventana. En juego
	# _input la invoca antes de que una GUI pueda consumir el mismo MouseMotion.
	caminante.call("_aplicar_movimiento_raton", movimiento)
	consumidor.call("_gui_input", movimiento)
	_comprobar(consumidor.movimientos == 1, "la GUI consume MouseMotion después")
	_comprobar(
		not is_equal_approx(caminante.rotation.y, yaw_inicial),
		"el delta cambia yaw",
	)
	_comprobar(
		not is_equal_approx(camara.rotation.x, pitch_inicial),
		"el delta cambia pitch",
	)

	var extremo := InputEventMouseMotion.new()
	extremo.relative = Vector2(0.0, -100000.0)
	caminante.call("_aplicar_movimiento_raton", extremo)
	_comprobar(
		camara.rotation.x <= deg_to_rad(85.0) + 0.0001,
		"el pitch conserva el límite superior",
	)
	extremo.relative = Vector2(0.0, 100000.0)
	caminante.call("_aplicar_movimiento_raton", extremo)
	_comprobar(
		camara.rotation.x >= -deg_to_rad(85.0) - 0.0001,
		"el pitch conserva el límite inferior",
	)

	root.remove_child(consumidor)
	consumidor.free()
	root.remove_child(caminante)
	caminante.free()
	for _frame in 2:
		await process_frame

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
