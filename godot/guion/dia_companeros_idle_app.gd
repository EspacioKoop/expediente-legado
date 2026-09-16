## Controller hijo para presencia ambiental de compañeros (#134).
extends Node

## `CompaneroInteractivo3D` flota esta altura sobre los pies de su cuerpo.
const ALTURA_CONVERSABLE := 0.9

var _mundo_id := 0
var _idles: Array[CompaneroIdle3D] = []
var _conversando: CompaneroIdle3D


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var id := mundo.get_instance_id()
	if id == _mundo_id:
		_vigilar_conversacion(dia)
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
		# Quien no trabaja ni está al teléfono se cruza de brazos a ratos.
		var brazos := indice > 0 and not trabajo
		# Quien trabaja lo hace sentado en su puesto; el cuñado y quien espera
		# con los brazos cruzados siguen de pie.
		var en_silla := trabajo
		idle.configurar(cuerpo, semilla, telefono, reducir, trabajo, brazos, en_silla)
		_idles.append(idle)
	_conectar_conversaciones(mundo)


## El diálogo lo abre `dia_clima_app.gd`; aquí solo se enlaza cada volumen
## conversable con el cuerpo que tiene debajo para que gesticule al hablar.
func _conectar_conversaciones(mundo: Node3D) -> void:
	for hijo in mundo.get_children():
		if not hijo is CompaneroInteractivo3D:
			continue
		var pies: Vector3 = hijo.position - Vector3(0.0, ALTURA_CONVERSABLE, 0.0)
		for idle in _idles:
			# `sitio()` y no la posición actual: sentarse sube y acerca el cuerpo.
			if idle.sitio().distance_to(pies) < 0.05:
				hijo.conversacion_solicitada.connect(_al_conversar.bind(idle))
				break


func _al_conversar(
	_companero: CompaneroInteractivo3D, _actor: Node, _clave: String, idle: CompaneroIdle3D
) -> void:
	if is_instance_valid(_conversando) and _conversando != idle:
		_conversando.conversar(false)
	_conversando = idle
	idle.conversar(true)


## La conversación dura lo que dure el diálogo diegético. Se comprueba un
## fotograma después de pedirla: si no llegó a abrirse, el gesto se retira.
func _vigilar_conversacion(dia: Node) -> void:
	if not is_instance_valid(_conversando):
		return
	if is_instance_valid(dia.get("_dialogo_actual")):
		return
	_conversando.conversar(false)
	_conversando = null


## Reacción colectiva consumida por el incidente de pared (#209). Este
## controller conoce qué cuerpos son compañeros; el incidente no necesita
## buscar modelos ni duplicar la lógica de montaje de la plantilla.
func huir_de(origen_global: Vector3) -> void:
	for idle in _idles:
		if is_instance_valid(idle):
			idle.huir_de(origen_global)


func _cuerpo_en(mundo: Node3D, posicion: Vector3) -> Node3D:
	for hijo in mundo.get_children():
		if not hijo is Node3D:
			continue
		var nodo := hijo as Node3D
		if nodo.position.distance_to(posicion) < 0.02 and Modelos._esqueleto(nodo) != null:
			return nodo
	return null


func _limpiar() -> void:
	_conversando = null
	for idle in _idles:
		if is_instance_valid(idle):
			idle.queue_free()
	_idles.clear()
