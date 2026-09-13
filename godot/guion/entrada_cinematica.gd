## La entrada: lo primero que se ve de una vida laboral.
##
## Tiene que dejar tres cosas puestas antes de que nadie lea nada: que esto es
## una **copia restaurada** de un sistema de los noventa, que **tú eres el
## auditor** que la abre, y que **nadie más va a mirar**. Desde #395 ya no lo
## cuenta con cuatro tarjetas separadas: rueda dentro de la oficina real que el
## jugador va a recorrer inmediatamente después.
##
## Los encuadres son deliberadamente de bloqueo. #398/#399 pueden mover arte,
## materiales e identidad espacial sin cambiar este contrato: cuatro planos 3D,
## mismo texto/voz, mismo contador de vistas, mismo skip y mismo estado final.
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
## entrada/puestos, terminal propio y pared de archivadores. No se duplica una
## maqueta cinematográfica ni se añade geometría exclusiva para estos planos.
static func planos(vistas: int = 0) -> Array:
	return [
		{
			# Primer contacto: desde el umbral se ve que se ha entrado en un
			# archivo físico, no en otra tarjeta de carga.
			"tipo": "3d",
			"nombre": "umbral",
			"camara": Vector3(0.3, 1.70, 4.15),
			"mira": Vector3(-2.4, 1.05, -0.6),
			"segundos": 3.0,
			"rotulo": "ENTRADA_RESTAURANDO",
			"voz": registro_de(vistas),
		},
		{
			# El terminal SIGA del puesto propio. La máquina y la oficina son las
			# mismas que quedan disponibles al recuperar el control.
			"tipo": "3d",
			"nombre": "terminal",
			"camara": Vector3(-2.55, 1.42, -0.35),
			"mira": Vector3(-4.30, 1.00, -2.10),
			"segundos": 3.2,
			"rotulo": "ENTRADA_SISTEMA",
			"voz": "ENTRADA_VOZ_VOLUMEN",
		},
		{
			# Identidad: el mismo puesto, visto desde el pasillo de trabajo. No
			# aparece una ficha flotante que rompa la continuidad espacial.
			"tipo": "3d",
			"nombre": "auditor",
			"camara": Vector3(-1.75, 1.65, 2.20),
			"mira": Vector3(-4.15, 1.00, -1.65),
			"segundos": 3.0,
			"rotulo": "ENTRADA_AUDITOR",
			"voz": "ENTRADA_VOZ_TURNO",
		},
		{
			# Remate: el archivo y sus armarios ocupan el plano. La frase sigue
			# hablando de acceso al volumen, no de que la oficina esté vacía.
			"tipo": "3d",
			"nombre": "archivo",
			"camara": Vector3(2.45, 1.65, 3.05),
			"mira": Vector3(5.45, 1.00, -1.15),
			"segundos": 3.4,
			"rotulo": "ENTRADA_NADIE_MIRA",
			"voz": "ENTRADA_VOZ_SOLO",
		},
	]


## Qué dice el registro de restauración en esta vuelta. La serie se agota en su
## última línea en vez de volver a "copia íntegra".
static func registro_de(vistas: int) -> String:
	var cual := clampi(vistas, 0, REGISTRO_POR_VUELTA.size() - 1)
	return REGISTRO_POR_VUELTA[cual]
