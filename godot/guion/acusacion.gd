## Acusar y cerrar un expediente.
##
## Es la pieza que estaban esperando dos sistemas: sin ella no se puede cerrar
## nada, así que `cerrados_hoy` era siempre cero y la nómina pagaba solo la
## base.
##
## Tres reglas que no son detalles:
##
## - **No hay sospechoso correcto.** El expediente se cierra igual a quien
##   acuses, y cada sospechoso trae su propio desenlace. Lo que el juego
##   registra no es un acierto, es una firma.
## - **El sistema no sabe si acertaste, pero sí sabe si miraste.** Acusar con
##   menos evidencia de la que pide la dificultad es una acusación precipitada:
##   **paga lo mismo** —la nómina no distingue— y te cuesta una vida. El castigo
##   es personal, nunca económico.
## - **Es irreversible.** Un veredicto por expediente, para siempre. Puedes
##   dormir un caso indefinidamente y volver mañana; lo que no puedes es
##   deshacer una firma.
class_name Acusacion
extends RefCounted

## Vidas y exigencia de evidencia por dificultad, tal como estaban en
## `prometeo-ui.js`.
const DIFICULTADES := {
	"facil": {"vidas": 5, "umbral": 0.4},
	"normal": {"vidas": 3, "umbral": 0.6},
	"dificil": {"vidas": 2, "umbral": 0.75},
}

const CLAVE_DESPIDO_PENDIENTE := "despido_pendiente"


static func ajustes(estado: Dictionary) -> Dictionary:
	return DIFICULTADES.get(estado.get("dificultad", "normal"), DIFICULTADES["normal"])


## Cambiar dificultad es una acción explícita de configuración de la partida,
## no una preferencia de interfaz. Como en el legado, bajar el máximo recorta
## vidas actuales pero subirlo nunca cura. Devuelve solo cartas recién ganadas
## para que la capa que originó el evento pueda reaccionar si lo necesita.
static func cambiar_dificultad(estado: Dictionary, nueva: String) -> Array:
	if not DIFICULTADES.has(nueva):
		return []
	var vidas_maximas := int(DIFICULTADES[nueva]["vidas"])
	estado["dificultad"] = nueva
	estado["vida"] = mini(int(estado.get("vida", vidas_maximas)), vidas_maximas)
	return Prometeo.sincronizar_tarot_por_dificultad(estado)


## El veredicto firmado en un expediente, o cadena vacía si sigue abierto.
static func veredicto_de(estado: Dictionary, caso_id: String) -> String:
	return estado.get("veredictos", {}).get(caso_id, "")


static func esta_cerrado(estado: Dictionary, caso_id: String) -> bool:
	return not veredicto_de(estado, caso_id).is_empty()


