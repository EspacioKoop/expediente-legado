## Transición espacial entre acostarse en casa y entrar en el sueño (#395).
##
## No crea una maqueta aparte: los tres planos miran la cama que ya existe en
## `EspaciosCatalogo.CASA`. El cambio de fase ocurre después, cuando el
## reproductor emite `terminada`; por eso ver la secuencia completa y saltarla
## desembocan en el mismo estado de Jornada.
class_name SuenoCinematica
extends RefCounted

const ID := "casa-sueno"


static func planos_de(vistas: int = 0) -> Array:
	return Cinematica.resolver(planos(), {}, vistas)


## La cama de gameplay está centrada en (-2.4, 0.28, -2). Los encuadres se
## acercan desde la habitación hasta el borde del colchón para que el corte al
## primer espacio onírico se lea como una transición y no como un teletransporte.
## No hay rótulos ni voz: #395 pide continuidad espacial, no exposición nueva.
static func planos() -> Array:
	return [
		{
			"tipo": "3d",
			"nombre": "casa",
			"camara": Vector3(1.80, 1.55, 2.20),
			"mira": Vector3(-2.40, 0.55, -2.00),
			"segundos": 2.6,
		},
		{
			"tipo": "3d",
			"nombre": "acercamiento",
			"camara": Vector3(0.00, 1.30, -0.20),
			"mira": Vector3(-2.40, 0.48, -2.00),
			"segundos": 2.8,
		},
		{
			"tipo": "3d",
			"nombre": "cama",
			"camara": Vector3(-1.45, 1.05, -0.70),
			"mira": Vector3(-2.40, 0.38, -2.00),
			"segundos": 2.4,
		},
	]
