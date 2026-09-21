## Controller de presentacion para vecinos/portal (#673).
##
## Observa la Jornada y el mundo ya montado por Dia. Solo añade una capa
## ambiental en trayecto y persiste la unica interaccion no dialogada.
extends Node

const Presentacion := preload("res://guion/vecinos_edificio_3d.gd")

var _firma := ""
var _raiz: Node3D
var _reduccion_movimiento := false


func _ready() -> void:
	_reduccion_movimiento = bool(PreferenciasSiga.cargar().get("reduccion_movimiento", false))


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	if String(dia.jornada.get("fase", "")) != "trayecto":
		_firma = ""
		_limpiar()
		return

	var firma := _firma_estado(dia, mundo)
	if firma == _firma and is_instance_valid(_raiz):
		return

	_limpiar()
	_raiz = Presentacion.montar(mundo, dia.jornada, _reduccion_movimiento)
	_firma = firma
	_conectar_paquete()


func _conectar_paquete() -> void:
	if not is_instance_valid(_raiz):
		return
	var paquete := _raiz.get_node_or_null("PaqueteEquivocado")
	if paquete == null or not paquete is Interactuable3D:
		return
	if not paquete.activado.is_connected(_resolver_paquete):
		paquete.activado.connect(_resolver_paquete)


func _resolver_paquete(_actor: Node) -> void:
	var dia := get_parent()
	if dia == null or not is_instance_valid(_raiz):
		return

	var resultado := VecinosEdificio.resolver_interaccion(
		dia.jornada, VecinosEdificio.ID_PAQUETE_EQUIVOCADO
	)
	if not bool(resultado.get("ok", false)):
		return

	Presentacion.marcar_paquete_resuelto(_raiz)
	dia.set_meta("ultimo_vecino_edificio", resultado.duplicate(true))
	if dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
	if dia._mundo != null:
		_firma = _firma_estado(dia, dia._mundo)


func _firma_estado(dia: Node, mundo: Node3D) -> String:
	return (
		"%d:%d:%s:%s"
		% [
			mundo.get_instance_id(),
			int(dia.jornada.get("dia", 1)),
			JSON.stringify(dia.jornada.get(VecinosEdificio.CLAVE_RESUELTOS, [])),
			"reducido" if _reduccion_movimiento else "normal",
		]
	)


func _limpiar() -> void:
	if is_instance_valid(_raiz):
		_raiz.free()
	_raiz = null
