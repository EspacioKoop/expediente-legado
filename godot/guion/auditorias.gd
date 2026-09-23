## Condiciones opcionales de una vida laboral (#152).
##
## Mantiene un estado pequeño, determinista y guardable: qué se aceptó antes de
## empezar, qué sigue vivo y qué terminó fallando o completándose. También
## expone adaptadores mínimos para hechos que ya existen en la partida (como
## fichar con cero acciones), sin duplicar las reglas de Jornada ni de la UI.
class_name Auditorias
extends RefCounted

const CLAVE_ESTADO := "auditorias"
const CLAVE_HISTORIAL := "historial"
const CLAVE_SELECCION_RESUELTA := "seleccion_resuelta"
const ACCION_SOBRANTE := "accion_sobrante"
const GATO_DIARIO := "gato_diario"

## El contrato base solo declara identidades e incompatibilidades. Los rótulos
## pertenecen a la futura capa de selección/consulta: declarar aquí claves de
## traducción que ninguna UI consume las convertiría en texto huérfano (#105).
const CATALOGO := {
	"sin_releer": {"incompatibles": []},
	"accion_sobrante": {"incompatibles": []},
	"gato_diario": {"incompatibles": []},
	"sueno_completo": {"incompatibles": []},
}


static func ids() -> Array:
	var resultado := CATALOGO.keys()
	resultado.sort()
	return resultado


## Crea el estado al COMENZAR la vida. Una selección resuelta puede estar
## vacía: rechazar el reto también es una decisión válida y debe distinguirse
## de "todavía no se ha preguntado".
static func nueva(
	seleccion: Array = [], historial_previo: Array = [], seleccion_resuelta: bool = true
) -> Dictionary:
	if not compatibles(seleccion):
		return {}
	var activas := []
	for valor in seleccion:
		activas.append(String(valor))
	activas.sort()
	return {
		"activas": activas,
		"fallidas": {},
		"completadas": [],
		CLAVE_HISTORIAL: historial_previo.duplicate(true),
		CLAVE_SELECCION_RESUELTA: seleccion_resuelta,
	}


## Recupera el bloque persistido, migrando partidas antiguas que aún no lo tenían.
static func asegurar_en_estado(estado_partida: Dictionary) -> Dictionary:
	var actual = estado_partida.get(CLAVE_ESTADO, {})
	if typeof(actual) != TYPE_DICTIONARY:
		actual = nueva()
		estado_partida[CLAVE_ESTADO] = actual
	elif not estado_partida.has(CLAVE_ESTADO):
		estado_partida[CLAVE_ESTADO] = actual
	if not actual.has(CLAVE_HISTORIAL):
		actual[CLAVE_HISTORIAL] = []
	# Un guardado anterior a este corte ya estaba dentro de una vida laboral:
	# migrarlo no debe abrir una decisión nueva a mitad de jornada.
	if not actual.has(CLAVE_SELECCION_RESUELTA):
		actual[CLAVE_SELECCION_RESUELTA] = true
	return actual


static func seleccion_pendiente(estado_partida: Dictionary) -> bool:
	return not bool(asegurar_en_estado(estado_partida).get(CLAVE_SELECCION_RESUELTA, true))


## Resuelve exactamente una oferta de comienzo de vida. Una lista vacía
## significa "continuar sin condición". El histórico nunca se pierde.
static func resolver_seleccion(estado_partida: Dictionary, seleccion: Array) -> bool:
	if not compatibles(seleccion):
		return false
	var auditoria := asegurar_en_estado(estado_partida)
	if bool(auditoria.get(CLAVE_SELECCION_RESUELTA, true)):
		return false
	var historial_previo: Array = auditoria.get(CLAVE_HISTORIAL, [])
	estado_partida[CLAVE_ESTADO] = nueva(seleccion, historial_previo, true)
	return true


## Cierra una vida una sola vez. Las condiciones aún activas han sobrevivido
## toda la vuelta y se completan en este punto; las ya fallidas conservan su
## motivo. El registro es descriptivo y no concede recursos, sellos ni logros.
static func cerrar_vuelta(
	estado_partida: Dictionary, vuelta: int, motivo: String = "otro"
) -> Dictionary:
	if vuelta < 1:
		return {}
	var auditoria := asegurar_en_estado(estado_partida)
	var historial_actual: Array = auditoria.get(CLAVE_HISTORIAL, [])
	for registro in historial_actual:
		if typeof(registro) == TYPE_DICTIONARY and int(registro.get("vuelta", -1)) == vuelta:
			return Dictionary(registro).duplicate(true)

	var activas: Array = auditoria.get("activas", [])
	if activas.is_empty():
		return {}

	for id in pendientes(auditoria):
		completar(auditoria, String(id))

	var registro := {
		"vuelta": vuelta,
		"motivo": motivo.strip_edges() if not motivo.strip_edges().is_empty() else "otro",
		"activas": activas.duplicate(),
		"completadas": Array(auditoria.get("completadas", [])).duplicate(),
		"fallidas": Dictionary(auditoria.get("fallidas", {})).duplicate(true),
	}
	historial_actual.append(registro)
	auditoria[CLAVE_HISTORIAL] = historial_actual
	return registro.duplicate(true)


