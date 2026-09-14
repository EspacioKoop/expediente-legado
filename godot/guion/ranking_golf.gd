## Ranking local persistente del golf de pasillo (#158).
##
## El ranking offline no depende de red ni de Partida. Guarda como máximo las
## mejores entradas en user:// y solo acepta partidas completas de tres hoyos.
class_name RankingGolf
extends RefCounted

const RUTA_LOCAL := "user://ranking_golf.json"
const LIMITE_LOCAL := 50
const GOLPES_MINIMOS := 3
const GOLPES_MAXIMOS := Golf.HOYOS * Golf.MAX_GOLPES_POR_HOYO


static func entrada(alias: String, golpes: int, fecha_unix: int = 0) -> Dictionary:
	var fecha := fecha_unix
	if fecha <= 0:
		fecha = int(Time.get_unix_time_from_system())
	return {
		"alias": _normalizar_alias(alias),
		"golpes": golpes,
		"hoyos": Golf.HOYOS,
		"fecha_unix": fecha,
	}


static func registrar(tabla: Array, nueva_entrada: Dictionary, limite: int = LIMITE_LOCAL) -> Array:
	var resultado := tabla.duplicate(true)
	var normalizada := _normalizar_entrada(nueva_entrada)
	if normalizada.is_empty():
		return ordenar(resultado).slice(0, maxi(limite, 0))
	resultado.append(normalizada)
	resultado = ordenar(resultado)
	if limite <= 0:
		return []
	if resultado.size() > limite:
		resultado.resize(limite)
	return resultado


static func registrar_resultado(
	tabla: Array, alias: String, resultado_partida: Dictionary, jugador: String
) -> Array:
	if not resultado_partida.get("completa", false):
		return tabla.duplicate(true)
	var totales: Dictionary = resultado_partida.get("totales", {})
	if not totales.has(jugador):
		return tabla.duplicate(true)
	return registrar(tabla, entrada(alias, int(totales[jugador])))


static func ordenar(tabla: Array) -> Array:
	var limpia := []
	for item in tabla:
		if item is Dictionary:
			var normalizada := _normalizar_entrada(item)
			if not normalizada.is_empty():
				limpia.append(normalizada)
	limpia.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["golpes"]) != int(b["golpes"]):
				return int(a["golpes"]) < int(b["golpes"])
			if int(a["fecha_unix"]) != int(b["fecha_unix"]):
				return int(a["fecha_unix"]) < int(b["fecha_unix"])
			return String(a["alias"]) < String(b["alias"])
	)
	return limpia


static func cargar_local(ruta: String = RUTA_LOCAL) -> Array:
	if not FileAccess.file_exists(ruta):
		return []
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return []
	var datos = JSON.parse_string(archivo.get_as_text())
	if not (datos is Array):
		return []
	return ordenar(datos)


static func guardar_local(tabla: Array, ruta: String = RUTA_LOCAL) -> bool:
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(JSON.stringify(ordenar(tabla)))
	archivo.flush()
	return true


static func registrar_local(alias: String, golpes: int, ruta: String = RUTA_LOCAL) -> Array:
	var tabla := cargar_local(ruta)
	tabla = registrar(tabla, entrada(alias, golpes))
	if not guardar_local(tabla, ruta):
		return []
	return tabla


static func _normalizar_entrada(item: Dictionary) -> Dictionary:
	var alias := _normalizar_alias(String(item.get("alias", "")))
	var golpes := int(item.get("golpes", -1))
	var hoyos := int(item.get("hoyos", Golf.HOYOS))
	if alias.is_empty() or hoyos != Golf.HOYOS:
		return {}
	if golpes < GOLPES_MINIMOS or golpes > GOLPES_MAXIMOS:
		return {}
	return {
		"alias": alias,
		"golpes": golpes,
		"hoyos": Golf.HOYOS,
		"fecha_unix": maxi(int(item.get("fecha_unix", 0)), 0),
	}


static func _normalizar_alias(alias: String) -> String:
	var limpio := alias.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
	while limpio.contains("  "):
		limpio = limpio.replace("  ", " ")
	return limpio.substr(0, 24)
