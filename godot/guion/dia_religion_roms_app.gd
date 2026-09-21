## Controller común de las ROMs culturales/religiosas (#932).
##
## Mantiene UN único ReligionEventos para JALI 98, VITRAL 98 y SARNATH 98.
## Los observers siguen siendo independientes y la Portátil Color 98 permanece
## genérica. Añadir otra ROM cultural debe ampliar este controller, no crear un
## registro paralelo.
extends Node

var _registro: Dictionary = ReligionEventos.nuevo()
var _mundo_id := 0
var _recuerdo_jali_mundo_id := 0
var _observadores: Dictionary = {}


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_mundo_id = mundo_id
		_recuerdo_jali_mundo_id = 0
		_observadores.clear()

	var fase := String(dia.jornada.get("fase", ""))
	if fase == "casa":
		_montar_observadores(mundo, dia.jornada)

	_actualizar_recuerdo_jali(mundo, fase, mundo_id)


func registro() -> Dictionary:
	return _registro


func observadores_montados() -> Array:
	return _observadores.keys()


func _montar_observadores(mundo: Node3D, jornada: Dictionary) -> void:
	var consola := mundo.get_node_or_null("ConsolaPortatil98") as ConsolaPortatil98
	if consola == null:
		return
	_montar_jali(mundo, jornada, consola)
	_montar_vitral(mundo, jornada, consola)
	_montar_sarnath(mundo, jornada, consola)


func _montar_jali(mundo: Node3D, jornada: Dictionary, consola: ConsolaPortatil98) -> void:
	if _observadores.has(Jali98Vigilia.ID_ROM):
		return
	var observador := mundo.get_node_or_null("Jali98VigiliaCasa") as Jali98Vigilia
	if observador == null:
		observador = Jali98Vigilia.new()
		observador.name = "Jali98VigiliaCasa"
		mundo.add_child(observador)
		observador.configurar(_registro, jornada, consola)
	_observadores[Jali98Vigilia.ID_ROM] = observador


func _montar_vitral(mundo: Node3D, jornada: Dictionary, consola: ConsolaPortatil98) -> void:
	if _observadores.has(Vitral98Vigilia.ID_ROM):
		return
	var observador := mundo.get_node_or_null("Vitral98VigiliaCasa") as Vitral98Vigilia
	if observador == null:
		observador = Vitral98Vigilia.new()
		observador.name = "Vitral98VigiliaCasa"
		mundo.add_child(observador)
		observador.configurar(_registro, jornada, consola)
	_observadores[Vitral98Vigilia.ID_ROM] = observador


func _montar_sarnath(mundo: Node3D, jornada: Dictionary, consola: ConsolaPortatil98) -> void:
	if _observadores.has(Sarnath98Vigilia.ID_ROM):
		return
	var observador := mundo.get_node_or_null("Sarnath98VigiliaCasa") as Sarnath98Vigilia
	if observador == null:
		observador = Sarnath98Vigilia.new()
		observador.name = "Sarnath98VigiliaCasa"
		mundo.add_child(observador)
		observador.configurar(_registro, jornada, consola)
	_observadores[Sarnath98Vigilia.ID_ROM] = observador


func _actualizar_recuerdo_jali(mundo: Node3D, fase: String, mundo_id: int) -> void:
	var recuerdo := ReligionRecuerdoJali932.recuerdo_para_sueno(_registro)
	if recuerdo.is_empty():
		return
	mundo.set_meta("recuerdo_cultural_jali_98", recuerdo)
	if fase != "sueño" or mundo_id == _recuerdo_jali_mundo_id:
		return
	var firma := ReligionRecuerdoJali9323D.montar(mundo, recuerdo)
	if firma != null:
		_recuerdo_jali_mundo_id = mundo_id
