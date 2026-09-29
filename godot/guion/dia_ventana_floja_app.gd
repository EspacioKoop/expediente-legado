## Integra la ventana floja de #1773 en la oficina real.
##
## Lee el inventario persistente de Partida, pero la interacción solo consulta
## carried mediante UsosHerramienta. Calzar la ventana persiste durante la
## jornada; no consume objetos, no da recursos y no bloquea la salida principal.
extends Node

const CLAVE_JORNADA := "ventana_floja_estabilizada_1773"
const NOMBRE := "VentanaFloja1773"

var _mundo_id := 0
var _ventana: VentanaFlojaOficina1773


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia.get("_mundo") == null:
		_limpiar()
		return
	var mundo := dia.get("_mundo") as Node3D
	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_limpiar()
		_mundo_id = mundo_id

	if String(dia.jornada.get("fase", "")) != "archivo":
		_limpiar()
		_mundo_id = mundo_id
		return
	if is_instance_valid(_ventana):
		return
	_montar(dia, mundo)


func _exit_tree() -> void:
	_limpiar()


func _montar(dia: Node, mundo: Node3D) -> void:
	var ventanas: Array = EspaciosCatalogo.OFICINA.get("ventanas", [])
	if ventanas.is_empty():
		return
	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		return
	Inventario.completar(inventario)

	var declaracion: Dictionary = ventanas[0]
	var ventana := VentanaFlojaOficina1773.new()
	ventana.name = NOMBRE
	ventana.position = declaracion.get("pos", Vector3.ZERO)
	mundo.add_child(ventana)
	ventana.configurar(inventario, bool(dia.jornada.get(CLAVE_JORNADA, false)))
	ventana.falta_herramienta.connect(_al_faltar_herramienta.bind(dia))
	ventana.estabilizada.connect(_al_estabilizar.bind(dia))
	_ventana = ventana


func _al_faltar_herramienta(dia: Node) -> void:
	var nomina = dia.get("_nomina")
	if nomina is Label:
		(nomina as Label).text = tr("VENTANA_FLOJA_FALTA_CALZO")


func _al_estabilizar(_herramienta_id: String, herramienta_nombre: String, dia: Node) -> void:
	dia.jornada[CLAVE_JORNADA] = true
	var nomina = dia.get("_nomina")
	if nomina is Label:
		(nomina as Label).text = tr("VENTANA_FLOJA_ESTABILIZADA") % herramienta_nombre
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")


func _limpiar() -> void:
	if is_instance_valid(_ventana):
		_ventana.queue_free()
	_ventana = null
