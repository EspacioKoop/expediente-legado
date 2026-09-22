## El sueño respira (#1230).
##
## En vigilia una animación tiene que ser creíble; en el sueño puede ser el
## síntoma. La sala se hincha y se deshincha muy despacio, lo justo para que al
## quedarte quieto notes que el sitio no está del todo quieto.
##
## Se hace en el **vértice**, dentro de `psx.gdshader`, y no moviendo nodos: la
## colisión no se entera. Un muro que respira y un muro contra el que chocas son
## la misma pared y no pueden desincronizarse, así que esto no puede abrir un
## hueco por donde caerse (#784) ni desplazar una salida.
##
## No inventa contenido: deformar lo que ya está montado es exactamente lo que
## el sueño hace con el archivo (#87).
class_name SuenoRespiracion
extends Node

const PARAMETRO_FUERZA := "respiracion_fuerza"
const PARAMETRO_FRECUENCIA := "respiracion_frecuencia"
const PARAMETRO_FASE := "respiracion_fase"

## Amplitud máxima, en metros. Tres centímetros y medio sobre una sala de tres
## metros no se ve moverse: se nota.
const AMPLITUD := 0.035

## Una respiración lenta, más cerca de la de alguien dormido que de la de
## alguien corriendo.
const FRECUENCIA := 0.14

## Lo que tarda la sala en soltarse del todo. Al entrar apenas respira; si te
## quedas, se va notando más. Sale del tiempo acumulado del animador, así que
## mirar a otro lado no lo reinicia.
const ASENTAMIENTO := 40.0
const AMPLITUD_INICIAL := 0.35

## Solo respira lo que tiene altura de sala. Un suelo es una losa plana, y un
## suelo que sube y baja bajo tus pies no es una anomalía onírica: es un mareo.
const ALTURA_MINIMA := 1.5

var _materiales: Array[ShaderMaterial] = []
var _animador: AnimadorAmbiental3D = null
var _centro := Vector3.ZERO
var _intensidad := 1.0
var _fuerza_aplicada := -1.0


## Recoge los muros de la sala colgada de [param raiz] y los da de alta.
## Devuelve cuántos materiales respiran.
func adoptar(raiz: Node, animador: AnimadorAmbiental3D) -> int:
	_animador = animador
	_materiales.clear()
	if raiz == null:
		return 0

	var suma := Vector3.ZERO
	var adoptados := 0
	for nodo in raiz.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if malla == null or not _es_sala(malla):
			continue
		var material := malla.material_override as ShaderMaterial
		if material == null or _materiales.has(material):
			continue
		_materiales.append(material)
		suma += malla.global_position if malla.is_inside_tree() else malla.position
		adoptados += 1
	if adoptados > 0:
		_centro = suma / float(adoptados)
	_preparar()

	if _animador != null and not _materiales.is_empty():
		# Tenaz: la sala que respira está alrededor, no delante. Dormirla por
		# darle la espalda sería pararla justo cuando se nota.
		_animador.registrar(nombre_pieza(), self, _centro, AnimacionAmbiental.PRIORIDAD_TENAZ)
	return _materiales.size()


func nombre_pieza() -> String:
	return "respiracion:%d" % get_instance_id()


## Cuánto respira esta noche, de 0 a 1. Lo fija quien sepa de contaminación o
## de profundidad del sueño; aquí no se decide, solo se aplica.
func fijar_intensidad(intensidad: float) -> void:
	_intensidad = clampf(intensidad, 0.0, 1.0)


func animar_pieza(_id: String, tiempo: float, _transcurrido: float, _lod: String) -> void:
	var asentada := clampf(tiempo / ASENTAMIENTO, 0.0, 1.0)
	var rampa := AMPLITUD_INICIAL + (1.0 - AMPLITUD_INICIAL) * asentada
	_aplicar(AMPLITUD * _intensidad * rampa)


func fuerza_actual() -> float:
	return _fuerza_aplicada


func materiales() -> int:
	return _materiales.size()


## Devuelve la sala a su forma exacta. Una animación ambiental tiene que saber
## irse sin dejar la geometría torcida.
func soltar() -> void:
	for material in _materiales:
		material.set_shader_parameter(PARAMETRO_FUERZA, 0.0)
	_materiales.clear()
	_fuerza_aplicada = -1.0


func _es_sala(malla: MeshInstance3D) -> bool:
	if malla.mesh == null:
		return false
	return malla.mesh.get_aabb().size.y >= ALTURA_MINIMA


func _preparar() -> void:
	for indice in _materiales.size():
		var material := _materiales[indice]
		material.set_shader_parameter(PARAMETRO_FRECUENCIA, FRECUENCIA)
		# Dos salas contiguas no pueden inhalar a la vez: se leería como un
		# latido del motor y no como dos sitios.
		material.set_shader_parameter(PARAMETRO_FASE, float(indice) * 1.7)
	_aplicar(AMPLITUD * _intensidad * AMPLITUD_INICIAL)


func _aplicar(fuerza: float) -> void:
	if is_equal_approx(fuerza, _fuerza_aplicada):
		return
	_fuerza_aplicada = fuerza
	for material in _materiales:
		material.set_shader_parameter(PARAMETRO_FUERZA, fuerza)