## Firma la acusación.
##
## Devuelve qué ha pasado, con todo lo que la pantalla necesita contar. El
## desenlace lo trae el propio sospechoso: no se compone aquí, porque es
## contenido y no regla.
static func acusar(
	estado: Dictionary,
	jornada: Dictionary,
	caso: Dictionary,
	sospechoso: Dictionary,
	descubiertas: Array
) -> Dictionary:
	var caso_id: String = caso["id"]
	if esta_cerrado(estado, caso_id):
		return {"resultado": "ya_cerrado"}

	# Cerrar compite con leer uno más, que es la tensión del día: ¿sigo
	# investigando o firmo y cobro?
	if not Jornada.gastar_accion(jornada):
		return {"resultado": "sin_acciones"}

	var veredictos: Dictionary = estado.get("veredictos", {})
	veredictos[caso_id] = sospechoso["id"]
	estado["veredictos"] = veredictos

	# #1029: el primer veredicto real re-gana El Hierofante en esta vuelta.
	# Vive aquí, junto a la firma irreversible, para que cargar/abrir UI nunca
	# fabrique la recompensa a posteriori.
	var cartas_desbloqueadas := []
	if Prometeo.desbloquear_carta_en_estado(estado, "el-hierofante"):
		cartas_desbloqueadas.append("el-hierofante")

	jornada["cerrados_hoy"] += 1

	var pistas: Array = caso.get("pistas", [])
	var encontradas := pistas.filter(func(p): return descubiertas.has(p["id"])).size()
	var precipitada := Prometeo.acusacion_precipitada(
		encontradas, pistas.size(), ajustes(estado)["umbral"]
	)

	var castigo := {}
	if precipitada:
		jornada["acusaciones_precipitadas_hoy"] = (
			int(jornada.get("acusaciones_precipitadas_hoy", 0)) + 1
		)
		castigo = perder_vida(estado, jornada, 1)
		for carta_id in castigo.get("cartas_desbloqueadas", []):
			cartas_desbloqueadas.append(carta_id)

	return {
		"resultado": "cerrado",
		"sospechoso": sospechoso["nombre"],
		"desenlace": sospechoso.get("desenlace", ""),
		"precipitada": precipitada,
		"evidencia": [encontradas, pistas.size()],
		"vida": estado["vida"],
		"despido": castigo.get("despido", false),
		"despido_pendiente": castigo.get("despido_pendiente", false),
		"cartas_desbloqueadas": cartas_desbloqueadas,
		# Un sospechoso con réplicas escritas no se deja acusar sin más: hay
		# careo. El duelo NO cambia el veredicto —ya está firmado— pero perderlo
		# cuesta una vida, así que es una escena con algo en juego.
		"duelo": sospechoso if not sospechoso.get("ataques", []).is_empty() else {},
	}


## Quita vidas y conserva la frontera de último recurso al llegar a cero.
##
## Llegar a cero es una pérdida real de vida (y por tanto puede conceder
## El Ermitaño), pero NO es todavía un despido. El estado queda persistible
## con una única decisión pendiente hasta que el jugador canjee o firme el cese.
static func perder_vida(estado: Dictionary, _jornada: Dictionary, cuantas: int) -> Dictionary:
	if despido_pendiente(estado):
		return {
			"despido": false,
			"despido_pendiente": true,
			"vida": 0,
			"cartas_desbloqueadas": [],
		}

	var vida_anterior := int(estado.get("vida", 3))
	estado["vida"] = maxi(0, vida_anterior - maxi(0, cuantas))
	var cartas_desbloqueadas := []
	if estado["vida"] < vida_anterior:
		# #1029/#46: El Ermitaño se re-gana por perder vida en ESTA vuelta.
		# La pérdida real es el emisor común para acusación, careo y otros daños.
		estado["perdio_vida_en_esta_vuelta"] = true
		if Prometeo.desbloquear_carta_en_estado(estado, "el-ermitanio"):
			cartas_desbloqueadas.append("el-ermitanio")

	if estado["vida"] > 0:
		return {
			"despido": false,
			"despido_pendiente": false,
			"vida": estado["vida"],
			"cartas_desbloqueadas": cartas_desbloqueadas,
		}

	estado[CLAVE_DESPIDO_PENDIENTE] = true
	return {
		"despido": false,
		"despido_pendiente": true,
		"vida": 0,
		"cartas_desbloqueadas": cartas_desbloqueadas,
	}


## La frontera pendiente es estado de partida, no estado de una pantalla. Así
## cerrar y volver a abrir el juego conserva exactamente la misma decisión.
static func despido_pendiente(estado: Dictionary) -> bool:
	return bool(estado.get(CLAVE_DESPIDO_PENDIENTE, false)) and int(estado.get("vida", 0)) == 0


## Ids de cartas que pueden salvar esta vuelta. Es una consulta pura para que
## cualquier UI pinte exactamente la misma elegibilidad que valida el canje.
static func cartas_canjeables(estado: Dictionary) -> Array:
	if not despido_pendiente(estado):
		return []
	var ids := []
	var tarot_bruto = estado.get("tarot", [])
	if typeof(tarot_bruto) != TYPE_ARRAY:
		return ids
	for bruto in tarot_bruto:
		if typeof(bruto) != TYPE_DICTIONARY:
			continue
		var carta: Dictionary = bruto
		if bool(carta.get("recogida", false)) and not bool(carta.get("gastada", false)):
			ids.append(String(carta.get("id", "")))
	return ids


