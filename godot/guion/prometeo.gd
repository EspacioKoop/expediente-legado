## La segunda capa: logros, tarot, vidas, ideología y el duelo.
##
## Port de `prometeo-logic.js`, que ya era lógica pura sin DOM ni
## localStorage. Se porta ENTERA antes que la interfaz por el mismo motivo por
## el que existía separada en JS: son las reglas, y las reglas se comprueban
## sin pintar nada.
##
## Lo que este módulo NO hace es guardar. En el original el estado vivía en
## `localStorage`; dónde vive una partida de Godot está sin decidir, así que
## aquí todo son funciones sobre un estado que se recibe.
class_name Prometeo
extends RefCounted

## Los cuatro ejes, en el orden que decide los empates.
const EJES := ["comunismo", "socialdemocrata", "centrista", "neoliberal"]

## En cada historia política hay dos opciones útiles (su secuela apunta a una
## pista real por descubrir) y dos de confusión. La corrección es POR
## SITUACIÓN, no por ideología: cada eje es útil en exactamente 4 de las 8
## cartas, y hay una prueba que lo exige. Sin esa invariante el juego estaría
## diciendo cuál es la ideología buena.
const UTILIDAD_CARTAS := {
	"la-justicia": ["comunismo", "socialdemocrata"],
	"la-rueda": ["centrista", "neoliberal"],
	"el-juicio": ["comunismo", "socialdemocrata"],
	"la-luna": ["centrista", "neoliberal"],
	"el-carro": ["comunismo", "centrista"],
	"el-sol": ["socialdemocrata", "neoliberal"],
	"la-emperatriz": ["socialdemocrata", "neoliberal"],
	"la-sacerdotisa": ["comunismo", "centrista"],
}

## Probabilidad de que el rival de la Ventanilla conteste a la última jugada
## en vez de tirar al azar. Es lo que lo hace cebable: hay una decisión por
## ronda, no una tabla que memorizar.
const TENDENCIA_REACTIVA := 0.7

## Contrato transversal de #919. Las historias de Tarot siguen viviendo en
## `historias_cartas` durante la migración; estas claves contienen únicamente
## decisiones nuevas, exposición consumida y lecturas sociales. Nunca se
## mezclan porque leer una idea no equivale a elegirla, y la interpretación de
## un NPC tampoco define al personaje jugador.
const CLAVE_ELECCIONES_IDEOLOGICAS := "elecciones_ideologicas_run"
const CLAVE_EXPOSICION_IDEOLOGICA := "exposicion_ideologica_hoy"
const CLAVE_LECTURAS_SOCIALES := "lecturas_sociales"
const PREFIJO_HISTORIA := "tarot:"


## Combina lo guardado en esta máquina con la lista vigente de logros o cartas:
## conserva el estado de lo ya guardado (buscándolo también por alias, para ids
## renombrados) y adopta los metadatos y las entradas nuevas.
##
## No muta ninguna de las dos listas de entrada.
static func fusionar_con_guardado(
	guardados: Array, actuales: Array, campos_estado: Array, alias: Dictionary = {}
) -> Array:
	var fusionados := []
	for item in actuales:
		var ids_buscados := [item["id"]]
		if alias.has(item["id"]):
			ids_buscados.append(alias[item["id"]])

		var copia: Dictionary = item.duplicate(true)
		for guardado in guardados:
			if not ids_buscados.has(guardado.get("id")):
				continue
			for campo in campos_estado:
				if guardado.has(campo):
					copia[campo] = guardado[campo]
			break
		fusionados.append(copia)
	return fusionados


## Marca como recogida la carta con ese id. Devuelve true solo si hubo novedad
## de verdad: la carta existía y no estaba ya recogida.
static func desbloquear_carta(tarot: Array, id: String) -> bool:
	for carta in tarot:
		if carta["id"] == id and not carta.get("recogida", false):
			carta["recogida"] = true
			return true
	return false


