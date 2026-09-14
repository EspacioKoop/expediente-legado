## Bingo diario de SIGA (#151).
##
## Este primer corte NO persiste progreso ni concede recompensas. Genera tres
## objetivos deterministas desde la semilla/día y comprueba su cumplimiento
## exclusivamente contra estado que ya existe en Partida/Jornada.
class_name BingoSiga
extends RefCounted

const CANTIDAD_OBJETIVOS := 3

const OBJETIVOS := [
	{
		"id": "leer_tres_documentos",
		"texto": "Leer al menos tres documentos durante la jornada.",
		"tipo": "productivo",
	},
	{
		"id": "cerrar_un_expediente",
		"texto": "Cerrar al menos un expediente hoy.",
		"tipo": "productivo",
	},
	{
		"id": "terminar_con_una_accion",
		"texto": "Terminar el trabajo con exactamente una acción disponible.",
		"tipo": "precision",
	},
	{
		"id": "terminar_con_dos_acciones",
		"texto": "Conservar al menos dos acciones sin utilizar.",
		"tipo": "improductivo",
	},
	{
		"id": "mantener_gato_presente",
		"texto": "Llegar al final del día con el gato todavía presente.",
		"tipo": "domestico",
	},
	{
		"id": "resolver_alquiler_si_toca",
		"texto": "Resolver el alquiler si hoy vence.",
		"tipo": "burocratico",
	},
]


static func tarjeta(estado: Dictionary) -> Array:
	var jornada: Dictionary = estado.get("jornada", {})
	var raiz := int(estado.get("semilla", 0))
	var dia := int(jornada.get("dia", 1))
	var indices := []
	for i in OBJETIVOS.size():
		indices.append(i)

	var rng := Azar.generador(raiz, "dia", [dia, 151])
	for i in range(indices.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temporal = indices[i]
		indices[i] = indices[j]
		indices[j] = temporal

	var resultado := []
	for i in mini(CANTIDAD_OBJETIVOS, indices.size()):
		resultado.append(OBJETIVOS[indices[i]].duplicate(true))
	return resultado


static func completado(objetivo_id: String, estado: Dictionary) -> bool:
	var jornada: Dictionary = estado.get("jornada", {})
	match objetivo_id:
		"leer_tres_documentos":
			return jornada.get("leido_hoy", []).size() >= 3
		"cerrar_un_expediente":
			return int(jornada.get("cerrados_hoy", 0)) >= 1
		"terminar_con_una_accion":
			return int(jornada.get("acciones", 0)) == 1
		"terminar_con_dos_acciones":
			return int(jornada.get("acciones", 0)) >= 2
		"mantener_gato_presente":
			var gato: Dictionary = jornada.get("gato", {})
			return bool(gato.get("presente", false))
		"resolver_alquiler_si_toca":
			var dia := int(jornada.get("dia", 1))
			var vencimiento := Jornada.alquiler_vencimiento(dia)
			if dia != vencimiento:
				return true
			var alquiler: Dictionary = jornada.get("alquiler", {})
			return int(alquiler.get("ultimo_resuelto", 0)) >= vencimiento
		_:
			return false


static func estado_tarjeta(estado: Dictionary) -> Array:
	var resultado := []
	for objetivo in tarjeta(estado):
		var fila: Dictionary = objetivo.duplicate(true)
		fila["completado"] = completado(String(objetivo["id"]), estado)
		resultado.append(fila)
	return resultado
