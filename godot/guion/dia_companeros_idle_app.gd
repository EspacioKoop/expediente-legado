## Controller hijo para presencia ambiental de compañeros (#134).
extends Node

var _mundo_id := 0
var _idles: Array[CompaneroIdle3D] = []


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var id := mundo.get_instance_id()
	if id == _mundo_id:
		return
	_mundo_id = id
	_limpiar()
	if String(dia.jornada.get("fase", "")) != "archivo":
		return
	_montar(mundo)


func _exit_tree() -> void:
	_limpiar()


func _montar(mundo: Node3D) -> void:
	var preferencias := PreferenciasSiga.cargar()
	var reducir := bool(preferencias.get("reduccion_movimiento", false))
	var sitios: Array = EspaciosCatalogo.OFICINA.get("sitios_companeros", [])
	for indice in sitios.size():
		var cuerpo := _cuerpo_en(mundo, sitios[indice])
		if cuerpo == null:
			continue
		var idle := CompaneroIdle3D.new()
		idle.name = "IdleCompanero%d" % (indice + 1)
		add_child(idle)
		var semilla := hash("companero-%d" % indice)
		var telefono := indice == 0
		# El del teléfono conserva su gesto propio. Entre el resto solo la mitad
		# alterna actividad para evitar una oficina sincronizada artificialmente.
		var trabajo := indice > 0 and indice % 2 == 1
		idle.configurar(cuerpo, semilla, telefono, trabajo, reducir)
		_idles.append(idle)


func _cuerpo_en(mundo: Node3D, posicion: Vector3) -> Node3D:
	for hijo in mundo.get_children():
		if not hijo is Node3D:
			continue
		var nodo := hijo as Node3D
		if nodo.position.distance_to(posicion) < 0.02 and Modelos._esqueleto(nodo) != null:
			return nodo
	return null


func _limpiar() -> void:
	for idle in _idles:
		if is_instance_valid(idle):
			idle.queue_free()
	_idles.clear()
