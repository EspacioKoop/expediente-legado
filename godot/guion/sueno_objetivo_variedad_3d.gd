## Variantes físicas reutilizables para objetivos oníricos (#299).
##
## Esta capa no conoce Partida, Jornada ni recompensas. Recibe un actor y
## posiciones ya decididas por la escena, y emite un único evento cuando se
## cumple la condición física. Así el contrato de SuenoObjetivos sigue siendo
## la única autoridad de progreso.
class_name SuenoObjetivoVariedad3D
extends Node3D

signal completado(objetivo_id: String)
signal rumbo_cambiado(posicion: Vector3)

const TIPO_RECORRIDO := SuenoObjetivosVariedad.TIPO_RECORRIDO
const TIPO_SECUENCIA := SuenoObjetivosVariedad.TIPO_SECUENCIA
const TIPO_PERMANENCIA := SuenoObjetivosVariedad.TIPO_PERMANENCIA
const TIPO_RETORNO := SuenoObjetivosVariedad.TIPO_RETORNO

const RADIO_ZONA := 1.2
const RANGO_LUZ := 2.8
const ENERGIA_LUZ_BASE := 0.16
const ENERGIA_LUZ_ACTIVA := 0.52
const TIEMPO_PERMANENCIA := 1.15

var _objetivo_id := ""
var _tipo := ""
var _actor: Node3D
var _puntos: Array[Vector3] = []
var _zonas: Array[Area3D] = []
var _luces: Array[OmniLight3D] = []
var _indice_secuencia := 0
var _dentro_permanencia := false
var _tiempo_permanencia := 0.0
var _terminado := false


func configurar(objetivo_id: String, tipo: String, actor: Node3D, puntos: Array) -> bool:
	_objetivo_id = objetivo_id.strip_edges()
	_tipo = tipo
	_actor = actor
	_puntos.clear()
	for punto in puntos:
		if punto is Vector3:
			_puntos.append(punto)

	if (
		_objetivo_id.is_empty()
		or _actor == null
		or not is_instance_valid(_actor)
		or _puntos.is_empty()
		or _tipo not in [TIPO_SECUENCIA, TIPO_PERMANENCIA, TIPO_RETORNO]
	):
		return false

	for indice in _puntos.size():
		_crear_zona(indice, _puntos[indice])
	_actualizar_luces()
	set_physics_process(_tipo == TIPO_PERMANENCIA)
	return true


func punto_actual() -> Vector3:
	if _puntos.is_empty():
		return global_position
	if _tipo in [TIPO_SECUENCIA, TIPO_RETORNO]:
		return _puntos[mini(_indice_secuencia, _puntos.size() - 1)]
	return _puntos[0]


func terminado() -> bool:
	return _terminado


func _physics_process(delta: float) -> void:
	if _terminado or _tipo != TIPO_PERMANENCIA or not _dentro_permanencia:
		return
	_tiempo_permanencia = minf(_tiempo_permanencia + delta, TIEMPO_PERMANENCIA)
	if not _luces.is_empty() and is_instance_valid(_luces[0]):
		var proporcion := _tiempo_permanencia / TIEMPO_PERMANENCIA
		_luces[0].light_energy = lerpf(ENERGIA_LUZ_BASE, ENERGIA_LUZ_ACTIVA, proporcion)
	if _tiempo_permanencia >= TIEMPO_PERMANENCIA:
		_completar()


func _crear_zona(indice: int, punto: Vector3) -> void:
	var zona := Area3D.new()
	zona.name = "VariedadSueno_%s_%d" % [_objetivo_id, indice]
	zona.position = punto
	zona.collision_layer = 0
	zona.collision_mask = 1
	zona.set_meta("paso", indice)

	var colision := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = RADIO_ZONA
	colision.shape = esfera
	zona.add_child(colision)

	var luz := OmniLight3D.new()
	luz.name = "EcoVariedad"
	luz.omni_range = RANGO_LUZ
	luz.light_energy = ENERGIA_LUZ_BASE
	luz.shadow_enabled = false
	zona.add_child(luz)

	add_child(zona)
	zona.body_entered.connect(_al_entrar.bind(indice))
	zona.body_exited.connect(_al_salir.bind(indice))
	_zonas.append(zona)
	_luces.append(luz)


func _al_entrar(cuerpo: Node3D, indice: int) -> void:
	if _terminado or cuerpo != _actor:
		return
	if _tipo in [TIPO_SECUENCIA, TIPO_RETORNO]:
		if indice != _indice_secuencia:
			return
		_indice_secuencia += 1
		if _indice_secuencia >= _puntos.size():
			_completar()
			return
		_actualizar_luces()
		rumbo_cambiado.emit(_puntos[_indice_secuencia])
		return
	if _tipo == TIPO_PERMANENCIA and indice == 0:
		_dentro_permanencia = true


func _al_salir(cuerpo: Node3D, indice: int) -> void:
	if _terminado or cuerpo != _actor:
		return
	if _tipo != TIPO_PERMANENCIA or indice != 0:
		return
	_dentro_permanencia = false
	_tiempo_permanencia = 0.0
	_actualizar_luces()


func _actualizar_luces() -> void:
	for indice in _luces.size():
		var luz := _luces[indice]
		var zona := _zonas[indice]
		if not is_instance_valid(luz) or not is_instance_valid(zona):
			continue
		if _tipo in [TIPO_SECUENCIA, TIPO_RETORNO]:
			var activa := indice == _indice_secuencia
			luz.visible = activa
			luz.light_energy = ENERGIA_LUZ_ACTIVA if activa else 0.0
			zona.set_deferred("monitoring", activa)
		else:
			luz.visible = indice == 0
			luz.light_energy = ENERGIA_LUZ_BASE
			zona.set_deferred("monitoring", indice == 0)


func _completar() -> void:
	if _terminado:
		return
	_terminado = true
	_dentro_permanencia = false
	set_physics_process(false)
	for zona in _zonas:
		if is_instance_valid(zona):
			zona.set_deferred("monitoring", false)
	for luz in _luces:
		if is_instance_valid(luz):
			luz.visible = true
			luz.light_energy = ENERGIA_LUZ_ACTIVA
	completado.emit(_objetivo_id)
