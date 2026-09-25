## Núcleo determinista del terminal SIGA-98 (#956).
##
## No toca el sistema de archivos ni la red del host. Todo lo que parece disco,
## usuario o conexión vive en estas tablas ficticias y de solo lectura.
class_name TerminalSiga
extends RefCounted

const DIRECTORIOS := [
	"/",
	"/SIGA",
	"/SIGA/MEMOS",
	"/SIGA/CASOS",
	"/RED",
	"/USUARIOS",
]

const ARCHIVOS := {
	"/README.TXT":
	"SIGA-98 · TERMINAL DE CONSULTA\nEscriba HELP para ver los comandos disponibles.",
	"/SIGA/MEMOS/AYUDA.TXT":
	(
		"Los expedientes se consultan desde la aplicación SIGA. "
		+ "Este terminal solo expone utilidades de consulta."
	),
	"/SIGA/CASOS/INDICE.TXT":
	"Índice local disponible. Abra SIGA para consultar expedientes y folios autorizados.",
	"/RED/HOSTS.TXT":
	"SIGA.LOCAL       10.98.0.10\nARCHIVO.LOCAL    10.98.0.20\nINTRANET.LOCAL   10.98.0.30",
	"/USUARIOS/AUDITOR.TXT": "usuario=auditor\nperfil=consulta\nunidad=archivo",
}

const ENTORNO := {
	"USER": "auditor",
	"SISTEMA": "SIGA-98",
	"UNIDAD": "A:",
}

const LATENCIAS := {
	"siga.local": 12,
	"archivo.local": 18,
	"intranet.local": 31,
}

var _cwd := "/"
var _archivos: Dictionary = ARCHIVOS.duplicate(true)


func ejecutar(linea: String) -> Dictionary:
	var limpia := linea.strip_edges()
	var resultado: Dictionary
	if limpia.is_empty():
		resultado = _resultado(true, "")
	else:
		var partes := limpia.split(" ", false)
		var comando := String(partes[0]).to_lower()
		match comando:
			"help", "?":
				resultado = _resultado(true, _ayuda())
			"pwd":
				resultado = _resultado(true, _cwd)
			"dir", "ls":
				resultado = _listar(_argumento(partes))
			"cd":
				resultado = _cambiar_directorio(_argumento(partes))
			"type", "cat":
				resultado = _leer(_argumento(partes))
			"whoami":
				resultado = _resultado(true, String(ENTORNO["USER"]))
			"set":
				resultado = _resultado(true, _entorno_texto())
			"echo":
				resultado = _resultado(true, _expandir(_resto(partes)))
			"ping":
				resultado = _ping(_argumento(partes))
			"netstat":
				resultado = _resultado(
					true,
					(
						"PROTO  LOCAL          REMOTO             ESTADO\n"
						+ "TCP    SIGA-98:1048   ARCHIVO.LOCAL:98   ESTABLECIDA"
					)
				)
			"copy", "cp":
				resultado = _copiar(partes)
			"edit":
				resultado = _editar(partes)
			"del", "erase", "rm":
				resultado = _borrar(_argumento(partes))
			"users", "usuarios":
				resultado = _usuarios()
			_:
				resultado = _resultado(false, "Comando no reconocido: %s" % comando)
	return resultado


func cwd() -> String:
	return _cwd


func _listar(argumento: String) -> Dictionary:
	var destino := _normalizar(_cwd, argumento) if not argumento.is_empty() else _cwd
	if not DIRECTORIOS.has(destino):
		if _archivos.has(destino):
			return _resultado(true, destino.get_file())
		return _resultado(false, "Ruta no encontrada: %s" % destino)

	var entradas := []
	for directorio in DIRECTORIOS:
		var ruta := String(directorio)
		if ruta != destino and _padre(ruta) == destino:
			entradas.append("[DIR] " + ruta.get_file())
	for archivo in _archivos:
		var ruta := String(archivo)
		if _padre(ruta) == destino:
			entradas.append("      " + ruta.get_file())
	entradas.sort()
	return _resultado(true, "\n".join(entradas))


func _cambiar_directorio(argumento: String) -> Dictionary:
	if argumento.is_empty():
		_cwd = "/"
		return _resultado(true, _cwd)
	var destino := _normalizar(_cwd, argumento)
	if not DIRECTORIOS.has(destino):
		return _resultado(false, "Directorio no encontrado: %s" % destino)
	_cwd = destino
	return _resultado(true, _cwd)


func _leer(argumento: String) -> Dictionary:
	if argumento.is_empty():
		return _resultado(false, "Falta nombre de archivo")
	var destino := _normalizar(_cwd, argumento)
	if DIRECTORIOS.has(destino):
		return _resultado(false, "Es un directorio: %s" % destino)
	if not _archivos.has(destino):
		return _resultado(false, "Archivo no encontrado: %s" % destino)
	return _resultado(true, String(_archivos[destino]))


