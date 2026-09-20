## Contrato puro para experiencias religiosas/culturales (#931/#936).
##
## Mantiene separados cuatro canales deliberadamente distintos. Un evento de
## exposición no se convierte en práctica; una práctica no se convierte en
## convicción; y un vínculo solo dice qué relación observable existe.
##
## Este módulo no persiste estado por sí mismo. El dueño de Partida podrá
## integrarlo cuando #931 fije esa frontera sin obligar a #936 a inventar una
## segunda fuente de verdad.
class_name ReligionEventos
extends RefCounted

const CANAL_EXPOSICION := "exposicion"
const CANAL_PRACTICA := "practica"
const CANAL_CONVICCION := "conviccion_declarada"
const CANAL_VINCULO := "vinculo"
const CANALES := [
	CANAL_EXPOSICION,
	CANAL_PRACTICA,
	CANAL_CONVICCION,
	CANAL_VINCULO,
]


static func nuevo() -> Dictionary:
	return {
		CANAL_EXPOSICION: [],
		CANAL_PRACTICA: [],
		CANAL_CONVICCION: [],
		CANAL_VINCULO: [],
	}


## Construye un hecho explícito de la run.
##
## `tradicion` es metadato documental opcional, nunca una clase de personaje.
## `reglas_conflicto` declara compromisos que la experiencia realmente puede
## habilitar. Exponer esa lista no significa que todos los canales puedan
## activarla: ReligionConflicto aplica una segunda frontera por canal/contexto.
static func crear_evento(
	id_evento: String,
	canal: String,
	fuente: String,
	contexto: String = "",
	jornada: int = 0,
	tradicion: String = "",
	etiquetas: Array = [],
	reglas_conflicto: Array = [],
	publico: bool = false,
	conocido_por: Array = []
) -> Dictionary:
	var id := id_evento.strip_edges()
	var origen := fuente.strip_edges()
	if id.is_empty() or origen.is_empty() or not CANALES.has(canal):
		return {}

	return {
		"id": id,
		"canal": canal,
		"fuente": origen,
		"contexto": contexto.strip_edges(),
		"jornada": maxi(0, jornada),
		"tradicion": tradicion.strip_edges(),
		"etiquetas": _normalizar_lista(etiquetas),
		"reglas_conflicto": _normalizar_lista(reglas_conflicto),
		"publico": publico,
		"conocido_por": _normalizar_lista(conocido_por),
	}


## Registra el evento una sola vez. El id es único entre canales para impedir
## que el mismo hecho termine contado como exposición y convicción por accidente.
static func registrar(registro: Dictionary, evento: Dictionary) -> bool:
	if not evento_valido(evento):
		return false

	var id := String(evento["id"])
	for canal in CANALES:
		for existente in _lista_canal(registro, canal):
			if typeof(existente) == TYPE_DICTIONARY and String(existente.get("id", "")) == id:
				return false

	var canal := String(evento["canal"])
	var destino := _lista_canal(registro, canal)
	destino.append(evento.duplicate(true))
	registro[canal] = destino
	return true


## Devuelve una copia: los consumidores no reciben la colección interna.
static func eventos(registro: Dictionary, canal: String) -> Array:
	if not CANALES.has(canal):
		return []
	return _lista_canal(registro, canal)


static func evento_valido(evento: Dictionary) -> bool:
	if String(evento.get("id", "")).strip_edges().is_empty():
		return false
	if String(evento.get("fuente", "")).strip_edges().is_empty():
		return false
	if not CANALES.has(String(evento.get("canal", ""))):
		return false
	for clave in ["etiquetas", "reglas_conflicto", "conocido_por"]:
		if evento.has(clave) and typeof(evento[clave]) != TYPE_ARRAY:
			return false
	if evento.has("publico") and typeof(evento["publico"]) != TYPE_BOOL:
		return false
	return true


static func _lista_canal(registro: Dictionary, canal: String) -> Array:
	var valor = registro.get(canal, [])
	return valor.duplicate(true) if typeof(valor) == TYPE_ARRAY else []


static func _normalizar_lista(valores: Array) -> Array:
	var resultado := []
	for valor in valores:
		var texto := String(valor).strip_edges()
		if not texto.is_empty() and not resultado.has(texto):
			resultado.append(texto)
	resultado.sort()
	return resultado
