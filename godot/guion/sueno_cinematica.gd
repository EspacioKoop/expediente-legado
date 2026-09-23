## Transición espacial entre acostarse en casa y entrar en el sueño (#395).
##
## No crea una maqueta aparte: los tres planos miran la cama que ya existe en
## EspaciosCatalogo.CASA. Tras el fallo humano del 17/09, la secuencia deja
## de ser tres coordenadas estáticas y aplica la gramática de #856:
## orientar -> acción -> residuo. El cambio de fase sigue ocurriendo únicamente
## cuando el reproductor emite terminada, así que ver completa y saltar
## desembocan en el mismo estado de Jornada.
class_name SuenoCinematica
extends RefCounted

const ID := "casa-sueno"


static func planos_de(vistas: int = 0) -> Array:
	return Cinematica.resolver(planos(), {}, vistas)


## La cama de gameplay está centrada en (-2.4, 0.28, -2). La cámara conserva
## continuidad entre planos y el único cambio expresivo fuerte es un oscurecido
## progresivo al final: la cama permanece como ancla hasta casi perderse.
## No hay rótulos ni voz; la acción debe entenderse por puesta en escena.
static func planos() -> Array:
	return [
		{
			"tipo": "3d",
			"nombre": "orientar-habitacion",
			"camara_desde": Vector3(2.35, 1.65, 2.85),
			"mira_desde": Vector3(-1.10, 0.80, -1.10),
			"camara": Vector3(1.35, 1.50, 1.35),
			"mira": Vector3(-2.40, 0.58, -2.00),
			"segundos": 3.2,
		},
		{
			"tipo": "3d",
			"nombre": "acostarse",
			"camara_desde": Vector3(1.35, 1.50, 1.35),
			"mira_desde": Vector3(-2.40, 0.58, -2.00),
			"camara": Vector3(-0.15, 1.22, -0.25),
			"mira": Vector3(-2.40, 0.46, -2.00),
			"fundido_desde": 0.0,
			"fundido_hasta": 0.16,
			"sonido": "cama",
			"sonido_tono": 0.78,
			"segundos": 3.0,
		},
		{
			"tipo": "3d",
			"nombre": "residuo-cama",
			"camara_desde": Vector3(-0.15, 1.22, -0.25),
			"mira_desde": Vector3(-2.40, 0.46, -2.00),
			"camara": Vector3(-1.45, 1.02, -0.72),
			"mira": Vector3(-2.40, 0.36, -2.00),
			"fundido_desde": 0.16,
			"fundido_hasta": 0.92,
			"segundos": 2.8,
		},
	]
