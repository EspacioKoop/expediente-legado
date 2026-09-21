## Wiring runtime del primer vertical de ROM religiosa/cultural (#932).
##
## Mantiene el registro en este controller de Dia y monta un observer externo
## junto a la Portátil Color 98. La ROM y la consola permanecen genéricas.
extends Node

var _registro: Dictionary = ReligionEventos.nuevo()
var _mundo_id := 0
var _observador: Jali98Vigilia = null


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

	var recuerdo := ReligionRecuerdoJali932.recuerdo_para_sueno(_registro)
	if not recuerdo.is_empty():
		mundo.set_meta("recuerdo_cultural_jali_98", recuerdo)


func registro() -> Dictionary:
	return _registro


func _montar_observador(mundo: Node3D, jornada: Dictionary) -> void:
	var existente := mundo.get_node_or_null("Jali98VigiliaCasa") as Jali98Vigilia
	if existente != null:
		_observador = existente
		return
	var consola := mundo.get_node_or_null("ConsolaPortatil98") as ConsolaPortatil98
	if consola == null:
		return
	_observador = Jali98Vigilia.new()
	_observador.name = "Jali98VigiliaCasa"
	mundo.add_child(_observador)
	_observador.configurar(_registro, jornada, consola)
