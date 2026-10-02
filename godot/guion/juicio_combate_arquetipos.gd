## Política pura de arquetipos para enemigos del hack & slash (#1771).
##
## No monta nodos ni resuelve consecuencias. Solo transforma un estado efímero
## en la siguiente intención: el host decide movimiento, colisiones, daño y HUD.
class_name JuicioCombateArquetipos
extends RefCounted

const HOSTIGADOR := "hostigador"
const BLOQUEADOR := "bloqueador"
const ENJAMBRE := "enjambre"
const EMBESTIDOR := "embestidor"
const CONTROLADOR := "controlador"

const REPOSICIONAR := "reposicionar"
const TELEGRAFIAR := "telegrafiar"
const DISPARAR_LINEA := "disparar_linea"
const VULNERABLE := "vulnerable"
const GUARDIA := "guardia"
const APERTURA := "apertura"
const RECUPERAR := "recuperar"
const ESPERA := "espera"
const ATACAR := "atacar"
const CARGAR := "cargar"

const HOSTIGADOR_DISTANCIA_MIN := 5.0
const HOSTIGADOR_DISTANCIA_MAX := 8.0
const HOSTIGADOR_TELEGRAFO := 0.65
const HOSTIGADOR_DISPARO := 0.08
const HOSTIGADOR_VENTANA := 0.90
const HOSTIGADOR_RECARGA := 1.20

const BLOQUEADOR_GUARDIA_MAX := 1.20
const BLOQUEADOR_APERTURA := 0.85
const BLOQUEADOR_RECUPERACION := 0.45

const ENJAMBRE_TELEGRAFO := 0.35
const ENJAMBRE_ATAQUE := 0.12
const ENJAMBRE_RECUPERACION := 0.75
const ENJAMBRE_PRESUPUESTO_ATAQUES := 2

const EMBESTIDOR_DISTANCIA_MIN := 2.5
const EMBESTIDOR_DISTANCIA_MAX := 9.0
const EMBESTIDOR_TELEGRAFO := 0.70
const EMBESTIDOR_CARGA := 0.55
const EMBESTIDOR_RECUPERACION := 1.00
const EMBESTIDOR_RECARGA := 0.80

const CONTROLADOR_MAX_ZONAS := 3
const CONTROLADOR_TELEGRAFO := 0.60
const CONTROLADOR_ACTIVACION := 0.40
const CONTROLADOR_RECUPERACION := 0.90


static func nuevo(tipo: String, raiz: int, indice: int = 0) -> Dictionary:
	var tirada := Azar.derivar(raiz, "combate", [1771, indice])
	match tipo:
		HOSTIGADOR:
			return {
				"tipo": HOSTIGADOR,
				"estado": REPOSICIONAR,
				"temporizador": 0.0,
				"cooldown": 0.0,
				"rumbo_bloqueado": 0.0,
				"sesgo_lateral": -1.0 if tirada % 2 == 0 else 1.0,
			}
		BLOQUEADOR:
			return {
				"tipo": BLOQUEADOR,
				"estado": GUARDIA,
				"temporizador": BLOQUEADOR_GUARDIA_MAX,
				"cooldown": 0.0,
			}
		ENJAMBRE:
			return {
				"tipo": ENJAMBRE,
				"estado": ESPERA,
				"temporizador": 0.0,
				"cooldown": 0.10 + float(tirada % 5) * 0.05,
				"determinacion": 1,
			}
		EMBESTIDOR:
			return {
				"tipo": EMBESTIDOR,
				"estado": REPOSICIONAR,
				"temporizador": 0.0,
				"cooldown": 0.0,
				"rumbo_bloqueado": 0.0,
			}
		CONTROLADOR:
			return {
				"tipo": CONTROLADOR,
				"estado": REPOSICIONAR,
				"temporizador": 0.0,
				"cooldown": 0.0,
				"zonas_marcadas": 0,
			}
		_:
			return {}


