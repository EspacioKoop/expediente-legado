## Núcleo persistente del clímax personal de Hastur (#1103).
##
## OS98 solo entrega un handoff. A partir de aquí la confrontación pertenece a
## campaña: se guarda por partida/vuelta, reutiliza Combate y deja un contrato
## explícito para la capa que presente el final político.
class_name ClimaxHastur
extends RefCounted

const CLAVE_ESTADO := "climax_hastur"
const FASE_COMBATE := "combate"
const FASE_VICTORIA := "victoria_pendiente"
const FASE_DERROTA := "derrota_pendiente"
const FASE_FINAL := "final_politico"
const FASE_INTERRUMPIDO := "interrumpido"

const VEREDICTO_HASTUR := "hastur_confrontado"

const RIVAL := {
	"id": "hastur",
	"nombre": "Hastur",
	"ataques": [],
}

const VIDAS_RIVAL := {
	"facil": 2,
	"normal": 3,
	"dificil": 4,
}


static func clave_vuelta(jornada: Dictionary) -> String:
	return (
		"%d:%d"
		% [
			int(jornada.get("raiz", 0)),
			int(jornada.get("vuelta", 1)),
		]
	)


static func estado_actual(estado: Dictionary, jornada: Dictionary) -> Dictionary:
	var bruto = estado.get(CLAVE_ESTADO, {})
	if typeof(bruto) != TYPE_DICTIONARY:
		return {}
	var actual: Dictionary = bruto
	if String(actual.get("clave_vuelta", "")) != clave_vuelta(jornada):
		return {}
	return actual


static func iniciar(
	estado: Dictionary,
	jornada: Dictionary,
	contexto: Dictionary,
	cargas: Dictionary = {},
) -> Dictionary:
	if not bool(contexto.get("climax_hastur_pendiente", false)):
		return {"resultado": "sin_handoff"}

	var existente := estado_actual(estado, jornada)
	if not existente.is_empty():
		return {
			"resultado": "reanudado",
			"fase": String(existente.get("fase", "")),
		}

	var dificultad := String(estado.get("dificultad", "normal"))
	var nuevo := {
		"clave_vuelta": clave_vuelta(jornada),
		"fase": FASE_COMBATE,
		"dificultad": dificultad,
		"intentos": 1,
		"combate": _nuevo_combate(dificultad, cargas),
		"cargas_iniciales": cargas.duplicate(true),
		"veredicto": "",
		"final_politico_pendiente": false,
	}
	estado[CLAVE_ESTADO] = nuevo
	return {
		"resultado": "iniciado",
		"fase": FASE_COMBATE,
	}


static func jugar(
	estado: Dictionary,
	jornada: Dictionary,
	tipo: String,
	habilidad: String = "",
) -> Dictionary:
	var actual := estado_actual(estado, jornada)
	if actual.is_empty() or String(actual.get("fase", "")) != FASE_COMBATE:
		return {"resultado": "fase_invalida"}
	if not Combate.TIPOS.has(tipo):
		return {"resultado": "jugada_invalida"}

	var combate_bruto = actual.get("combate", {})
	if typeof(combate_bruto) != TYPE_DICTIONARY:
		return {"resultado": "combate_invalido"}
	var combate: Dictionary = combate_bruto
	var ronda := Combate.jugar(combate, tipo, habilidad, func(): return 0.0)
	if ronda.is_empty():
		return {"resultado": "sin_ronda"}

	if bool(ronda.get("terminado", false)):
		actual["fase"] = (
			FASE_VICTORIA if String(ronda.get("ganador", "")) == "jugador" else FASE_DERROTA
		)

	return {
		"resultado": "ronda",
		"fase": String(actual.get("fase", "")),
		"ronda": ronda,
	}


static func confirmar_victoria(estado: Dictionary, jornada: Dictionary) -> bool:
	var actual := estado_actual(estado, jornada)
	if actual.is_empty() or String(actual.get("fase", "")) != FASE_VICTORIA:
		return false

	actual["fase"] = FASE_FINAL
	actual["veredicto"] = VEREDICTO_HASTUR
	actual["final_politico_pendiente"] = true
	# El presentador del final sigue siendo otra capa. Aquí solo se rearma su
	# bandera histórica para que una vuelta nueva pueda mostrarlo.
	estado["final_politico_mostrado"] = false
	return true


static func aplicar_derrota(
	estado: Dictionary,
	jornada: Dictionary,
) -> Dictionary:
	var actual := estado_actual(estado, jornada)
	if actual.is_empty() or String(actual.get("fase", "")) != FASE_DERROTA:
		return {"resultado": "ignorada"}

	# Cambiar de fase ANTES de cobrar impide dos cobros dentro de la misma
	# sesión si una señal de UI se repite accidentalmente.
	actual["fase"] = FASE_INTERRUMPIDO
	var consecuencia := Acusacion.perder_vida(estado, jornada, 1)
	var despido := bool(consecuencia.get("despido", false))
	actual["ultima_derrota"] = {
		"vida": int(consecuencia.get("vida", estado.get("vida", 0))),
		"despido": despido,
	}

	if despido:
		return {
			"resultado": "reasignacion",
			"despido": true,
			"vida": int(consecuencia.get("vida", 0)),
		}

	actual["intentos"] = int(actual.get("intentos", 1)) + 1
	actual["combate"] = _nuevo_combate(
		String(actual.get("dificultad", "normal")),
		actual.get("cargas_iniciales", {}),
	)
	actual["fase"] = FASE_COMBATE
	return {
		"resultado": "reintento",
		"despido": false,
		"vida": int(consecuencia.get("vida", estado.get("vida", 0))),
	}


static func contrato_final(estado: Dictionary, jornada: Dictionary) -> Dictionary:
	var actual := estado_actual(estado, jornada)
	if actual.is_empty() or String(actual.get("fase", "")) != FASE_FINAL:
		return {"pendiente": false}

	return {
		"pendiente": bool(actual.get("final_politico_pendiente", false)),
		"veredicto": String(actual.get("veredicto", "")),
		"ejes_dominantes": Prometeo.ejes_dominantes(estado),
		"elecciones": Prometeo.elecciones_ideologicas(estado).size(),
	}


static func _nuevo_combate(dificultad: String, cargas: Dictionary) -> Dictionary:
	var combate := Combate.nuevo("ciclo", RIVAL.duplicate(true), cargas.duplicate(true))
	combate["vida_rival"] = int(VIDAS_RIVAL.get(dificultad, VIDAS_RIVAL["normal"]))
	return combate