## Frontera común de adquisición de Tarot (#46/#1029): posesión de esta vuelta
## y memoria fantasma se escriben juntas. Los emisores deciden CUÁNDO se gana
## una carta; esta función solo garantiza que todas las fuentes persistan igual.
##
## Devuelve true únicamente para una adquisición nueva. Repetir el mismo
## evento no vuelve a escribir la memoria ni convierte una carga de partida en
## un desbloqueo.
static func desbloquear_carta_en_estado(estado: Dictionary, id: String) -> bool:
	var tarot_bruto = estado.get("tarot", [])
	if typeof(tarot_bruto) != TYPE_ARRAY:
		return false
	var tarot: Array = tarot_bruto
	if not desbloquear_carta(tarot, id):
		return false

	var conocidas_bruto = estado.get("cartas_conocidas", [])
	var conocidas: Array = conocidas_bruto if typeof(conocidas_bruto) == TYPE_ARRAY else []
	if not conocidas.has(id):
		conocidas.append(id)
		estado["cartas_conocidas"] = conocidas
	return true


## Familia de progreso que nace de descubrir una pista REAL. Se llama desde el
## evento de descubrimiento, nunca al cargar una partida ni al abrir una UI.
## Así conserva la semántica del legado sin convertir el estado guardado en un
## emisor de recompensas.
static func sincronizar_tarot_por_pistas(estado: Dictionary) -> Array:
	var pistas_bruto = estado.get("pistas_descubiertas", [])
	if typeof(pistas_bruto) != TYPE_ARRAY:
		return []
	var pistas: Array = pistas_bruto
	var nuevas := []
	if pistas.size() >= 1 and desbloquear_carta_en_estado(estado, "el-mago"):
		nuevas.append("el-mago")
	if pistas.size() >= 20 and desbloquear_carta_en_estado(estado, "la-estrella"):
		nuevas.append("la-estrella")
	return nuevas


## Progreso por expediente (#1029): Los Enamorados nace exactamente cuando
## una pista real completa la investigación del caso que se está mirando.
## Recibe el caso explícitamente para no recorrer el catálogo ni convertir una
## carga de partida en un emisor de recompensas.
static func sincronizar_tarot_por_caso_resuelto(estado: Dictionary, caso: Dictionary) -> Array:
	var nuevas := []
	var pistas_bruto = estado.get("pistas_descubiertas", [])
	if typeof(pistas_bruto) == TYPE_ARRAY:
		var pistas: Array = pistas_bruto
		if (
			Progreso.caso_resuelto(caso, pistas)
			and desbloquear_carta_en_estado(estado, "los-enamorados")
		):
			nuevas.append("los-enamorados")
	return nuevas


## Cierre perfecto de #46/#1029. La Templanza queda fuera del conjunto
## exigido porque obtenerla requiere gastar una carta y El Mundo exige que
## ninguna de las cartas válidas se haya gastado. Los casos recibidos son los
## principales del catálogo; una lista vacía nunca concede victoria.
static func sincronizar_tarot_mundo(estado: Dictionary, casos_principales: Array) -> Array:
	var tarot_bruto = estado.get("tarot", [])
	var pistas_bruto = estado.get("pistas_descubiertas", [])
	if typeof(tarot_bruto) != TYPE_ARRAY or typeof(pistas_bruto) != TYPE_ARRAY:
		return []

	var validas := 0
	for carta in tarot_bruto:
		var carta_id := String(carta.get("id", ""))
		if carta_id in ["el-mundo", "la-templanza"]:
			continue
		validas += 1
		if not carta.get("recogida", false) or carta.get("gastada", false):
			return []

	var pistas: Array = pistas_bruto
	if validas == 0 or not Progreso.todos_resueltos(casos_principales, pistas):
		return []
	if desbloquear_carta_en_estado(estado, "el-mundo"):
		return ["el-mundo"]
	return []


