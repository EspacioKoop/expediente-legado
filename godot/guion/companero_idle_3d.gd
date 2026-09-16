## Presencia ambiental mínima para compañeros de oficina (#134).
##
## No posee estado de juego ni colisiones. Modula únicamente el nodo visual ya
## montado por Espacio3D y vuelve exactamente a su transform base al desactivarse.
## La actividad de escritorio reutiliza el clip `work` que ya trae persona.fbx:
## no añade rigs, huesos ni assets nuevos y alterna con `idle` de forma estable.
## Quien está al teléfono habla de verdad con la llamada de `AnimacionesUAL`,
## quien no trabaja se cruza de brazos a ratos y quien te habla gesticula mientras
## dura la conversación.
##
## Quien tiene puesto se sienta en su silla mirando a su mesa: la figura llega
## de pie y de espaldas a ella, así que sentarla es girarla, subirla al asiento
## y acercarla al tablero. Todo eso se deshace al desmontarse.
class_name CompaneroIdle3D
extends Node

const AMPLITUD_RESPIRACION := 0.006
const AMPLITUD_GESTO := 0.025
const VELOCIDAD := 1.35
const DURACION_TRABAJO := 5.5
## Cruzarse de brazos comparte reloj con el trabajo pero dura menos: esperar a
## que pase algo, no un turno.
const DURACION_BRAZOS_CRUZADOS := 4.0
const DURACION_PAUSA := 3.5
const CICLO_TRABAJO := DURACION_TRABAJO + DURACION_PAUSA
const DISTANCIA_HUIDA := 1.35
## Asiento de `chairDesk` a su tamaño del catálogo y cuánto se acerca el cuerpo
## a la mesa para que la espalda quede contra el respaldo y no dentro de él.
const ALTURA_ASIENTO := 0.09
const ADELANTO_SENTADO := 0.08
## Sentado no hay clip de teclear: `Sitting_Talking` adelanta los brazos al
## tablero y se lee como trabajar en la mesa.
const CLIP_SENTADO := "sentado"
const CLIP_SENTADO_ACTIVO := "sentado_hablando"
const DURACION_HUIDA := 0.42

var objetivo: Node3D
var fase := 0.0
var gesto_telefono := false
var actividad_trabajo := false
var actividad_brazos := false
var sentado := false
var reduccion_movimiento := false
var _escala_base := Vector3.ONE
var _rotacion_base := 0.0
var _rotacion_original := 0.0
var _posicion_original := Vector3.ZERO
var _reloj_actividad := 0.0
var _trabajando := false
var _brazos_cruzados := false
var _conversando := false


func configurar(
	nodo: Node3D,
	semilla: int,
	telefono: bool,
	reducir: bool,
	trabajo: bool = false,
	brazos: bool = false,
	en_silla: bool = false,
) -> void:
	objetivo = nodo
	fase = float(absi(semilla) % 1000) / 1000.0 * TAU
	gesto_telefono = telefono
	actividad_trabajo = trabajo and not telefono
	actividad_brazos = brazos and not telefono and not actividad_trabajo
	reduccion_movimiento = reducir
	sentado = en_silla and not telefono
	# Sentado no se puede cruzar de brazos: el clip es de pie y lo levantaría.
	actividad_brazos = actividad_brazos and not sentado
	_escala_base = objetivo.scale
	_rotacion_original = objetivo.rotation.y
	_posicion_original = objetivo.position
	if sentado:
		objetivo.rotation.y += PI
		var frente := Basis(Vector3.UP, objetivo.rotation.y).z
		objetivo.position += frente * ADELANTO_SENTADO + Vector3.UP * ALTURA_ASIENTO
	_rotacion_base = objetivo.rotation.y
	_reloj_actividad = float(absi(semilla) % int(CICLO_TRABAJO * 1000.0)) / 1000.0
	_aplicar(0.0)
	_retomar_rutina()


