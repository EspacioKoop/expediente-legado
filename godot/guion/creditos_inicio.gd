## Fuente canónica de contenido para la apertura de #795.
##
## Este módulo no decide cámaras, duración ni montaje. Solo entrega los bloques
## en el orden editorial acordado y agrega atribuciones de assets desde el
## catálogo de procedencia ya existente, para que la futura cinemática 3D no
## duplique ni deje obsoletos créditos de terceros.
class_name CreditosInicio
extends RefCounted

const RUTA_CATALOGO := "res://datos/creditos.json"
const RUTA_PROCEDENCIA := "res://assets/procedencia.json"


static func catalogo() -> Dictionary:
	return _leer_json(RUTA_CATALOGO, "catálogo de créditos")


static func bloques() -> Array:
	var datos := catalogo()
	var por_id := {}
	for entrada in datos.get("bloques", []):
		if not (entrada is Dictionary):
			continue
		var bloque: Dictionary = entrada.duplicate(true)
		var bloque_id := String(bloque.get("id", ""))
		if not bloque_id.is_empty():
			por_id[bloque_id] = bloque

	var salida := []
	for entrada_id in datos.get("orden", []):
		var bloque_id := String(entrada_id)
		if por_id.has(bloque_id):
			salida.append(por_id[bloque_id])
	return salida


## Devuelve una entrada por combinación autor/licencia/fuente. El catálogo de
## procedencia conserva el detalle por fichero; la apertura necesita acreditar
## la fuente una vez, no recitar cada GLB, textura, fuente o sonido.
static func atribuciones_assets() -> Array:
	var datos := _leer_json(RUTA_PROCEDENCIA, "catálogo de procedencia")
	var unicas := {}
	for entrada in datos.get("assets", []):
		if not (entrada is Dictionary):
			continue
		var autor := String(entrada.get("autor", "")).strip_edges()
		var licencia := String(entrada.get("licencia", "")).strip_edges()
		var fuente := String(entrada.get("fuente", "")).strip_edges()
		if autor.is_empty() or licencia.is_empty() or fuente.is_empty():
			continue
		var clave := "%s\u001f%s\u001f%s" % [autor, licencia, fuente]
		unicas[clave] = {
			"nombre": autor,
			"detalle": fuente,
			"licencia": licencia,
			"fuente": fuente,
			"tipo": "asset",
		}

	var claves := unicas.keys()
	claves.sort()
	var salida := []
	for clave in claves:
		salida.append(unicas[clave])
	return salida


## Forma lista para consumir por el futuro montaje: conserva los cinco bloques
## y expande únicamente el bloque open-source con atribuciones reales de assets.
static func bloques_completos() -> Array:
	var salida := bloques()
	for bloque in salida:
		if String(bloque.get("id", "")) != "open_source":
			continue
		var entradas: Array = bloque.get("entradas", []).duplicate(true)
		entradas.append_array(atribuciones_assets())
		bloque["entradas"] = entradas
		break
	return salida


static func _leer_json(ruta: String, etiqueta: String) -> Dictionary:
	var fichero := FileAccess.open(ruta, FileAccess.READ)
	if fichero == null:
		push_error("No se pudo abrir %s: %s" % [etiqueta, ruta])
		return {}
	var datos = JSON.parse_string(fichero.get_as_text())
	fichero.close()
	if not (datos is Dictionary):
		push_error("%s no contiene un objeto JSON" % etiqueta.capitalize())
		return {}
	return datos
