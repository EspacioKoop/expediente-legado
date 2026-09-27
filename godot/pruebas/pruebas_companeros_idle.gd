extends SceneTree

const Idle := preload("res://guion/companero_idle_3d.gd")

var _pasadas := 0
var _fallos := 0


## Restaurar escala y giro ocurre en `_exit_tree`, que no llega a correr si el
## idle se libera durante `_initialize`: la raíz todavía no está en el árbol.
## Por eso las comprobaciones esperan al primer fotograma.
func _initialize() -> void:
	process_frame.connect(_ejecutar, CONNECT_ONE_SHOT)


func _ejecutar() -> void:
	_probar_movimiento()
	_probar_atencion_selectiva()
	_probar_modificador_cabeza()
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


func _probar_atencion_selectiva() -> void:
	var escenario := Node3D.new()
	root.add_child(escenario)
	var cuerpo := Node3D.new()
	escenario.add_child(cuerpo)
	var actor := Node3D.new()
	actor.position = Vector3(1.0, 0.0, -2.0)
	escenario.add_child(actor)
	var idle := Idle.new()
	root.add_child(idle)
	idle.configurar(cuerpo, 134, false, false, false, false, false, true, actor)
	idle._process(0.2)
	_comprobar(
		not is_zero_approx(cuerpo.rotation.y), "una figura seleccionada reacciona al paso frontal"
	)
	_comprobar(
		absf(cuerpo.rotation.y) <= Idle.GIRO_ATENCION_MAX + 0.001,
		"la atención nunca supera el giro corporal permitido"
	)
	actor.position = Vector3(0.0, 0.0, 2.0)
	idle._process(0.5)
	_comprobar(
		is_zero_approx(cuerpo.rotation.y), "al quedar detrás recupera suavemente su orientación"
	)
	idle.free()
	escenario.free()


func _probar_modificador_cabeza() -> void:
	var esqueleto := Skeleton3D.new()
	root.add_child(esqueleto)
	esqueleto.add_bone("Neck")
	esqueleto.add_bone("Head")
	esqueleto.set_bone_parent(1, 0)
	var modificador := AtencionCabeza3D.new()
	esqueleto.add_child(modificador)
	modificador.giro = deg_to_rad(12.0)
	modificador._process_modification()
	_comprobar(
		esqueleto.get_bone_pose_rotation(0).get_angle() > 0.001,
		"la atención añade giro al cuello después de la animación",
	)
	_comprobar(
		esqueleto.get_bone_pose_rotation(1).get_angle() > 0.001,
		"la atención añade giro a la cabeza después de la animación",
	)
	esqueleto.free()


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