static func avanzar(unidad: Dictionary, delta: float, contexto: Dictionary = {}) -> Dictionary:
	if unidad.is_empty():
		return _resultado({}, "ninguna", "", false)
	var copia := unidad.duplicate(true)
	match String(copia.get("tipo", "")):
		HOSTIGADOR:
			return _avanzar_hostigador(copia, delta, contexto)
		BLOQUEADOR:
			return _avanzar_bloqueador(copia, delta, contexto)
		ENJAMBRE:
			return _avanzar_enjambre(copia, delta, contexto)
		EMBESTIDOR:
			return _avanzar_embestidor(copia, delta, contexto)
		CONTROLADOR:
			return _avanzar_controlador(copia, delta, contexto)
		_:
			return _resultado(copia, "ninguna", "", false)


static func _avanzar_hostigador(
	unidad: Dictionary, delta: float, contexto: Dictionary
) -> Dictionary:
	unidad["cooldown"] = maxf(0.0, float(unidad.get("cooldown", 0.0)) - delta)
	var distancia := float(contexto.get("distancia", HOSTIGADOR_DISTANCIA_MAX))
	var estado := String(unidad.get("estado", REPOSICIONAR))
	match estado:
		REPOSICIONAR:
			if distancia < HOSTIGADOR_DISTANCIA_MIN:
				return _resultado(unidad, "alejarse", "", false)
			if distancia > HOSTIGADOR_DISTANCIA_MAX:
				return _resultado(unidad, "acercarse", "", false)
			if float(unidad["cooldown"]) <= 0.0:
				unidad["estado"] = TELEGRAFIAR
				unidad["temporizador"] = HOSTIGADOR_TELEGRAFO
				unidad["rumbo_bloqueado"] = float(contexto.get("rumbo_objetivo", 0.0))
				return _resultado(unidad, "telegrafiar", "linea", false)
			return _resultado(unidad, "mantener_distancia", "", false)
		TELEGRAFIAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = DISPARAR_LINEA
				unidad["temporizador"] = HOSTIGADOR_DISPARO
				return _resultado(unidad, DISPARAR_LINEA, "linea", false)
			return _resultado(unidad, "telegrafiar", "linea", false)
		DISPARAR_LINEA:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = VULNERABLE
				unidad["temporizador"] = HOSTIGADOR_VENTANA
				unidad["cooldown"] = HOSTIGADOR_RECARGA
				return _resultado(unidad, "retroceder", "vulnerable", true)
			return _resultado(unidad, DISPARAR_LINEA, "linea", false)
		VULNERABLE:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = REPOSICIONAR
				return _resultado(unidad, "reposicionar", "", false)
			return _resultado(unidad, "vulnerable", "vulnerable", true)
		_:
			unidad["estado"] = REPOSICIONAR
			unidad["temporizador"] = 0.0
			return _resultado(unidad, "reposicionar", "", false)


static func _avanzar_bloqueador(
	unidad: Dictionary, delta: float, contexto: Dictionary
) -> Dictionary:
	var estado := String(unidad.get("estado", GUARDIA))
	match estado:
		GUARDIA:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			var forzar_apertura := (
				bool(contexto.get("flanqueado", false))
				or bool(contexto.get("guardia_rota", false))
				or float(unidad["temporizador"]) <= 0.0
			)
			if forzar_apertura:
				unidad["estado"] = APERTURA
				unidad["temporizador"] = BLOQUEADOR_APERTURA
				return _resultado(unidad, "abrir_guardia", "apertura", true)
			return _resultado(unidad, "guardar_frente", "guardia", false)
		APERTURA:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = RECUPERAR
				unidad["temporizador"] = BLOQUEADOR_RECUPERACION
				return _resultado(unidad, "recuperar", "", false)
			return _resultado(unidad, "apertura", "apertura", true)
		RECUPERAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = GUARDIA
				unidad["temporizador"] = BLOQUEADOR_GUARDIA_MAX
				return _resultado(unidad, "guardar_frente", "guardia", false)
			return _resultado(unidad, "recuperar", "", false)
		_:
			unidad["estado"] = GUARDIA
			unidad["temporizador"] = BLOQUEADOR_GUARDIA_MAX
			return _resultado(unidad, "guardar_frente", "guardia", false)