func _copiar(partes: PackedStringArray) -> Dictionary:
	if partes.size() < 3:
		return _resultado(false, "Uso: COPY origen destino")
	var origen := _normalizar(_cwd, String(partes[1]))
	var destino := _normalizar(_cwd, String(partes[2]))
	if not _archivos.has(origen):
		return _resultado(false, "Archivo no encontrado: %s" % origen)
	if DIRECTORIOS.has(destino):
		destino = _normalizar(destino, origen.get_file())
	if not DIRECTORIOS.has(_padre(destino)):
		return _resultado(false, "Directorio de destino no encontrado: %s" % _padre(destino))
	_archivos[destino] = _archivos[origen]
	return _resultado(true, "1 archivo copiado: %s" % destino)


func _editar(partes: PackedStringArray) -> Dictionary:
	if partes.size() < 3:
		return _resultado(false, "Uso: EDIT archivo texto")
	var destino := _normalizar(_cwd, String(partes[1]))
	if DIRECTORIOS.has(destino):
		return _resultado(false, "Es un directorio: %s" % destino)
	if not DIRECTORIOS.has(_padre(destino)):
		return _resultado(false, "Directorio no encontrado: %s" % _padre(destino))
	var texto := _resto_desde(partes, 2)
	_archivos[destino] = texto
	return _resultado(true, "Archivo temporal guardado: %s" % destino)


func _borrar(argumento: String) -> Dictionary:
	if argumento.is_empty():
		return _resultado(false, "Uso: DEL archivo")
	var destino := _normalizar(_cwd, argumento)
	if DIRECTORIOS.has(destino):
		return _resultado(false, "No se pueden borrar directorios")
	if not _archivos.has(destino):
		return _resultado(false, "Archivo no encontrado: %s" % destino)
	_archivos.erase(destino)
	return _resultado(true, "Archivo temporal eliminado: %s" % destino)


func _usuarios() -> Dictionary:
	var usuarios := []
	for archivo in _archivos:
		var ruta := String(archivo)
		if _padre(ruta) == "/USUARIOS":
			usuarios.append(ruta.get_file().trim_suffix(".TXT").to_lower())
	usuarios.sort()
	return _resultado(true, "\n".join(usuarios))


func _ping(argumento: String) -> Dictionary:
	var host := argumento.strip_edges().to_lower()
	if host.is_empty():
		return _resultado(false, "Falta host")
	if not LATENCIAS.has(host):
		return _resultado(false, "Host simulado desconocido: %s" % host)
	return _resultado(
		true, "PING %s (simulado): respuesta en %d ms" % [host.to_upper(), int(LATENCIAS[host])]
	)


func _resultado(ok: bool, salida: String) -> Dictionary:
	return {
		"ok": ok,
		"salida": salida,
		"cwd": _cwd,
	}


static func _argumento(partes: PackedStringArray) -> String:
	return String(partes[1]) if partes.size() > 1 else ""


static func _resto(partes: PackedStringArray) -> String:
	return _resto_desde(partes, 1)


static func _resto_desde(partes: PackedStringArray, inicio: int) -> String:
	var salida := ""
	for i in range(inicio, partes.size()):
		if not salida.is_empty():
			salida += " "
		salida += String(partes[i])
	return salida


static func _expandir(texto: String) -> String:
	var salida := texto
	for clave in ENTORNO:
		salida = salida.replace("%%%s%%" % String(clave), String(ENTORNO[clave]))
	return salida


static func _entorno_texto() -> String:
	var claves := ENTORNO.keys()
	claves.sort()
	var lineas := []
	for clave in claves:
		lineas.append("%s=%s" % [String(clave), String(ENTORNO[clave])])
	return "\n".join(lineas)


static func _normalizar(actual: String, entrada: String) -> String:
	var texto := entrada.strip_edges().replace("\\", "/")
	var partes := []
	if not texto.begins_with("/"):
		for parte in actual.split("/", false):
			partes.append(String(parte).to_upper())
	for parte_bruta in texto.split("/", false):
		var parte := String(parte_bruta)
		if parte.is_empty() or parte == ".":
			continue
		if parte == "..":
			if not partes.is_empty():
				partes.pop_back()
			continue
		partes.append(parte.to_upper())

	if partes.is_empty():
		return "/"
	var salida := ""
	for parte in partes:
		salida += "/" + String(parte)
	return salida


static func _padre(ruta: String) -> String:
	if ruta == "/":
		return ""
	var ultimo := ruta.rfind("/")
	if ultimo <= 0:
		return "/"
	return ruta.substr(0, ultimo)


static func _ayuda() -> String:
	return (
		"HELP  DIR/LS  CD  PWD  TYPE/CAT\n"
		+ "COPY/CP  EDIT  DEL/RM  USERS\n"
		+ "WHOAMI  SET  ECHO  PING  NETSTAT\n"
		+ "Sistema local simulado · cambios temporales de sesión"
	)