static func historial(estado_partida: Dictionary) -> Array:
	return Array(asegurar_en_estado(estado_partida).get(CLAVE_HISTORIAL, [])).duplicate(true)


## Una reasignación empieza otra vida laboral: ninguna condición activa de la
## anterior puede sobrevivir, pero el histórico sellado sí.
static func reiniciar_vuelta(estado_partida: Dictionary) -> void:
	var auditoria := asegurar_en_estado(estado_partida)
	var historial_previo: Array = auditoria.get(CLAVE_HISTORIAL, [])
	estado_partida[CLAVE_ESTADO] = nueva([], historial_previo, false)


## Primer predicado conectado extremo a extremo: al fichar, "accion_sobrante"
## exige que quede al menos una acción. Observa el hecho antes de que Jornada
## cambie de fase; no cobra, no bloquea la salida y no concede recompensa.
static func resolver_fin_archivo(estado_partida: Dictionary) -> Dictionary:
	var auditoria := asegurar_en_estado(estado_partida)
	var estado_actual := estado(auditoria, ACCION_SOBRANTE)
	if estado_actual != "activa":
		return {"resultado": estado_actual, "id": ACCION_SOBRANTE}

	var jornada = estado_partida.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return {"resultado": "sin-jornada", "id": ACCION_SOBRANTE}

	var acciones := int(jornada.get("acciones", 0))
	if acciones <= 0:
		fallar(auditoria, ACCION_SOBRANTE, "sin_accion_al_fichar")
		return {"resultado": "fallida", "id": ACCION_SOBRANTE, "acciones": acciones}
	return {"resultado": "activa", "id": ACCION_SOBRANTE, "acciones": acciones}


## Segundo predicado extremo a extremo: al acostarse, "gato_diario" observa
## el hambre que Jornada ya mantiene. Cero significa atendido; un valor mayor
## implica que el día termina sin haberlo alimentado. Se evalúa ANTES de
## Jornada.dormir(), que incrementa el contador para la noche siguiente.
static func resolver_fin_casa(estado_partida: Dictionary) -> Dictionary:
	var auditoria := asegurar_en_estado(estado_partida)
	var estado_actual := estado(auditoria, GATO_DIARIO)
	if estado_actual != "activa":
		return {"resultado": estado_actual, "id": GATO_DIARIO}

	var jornada = estado_partida.get("jornada", {})
	if typeof(jornada) != TYPE_DICTIONARY:
		return {"resultado": "sin-jornada", "id": GATO_DIARIO}
	var gato = jornada.get("gato", {})
	if typeof(gato) != TYPE_DICTIONARY:
		return {"resultado": "sin-gato", "id": GATO_DIARIO}

	if not bool(gato.get("presente", false)):
		fallar(auditoria, GATO_DIARIO, "gato_ausente_al_dormir")
		return {"resultado": "fallida", "id": GATO_DIARIO}
	var dias_sin_comer := int(gato.get("dias_sin_comer", 0))
	if dias_sin_comer > 0:
		fallar(auditoria, GATO_DIARIO, "gato_sin_comer_al_dormir")
		return {
			"resultado": "fallida",
			"id": GATO_DIARIO,
			"dias_sin_comer": dias_sin_comer,
		}
	return {"resultado": "activa", "id": GATO_DIARIO, "dias_sin_comer": dias_sin_comer}


