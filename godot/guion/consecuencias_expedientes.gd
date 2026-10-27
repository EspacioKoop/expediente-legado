## Motor de consecuencias persistentes para decisiones SIGA (#2742).
##
## Este módulo implementa la persistencia de efectos posteriores visibles
## vinculados a decisiones tomadas sobre expedientes. No sustituye el
## catálogo de variables de expedientes, sino que extiende el sistema
## existente de veredictos para incluir consecuencias específicas.
##
## Diseño:
## - Cada expediente puede definir consecuencias específicas al ser cerrado
## - Las consecuencias se persisten junto al veredicto
## - Las consecuencias pueden ser visibles en el mundo (casa, oficina, etc.)
## - Se proporcionan helpers para consultar y materializar consecuencias
##
## Ejemplo de uso:
##   # Al acusar un expediente
##   var resultado := ConsecuenciasExpedientes.registrar(
##       estado, caso_id, sospechoso_id, consecuencias
##   )
##
##   # Al cargar una partida
##   var consecuencias := ConsecuenciasExpedientes.de_expediente(estado, caso_id)
##
##   # Al materializar en escena
##   ConsecuenciasExpedientes.aplicar_a_escena(escena, estado)
class_name ConsecuenciasExpedientes
extends RefCounted

## Clave donde se guardan las consecuencias por expediente en Partida
const CLAVE_CONSECUENCIAS := "consecuencias_expedientes"

## Tipos de consecuencias soportadas
const TIPO_VISUAL := "visual"
const TIPO_AMBIENTAL := "ambiental"
const TIPO_ECONOMICO := "economico"
const TIPO_NARRATIVO := "narrativo"

## Catálogo de consecuencias predefinidas por expediente
## Cada entrada define: id, tipo, descripción, y parámetros específicos
const CATALOGO_CONSECUENCIAS := {
	"caso@1":
	[
		{
			"id": "oficina_luz_tenue",
			"tipo": TIPO_AMBIENTAL,
			"descripcion": "La oficina tiene luz más tenue tras el caso",
			"ambito": "oficina",
			"parametros": {"intensidad_luz": 0.7}
		},
		{
			"id": "archivador_desordenado",
			"tipo": TIPO_VISUAL,
			"descripcion": "El archivador del caso queda desordenado",
			"ambito": "oficina",
			"parametros": {"archivador_id": "archivador_1"}
		}
	],
	"caso2@2":
	[
		{
			"id": "casa_puerta_rayada",
			"tipo": TIPO_VISUAL,
			"descripcion": "La puerta de casa tiene rayones",
			"ambito": "casa",
			"parametros": {"puerta_id": "puerta_entrada"}
		}
	],
	"caso7@7":
	[
		{
			"id": "oficina_papel_acumulado",
			"tipo": TIPO_VISUAL,
			"descripcion": "Papeles acumulados en el escritorio",
			"ambito": "oficina",
			"parametros": {"cantidad": 3, "posicion": "escritorio"}
		}
	]
}


## Registra consecuencias para un expediente al ser cerrado.
##
## Si el expediente ya tenía consecuencias, se reemplazan (solo un veredicto
## por expediente, y por tanto solo un conjunto de consecuencias).
##
## Parámetros:
## - estado: Dictionary de Partida
## - caso_id: String, identificador del expediente
## - sospechoso_id: String, identificador del sospechoso elegido
## - consecuencias: Array de Dictionary (opcional, usa CATALOGO si no se provee)
##
## Devuelve: Dictionary con el resultado de la operación
static func registrar(
	estado: Dictionary, caso_id: String, sospechoso_id: String, consecuencias: Array = []
) -> Dictionary:
	# Si no se proveen consecuencias, usar las del catálogo
	var consecuencias_a_registrar := consecuencias
	if consecuencias_a_registrar.is_empty():
		consecuencias_a_registrar = CATALOGO_CONSECUENCIAS.get(caso_id, [])

	# Obtener o crear el diccionario de consecuencias por expediente
	var consecuencias_expedientes: Dictionary = (
		estado.get(CLAVE_CONSECUENCIAS, {})
		if typeof(estado.get(CLAVE_CONSECUENCIAS, {})) == TYPE_DICTIONARY
		else {}
	)

	# Registrar consecuencias para este expediente
	consecuencias_expedientes[caso_id] = {
		"sospechoso_id": sospechoso_id,
		"consecuencias": consecuencias_a_registrar.duplicate(true),
		"fecha_registro": Time.get_ticks_msec()
	}

	# Guardar de vuelta en el estado
	estado[CLAVE_CONSECUENCIAS] = consecuencias_expedientes

	return {
		"resultado": "registrado",
		"caso_id": caso_id,
		"sospechoso_id": sospechoso_id,
		"consecuencias_registradas": consecuencias_a_registrar.size()
	}


