## Traducción pura de la política de arquetipos (#1771) a primitivas del duelo
## onírico de JuicioCombate3D.
##
## JuicioCombateArquetipos decide la intención; esta capa responde a lo que el
## host necesita saber en cada fotograma: si la figura lleva arquetipo, hacia
## dónde gira mientras guarda, si el jugador la flanquea y si un golpe concreto
## queda bloqueado. No monta nodos, no toca determinación ni consecuencias.
##
## El duelo 1 contra 1 ya representa bloqueador y hostigador. El enjambre aún no
## tiene cuerpo en la arena, pero su coordinador sí es puro: reparte los
## ataques que caben a la vez y fija el orden en que avanza cada unidad.
class_name JuicioCombateArquetipoHost
extends RefCounted

const ARQUETIPOS = preload("res://guion/juicio_combate_arquetipos.gd")

## Arquetipos que el host sabe representar. Elegir otro dejaría una política
## viva sin cuerpo que la muestre.
const SOPORTADOS := [ARQUETIPOS.BLOQUEADOR, ARQUETIPOS.HOSTIGADOR]

## Medio arco frontal de la guardia: ±60° respecto a donde mira la figura.
## Fuera de ese cono el golpe entra por el flanco.
const COSENO_ARCO_FRONTAL := 0.5

## Giro máximo mientras guarda, en rad/s. El jugador rodea a ~3 rad/s a la
## distancia de golpe del rival, así que flanquear exige moverse con intención
## pero nunca precisión extrema.
const GIRO_GUARDIA := 1.6

## Tamaño de un enjambre. Con 1 no hay turno compartido que repartir; con más de
## 3 el presupuesto deja de ser una presión legible y el enjambre se vuelve ruido.
const ENJAMBRE_MINIMO := 2
const ENJAMBRE_MAXIMO := 3

## Estados que ocupan un hueco del presupuesto compartido: avisar y golpear. La
## lista sale de la política para que el contador y `cuenta_presupuesto` no
## puedan discrepar sobre qué cuenta como atacante.
const ESTADOS_ATACANTE := [ARQUETIPOS.TELEGRAFIAR, ARQUETIPOS.ATACAR]


## Arquetipo de una figura onírica concreta, estable para la misma partida.
##
## Solo el plano del sueño recibe arquetipos: la realidad y la ventanilla ritual
## conservan su duelo clásico. Una figura sin id tampoco se inventa uno.
static func elegir(id_figura: String, raiz: int, plano: String) -> String:
	var id := id_figura.strip_edges()
	if plano != CombateContextual.PLANO_SUENO or id.is_empty():
		return ""
	# Se conserva la asignación histórica de bloqueadores (todas las tiradas
	# pares); entre las antiguas figuras clásicas, una mitad pasa a hostigador.
	var tirada := Azar.derivar_texto(raiz, "combate", "arquetipo_1771:%s" % id)
	# Conservar exactamente todos los bloqueadores ya asignados (tirada par) y
	# convertir solo la mitad del antiguo duelo clásico en hostigador.
	if tirada % 2 == 0:
		return ARQUETIPOS.BLOQUEADOR
	if tirada % 4 == 1:
		return ARQUETIPOS.HOSTIGADOR
	return ""


static func soportado(tipo: String) -> bool:
	return SOPORTADOS.has(tipo)


static func flanqueado(
	posicion_rival: Vector3, rotacion_y_rival: float, posicion_jugador: Vector3
) -> bool:
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return false
	var frente := Vector3(sin(rotacion_y_rival), 0.0, cos(rotacion_y_rival))
	return frente.dot(hacia.normalized()) < COSENO_ARCO_FRONTAL


## Contexto que JuicioCombateArquetipos.avanzar espera para el bloqueador.
static func contexto(
	posicion_rival: Vector3,
	rotacion_y_rival: float,
	posicion_jugador: Vector3,
	guardia_rota: bool,
) -> Dictionary:
	return {
		"flanqueado": flanqueado(posicion_rival, rotacion_y_rival, posicion_jugador),
		"guardia_rota": guardia_rota,
	}


