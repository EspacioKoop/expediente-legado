## Evaluación automática de una vida laboral a partir del estado ya guardado.
##
## No puntúa al jugador ni concede recompensas. Devuelve categorías independientes
## con rangos corporativos deliberadamente descriptivos. Todo sale de Partida /
## Jornada: aquí no se crean contadores paralelos. `calcular` es puro; `sellar`
## solo congela el resultado cuando una vida termina para poder consultarlo después.
class_name EvaluacionDesempeno
extends RefCounted

const BAJA := "BAJA"
const MEDIA := "MEDIA"
const ALTA := "ALTA"
const RANGOS := [BAJA, MEDIA, ALTA]
const CATEGORIAS := [
	"productividad",
	"precipitacion",
	"cuidado_gato",
	"liquidez",
	"exploracion_onirica",
]
const CLAVE_HISTORIAL := "evaluaciones_desempeno"


static func calcular(partida: Dictionary, jornada_override: Dictionary = {}) -> Dictionary:
	var jornada: Dictionary = (
		jornada_override if not jornada_override.is_empty() else partida.get("jornada", {})
	)
	var vuelta := int(jornada.get("vuelta", 1))
	var sellada := _registro_de_vuelta(partida, vuelta)
	if not sellada.is_empty() and typeof(sellada.get("evaluacion")) == TYPE_DICTIONARY:
		return Dictionary(sellada["evaluacion"]).duplicate(true)

	var gato: Dictionary = jornada.get("gato", {})
	var veredictos: Dictionary = partida.get("veredictos", {})
	var mapa: Array = jornada.get("mapa", [])
	var dinero := int(jornada.get("dinero", 0))
	var dias_sin_comer := int(gato.get("dias_sin_comer", 0))
	var cerrados_vuelta := maxi(0, veredictos.size() - _veredictos_antes_de(partida, vuelta))

	return {
		"productividad": _rango(cerrados_vuelta, 2, 6),
		"precipitacion": ALTA if bool(partida.get("perdio_vida_en_esta_vuelta", false)) else BAJA,
		"cuidado_gato": _rango_invertido(dias_sin_comer, 1, Jornada.PACIENCIA_GATO),
		"liquidez": _rango(dinero, Jornada.PRECIO_COMIDA_GATO, Jornada.PRECIO_ALQUILER),
		"exploracion_onirica": _rango(mapa.size(), 2, 6),
	}


## Congela una vida una sola vez. El motivo describe por qué terminó, no altera
## la evaluación: "reasignacion", "final_narrativo" o cualquier condición futura.
## Repetir la llamada para la misma vuelta devuelve exactamente el sello existente.
static func sellar(
	partida: Dictionary, motivo: String, jornada_override: Dictionary = {}
) -> Dictionary:
	var jornada: Dictionary = (
		jornada_override if not jornada_override.is_empty() else partida.get("jornada", {})
	)
	var vuelta := int(jornada.get("vuelta", 1))
	var existente := _registro_de_vuelta(partida, vuelta)
	if not existente.is_empty():
		return existente.duplicate(true)

	var veredictos: Dictionary = partida.get("veredictos", {})
	var registro := {
		"vuelta": vuelta,
		"motivo": motivo.strip_edges() if not motivo.strip_edges().is_empty() else "otro",
		"veredictos_total": veredictos.size(),
		"evaluacion": calcular(partida, jornada),
	}
	var historial := _historial(partida).duplicate(true)
	historial.append(registro)
	partida[CLAVE_HISTORIAL] = historial
	return registro.duplicate(true)


static func historial(partida: Dictionary) -> Array:
	return _historial(partida).duplicate(true)


## Valida únicamente la forma persistida. Partidas antiguas pueden no tener esta
## clave: Partida._fusionar las completa con una lista vacía desde Partida.nueva().
static func validar_historial(historial_crudo: Array) -> Array:
	var errores := []
	var vueltas := {}
	for i in historial_crudo.size():
		var registro = historial_crudo[i]
		if typeof(registro) != TYPE_DICTIONARY:
			errores.append("%d no es un objeto" % i)
			continue
		if not _entero_no_negativo(registro.get("vuelta", -1)) or int(registro["vuelta"]) < 1:
			errores.append("%d.vuelta inválida" % i)
		elif vueltas.has(int(registro["vuelta"])):
			errores.append("%d.vuelta duplicada" % i)
		else:
			vueltas[int(registro["vuelta"])] = true
		if typeof(registro.get("motivo")) != TYPE_STRING or String(registro["motivo"]).strip_edges().is_empty():
			errores.append("%d.motivo inválido" % i)
		if not _entero_no_negativo(registro.get("veredictos_total", -1)):
			errores.append("%d.veredictos_total inválido" % i)
		var evaluacion = registro.get("evaluacion")
		if typeof(evaluacion) != TYPE_DICTIONARY:
			errores.append("%d.evaluacion no es un objeto" % i)
			continue
		for categoria in CATEGORIAS:
			if not evaluacion.has(categoria) or not RANGOS.has(evaluacion[categoria]):
				errores.append("%d.evaluacion.%s inválida" % [i, categoria])
	return errores


static func _historial(partida: Dictionary) -> Array:
	var valor = partida.get(CLAVE_HISTORIAL, [])
	return valor if typeof(valor) == TYPE_ARRAY else []


static func _registro_de_vuelta(partida: Dictionary, vuelta: int) -> Dictionary:
	for registro in _historial(partida):
		if typeof(registro) == TYPE_DICTIONARY and int(registro.get("vuelta", -1)) == vuelta:
			return registro
	return {}


static func _veredictos_antes_de(partida: Dictionary, vuelta: int) -> int:
	var total := 0
	for registro in _historial(partida):
		if typeof(registro) != TYPE_DICTIONARY:
			continue
		if int(registro.get("vuelta", vuelta)) < vuelta:
			total = maxi(total, int(registro.get("veredictos_total", 0)))
	return total


## Los umbrales son inclusivos y solo clasifican magnitudes observadas. No hay
## una suma final porque una vida puede ser simultáneamente productiva, precaria
## y poco exploradora sin que una categoría invalide las demás.
static func _rango(valor: int, umbral_medio: int, umbral_alto: int) -> String:
	if valor >= umbral_alto:
		return ALTA
	if valor >= umbral_medio:
		return MEDIA
	return BAJA


static func _rango_invertido(valor: int, umbral_medio: int, umbral_alto: int) -> String:
	if valor >= umbral_alto:
		return BAJA
	if valor >= umbral_medio:
		return MEDIA
	return ALTA


static func _entero_no_negativo(valor) -> bool:
	if typeof(valor) == TYPE_INT:
		return valor >= 0
	if typeof(valor) != TYPE_FLOAT or not is_finite(valor):
		return false
	return floor(valor) == valor and valor >= 0.0