## Una acusación es precipitada cuando se ha descubierto menos proporción de
## pistas que el umbral de la dificultad. Sin pistas totales no hay ratio que
## evaluar, así que nunca es precipitada — y de paso no se divide por cero.
static func acusacion_precipitada(descubiertas: int, total: int, umbral: float) -> bool:
	if total == 0:
		return false
	return (float(descubiertas) / float(total)) < umbral


## Cuenta las elecciones de la partida por eje. Es el conteo que decide el
## final político, expuesto también como recuento: son los puntos de ideología
## de las cargas de habilidad en combate — la partida política ES el
## equipamiento, sin pantalla de asignación.
static func puntos_por_eje(
	historias: Dictionary, resueltas: Array, orden: Array = EJES
) -> Dictionary:
	var conteo := {}
	for eje in orden:
		conteo[eje] = 0
	for id in resueltas:
		var eje = historias.get(id)
		if conteo.has(eje):
			conteo[eje] += 1
	return conteo


## El eje ganador. Cualquier empate lo gana el primero de [param orden], que
## por eso no es un detalle: es la ideología por defecto del final.
static func eje_ganador(historias: Dictionary, resueltas: Array, orden: Array = EJES) -> String:
	var conteo := puntos_por_eje(historias, resueltas, orden)
	var ganador: String = orden[0]
	var mas_votos := -1
	for eje in orden:
		if conteo[eje] > mas_votos:
			mas_votos = conteo[eje]
			ganador = eje
	return ganador


## Registra una decisión ideológica nueva fuera del corpus heredado de Tarot.
##
## `id_evento` es estable e idempotente dentro de la vuelta. El prefijo
## `tarot:` queda reservado al adaptador de `historias_cartas`: duplicar una
## historia como evento nuevo crearía dos fuentes de verdad.
static func registrar_eleccion_ideologica(
	estado: Dictionary,
	id_evento: String,
	fuente: String,
	eje: String,
	contexto: String = "",
	jornada: int = 0,
	etiquetas: Array = []
) -> bool:
	if (
		id_evento.strip_edges().is_empty()
		or id_evento.begins_with(PREFIJO_HISTORIA)
		or fuente.strip_edges().is_empty()
		or not EJES.has(eje)
	):
		return false

	var elecciones := _lista_estado(estado, CLAVE_ELECCIONES_IDEOLOGICAS)
	for evento in elecciones:
		if evento.get("id", "") == id_evento:
			return false

	(
		elecciones
		. append(
			{
				"id": id_evento,
				"fuente": fuente,
				"eje": eje,
				"contexto": contexto,
				"jornada": jornada,
				"etiquetas": _etiquetas_normalizadas(etiquetas),
			}
		)
	)
	estado[CLAVE_ELECCIONES_IDEOLOGICAS] = elecciones
	return true


## Vista unificada de las elecciones de la vuelta.
##
## Durante la migración, las ocho historias siguen siendo la fuente de verdad
## de Tarot y se adaptan en lectura como eventos `tarot:<carta>`. Las decisiones
## nuevas viven en su propia lista. No se escribe de vuelta en
## `historias_cartas`, así que no se altera persistencia, cargas ni finales
## heredados antes de que sus verticales migren explícitamente.
static func elecciones_ideologicas(estado: Dictionary) -> Array:
	var resultado := []
	var ids := {}
	var historias = estado.get("historias_cartas", {})
	if typeof(historias) == TYPE_DICTIONARY:
		var cartas: Array = historias.keys()
		cartas.sort()
		for carta in cartas:
			var eje = historias[carta]
			if not EJES.has(eje):
				continue
			var id_evento := PREFIJO_HISTORIA + String(carta)
			(
				resultado
				. append(
					{
						"id": id_evento,
						"fuente": "tarot",
						"eje": eje,
						"contexto": String(carta),
						"jornada": -1,
						"etiquetas": ["prometeo", "tarot"],
					}
				)
			)
			ids[id_evento] = true

	for evento in _lista_estado(estado, CLAVE_ELECCIONES_IDEOLOGICAS):
		var id_evento := String(evento.get("id", ""))
		var eje := String(evento.get("eje", ""))
		if id_evento.is_empty() or ids.has(id_evento) or not EJES.has(eje):
			continue
		resultado.append(evento.duplicate(true))
		ids[id_evento] = true
	return resultado


