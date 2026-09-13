extends SceneTree

const Almacenamiento := preload("res://guion/almacenamiento_casa_interactivo_3d.gd")

var _pasadas := 0
var _fallos := 0


func _initialize() -> void:
	var almacenamiento := Almacenamiento.new()
	root.add_child(almacenamiento)
	almacenamiento.configurar()

	_comprobar(not almacenamiento.esta_abierto(), "empieza cerrado")
	_comprobar(almacenamiento.texto_accion() == "Abrir cajón", "anuncia abrir")
	_comprobar(
		almacenamiento.get_node_or_null("CajonCasa") != null,
		"el cajón visible forma parte del objeto"
	)
	_comprobar(
		almacenamiento.get_node_or_null("CollisionShape3D") != null,
		"expone un volumen de interacción"
	)

	var posicion_cerrada := almacenamiento.posicion_cajon()
	_comprobar(almacenamiento.interactuar(root), "acepta la interacción semántica")
	_comprobar(almacenamiento.esta_abierto(), "abre tras interactuar")
	_comprobar(almacenamiento.texto_accion() == "Cerrar cajón", "actualiza el verbo")
	_comprobar(
		almacenamiento.posicion_cajon().z < posicion_cerrada.z,
		"el cajón se desplaza de forma visible"
	)

	_comprobar(almacenamiento.interactuar(root), "acepta cerrar")
	_comprobar(not almacenamiento.esta_abierto(), "vuelve a cerrado")
	_comprobar(almacenamiento.texto_accion() == "Abrir cajón", "restaura el prompt")
	_comprobar(
		almacenamiento.posicion_cajon().is_equal_approx(posicion_cerrada),
		"restaura la posición física"
	)

	almacenamiento.queue_free()
	print("%d pasadas, %d fallos" % [_pasadas, _fallos])
	quit(1 if _fallos else 0)


func _comprobar(condicion: bool, nombre: String) -> void:
	if condicion:
		_pasadas += 1
		return
	_fallos += 1
	push_error("FALLO AlmacenamientoCasa: " + nombre)
