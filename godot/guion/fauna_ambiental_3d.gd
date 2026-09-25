## Montaje de la fauna declarada por FaunaAmbiental (#1396).
class_name FaunaAmbiental3D
extends Node3D

var _animales: Array[AnimalAmbiental3D] = []


func montar(
	fase: String,
	espacio: Dictionary,
	dia: int,
	raiz: int,
	contexto: String,
	animador: AnimadorAmbiental3D,
	reduccion_movimiento: bool = false,
) -> Array[AnimalAmbiental3D]:
	_limpiar()
	var plan := FaunaAmbiental.plan(fase, espacio, dia, raiz, contexto)
	for dato in plan:
		var animal := AnimalAmbiental3D.new()
		animal.name = _nombre_nodo(String(dato.get("especie", "animal")), _animales.size())
		add_child(animal)
		animal.configurar(dato, animador, reduccion_movimiento)
		_animales.append(animal)
		if animador != null:
			animador.registrar(animal.id_fauna(), animal, animal.global_position, 1)
	return _animales.duplicate()


func animales() -> Array[AnimalAmbiental3D]:
	return _animales.duplicate()


func especies() -> Array[String]:
	var resultado: Array[String] = []
	for animal in _animales:
		var id := animal.especie()
		if not resultado.has(id):
			resultado.append(id)
	return resultado


func _limpiar() -> void:
	for animal in _animales:
		if animal != null and is_instance_valid(animal):
			animal.queue_free()
	_animales.clear()


func _nombre_nodo(especie: String, indice: int) -> String:
	var limpio := especie.capitalize().replace(" ", "")
	return "%s%02d" % [limpio, indice + 1]