## Exposición es lo que se leyó, vio o escuchó. Se registra aparte a propósito:
## nunca suma puntos de elección ni concede por sí sola una doctrina de combate.
static func registrar_exposicion_ideologica(
	estado: Dictionary,
	id_evento: String,
	fuente: String,
	eje: String,
	jornada: int = 0,
	etiquetas: Array = []
) -> bool:
	if id_evento.strip_edges().is_empty() or fuente.strip_edges().is_empty() or not EJES.has(eje):
		return false

	var exposicion := _lista_estado(estado, CLAVE_EXPOSICION_IDEOLOGICA)
	for evento in exposicion:
		if evento.get("id", "") == id_evento:
			return false

	(
		exposicion
		. append(
			{
				"id": id_evento,
				"fuente": fuente,
				"eje": eje,
				"jornada": jornada,
				"etiquetas": _etiquetas_normalizadas(etiquetas),
			}
		)
	)
	estado[CLAVE_EXPOSICION_IDEOLOGICA] = exposicion
	return true


## Registra qué cree un actor haber observado. Una lectura social se vincula a
## un evento real conocido por ese actor, pero no añade votos ni reescribe la
## elección original.
static func registrar_lectura_social(
	estado: Dictionary,
	actor: String,
	evento_observado: String,
	reaccion: String = "",
	etiquetas: Array = []
) -> bool:
	if actor.strip_edges().is_empty() or evento_observado.strip_edges().is_empty():
		return false

	var lecturas := _lista_estado(estado, CLAVE_LECTURAS_SOCIALES)
	for lectura in lecturas:
		if (
			lectura.get("actor", "") == actor
			and lectura.get("evento_observado", "") == evento_observado
		):
			return false

	(
		lecturas
		. append(
			{
				"actor": actor,
				"evento_observado": evento_observado,
				"reaccion": reaccion,
				"etiquetas": _etiquetas_normalizadas(etiquetas),
			}
		)
	)
	estado[CLAVE_LECTURAS_SOCIALES] = lecturas
	return true


## Recuento transversal: consume elecciones heredadas + nuevas y, de forma
## deliberada, ignora exposición y lectura social.
static func conteo_elecciones_ideologicas(estado: Dictionary) -> Dictionary:
	var conteo := {}
	for eje in EJES:
		conteo[eje] = 0
	for evento in elecciones_ideologicas(estado):
		var eje: String = evento["eje"]
		conteo[eje] += 1
	return conteo


## Cargas de doctrina que puede consumir cualquier vertical de combate.
##
## Solo cuentan elecciones explícitas de la vuelta. Exposición y lecturas
## sociales quedan fuera por contrato, y el tope evita acumulación ilimitada.
static func cargas_ideologicas(estado: Dictionary, tope_por_eje: int = 2) -> Dictionary:
	var conteo := conteo_elecciones_ideologicas(estado)
	var cargas := {}
	var tope := maxi(0, tope_por_eje)
	for eje in EJES:
		cargas[eje] = mini(tope, int(conteo.get(eje, 0)))
	return cargas


## Devuelve TODOS los ejes empatados en cabeza. Sin elecciones devuelve [].
## Es el contrato nuevo para #925: pluralidad es un estado real y no cae por
## posición en EJES. `eje_ganador()` conserva por ahora el comportamiento
## legado para no cambiar finales existentes dentro de este corte.
static func ejes_dominantes(estado: Dictionary) -> Array:
	var conteo := conteo_elecciones_ideologicas(estado)
	var maximo := 0
	for eje in EJES:
		maximo = maxi(maximo, conteo[eje])
	if maximo == 0:
		return []

	var dominantes := []
	for eje in EJES:
		if conteo[eje] == maximo:
			dominantes.append(eje)
	return dominantes


