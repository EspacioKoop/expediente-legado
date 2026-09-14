extends SceneTree

const Idle := preload("res://guion/companero_idle_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	_probar_movimiento()
	_probar_reduccion()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _probar_movimiento() -> void:
	var cuerpo := Node3D.new()
	root.add_child(cuerpo)
	var idle := Idle.new()
	root.add_child(idle)
	idle.configurar(cuerpo, 134, true, false)
	var escala := cuerpo.scale
	var giro := cuerpo.rotation.y
	idle._process(0.5)
	_comprobar(
		not cuerpo.scale.is_equal_approx(escala), "la respiración altera solo la escala visual"
	)
	_comprobar(
		not is_equal_approx(cuerpo.rotation.y, giro),
		"el gesto contextual mueve suavemente el cuerpo"
	)
	idle.free()
	_comprobar(cuerpo.scale.is_equal_approx(escala), "al retirar el idle restaura la escala")
	_comprobar(is_equal_approx(cuerpo.rotation.y, giro), "al retirar el idle restaura el giro")
	cuerpo.free()


func _probar_reduccion() -> void:
	var cuerpo := Node3D.new()
	root.add_child(cuerpo)
	var idle := Idle.new()
	root.add_child(idle)
	idle.configurar(cuerpo, 42, true, true)
	var escala := cuerpo.scale
	var giro := cuerpo.rotation.y
	idle._process(1.0)
	_comprobar(cuerpo.scale.is_equal_approx(escala), "reducción de movimiento congela respiración")
	_comprobar(is_equal_approx(cuerpo.rotation.y, giro), "reducción de movimiento congela gesto")
	idle.free()
	cuerpo.free()


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO CompanerosIdle: " + nombre)
