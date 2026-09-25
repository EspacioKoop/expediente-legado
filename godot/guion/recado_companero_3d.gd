## Un recado de oficina (#400): levantarse, ir, coger algo, volver y sentarse.
##
## Solo mueve el cuerpo visual del compañero que ya está sentado: no tiene
## colisión, no toca estado de juego ni reserva el camino frente al jugador.
## `CompaneroIdle3D` pausa su rutina mientras dura y la retoma al terminar, con
## el cuerpo otra vez en la misma postura sentada en la que empezó.
class_name RecadoCompanero3D
extends Node

signal terminado(recado: RecadoCompanero3D)

enum Fase {
	LEVANTARSE,
	IR,
	GESTO,
	VOLVER,
	SENTARSE,
	HECHO,
}

## Paso de oficina, no de prisa: el clip `Walk_Formal` es un andar pausado.
const VELOCIDAD := 0.9
const GIRO := 7.0
const LLEGADA := 0.05

var fase := Fase.LEVANTARSE
var idle: CompaneroIdle3D
var _cuerpo: Node3D
var _ida := PackedVector3Array()
var _vuelta := PackedVector3Array()
var _indice := 0
var _reloj := 0.0
var _duracion := 0.0
var _mirar_a := Vector3.ZERO
var _pausado := false
var _postura_sentada := Transform3D.IDENTITY
var _altura := 0.0


## Prepara el recado sobre una ruta ya calculada entre el sitio del compañero y
## su destino. Devuelve falso si no hay ruta o el compañero no está sentado.
func iniciar(companero: CompaneroIdle3D, ruta: PackedVector3Array, mirar_a: Vector3) -> bool:
	if not is_instance_valid(companero) or not companero.sentado or ruta.size() < 2:
		return false
	idle = companero
	_cuerpo = companero.objetivo
	_altura = companero.sitio().y
	_postura_sentada = _cuerpo.transform
	_mirar_a = mirar_a
	for punto in ruta:
		_ida.append(Vector3(punto.x, _altura, punto.z))
	_vuelta = _ida.duplicate()
	_vuelta.reverse()
	_vuelta[_vuelta.size() - 1] = companero.sitio()
	idle.empezar_recado(self)
	_entrar(Fase.LEVANTARSE)
	return true


func pausar(pausa: bool) -> void:
	if pausa == _pausado or fase == Fase.HECHO:
		return
	_pausado = pausa
	if not pausa:
		_reproducir_fase()


func esta_pausado() -> bool:
	return _pausado


## La huida de #209 manda: deja el cuerpo donde esté y no vuelve a sentarlo.
func cancelar() -> void:
	fase = Fase.HECHO
	queue_free()


func _process(delta: float) -> void:
	if not is_instance_valid(_cuerpo):
		queue_free()
		return
	if _pausado or fase == Fase.HECHO:
		return
	_reloj += delta
	match fase:
		Fase.LEVANTARSE:
			var t := _progreso()
			_cuerpo.position = _postura_sentada.origin.lerp(idle.sitio(), t)
			if t >= 1.0:
				_entrar(Fase.IR)
		Fase.IR:
			if _andar(_ida, delta):
				_entrar(Fase.GESTO)
		Fase.GESTO:
			_girar_hacia(_mirar_a - _cuerpo.position, delta)
			if _progreso() >= 1.0:
				_entrar(Fase.VOLVER)
		Fase.VOLVER:
			if _andar(_vuelta, delta):
				_cuerpo.rotation.y = _postura_sentada.basis.get_euler().y
				_entrar(Fase.SENTARSE)
		Fase.SENTARSE:
			var t := _progreso()
			_cuerpo.position = idle.sitio().lerp(_postura_sentada.origin, t)
			if t >= 1.0:
				_terminar()


func _entrar(nueva: int) -> void:
	fase = nueva
	_reloj = 0.0
	_indice = 1
	match fase:
		Fase.LEVANTARSE:
			_duracion = AnimacionesUAL.duracion("levantarse", _cuerpo)
		Fase.SENTARSE:
			_duracion = AnimacionesUAL.duracion("sentarse", _cuerpo)
		Fase.GESTO:
			_duracion = AnimacionesUAL.duracion("coger", _cuerpo)
		_:
			_duracion = 0.0
	_reproducir_fase()


func _reproducir_fase() -> void:
	var clip := ""
	match fase:
		Fase.LEVANTARSE:
			clip = "levantarse"
		Fase.IR:
			clip = "andar"
		Fase.GESTO:
			clip = "coger"
		Fase.VOLVER:
			clip = "andar_cargando"
		Fase.SENTARSE:
			clip = "sentarse"
	if clip.is_empty():
		return
	var desfase := clampf(_reloj / _duracion, 0.0, 1.0) if _duracion > 0.0 else 0.0
	AnimacionesUAL.reproducir(_cuerpo, clip, desfase)


## Avanza por [param ruta]; verdadero al llegar al último punto.
func _andar(ruta: PackedVector3Array, delta: float) -> bool:
	var paso := VELOCIDAD * delta
	while _indice < ruta.size():
		var destino := ruta[_indice]
		var hacia := destino - _cuerpo.position
		hacia.y = 0.0
		var distancia := hacia.length()
		if distancia <= LLEGADA:
			_indice += 1
			continue
		_girar_hacia(hacia, delta)
		if distancia <= paso:
			_cuerpo.position = destino
			paso -= distancia
			_indice += 1
			continue
		_cuerpo.position += hacia / distancia * paso
		return false
	return true


## `persona.fbx` mira hacia su +Z local.
func _girar_hacia(direccion: Vector3, delta: float) -> void:
	direccion.y = 0.0
	if direccion.length_squared() < 0.0001:
		return
	var objetivo := atan2(direccion.x, direccion.z)
	_cuerpo.rotation.y = lerp_angle(_cuerpo.rotation.y, objetivo, clampf(GIRO * delta, 0.0, 1.0))


func _progreso() -> float:
	return 1.0 if _duracion <= 0.0 else clampf(_reloj / _duracion, 0.0, 1.0)


func _terminar() -> void:
	fase = Fase.HECHO
	_cuerpo.transform = _postura_sentada
	if is_instance_valid(idle):
		idle.terminar_recado(self)
	terminado.emit(self)
	queue_free()