## Canje real de último recurso. No deriva Templanza de una carta ya gastada al
## cargar: solo este evento explícito puede concederla.
static func canjear_carta_por_vida(estado: Dictionary, carta_id: String) -> Dictionary:
	if not despido_pendiente(estado) or carta_id.is_empty():
		return {
			"resultado": "rechazado",
			"despido": false,
			"despido_pendiente": despido_pendiente(estado),
			"vida": int(estado.get("vida", 0)),
			"cartas_desbloqueadas": [],
		}

	var elegida: Dictionary = {}
	var tarot_bruto = estado.get("tarot", [])
	if typeof(tarot_bruto) == TYPE_ARRAY:
		for bruto in tarot_bruto:
			if typeof(bruto) != TYPE_DICTIONARY:
				continue
			var carta: Dictionary = bruto
			if String(carta.get("id", "")) == carta_id:
				elegida = carta
				break

	if (
		elegida.is_empty()
		or not bool(elegida.get("recogida", false))
		or bool(elegida.get("gastada", false))
	):
		return {
			"resultado": "rechazado",
			"despido": false,
			"despido_pendiente": true,
			"vida": 0,
			"cartas_desbloqueadas": [],
		}

	elegida["gastada"] = true
	estado["vida"] = 1
	estado[CLAVE_DESPIDO_PENDIENTE] = false
	var cartas_desbloqueadas := []
	if Prometeo.desbloquear_carta_en_estado(estado, "la-templanza"):
		cartas_desbloqueadas.append("la-templanza")
	return {
		"resultado": "canje",
		"despido": false,
		"despido_pendiente": false,
		"vida": 1,
		"carta_gastada": carta_id,
		"cartas_desbloqueadas": cartas_desbloqueadas,
	}


## Aceptar el cese es la única operación que convierte el cero en despido.
## La Muerte, la evaluación y los dos resets siguen siendo una sola transacción
## de dominio, pero ahora ocurren DESPUÉS de la decisión explícita.
static func aceptar_cese(estado: Dictionary, jornada: Dictionary) -> Dictionary:
	if not despido_pendiente(estado):
		return {
			"resultado": "rechazado",
			"despido": false,
			"despido_pendiente": false,
			"vida": int(estado.get("vida", 0)),
			"cartas_desbloqueadas": [],
		}

	Prometeo.desbloquear_carta_en_estado(estado, "la-muerte")
	EvaluacionDesempeno.sellar(estado, "reasignacion", jornada)
	var auditoria := Auditorias.cerrar_vuelta(
		estado, int(jornada.get("vuelta", 1)), "reasignacion"
	)
	estado[CLAVE_DESPIDO_PENDIENTE] = false
	Prometeo.reiniciar_vuelta(estado, ajustes(estado)["vidas"])
	Jornada.reiniciar_vuelta(jornada)
	return {
		"resultado": "cese",
		"despido": true,
		"despido_pendiente": false,
		"vida": estado["vida"],
		"cartas_desbloqueadas": [],
		"auditoria": auditoria,
	}


## Cierra el careo. Perder cuesta una vida; el veredicto ya está firmado y no
## se toca.
static func resolver_duelo(estado: Dictionary, jornada: Dictionary, gano: bool) -> Dictionary:
	if gano:
		var cartas_desbloqueadas := []
		# #1029/#46: El Colgado se re-gana por una victoria de ESTA vuelta.
		# El resultado del careo es el emisor; no se deriva de memoria histórica.
		if Prometeo.desbloquear_carta_en_estado(estado, "el-colgado"):
			cartas_desbloqueadas.append("el-colgado")
		return {
			"despido": false,
			"vida": estado.get("vida", 3),
			"cartas_desbloqueadas": cartas_desbloqueadas,
		}
	return perder_vida(estado, jornada, 1)


## A quién se puede acusar en un expediente. Se puede acusar a cualquiera desde
## el primer minuto: el juego no te impide firmar sin haber leído nada, solo te
## lo apunta.
static func sospechosos_de(caso: Dictionary) -> Array:
	return caso.get("sospechosos", [])
