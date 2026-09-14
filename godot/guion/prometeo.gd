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

	for carta in estado.get("tarot", []):
		carta["recogida"] = carta["id"] == "el-loco"
		carta["gastada"] = false

	for logro in estado.get("logros", []):
		if logro.get("por_vuelta", false):
			logro["desbloqueado"] = false

	return estado