## La exposición es diaria. Quien gobierne el cambio de jornada puede limpiar
## solo este canal sin tocar decisiones ni reacciones de la vuelta.
static func reiniciar_exposicion_ideologica_diaria(estado: Dictionary) -> void:
	estado[CLAVE_EXPOSICION_IDEOLOGICA] = []


static func clasificar_eleccion(carta_id: String, eje: String) -> String:
	var utiles: Array = UTILIDAD_CARTAS.get(carta_id, [])
	return "pista" if utiles.has(eje) else "confusion"


## Qué juega el rival esta ronda.
##
## "ciclo" reproduce el ritmo autorado del duelo del caso 6: determinista y
## aprendible, porque es una escena y no un desafío repetible. "reactiva" es la
## Ventanilla de Reclamaciones, que tiende a contestar a tu última jugada y por
## eso se puede cebar.
##
## Asume la cadena circular de tipos del juego —cada índice vence al
## siguiente—, así que lo que vence a X es el índice anterior a X.
static func jugada_rival(
	modo: String, ronda: int, total_tipos: int, azar: Callable, ultima_del_jugador: int = -1
) -> int:
	if modo == "reactiva":
		if ultima_del_jugador < 0 or azar.call() >= TENDENCIA_REACTIVA:
			return int(azar.call() * total_tipos)
		return (ultima_del_jugador + total_tipos - 1) % total_tipos
	return ronda % total_tipos


## Ganar suma una a la racha, perder la devuelve a cero; la mejor marca solo
## puede crecer. La racha en curso es efímera, la mejor marca es lo único que
## sobrevive a la partida.
static func actualizar_racha(racha: int, mejor: int, gano: bool) -> Dictionary:
	var nueva := racha + 1 if gano else 0
	return {"racha": nueva, "mejor": maxi(mejor, nueva)}


## El borrado de una vuelta, que es la frontera más delicada de todo el estado.
##
## Deja a cero SOLO lo de la vuelta: vida al máximo, avisos re-armados,
## decisiones políticas vacías, finales re-conquistables, tarot en posesión
## inicial (El Loco) y logros de desempeño re-bloqueados.
##
## NO toca la memoria de por vida: las cartas ya conocidas (el fantasma de las
## vueltas anteriores), la mejor racha, la dificultad, los logros de vitrina ni
## los indicadores de "alguna vez". Muta el estado recibido, como el original.
static func reiniciar_vuelta(estado: Dictionary, vida_maxima: int) -> Dictionary:
	estado["vida"] = vida_maxima
	estado["despido_mostrado"] = false
	estado["epilogo_avisado"] = false
	estado["historias_cartas"] = {}
	estado["final_politico_mostrado"] = false
	estado["final_verdadero_mostrado"] = false
	estado["perdio_vida_en_esta_vuelta"] = false
	estado[CLAVE_ELECCIONES_IDEOLOGICAS] = []
	estado[CLAVE_EXPOSICION_IDEOLOGICA] = []
	estado[CLAVE_LECTURAS_SOCIALES] = []
	# El catálogo conserva la memoria total, pero una nueva vida laboral debe
	# empezar sin hallazgos atribuidos a la vuelta anterior (#149).
	CatalogoAnomalias.reiniciar_vuelta(estado)

	for carta in estado.get("tarot", []):
		carta["recogida"] = carta["id"] == "el-loco"
		carta["gastada"] = false

	for logro in estado.get("logros", []):
		if logro.get("por_vuelta", false):
			logro["desbloqueado"] = false

	return estado


static func _lista_estado(estado: Dictionary, clave: String) -> Array:
	var valor = estado.get(clave, [])
	return valor.duplicate(true) if typeof(valor) == TYPE_ARRAY else []


static func _etiquetas_normalizadas(etiquetas: Array) -> Array:
	var normalizadas := []
	for etiqueta in etiquetas:
		var texto := String(etiqueta).strip_edges()
		if not texto.is_empty() and not normalizadas.has(texto):
			normalizadas.append(texto)
	normalizadas.sort()
	return normalizadas
