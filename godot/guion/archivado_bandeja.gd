## Estado de una bandeja de archivado (#157).
##
## Separa la sesión de juego de la escena 3D. La pantalla puede transportar una
## carpeta y llamar a `colocar`; esta capa conserva los errores para que la
## carpeta siga existiendo y delega la regla de destino en `Archivado` (#169).
class_name ArchivadoBandeja
extends RefCounted

const VERSION_GUARDADO := 1
const DEMORA_BUSQUEDA_POR_ERROR := 0.35
const DEMORA_BUSQUEDA_MAX := 1.4


static func nueva(casos: Array, folios_leidos: Array) -> Dictionary:
	return {
		"casos": casos.duplicate(true),
		"folios_leidos": folios_leidos.duplicate(),
		"colocaciones": [],
		"pendientes": casos.duplicate(true),
		"cerrada": false,
		"abandonada": false,
	}


## Incorpora carpetas que se hayan vuelto clasificables después de abrir más
## folios. No reabre las ya archivadas ni duplica casos existentes.
static func sincronizar(estado: Dictionary, casos: Array, folios_leidos: Array) -> Dictionary:
	estado["folios_leidos"] = folios_leidos.duplicate()
	var conocidas := {}
	for caso in estado.get("casos", []):
		var caso_id := String(caso.get("id", ""))
		if not caso_id.is_empty():
			conocidas[caso_id] = true

	var agregadas := 0
	for caso in casos:
		if not Archivado.es_clasificable(caso, folios_leidos):
			continue
		var caso_id := String(caso.get("id", ""))
		if caso_id.is_empty() or conocidas.has(caso_id):
			continue
		estado["casos"].append(caso.duplicate(true))
		if not _contiene_id(estado.get("pendientes", []), caso_id):
			estado["pendientes"].append(caso.duplicate(true))
		conocidas[caso_id] = true
		agregadas += 1

	if agregadas > 0:
		estado["cerrada"] = false
		estado["abandonada"] = false
	return estado


## Coloca una carpeta si el jugador conoce su contenido y devuelve si se aceptó.
## Una colocación incorrecta no destruye el caso: permanece en pendientes.
static func colocar(estado: Dictionary, caso: Dictionary, destino: String) -> bool:
	var caso_id := String(caso.get("id", ""))
	if (
		estado.get("cerrada", false)
		or caso_id.is_empty()
		or not _contiene_id(estado.get("pendientes", []), caso_id)
		or not Archivado.es_clasificable(caso, estado.get("folios_leidos", []))
	):
		return false
	var colocacion := {
		"caso": caso,
		"destino": destino,
		"folios_leidos": estado.get("folios_leidos", []).duplicate(),
	}
	estado["colocaciones"].append(colocacion)
	var correcta := destino == Archivado.destino_de(caso)
	if not correcta:
		return false
	for pendiente in estado["pendientes"]:
		if String(pendiente.get("id", "")) == caso_id:
			estado["pendientes"].erase(pendiente)
			break
	return true


## Resultado actual de la bandeja. `Archivado.evaluar` mide los intentos; esta
## capa añade las carpetas que aún siguen físicamente pendientes.
## El desorden espacial se deriva de intentos incorrectos que todavía no se han
## resuelto. Cuando ese mismo caso acaba en su destino correcto deja de estar
## pendiente y todas sus carpetas mal colocadas desaparecen del cómputo.
static func desorden_por_destino(estado: Dictionary) -> Dictionary:
	var pendientes := {}
	for caso in estado.get("pendientes", []):
		var caso_id := String(caso.get("id", ""))
		if not caso_id.is_empty():
			pendientes[caso_id] = true

	var resultado := {}
	for colocacion in estado.get("colocaciones", []):
		var caso: Dictionary = colocacion.get("caso", {})
		var caso_id := String(caso.get("id", ""))
		if not pendientes.has(caso_id):
			continue
		var destino := String(colocacion.get("destino", ""))
		if destino.is_empty() or destino == Archivado.destino_de(caso):
			continue
		resultado[destino] = int(resultado.get(destino, 0)) + 1
	return resultado


static func demora_busqueda(estado: Dictionary) -> float:
	var total := 0
	for cantidad in desorden_por_destino(estado).values():
		total += int(cantidad)
	return minf(DEMORA_BUSQUEDA_MAX, float(total) * DEMORA_BUSQUEDA_POR_ERROR)