## Orientación tras un fotograma. La figura sigue al jugador a ritmo limitado,
## salvo en la apertura: ahí se queda mirando donde estaba para que la ventana
## sea legible. Recuperar también gira; si no, quien se planta a la espalda
## volvería a encontrar la guardia de cara a la nada y la tendría abierta para
## siempre.
static func girar(
	unidad: Dictionary,
	rotacion_y_rival: float,
	posicion_rival: Vector3,
	posicion_jugador: Vector3,
	delta: float,
) -> float:
	if String(unidad.get("tipo", "")) != ARQUETIPOS.BLOQUEADOR:
		return rotacion_y_rival
	if String(unidad.get("estado", "")) == ARQUETIPOS.APERTURA:
		return rotacion_y_rival
	var hacia := posicion_jugador - posicion_rival
	hacia.y = 0.0
	if hacia.length() < 0.01:
		return rotacion_y_rival
	var objetivo := atan2(hacia.x, hacia.z)
	var diferencia := wrapf(objetivo - rotacion_y_rival, -PI, PI)
	var paso := GIRO_GUARDIA * maxf(0.0, delta)
	return rotacion_y_rival + clampf(diferencia, -paso, paso)


## Qué hace la guardia con un golpe que ya alcanza a la figura.
##
## Un golpe fuerte de frente no hace daño pero rompe la guardia: es la vía
## para no tener que esperar ni rodear. Por el flanco, o fuera de la guardia,
## el golpe entra como en el duelo clásico.
static func golpe(unidad: Dictionary, flanco: bool, fuerte: bool) -> Dictionary:
	var resultado := {"bloqueado": false, "rompe_guardia": false}
	if String(unidad.get("tipo", "")) != ARQUETIPOS.BLOQUEADOR:
		return resultado
	if String(unidad.get("estado", "")) != ARQUETIPOS.GUARDIA or flanco:
		return resultado
	resultado["bloqueado"] = true
	resultado["rompe_guardia"] = fuerte
	return resultado


## La apertura es la ventana del jugador: mientras dura, la figura no empieza
## un ataque propio. En guardia y recuperación sí puede, como el rival clásico.
static func permite_iniciar_ataque(unidad: Dictionary) -> bool:
	var tipo := String(unidad.get("tipo", ""))
	# El hostigador dispara por su propia línea telegrafiada; nunca debe caer en
	# el ataque cuerpo a cuerpo genérico del rival.
	if tipo == ARQUETIPOS.HOSTIGADOR:
		return false
	if tipo != ARQUETIPOS.BLOQUEADOR:
		return true
	return String(unidad.get("estado", "")) != ARQUETIPOS.APERTURA


## Contexto que JuicioCombateArquetipos.avanzar espera para el hostigador:
## distancia en plano y rumbo hacia el jugador, con la misma convención de
## `girar` (0 mira hacia +Z). Con distancia casi cero no hay rumbo legible:
## se fija 0.0 para que la política tenga un valor estable sin NaN ni tirones.
static func contexto_hostigador(
	posicion_hostigador: Vector3,
	posicion_jugador: Vector3,
) -> Dictionary:
	var hacia := posicion_jugador - posicion_hostigador
	hacia.y = 0.0
	var distancia := hacia.length()
	var rumbo := 0.0
	if distancia >= 0.01:
		rumbo = atan2(hacia.x, hacia.z)
	return {"distancia": distancia, "rumbo_objetivo": rumbo}


## Dirección 3D de la línea de ataque a partir de un rumbo congelado. Durante
## `telegrafiar` la política congela `rumbo_bloqueado`, así que la línea debe
## salir solo de ese ángulo: si el jugador se mueve después, la línea no gira.
static func direccion_linea(rumbo_bloqueado: float) -> Vector3:
	return Vector3(sin(rumbo_bloqueado), 0.0, cos(rumbo_bloqueado))