static func _avanzar_enjambre(unidad: Dictionary, delta: float, contexto: Dictionary) -> Dictionary:
	var estado := String(unidad.get("estado", ESPERA))
	match estado:
		ESPERA:
			unidad["cooldown"] = maxf(0.0, float(unidad.get("cooldown", 0.0)) - delta)
			var activos := maxi(0, int(contexto.get("atacantes_activos", 0)))
			var presupuesto := maxi(
				1, int(contexto.get("presupuesto_ataques", ENJAMBRE_PRESUPUESTO_ATAQUES))
			)
			if float(unidad["cooldown"]) <= 0.0 and activos < presupuesto:
				unidad["estado"] = TELEGRAFIAR
				unidad["temporizador"] = ENJAMBRE_TELEGRAFO
				return _resultado(unidad, "telegrafiar", "ataque_corto", false)
			return _resultado(unidad, "rodear", "", false)
		TELEGRAFIAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = ATACAR
				unidad["temporizador"] = ENJAMBRE_ATAQUE
				return _resultado(unidad, "atacar", "ataque_corto", false)
			return _resultado(unidad, "telegrafiar", "ataque_corto", false)
		ATACAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = RECUPERAR
				unidad["temporizador"] = ENJAMBRE_RECUPERACION
				return _resultado(unidad, "recuperar", "", true)
			return _resultado(unidad, "atacar", "ataque_corto", false)
		RECUPERAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = ESPERA
				unidad["cooldown"] = 0.25
				return _resultado(unidad, "rodear", "", false)
			return _resultado(unidad, "recuperar", "", true)
		_:
			unidad["estado"] = ESPERA
			unidad["temporizador"] = 0.0
			unidad["cooldown"] = 0.25
			return _resultado(unidad, "rodear", "", false)


static func _avanzar_embestidor(
	unidad: Dictionary, delta: float, contexto: Dictionary
) -> Dictionary:
	unidad["cooldown"] = maxf(0.0, float(unidad.get("cooldown", 0.0)) - delta)
	var distancia := float(contexto.get("distancia", EMBESTIDOR_DISTANCIA_MAX))
	var estado := String(unidad.get("estado", REPOSICIONAR))
	match estado:
		REPOSICIONAR:
			if distancia < EMBESTIDOR_DISTANCIA_MIN:
				return _resultado(unidad, "alejarse", "", false)
			if distancia > EMBESTIDOR_DISTANCIA_MAX:
				return _resultado(unidad, "acercarse", "", false)
			if not bool(contexto.get("linea_libre", true)):
				return _resultado(unidad, "buscar_linea", "", false)
			if float(unidad["cooldown"]) <= 0.0:
				unidad["estado"] = TELEGRAFIAR
				unidad["temporizador"] = EMBESTIDOR_TELEGRAFO
				unidad["rumbo_bloqueado"] = float(contexto.get("rumbo_objetivo", 0.0))
				return _resultado(unidad, "telegrafiar", "carga_lineal", false)
			return _resultado(unidad, "reposicionar", "", false)
		TELEGRAFIAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = CARGAR
				unidad["temporizador"] = EMBESTIDOR_CARGA
				return _resultado(unidad, CARGAR, "carga_lineal", false)
			return _resultado(unidad, "telegrafiar", "carga_lineal", false)
		CARGAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if bool(contexto.get("choque", false)) or float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = RECUPERAR
				unidad["temporizador"] = EMBESTIDOR_RECUPERACION
				unidad["cooldown"] = EMBESTIDOR_RECARGA
				return _resultado(unidad, "recuperar", "vulnerable", true)
			return _resultado(unidad, CARGAR, "carga_lineal", false)
		RECUPERAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = REPOSICIONAR
				return _resultado(unidad, "reposicionar", "", false)
			return _resultado(unidad, "recuperar", "vulnerable", true)
		_:
			unidad["estado"] = REPOSICIONAR
			unidad["temporizador"] = 0.0
			return _resultado(unidad, "reposicionar", "", false)


static func cuenta_presupuesto(unidades: Array) -> int:
	var activos := 0
	for unidad in unidades:
		if not unidad is Dictionary:
			continue
		if String(unidad.get("tipo", "")) != ENJAMBRE:
			continue
		if String(unidad.get("estado", "")) in [TELEGRAFIAR, ATACAR]:
			activos += 1
	return activos


