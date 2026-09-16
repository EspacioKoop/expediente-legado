## Controller hijo de #672 para `dia.tscn`.
##
## Sigue el patrón de otros verticales del día: observa el mundo que ya montó
## Dia y añade el buzón únicamente en `trayecto`. No modifica la máquina de
## estados ni crea una segunda pantalla obligatoria.
extends Node

const BuzonPostal := preload("res://guion/buzon_postal_interactivo_3d.gd")

var _mundo_id := 0
var _lector: CorreoPostalLector
var _mouse_previo := Input.MOUSE_MODE_CAPTURED


func _ready() -> void:
	# El lector pausa el árbol; este controller debe poder restaurarlo al cerrarse.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	var fase := String(dia.jornada.get("fase", ""))
	if fase != "trayecto":
		_mundo_id = mundo_id
		return
	if mundo_id == _mundo_id and mundo.get_node_or_null("BuzonPostal") != null:
		return

	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		return

	_mundo_id = mundo_id
	var buzon := BuzonPostal.new()
	buzon.name = "BuzonPostal"
	# A la derecha del marco del portal final declarado por dia_calle_app.gd.
	# No invade el hueco de paso ni añade una colisión física al caminante: es Area3D.
	buzon.position = Vector3(1.58, 1.12, 15.38)
	mundo.add_child(buzon)
	buzon.configurar(dia.jornada, inventario)
	buzon.correo_recogido.connect(_al_recoger_correo)
	buzon.buzon_vacio.connect(_al_buzon_vacio)


func _al_recoger_correo(resultado: Dictionary, _actor: Node) -> void:
	var dia := get_parent()
	if dia == null:
		return
	# La pieza ya está en Jornada/Inventario. Persistimos antes de abrir el lector
	# para que incluso cerrar el juego desde la lectura no duplique paquetes.
	if dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
	dia.set_meta("ultimo_correo_postal", resultado.duplicate(true))
	_abrir_resultado(resultado)


func _al_buzon_vacio(_actor: Node) -> void:
	if get_tree().paused:
		return
	var dia := get_parent()
	if dia == null:
		return
	_asegurar_lector(dia)
	_preparar_modal()
	_lector.abrir_vacio()


func _abrir_resultado(resultado: Dictionary) -> void:
	if get_tree().paused:
		return
	var dia := get_parent()
	if dia == null:
		return
	_asegurar_lector(dia)
	_preparar_modal()
	_lector.abrir(resultado.duplicate(true))


func _asegurar_lector(dia: Node) -> void:
	if is_instance_valid(_lector):
		return
	_lector = CorreoPostalLector.new()
	_lector.name = "CorreoPostalLector"
	_lector.cerrada.connect(_cerrar_lector)
	dia.add_child(_lector)


func _preparar_modal() -> void:
	_mouse_previo = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func _cerrar_lector() -> void:
	if not is_instance_valid(_lector) or not _lector.visible:
		return
	_lector.hide()
	get_tree().paused = false
	Input.mouse_mode = _mouse_previo
