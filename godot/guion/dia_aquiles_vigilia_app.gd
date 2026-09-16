## Wiring del corte de vigilia de Aquiles (#438) al recorrido real.
##
## Este controller hijo observa el mundo que ya monta Dia y añade la estampa
## únicamente en casa. También conecta MYRMIDON 98 a la misma Jornada mediante
## un observer externo: la consola sigue siendo genérica y la ROM solo activa
## Aquiles al alcanzar su estado real de victoria.
extends Node

const POSICION_ESTAMPA := Vector3(-2.6, 1.35, -3.2)

var _mundo_montado_id := 0
var _rom_observador_mundo_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	if String(dia.jornada.get("fase", "")) != "casa":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_montado_id:
		_mundo_montado_id = mundo_id
		_montar_estampa(mundo, dia.jornada)

	# CasaUtileria puede montar la consola después de este controller dentro del
	# mismo frame. Reintentamos de forma barata hasta encontrarla, y después no
	# volvemos a consultar durante este mundo.
	if mundo_id != _rom_observador_mundo_id:
		if _montar_observador_rom(mundo, dia.jornada):
			_rom_observador_mundo_id = mundo_id


func _montar_estampa(mundo: Node3D, jornada: Dictionary) -> void:
	if mundo.get_node_or_null("AquilesVigiliaCasa") != null:
		return
	var estampa := AquilesVigilia.new()
	estampa.name = "AquilesVigiliaCasa"
	estampa.position = POSICION_ESTAMPA
	mundo.add_child(estampa)
	estampa.configurar(jornada)


func _montar_observador_rom(mundo: Node3D, jornada: Dictionary) -> bool:
	if mundo.get_node_or_null("Aquiles98VigiliaCasa") != null:
		return true
	var consola := mundo.get_node_or_null("ConsolaPortatil98") as ConsolaPortatil98
	if consola == null:
		return false
	var observador := Aquiles98Vigilia.new()
	observador.name = "Aquiles98VigiliaCasa"
	mundo.add_child(observador)
	observador.configurar(jornada, consola)
	return true
