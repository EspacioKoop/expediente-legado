## Controller hijo para presencia ambiental de compañeros (#134).
##
## También reparte los recados de oficina (#400): de vez en cuando, uno de los
## compañeros sentados se levanta y va al archivador o a la máquina de café por
## la malla de navegación del espacio. Nunca hay dos recados a la vez, el turno
## y el destino rotan sin azar y con reducción de movimiento no hay ninguno.
extends Node

## `CompaneroInteractivo3D` flota esta altura sobre los pies de su cuerpo.
const ALTURA_CONVERSABLE := 0.9
## Una oficina tranquila: el primer recado tarda en llegar y los siguientes se
## espacian lo bastante como para que levantarse siga siendo un acontecimiento.
const PRIMER_RECADO := 20.0
const INTERVALO_RECADO := 45.0
## Distancia a la que se para delante de un mueble, además de su media anchura.
const HOLGURA_DESTINO := 0.55
const MAQUINA_CAFE := "MaquinaCafeInteractuable"
const TAM_MAQUINA_CAFE := 0.7

var _mundo_id := 0
var _idles: Array[CompaneroIdle3D] = []
var _conversando: CompaneroIdle3D
var _conversables := {}
var _navegacion: NavigationRegion3D
var _reloj_recados := 0.0
var _proximo_recado := PRIMER_RECADO
var _recados_hechos := 0
var _reducir := false


func _process(delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var mundo: Node3D = dia._mundo
	var id := mundo.get_instance_id()
	if id == _mundo_id:
		_vigilar_conversacion(dia)
		_seguir_recados(mundo, delta)
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
	_reducir = reducir
	var sitios: Array = EspaciosCatalogo.OFICINA.get("sitios_companeros", [])
	var dia := get_parent()
	var actor: Node3D = dia.get("_caminante") as Node3D if dia != null else null
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
		# Solo una figura no telefónica reacciona al paso del jugador. Elegir la
		# última posición mantiene el gesto estable aunque crezca el roster.
		var atencion := indice > 0 and indice == sitios.size() - 1
		idle.configurar(
			cuerpo, semilla, telefono, reducir, trabajo, brazos, en_silla, atencion, actor
		)
		_idles.append(idle)
	_conectar_conversaciones(mundo)
	_reloj_recados = 0.0
	_proximo_recado = PRIMER_RECADO
	if not reducir:
		_navegacion = NavegacionOficina.montar(mundo)


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
				_conversables[idle] = hijo
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


## Lanza el siguiente recado cuando toca y mantiene el volumen conversable
## encima del cuerpo que anda: hablar con alguien es hablar donde está.
func _seguir_recados(mundo: Node3D, delta: float) -> void:
	for idle in _conversables:
		if not is_instance_valid(idle) or not is_instance_valid(_conversables[idle]):
			continue
		var base: Vector3 = idle.objetivo.position if idle.en_recado() else idle.sitio()
		_conversables[idle].position = (
			Vector3(base.x, idle.sitio().y, base.z) + Vector3.UP * ALTURA_CONVERSABLE
		)
	if _reducir or _hay_recado():
		return
	_reloj_recados += delta
	if _reloj_recados < _proximo_recado:
		return
	_reloj_recados = 0.0
	_proximo_recado = INTERVALO_RECADO
	lanzar_recado(mundo)


## Manda al siguiente compañero sentado a por el siguiente destino. Público
## para las pruebas; en partida lo llama el reloj de recados.
func lanzar_recado(mundo: Node3D) -> RecadoCompanero3D:
	if _hay_recado() or not is_instance_valid(_navegacion):
		return null
	var candidatos: Array[CompaneroIdle3D] = []
	for idle in _idles:
		if is_instance_valid(idle) and idle.sentado and not idle.esta_conversando():
			candidatos.append(idle)
	var destinos := destinos_recado(mundo)
	if candidatos.is_empty() or destinos.is_empty():
		return null
	var idle := candidatos[_recados_hechos % candidatos.size()]
	var destino: Dictionary = destinos[_recados_hechos % destinos.size()]
	_recados_hechos += 1
	var ruta := NavegacionOficina.ruta(_navegacion, idle.sitio(), destino["pie"])
	var recado := RecadoCompanero3D.new()
	recado.name = "Recado"
	idle.add_child(recado)
	if not recado.iniciar(idle, ruta, destino["mirar"]):
		recado.free()
		return null
	return recado


## Dónde se puede ir: cada archivador del catálogo y la máquina de café. El
## punto de llegada queda delante del mueble, hacia el centro de la sala.
static func destinos_recado(mundo: Node3D) -> Array:
	var destinos := []
	var cafe := mundo.get_node_or_null(MAQUINA_CAFE) as Node3D
	for bulto in EspaciosCatalogo.OFICINA.get("bultos", []):
		if String(bulto.get("modelo", "")) != "bookcaseClosed":
			continue
		destinos.append(_destino(bulto["pos"], bulto["tam"]))
		if cafe != null:
			destinos.append(_destino(cafe.position, Vector3.ONE * TAM_MAQUINA_CAFE))
	return destinos


static func _destino(pos: Vector3, tam: Vector3) -> Dictionary:
	var suelo := Vector3(pos.x, 0.0, pos.z)
	var pie := suelo
	if absf(pos.x) >= absf(pos.z):
		pie.x -= signf(pos.x) * (tam.x * 0.5 + HOLGURA_DESTINO)
	else:
		pie.z -= signf(pos.z) * (tam.z * 0.5 + HOLGURA_DESTINO)
	return {"pie": pie, "mirar": suelo}


func _hay_recado() -> bool:
	for idle in _idles:
		if is_instance_valid(idle) and idle.en_recado():
			return true
	return false


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
	_conversables.clear()
	_navegacion = null
	for idle in _idles:
		if is_instance_valid(idle):
			idle.queue_free()
	_idles.clear()
