## Integra las ROMs literarias con la casa real (#1179).
##
## Lee el registro del autoload, desbloquea IDs en la consola genérica y monta
## observers externos. Ni la consola ni el emulador conocen LiteraturaEventos.
extends Node

var _mundo_id := 0
var _observador: Sueno98Vigilia = null


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia.get("_mundo") == null:
		return
	if String(dia.jornada.get("fase", "")) != "casa":
		return

	var mundo: Node3D = dia._mundo
	_actualizar_mundo(mundo)

	var consola := mundo.get_node_or_null("ConsolaPortatil98") as ConsolaPortatil98
	if consola == null:
		return
	var gestor := get_node_or_null("/root/GestorLiteratura")
	if gestor == null or not gestor.has_method("obtener_registro_literario"):
		return

	var registro_variante = gestor.call("obtener_registro_literario")
	if typeof(registro_variante) != TYPE_DICTIONARY:
		return
	_sincronizar_roms(
		gestor,
		dia.jornada,
		mundo,
		consola,
		registro_variante,
	)


func _actualizar_mundo(mundo: Node3D) -> void:
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_id:
		return
	_mundo_id = mundo_id
	_observador = null


func _sincronizar_roms(
	gestor: Node,
	jornada: Dictionary,
	mundo: Node3D,
	consola: ConsolaPortatil98,
	registro: Dictionary,
) -> void:
	var desbloqueadas := LiteraturaRoms.desbloqueadas(registro)
	for id_rom in desbloqueadas:
		consola.desbloquear_rom(String(id_rom))

	if not desbloqueadas.has(Sueno98Vigilia.ID_ROM) or is_instance_valid(_observador):
		return

	var existente := mundo.get_node_or_null("Sueno98VigiliaCasa") as Sueno98Vigilia
	if existente != null:
		_observador = existente
		return

	_observador = Sueno98Vigilia.new()
	_observador.name = "Sueno98VigiliaCasa"
	mundo.add_child(_observador)
	_observador.configurar(gestor, jornada, consola)
