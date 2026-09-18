## Relación documental onírica (#89).
##
## Presenta entre tres y cuatro documentos leídos hoy. Dos de ellos son los
## orígenes de una relación ya catalogada; el jugador solo puede cerrar una
## pareja una vez. Así comprender el contenido importa y probar combinaciones
## sucesivas no puede convertirse en la estrategia óptima.
class_name RelacionOnirica
extends RefCounted

const Puzzle := preload("res://guion/puzzle_onirico.gd")
const MIN_DOCUMENTOS := 3
const MAX_DOCUMENTOS := 4
const MAX_EXTRACTO := 140
const ANCHO_LINEA := 34
const _RUTA_SCRIPT := "res://guion/relacion_onirica.gd"

var nucleo
var documentos: Array = []
var origenes: Array = []
var seleccion: Array = []
var cerrada := false


static func crear(caso: Dictionary, pista: Dictionary, leido_hoy: Array, raiz: int):
	var pista_id := String(pista.get("id", "")).strip_edges()
	var origen_a := String(pista.get("registroOrigen", ""))
	var origen_b := String(pista.get("registroOrigen2", ""))
	if pista_id.is_empty() or origen_a.is_empty() or origen_b.is_empty() or origen_a == origen_b:
		return null

	var registro_a := _registro_por_id(caso, origen_a)
	var registro_b := _registro_por_id(caso, origen_b)
	if registro_a.is_empty() or registro_b.is_empty():
		return null
	if not _leido_hoy(registro_a, leido_hoy) or not _leido_hoy(registro_b, leido_hoy):
		return null

	var distractores: Array = []
	for registro in caso.get("registros", []):
		var registro_id := String(registro.get("id", ""))
		if registro_id == origen_a or registro_id == origen_b:
			continue
		if _leido_hoy(registro, leido_hoy):
			distractores.append(registro)
	if distractores.is_empty():
		return null

	var folio_a := String(registro_a.get("folio", ""))
	var folio_b := String(registro_b.get("folio", ""))
	var base = (
		Puzzle
		. crear(
			"relacion:" + pista_id,
			[folio_a, folio_b],
			leido_hoy,
			raiz,
			pista_id,
		)
	)
	if base == null:
		return null
	return _construir(caso, pista, leido_hoy, base)


## Restaura el mismo tablero y valida que selección/estado no contradigan al
## núcleo terminal. Un guardado manipulado no puede reabrir un fallo ni cambiar
## la pareja correcta después de haber visto el resultado.
static func restaurar(
	datos: Dictionary,
	caso: Dictionary,
	pista: Dictionary,
	leido_hoy: Array,
):
	var base = Puzzle.restaurar(datos.get("nucleo", {}), leido_hoy)
	var pista_id := String(pista.get("id", "")).strip_edges()
	if not _base_restaurable(base, pista_id):
		return null

	var relacion = _construir(caso, pista, leido_hoy, base)
	if relacion == null:
		return null
	var seleccion_guardada: Variant = datos.get("seleccion", [])
	if not seleccion_guardada is Array:
		return null
	var seleccion := seleccion_guardada as Array
	if not _seleccion_valida(seleccion, relacion.documentos):
		return null
	relacion.seleccion = seleccion.duplicate()
	relacion.cerrada = bool(datos.get("cerrada", false))
	if not _estado_restaurado_valido(relacion):
		return null
	return relacion


func seleccionar(indice: int) -> String:
	if nucleo == null or cerrada or not nucleo.pendiente():
		return "cerrado"

	var registro_id := _id_seleccionable(indice)
	if registro_id.is_empty():
		return "invalido"
	if seleccion.has(registro_id):
		return "duplicado"

	seleccion.append(registro_id)
	if seleccion.size() < 2:
		return "seleccionado"

	var elegida := seleccion.duplicate()
	elegida.sort()
	cerrada = true
	if elegida == origenes:
		nucleo.completar()
		return "completado"
	nucleo.fallar()
	return "fallado"


func _id_seleccionable(indice: int) -> String:
	if indice < 0 or indice >= documentos.size():
		return ""
	return String(documentos[indice].get("id", ""))


func salir() -> bool:
	if nucleo == null:
		return false
	if nucleo.pendiente():
		cerrada = true
		return nucleo.abandonar()
	cerrada = true
	return true


func serializar() -> Dictionary:
	if nucleo == null:
		return {}
	return {
		"nucleo": nucleo.serializar(),
		"seleccion": seleccion.duplicate(),
		"cerrada": cerrada,
	}


static func _base_restaurable(base, pista_id: String) -> bool:
	return (
		base != null
		and not pista_id.is_empty()
		and String(base.puzzle_id) == "relacion:" + pista_id
		and String(base.reward_id) == pista_id
	)


