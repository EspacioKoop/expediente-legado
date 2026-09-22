## El nodo que ejecuta el reparto de `AnimacionAmbiental` (#1230).
##
## Mantiene el registro de piezas, pregunta cada poco quién merece moverse y
## avisa solo a esas. Lo que no se ve no consume nada.
##
## Lo importante está en qué se le pasa a la pieza al avisarla: el **tiempo
## acumulado**, no el delta del fotograma. Una pieza dormida treinta segundos
## despierta sabiendo que han pasado treinta segundos y salta a donde le tocaba
## estar. Así una animación ambiental es una función del tiempo y no un estado
## que se corrompe cada vez que miras a otro lado.
##
## El destino de una pieza es cualquier objeto con:
##
##     func animar_pieza(id: String, tiempo: float, transcurrido: float, lod: String) -> void
class_name AnimadorAmbiental3D
extends Node

## Cada cuánto se rehace el reparto. No hace falta más: a 2,6 m/s el jugador no
## cambia de LOD cuatro veces por segundo, y planificar sí recorre todas las
## piezas, incluidas las dormidas.
const INTERVALO_PLAN := 0.25

const METODO_PIEZA := "animar_pieza"

## Semilla del desfase entre piezas. Se fija desde fuera cuando la partida tiene
## una: aquí no se inventa un reloj ni un azar propio.
var semilla := 0

var _piezas: Array[Dictionary] = []
var _indices: Dictionary = {}
var _reparto: Dictionary = {}
var _ultimo_aviso: Dictionary = {}
var _observador: Node3D = null
var _observador_manual: Dictionary = {}
var _tiempo := 0.0
var _desde_plan := INTERVALO_PLAN
var _presupuesto := AnimacionAmbiental.PRESUPUESTO


func _process(delta: float) -> void:
	avanzar(delta)


## Da de alta una pieza. [param destino] recibirá `animar_pieza`; si desaparece,
## la pieza se descarta sola en el siguiente reparto.
func registrar(id: String, destino: Object, posicion: Vector3, prioridad: int = 1) -> void:
	if id.is_empty() or destino == null or not destino.has_method(METODO_PIEZA):
		return
	var pieza := {
		"id": id,
		"destino": destino,
		"posicion": posicion,
		"prioridad": prioridad,
	}
	if _indices.has(id):
		_piezas[int(_indices[id])] = pieza
	else:
		_indices[id] = _piezas.size()
		_piezas.append(pieza)
		_ultimo_aviso[id] = _tiempo
	_forzar_plan()


## Actualiza la posición de una pieza que se mueve.
func mover(id: String, posicion: Vector3) -> void:
	if not _indices.has(id):
		return
	_piezas[int(_indices[id])]["posicion"] = posicion


func olvidar(id: String) -> void:
	if not _indices.has(id):
		return
	_piezas.remove_at(int(_indices[id]))
	_ultimo_aviso.erase(id)
	_reparto.erase(id)
	_reindexar()
	_forzar_plan()


func limpiar() -> void:
	_piezas.clear()
	_indices.clear()
	_reparto.clear()
	_ultimo_aviso.clear()
	_forzar_plan()


## Fija el nodo desde el que se mide la atención: normalmente la cámara.
func observar(camara: Node3D) -> void:
	_observador = camara
	_observador_manual.clear()
	_forzar_plan()


## Alternativa sin nodo, para pruebas y para quien ya sabe dónde mira el jugador.
func observar_desde(posicion: Vector3, mirada: Vector3) -> void:
	_observador = null
	_observador_manual = {"posicion": posicion, "mirada": mirada}
	_forzar_plan()


## Cupo de piezas activas. Bajarlo es la palanca de emergencia si un sitio
## concreto se pasa de presupuesto.
func fijar_presupuesto(cupo: int) -> void:
	_presupuesto = max(cupo, 0)
	_forzar_plan()


## Avanza el reloj ambiental. `_process` no hace otra cosa; existe aparte para
## que una regresión pueda pasar el tiempo sin montar un árbol de escena.
func avanzar(delta: float) -> void:
	if _piezas.is_empty():
		return
	_tiempo += delta
	_desde_plan += delta
	if _desde_plan >= INTERVALO_PLAN:
		_desde_plan = 0.0
		_planificar()
	_avisar()


## Desfase estable de una pieza, para que quien la anima escalone su ciclo.
func desfase_de(id: String) -> float:
	return AnimacionAmbiental.desfase(id, semilla)


## Fotografía del reparto vigente. La usan las regresiones y el depurador; no
## forma parte del camino caliente.
func estado() -> Dictionary:
	var activas := 0
	for entrada in _reparto.values():
		if bool((entrada as Dictionary)["activa"]):
			activas += 1
	return {
		"tiempo": _tiempo,
		"piezas": _piezas.size(),
		"activas": activas,
		"dormidas": _piezas.size() - activas,
		"presupuesto": _presupuesto,
	}


## LOD vigente de una pieza, o `dormida` si no está repartida.
func lod_de(id: String) -> String:
	if not _reparto.has(id):
		return AnimacionAmbiental.LOD_DORMIDA
	return String((_reparto[id] as Dictionary)["lod"])


func _forzar_plan() -> void:
	_desde_plan = INTERVALO_PLAN


func _reindexar() -> void:
	_indices.clear()
	for indice in _piezas.size():
		_indices[String(_piezas[indice]["id"])] = indice


func _purgar() -> bool:
	var vivas: Array[Dictionary] = []
	for pieza in _piezas:
		var destino: Object = pieza["destino"]
		if is_instance_valid(destino):
			vivas.append(pieza)
		else:
			_ultimo_aviso.erase(String(pieza["id"]))
			_reparto.erase(String(pieza["id"]))
	if vivas.size() == _piezas.size():
		return false
	_piezas = vivas
	_reindexar()
	return true


func _observacion() -> Dictionary:
	if _observador != null and is_instance_valid(_observador):
		var global := _observador.global_transform
		# En Godot la cámara mira hacia su -Z.
		return {"posicion": global.origin, "mirada": -global.basis.z}
	if not _observador_manual.is_empty():
		return _observador_manual
	# Sin observador explícito vale la cámara activa: quien monta el sitio no
	# siempre tiene a mano la del caminante cuando se registran las piezas.
	if is_inside_tree():
		var activa := get_viewport().get_camera_3d()
		if activa != null:
			var suya := activa.global_transform
			return {"posicion": suya.origin, "mirada": -suya.basis.z}
	return {"posicion": Vector3.ZERO, "mirada": Vector3.FORWARD}


func _planificar() -> void:
	_purgar()
	var reparto := AnimacionAmbiental.planificar(_piezas, _observacion(), _presupuesto)
	_reparto.clear()
	for entrada in reparto:
		_reparto[String((entrada as Dictionary)["id"])] = entrada


func _avisar() -> void:
	for pieza in _piezas:
		var id := String(pieza["id"])
		if not _reparto.has(id):
			continue
		var entrada := _reparto[id] as Dictionary
		if not bool(entrada["activa"]):
			continue
		var transcurrido := _tiempo - float(_ultimo_aviso.get(id, _tiempo))
		if transcurrido < float(entrada["periodo"]):
			continue
		_ultimo_aviso[id] = _tiempo
		var destino: Object = pieza["destino"]
		if is_instance_valid(destino):
			destino.call(METODO_PIEZA, id, _tiempo, transcurrido, String(entrada["lod"]))
