## Núcleo de la estación nocturna: el cruce entre tres destinos oníricos.
##
## No monta geometría ni decide cuándo aparece en la noche: eso pertenece a la
## capa de día (#279/#280). Este módulo solo gestiona el estado del cruce,
## qué destinos están accesibles, el bloqueo contextual por narrativa y el
## retorno seguro sin tocar el estado global de Partida.
##
## Los tres destinos —Casa, Infancia, Juicio— son nodos del mismo grafo. El
## jugador llega a la estación, elige uno y vuelve; la estación no es una sala
## más del sueño, es el nudo que los une sin mezclar sus lógicas internas.
class_name SuenoEstacion
extends RefCounted

const DESTINOS := ["casa", "infancia", "juicio"]

const BLOQUEO_NARRATIVO := "narrativo"
const BLOQUEO_PROGRESO := "progreso"
const BLOQUEO_SEGURIDAD := "seguridad"

## Un bloqueo de acceso impide subir al tren; uno de seguridad no. La zona
## inestable se puede visitar, pero mientras estés dentro el retorno deja de
## estar garantizado: quien integra decide si avisa o si corta la microescena.
const BLOQUEOS_ACCESO := [BLOQUEO_NARRATIVO, BLOQUEO_PROGRESO]


## Estado inicial de la estación para una noche concreta.
##
## [param raiz] semilla de la partida (#147), usada solo para derivar el orden
## de presentación si hace falta desempate determinista.
static func estado_nuevo(raiz: int = 0) -> Dictionary:
	return {
		"destino_actual": "",
		"destino_anterior": "",
		"visitados": [],
		"bloqueos": {},
		"orden_presentacion": _orden_destinos(raiz),
		"retorno_seguro": true,
		"veces_entrada": 0,
	}


