## Modelo editorial declarativo de la prensa ficticia Web98 (#537).
##
## Los hechos base viven separados de sus tratamientos por cabecera. Cada artículo
## sólo puede destacar datos ya declarados en el hecho compartido; el encuadre,
## orden, omisiones y opinión pertenecen al tratamiento. No usa reloj real ni red.
class_name Web98Prensa
extends RefCounted

const RUTA_CATALOGO := "res://datos/web98_prensa.json"

var _cabeceras: Array[Dictionary] = []
var _hechos: Array[Dictionary] = []
var _tratamientos: Array[Dictionary] = []
var _por_cabecera: Dictionary = {}
var _por_hecho: Dictionary = {}
var _contexto: Dictionary = {"dia": 1}


func _init(ruta: String = RUTA_CATALOGO) -> void:
	_cargar_catalogo(ruta)


func configurar_contexto(contexto: Dictionary) -> void:
	_contexto = contexto.duplicate(true)


func cabeceras() -> Array[Dictionary]:
	return _cabeceras.duplicate(true)


func hechos() -> Array[Dictionary]:
	return _hechos.duplicate(true)


func hecho(hecho_id: String) -> Dictionary:
	var valor: Variant = _por_hecho.get(hecho_id, {})
	if not valor is Dictionary:
		return {}
	return (valor as Dictionary).duplicate(true)


func tratamientos_de(hecho_id: String) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for tratamiento in _tratamientos:
		if String(tratamiento.get("hecho_id", "")) == hecho_id:
			resultado.append(tratamiento.duplicate(true))
	resultado.sort_custom(_orden_tratamientos)
	return resultado


func portada(cabecera_id: String) -> Dictionary:
	var cabecera_valor: Variant = _por_cabecera.get(cabecera_id, {})
	if not cabecera_valor is Dictionary or (cabecera_valor as Dictionary).is_empty():
		return {"estado": "no_encontrado", "cabecera_id": cabecera_id}

	var articulos: Array[Dictionary] = []
	for tratamiento in _tratamientos:
		if String(tratamiento.get("cabecera_id", "")) != cabecera_id:
			continue
		var hecho_id := String(tratamiento.get("hecho_id", ""))
		var hecho_valor: Variant = _por_hecho.get(hecho_id, {})
		if not hecho_valor is Dictionary:
			continue
		var hecho_datos := hecho_valor as Dictionary
		if not _disponible_en_dia(hecho_datos):
			continue
		(
			articulos
			. append(
				{
					"hecho_id": hecho_id,
					"hecho": hecho_datos.duplicate(true),
					"tratamiento": tratamiento.duplicate(true),
					"datos_destacados": _proyectar_datos(hecho_datos, tratamiento),
				}
			)
		)
	articulos.sort_custom(_orden_articulos)
	return {
		"estado": "ok",
		"jornada": maxi(1, int(_contexto.get("dia", 1))),
		"cabecera": (cabecera_valor as Dictionary).duplicate(true),
		"articulos": articulos,
	}


## Conecta una portada realmente consumida con el contrato transversal de #919.
## Cada artículo registra la cabecera y el hecho compartido como una exposición
## idempotente. No escribe elecciones ni decide qué marco es verdadero.
func registrar_exposicion_portada(estado: Dictionary, cabecera_id: String) -> int:
	var portada_actual := portada(cabecera_id)
	if String(portada_actual.get("estado", "")) != "ok":
		return 0
	var cabecera: Dictionary = portada_actual.get("cabecera", {})
	var eje := String(cabecera.get("eje", ""))
	if not Prometeo.EJES.has(eje):
		return 0

	var registradas := 0
	for articulo_valor in portada_actual.get("articulos", []):
		if not articulo_valor is Dictionary:
			continue
		var articulo := articulo_valor as Dictionary
		var hecho_id := String(articulo.get("hecho_id", ""))
		if hecho_id.is_empty():
			continue
		if (
			Prometeo
			. registrar_exposicion_ideologica(
				estado,
				"prensa:%s:%s" % [cabecera_id, hecho_id],
				"prensa:%s" % cabecera_id,
				eje,
				int(portada_actual.get("jornada", 1)),
				_etiquetas_exposicion(articulo),
			)
		):
			registradas += 1
	return registradas


