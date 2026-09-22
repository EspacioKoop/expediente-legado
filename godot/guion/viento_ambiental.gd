## El viento que mueve el follaje (#1230).
##
## El balanceo lo dibuja `psx.gdshader` en el vértice; aquí solo se decide su
## fuerza y su dirección, y se dejan escritas en los materiales del follaje.
##
## No hay una pieza por árbol **a propósito**: `ArbolesQuaternius` cachea un
## material por color, de modo que una sola escritura mueve toda la masa, y el
## desfase entre ejemplares ya lo saca el shader de la posición del modelo. Lo
## que aporta el animador aquí no es repartir árboles, es dejar de calcular
## rachas cuando no hay una hoja a la vista.
class_name VientoAmbiental
extends Node

## Un nodo solo se balancea si alguien lo pide. Una farola con el mismo shader
## no puede empezar a mecerse porque sí.
const GRUPO_FOLLAJE := "follaje_viento"

const PARAMETRO_FUERZA := "viento_fuerza"
const PARAMETRO_DIRECCION := "viento_direccion"
const PARAMETRO_FRECUENCIA := "viento_frecuencia"
const PARAMETRO_ALTURA := "viento_altura"

## Cuánto se mece el follaje con cada cielo, en metros de desplazamiento de copa.
## La niebla es aire quieto; la nieve cae recta porque si no, no cuaja.
const FUERZA_POR_CLIMA := {
	"despejado": 0.055,
	"nublado": 0.10,
	"lluvia": 0.16,
	"niebla": 0.015,
	"nieve": 0.035,
}

const FUERZA_PREDETERMINADA := 0.055

## Cada cuánto vuelve una racha, en segundos, y cuánto suma sobre la base.
const PERIODO_RACHA := 11.0
const RACHA := 0.45

## La calle corre en Z: un viento cruzado se lee mejor que uno de frente.
const DIRECCION := Vector2(0.82, 0.57)

const _ALTURA_COPA := 4.0

## El vestido del trayecto no llega todo en el mismo fotograma: el arbolado CC0
## lo monta su propio controlador desde `_process`. En vez de encadenar quién
## monta antes que quién, el viento vuelve a mirar unas cuantas veces y, si
## sigue sin haber una hoja, se rinde y deja de gastar.
const INTENTOS_ADOPCION := 120

var _animador: AnimadorAmbiental3D = null
var _materiales: Array[ShaderMaterial] = []
var _centro := Vector3.ZERO
var _fuerza_base := FUERZA_PREDETERMINADA
var _fuerza_aplicada := -1.0
var _raiz: Node = null
var _intentos := 0
var _rendido := false


## Recoge el follaje colgado de [param raiz] y lo da de alta en el animador.
func adoptar(raiz: Node, animador: AnimadorAmbiental3D) -> int:
	_animador = animador
	_raiz = raiz
	_intentos = 0
	_rendido = false
	_materiales.clear()
	if raiz == null:
		return 0

	_recoger(raiz)
	_aplicar(_fuerza_base)
	if _animador != null:
		_animador.registrar(nombre_pieza(), self, _centro)
	return _materiales.size()


## Nombre de la pieza en el animador. Es único por nodo para que dos masas de
## follaje —la calle y un patio— no se pisen el registro.
func nombre_pieza() -> String:
	return "viento:%d" % get_instance_id()


## El cielo manda sobre la fuerza base; las rachas siguen encima.
func fijar_clima(clima: String) -> void:
	_fuerza_base = float(FUERZA_POR_CLIMA.get(clima, FUERZA_PREDETERMINADA))
	_aplicar(_fuerza_base)


## Lo llama el animador. `tiempo` es el acumulado, así que una racha no se
## reinicia por haber estado mirando al suelo.
func animar_pieza(_id: String, tiempo: float, _transcurrido: float, lod: String) -> void:
	if _materiales.is_empty() and not _buscar_follaje_tardio():
		return
	if lod == AnimacionAmbiental.LOD_LEJOS:
		# De lejos la copa es una mancha: la racha no se lee y no se calcula.
		_aplicar(_fuerza_base)
		return
	var ciclo := sin(tiempo * TAU / PERIODO_RACHA)
	_aplicar(_fuerza_base * (1.0 + RACHA * maxf(ciclo, 0.0)))


## Vuelve a buscar follaje mientras quede paciencia. Devuelve si ya hay algo
## que mecer.
func _buscar_follaje_tardio() -> bool:
	if _rendido or _raiz == null or not is_instance_valid(_raiz):
		_rendido = true
		return false
	_intentos += 1
	if _intentos > INTENTOS_ADOPCION:
		_rendido = true
		return false
	_recoger(_raiz)
	if _materiales.is_empty():
		return false
	if _animador != null:
		_animador.mover(nombre_pieza(), _centro)
	return true


func fuerza_actual() -> float:
	return _fuerza_aplicada


func materiales() -> int:
	return _materiales.size()


## Recorre el sitio y se queda con los materiales del follaje declarado.
func _recoger(raiz: Node) -> void:
	var suma := Vector3.ZERO
	var nodos := 0
	for nodo in raiz.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if malla == null or not malla.is_in_group(GRUPO_FOLLAJE):
			continue
		suma += malla.global_position if malla.is_inside_tree() else malla.position
		nodos += 1
		_recoger_materiales(malla)
	if nodos > 0:
		_centro = suma / float(nodos)


func _recoger_materiales(malla: MeshInstance3D) -> void:
	var candidatos: Array[Material] = []
	if malla.material_override != null:
		candidatos.append(malla.material_override)
	for superficie in malla.get_surface_override_material_count():
		var material := malla.get_surface_override_material(superficie)
		if material != null:
			candidatos.append(material)
	for material in candidatos:
		var shader_material := material as ShaderMaterial
		if shader_material == null or _materiales.has(shader_material):
			continue
		_materiales.append(shader_material)


func _aplicar(fuerza: float) -> void:
	if is_equal_approx(fuerza, _fuerza_aplicada):
		return
	_fuerza_aplicada = fuerza
	for material in _materiales:
		material.set_shader_parameter(PARAMETRO_FUERZA, fuerza)
		material.set_shader_parameter(PARAMETRO_DIRECCION, DIRECCION)
		material.set_shader_parameter(PARAMETRO_FRECUENCIA, 1.1)
		material.set_shader_parameter(PARAMETRO_ALTURA, _ALTURA_COPA)
