## Conecta la vista 3D de la ventana de casa con el clima determinista del día.
##
## La casa no se convierte en `exterior`: únicamente la ventana consulta
## `Clima.estado(dia)`, preservando el contrato de #143 para el resto de la fase.
extends Node

var _mundo_id := -1
var _estado := ""


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var mundo: Node3D = dia._mundo
	if mundo == null or dia.fase != "casa":
		_mundo_id = -1
		_estado = ""
		return

	var ventana := mundo.get_node_or_null("VentanaCasa") as Node3D
	if ventana == null:
		return

	var estado_clima := Clima.estado(int(dia.jornada.get("dia", 1)))
	var mundo_id := mundo.get_instance_id()
	var exterior := ventana.get_node_or_null("Exterior3D") as VentanaExterior3D
	if exterior == null:
		exterior = VentanaExterior3D.new()
		exterior.name = "Exterior3D"
		ventana.add_child(exterior)

	if mundo_id != _mundo_id or estado_clima != _estado:
		_mundo_id = mundo_id
		_estado = estado_clima
		exterior.configurar(estado_clima)
