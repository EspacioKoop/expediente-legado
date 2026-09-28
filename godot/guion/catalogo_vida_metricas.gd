## Métricas locales de uso del catálogo por vida laboral (#91).
##
## No selecciona, oculta ni prioriza expedientes. Solo conserva IDs que el juego
## ya conoce para poder medir variedad/repetición antes de decidir una política
## de subconjuntos. Vive dentro de Jornada: una reasignación archiva únicamente
## la vida inmediatamente anterior y empieza otra medición vacía.
class_name CatalogoVidaMetricas
extends RefCounted

const CLAVE_ACTUAL := "catalogo_vida"
const CLAVE_ANTERIOR := "catalogo_vida_anterior"
const CLAVES_IDS := ["casos_disponibles", "casos_abiertos", "casos_resueltos"]


static func nueva(vuelta: int = 1) -> Dictionary:
	return {
		"vuelta": maxi(vuelta, 1),
		"casos_disponibles": [],
		"casos_abiertos": [],
		"casos_resueltos": [],
	}


static func asegurar(jornada: Dictionary) -> Dictionary:
	var vuelta := maxi(int(jornada.get("vuelta", 1)), 1)
	var actual = jornada.get(CLAVE_ACTUAL, {})
	if typeof(actual) != TYPE_DICTIONARY:
		actual = {}
	if actual.is_empty() or int(actual.get("vuelta", vuelta)) != vuelta:
		actual = nueva(vuelta)
	else:
		actual["vuelta"] = vuelta
		for clave in CLAVES_IDS:
			actual[clave] = _ids(actual.get(clave, []))
	jornada[CLAVE_ACTUAL] = actual

	var anterior = jornada.get(CLAVE_ANTERIOR, {})
	if typeof(anterior) != TYPE_DICTIONARY:
		anterior = {}
	if not anterior.is_empty():
		for clave in CLAVES_IDS:
			anterior[clave] = _ids(anterior.get(clave, []))
	jornada[CLAVE_ANTERIOR] = anterior
	return actual


## Fija la foto de disponibilidad una sola vez por vida. Si el catálogo cambia
## tras empezar una vida, esa vida conserva la foto con la que comenzó.
static func sincronizar_disponibles(jornada: Dictionary, casos: Array) -> bool:
	var actual := asegurar(jornada)
	if not actual["casos_disponibles"].is_empty():
		return false
	var ids := []
	for caso in casos:
		if typeof(caso) != TYPE_DICTIONARY:
			continue
		var caso_id := String(caso.get("id", "")).strip_edges()
		if not caso_id.is_empty() and not ids.has(caso_id):
			ids.append(caso_id)
	actual["casos_disponibles"] = ids
	return not ids.is_empty()


static func registrar_abierto(jornada: Dictionary, caso_id: String) -> bool:
	var limpio := caso_id.strip_edges()
	if limpio.is_empty():
		return false
	var actual := asegurar(jornada)
	var abiertos: Array = actual["casos_abiertos"]
	if abiertos.has(limpio):
		return false
	abiertos.append(limpio)
	return true


## Cerrar implica haber entrado en el expediente, aunque se haya firmado sin
## leer documentos. No interpreta si la firma fue buena o mala.
static func registrar_resuelto(jornada: Dictionary, caso_id: String) -> bool:
	var limpio := caso_id.strip_edges()
	if limpio.is_empty():
		return false
	var actual := asegurar(jornada)
	var cambio := registrar_abierto(jornada, limpio)
	var resueltos: Array = actual["casos_resueltos"]
	if not resueltos.has(limpio):
		resueltos.append(limpio)
		cambio = true
	return cambio


static func snapshot(jornada: Dictionary) -> Dictionary:
	return asegurar(jornada).duplicate(true)


static func anterior(jornada: Dictionary) -> Dictionary:
	asegurar(jornada)
	return Dictionary(jornada.get(CLAVE_ANTERIOR, {})).duplicate(true)


## Comparación puramente descriptiva entre la vida activa y la anterior.
static func comparar_con_anterior(jornada: Dictionary) -> Dictionary:
	var actual := snapshot(jornada)
	var previa := anterior(jornada)
	var resultado := {}
	for clave in CLAVES_IDS:
		var actuales: Array = actual.get(clave, [])
		var anteriores: Array = previa.get(clave, [])
		var comunes := []
		for caso_id in actuales:
			if anteriores.has(caso_id):
				comunes.append(caso_id)
		resultado[clave] = {
			"actual": actuales.size(),
			"anterior": anteriores.size(),
			"comunes": comunes.size(),
			"fraccion_actual":
			0.0 if actuales.is_empty() else float(comunes.size()) / float(actuales.size()),
		}
	return resultado


static func validar(valor: Dictionary, vuelta_esperada: int = 0) -> Array:
	var errores := []
	if valor.is_empty():
		return errores
	var vuelta = valor.get("vuelta", 0)
	if (
		typeof(vuelta) not in [TYPE_INT, TYPE_FLOAT]
		or int(vuelta) < 1
		or float(vuelta) != int(vuelta)
	):
		errores.append("vuelta inválida")
	elif vuelta_esperada > 0 and int(vuelta) != vuelta_esperada:
		errores.append("vuelta no coincide con Jornada")
	for clave in CLAVES_IDS:
		if not valor.has(clave) or typeof(valor[clave]) != TYPE_ARRAY:
			errores.append("%s no es una lista" % clave)
			continue
		var vistos := {}
		for bruto in valor[clave]:
			if typeof(bruto) != TYPE_STRING or String(bruto).strip_edges().is_empty():
				errores.append("%s contiene id inválido" % clave)
				continue
			if vistos.has(bruto):
				errores.append("%s contiene id duplicado: %s" % [clave, bruto])
			vistos[bruto] = true
	return errores


static func _ids(valor) -> Array:
	if typeof(valor) != TYPE_ARRAY:
		return []
	var salida := []
	for bruto in valor:
		if typeof(bruto) != TYPE_STRING:
			continue
		var limpio := String(bruto).strip_edges()
		if not limpio.is_empty() and not salida.has(limpio):
			salida.append(limpio)
	return salida
