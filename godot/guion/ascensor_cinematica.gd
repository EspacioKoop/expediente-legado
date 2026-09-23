## Bajada de la planta 4 al portal.
##
## No cambia de fase, no ficha y no calcula nómina: recibe el tránsito ya
## resuelto por el día y solo pone cuerpo visual a esos segundos entre archivo
## y calle. Tras el playtest de #395, la bajada aplica la gramática de #856:
## orientar -> acción -> residuo, sin tocar el guardado seguro del tránsito.
class_name AscensorCinematica
extends RefCounted

const ID := "ascensor-bajada"

## La cabina vive lejos del espacio jugable ya montado. La jornada entra en
## `trayecto` antes de reproducir por seguridad de guardado; el primer plano
## conserva un vestíbulo visual de la planta 4 para que el corte no borre de
## golpe el último referente del archivo.
const ORIGEN := Vector3(0.0, 0.0, 120.0)


static func planos_de(vistas: int = 0) -> Array:
	var planos := _planos()
	# #135: el ascensor puede encerrar una vez al jugador con alguien de la
	# oficina, pero no se convierte en un generador de encuentros. La misma cuenta
	# de vistas que acorta la cinemática decide si ese momento todavía existe;
	# saltarlo también cuenta como haberlo dejado atrás.
	if vistas == 0:
		for plano in planos:
			plano["encuentro_companero"] = "cunado"
		planos[1]["voz"] = Companeros.frase_de(Companeros.CUNADO, 1)
	return Cinematica.resolver(planos, {}, vistas)


static func _planos() -> Array:
	return [
		{
			"tipo": "3d",
			"nombre": "salida-archivo",
			"segundos": 1.7,
			"camara_desde": ORIGEN + Vector3(0.0, 0.18, 0.92),
			"mira_desde": ORIGEN + Vector3(0.0, 0.10, -3.20),
			"camara": ORIGEN + Vector3(0.0, 0.12, 0.62),
			"mira": ORIGEN + Vector3(-0.45, 0.12, -3.45),
		},
		{
			"tipo": "3d",
			"nombre": "bajada",
			"segundos": 1.4,
			"camara_desde": ORIGEN + Vector3(0.0, 0.12, 0.62),
			"mira_desde": ORIGEN + Vector3(-0.45, 0.12, -3.45),
			"camara": ORIGEN + Vector3(0.16, 0.18, 0.70),
			"mira": ORIGEN + Vector3(1.55, 0.18, -1.42),
		},
		{
			"tipo": "3d",
			"nombre": "portal",
			"segundos": 1.6,
			"camara_desde": ORIGEN + Vector3(0.16, 0.18, 0.70),
			"mira_desde": ORIGEN + Vector3(1.55, 0.18, -1.42),
			"camara": ORIGEN + Vector3(0.0, 0.08, 0.45),
			"mira": ORIGEN + Vector3(0.0, -0.05, -3.75),
		},
	]
