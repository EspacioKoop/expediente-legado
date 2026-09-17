## Controller hijo de #677 para el recorrido real de `dia.tscn`.
##
## Sigue el patrón de dressing: observa el mundo ya montado por Dia y no toma
## decisiones de jornada. Solo en casa deriva el estado ambiental oficial,
## refresca home_storage y conecta publicaciones físicas con su visor existente.
extends Node

const CasaAcumulacion := preload("res://guion/casa_acumulacion_3d.gd")
const CasaEstadoAmbientalScript := preload("res://guion/casa_estado_ambiental.gd")

var _mundo_id := 0
var _firma := ""
var _visor: VisorPublicacion


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	var fase := String(dia.jornada.get("fase", ""))
	if fase != "casa":
		_mundo_id = mundo_id
		_firma = ""
		return

	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		inventario = {}
	var estado := CasaEstadoAmbientalScript.derivar(dia.jornada, inventario)
	var firma := CasaAcumulacion.firma(estado)
	if mundo_id == _mundo_id and firma == _firma:
		return

	_mundo_id = mundo_id
	_firma = firma
	var acumulacion := CasaAcumulacion.montar(mundo, estado)
	_conectar_publicaciones(acumulacion)


func _conectar_publicaciones(acumulacion: Node3D) -> void:
	if acumulacion == null:
		return
	for nodo in acumulacion.get_children():
		if not nodo is Interactuable3D:
			continue
		var publicacion_id := String(nodo.get_meta("publicacion_id", ""))
		if publicacion_id.is_empty():
			continue
		nodo.activado.connect(_abrir_publicacion.bind(publicacion_id))


func _abrir_publicacion(_actor: Node, publicacion_id: String) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var visor := _asegurar_visor(dia)
	visor.abrir(dia.jornada, publicacion_id)


func _asegurar_visor(dia: Node) -> VisorPublicacion:
	if is_instance_valid(_visor):
		return _visor
	_visor = VisorPublicacion.new()
	_visor.name = "VisorPublicacionCasa"
	dia.add_child(_visor)
	_visor.cerrada.connect(_guardar_lectura)
	return _visor


func _guardar_lectura(_resultado: Dictionary) -> void:
	var dia := get_parent()
	if dia != null and dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
