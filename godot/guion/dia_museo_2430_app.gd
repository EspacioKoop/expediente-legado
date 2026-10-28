## Entrada opcional al museo de vidas no ocurridas (#2430).
##
## Sigue el patrón de los otros Dia*Controller: observa una sala ya elegida
## por Jornada, sin tocar la selección, el mapa, los documentos ni Partida.
extends Node

const GALERIA = preload("res://escenas/museo_vidas_no_ocurridas.tscn")
const DESPLAZAMIENTO_GALERIA := Vector3(400.0, 0.0, 0.0)

var _mundo_montado_id := 0
var _montado_esta_noche := false
var _fase_anterior := ""
var _galeria: SuenoMuseoEscena2430
var _portal_entrada: Interactuable3D
var _portal_salida: Interactuable3D
var _actor_dentro: Node3D
var _transform_regreso := Transform3D.IDENTITY


func _process(_delta: float) -> void:
	var dia := get_parent()
	if dia == null or dia._mundo == null:
		return
	var fase := String(dia.jornada.get("fase", ""))
	if fase != _fase_anterior:
		if fase != "sueño":
			_montado_esta_noche = false
			_actor_dentro = null
		_fase_anterior = fase
	if fase != "sueño":
		return

	var mundo: Node3D = dia._mundo
	var mundo_id := mundo.get_instance_id()
	if mundo_id == _mundo_montado_id:
		return
	_mundo_montado_id = mundo_id
	_actor_dentro = null
	if _montado_esta_noche or dia.jornada.get("leido_hoy", []).is_empty():
		return
	if dia.jornada.get("sueno_escenas", []).is_empty():
		return
	_montar(mundo, dia)
	_montado_esta_noche = true


func _montar(mundo: Node3D, dia: Node) -> void:
	if mundo.get_node_or_null("GaleriaVidasNoOcurridas") != null:
		return
	var contexto := {
		"dia": int(dia.jornada.get("dia", 1)),
		"vuelta": int(dia.jornada.get("vuelta", 1)),
		"companeros": Companeros.plantilla(int(dia.jornada.get("plantilla", 0))),
	}
	var galeria := GALERIA.instantiate() as SuenoMuseoEscena2430
	if galeria == null:
		return
	galeria.name = "GaleriaVidasNoOcurridas"
	galeria.position = DESPLAZAMIENTO_GALERIA
	# La semilla existente determina el contenido. No se guarda otra tirada.
	galeria.configurar(contexto, int(dia.jornada.get("raiz", 0)))
	mundo.add_child(galeria)
	_galeria = galeria

	var entrada: Vector3 = dia._espacio_actual.get("entrada", Vector3.ZERO)
	_portal_entrada = _crear_umbral(
		mundo,
		"UmbralMuseo",
		entrada + Vector3(0.0, 1.0, -2.3),
		"archivo de vidas no ocurridas",
	)
	_portal_entrada.activado.connect(_entrar)

	_portal_salida = _crear_umbral(
		galeria,
		"SalidaMuseo",
		Vector3(0.0, 1.0, 6.0),
		"al sueño",
	)
	_portal_salida.habilitado = false
	_portal_salida.activado.connect(_salir)
	_anadir_cartel(_portal_entrada, "VIDAS QUE NO OCURRIERON")
	_anadir_cartel(_portal_salida, "REGRESAR AL SUEÑO")


func _crear_umbral(
	padre: Node3D, nombre: String, posicion: Vector3, descripcion: String
) -> Interactuable3D:
	var zona := Interactuable3D.new()
	zona.name = nombre
	zona.verbo = Interactuable3D.Verbo.EXAMINAR
	zona.nombre_objeto = descripcion
	zona.sonido = Interactuable3D.SIN_SONIDO
	zona.position = posicion
	var colision := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(1.7, 2.1, 1.0)
	colision.shape = caja
	zona.add_child(colision)
	padre.add_child(zona)
	return zona


func _anadir_cartel(umbral: Node3D, titulo: String) -> void:
	var cartel := Label3D.new()
	cartel.name = "Inscripcion"
	cartel.text = titulo
	cartel.font_size = 30
	cartel.pixel_size = 0.004
	cartel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cartel.position = Vector3(0.0, 1.5, 0.0)
	umbral.add_child(cartel)


func _entrar(actor: Node) -> void:
	if _actor_dentro != null or _galeria == null or not is_instance_valid(_galeria):
		return
	var cuerpo := actor as Node3D
	if cuerpo == null:
		return
	_actor_dentro = cuerpo
	_transform_regreso = cuerpo.global_transform
	_portal_entrada.habilitado = false
	_portal_salida.habilitado = true
	cuerpo.global_position = _galeria.to_global(Vector3(0.0, 0.1, 4.5))


func _salir(_actor: Node) -> void:
	if _actor_dentro == null:
		return
	if is_instance_valid(_actor_dentro):
		_actor_dentro.global_transform = _transform_regreso
	_actor_dentro = null
	_portal_entrada.habilitado = true
	_portal_salida.habilitado = false