static func resultado(estado: Dictionary) -> Dictionary:
	var resumen := Archivado.evaluar(estado.get("colocaciones", []))
	resumen["pendientes"] = estado.get("pendientes", []).size()
	resumen["total"] = estado.get("casos", []).size()
	resumen["completada"] = resumen["pendientes"] == 0 and resumen["total"] > 0
	return resumen


static func cerrar(estado: Dictionary) -> Dictionary:
	estado["cerrada"] = true
	return resultado(estado)


static func abandonar(estado: Dictionary) -> Dictionary:
	# No cambia jornada, economía ni expedientes. La bandeja sigue reanudable:
	# abandonar solo registra que se salió con trabajo pendiente.
	estado["abandonada"] = true
	var resumen := resultado(estado)
	resumen["abandonada"] = true
	return resumen


static func siguiente_pendiente(estado: Dictionary) -> Dictionary:
	var pendientes: Array = estado.get("pendientes", [])
	return pendientes[0] if not pendientes.is_empty() else {}


## El guardado no copia contenido de casos.json: solo ids y estado de la sesión.
static func serializar(estado: Dictionary) -> Dictionary:
	var colocaciones := []
	for colocacion in estado.get("colocaciones", []):
		var caso: Dictionary = colocacion.get("caso", {})
		var caso_id := String(caso.get("id", ""))
		if caso_id.is_empty():
			continue
		(
			colocaciones
			. append(
				{
					"caso_id": caso_id,
					"destino": String(colocacion.get("destino", "")),
				}
			)
		)
	return {
		"version": VERSION_GUARDADO,
		"casos": _ids_de_casos(estado.get("casos", [])),
		"pendientes": _ids_de_casos(estado.get("pendientes", [])),
		"colocaciones": colocaciones,
		"cerrada": bool(estado.get("cerrada", false)),
		"abandonada": bool(estado.get("abandonada", false)),
	}


## Reconstruye las referencias de caso desde el catálogo vigente. Un guardado
## no puede convertirse en autoridad de metadatos, folios o reglas de destino.
static func restaurar(guardado: Dictionary, catalogo: Array, folios_leidos: Array) -> Dictionary:
	var por_id := _catalogo_por_id(catalogo)
	var estado := nueva([], folios_leidos)
	if int(guardado.get("version", VERSION_GUARDADO)) > VERSION_GUARDADO:
		return sincronizar(estado, catalogo, folios_leidos)

	estado["casos"] = _casos_de_ids(guardado.get("casos", []), por_id)
	estado["pendientes"] = _casos_de_ids(guardado.get("pendientes", []), por_id)
	estado["cerrada"] = bool(guardado.get("cerrada", false))
	estado["abandonada"] = bool(guardado.get("abandonada", false))

	for colocacion in guardado.get("colocaciones", []):
		if typeof(colocacion) != TYPE_DICTIONARY:
			continue
		var caso_id := String(colocacion.get("caso_id", ""))
		if not por_id.has(caso_id):
			continue
		(
			estado["colocaciones"]
			. append(
				{
					"caso": por_id[caso_id].duplicate(true),
					"destino": String(colocacion.get("destino", "")),
					"folios_leidos": folios_leidos.duplicate(),
				}
			)
		)

	return sincronizar(estado, catalogo, folios_leidos)


static func _ids_de_casos(casos: Array) -> Array:
	var ids := []
	for caso in casos:
		var caso_id := String(caso.get("id", ""))
		if not caso_id.is_empty() and not ids.has(caso_id):
			ids.append(caso_id)
	return ids


static func _catalogo_por_id(catalogo: Array) -> Dictionary:
	var por_id := {}
	for caso in catalogo:
		var caso_id := String(caso.get("id", ""))
		if not caso_id.is_empty():
			por_id[caso_id] = caso
	return por_id


static func _casos_de_ids(ids: Array, por_id: Dictionary) -> Array:
	var casos := []
	for caso_id_crudo in ids:
		var caso_id := String(caso_id_crudo)
		if por_id.has(caso_id) and not _contiene_id(casos, caso_id):
			casos.append(por_id[caso_id].duplicate(true))
	return casos


static func _contiene_id(casos: Array, caso_id: String) -> bool:
	for caso in casos:
		if String(caso.get("id", "")) == caso_id:
			return true
	return false
