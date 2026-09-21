## Wiring runtime de SARNATH 98 (#932).
##
## Observa el handshake desde la Portátil Color 98 y registra exposición
## cultural en el contrato común. No interpreta el recorrido como práctica.
extends Node

var _registro: Dictionary = ReligionEventos.nuevo()
var _mundo_id := 0
var _observador: Sarnath98Vigilia = null


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_mundo_id = mundo_id
		_observador = null

	if String(dia.jornada.get("fase", "")) == "casa" and _observador == null:
		_montar_observador(mundo, dia.jornada)


func registro() -> Dictionary:
	return _registro


func _montar_observador(mundo: Node3D, jornada: Dictionary) -> void:
	var existente := mundo.get_node_or_null("Sarnath98VigiliaCasa") as Sarnath98Vigilia
	if existente != null:
		_observador = existente
		return
	var consola := mundo.get_node_or_null("ConsolaPortatil98") as ConsolaPortatil98
	if consola == null:
		return
	_observador = Sarnath98Vigilia.new()
	_observador.name = "Sarnath98VigiliaCasa"
	mundo.add_child(_observador)
	_observador.configurar(_registro, jornada, consola)