## Valida únicamente estructura e invariantes persistibles. Las reglas de
## gameplay se evalúan en sus fronteras de evento, no durante la carga.
static func validar(auditoria) -> Array:
	if typeof(auditoria) != TYPE_DICTIONARY:
		return ["raiz no es un objeto"]

	var errores := []
	for clave in ["activas", "completadas"]:
		if not auditoria.has(clave):
			errores.append("%s ausente" % clave)
		elif typeof(auditoria[clave]) != TYPE_ARRAY:
			errores.append("%s no es una lista" % clave)
	if not auditoria.has("fallidas"):
		errores.append("fallidas ausente")
	elif typeof(auditoria["fallidas"]) != TYPE_DICTIONARY:
		errores.append("fallidas no es un objeto")
	if auditoria.has(CLAVE_HISTORIAL) and typeof(auditoria[CLAVE_HISTORIAL]) != TYPE_ARRAY:
		errores.append("historial no es una lista")
	if (
		auditoria.has(CLAVE_SELECCION_RESUELTA)
		and typeof(auditoria[CLAVE_SELECCION_RESUELTA]) != TYPE_BOOL
	):
		errores.append("seleccion_resuelta no es booleana")
	if not errores.is_empty():
		return errores

	var activas: Array = auditoria["activas"]
	if not compatibles(activas):
		errores.append("seleccion invalida")

	var completadas: Array = auditoria["completadas"]
	var completadas_vistas := {}
	for valor in completadas:
		var id := String(valor)
		if completadas_vistas.has(id):
			errores.append("completada duplicada: %s" % id)
			continue
		completadas_vistas[id] = true
		if not CATALOGO.has(id) or not activas.has(id):
			errores.append("completada fuera de seleccion: %s" % id)

	var fallidas: Dictionary = auditoria["fallidas"]
	for clave in fallidas:
		var id := String(clave)
		if not CATALOGO.has(id) or not activas.has(id):
			errores.append("fallida fuera de seleccion: %s" % id)
		if typeof(fallidas[clave]) != TYPE_STRING:
			errores.append("motivo de fallo invalido: %s" % id)
		if completadas_vistas.has(id):
			errores.append("estado terminal duplicado: %s" % id)

	if auditoria.has(CLAVE_HISTORIAL):
		errores.append_array(_validar_historial(auditoria[CLAVE_HISTORIAL]))
	return errores


static func _validar_historial(historial_crudo: Array) -> Array:
	var errores := []
	var vueltas := {}
	for i in historial_crudo.size():
		var registro = historial_crudo[i]
		if typeof(registro) != TYPE_DICTIONARY:
			errores.append("historial.%d no es un objeto" % i)
			continue
		var vuelta = registro.get("vuelta", -1)
		if not _entero_positivo(vuelta):
			errores.append("historial.%d.vuelta invalida" % i)
		elif vueltas.has(int(vuelta)):
			errores.append("historial.%d.vuelta duplicada" % i)
		else:
			vueltas[int(vuelta)] = true
		if (
			typeof(registro.get("motivo")) != TYPE_STRING
			or String(registro.get("motivo", "")).strip_edges().is_empty()
		):
			errores.append("historial.%d.motivo invalido" % i)

		var activas = registro.get("activas")
		var completadas = registro.get("completadas")
		var fallidas = registro.get("fallidas")
		if typeof(activas) != TYPE_ARRAY or not compatibles(activas):
			errores.append("historial.%d.activas invalidas" % i)
			continue
		if typeof(completadas) != TYPE_ARRAY:
			errores.append("historial.%d.completadas no es una lista" % i)
			continue
		if typeof(fallidas) != TYPE_DICTIONARY:
			errores.append("historial.%d.fallidas no es un objeto" % i)
			continue

		var terminales := {}
		for valor in completadas:
			var id := String(valor)
			if terminales.has(id) or not activas.has(id):
				errores.append("historial.%d.completada invalida: %s" % [i, id])
			terminales[id] = true
		for clave in fallidas:
			var id := String(clave)
			if terminales.has(id) or not activas.has(id) or typeof(fallidas[clave]) != TYPE_STRING:
				errores.append("historial.%d.fallida invalida: %s" % [i, id])
			terminales[id] = true
	return errores


static func compatibles(seleccion: Array) -> bool:
	var vistas := {}
	for valor in seleccion:
		var id := String(valor)
		if not CATALOGO.has(id) or vistas.has(id):
			return false
		vistas[id] = true
		for otro in CATALOGO[id].get("incompatibles", []):
			if seleccion.has(otro):
				return false
	return true


static func estado(auditoria: Dictionary, id: String) -> String:
	if auditoria.get("fallidas", {}).has(id):
		return "fallida"
	if auditoria.get("completadas", []).has(id):
		return "completada"
	if auditoria.get("activas", []).has(id):
		return "activa"
	return "inactiva"


## Fallar es irreversible durante la vida. El motivo es una clave técnica para
## que UI/pruebas puedan explicar qué ocurrió sin convertirlo en puntuación.
static func fallar(auditoria: Dictionary, id: String, motivo: String = "") -> bool:
	if estado(auditoria, id) != "activa":
		return false
	auditoria["fallidas"][id] = motivo
	return true


## Completar solo es válido si la condición sobrevivió toda la vida.
static func completar(auditoria: Dictionary, id: String) -> bool:
	if estado(auditoria, id) != "activa":
		return false
	auditoria["completadas"].append(id)
	auditoria["completadas"].sort()
	return true


static func pendientes(auditoria: Dictionary) -> Array:
	var resultado := []
	for id in auditoria.get("activas", []):
		if estado(auditoria, id) == "activa":
			resultado.append(id)
	return resultado


static func _entero_positivo(valor) -> bool:
	if typeof(valor) == TYPE_INT:
		return valor >= 1
	if typeof(valor) != TYPE_FLOAT or not is_finite(valor):
		return false
	return floor(valor) == valor and valor >= 1.0