static func _construir(caso: Dictionary, pista: Dictionary, leido_hoy: Array, base):
	var origen_a := String(pista.get("registroOrigen", ""))
	var origen_b := String(pista.get("registroOrigen2", ""))
	var registro_a := _registro_por_id(caso, origen_a)
	var registro_b := _registro_por_id(caso, origen_b)
	if registro_a.is_empty() or registro_b.is_empty():
		return null
	if not _leido_hoy(registro_a, leido_hoy) or not _leido_hoy(registro_b, leido_hoy):
		return null

	var folios := [String(registro_a.get("folio", "")), String(registro_b.get("folio", ""))]
	folios.sort()
	if base.source_ids != folios:
		return null

	var distractores: Array = []
	for registro in caso.get("registros", []):
		var registro_id := String(registro.get("id", ""))
		if registro_id == origen_a or registro_id == origen_b:
			continue
		if _leido_hoy(registro, leido_hoy):
			distractores.append(registro)
	if distractores.is_empty():
		return null
	distractores.sort_custom(
		func(a: Dictionary, b: Dictionary): return String(a.get("id", "")) < String(b.get("id", ""))
	)

	var rng := RandomNumberGenerator.new()
	rng.seed = base.seed
	_barajar(distractores, rng)
	var elegidos: Array = [registro_a, registro_b]
	for i in range(mini(MAX_DOCUMENTOS - 2, distractores.size())):
		elegidos.append(distractores[i])
	_barajar(elegidos, rng)

	var relacion = _nueva_instancia()
	if relacion == null:
		return null
	relacion.nucleo = base
	relacion.origenes = [origen_a, origen_b]
	relacion.origenes.sort()
	for registro in elegidos:
		relacion.documentos.append(_vista_registro(registro))
	return relacion


static func _seleccion_valida(seleccion: Array, documentos: Array) -> bool:
	if seleccion.size() > 2:
		return false
	var ids: Array = documentos.map(func(documento): return String(documento.get("id", "")))
	var vistos: Array = []
	for valor in seleccion:
		var registro_id := String(valor)
		if registro_id.is_empty() or not ids.has(registro_id) or vistos.has(registro_id):
			return false
		vistos.append(registro_id)
	return true


static func _estado_restaurado_valido(relacion) -> bool:
	var estado := String(relacion.nucleo.state)
	var elegida: Array = relacion.seleccion.duplicate()
	elegida.sort()
	if estado == Puzzle.ESTADO_PENDIENTE:
		return not relacion.cerrada and relacion.seleccion.size() <= 1
	if not relacion.cerrada:
		return false
	if estado == Puzzle.ESTADO_COMPLETADO:
		return relacion.seleccion.size() == 2 and elegida == relacion.origenes
	if estado == Puzzle.ESTADO_FALLADO:
		return relacion.seleccion.size() == 2 and elegida != relacion.origenes
	if estado == Puzzle.ESTADO_ABANDONADO:
		return relacion.seleccion.size() <= 1
	return false


static func _registro_por_id(caso: Dictionary, registro_id: String) -> Dictionary:
	for registro in caso.get("registros", []):
		if String(registro.get("id", "")) == registro_id:
			return registro
	return {}


static func _leido_hoy(registro: Dictionary, leido_hoy: Array) -> bool:
	var folio := String(registro.get("folio", ""))
	return not folio.is_empty() and leido_hoy.has(folio)


static func _vista_registro(registro: Dictionary) -> Dictionary:
	var contenido := String(registro.get("contenido", "")).strip_edges()
	contenido = contenido.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	while contenido.contains("  "):
		contenido = contenido.replace("  ", " ")
	if contenido.length() > MAX_EXTRACTO:
		contenido = contenido.substr(0, MAX_EXTRACTO).strip_edges() + "…"
	contenido = _envolver(contenido)
	return {
		"id": String(registro.get("id", "")),
		"folio": String(registro.get("folio", "")),
		"tipo": String(registro.get("tipo", "")),
		"fecha": String(registro.get("fecha", "")),
		"extracto": contenido,
	}


static func _envolver(texto: String) -> String:
	var lineas: Array = []
	var linea := ""
	for palabra in texto.split(" ", false):
		var candidata := String(palabra) if linea.is_empty() else linea + " " + String(palabra)
		if candidata.length() <= ANCHO_LINEA:
			linea = candidata
			continue
		if not linea.is_empty():
			lineas.append(linea)
		linea = String(palabra)
	if not linea.is_empty():
		lineas.append(linea)
	return "\n".join(lineas)


static func _barajar(lista: Array, rng: RandomNumberGenerator) -> void:
	for i in range(lista.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var guardado = lista[i]
		lista[i] = lista[j]
		lista[j] = guardado


static func _nueva_instancia():
	var script := load(_RUTA_SCRIPT)
	if script == null:
		return null
	return script.new()
