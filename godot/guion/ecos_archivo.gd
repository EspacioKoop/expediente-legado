## Ecos del archivo (#161): recomponer una frase ya leída.
##
## Este módulo NO busca contenido por su cuenta. Recibe un folio y la frase
## original que otro sistema ya obtuvo del documento abierto, y delega en
## PuzzleOnirico la regla que impide usar un folio fuera de `leido_hoy`.
##
## La frase tampoco se persiste: al reentrar se vuelve a derivar desde el
## original. Así un guardado manipulado no puede convertir el puzzle en un canal
## para inyectar texto que nunca estuvo en el archivo.
class_name EcosArchivo
extends RefCounted

const Puzzle := preload("res://guion/puzzle_onirico.gd")
const MAX_INTENTOS := 3
const CANTIDAD_FRAGMENTOS := 3
const _RUTA_SCRIPT := "res://guion/ecos_archivo.gd"

var nucleo
var fragmentos: Array = []
var presentacion: Array = []
var intentos := 0


## Construye los tres ecos únicamente desde un folio leído hoy.
static func crear(folio: String, frase: String, leido_hoy: Array, raiz: int):
	var partes := _fragmentar(frase)
	if partes.size() != CANTIDAD_FRAGMENTOS:
		return null
	var base = Puzzle.crear("ecos:" + folio, [folio], leido_hoy, raiz)
	if base == null:
		return null

	var ecos = _nueva_instancia()
	if ecos == null:
		return null
	ecos.nucleo = base
	ecos.fragmentos = partes
	ecos.presentacion = _orden_presentacion(base.seed)
	return ecos


## Restaura estado e intentos, pero reconstruye el contenido desde la frase
## original y vuelve a validar el folio mediante PuzzleOnirico.
static func restaurar(datos: Dictionary, frase: String, leido_hoy: Array):
	var base = Puzzle.restaurar(datos.get("nucleo", {}), leido_hoy)
	var partes := _fragmentar(frase)
	if base == null or partes.size() != CANTIDAD_FRAGMENTOS:
		return null
	if not str(base.puzzle_id).begins_with("ecos:") or base.source_ids.size() != 1:
		return null

	var usados := int(datos.get("intentos", 0))
	if usados < 0 or usados > MAX_INTENTOS:
		return null
	if base.state == Puzzle.ESTADO_PENDIENTE and usados >= MAX_INTENTOS:
		return null
	if base.state == Puzzle.ESTADO_FALLADO and usados != MAX_INTENTOS:
		return null

	var ecos = _nueva_instancia()
	if ecos == null:
		return null
	ecos.nucleo = base
	ecos.fragmentos = partes
	ecos.presentacion = _orden_presentacion(base.seed)
	ecos.intentos = usados
	return ecos


## Los elementos que una UI debe enseñar, en el orden deformado del sueño.
## Cada eco conserva su índice canónico para poder colocarlo sin comparar texto.
func ecos_presentados() -> Array:
	var salida := []
	for indice in presentacion:
		salida.append({"id": indice, "texto": fragmentos[indice]})
	return salida


## Prueba una secuencia de ids canónicos.
##
## Una entrada mal formada no gasta intento: pulsar dos veces por rebote o un
## estado incompleto de UI no debe acercar al jugador al castigo. Una secuencia
## completa pero incorrecta sí cuenta; al tercer fallo los ecos se dispersan y
## PuzzleOnirico queda terminal, de modo que la salida nunca se bloquea.
func probar(orden: Array) -> String:
	if nucleo == null or not nucleo.pendiente():
		return "cerrado"
	if not _es_permutacion(orden):
		return "invalido"
	if orden == [0, 1, 2]:
		nucleo.completar()
		return "completado"

	intentos += 1
	if intentos >= MAX_INTENTOS:
		nucleo.fallar()
		return "dispersado"
	return "incorrecto"


## Salir siempre es seguro. Si el puzzle sigue pendiente, salir equivale a
## abandonarlo; si ya terminó, no se vuelve a emitir ningún resultado.
func salir() -> bool:
	if nucleo == null:
		return false
	if nucleo.pendiente():
		return nucleo.abandonar()
	return true


## Navegación circular mínima para mando/teclado. La escena concreta decide qué
## Control recibe foco; aquí solo se evita que izquierda/derecha se salgan de
## los tres ecos.
func mover_foco(actual: int, direccion: int) -> int:
	if direccion == 0:
		return clampi(actual, 0, CANTIDAD_FRAGMENTOS - 1)
	var paso := 1 if direccion > 0 else -1
	return posmod(actual + paso, CANTIDAD_FRAGMENTOS)


## La capa visual puede consultar esta política sin duplicar la preferencia:
## con reducción de movimiento no hay desplazamiento ni transición temporal.
func politica_presentacion(reduccion_movimiento: bool) -> Dictionary:
	return {
		"animar": not reduccion_movimiento,
		"duracion": 0.0 if reduccion_movimiento else 0.35,
	}


func serializar() -> Dictionary:
	if nucleo == null:
		return {}
	return {"nucleo": nucleo.serializar(), "intentos": intentos}


static func _fragmentar(frase: String) -> Array:
	var palabras := frase.strip_edges().split(" ", false)
	if palabras.size() < CANTIDAD_FRAGMENTOS:
		return []

	var corte_uno := maxi(1, int(ceil(float(palabras.size()) / 3.0)))
	var corte_dos := mini(
		palabras.size() - 1, maxi(corte_uno + 1, int(ceil(float(palabras.size()) * 2.0 / 3.0)))
	)
	return [
		" ".join(palabras.slice(0, corte_uno)),
		" ".join(palabras.slice(corte_uno, corte_dos)),
		" ".join(palabras.slice(corte_dos)),
	]


static func _orden_presentacion(semilla: int) -> Array:
	var orden := [0, 1, 2]
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for i in range(orden.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado = orden[i]
		orden[i] = orden[j]
		orden[j] = guardado
	# Un puzzle que casualmente aparezca ya resuelto no prueba nada. Rotar la
	# identidad conserva determinismo sin consumir otra tirada ni sesgar semillas.
	if orden == [0, 1, 2]:
		orden = [1, 2, 0]
	return orden


static func _es_permutacion(orden: Array) -> bool:
	if orden.size() != CANTIDAD_FRAGMENTOS:
		return false
	var copia := orden.duplicate()
	copia.sort()
	return copia == [0, 1, 2]


## Igual que PuzzleOnirico, este runner puede cargarse antes de que Godot haya
## construido la caché de `class_name`; instanciar por ruta evita depender de
## esa caché en un checkout limpio.
static func _nueva_instancia():
	var script := load(_RUTA_SCRIPT)
	if script == null:
		return null
	return script.new()