## Deriva un orden determinista de presentación para los tres destinos.
## No cambia la lógica, solo evita que la UI siempre muestre el mismo primero.
static func _orden_destinos(raiz: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = Azar.derivar_guardable(raiz, "estacion_orden", [])
	var copia: Array = DESTINOS.duplicate()
	for i in range(copia.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = copia[i]
		copia[i] = copia[j]
		copia[j] = tmp
	return copia


## Comprueba si un destino está disponible en la estación actual.
##
## Un destino está disponible si existe en DESTINOS y no tiene un bloqueo de
## acceso activo. El rebote inmediato no es asunto del acceso: volver al mismo
## destino es legítimo, solo deja de sugerirse (ver `destinos_sugeridos`).
static func disponible(estado: Dictionary, destino: String, contexto: Dictionary = {}) -> bool:
	if not DESTINOS.has(destino):
		return false
	return not _tiene_bloqueo_activo(estado, destino, contexto)


## Devuelve la lista de destinos accesibles, en el orden de presentación.
static func disponibles(estado: Dictionary, contexto: Dictionary = {}) -> Array:
	var resultado := []
	for destino in estado.get("orden_presentacion", DESTINOS):
		if disponible(estado, destino, contexto):
			resultado.append(destino)
	return resultado


## Lo que la estación ofrece en pantalla: lo accesible, apartando el destino
## del que se acaba de volver para que la noche no se quede en un ida y vuelta.
##
## Si apartarlo dejaría la lista vacía, se conserva: la estación nunca puede
## quedarse sin salida mientras exista un destino accesible.
static func destinos_sugeridos(estado: Dictionary, contexto: Dictionary = {}) -> Array:
	var accesibles := disponibles(estado, contexto)
	var anterior := String(estado.get("destino_anterior", ""))
	if anterior.is_empty() or not accesibles.has(anterior) or accesibles.size() <= 1:
		return accesibles
	accesibles.erase(anterior)
	return accesibles


## Marca un destino como visitado y actualiza el estado de la estación.
##
## Devuelve true si el cambio fue efectivo (el destino era válido y disponible).
static func ir_a(estado: Dictionary, destino: String) -> bool:
	if not DESTINOS.has(destino):
		return false
	if not disponible(estado, destino):
		return false

	# Saltar de un destino a otro sin pasar por la estación sí cambia la
	# referencia; entrar desde la estación conserva el destino del que se volvió,
	# que es lo que la presentación necesita para no repetir el mismo tren.
	var actual := String(estado.get("destino_actual", ""))
	if not actual.is_empty():
		estado["destino_anterior"] = actual
	estado["destino_actual"] = destino

	var visitados: Array = estado.get("visitados", [])
	if not visitados.has(destino):
		visitados.append(destino)
		estado["visitados"] = visitados

	estado["veces_entrada"] = int(estado.get("veces_entrada", 0)) + 1
	_actualizar_retorno_seguro(estado)
	return true


## Vuelve a la estación desde el destino actual.
##
## Limpia el destino actual, conserva el anterior como referencia y garantiza
## que el retorno es seguro (no pierde progreso ni modifica Partida).
##
## Devuelve el destino desde el que se vuelve, o cadena vacía si no había uno.
static func volver(estado: Dictionary) -> String:
	var actual := String(estado.get("destino_actual", ""))
	if actual.is_empty():
		return ""
	estado["destino_actual"] = ""
	estado["destino_anterior"] = actual
	_actualizar_retorno_seguro(estado)
	return actual


## Añade un bloqueo contextual a un destino.
##
## [param tipo] uno de BLOQUEO_NARRATIVO, BLOQUEO_PROGRESO, BLOQUEO_SEGURIDAD
## [param motivo] texto legible para depuración/trazas; no se muestra al jugador
## [param condicion] diccionario opcional que la capa de día evalúa para decidir
## si el bloqueo sigue activo (p. ej. {"requiere": "carta_x", "dia": 5})
##
## El bloqueo es consultivo: la estación no lo resuelve, solo lo expone. Quien
## integra la estación decide cuándo comprobar las condiciones y levantar el
## bloqueo llamando a `levantar_bloqueo`.
static func bloquear(
	estado: Dictionary, destino: String, tipo: String, motivo: String, condicion: Dictionary = {}
) -> bool:
	if not DESTINOS.has(destino):
		return false
	if not [BLOQUEO_NARRATIVO, BLOQUEO_PROGRESO, BLOQUEO_SEGURIDAD].has(tipo):
		return false

	var bloqueos: Dictionary = estado.get("bloqueos", {})
	if not bloqueos.has(destino):
		bloqueos[destino] = []
	(
		bloqueos[destino]
		. append(
			{
				"tipo": tipo,
				"motivo": motivo,
				"condicion": condicion,
				"activo": true,
			}
		)
	)
	estado["bloqueos"] = bloqueos
	# Bloquear el destino en el que estás puede retirar la garantía de vuelta.
	_actualizar_retorno_seguro(estado)
	return true


## Levanta un bloqueo específico de un destino.
##
## [param indice] índice dentro de la lista de bloqueos de ese destino.
## Devuelve true si se encontró y levantó.
static func levantar_bloqueo(estado: Dictionary, destino: String, indice: int) -> bool:
	var bloqueos: Dictionary = estado.get("bloqueos", {})
	if not bloqueos.has(destino):
		return false
	var lista: Array = bloqueos[destino]
	if indice < 0 or indice >= lista.size():
		return false
	lista[indice]["activo"] = false
	estado["bloqueos"] = bloqueos
	# Levantarlo desde dentro devuelve la garantía de vuelta en el mismo acto.
	_actualizar_retorno_seguro(estado)
	return true


## Levanta todos los bloqueos de un tipo para un destino.
static func levantar_bloqueos_tipo(estado: Dictionary, destino: String, tipo: String) -> int:
	var bloqueos: Dictionary = estado.get("bloqueos", {})
	if not bloqueos.has(destino):
		return 0
	var lista: Array = bloqueos[destino]
	var levantados := 0
	for i in lista.size():
		if lista[i].get("tipo", "") == tipo and bool(lista[i].get("activo", false)):
			lista[i]["activo"] = false
			levantados += 1
	estado["bloqueos"] = bloqueos
	_actualizar_retorno_seguro(estado)
	return levantados


## Comprueba si un destino tiene algún bloqueo de acceso activo (consultando
## condiciones si el contexto las provee). Los de seguridad no cuentan aquí:
## se pagan a la vuelta, no a la entrada.
static func _tiene_bloqueo_activo(
	estado: Dictionary, destino: String, contexto: Dictionary
) -> bool:
	var bloqueos: Dictionary = estado.get("bloqueos", {})
	if not bloqueos.has(destino):
		return false
	for bloqueo in bloqueos[destino]:
		if not bool(bloqueo.get("activo", false)):
			continue
		if not BLOQUEOS_ACCESO.has(String(bloqueo.get("tipo", ""))):
			continue
		var condicion: Dictionary = bloqueo.get("condicion", {})
		if condicion.is_empty():
			return true
		# Evaluación perezosa: si el contexto no tiene la clave, asumimos que
		# el bloqueo sigue activo por seguridad. Quien integra debe proveer
		# el contexto completo si quiere que se resuelva automáticamente.
		if not _evalua_condicion(condicion, contexto):
			return true
	return false


## Evalúa una condición simple de bloqueo contra el contexto.
##
## Formato soportado: {"requiere": "clave", "valor": esperado}
## o {"dia_minimo": 5}, {"flag": "nombre_flag"}
## Extensible sin romper contratos existentes.
static func _evalua_condicion(condicion: Dictionary, contexto: Dictionary) -> bool:
	if condicion.has("requiere") and condicion.has("valor"):
		var clave := String(condicion["requiere"])
		var esperado: Variant = condicion["valor"]
		if not contexto.has(clave):
			return false
		return contexto[clave] == esperado
	if condicion.has("dia_minimo"):
		var minimo := int(condicion["dia_minimo"])
		var dia := int(contexto.get("dia", 0))
		return dia >= minimo
	if condicion.has("flag"):
		var flag := String(condicion["flag"])
		return bool(contexto.get(flag, false))
	# Condición no reconocida: por seguridad, no la resuelve automáticamente.
	return false


## Actualiza la bandera de retorno seguro.
##
## El retorno es seguro mientras:
## - No estemos dentro de un destino (destino_actual vacío)
## - O el destino actual no tenga bloqueos de seguridad activos
static func _actualizar_retorno_seguro(estado: Dictionary) -> void:
	var actual := String(estado.get("destino_actual", ""))
	if actual.is_empty():
		estado["retorno_seguro"] = true
		return

	var bloqueos: Dictionary = estado.get("bloqueos", {})
	if not bloqueos.has(actual):
		estado["retorno_seguro"] = true
		return

	for bloqueo in bloqueos[actual]:
		if (
			bool(bloqueo.get("activo", false))
			and String(bloqueo.get("tipo", "")) == BLOQUEO_SEGURIDAD
		):
			estado["retorno_seguro"] = false
			return
	estado["retorno_seguro"] = true


## Consulta si el retorno a la estación es seguro en este momento.
static func retorno_seguro(estado: Dictionary) -> bool:
	return bool(estado.get("retorno_seguro", true))


## Obtiene información de depuración sobre los bloqueos de un destino.
static func info_bloqueos(estado: Dictionary, destino: String) -> Array:
	var bloqueos: Dictionary = estado.get("bloqueos", {})
	if not bloqueos.has(destino):
		return []
	return bloqueos[destino].duplicate(true)


## Serializa el estado para guardado (solo datos, sin lógica).
static func serializar(estado: Dictionary) -> Dictionary:
	return {
		"destino_actual": estado.get("destino_actual", ""),
		"destino_anterior": estado.get("destino_anterior", ""),
		"visitados": estado.get("visitados", []).duplicate(),
		"bloqueos": _serializar_bloqueos(estado.get("bloqueos", {})),
		"orden_presentacion": estado.get("orden_presentacion", DESTINOS).duplicate(),
		"veces_entrada": int(estado.get("veces_entrada", 0)),
	}


## Deserializa el estado desde guardado, validando estructura.
static func deserializar(datos: Dictionary, raiz: int = 0) -> Dictionary:
	var base: Dictionary = estado_nuevo(raiz)
	if typeof(datos) != TYPE_DICTIONARY:
		return base

	base["destino_actual"] = String(datos.get("destino_actual", ""))
	base["destino_anterior"] = String(datos.get("destino_anterior", ""))
	base["visitados"] = _validar_array_strings(datos.get("visitados", []))
	base["bloqueos"] = _deserializar_bloqueos(datos.get("bloqueos", {}))
	base["orden_presentacion"] = _validar_array_strings(datos.get("orden_presentacion", DESTINOS))
	base["veces_entrada"] = int(datos.get("veces_entrada", 0))
	_actualizar_retorno_seguro(base)
	return base


static func _serializar_bloqueos(bloqueos: Dictionary) -> Dictionary:
	var resultado := {}
	for destino in bloqueos:
		var lista: Array = bloqueos[destino]
		var serializada := []
		for b in lista:
			(
				serializada
				. append(
					{
						"tipo": String(b.get("tipo", "")),
						"motivo": String(b.get("motivo", "")),
						"condicion": b.get("condicion", {}).duplicate(true),
						"activo": bool(b.get("activo", false)),
					}
				)
			)
		resultado[destino] = serializada
	return resultado


static func _deserializar_bloqueos(datos: Dictionary) -> Dictionary:
	var resultado := {}
	if typeof(datos) != TYPE_DICTIONARY:
		return resultado
	for destino in datos:
		var lista: Variant = datos[destino]
		if typeof(lista) != TYPE_ARRAY:
			continue
		var deserializada := []
		for b in lista:
			if typeof(b) != TYPE_DICTIONARY:
				continue
			(
				deserializada
				. append(
					{
						"tipo": String(b.get("tipo", "")),
						"motivo": String(b.get("motivo", "")),
						"condicion": b.get("condicion", {}).duplicate(true),
						"activo": bool(b.get("activo", false)),
					}
				)
			)
		resultado[destino] = deserializada
	return resultado


static func _validar_array_strings(arr) -> Array:
	if typeof(arr) != TYPE_ARRAY:
		return []
	var resultado := []
	for item in arr:
		var s := String(item).strip_edges()
		if not s.is_empty():
			resultado.append(s)
	return resultado
