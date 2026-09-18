## Controller hijo de #675/#93 para las decisiones domésticas físicas.
##
## Mantiene las microinteracciones de rutina y añade la comida propia sobre la
## cocina real. La regla económica sigue viviendo exclusivamente en Jornada.
extends Node

const CasaEstadoAmbientalScript := preload("res://guion/casa_estado_ambiental.gd")
const CasaRutinas3DScript := preload("res://guion/casa_rutinas_3d.gd")

var _mundo_id := 0


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	var fase := String(dia.jornada.get("fase", ""))
	if fase != "casa":
		_mundo_id = mundo_id
		return
	if mundo_id == _mundo_id and mundo.get_node_or_null(CasaRutinas3DScript.NOMBRE_RAIZ) != null:
		return

	# CasaUtileria se monta desde la capa principal del día; si todavía no han
	# aparecido sus anclajes, esperamos al siguiente frame sin crear una casa paralela.
	if mundo.find_child("VentanaCasa", true, false) == null:
		return

	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		inventario = {}
	var estado := CasaEstadoAmbientalScript.derivar(dia.jornada, inventario)
	var reduccion := bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))
	CasaRutinas3DScript.montar(mundo, dia.jornada, estado, reduccion)
	_montar_comida_propia(dia, mundo)
	_mundo_id = mundo_id


func _montar_comida_propia(dia, mundo: Node3D) -> void:
	var cocina := mundo.find_child("CocinaCasa", true, false) as Node3D
	if cocina == null:
		return
	var comida := ComidaPropiaInteractiva3D.new()
	comida.name = "ComidaPropiaInteractuable"
	comida.position = Vector3(-0.10, 1.03, -0.48)
	cocina.add_child(comida)
	comida.configurar(Jornada.PRECIO_COMIDA_PROPIA)
	if int(dia.jornada.get("comida_propia", {}).get("dias_sin_comer", 0)) <= 0:
		comida.marcar_saciado()
	comida.activado.connect(_al_comer.bind(dia, comida))


func _al_comer(_actor: Node, dia, comida: ComidaPropiaInteractiva3D) -> void:
	if String(dia.jornada.get("fase", "")) != "casa" or not comida.disponible():
		return
	if int(dia.jornada.get("comida_propia", {}).get("dias_sin_comer", 0)) <= 0:
		comida.marcar_saciado()
		return
	if not Jornada.comer(dia.jornada, Jornada.PRECIO_COMIDA_PROPIA):
		comida.marcar_sin_dinero()
		return
	comida.consumir()
	if dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
