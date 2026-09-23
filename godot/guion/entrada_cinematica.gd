## La entrada: lo primero que se ve de una vida laboral.
##
## Tiene que dejar tres cosas puestas antes de que nadie lea nada: que esto es
## una **copia restaurada** de un sistema de los noventa, que **tú eres el
## auditor** que la abre, y que **nadie más va a mirar**. Desde #395 ya no lo
## cuenta con cuatro tarjetas separadas: rueda dentro de la oficina real que el
## jugador va a recorrer inmediatamente después.
##
## Tras el playtest humano del 17/09/2026 y la síntesis de #177/#856, los cuatro
## planos dejan de ser coordenadas de bloqueo independientes. Forman una sola
## frase visual: **orientar -> acercar al puesto -> identificar -> residuo**.
## `camara_desde`/`mira_desde` solo describen el recorrido de cámara; con
## reducción de movimiento el reproductor usa la composición final estática.
##
## **Se ve cada vuelta** (decisión de #68). Cada reasignación vuelve a entrar
## por la puerta y la copia está un poco peor. El reproductor la acorta a partir
## de la segunda vista (#67), así que la repetición sigue funcionando como reloj
## del juego sin volver a convertir la entrada en una avalancha de inserts.
class_name EntradaCinematica
extends RefCounted

## Con qué nombre lleva el reproductor la cuenta de veces vista.
const ID := "entrada"

## El usuario del jugador. Es el mismo que ya usa el archivo.
const USUARIO := "auditor01"

## Una línea de restauración por vuelta. La última se mantiene para siempre.
const REGISTRO_POR_VUELTA := [
	"ENTRADA_COPIA_INTEGRA",
	"ENTRADA_COPIA_SECTORES",
	"ENTRADA_COPIA_INDICES",
	"ENTRADA_COPIA_SIN_CUENTA",
]


## El plano de rodaje de esta vuelta, ya traducido y acortado si procede.
static func planos_de(vistas: int = 0) -> Array:
	return Cinematica.resolver(planos(vistas), {"usuario": USUARIO}, vistas)


## Los cuatro momentos ocurren dentro de la oficina montada por gameplay. Las
## coordenadas apuntan a elementos que ya existen en `EspaciosCatalogo.OFICINA`:
## entrada, puesto propio, terminal real del puesto y pared de archivadores. No
## se duplica una maqueta cinematográfica ni se añade geometría exclusiva.
static func planos(vistas: int = 0) -> Array:
	return [
		{
			# ORIENTAR. Empieza pegado al punto de entrada y avanza lo justo para
			# que la oficina tenga profundidad antes de dirigir la mirada al puesto.
			"tipo": "3d",
			"nombre": "umbral",
			"camara_desde": Vector3(0.05, 1.70, 3.35),
			"mira_desde": Vector3(-0.8, 1.10, 0.4),
			"camara": Vector3(-0.65, 1.68, 2.55),
			"mira": Vector3(-3.8, 1.00, 0.75),
			"segundos": 3.8,
			"sonido": "puerta_abre",
			"rotulo": "ENTRADA_RESTAURANDO",
			"voz": registro_de(vistas),
		},
		{
			# ACCIÓN. El plano recoge la dirección del anterior y termina sobre el
			# ordenador REAL del puesto del jugador (-4, 1), no sobre el terminal
			# de la mesa vecina que usaba el bloqueo antiguo.
			"tipo": "3d",
			"nombre": "terminal",
			"camara_desde": Vector3(-1.15, 1.62, 2.15),
			"mira_desde": Vector3(-3.7, 1.00, 1.00),
			"camara": Vector3(-2.70, 1.38, 1.55),
			"mira": Vector3(-4.0, 0.98, 0.68),
			"segundos": 3.4,
			"sonido": "pulsar",
			"rotulo": "ENTRADA_SISTEMA",
			"voz": "ENTRADA_VOZ_VOLUMEN",
		},
		{
			# IDENTIFICAR. Sin saltar a otro rincón de la sala: desde el terminal
			# se abre un poco el encuadre para incluir silla + puesto mientras el
			# sistema acredita al usuario. La continuidad espacial hace el trabajo
			# que antes recaía en una tarjeta aislada.
			"tipo": "3d",
			"nombre": "auditor",
			"camara_desde": Vector3(-2.70, 1.38, 1.55),
			"mira_desde": Vector3(-4.0, 0.98, 0.68),
			"camara": Vector3(-2.05, 1.58, 2.35),
			"mira": Vector3(-4.0, 0.82, 1.05),
			"segundos": 3.0,
			"sonido": "marcar",
			"rotulo": "ENTRADA_AUDITOR",
			"voz": "ENTRADA_VOZ_TURNO",
		},
		{
			# RESIDUO. Un desplazamiento lateral lento deja la masa de archivadores
			# ocupando el final de la secuencia antes de devolver el control.
			"tipo": "3d",
			"nombre": "archivo",
			"camara_desde": Vector3(1.55, 1.62, 2.65),
			"mira_desde": Vector3(5.45, 1.00, 0.75),
			"camara": Vector3(2.55, 1.62, 2.95),
			"mira": Vector3(5.45, 1.00, -1.10),
			"segundos": 3.6,
			"rotulo": "ENTRADA_NADIE_MIRA",
			"voz": "ENTRADA_VOZ_SOLO",
		},
	]


## Qué dice el registro de restauración en esta vuelta. La serie se agota en su
## última línea en vez de volver a "copia íntegra".
static func registro_de(vistas: int) -> String:
	var cual := clampi(vistas, 0, REGISTRO_POR_VUELTA.size() - 1)
	return REGISTRO_POR_VUELTA[cual]
