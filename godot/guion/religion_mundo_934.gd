## Primer contrato de mundo físico para religión (#934).
##
## Este corte es deliberadamente no confesional: prueba cómo una superficie
## material y una práctica comunitaria ambigua atraviesan ReligionEventos sin
## convertir participación en convicción. Las tradiciones vivas concretas se
## añadirán únicamente cuando exista documentación específica.
class_name ReligionMundo934
extends RefCounted

const ID_ACTO_MEMORIA := "acto_memoria_vecinal"
const DIA_ACTO_MEMORIA := 3

const SUPERFICIES := [
	{
		"id": "tablon_calendario",
		"espacio": "sala_comunitaria",
		"funcion": "exposicion",
		"fuente": "mundo:tablon_calendario_98",
		"materiales": ["corcho", "papel", "madera"],
	},
	{
		"id": "mesa_recuerdo",
		"espacio": "sala_comunitaria",
		"funcion": "practica",
		"fuente": "mundo:mesa_recuerdo_98",
		"materiales": ["madera", "papel"],
	},
]

const CALENDARIO := [
	{
		"id": ID_ACTO_MEMORIA,
		"dia": DIA_ACTO_MEMORIA,
		"fuente": "calendario:tablon_comunitario_98",
		"espacio": "sala_comunitaria",
		"tipo": "memoria_comunitaria",
	},
]

const PRACTICAS := {
	"silencio_memoria":
	{
		"actividad": ID_ACTO_MEMORIA,
		"fuente": "mundo:mesa_recuerdo_98",
		"contexto": "sala_comunitaria:acto_memoria",
		"etiquetas": ["duelo_memoria", "participacion_ambigua", "presencial", "voluntario"],
	}
}


static func superficies() -> Array:
	return SUPERFICIES.duplicate(true)


static func eventos_calendario(dia: int) -> Array:
	var resultado := []
	for actividad in CALENDARIO:
		var entrada: Dictionary = actividad
		if int(entrada["dia"]) == dia:
			resultado.append(entrada.duplicate(true))
	return resultado


static func actividad_disponible(id_actividad: String, dia: int) -> bool:
	for actividad in eventos_calendario(dia):
		if String(actividad.get("id", "")) == id_actividad:
			return true
	return false


static func registrar_exposicion(
	registro: Dictionary, id_superficie: String, dia: int, vuelta: int = 0
) -> bool:
	var superficie := _superficie(id_superficie)
	if superficie.is_empty():
		return false
	var etiquetas := ["cultura_material"]
	for actividad in eventos_calendario(dia):
		etiquetas.append("fuente_calendario:%s" % String(actividad["fuente"]))
	var evento := ReligionEventos.crear_evento(
		"exposicion:%s:vuelta:%d:jornada:%d" % [id_superficie, vuelta, dia],
		ReligionEventos.CANAL_EXPOSICION,
		String(superficie["fuente"]),
		String(superficie["espacio"]),
		dia,
		"",
		etiquetas,
		[],
		false,
		[],
		{"vuelta": vuelta, "procedencia": "mundo:interaccion:examinar"}
	)
	return ReligionEventos.registrar(registro, evento)


static func registrar_practica(
	registro: Dictionary, id_practica: String, dia: int, vuelta: int = 0
) -> bool:
	var practica: Dictionary = PRACTICAS.get(id_practica, {})
	if practica.is_empty():
		return false
	var actividad := String(practica["actividad"])
	if not actividad_disponible(actividad, dia):
		return false
	var fuente_calendario := ""
	for entrada in eventos_calendario(dia):
		if String(entrada.get("id", "")) == actividad:
			fuente_calendario = String(entrada.get("fuente", ""))
			break
	var etiquetas: Array = practica["etiquetas"].duplicate()
	if not fuente_calendario.is_empty():
		etiquetas.append("fuente_calendario:%s" % fuente_calendario)
	var evento := ReligionEventos.crear_evento(
		"practica:%s:vuelta:%d:jornada:%d" % [id_practica, vuelta, dia],
		ReligionEventos.CANAL_PRACTICA,
		String(practica["fuente"]),
		String(practica["contexto"]),
		dia,
		"",
		etiquetas,
		[],
		false,
		[],
		{"vuelta": vuelta, "procedencia": "mundo:interaccion:participar"}
	)
	return ReligionEventos.registrar(registro, evento)


static func _superficie(id_superficie: String) -> Dictionary:
	for superficie in SUPERFICIES:
		var entrada: Dictionary = superficie
		if String(entrada["id"]) == id_superficie:
			return entrada.duplicate(true)
	return {}
