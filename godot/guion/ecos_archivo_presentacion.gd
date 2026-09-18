## Adaptador de presentación para Ecos del archivo (#161).
##
## Este módulo convierte la lógica pura de EcosArchivo en un contrato consumible
## por una futura sala/UI sin conocer teclado, mando ni nodos concretos. La escena
## solo traduce acciones semánticas a mover/seleccionar/deshacer/abandonar y pinta
## la vista devuelta aquí. Así la navegación por foco y la salida segura se pueden
## probar antes de tocar escenas compartidas del sueño.
class_name EcosArchivoPresentacion
extends RefCounted

const Ecos := preload("res://guion/ecos_archivo.gd")
const Puzzle := preload("res://guion/puzzle_onirico.gd")
const _RUTA_SCRIPT := "res://guion/ecos_archivo_presentacion.gd"

const EVENTO_NINGUNO := "ninguno"
const EVENTO_SELECCIONADO := "seleccionado"
const EVENTO_DESHECHO := "deshecho"
const EVENTO_DUPLICADO := "duplicado"
const EVENTO_INCORRECTO := "incorrecto"
const EVENTO_COMPLETADO := "completado"
const EVENTO_DISPERSADO := "dispersado"
const EVENTO_ABANDONADO := "abandonado"
const EVENTO_CERRADO := "cerrado"

var ecos
var foco := 0
var seleccion: Array = []
var ultimo_evento := EVENTO_NINGUNO
var cerrada := false


static func crear(ecos_instancia):
	if ecos_instancia == null or ecos_instancia.nucleo == null:
		return null
	var presentacion = _nueva_instancia()
	if presentacion == null:
		return null
	presentacion.ecos = ecos_instancia
	presentacion.cerrada = not ecos_instancia.nucleo.pendiente()
	return presentacion


## La escena concreta decide qué entrada física significa izquierda/derecha.
## Aquí solo existe dirección semántica, igual que en EcosArchivo.mover_foco().
func mover(direccion: int) -> int:
	if ecos == null:
		return foco
	foco = ecos.mover_foco(foco, direccion)
	return foco


## Selecciona el eco que ocupa el foco visual actual. El jugador construye la
## secuencia por ids canónicos, nunca comparando texto ni creando información.
func seleccionar() -> String:
	if _terminal():
		return EVENTO_CERRADO
	var presentados: Array = ecos.ecos_presentados()
	if foco < 0 or foco >= presentados.size():
		return EVENTO_CERRADO
	var eco: Dictionary = presentados[foco]
	var id := int(eco.get("id", -1))
	if seleccion.has(id):
		if not seleccion.is_empty() and seleccion.back() == id:
			seleccion.pop_back()
			ultimo_evento = EVENTO_DESHECHO
		else:
			ultimo_evento = EVENTO_DUPLICADO
		return ultimo_evento
	seleccion.append(id)
	ultimo_evento = EVENTO_SELECCIONADO
	if seleccion.size() < Ecos.CANTIDAD_FRAGMENTOS:
		return ultimo_evento

	var resultado: String = str(ecos.probar(seleccion))
	ultimo_evento = resultado
	if resultado == EVENTO_COMPLETADO or resultado == EVENTO_DISPERSADO:
		cerrada = true
	return ultimo_evento


## Permite corregir una elección sin gastar intento. Es una operación semántica
## separada para que una UI pueda mapearla a cancelar/volver según preferencias.
func deshacer() -> bool:
	if _terminal() or seleccion.is_empty():
		return false
	seleccion.pop_back()
	ultimo_evento = EVENTO_DESHECHO
	return true


## Abandonar nunca bloquea la salida del sueño. No se modela aquí una tecla ni
## una puerta: la sala recibe true y recupera el control del jugador.
func abandonar() -> bool:
	if ecos == null:
		return false
	var estaba_pendiente: bool = bool(ecos.nucleo.pendiente())
	var seguro: bool = bool(ecos.salir())
	if not seguro:
		return false
	cerrada = true
	if estaba_pendiente:
		ultimo_evento = EVENTO_ABANDONADO
	return true


## View-model determinista para una capa Control o para elementos 3D con foco.
## `texto` procede únicamente de EcosArchivo, que ya valida leido_hoy.
func vista(reduccion_movimiento: bool) -> Dictionary:
	if ecos == null:
		return {}
	var elementos := []
	var presentados: Array = ecos.ecos_presentados()
	for indice in range(presentados.size()):
		var eco: Dictionary = presentados[indice]
		var id := int(eco.get("id", -1))
		var elemento := {
			"slot": indice,
			"id": id,
			"texto": str(eco.get("texto", "")),
			"foco": indice == foco,
			"seleccionado": seleccion.has(id),
			"posicion_seleccion": seleccion.find(id),
		}
		elementos.append(elemento)
	return {
		"regla":
		"Recompón los tres ecos. Puedes deshacer antes del tercero; la secuencia completa es definitiva.",
		"elementos": elementos,
		"foco": foco,
		"seleccion": seleccion.duplicate(),
		"intentos": ecos.intentos,
		"max_intentos": Ecos.MAX_INTENTOS,
		"estado": _estado_visual(),
		"ultimo_evento": ultimo_evento,
		"salida_disponible": true,
		"movimiento": ecos.politica_presentacion(reduccion_movimiento),
	}


func _estado_visual() -> String:
	if ecos == null or ecos.nucleo == null:
		return EVENTO_CERRADO
	match ecos.nucleo.state:
		Puzzle.ESTADO_COMPLETADO:
			return EVENTO_COMPLETADO
		Puzzle.ESTADO_FALLADO:
			return EVENTO_DISPERSADO
		Puzzle.ESTADO_ABANDONADO:
			return EVENTO_ABANDONADO
		_:
			return "activo"


func _terminal() -> bool:
	return ecos == null or ecos.nucleo == null or cerrada or not ecos.nucleo.pendiente()


static func _nueva_instancia():
	var script := load(_RUTA_SCRIPT)
	if script == null:
		return null
	return script.new()
