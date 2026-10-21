## Corredor estable del Hotel de los Olvidados (#2487).
##
## Sin reloj, desplazamiento aleatorio ni estado persistente. El host conserva
## la responsabilidad sobre la visita y selecciona sus habitaciones.
extends Node3D

signal hotel_exited

@export var rooms: Array[NodePath] = []
@export var corridor_stable := true
@export_range(4.0, 30.0, 0.5) var corridor_length := 12.0
@export_range(2.0, 6.0, 0.5) var corridor_width := 3.0

var _exiting := false


func _ready() -> void:
	# Geometría y colisión del corredor nacen juntas, sin animaciones.
	if corridor_stable:
		_crear_corredor()
	for room_path in rooms:
		var room := get_node_or_null(room_path)
		if room == null:
			push_warning("Hotel: habitación sin resolver: %s" % room_path)
			continue
		if room.has_method("connect_to_hub"):
			room.call("connect_to_hub", self)
		if corridor_stable and room.has_method("set_static"):
			room.call("set_static", true)


func _crear_corredor() -> void:
	# Superficies sólidas: piso, dos muros laterales y remate trasero.
	var length := maxf(4.0, corridor_length)
	var width := maxf(2.0, corridor_width)
	_agregar_tramo("Suelo", Vector3(0, -0.10, 0), Vector3(width, 0.2, length))
	# Ambos laterales dejan huecos centrales para puertas conectadas.
	var hueco := minf(2.2, length * 0.4)
	var tramo := (length - hueco) * 0.5
	var distancia := (length + hueco) * 0.25
	for lado in [-1, 1]:
		for mitad in [-1, 1]:
			_agregar_tramo(
				"Muro_%d_%d" % [lado, mitad],
				Vector3(float(lado) * width * 0.5, 1.35, float(mitad) * distancia),
				Vector3(0.18, 2.7, tramo)
			)
	_agregar_tramo(
		"Fondo", Vector3(0, 1.35, -length * 0.5), Vector3(width, 2.7, 0.18)
	)


func _agregar_tramo(nombre: String, posicion: Vector3, tamano: Vector3) -> void:
	var solido := StaticBody3D.new()
	solido.name = nombre
	solido.position = posicion
	add_child(solido)

	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamano
	colision.shape = forma
	solido.add_child(colision)

	var aspecto := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	aspecto.mesh = malla
	solido.add_child(aspecto)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _exiting:
		get_viewport().set_input_as_handled()
		exit_hotel()


func exit_hotel() -> void:
	if _exiting:
		return
	_exiting = true
	hotel_exited.emit()