## Obtiene las consecuencias de un expediente específico.
##
## Parámetros:
## - estado: Dictionary de Partida
## - caso_id: String, identificador del expediente
##
## Devuelve: Array de Dictionary con las consecuencias, o array vacío
static func de_expediente(estado: Dictionary, caso_id: String) -> Array:
	var consecuencias_expedientes: Dictionary = (
		estado.get(CLAVE_CONSECUENCIAS, {})
		if typeof(estado.get(CLAVE_CONSECUENCIAS, {})) == TYPE_DICTIONARY
		else {}
	)
	var entrada := consecuencias_expedientes.get(caso_id, {})
	if typeof(entrada) != TYPE_DICTIONARY:
		return []
	var consecuencias := entrada.get("consecuencias", [])
	return consecuencias if typeof(consecuencias) == TYPE_ARRAY else []


## Verifica si un expediente tiene consecuencias registradas.
##
## Parámetros:
## - estado: Dictionary de Partida
## - caso_id: String, identificador del expediente
##
## Devuelve: bool
static func tiene_consecuencias(estado: Dictionary, caso_id: String) -> bool:
	return not de_expediente(estado, caso_id).is_empty()


## Obtiene todas las consecuencias de todos los expedientes.
##
## Parámetros:
## - estado: Dictionary de Partida
##
## Devuelve: Array de Dictionary con todas las consecuencias
static func todas(estado: Dictionary) -> Array:
	var consecuencias_expedientes: Dictionary = (
		estado.get(CLAVE_CONSECUENCIAS, {})
		if typeof(estado.get(CLAVE_CONSECUENCIAS, {})) == TYPE_DICTIONARY
		else {}
	)
	var todas_consecuencias: Array = []
	for caso_id in consecuencias_expedientes:
		var entrada := consecuencias_expedientes[caso_id]
		if typeof(entrada) == TYPE_DICTIONARY:
			var consecuencias := entrada.get("consecuencias", [])
			if typeof(consecuencias) == TYPE_ARRAY:
				todas_consecuencias.append_array(consecuencias)
	return todas_consecuencias


## Filtra consecuencias por ámbito (casa, oficina, etc.)
##
## Parámetros:
## - estado: Dictionary de Partida
## - ambito: String, ámbito de interés
##
## Devuelve: Array de Dictionary con consecuencias del ámbito
static func por_ambito(estado: Dictionary, ambito: String) -> Array:
	var todas := todas(estado)
	var filtradas: Array = []
	for consecuencia in todas:
		if typeof(consecuencia) == TYPE_DICTIONARY:
			var ambito_consecuencia := consecuencia.get("ambito", "")
			if ambito_consecuencia == ambito:
				filtradas.append(consecuencia.duplicate(true))
	return filtradas


## Elimina las consecuencias de un expediente.
##
## Esto NO debería usarse en juego normal (los veredictos son irreversibles),
## pero es útil para pruebas y depuración.
##
## Parámetros:
## - estado: Dictionary de Partida
## - caso_id: String, identificador del expediente
##
## Devuelve: bool (true si se eliminaron consecuencias)
static func eliminar(estado: Dictionary, caso_id: String) -> bool:
	var consecuencias_expedientes: Dictionary = (
		estado.get(CLAVE_CONSECUENCIAS, {})
		if typeof(estado.get(CLAVE_CONSECUENCIAS, {})) == TYPE_DICTIONARY
		else {}
	)
	if not consecuencias_expedientes.has(caso_id):
		return false
	consecuencias_expedientes.erase(caso_id)
	estado[CLAVE_CONSECUENCIAS] = consecuencias_expedientes
	return true


## Limpia todas las consecuencias (útil para pruebas)
##
## Parámetros:
## - estado: Dictionary de Partida
static func limpiar_todo(estado: Dictionary) -> void:
	estado.erase(CLAVE_CONSECUENCIAS)


## Cuenta cuántos expedientes tienen consecuencias registradas.
##
## Parámetros:
## - estado: Dictionary de Partida
##
## Devuelve: int
static func contar_expedientes_con_consecuencias(estado: Dictionary) -> int:
	var consecuencias_expedientes: Dictionary = (
		estado.get(CLAVE_CONSECUENCIAS, {})
		if typeof(estado.get(CLAVE_CONSECUENCIAS, {})) == TYPE_DICTIONARY
		else {}
	)
	return consecuencias_expedientes.size()


## Cuenta cuántas consecuencias hay en total.
##
## Parámetros:
## - estado: Dictionary de Partida
##
## Devuelve: int
static func contar_consecuencias(estado: Dictionary) -> int:
	return todas(estado).size()


## Verifica si una consecuencia específica está registrada.
##
## Parámetros:
## - estado: Dictionary de Partida
## - consecuencia_id: String, identificador de la consecuencia
##
## Devuelve: bool
static func tiene_consecuencia_id(estado: Dictionary, consecuencia_id: String) -> bool:
	var todas := todas(estado)
	for consecuencia in todas:
		if typeof(consecuencia) == TYPE_DICTIONARY:
			if String(consecuencia.get("id", "")) == consecuencia_id:
				return true
	return false
