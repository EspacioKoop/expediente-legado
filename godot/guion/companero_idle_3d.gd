## Presencia ambiental mínima para compañeros de oficina (#134).
##
## No posee estado de juego ni colisiones. Modula únicamente el nodo visual ya
## montado por Espacio3D y vuelve exactamente a su transform base al desactivarse.
## La actividad de escritorio reutiliza el clip `work` que ya trae persona.fbx:
## no añade rigs, huesos ni assets nuevos y alterna con `idle` de forma estable.
class_name CompaneroIdle3D
extends Node

const AMPLITUD_RESPIRACION := 0.006
const AMPLITUD_GESTO := 0.025
const VELOCIDAD := 1.35
const DURACION_TRABAJO := 5.5
const DURACION_PAUSA := 3.5
const CICLO_TRABAJO := DURACION_TRABAJO + DURACION_PAUSA

var objetivo: Node3D
var fase := 0.0
var gesto_telefono := false
var actividad_trabajo := false
var reduccion_movimiento := false
var _escala_base := Vector3.ONE
var _rotacion_base := 0.0
var _reloj_actividad := 0.0
var _trabajando := false


func configurar(nodo: Node3D, semilla: int, telefono: bool, trabajo: bool, reducir: bool) -> void:
	objetivo = nodo
	fase = float(absi(semilla) % 1000) / 1000.0 * TAU
	gesto_telefono = telefono
	actividad_trabajo = trabajo and not telefono
	reduccion_movimiento = reducir
	_escala_base = objetivo.scale
	_rotacion_base = objetivo.rotation.y
	_reloj_actividad = float(absi(semilla) % int(CICLO_TRABAJO * 1000.0)) / 1000.0
	_aplicar(0.0)
	_actualizar_actividad(true)


func _process(delta: float) -> void:
	if not is_instance_valid(objetivo):
		queue_free()
		return
	fase = fmod(fase + delta * VELOCIDAD, TAU)
	_reloj_actividad = fmod(_reloj_actividad + delta, CICLO_TRABAJO)
	_actualizar_actividad(false)
	_aplicar(fase)


func _exit_tree() -> void:
	if is_instance_valid(objetivo):
		objetivo.scale = _escala_base
		objetivo.rotation.y = _rotacion_base
		if actividad_trabajo:
			Modelos._animar(objetivo, "idle")


func _actualizar_actividad(forzar: bool) -> void:
	var debe_trabajar := actividad_trabajo and not reduccion_movimiento and _reloj_actividad < DURACION_TRABAJO
	if not forzar and debe_trabajar == _trabajando:
		return
	_trabajando = debe_trabajar
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
