## Controller de publicaciones físicas para el recorrido real (#674/#655).
##
## Archivo/casa mantienen los cuatro ejemplares encontrables de #674. En
## trayecto, #655 reutiliza este controller ya montado en dia.tscn para exponer
## una copia física de consulta del cuaderno Popol Wuj. Ninguna de estas capas
## decide la semilla: el cierre deliberado sigue perteneciendo a Publicaciones98.
extends Node

const Encontrables := preload("res://guion/publicaciones_encontrables_3d.gd")
const PopolTrayecto := preload("res://guion/popol_wuj_trayecto_3d.gd")

var _mundo_id := 0
var _firma := ""
var _visor_trayecto: VisorPublicacion


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return

	var mundo: Node3D = dia._mundo
	var fase := String(dia.jornada.get("fase", ""))
	if fase == "trayecto":
		_limpiar_si_toca(mundo)
		_montar_popol_wuj_trayecto(dia, mundo)
		return

	PopolTrayecto.limpiar(mundo)
	if fase not in ["archivo", "casa"]:
		_limpiar_si_toca(mundo)
		return

	var inventario = dia.partida.estado.get("inventario", {})
	if typeof(inventario) != TYPE_DICTIONARY:
		return
	Inventario.completar(inventario)

	var numero_dia := int(dia.jornada.get("dia", 1))
	if not Encontrables.listo_para_montar(mundo, fase, numero_dia, inventario):
		return

	var mundo_id := mundo.get_instance_id()
	var firma := Encontrables.firma(fase, numero_dia, inventario)
	if mundo_id == _mundo_id and firma == _firma:
		return

	_mundo_id = mundo_id
	_firma = firma
	var raiz := Encontrables.montar(mundo, fase, numero_dia, inventario)
	for nodo in raiz.get_children():
		if nodo is Recogible3D:
			nodo.recogido.connect(_al_recoger)


func _montar_popol_wuj_trayecto(dia: Node, mundo: Node3D) -> void:
	var lectura := PopolTrayecto.montar(mundo)
	if lectura == null:
		return
	if not lectura.activado.is_connected(_abrir_popol_wuj_trayecto):
		lectura.activado.connect(_abrir_popol_wuj_trayecto)
	_mundo_id = mundo.get_instance_id()
	_firma = "trayecto:%s" % PopolTrayecto.ITEM_ID


func _abrir_popol_wuj_trayecto(_actor: Node) -> void:
	var dia := get_parent()
	if dia == null or String(dia.jornada.get("fase", "")) != "trayecto":
		return
	var visor := _asegurar_visor_trayecto(dia)
	visor.abrir(dia.jornada, PopolTrayecto.ITEM_ID)


func _asegurar_visor_trayecto(dia: Node) -> VisorPublicacion:
	if is_instance_valid(_visor_trayecto):
		return _visor_trayecto
	_visor_trayecto = VisorPublicacion.new()
	_visor_trayecto.name = "VisorPublicacionTrayecto"
	dia.add_child(_visor_trayecto)
	_visor_trayecto.cerrada.connect(_guardar_lectura_trayecto)
	return _visor_trayecto


func _guardar_lectura_trayecto(_resultado: Dictionary) -> void:
	var dia := get_parent()
	if dia != null and dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")


func _limpiar_si_toca(mundo: Node3D) -> void:
	if mundo.get_node_or_null(Encontrables.NOMBRE_RAIZ) != null:
		Encontrables.limpiar(mundo)
	_mundo_id = mundo.get_instance_id()
	_firma = ""


func _al_recoger(_objeto: Dictionary, _actor: Node) -> void:
	# La siguiente iteración cambiará la firma porque el ID ya está en Inventario,
	# evitando respawn. Guardamos por el mismo dueño que el resto del día.
	_firma = ""
	var dia := get_parent()
	if dia != null and dia.has_method("_guardar_o_avisar"):
		dia._guardar_o_avisar("")
