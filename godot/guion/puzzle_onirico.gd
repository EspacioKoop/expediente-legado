## Contrato mínimo de un puzzle del sueño (#267, #89).
##
## Un puzzle onírico no es una segunda fuente de información: solo puede
## recombinar material que la jornada ya tocó. Por eso este núcleo recibe
## explícitamente `leido_hoy` al construirse y falla cerrado si alguna fuente
## queda fuera. El puzzle concreto decide QUÉ hay que entender y cómo se pinta;
## aquí solo viven identidad, determinismo y ciclo de vida.
##
## También se separa el resultado de la recompensa. Completar un puzzle emite
## un hecho una sola vez; otro sistema decide si eso abre una salida, entrega un
## objeto o recontextualiza una pista. Así este módulo no puede crear dinero,
## acciones ni conocimiento por accidente.
class_name PuzzleOnirico
extends RefCounted

signal resultado(resultado: Dictionary)

const ESTADO_PENDIENTE := "pendiente"
const ESTADO_COMPLETADO := "completado"
const ESTADO_FALLADO := "fallado"
const ESTADO_ABANDONADO := "abandonado"
const ESTADOS_TERMINALES := [ESTADO_COMPLETADO, ESTADO_FALLADO, ESTADO_ABANDONADO]
const AZAR := preload("res://guion/azar.gd")
const _SEMILLA_GUARDABLE := 0xFFFFFFFF
const _RUTA_SCRIPT := "res://guion/puzzle_onirico.gd"

var puzzle_id := ""
var source_ids: Array = []
var seed := 0
var state := ESTADO_PENDIENTE
var _resultado_emitido := false


## Crea un puzzle únicamente si TODAS sus fuentes se leyeron hoy.
##
## Las fuentes se ordenan y deduplican antes de derivar la semilla: presentar
## los mismos folios en otro orden no debe rerrollear la solución al recargar.
static func crear(id: String, fuentes: Array, leido_hoy: Array, semilla_raiz: int):
	var normalizadas := _normalizar_fuentes(fuentes)
	if id.strip_edges().is_empty() or normalizadas.is_empty():
		return null
	if not _fuentes_permitidas(normalizadas, leido_hoy):
		return null

	var puzzle = _nueva_instancia()
	puzzle.puzzle_id = id
	puzzle.source_ids = normalizadas
	puzzle.seed = semilla(semilla_raiz, id, normalizadas)
	return puzzle


## Derivación estable dentro del dominio del sueño.
##
## No se declara un dominio de azar aparte: los puzzles son contenido del sueño
## y deben variar con la raíz de esa noche, sin acoplarse a un RNG global. El
## resultado se limita a 32 bits porque se serializa: JSON no conserva exactos
## los enteros grandes y una semilla redondeada rerrollearía el puzzle al cargar.
static func semilla(raiz: int, id: String, fuentes: Array) -> int:
	var normalizadas := _normalizar_fuentes(fuentes)
	var texto := "puzzle:" + id
	for fuente in normalizadas:
		texto += "|" + fuente
	return AZAR.derivar_texto(raiz, "sueno", texto) & _SEMILLA_GUARDABLE


## Restaura exactamente el estado serializado, pero vuelve a comprobar el
## aislamiento respecto de `leido_hoy`. Un guardado manipulado o viejo no puede
## colar en el sueño un documento que esta jornada no abrió.
static func restaurar(datos: Dictionary, leido_hoy: Array):
	var id := str(datos.get("puzzle_id", ""))
	var fuentes: Array = datos.get("source_ids", [])
	var normalizadas := _normalizar_fuentes(fuentes)
	var estado := str(datos.get("state", ""))
	var emitido := bool(datos.get("resultado_emitido", false))
	if id.strip_edges().is_empty() or normalizadas.is_empty():
		return null
	if not _fuentes_permitidas(normalizadas, leido_hoy):
		return null
	if estado != ESTADO_PENDIENTE and not ESTADOS_TERMINALES.has(estado):
		return null
	# Un resultado solo existe para estados terminales, y todo estado terminal
	# ya lo emitió antes de serializarse. Rechazar la contradicción evita una
	# recompensa doble después de cargar.
	if emitido != ESTADOS_TERMINALES.has(estado):
		return null

	var puzzle = _nueva_instancia()
	puzzle.puzzle_id = id
	puzzle.source_ids = normalizadas
	puzzle.seed = int(datos.get("seed", 0)) & _SEMILLA_GUARDABLE
	puzzle.state = estado
	puzzle._resultado_emitido = emitido
	return puzzle


func completar() -> bool:
	return _cerrar(ESTADO_COMPLETADO)


func fallar() -> bool:
	return _cerrar(ESTADO_FALLADO)


func abandonar() -> bool:
	return _cerrar(ESTADO_ABANDONADO)


func pendiente() -> bool:
	return state == ESTADO_PENDIENTE


## Datos suficientes para persistir el puzzle dentro de la sesión onírica.
## No guarda recompensa: el consumidor del resultado es dueño de esa decisión.
func serializar() -> Dictionary:
	return {
		"puzzle_id": puzzle_id,
		"source_ids": source_ids.duplicate(),
		"seed": seed,
		"state": state,
		"resultado_emitido": _resultado_emitido,
	}


func _cerrar(nuevo_estado: String) -> bool:
	if not pendiente() or not ESTADOS_TERMINALES.has(nuevo_estado):
		return false
	state = nuevo_estado
	_resultado_emitido = true
	(
		resultado
		. emit(
			{
				"puzzle_id": puzzle_id,
				"source_ids": source_ids.duplicate(),
				"seed": seed,
				"state": state,
			}
		)
	)
	return true


## El runner de `unittest` carga este script antes de la importación del
## proyecto. En ese punto Godot aún no ha construido la caché de `class_name`,
## así que una factoría que escribiera `PuzzleOnirico.new()` no compilaría.
## Cargar el propio Script por ruta funciona tanto antes como después de importar
## y mantiene el contrato ejecutable en un checkout limpio.
static func _nueva_instancia():
	var script := load(_RUTA_SCRIPT)
	if script == null:
		return null
	return script.new()


static func _normalizar_fuentes(fuentes: Array) -> Array:
	var normalizadas := []
	for fuente in fuentes:
		var id := str(fuente)
		if id.is_empty() or normalizadas.has(id):
			continue
		normalizadas.append(id)
	normalizadas.sort()
	return normalizadas


static func _fuentes_permitidas(fuentes: Array, leido_hoy: Array) -> bool:
	for fuente in fuentes:
		if not leido_hoy.has(fuente):
			return false
	return true