static func arena_tiene_ventana(unidades: Array) -> bool:
	for unidad in unidades:
		if not unidad is Dictionary:
			continue
		var tipo := String(unidad.get("tipo", ""))
		var estado := String(unidad.get("estado", ""))
		if tipo == HOSTIGADOR and estado == VULNERABLE:
			return true
		if tipo == BLOQUEADOR and estado == APERTURA:
			return true
		if tipo == ENJAMBRE and estado == RECUPERAR:
			return true
		if tipo == EMBESTIDOR and estado == RECUPERAR:
			return true
		if tipo == CONTROLADOR and estado == RECUPERAR:
			return true
	return false


static func _avanzar_controlador(
	unidad: Dictionary, delta: float, contexto: Dictionary
) -> Dictionary:
	unidad["cooldown"] = maxf(0.0, float(unidad.get("cooldown", 0.0)) - delta)
	var distancia := float(contexto.get("distancia", 6.0))
	var estado := String(unidad.get("estado", REPOSICIONAR))
	var zonas_activas := int(contexto.get("zonas_activas", 0))
	var hay_salida := bool(contexto.get("queda_salida_valida", true))
	var zonas_marcadas := int(unidad.get("zonas_marcadas", 0))
	match estado:
		REPOSICIONAR:
			if distancia < 3.0:
				return _resultado(unidad, "alejarse", "", false)
			if float(unidad["cooldown"]) <= 0.0 and zonas_marcadas < CONTROLADOR_MAX_ZONAS:
				unidad["estado"] = TELEGRAFIAR
				unidad["temporizador"] = CONTROLADOR_TELEGRAFO
				unidad["zonas_marcadas"] = zonas_marcadas + 1
				return _resultado(unidad, "telegrafiar", "zona", false)
			return _resultado(unidad, "reposicionar", "", false)
		TELEGRAFIAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				# No activar si cerraría todas las salidas
				if not hay_salida:
					return _resultado(unidad, "esperar_salida", "zona", false)
				if zonas_activas >= CONTROLADOR_MAX_ZONAS:
					return _resultado(unidad, "esperar_zona", "zona", false)
				unidad["estado"] = ACTIVAR_ZONA
				unidad["temporizador"] = CONTROLADOR_ACTIVACION
				return _resultado(unidad, "telegrafiar", "zona", false)
			return _resultado(unidad, "telegrafiar", "zona", false)
		ACTIVAR_ZONA:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = RECUPERAR
				unidad["temporizador"] = CONTROLADOR_RECUPERACION
				return _resultado(unidad, "activar_zona", "zona", false)
			return _resultado(unidad, "activar_zona", "zona", false)
		RECUPERAR:
			unidad["temporizador"] = maxf(0.0, float(unidad["temporizador"]) - delta)
			if float(unidad["temporizador"]) <= 0.0:
				unidad["estado"] = REPOSICIONAR
				unidad["cooldown"] = 0.50
				return _resultado(unidad, "reposicionar", "", false)
			return _resultado(unidad, "recuperar", "vulnerable", true)
		_:
			unidad["estado"] = REPOSICIONAR
			unidad["temporizador"] = 0.0
			return _resultado(unidad, "reposicionar", "", false)


## La reducción de movimiento solo cambia cómo se dibuja el aviso. La lógica y
## sus duraciones ya vienen resueltas en `resultado` y se copian sin alterarlas.
static func presentacion(resultado: Dictionary, reduccion_movimiento: bool) -> Dictionary:
	var unidad: Dictionary = resultado.get("unidad", {})
	return {
		"telegraph": String(resultado.get("telegraph", "")),
		"ventana_respuesta": bool(resultado.get("ventana_respuesta", false)),
		"estado": String(unidad.get("estado", "")),
		"temporizador": float(unidad.get("temporizador", 0.0)),
		"estilo": "corte" if reduccion_movimiento else "animado",
	}


static func _resultado(
	unidad: Dictionary, intencion: String, telegraph: String, ventana_respuesta: bool
) -> Dictionary:
	return {
		"unidad": unidad,
		"intencion": intencion,
		"telegraph": telegraph,
		"ventana_respuesta": ventana_respuesta,
		"cooldown": float(unidad.get("cooldown", 0.0)),
	}
