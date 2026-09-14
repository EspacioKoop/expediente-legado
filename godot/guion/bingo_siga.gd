## Bingo diario de SIGA (#151).
##
## La tarjeta se genera de forma determinista desde semilla/día, pero una vez
## vista se conserva dentro de la propia Jornada. No escribe archivos ni concede
## recompensas: la persistencia la hereda del guardado normal de Partida.
class_name BingoSiga
extends RefCounted

const CANTIDAD_OBJETIVOS := 3
const CLAVE_ESTADO := "bingo_siga"
const DECISION_PENDIENTE := "pendiente"
const DECISION_ACEPTAR := "aceptar"
const DECISION_DESCARTAR := "descartar"
const DECISION_IGNORAR := "ignorar"
const DECISIONES_VALIDAS := [DECISION_ACEPTAR, DECISION_DESCARTAR, DECISION_IGNORAR]

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


## Generación pura. Se mantiene separada de la tarjeta persistida para poder
## reproducir una jornada desde su semilla sin alterar el estado.
static func tarjeta(estado: Dictionary) -> Array:
	var jornada: Dictionary = estado.get("jornada", {})
	var raiz := int(estado.get("semilla", jornada.get("raiz", 0)))
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


## Normaliza el contenedor persistente. Vive dentro de Jornada para viajar con
## el mismo guardado que dinero, gato, alquiler y contadores diarios.
static func _asegurar_estado(jornada: Dictionary) -> Dictionary:
	if typeof(jornada.get(CLAVE_ESTADO, null)) != TYPE_DICTIONARY:
		jornada[CLAVE_ESTADO] = {}
	var bingo: Dictionary = jornada[CLAVE_ESTADO]
	if typeof(bingo.get("actual", null)) != TYPE_DICTIONARY:
		bingo["actual"] = {}
	if typeof(bingo.get("historial", null)) != TYPE_ARRAY:
		bingo["historial"] = []
	return bingo


## Devuelve la tarjeta del día y la crea una única vez si todavía no existe.
## Recargar una partida devuelve exactamente los objetivos guardados, incluso si
## en una versión futura cambia el catálogo o su orden.
static func tarjeta_diaria(estado: Dictionary) -> Dictionary:
	if typeof(estado.get("jornada", null)) != TYPE_DICTIONARY:
		return {}
	var jornada: Dictionary = estado["jornada"]
	var bingo := _asegurar_estado(jornada)
	var dia := int(jornada.get("dia", 1))
	var actual: Dictionary = bingo["actual"]
	if int(actual.get("dia", 0)) != dia:
		actual = {
			"dia": dia,
			"decision": DECISION_PENDIENTE,
			"objetivos": tarjeta(estado),
			"completados": [],
			"cerrada": false,
		}
		bingo["actual"] = actual
	return actual


## Registra la elección de la persona jugadora. Repetir la misma llamada no
## duplica nada y una decisión válida puede corregirse mientras el día siga
## abierto; al cerrar la jornada queda congelada en el historial.
static func decidir(estado: Dictionary, decision: String) -> bool:
	if not DECISIONES_VALIDAS.has(decision):
		return false
	var actual := tarjeta_diaria(estado)
	if actual.is_empty() or bool(actual.get("cerrada", false)):
		return false
	actual["decision"] = decision
	return true


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


## Estado vivo de la tarjeta persistida. Consultarlo no vuelve a sortearla.
static func estado_tarjeta(estado: Dictionary) -> Array:
	var actual := tarjeta_diaria(estado)
	var resultado := []
	for objetivo in actual.get("objetivos", []):
		var fila: Dictionary = objetivo.duplicate(true)
		fila["completado"] = completado(String(objetivo["id"]), estado)
		resultado.append(fila)
	return resultado


## Congela el resultado del día antes de que Jornada.despertar() limpie los
## contadores. Si la tarjeta se abrió pero nunca se respondió, cerrar el día la
## registra como ignorada. Es idempotente por número de día.
static func cerrar_jornada(jornada: Dictionary) -> Dictionary:
	var bingo := _asegurar_estado(jornada)
	var actual: Dictionary = bingo["actual"]
	var dia := int(jornada.get("dia", 1))
	if actual.is_empty() or int(actual.get("dia", 0)) != dia:
		return {}

	if bool(actual.get("cerrada", false)):
		return actual
	if String(actual.get("decision", DECISION_PENDIENTE)) == DECISION_PENDIENTE:
		actual["decision"] = DECISION_IGNORAR

	var estado := {
		"semilla": int(jornada.get("raiz", 0)),
		"jornada": jornada,
	}
	var completados := []
	for objetivo in actual.get("objetivos", []):
		var objetivo_id := String(objetivo.get("id", ""))
		if completado(objetivo_id, estado):
			completados.append(objetivo_id)
	actual["completados"] = completados
	actual["cerrada"] = true

	var historial: Array = bingo["historial"]
	var reemplazado := false
	for i in historial.size():
		if int(historial[i].get("dia", 0)) == dia:
			historial[i] = actual.duplicate(true)
			reemplazado = true
			break
	if not reemplazado:
		historial.append(actual.duplicate(true))
	return actual
