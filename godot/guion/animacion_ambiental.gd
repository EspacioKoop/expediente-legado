## Quién se anima, con cuánto detalle y cada cuánto (#1230).
##
## Un mundo vivo no es un mundo donde todo se mueve: es uno donde se mueve lo
## que estás mirando. Sin un reparto explícito, cada efecto ambiental nuevo es
## otro `_process` suelto y el coste crece sin que nadie lo mida.
##
## Este módulo no anima nada ni conoce Godot en ejecución: recibe piezas,
## un observador y un presupuesto, y devuelve el reparto. Es determinista —
## mismas entradas, mismo reparto — para que una regresión pueda comprobarlo
## sin abrir una ventana.
##
## Una pieza no tiene por qué ser un nodo. Una instancia dentro de un MultiMesh
## o un parámetro de shader también es una pieza: lo único que se exige es una
## posición en el mundo y un identificador estable.
class_name AnimacionAmbiental
extends RefCounted

const LOD_CERCA := "cerca"
const LOD_MEDIA := "media"
const LOD_LEJOS := "lejos"
const LOD_DORMIDA := "dormida"

## Los cortes coinciden con los de `CalleFachadasVivas` a propósito: si una
## ventana deja de dibujar su mobiliario a 18 m, tampoco tiene sentido seguir
## animándolo a ritmo de fotograma.
const DISTANCIA_CERCA := 18.0
const DISTANCIA_MEDIA := 36.0
const DISTANCIA_LEJOS := 72.0

## Cada cuánto se refresca una pieza según su detalle, en segundos. Cerca es
## cada tick; lejos, tres veces por segundo y medio. Lo que no se ve a 40 m no
## es el movimiento, es que haya cambiado algo cuando vuelves a mirar.
const PERIODO_CERCA := 0.0
const PERIODO_MEDIA := 0.2
const PERIODO_LEJOS := 0.6

## Cuántas piezas pueden estar activas a la vez. El cupo es el gate: si un corte
## nuevo quiere más movimiento, o sube esto a sabiendas o compite por el sitio.
const PRESUPUESTO := 24

## Media apertura del cono de atención. La cámara del trayecto va a 68°, así que
## 70° de media apertura deja un margen cómodo: una pieza justo fuera del
## encuadre sigue despierta y no se congela delante de tus ojos al girar.
const COSENO_ATENCION := 0.342

## Lo que está a menos de esta distancia se anima aunque quede a la espalda.
## A dos metros no hace falta verlo para notar que se ha parado.
const RADIO_CERCANIA := 6.0

## Prioridad a partir de la cual una pieza no se duerme por quedar fuera del
## cono. Se reserva para lo que cuenta algo —un semáforo, una tele que marca la
## hora—, no para decorado.
const PRIORIDAD_TENAZ := 2

const _PRIMO_DESFASE := 2_654_435_761


## Reparte detalle entre [param piezas] para un [param observador] dado.
##
## Cada pieza es `{id, posicion, prioridad}`; el observador, `{posicion, mirada}`.
## Devuelve una entrada por pieza y en el mismo orden, con su LOD, su periodo de
## refresco y la distancia que lo justifica.
static func planificar(
	piezas: Array, observador: Dictionary, presupuesto: int = PRESUPUESTO
) -> Array:
	var origen: Vector3 = observador.get("posicion", Vector3.ZERO)
	var mirada: Vector3 = observador.get("mirada", Vector3.FORWARD)
	if mirada.length_squared() > 0.0:
		mirada = mirada.normalized()

	var reparto: Array = []
	var candidatas: Array = []
	for indice in piezas.size():
		var pieza := piezas[indice] as Dictionary
		var posicion: Vector3 = pieza.get("posicion", Vector3.ZERO)
		var prioridad := int(pieza.get("prioridad", 1))
		var distancia := origen.distance_to(posicion)
		var lod := _lod_por_distancia(distancia)
		if lod != LOD_DORMIDA and not _atendida(origen, mirada, posicion, distancia, prioridad):
			lod = LOD_DORMIDA
		var entrada := {
			"id": String(pieza.get("id", "")),
			"lod": lod,
			"periodo": periodo_de(lod),
			"distancia": distancia,
			"activa": lod != LOD_DORMIDA,
		}
		reparto.append(entrada)
		if entrada["activa"]:
			candidatas.append({"indice": indice, "prioridad": prioridad, "distancia": distancia})

	_recortar_al_presupuesto(reparto, candidatas, presupuesto)
	return reparto


## Periodo de refresco de un LOD, en segundos. Cero significa cada tick.
static func periodo_de(lod: String) -> float:
	match lod:
		LOD_CERCA:
			return PERIODO_CERCA
		LOD_MEDIA:
			return PERIODO_MEDIA
		LOD_LEJOS:
			return PERIODO_LEJOS
		_:
			return 0.0


## Desfase estable en [0, 1) para una pieza.
##
## Sirve para que veinte ventanas con el mismo ciclo no parpadeen a la vez. Se
## deriva del identificador y de la semilla, nunca del reloj: dos partidas con
## la misma semilla ven el mismo barrio.
static func desfase(id: String, semilla: int) -> float:
	var mezcla := (hash(id) ^ (semilla * _PRIMO_DESFASE)) & 0x7FFFFFFF
	return float(mezcla % 10_007) / 10_007.0


static func _lod_por_distancia(distancia: float) -> String:
	if distancia <= DISTANCIA_CERCA:
		return LOD_CERCA
	if distancia <= DISTANCIA_MEDIA:
		return LOD_MEDIA
	if distancia <= DISTANCIA_LEJOS:
		return LOD_LEJOS
	return LOD_DORMIDA


static func _atendida(
	origen: Vector3, mirada: Vector3, posicion: Vector3, distancia: float, prioridad: int
) -> bool:
	if prioridad >= PRIORIDAD_TENAZ:
		return true
	if distancia <= RADIO_CERCANIA:
		return true
	if is_zero_approx(distancia):
		return true
	return mirada.dot((posicion - origen) / distancia) >= COSENO_ATENCION


## Si hay más candidatas que cupo, gana la prioridad alta y, a igualdad, la más
## cercana. El identificador desempata para que el reparto no dependa del orden
## en que cada consumidor se registró.
static func _recortar_al_presupuesto(reparto: Array, candidatas: Array, presupuesto: int) -> void:
	if candidatas.size() <= presupuesto:
		return
	candidatas.sort_custom(
		func(izquierda: Dictionary, derecha: Dictionary) -> bool:
			if izquierda["prioridad"] != derecha["prioridad"]:
				return izquierda["prioridad"] > derecha["prioridad"]
			if not is_equal_approx(izquierda["distancia"], derecha["distancia"]):
				return izquierda["distancia"] < derecha["distancia"]
			return (
				String(reparto[izquierda["indice"]]["id"])
				< String(reparto[derecha["indice"]]["id"])
			)
	)
	for sobrante in candidatas.slice(max(presupuesto, 0)):
		var entrada := reparto[sobrante["indice"]] as Dictionary
		entrada["lod"] = LOD_DORMIDA
		entrada["periodo"] = 0.0
		entrada["activa"] = false
