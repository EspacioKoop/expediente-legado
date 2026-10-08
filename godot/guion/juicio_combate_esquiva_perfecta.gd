## Política determinista de esquiva perfecta para el Juicio por Combate (#2450, #2567).
##
## Contrato: una sola función estática pura que evalúa si una esquiva activa
## cae dentro de la ventana estrecha de una amenaza válida y no consumida.
##
## Entradas (diccionario):
##   - amenaza_valida: bool         # la amenaza realmente va a impactar
##   - amenaza_consumida: bool      # ya premió esta amenaza antes
##   - id_amenaza: String           # identificador único de la amenaza
##   - segundos_hasta_impacto: float# tiempo restante hasta que la amenaza impactaría
##   - esquiva_activa: bool         # el jugador está esquivando ahora
##   - segundos_desde_inicio_esquiva: float # tiempo transcurrido desde que empezó la esquiva
##
## Salida (diccionario):
##   - perfecta: bool               # true si la esquiva fue perfecta
##   - amenaza_consumida: bool      # true si esta amenaza queda marcada como consumida
##   - ventana_contraataque: float  # segundos de ventana para contraatacar (0 si no perfecta)
##   - bonus_momentum: float        # bonus declarativo de momentum (0 si no perfecta)
##
## Reglas:
## - Ventana: 0.05–0.15 s antes del impacto (no frame-perfect, estable a FPS).
## - Solo premia si `amenaza_valida` y no `amenaza_consumida`.
## - `esquiva_activa` debe ser true y la esquiva debe haber empezado DENTRO de la ventana.
## - `segundos_desde_inicio_esquiva` no debe exceder la duración base de esquiva (0.34 s).
## - Una amenaza nunca concede dos premios: `id_amenaza` previene dobles premios.
## - Esquiva temprana (fuera de ventana) o tarde (tras impacto) = esquiva normal, sin premio.
## - Reducción de movimiento no altera los timings.
## - Sin RNG, sin SceneTree, sin nodos, sin assets, sin persistencia.
##
## Integración futura: JuicioCombate3D llamará a esta política cada frame con
## las amenazas activas y aplicará `ventana_contraataque` y `bonus_momentum`
## según su orquestación; esta política no decide cómo se aplican.
class_name JuicioCombateEsquivaPerfecta
extends RefCounted

const VENTANA_INICIO := 0.05  # segundos antes del impacto donde empieza la ventana
const VENTANA_FIN := 0.15  # segundos antes del impacto donde termina la ventana
const DURACION_ESQUIVA_BASE := 0.34  # coincide con JuicioCombateJugador.DURACION_ESQUIVA_BASE
const VENTANA_CONTRAATAQUE := 0.6  # segundos de ventana de contraataque tras perfecta
const BONUS_MOMENTUM_BASE := 0.25  # bonus declarativo base de momentum


## Evalúa una única amenaza contra el estado de esquiva actual.
static func evaluar(entradas: Dictionary) -> Dictionary:
	var resultado_base := {
		"perfecta": false,
		"amenaza_consumida": false,
		"ventana_contraataque": 0.0,
		"bonus_momentum": 0.0,
	}

	# Validar entradas mínimas
	if not _entradas_validas(entradas):
		return resultado_base

	var amenaza_valida := bool(entradas.get("amenaza_valida", false))
	var amenaza_consumida := bool(entradas.get("amenaza_consumida", false))
	var id_amenaza := String(entradas.get("id_amenaza", ""))
	var segundos_hasta_impacto := float(entradas.get("segundos_hasta_impacto", 0.0))
	var esquiva_activa := bool(entradas.get("esquiva_activa", false))
	var segundos_desde_inicio_esquiva := float(entradas.get("segundos_desde_inicio_esquiva", 0.0))

	# Amenaza no válida o ya consumida: sin premio
	if not amenaza_valida or amenaza_consumida or id_amenaza.is_empty():
		return resultado_base

	# Jugador no está esquivando: sin premio
	if not esquiva_activa:
		return resultado_base

	# Esquiva empezada fuera de la duración base: ya no cuenta como esquiva activa
	if segundos_desde_inicio_esquiva > DURACION_ESQUIVA_BASE:
		return resultado_base

	# La esquiva debe haber empezado DENTRO de la ventana [VENTANA_INICIO, VENTANA_FIN]
	# segundos_hasta_impacto en el momento de empezar la esquiva =
	# segundos_hasta_impacto_actual + segundos_desde_inicio_esquiva
	var segundos_hasta_impacto_al_inicio := segundos_hasta_impacto + segundos_desde_inicio_esquiva

	# Ventana válida: la esquiva empieza cuando la amenaza está entre
	# VENTANA_INICIO y VENTANA_FIN segundos de impactar
	var en_ventana := (
		(segundos_hasta_impacto_al_inicio >= VENTANA_INICIO)
		and (segundos_hasta_impacto_al_inicio <= VENTANA_FIN)
	)

	if not en_ventana:
		return resultado_base

	# Esquiva perfecta confirmada
	return {
		"perfecta": true,
		"amenaza_consumida": true,
		"ventana_contraataque": VENTANA_CONTRAATAQUE,
		"bonus_momentum": BONUS_MOMENTUM_BASE,
	}


## Evalúa múltiples amenazas a la vez; devuelve array de resultados alineado.
## Cada amenaza se evalúa independientemente; una misma amenaza (mismo id)
## solo puede premiar una vez en todo el array (la primera que cumpla).
static func evaluar_multiples(entradas_array: Array) -> Array:
	var ids_consumidos: Array[String] = []
	var resultados := []

	for entrada in entradas_array:
		var id_amenaza := String(entrada.get("id_amenaza", ""))
		var ya_consumida := bool(entrada.get("amenaza_consumida", false))

		if id_amenaza in ids_consumidos or ya_consumida:
			# Esta amenaza ya premió en una evaluación anterior del mismo tick
			(
				resultados
				. append(
					{
						"perfecta": false,
						"amenaza_consumida": true,
						"ventana_contraataque": 0.0,
						"bonus_momentum": 0.0,
					}
				)
			)
			continue

		var resultado := evaluar(entrada)
		resultados.append(resultado)

		if resultado["perfecta"] and not id_amenaza.is_empty():
			ids_consumidos.append(id_amenaza)

	return resultados


static func _entradas_validas(entradas: Dictionary) -> bool:
	if not entradas.has("amenaza_valida"):
		return false
	if not entradas.has("amenaza_consumida"):
		return false
	if not entradas.has("id_amenaza"):
		return false
	if not entradas.has("segundos_hasta_impacto"):
		return false
	if not entradas.has("esquiva_activa"):
		return false
	if not entradas.has("segundos_desde_inicio_esquiva"):
		return false
	return true
