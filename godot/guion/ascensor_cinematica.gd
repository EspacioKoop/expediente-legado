## Bajada de la planta 4 al portal.
##
## No cambia de fase, no ficha y no calcula nómina: recibe el tránsito ya
## resuelto por el día y solo pone cuerpo visual a esos segundos entre archivo
## y calle. El reproductor común se ocupa de skip, reducción de movimiento y
## acortado progresivo.
class_name AscensorCinematica
extends RefCounted

const ID := "ascensor-bajada"

## La cabina vive lejos del espacio jugable ya montado. La jornada entra en
## `trayecto` antes de reproducir por seguridad de guardado; separar el set evita
## que la calle atraviese visualmente las paredes del ascensor.
const ORIGEN := Vector3(0.0, 0.0, 120.0)


static func planos_de(vistas: int = 0) -> Array:
	return Cinematica.resolver(_planos(), {}, vistas)


static func _planos() -> Array:
	return [
		{
			"tipo": "3d",
			"nombre": "planta-4",
			"segundos": 1.0,
			"camara": ORIGEN + Vector3(0.0, 0.12, 0.82),
			"mira": ORIGEN + Vector3(0.0, 0.05, -1.78),
		},
		{
			"tipo": "3d",
			"nombre": "bajada",
			"segundos": 1.1,
			"camara": ORIGEN + Vector3(0.18, 0.18, 0.72),
			"mira": ORIGEN + Vector3(1.55, 0.18, -1.42),
		},
		{
			"tipo": "3d",
			"nombre": "portal",
			"segundos": 1.0,
			"camara": ORIGEN + Vector3(0.0, 0.08, 0.45),
			"mira": ORIGEN + Vector3(0.0, -0.05, -3.75),
		},
	]
