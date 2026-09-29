## Dos superficies cotidianas del mismo hecho de #922, sin crear estado paralelo (#1883).
##
## La capa conserva separado el hecho base del tratamiento que ve el jugador. Registrar
## una exposición delega siempre en Prometeo/#919: leer una circular o un aviso no es
## elegir una ideología ni altera expedientes, economía o doctrinas.
class_name IdeologiaCulturaCotidiana1883
extends RefCounted

const EVENTO_BASE := "turnos-atencion-planta4"
const SUPERFICIE_CIRCULAR := "circular_oficina"
const SUPERFICIE_POSTAL := "aviso_postal"

const SUPERFICIES := {
	SUPERFICIE_CIRCULAR:
	{
		"evento_base": EVENTO_BASE,
		"id": "institucional:oficina:turnos-atencion-planta4",
		"fuente": "institucional:oficina:tablon",
		"eje": "centrista",
		"etiqueta": "tablón: circular de horario",
		"tratamiento":
		(
			"Circular interna: la planta 4 amplía treinta minutos la atención de tarde "
			+ "durante dos semanas. Tras la primera semana se recogerá una evaluación "
			+ "escrita."
		),
		"datos_destacados": ["duracion", "franja", "seguimiento"],
	},
	SUPERFICIE_POSTAL:
	{
		"evento_base": EVENTO_BASE,
		"id": "cotidiano:postal:turnos-atencion-planta4",
		"fuente": "correo_postal:aviso_horario_planta4",
		"eje": "socialdemocrata",
		"etiqueta": "Aviso de atención al público",
		"tratamiento":
		(
			"Aviso informativo: la atención vespertina de la planta 4 se amplía treinta "
			+ "minutos durante una prueba de dos semanas. La medida afecta a catorce "
			+ "puestos y tendrá revisión escrita."
		),
		"datos_destacados": ["franja", "duracion", "plantilla", "seguimiento"],
	},
}


static func superficie(id_superficie: String) -> Dictionary:
	var datos = SUPERFICIES.get(id_superficie, {})
	if typeof(datos) != TYPE_DICTIONARY:
		return {}
	return (datos as Dictionary).duplicate(true)


static func pieza_postal() -> Dictionary:
	var tratamiento := superficie(SUPERFICIE_POSTAL)
	return {
		"id": "aviso_horario_planta4",
		"categoria": "notificacion",
		"remitente": "DGAI · Información",
		"asunto": String(tratamiento.get("etiqueta", "")),
		"contenido": String(tratamiento.get("tratamiento", "")),
		"dias": [1],
		"ideologia_superficie_id": SUPERFICIE_POSTAL,
		"evento_base": EVENTO_BASE,
	}


static func registrar_exposicion(estado: Dictionary, id_superficie: String, jornada: int) -> bool:
	var datos := superficie(id_superficie)
	if datos.is_empty():
		return false
	return (
		Prometeo
		. registrar_exposicion_ideologica(
			estado,
			String(datos.get("id", "")),
			String(datos.get("fuente", "")),
			String(datos.get("eje", "")),
			jornada,
			["cultura_cotidiana", EVENTO_BASE, id_superficie],
		)
	)