func _etiquetas_exposicion(articulo: Dictionary) -> Array:
	var etiquetas: Array = []
	var hecho_datos: Dictionary = articulo.get("hecho", {})
	var tratamiento: Dictionary = articulo.get("tratamiento", {})
	for valor in hecho_datos.get("temas", []):
		var etiqueta_hecho := String(valor).strip_edges()
		if not etiqueta_hecho.is_empty() and not etiquetas.has(etiqueta_hecho):
			etiquetas.append(etiqueta_hecho)
	for valor in tratamiento.get("enfasis", []):
		var etiqueta_enfasis := String(valor).strip_edges()
		if not etiqueta_enfasis.is_empty() and not etiquetas.has(etiqueta_enfasis):
			etiquetas.append(etiqueta_enfasis)
	return etiquetas


func _proyectar_datos(hecho_datos: Dictionary, tratamiento: Dictionary) -> Array[Dictionary]:
	var por_id: Dictionary = {}
	for dato in hecho_datos.get("datos", []):
		if dato is Dictionary:
			por_id[String((dato as Dictionary).get("id", ""))] = dato
	var resultado: Array[Dictionary] = []
	for dato_id in tratamiento.get("datos_destacados", []):
		var dato: Variant = por_id.get(String(dato_id), {})
		if dato is Dictionary and not (dato as Dictionary).is_empty():
			resultado.append((dato as Dictionary).duplicate(true))
	return resultado


func _disponible_en_dia(hecho_datos: Dictionary) -> bool:
	var dia := maxi(1, int(_contexto.get("dia", 1)))
	var desde := maxi(
		1, int(hecho_datos.get("disponible_desde_dia", hecho_datos.get("jornada", 1)))
	)
	var hasta := int(hecho_datos.get("disponible_hasta_dia", 0))
	if dia < desde:
		return false
	return hasta <= 0 or dia <= hasta


func _orden_articulos(a: Dictionary, b: Dictionary) -> bool:
	var tratamiento_a: Dictionary = a.get("tratamiento", {})
	var tratamiento_b: Dictionary = b.get("tratamiento", {})
	var orden_a := int(tratamiento_a.get("orden", 999))
	var orden_b := int(tratamiento_b.get("orden", 999))
	if orden_a != orden_b:
		return orden_a < orden_b
	return String(a.get("hecho_id", "")) < String(b.get("hecho_id", ""))


func _orden_tratamientos(a: Dictionary, b: Dictionary) -> bool:
	var cabecera_a := String(a.get("cabecera_id", ""))
	var cabecera_b := String(b.get("cabecera_id", ""))
	if cabecera_a != cabecera_b:
		return cabecera_a < cabecera_b
	return int(a.get("orden", 999)) < int(b.get("orden", 999))


func _cargar_catalogo(ruta: String) -> void:
	if not FileAccess.file_exists(ruta):
		return
	var datos: Variant = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	if not datos is Dictionary:
		return
	for valor in (datos as Dictionary).get("cabeceras", []):
		if not valor is Dictionary:
			continue
		var cabecera := (valor as Dictionary).duplicate(true)
		var cabecera_id := String(cabecera.get("id", ""))
		if cabecera_id.is_empty() or _por_cabecera.has(cabecera_id):
			continue
		_cabeceras.append(cabecera)
		_por_cabecera[cabecera_id] = cabecera
	for valor in (datos as Dictionary).get("hechos", []):
		if not valor is Dictionary:
			continue
		var hecho_datos := (valor as Dictionary).duplicate(true)
		var hecho_id := String(hecho_datos.get("id", ""))
		if hecho_id.is_empty() or _por_hecho.has(hecho_id):
			continue
		_hechos.append(hecho_datos)
		_por_hecho[hecho_id] = hecho_datos
	for valor in (datos as Dictionary).get("tratamientos", []):
		if valor is Dictionary:
			_tratamientos.append((valor as Dictionary).duplicate(true))
