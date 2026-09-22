## Wiring del pasaporte de inspección para la escena Dia (#154).
##
## Está preparado como controller hijo de Dia: espera a que cada vertical monte
## sus anclas, añade un Area3D EXAMINAR sin modificar la geometría original y
## registra únicamente hechos derivados de Partida. No concede recompensas ni
## necesita coordenadas duplicadas en el catálogo del pasaporte.
class_name DiaPasaporteInspeccionApp
extends Node

const RADIO_INTERACCION := 0.68

var _mundo_id := 0
var _montados := {}


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null:
		return
	var mundo = dia.get("_mundo")
	if not mundo is Node3D:
		return

	var mundo_id := mundo.get_instance_id()
	if mundo_id != _mundo_id:
		_mundo_id = mundo_id
		_montados.clear()
	_montar_pendientes(dia, mundo)


func _montar_pendientes(dia: Node, mundo: Node3D) -> void:
	var jornada = dia.get("jornada")
	if typeof(jornada) != TYPE_DICTIONARY:
		return
	var fase := String(jornada.get("fase", ""))
	var forma_actual := _forma_sueno_actual(jornada)
	for entrada in PasaporteInspeccion.catalogo():
		var punto_id := String(entrada.get("id", ""))
		if punto_id.is_empty() or _montados.has(punto_id):
			continue
		if String(entrada.get("zona", "")) != fase:
			continue

		var forma_requerida := String(entrada.get("forma", ""))
		if not forma_requerida.is_empty() and forma_requerida != forma_actual:
			continue

		var ancla := _resolver_ancla(mundo, entrada)
		if ancla == null:
			continue
		var punto := crear_punto(punto_id)
		ancla.add_child(punto)
		punto.observado.connect(_al_observar.bind(dia))
		_montados[punto_id] = true


func crear_punto(punto_id: String) -> PuntoInspeccion3D:
	var punto := PuntoInspeccion3D.new()
	punto.name = _nombre_nodo(punto_id)
	punto.collision_layer = 1
	punto.collision_mask = 0
	punto.configurar(punto_id)

	var colision := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = RADIO_INTERACCION
	colision.shape = esfera
	punto.add_child(colision)
	return punto


func _al_observar(punto_id: String, _actor: Node, dia: Node) -> void:
	if dia == null or not is_instance_valid(dia):
		return
	var partida_actual = dia.get("partida")
	if not partida_actual is Partida:
		return
	var registro := PasaporteInspeccion.registrar_observacion_contextual(
		partida_actual.estado, punto_id
	)
	if not bool(registro.get("cambio", false)):
		return
	if dia.has_method("_guardar_o_avisar"):
		dia.call("_guardar_o_avisar", "")


func _resolver_ancla(mundo: Node3D, entrada: Dictionary) -> Node3D:
	var tipo := String(entrada.get("ancla_tipo", "nodo"))
	var valor := String(entrada.get("ancla", ""))
	if valor.is_empty():
		return null
	match tipo:
		"nodo":
			return mundo.find_child(valor, true, false) as Node3D
		"nodo_prefijo":
			return _buscar_prefijo(mundo, valor)
		"bulto_rol":
			return _buscar_bulto_por_rol(mundo, String(entrada.get("zona", "")), valor)
		_:
			return null


func _buscar_prefijo(nodo: Node, prefijo: String) -> Node3D:
	for hijo in nodo.get_children():
		if hijo is Node3D and String(hijo.name).begins_with(prefijo):
			return hijo
		var encontrado := _buscar_prefijo(hijo, prefijo)
		if encontrado != null:
			return encontrado
	return null


func _buscar_bulto_por_rol(mundo: Node3D, zona: String, rol: String) -> Node3D:
	var espacio := EspaciosCatalogo.de_fase(zona)
	var posicion := Vector3.ZERO
	var encontrada := false
	for bulto in espacio.get("bultos", []):
		if String(bulto.get("rol", "")) != rol:
			continue
		var candidata = bulto.get("pos", null)
		if typeof(candidata) != TYPE_VECTOR3:
			return null
		posicion = candidata
		encontrada = true
		break
	if not encontrada:
		return null

	for hijo in mundo.get_children():
		if not hijo is StaticBody3D:
			continue
		var cuerpo := hijo as StaticBody3D
		if cuerpo.position.distance_squared_to(posicion) <= 0.0004:
			return cuerpo
	return null


func _forma_sueno_actual(jornada: Dictionary) -> String:
	if String(jornada.get("fase", "")) != "sueño":
		return ""
	var escenas: Array = jornada.get("sueno_escenas", [])
	if escenas.is_empty():
		return ""
	return String(escenas[0])


func _nombre_nodo(punto_id: String) -> String:
	return (
		"PasaporteInspeccion_"
		+ punto_id.replace(":", "_").replace("/", "_").replace(" ", "_").replace("-", "_")
	)