## Comprueba un impacto contra el segmento de disparo congelado. La anchura es
## deliberadamente generosa para que el reto sea leer la línea y salir de ella,
## no acertar un píxel. Solo usa geometría plana; el host decide después cómo
## resolver esquiva, invulnerabilidad y doctrinas.
static func impacto_linea(
	origen: Vector3,
	rumbo_bloqueado: float,
	objetivo: Vector3,
	alcance: float,
	radio: float,
) -> bool:
	if alcance <= 0.0 or radio < 0.0:
		return false
	var direccion := direccion_linea(rumbo_bloqueado)
	var relativo := objetivo - origen
	relativo.y = 0.0
	var avance := relativo.dot(direccion)
	if avance < 0.0 or avance > alcance:
		return false
	var lateral := relativo - direccion * avance
	return lateral.length() <= radio


## Tamaño de enjambre seguro para un requisito del host. Una arena que no pide
## ninguno arranca en el mínimo; una que pide más se recorta al máximo porque un
## presupuesto de tres ataques simultáneos dejaría de leerse como presión.
static func tamano_enjambre(cantidad: int = ENJAMBRE_MINIMO) -> int:
	if cantidad < ENJAMBRE_MINIMO:
		return ENJAMBRE_MINIMO
	return mini(cantidad, ENJAMBRE_MAXIMO)


## Presupuesto de ataques simultáneos. Un valor menor que uno haría que la
## política elevase el suelo por su cuenta; aquí se respeta el mínimo de uno y
## se descarta cualquier sobra.
static func presupuesto_enjambre(presupuesto: int = ARQUETIPOS.ENJAMBRE_PRESUPUESTO_ATAQUES) -> int:
	return mini(maxi(1, presupuesto), ARQUETIPOS.ENJAMBRE_PRESUPUESTO_ATAQUES)


## Estados de un enjambre recién creado. Determinista: la misma raíz produce el
## mismo grupo, y el índice distingue a cada unidad dentro de él. Cada estado es
## una copia propia, para que avanzar una nunca altere a sus hermanas.
static func nuevo_enjambre(raiz: int, cantidad: int = ENJAMBRE_MINIMO) -> Array:
	var unidades := []
	for indice in range(tamano_enjambre(cantidad)):
		unidades.append(ARQUETIPOS.nuevo(ARQUETIPOS.ENJAMBRE, raiz, indice))
	return unidades


## Un fotograma del enjambre completo. Devuelve estados y resultados nuevos; el
## array recibido no se muta.
##
## Los atacantes se cuentan una sola vez al abrir el tick y el contador se ajusta
## en local según lo que devuelve cada unidad. Sin ese ajuste, dos huecos libres
## al empezar el tick dejarían arrancar a tres unidades: las dos primeras no se
## verían reflejadas hasta que la tercera ya habría leído el presupuesto intacto.
static func avanzar_enjambre(
	unidades: Array, delta: float, presupuesto: int = ARQUETIPOS.ENJAMBRE_PRESUPUESTO_ATAQUES
) -> Dictionary:
	var maximo := presupuesto_enjambre(presupuesto)
	var atacantes := ARQUETIPOS.cuenta_presupuesto(unidades)
	var nuevos := []
	var resultados := []
	for unidad in unidades:
		var paso := ARQUETIPOS.avanzar(
			unidad, delta, {"atacantes_activos": atacantes, "presupuesto_ataques": maximo}
		)
		var estado: Dictionary = paso.get("unidad", {})
		nuevos.append(estado)
		resultados.append(paso)
		atacantes += _delta_atacante(unidad, estado)
	return {"unidades": nuevos, "resultados": resultados, "atacantes_activos": atacantes}


## Cuántos atacantes gana o pierde una unidad al pasar de un estado a otro.
static func _delta_atacante(anterior: Dictionary, nuevo: Dictionary) -> int:
	var antes := 1 if String(anterior.get("estado", "")) in ESTADOS_ATACANTE else 0
	var despues := 1 if String(nuevo.get("estado", "")) in ESTADOS_ATACANTE else 0
	return despues - antes
