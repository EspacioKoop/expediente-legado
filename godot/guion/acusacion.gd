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


static func ajustes(estado: Dictionary) -> Dictionary:
	return DIFICULTADES.get(estado.get("dificultad", "normal"), DIFICULTADES["normal"])


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
		# Si esta firma agotó la última vida, reiniciar_vuelta() ya retiró la
		# posesión per-run. La memoria fantasma permanece, pero la UI no debe
		# anunciar como poseída una carta que pertenece a la vuelta terminada.
		if castigo.get("despido", false):
			cartas_desbloqueadas.clear()

	return {
		"resultado": "cerrado",
		"sospechoso": sospechoso["nombre"],
		"desenlace": sospechoso.get("desenlace", ""),
		"precipitada": precipitada,
		"evidencia": [encontradas, pistas.size()],
		"vida": estado["vida"],
		"despido": castigo.get("despido", false),
		"cartas_desbloqueadas": cartas_desbloqueadas,
		# Un sospechoso con réplicas escritas no se deja acusar sin más: hay
		# careo. El duelo NO cambia el veredicto —ya está firmado— pero perderlo
		# cuesta una vida, así que es una escena con algo en juego.
		"duelo": sospechoso if not sospechoso.get("ataques", []).is_empty() else {},
	}


## Quita vidas y, si se acaban, te reasignan.
##
## El despido reinicia la capa de Prometeo (#46) y la vida laboral, pero **no**
## el archivo: las pistas que descubriste y los expedientes que firmaste siguen
## ahí, porque son del sistema y no tuyos. Otra persona en el mismo puesto
## hereda tu trabajo, incluidos tus errores.
static func perder_vida(estado: Dictionary, jornada: Dictionary, cuantas: int) -> Dictionary:
	var vida_anterior := int(estado.get("vida", 3))
	estado["vida"] = maxi(0, vida_anterior - cuantas)
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
			"vida": estado["vida"],
			"cartas_desbloqueadas": cartas_desbloqueadas,
		}

	# #1029/#46: La Muerte pertenece al evento de despido de ESTA vuelta.
	# Se adquiere antes del reset para que la memoria fantasma sobreviva; la
	# posesión se limpia inmediatamente al comenzar la nueva vida laboral.
	Prometeo.desbloquear_carta_en_estado(estado, "la-muerte")

	# Hay que sellar ANTES del reset: Jornada contiene todavía el mapa, dinero y gato
	# de la vida que acaba. La operación es idempotente si esta ruta se reintenta.
	EvaluacionDesempeno.sellar(estado, "reasignacion", jornada)
	Prometeo.reiniciar_vuelta(estado, ajustes(estado)["vidas"])
	Jornada.reiniciar_vuelta(jornada)
	# La memoria fantasma conserva el evento, pero la nueva vuelta ya no posee
	# El Ermitaño y por tanto no debe recibir una notificación de la vuelta anterior.
	return {"despido": true, "vida": estado["vida"], "cartas_desbloqueadas": []}


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