## Gesticula mientras [param activo]; al terminar retoma lo que hacía. Con
## reducción de movimiento no hay gesto, igual que no hay ciclo de trabajo.
func conversar(activo: bool) -> void:
	if not is_instance_valid(objetivo) or activo == _conversando:
		return
	if activo and reduccion_movimiento:
		return
	_conversando = activo
	if activo:
		var clip := CLIP_SENTADO_ACTIVO if sentado else "conversar"
		AnimacionesUAL.reproducir(objetivo, clip, fase / TAU)
	else:
		_retomar_rutina()


func esta_conversando() -> bool:
	return _conversando


## Dónde estaba el cuerpo antes de sentarse: su sitio del catálogo.
func sitio() -> Vector3:
	return _posicion_original


func _retomar_rutina() -> void:
	_actualizar_actividad(true)
	if gesto_telefono:
		AnimacionesUAL.reproducir(objetivo, "telefono", fase / TAU)


func _process(delta: float) -> void:
	if not is_instance_valid(objetivo):
		queue_free()
		return
	fase = fmod(fase + delta * VELOCIDAD, TAU)
	_reloj_actividad = fmod(_reloj_actividad + delta, CICLO_TRABAJO)
	_actualizar_actividad(false)
	_aplicar(fase)


## Reacción social breve de #209. No cambia estado de juego: desplaza el cuerpo
## visual que ya existe, alejándolo del origen del incidente antes de que la
## jornada desmonte la oficina.
func huir_de(origen_global: Vector3) -> void:
	if not is_instance_valid(objetivo):
		return
	actividad_trabajo = false
	actividad_brazos = false
	_trabajando = false
	_brazos_cruzados = false
	_conversando = false
	sentado = false
	Modelos._animar(objetivo, "idle")
	var direccion := objetivo.global_position - origen_global
	direccion.y = 0.0
	if direccion.length_squared() < 0.01:
		direccion = Vector3.RIGHT
	var destino := objetivo.position + direccion.normalized() * DISTANCIA_HUIDA
	var tween := create_tween()
	(
		tween
		. tween_property(objetivo, "position", destino, DURACION_HUIDA)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)


func _exit_tree() -> void:
	if is_instance_valid(objetivo):
		objetivo.scale = _escala_base
		objetivo.rotation.y = _rotacion_original
		objetivo.position = _posicion_original
		if actividad_trabajo or actividad_brazos or gesto_telefono or _conversando or sentado:
			Modelos._animar(objetivo, "idle")


func _actualizar_actividad(forzar: bool) -> void:
	if _conversando:
		return
	var debe_trabajar := (
		actividad_trabajo and not reduccion_movimiento and _reloj_actividad < DURACION_TRABAJO
	)
	var debe_cruzar_brazos := (
		actividad_brazos
		and not reduccion_movimiento
		and _reloj_actividad < DURACION_BRAZOS_CRUZADOS
	)
	if not forzar and debe_trabajar == _trabajando and debe_cruzar_brazos == _brazos_cruzados:
		return
	_trabajando = debe_trabajar
	_brazos_cruzados = debe_cruzar_brazos
	if sentado:
		var clip := CLIP_SENTADO_ACTIVO if _trabajando else CLIP_SENTADO
		if AnimacionesUAL.reproducir(objetivo, clip, fase / TAU):
			return
	if _brazos_cruzados and AnimacionesUAL.reproducir(objetivo, "brazos_cruzados"):
		return
	Modelos._animar(objetivo, "work" if _trabajando else "idle")


func _aplicar(angulo: float) -> void:
	if reduccion_movimiento:
		objetivo.scale = _escala_base
		objetivo.rotation.y = _rotacion_base
		return
	var respiracion := sin(angulo) * AMPLITUD_RESPIRACION
	objetivo.scale = Vector3(_escala_base.x, _escala_base.y * (1.0 + respiracion), _escala_base.z)
	var gesto := sin(angulo * 0.55) * AMPLITUD_GESTO if gesto_telefono else 0.0
	objetivo.rotation.y = _rotacion_base + gesto
